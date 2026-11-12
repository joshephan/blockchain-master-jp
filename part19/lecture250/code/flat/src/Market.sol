// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20, IPriceFeed, Amount, Rate, Ratio, Position, AssetConfig, Reserve, PriceConfig} from "./MarketTypes.sol";
import {IMarket} from "./IMarket.sol";
import {InterestMath} from "./MarketMath.sol";

// 平らな版(第53章末の版s199が基準): 基準の版と同じ状態変数の順番・同じ検査の順番・同じABI
// 外したもの: 親コントラクト三つ(MarketBase、AssetRegistry、Ledger)、modifier三つ(onlyAdmin、notFrozen、whenActive)、
// virtual・overrideのフック(_checkDeposit、_checkWithdraw、_rateAtKink)、using PositionLib for Position、
// Amountの演算子+・-の使用(Amount.wrap・unwrapで直接計算)
// 残したもの: IMarketの実装、InterestMathの内部呼び出し、同じコントラクト内のinternal関数

/// @title レンディング市場
/// @notice 管理者が上場したトークンを預けて引き出す市場。関数・イベント・エラーの説明はIMarket
/// @dev デプロイするのはこのコントラクト一つ。親コントラクトなし
contract Market is IMarket {
    MarketStatus public status; // スロット0
    address public immutable admin;
    Ratio public immutable collateralRatio;
    IERC20[] public assets; // スロット1
    mapping(address asset => AssetConfig) public assetConfig; // スロット2
    mapping(address asset => mapping(address user => Position)) public positions; // スロット3
    mapping(address asset => Amount) public totalDeposits; // スロット4
    mapping(address asset => Amount) public totalBorrows; // スロット5
    mapping(address asset => Reserve) public reserves; // スロット6
    Rate public immutable interestRate;
    mapping(address asset => PriceConfig) public priceConfig; // スロット7

    uint32 public constant TWAP_WINDOW = 30 minutes;
    uint256 public constant LIQUIDATION_GAP = 5;
    uint256 public constant LIQUIDATION_BONUS = 5;
    uint256 public constant CLOSE_FACTOR = 50;
    uint256 public constant SECONDS_PER_YEAR = InterestMath.SECONDS_PER_YEAR;

    /// @notice 市場を作る
    /// @param admin_ 管理者のアドレス。0ならZeroAdmin
    /// @param interestRate_ 借りた比率が折れ点(80%)のときの年利(倍率10の18乗)
    /// @param collateralRatio_ 資産ごとに決める担保比率の上限(パーセント)
    constructor(address admin_, Rate interestRate_, Ratio collateralRatio_) {
        if (admin_ == address(0)) revert ZeroAdmin();
        admin = admin_;
        collateralRatio = collateralRatio_;
        interestRate = interestRate_;
    }

    function setStatus(MarketStatus s) external {
        if (msg.sender != admin) revert NotAdmin(msg.sender);
        MarketStatus from = status;
        status = s;
        emit StatusChanged(from, s);
    }

    function addAsset(IERC20 asset, Ratio ratio) external {
        if (msg.sender != admin) revert NotAdmin(msg.sender);
        if (status == MarketStatus.Frozen) revert MarketFrozen();
        if (address(asset) == address(0)) revert ZeroAsset();
        if (assetConfig[address(asset)].listed) revert AlreadyListed(address(asset));
        if (Ratio.unwrap(ratio) > Ratio.unwrap(collateralRatio)) revert RatioAboveCap(ratio, collateralRatio);
        assets.push(asset);
        assetConfig[address(asset)] = AssetConfig({collateralRatio: ratio, listed: true});
        emit AssetAdded(address(asset), ratio);
    }

    function assetCount() external view returns (uint256) {
        return assets.length;
    }

    function setPriceFeed(address asset, IPriceFeed feed) external {
        if (msg.sender != admin) revert NotAdmin(msg.sender);
        if (status == MarketStatus.Frozen) revert MarketFrozen();
        if (!assetConfig[asset].listed) revert NotListed(asset);
        if (address(feed) == address(0)) revert ZeroFeed();
        if (address(priceConfig[asset].feed) != address(0)) revert PriceFeedAlreadySet(asset);
        uint8 d = IERC20(asset).decimals();
        priceConfig[asset] = PriceConfig({feed: feed, decimals: d});
        emit PriceFeedSet(asset, address(feed));
    }

    /// @inheritdoc IMarket
    /// @dev 検査の順番: マーケットの状態、上場の確認、金額の確認
    function deposit(address asset, uint256 amount) external {
        if (status != MarketStatus.Active) revert NotActive(status);
        if (!assetConfig[asset].listed) revert NotListed(asset);
        if (amount == 0) revert ZeroAmount();
        (, uint256 s) = _accrue(asset);
        _credit(asset, msg.sender, amount * 1e18 / s);
        bool ok = IERC20(asset).transferFrom(msg.sender, address(this), amount);
        if (!ok) revert TransferFromFailed(asset);
        emit Deposited(asset, msg.sender, amount);
    }

    function withdraw(address asset, uint256 amount) public {
        if (amount == 0) revert ZeroAmount();
        (uint256 b, uint256 s) = _accrue(asset);
        uint256 have = Amount.unwrap(positions[asset][msg.sender].deposited) * s / 1e18;
        if (have < amount) revert InsufficientDeposit(have, amount);
        uint256 cash = _cash(asset, b, s);
        if (cash < amount) revert InsufficientLiquidity(cash, amount);
        _debit(asset, msg.sender, InterestMath.divUp(amount * 1e18, s));
        if (positions[asset][msg.sender].useAsCollateral) _checkHealth(msg.sender);
        bool ok = IERC20(asset).transfer(msg.sender, amount);
        if (!ok) revert TransferFailed(asset);
        emit Withdrawn(asset, msg.sender, amount);
    }

    function withdrawAll(address asset) external {
        withdraw(asset, depositOf(asset, msg.sender));
    }

    function depositOf(address asset, address user) public view returns (uint256) {
        (, uint256 s) = _indexesNow(asset);
        return Amount.unwrap(positions[asset][user].deposited) * s / 1e18;
    }

    function debtOf(address asset, address user) public view returns (uint256) {
        (uint256 b,) = _indexesNow(asset);
        return InterestMath.divUp(Amount.unwrap(positions[asset][user].borrowed) * b, 1e18);
    }

    function utilization(address asset) public view returns (uint256) {
        (uint256 b, uint256 s) = _indexesNow(asset);
        return InterestMath.utilization(
            Amount.unwrap(totalBorrows[asset]) * b / 1e18, Amount.unwrap(totalDeposits[asset]) * s / 1e18
        );
    }

    function borrowRate(address asset) external view returns (Rate) {
        return InterestMath.borrowRate(utilization(asset), interestRate);
    }

    function elapsedOf(address asset, address user) external view returns (uint256) {
        return block.timestamp - positions[asset][user].lastUpdate;
    }

    function interestFor(uint256 amount, Rate rate, uint256 elapsed) external pure returns (uint256) {
        return InterestMath.interestFor(amount, rate, elapsed);
    }

    function setCollateral(address asset, bool on) external {
        if (on && address(priceConfig[asset].feed) == address(0)) revert NoPriceFeed(asset);
        positions[asset][msg.sender].useAsCollateral = on;
        if (!on) _checkHealth(msg.sender);
        emit CollateralSet(asset, msg.sender, on);
    }

    function borrow(address asset, uint256 amount) external {
        if (status != MarketStatus.Active) revert NotActive(status);
        if (amount == 0) revert ZeroAmount();
        if (address(priceConfig[asset].feed) == address(0)) revert NoPriceFeed(asset);
        (uint256 b, uint256 s) = _accrue(asset);
        uint256 cash = _cash(asset, b, s);
        if (cash < amount) revert InsufficientLiquidity(cash, amount);
        if (Amount.unwrap(totalBorrows[asset]) == 0) reserves[asset].lastAccrual = uint64(block.timestamp);
        uint256 scaled = InterestMath.divUp(amount * 1e18, b);
        Position storage p = positions[asset][msg.sender];
        p.borrowed = Amount.wrap(Amount.unwrap(p.borrowed) + scaled);
        totalBorrows[asset] = Amount.wrap(Amount.unwrap(totalBorrows[asset]) + scaled);
        _checkHealth(msg.sender);
        bool ok = IERC20(asset).transfer(msg.sender, amount);
        if (!ok) revert TransferFailed(asset);
        emit Borrowed(asset, msg.sender, amount);
    }

    function repay(address asset, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        (uint256 b,) = _accrue(asset);
        uint256 paid = _subDebt(asset, msg.sender, amount, b);
        bool ok = IERC20(asset).transferFrom(msg.sender, address(this), paid);
        if (!ok) revert TransferFromFailed(asset);
        emit Repaid(asset, msg.sender, paid);
    }

    function liquidate(address borrower, address debtAsset, address collateralAsset, uint256 repayAmount) external {
        if (repayAmount == 0) revert ZeroAmount();
        (uint256 b,) = _accrue(debtAsset);
        _accrue(collateralAsset);
        _checkLiquidation(borrower, debtAsset, collateralAsset, repayAmount);
        uint256 seize = _value(debtAsset, repayAmount, false) * (100 + LIQUIDATION_BONUS) * 10
            ** priceConfig[collateralAsset].decimals / (100 * priceOf(collateralAsset));
        uint256 have = depositOf(collateralAsset, borrower);
        if (seize > have) {
            seize = have;
            repayAmount = InterestMath.divUp(
                _value(collateralAsset, have, false) * 100 * 10 ** priceConfig[debtAsset].decimals,
                (100 + LIQUIDATION_BONUS) * priceOf(debtAsset)
            );
        }
        uint256 paid = _subDebt(debtAsset, borrower, repayAmount, b);
        _moveCollateral(collateralAsset, borrower, msg.sender, seize);
        bool ok = IERC20(debtAsset).transferFrom(msg.sender, address(this), paid);
        if (!ok) revert TransferFromFailed(debtAsset);
        emit Liquidated(borrower, msg.sender, collateralAsset, debtAsset, paid, seize);
    }

    function _checkLiquidation(address borrower, address debtAsset, address collateralAsset, uint256 repayAmount)
        internal
        view
    {
        (uint256 limit, uint256 debtValue, uint256 collateralValue) = _health(borrower, LIQUIDATION_GAP);
        if (debtValue <= limit) revert NotLiquidatable(limit, debtValue);
        if (!positions[collateralAsset][borrower].useAsCollateral) revert NotCollateral(collateralAsset);
        uint256 debt = debtOf(debtAsset, borrower);
        uint256 maxRepay = collateralValue < debtValue ? debt : debt * CLOSE_FACTOR / 100;
        if (repayAmount > maxRepay) revert AboveCloseFactor(maxRepay, repayAmount);
    }

    function _moveCollateral(address asset, address from, address to, uint256 amount) internal {
        (, uint256 s) = _indexesNow(asset);
        uint256 scaledHave = Amount.unwrap(positions[asset][from].deposited);
        uint256 scaled = amount == scaledHave * s / 1e18 ? scaledHave : InterestMath.divUp(amount * 1e18, s);
        _debit(asset, from, scaled);
        _credit(asset, to, amount * 1e18 / s);
    }

    function writeOffBadDebt(address borrower, address asset) external {
        (,, uint256 collateralValue) = _health(borrower, 0);
        if (collateralValue != 0) revert HasCollateral(collateralValue);
        (uint256 b, uint256 s) = _accrue(asset);
        Position storage p = positions[asset][borrower];
        uint256 scaled = Amount.unwrap(p.borrowed);
        if (scaled == 0) revert NoDebt(asset);
        uint256 loss = InterestMath.divUp(scaled * b, 1e18);
        p.borrowed = Amount.wrap(0);
        totalBorrows[asset] = Amount.wrap(Amount.unwrap(totalBorrows[asset]) - scaled);
        reserves[asset].supplyIndex = s - InterestMath.divUp(loss * 1e18, Amount.unwrap(totalDeposits[asset]));
        emit BadDebtWrittenOff(asset, borrower, loss);
    }

    function priceOf(address asset) public view returns (uint256) {
        IPriceFeed feed = priceConfig[asset].feed;
        if (address(feed) == address(0)) revert NoPriceFeed(asset);
        return (feed.cumulativePrice(0) - feed.cumulativePrice(TWAP_WINDOW)) / TWAP_WINDOW;
    }

    function accountHealth(address user) public view returns (uint256 borrowLimit, uint256 debtValue) {
        (borrowLimit, debtValue,) = _health(user, 0);
    }

    function liquidationLimit(address user) external view returns (uint256 limit) {
        (limit,,) = _health(user, LIQUIDATION_GAP);
    }

    function collateralCount(address user) external view returns (uint256 count) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (positions[address(assets[i])][user].useAsCollateral) {
                count++;
            }
        }
    }

    function _indexesNow(address asset) internal view returns (uint256 b, uint256 s) {
        Reserve storage r = reserves[asset];
        b = r.borrowIndex == 0 ? 1e18 : r.borrowIndex;
        s = r.supplyIndex == 0 ? 1e18 : r.supplyIndex;
        uint256 scaledBorrows = Amount.unwrap(totalBorrows[asset]);
        uint256 elapsed = block.timestamp - r.lastAccrual;
        if (elapsed == 0 || scaledBorrows == 0) return (b, s);
        uint256 scaledDeposits = Amount.unwrap(totalDeposits[asset]);
        uint256 borrows = scaledBorrows * b / 1e18;
        Rate rate = InterestMath.borrowRate(InterestMath.utilization(borrows, scaledDeposits * s / 1e18), interestRate);
        uint256 newB = b + InterestMath.interestFor(b, rate, elapsed);
        uint256 interest = scaledBorrows * newB / 1e18 - borrows;
        if (scaledDeposits != 0) s += interest * 1e18 / scaledDeposits;
        b = newB;
    }

    function _accrue(address asset) internal returns (uint256 b, uint256 s) {
        (b, s) = _indexesNow(asset);
        if (Amount.unwrap(totalBorrows[asset]) == 0) return (b, s);
        Reserve storage r = reserves[asset];
        r.borrowIndex = b;
        r.supplyIndex = s;
        r.lastAccrual = uint64(block.timestamp);
    }

    function _cash(address asset, uint256 b, uint256 s) internal view returns (uint256) {
        uint256 d = Amount.unwrap(totalDeposits[asset]) * s / 1e18;
        uint256 bw = InterestMath.divUp(Amount.unwrap(totalBorrows[asset]) * b, 1e18);
        return d > bw ? d - bw : 0;
    }

    function _subDebt(address asset, address user, uint256 amount, uint256 b) internal returns (uint256 paid) {
        Position storage p = positions[asset][user];
        uint256 scaledHave = Amount.unwrap(p.borrowed);
        if (scaledHave == 0) revert NoDebt(asset);
        uint256 debt = InterestMath.divUp(scaledHave * b, 1e18);
        uint256 scaled;
        if (amount >= debt) {
            paid = debt;
            scaled = scaledHave;
        } else {
            paid = amount;
            scaled = amount * 1e18 / b;
        }
        p.borrowed = Amount.wrap(scaledHave - scaled);
        totalBorrows[asset] = Amount.wrap(Amount.unwrap(totalBorrows[asset]) - scaled);
    }

    function _credit(address asset, address user, uint256 amount) internal {
        Position storage p = positions[asset][user];
        p.deposited = Amount.wrap(Amount.unwrap(p.deposited) + amount);
        p.lastUpdate = uint64(block.timestamp);
        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) + amount);
    }

    function _debit(address asset, address user, uint256 amount) internal {
        Position storage p = positions[asset][user];
        uint256 have = Amount.unwrap(p.deposited);
        if (have < amount) revert InsufficientDeposit(have, amount);
        p.deposited = Amount.wrap(have - amount);
        p.lastUpdate = uint64(block.timestamp);
        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) - amount);
        assert(Amount.unwrap(totalDeposits[asset]) >= Amount.unwrap(p.deposited));
    }

    function _health(address user, uint256 gap)
        internal
        view
        returns (uint256 limit, uint256 debtValue, uint256 collateralValue)
    {
        for (uint256 i = 0; i < assets.length; i++) {
            address a = address(assets[i]);
            Position storage p = positions[a][user];
            if (p.useAsCollateral && Amount.unwrap(p.deposited) != 0) {
                uint256 v = _value(a, depositOf(a, user), false);
                collateralValue += v;
                limit += v * (Ratio.unwrap(assetConfig[a].collateralRatio) + gap) / 100;
            }
            if (Amount.unwrap(p.borrowed) != 0) debtValue += _value(a, debtOf(a, user), true);
        }
    }

    function _value(address asset, uint256 amount, bool roundUp) internal view returns (uint256) {
        uint256 x = amount * priceOf(asset);
        uint256 unit = 10 ** priceConfig[asset].decimals;
        return roundUp ? InterestMath.divUp(x, unit) : x / unit;
    }

    function _checkHealth(address user) internal view {
        (uint256 limit, uint256 debt) = accountHealth(user);
        if (debt > limit) revert InsufficientCollateral(limit, debt);
    }
}
