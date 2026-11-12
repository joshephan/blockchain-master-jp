// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMarket} from "./IMarket.sol";
import {IPriceFeed, AssetConfig, Reserve, Position} from "./MarketTypes.sol";
import {MarketMath} from "./MarketMath.sol";

/// @title レンディング市場
/// @notice 上場したERC-20トークンを預け、担保で借り、返し、清算するマーケット。関数・イベント・エラーの説明はIMarket
/// @dev 一つのコントラクト、親・modifierなし(設計文書D-03)。状態を変える関数は全部
/// 確認 → 利息の積み上げ → 帳簿の修正 → 上限の確認 → トークンの移動 → イベントの順(設計文書4節、S-02)
contract Market is IMarket {
    uint256 internal constant WAD = 1e18;
    uint8 public constant PAUSE_DEPOSIT = 1;
    uint8 public constant PAUSE_BORROW = 2;
    uint8 public constant MAX_COLLATERAL_RATIO = 80; // パーセント
    uint256 public constant MAX_ASSETS = 20; // S-05: 上限の計算が回る資産数の上限
    uint32 public constant TWAP_WINDOW = 30 minutes; // F-09
    uint256 public constant LIQUIDATION_GAP = 5; // 清算ライン = 担保比率 + 5(パーセントポイント)
    uint256 public constant LIQUIDATION_BONUS = 5; // パーセント
    uint256 public constant CLOSE_FACTOR = 50; // 一度に返す借金(パーセント)

    /// @notice 設定キー。資産の上場・上限・停止・再開
    address public immutable admin;
    /// @notice 借りた比率が折れ点(80%)のときの年利(倍率10の18乗)
    uint256 public immutable rateAtKink;

    // ストレージスロット(設計文書2節): 0 assets、1 assetConfig、2 reserves、3 positions
    address[] public assets;
    mapping(address asset => AssetConfig) public assetConfig;
    mapping(address asset => Reserve) public reserves;
    mapping(address asset => mapping(address user => Position)) public positions;

    /// @param admin_ 設定キーのアドレス。0ならZeroAddress
    /// @param rateAtKink_ 折れ点の年利率(倍率10の18乗)
    constructor(address admin_, uint256 rateAtKink_) {
        if (admin_ == address(0)) revert ZeroAddress();
        admin = admin_;
        rateAtKink = rateAtKink_;
    }

    // ---------- 設定 ----------

    function listAsset(address asset, IPriceFeed feed, uint8 collateralRatio, uint256 supplyCap) external {
        _onlyAdmin();
        if (asset == address(0) || address(feed) == address(0)) revert ZeroAddress();
        if (assetConfig[asset].listed) revert AlreadyListed(asset);
        if (assets.length >= MAX_ASSETS) revert TooManyAssets(MAX_ASSETS);
        if (collateralRatio > MAX_COLLATERAL_RATIO) revert RatioAboveCap(collateralRatio, MAX_COLLATERAL_RATIO);
        uint8 d = IERC20Metadata(asset).decimals(); // decimalsがないトークン(ERC-721・ERC-1155)はここでリバート
        feed.cumulativePrice(TWAP_WINDOW); // 記録が30分より短い出どころは上場の前にリバート
        assets.push(asset);
        assetConfig[asset] = AssetConfig({
            feed: feed, decimals: d, collateralRatio: collateralRatio, pausedBits: 0, listed: true, supplyCap: supplyCap
        });
        emit AssetListed(asset, address(feed), collateralRatio, supplyCap);
    }

    function setSupplyCap(address asset, uint256 cap) external {
        _onlyAdmin();
        _config(asset).supplyCap = cap;
        emit SupplyCapSet(asset, cap);
    }

    function pause(address asset, uint8 bits) external {
        _onlyAdmin();
        AssetConfig storage c = _config(asset);
        c.pausedBits |= bits & (PAUSE_DEPOSIT | PAUSE_BORROW);
        emit PauseSet(asset, c.pausedBits);
    }

    function unpause(address asset, uint8 bits) external {
        _onlyAdmin();
        AssetConfig storage c = _config(asset);
        c.pausedBits &= ~bits;
        emit PauseSet(asset, c.pausedBits);
    }

    // ---------- ユーザー ----------

    function deposit(address asset, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        AssetConfig storage c = _config(asset);
        if (c.pausedBits & PAUSE_DEPOSIT != 0) revert ActionPaused(asset, PAUSE_DEPOSIT);
        (uint256 s,) = _accrue(asset);
        Reserve storage r = reserves[asset];
        uint256 total = MarketMath.mulDivDown(r.scaledDeposits, s, WAD) + amount;
        if (total > c.supplyCap) revert SupplyCapExceeded(c.supplyCap, total);
        uint256 scaled = MarketMath.mulDivDown(amount, WAD, s); // 渡す持ち分は切り捨て(S-04)
        if (scaled == 0) revert ZeroShares(); // S-06
        positions[asset][msg.sender].scaledDeposit += scaled;
        r.scaledDeposits += scaled;
        _pull(asset, msg.sender, amount);
        emit Deposited(asset, msg.sender, amount);
    }

    function withdraw(address asset, uint256 amount) external {
        _withdraw(asset, amount);
    }

    function withdrawAll(address asset) external {
        _withdraw(asset, depositOf(asset, msg.sender));
    }

    function setCollateral(address asset, bool on) external {
        _config(asset);
        positions[asset][msg.sender].useAsCollateral = on;
        if (!on) _checkHealth(msg.sender);
        emit CollateralSet(asset, msg.sender, on);
    }

    function borrow(address asset, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        AssetConfig storage c = _config(asset);
        if (c.pausedBits & PAUSE_BORROW != 0) revert ActionPaused(asset, PAUSE_BORROW);
        (uint256 s, uint256 b) = _accrue(asset);
        uint256 cash = _cash(asset, s, b);
        if (cash < amount) revert InsufficientLiquidity(cash, amount);
        uint256 scaled = MarketMath.mulDivUp(amount, WAD, b); // 受け取る借金の持ち分は切り上げ(S-04)
        positions[asset][msg.sender].scaledDebt += scaled;
        reserves[asset].scaledBorrows += scaled;
        _checkHealth(msg.sender);
        _push(asset, msg.sender, amount);
        emit Borrowed(asset, msg.sender, amount);
    }

    function repay(address asset, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        _config(asset);
        (, uint256 b) = _accrue(asset);
        uint256 paid = _reduceDebt(asset, msg.sender, amount, b);
        _pull(asset, msg.sender, paid);
        emit Repaid(asset, msg.sender, paid);
    }

    function liquidate(address borrower, address debtAsset, address collateralAsset, uint256 repayAmount) external {
        if (repayAmount == 0) revert ZeroAmount();
        _config(debtAsset);
        _config(collateralAsset);
        (, uint256 b) = _accrue(debtAsset);
        _accrue(collateralAsset);
        (uint256 limit, uint256 debtValue, uint256 collateralValue) = _health(borrower, LIQUIDATION_GAP);
        if (debtValue <= limit) revert NotLiquidatable(limit, debtValue);
        if (!positions[collateralAsset][borrower].useAsCollateral) revert NotCollateral(collateralAsset);
        uint256 debt = debtOf(debtAsset, borrower);
        // 担保の値が借金より小さいポジションは借金全部まで一度に(F-07)
        uint256 maxRepay = collateralValue < debtValue ? debt : debt * CLOSE_FACTOR / 100;
        if (repayAmount > maxRepay) revert AboveCloseFactor(maxRepay, repayAmount);
        uint256 seize = _seizeFor(debtAsset, collateralAsset, repayAmount);
        uint256 have = depositOf(collateralAsset, borrower);
        if (seize > have) {
            // 受け取る担保が預けた量より多ければ預けた量全部に減らし、返す量もそれに合わせる
            seize = have;
            repayAmount = _repayFor(debtAsset, collateralAsset, have);
        }
        uint256 paid = _reduceDebt(debtAsset, borrower, repayAmount, b);
        _moveCollateral(collateralAsset, borrower, msg.sender, seize);
        _pull(debtAsset, msg.sender, paid);
        emit Liquidated(borrower, msg.sender, collateralAsset, debtAsset, paid, seize);
    }

    function writeOffBadDebt(address borrower, address asset) external {
        (,, uint256 collateralValue) = _health(borrower, 0);
        if (collateralValue != 0) revert HasCollateral(collateralValue);
        _config(asset);
        (uint256 s, uint256 b) = _accrue(asset);
        Position storage p = positions[asset][borrower];
        if (p.scaledDebt == 0) revert NoDebt(asset);
        Reserve storage r = reserves[asset];
        uint256 loss = MarketMath.mulDivUp(p.scaledDebt, b, WAD);
        uint256 cut = r.scaledDeposits == 0 ? s : MarketMath.mulDivUp(loss, WAD, r.scaledDeposits);
        if (cut >= s) revert LossExceedsDeposits(loss, MarketMath.mulDivDown(r.scaledDeposits, s, WAD));
        r.scaledBorrows -= p.scaledDebt;
        p.scaledDebt = 0;
        r.supplyIndex = s - cut; // 消した借金の分だけ預け入れ側の指数を下げる(切り上げで計算)
        emit BadDebtWrittenOff(asset, borrower, loss);
    }

    // ---------- 読み取り ----------

    function assetCount() external view returns (uint256) {
        return assets.length;
    }

    function totalDeposits(address asset) external view returns (uint256) {
        (uint256 s,) = _indexesNow(asset);
        return MarketMath.mulDivDown(reserves[asset].scaledDeposits, s, WAD);
    }

    function totalBorrows(address asset) external view returns (uint256) {
        (, uint256 b) = _indexesNow(asset);
        return MarketMath.mulDivUp(reserves[asset].scaledBorrows, b, WAD);
    }

    function depositOf(address asset, address user) public view returns (uint256) {
        (uint256 s,) = _indexesNow(asset);
        return MarketMath.mulDivDown(positions[asset][user].scaledDeposit, s, WAD);
    }

    function debtOf(address asset, address user) public view returns (uint256) {
        (, uint256 b) = _indexesNow(asset);
        return MarketMath.mulDivUp(positions[asset][user].scaledDebt, b, WAD);
    }

    function utilization(address asset) public view returns (uint256) {
        (uint256 s, uint256 b) = _indexesNow(asset);
        Reserve storage r = reserves[asset];
        return MarketMath.utilization(
            MarketMath.mulDivDown(r.scaledBorrows, b, WAD), MarketMath.mulDivDown(r.scaledDeposits, s, WAD)
        );
    }

    function borrowRate(address asset) external view returns (uint256) {
        return MarketMath.borrowRate(utilization(asset), rateAtKink);
    }

    function priceOf(address asset) public view returns (uint256) {
        IPriceFeed feed = _config(asset).feed;
        return (feed.cumulativePrice(0) - feed.cumulativePrice(TWAP_WINDOW)) / TWAP_WINDOW;
    }

    function accountHealth(address user) public view returns (uint256 borrowLimit, uint256 debtValue) {
        (borrowLimit, debtValue,) = _health(user, 0);
    }

    function liquidationLimit(address user) external view returns (uint256 limit) {
        (limit,,) = _health(user, LIQUIDATION_GAP);
    }

    // ---------- 内部 ----------

    function _onlyAdmin() internal view {
        if (msg.sender != admin) revert NotAdmin(msg.sender);
    }

    function _config(address asset) internal view returns (AssetConfig storage c) {
        c = assetConfig[asset];
        if (!c.listed) revert NotListed(asset);
    }

    function _withdraw(address asset, uint256 amount) internal {
        if (amount == 0) revert ZeroAmount();
        _config(asset);
        (uint256 s, uint256 b) = _accrue(asset);
        Position storage p = positions[asset][msg.sender];
        uint256 have = MarketMath.mulDivDown(p.scaledDeposit, s, WAD);
        if (have < amount) revert InsufficientDeposit(have, amount);
        uint256 cash = _cash(asset, s, b);
        if (cash < amount) revert InsufficientLiquidity(cash, amount);
        uint256 scaled = amount == have ? p.scaledDeposit : MarketMath.mulDivUp(amount, WAD, s); // 引く持ち分は切り上げ
        p.scaledDeposit -= scaled;
        reserves[asset].scaledDeposits -= scaled;
        if (p.useAsCollateral) _checkHealth(msg.sender);
        _push(asset, msg.sender, amount);
        emit Withdrawn(asset, msg.sender, amount);
    }

    // 指数二つを今の時刻まで上げた値。同じブロック内ではそのまま、貸し出した持ち分がなければそのまま
    function _indexesNow(address asset) internal view returns (uint256 s, uint256 b) {
        Reserve storage r = reserves[asset];
        s = r.supplyIndex == 0 ? WAD : r.supplyIndex;
        b = r.borrowIndex == 0 ? WAD : r.borrowIndex;
        uint256 elapsed = block.timestamp - r.lastAccrual;
        if (elapsed == 0 || r.scaledBorrows == 0) return (s, b);
        uint256 borrows = MarketMath.mulDivDown(r.scaledBorrows, b, WAD);
        uint256 rate = MarketMath.borrowRate(
            MarketMath.utilization(borrows, MarketMath.mulDivDown(r.scaledDeposits, s, WAD)), rateAtKink
        );
        uint256 newB = b + MarketMath.interestFor(b, rate, elapsed);
        uint256 interest = MarketMath.mulDivDown(r.scaledBorrows, newB, WAD) - borrows;
        if (r.scaledDeposits != 0) s += MarketMath.mulDivDown(interest, WAD, r.scaledDeposits); // 預け入れ側の持ち分は切り捨て
        b = newB;
    }

    // 指数を今の時刻まで上げて書く
    function _accrue(address asset) internal returns (uint256 s, uint256 b) {
        (s, b) = _indexesNow(asset);
        Reserve storage r = reserves[asset];
        if (r.lastAccrual == block.timestamp) return (s, b);
        if (r.scaledBorrows != 0) {
            r.supplyIndex = s;
            r.borrowIndex = b;
        }
        r.lastAccrual = block.timestamp;
    }

    // マーケットに残ったトークン(帳簿で数える): 預けた量 - 貸し出した量
    function _cash(address asset, uint256 s, uint256 b) internal view returns (uint256) {
        Reserve storage r = reserves[asset];
        uint256 d = MarketMath.mulDivDown(r.scaledDeposits, s, WAD);
        uint256 bw = MarketMath.mulDivUp(r.scaledBorrows, b, WAD);
        return d > bw ? d - bw : 0;
    }

    // 借金を減らす。借金より多ければ借金の分だけ。一部だけ返すなら減らす持ち分は切り捨て
    function _reduceDebt(address asset, address user, uint256 amount, uint256 b) internal returns (uint256 paid) {
        Position storage p = positions[asset][user];
        uint256 scaledHave = p.scaledDebt;
        if (scaledHave == 0) revert NoDebt(asset);
        uint256 debt = MarketMath.mulDivUp(scaledHave, b, WAD);
        uint256 scaled;
        if (amount >= debt) {
            paid = debt;
            scaled = scaledHave;
        } else {
            paid = amount;
            scaled = MarketMath.mulDivDown(amount, WAD, b);
        }
        p.scaledDebt = scaledHave - scaled;
        reserves[asset].scaledBorrows -= scaled;
    }

    // 借金のあるアカウントの担保欄から清算したアカウントの欄へ。引く持ち分は切り上げ、入れる持ち分は切り捨て、差は預け入れの合計から引く
    function _moveCollateral(address asset, address from, address to, uint256 amount) internal {
        (uint256 s,) = _indexesNow(asset);
        Position storage pf = positions[asset][from];
        uint256 out = amount == MarketMath.mulDivDown(pf.scaledDeposit, s, WAD)
            ? pf.scaledDeposit
            : MarketMath.mulDivUp(amount, WAD, s);
        uint256 into = MarketMath.mulDivDown(amount, WAD, s);
        pf.scaledDeposit -= out;
        positions[asset][to].scaledDeposit += into;
        reserves[asset].scaledDeposits -= out - into;
    }

    // 返す量の値にボーナスを足して担保トークンの量に(切り捨て)
    function _seizeFor(address debtAsset, address collateralAsset, uint256 repayAmount)
        internal
        view
        returns (uint256)
    {
        uint256 unit = 10 ** assetConfig[collateralAsset].decimals;
        return
            _value(debtAsset, repayAmount, false) * (100 + LIQUIDATION_BONUS) * unit / (100 * priceOf(collateralAsset));
    }

    // 受け取る担保の量から逆に返す量を出す(切り上げ)
    function _repayFor(address debtAsset, address collateralAsset, uint256 seize) internal view returns (uint256) {
        uint256 unit = 10 ** assetConfig[debtAsset].decimals;
        return MarketMath.mulDivUp(
            _value(collateralAsset, seize, false) * 100, unit, (100 + LIQUIDATION_BONUS) * priceOf(debtAsset)
        );
    }

    // 上限と借金の値、担保の値の合計。資産リスト(MAX_ASSETS以下)を全部回る。担保の値は切り捨て、借金の値は切り上げ
    // gap: 担保比率に足すパーセントポイント(借入上限は0、清算ラインはLIQUIDATION_GAP)。比率0の資産には足さない
    function _health(address user, uint256 gap)
        internal
        view
        returns (uint256 limit, uint256 debtValue, uint256 collateralValue)
    {
        for (uint256 i = 0; i < assets.length; i++) {
            address a = assets[i];
            Position storage p = positions[a][user];
            if (p.useAsCollateral && p.scaledDeposit != 0) {
                uint256 v = _value(a, depositOf(a, user), false);
                uint256 ratio = assetConfig[a].collateralRatio;
                collateralValue += v;
                if (ratio != 0) limit += v * (ratio + gap) / 100;
            }
            if (p.scaledDebt != 0) debtValue += _value(a, debtOf(a, user), true);
        }
    }

    // トークン量を値に(倍率10の18乗)。資産ごとに10のdecimals乗で割る
    function _value(address asset, uint256 amount, bool roundUp) internal view returns (uint256) {
        uint256 unit = 10 ** assetConfig[asset].decimals;
        return roundUp
            ? MarketMath.mulDivUp(amount, priceOf(asset), unit)
            : MarketMath.mulDivDown(amount, priceOf(asset), unit);
    }

    function _checkHealth(address user) internal view {
        (uint256 limit, uint256 debt) = accountHealth(user);
        if (debt > limit) revert InsufficientCollateral(limit, debt);
    }

    // トークンを受け取る。戻り値はSafeERC20が見分ける(なければ通過、falseならリバート、S-08)
    // 金庫の残高が実際に増えた量が申告した量と違えばリバート(S-07)
    function _pull(address asset, address from, uint256 amount) internal {
        uint256 before = IERC20(asset).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(asset), from, address(this), amount);
        uint256 received = IERC20(asset).balanceOf(address(this)) - before;
        if (received != amount) revert AmountMismatch(amount, received);
    }

    // トークンを送る。受け取るアドレスは常に呼んだアカウント(withdraw・borrowに受け取りアドレスの引数はない)
    function _push(address asset, address to, uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(asset), to, amount);
    }
}
