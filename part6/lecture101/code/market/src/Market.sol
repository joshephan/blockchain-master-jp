// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256; // 金額、資産トークンのdecimalsのまま
type Rate is uint256;   // 利率、倍率10の18乗
type Ratio is uint8;    // 担保比率、倍率100

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool); // 第78講
    function transfer(address to, uint256 amount) external returns (bool); // 第83講
}

// ユーザー一人分 (第70講)
struct Position {
    Amount deposited;
    Amount borrowed;
    uint64 lastUpdate;
    bool useAsCollateral;
}

// 資産一つの設定
struct AssetConfig {
    Ratio collateralRatio;
    bool listed;
}

// 第90講: 預け入れより多く引き出そうとする要求
error InsufficientDeposit(uint256 have, uint256 want);

// 第21章 第101講末の版: 第100講の版そのまま + src/IMarket.sol(外部関数の一覧)、test/Selectors.t.sol
contract Market {
    enum MarketStatus { Active, DepositPaused, Frozen }

    MarketStatus public status;
    Ratio public collateralRatio; // 第92講: 資産ごとに決める担保比率の上限
    address public admin;
    Rate public interestRate;
    IERC20[] public assets;
    mapping(address asset => AssetConfig) public assetConfig;
    mapping(address asset => mapping(address user => Position)) public positions;
    mapping(address asset => Amount) public totalDeposits;
    mapping(address asset => Amount) public totalBorrows;

    constructor(address admin_, Rate interestRate_, Ratio collateralRatio_) {
        require(admin_ != address(0), "admin is zero");
        admin = admin_;
        interestRate = interestRate_;
        collateralRatio = collateralRatio_;
    }

    function addAsset(IERC20 asset, Ratio ratio) external {
        require(msg.sender == admin, "not admin");
        require(address(asset) != address(0), "zero asset"); // 第90講
        require(!assetConfig[address(asset)].listed, "already listed");
        require(Ratio.unwrap(ratio) <= Ratio.unwrap(collateralRatio), "ratio above cap"); // 第92講
        assets.push(asset);
        assetConfig[address(asset)] = AssetConfig({collateralRatio: ratio, listed: true});
    }

    function deposit(address asset, uint256 amount) external {
        require(assetConfig[asset].listed, "not listed");
        require(amount > 0, "zero amount"); // 第90講
        _credit({asset: asset, user: msg.sender, amount: amount});
        bool ok = IERC20(asset).transferFrom(msg.sender, address(this), amount); // 第83講
        require(ok, "transferFrom failed");
    }

    // 第100講: withdrawAllが内部で呼ぶのでexternalからpublicに
    function withdraw(address asset, uint256 amount) public {
        require(amount > 0, "zero amount"); // 第90講
        _debit({asset: asset, user: msg.sender, amount: amount});
        bool ok = IERC20(asset).transfer(msg.sender, amount); // 第83講
        require(ok, "transfer failed");
    }

    // 第100講: withdraw(address)でオーバーロードせず、名前を別に付ける
    function withdrawAll(address asset) external {
        withdraw(asset, Amount.unwrap(positions[asset][msg.sender].deposited));
    }

    function _credit(address asset, address user, uint256 amount) internal {
        Position storage p = positions[asset][user];
        p.deposited = Amount.wrap(Amount.unwrap(p.deposited) + amount);
        _touch(p);
        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) + amount);
    }

    function _debit(address asset, address user, uint256 amount) internal {
        Position storage p = positions[asset][user];
        uint256 have = Amount.unwrap(p.deposited);
        require(have >= amount, InsufficientDeposit(have, amount)); // 第90講
        p.deposited = Amount.wrap(have - amount);
        _touch(p);
        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) - amount);
        assert(Amount.unwrap(totalDeposits[asset]) >= Amount.unwrap(p.deposited)); // 第90講
    }

    function _touch(Position storage p) internal {
        p.lastUpdate = uint64(block.timestamp);
    }

    function assetCount() external view returns (uint256) {
        return assets.length;
    }

    // 第75講の利息の草案: 1年は365 daysとみなす
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // amount: 資産の桁数のまま、rate: 年利 倍率10の18乗、elapsed: 秒
    // 第95講: 内部で呼ぶ場所がないのでpublicからexternalに
    function interestFor(uint256 amount, Rate rate, uint256 elapsed) external pure returns (uint256) {
        return amount * Rate.unwrap(rate) * elapsed / SECONDS_PER_YEAR / 1e18;
    }

    // 第76講: 最後の更新から経過した秒数
    function elapsedOf(address asset, address user) external view returns (uint256) {
        Position storage p = positions[asset][user];
        return block.timestamp - p.lastUpdate;
    }

    // 第81講: このユーザーが担保に使う資産の数
    function collateralCount(address user) external view returns (uint256 count) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (positions[address(assets[i])][user].useAsCollateral) {
                count++;
            }
        }
    }
}
