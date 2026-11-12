// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256; // 金額、資産トークンのdecimalsのまま
type Rate is uint256;   // 利率、倍率10の18乗
type Ratio is uint8;    // 担保比率、倍率100

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// 第72講のMarket、IERC20にtransferFromの宣言を足し、デモ用のpullCalldataを付けた版
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

    // デモ用: depositがトークンを取ってくるときに送るバイト列 (まだ送らない)
    function pullCalldata(uint256 amount) external view returns (bytes memory) {
        return abi.encodeCall(IERC20.transferFrom, (msg.sender, address(this), amount));
    }
}
