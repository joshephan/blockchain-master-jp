// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256; // 金額、資産トークンのdecimalsのまま
type Rate is uint256;   // 利率、倍率10の18乗
type Ratio is uint8;    // 担保比率、倍率100

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool); // 第78講
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

// 第17章末のMarket + 第81講のcollateralCount、デモ用のstatusNote
contract Market {
    enum MarketStatus { Active, DepositPaused, Frozen }

    MarketStatus public status;
    Ratio public collateralRatio;
    address public admin;
    Rate public interestRate;
    IERC20[] public assets;
    mapping(address asset => AssetConfig) public assetConfig;
    mapping(address asset => mapping(address user => Position)) public positions;
    mapping(address asset => Amount) public totalDeposits;
    mapping(address asset => Amount) public totalBorrows;

    constructor() {
        admin = msg.sender;
    }

    function addAsset(IERC20 asset, Ratio ratio) external {
        require(msg.sender == admin, "not admin");
        require(!assetConfig[address(asset)].listed, "already listed");
        assets.push(asset);
        assetConfig[address(asset)] = AssetConfig({collateralRatio: ratio, listed: true});
    }

    function deposit(address asset, uint256 amount) external {
        require(assetConfig[asset].listed, "not listed");
        Position storage p = positions[asset][msg.sender];
        p.deposited = Amount.wrap(Amount.unwrap(p.deposited) + amount);
        p.lastUpdate = uint64(block.timestamp);
        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) + amount);
    }

    function assetCount() external view returns (uint256) {
        return assets.length;
    }

    // 第75講の利息の草案: 1年は365 daysとみなす
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // amount: 資産の桁数のまま、rate: 年利 倍率10の18乗、elapsed: 秒
    function interestFor(uint256 amount, Rate rate, uint256 elapsed) public pure returns (uint256) {
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
            if (Amount.unwrap(positions[address(assets[i])][user].deposited)) {
                count++;
            }
        }
    }

    // デモ用: 三つの状態をif、else ifで分ける
    function statusNote() external view returns (string memory) {
        if (status == MarketStatus.Active) {
            return "open";
        } else if (status == MarketStatus.DepositPaused) {
            return "no deposit";
        } else {
            return "frozen";
        }
    }
}
