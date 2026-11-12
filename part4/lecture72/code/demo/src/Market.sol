// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Amount, Rate, Ratio, IERC20, Position} from "./Types.sol";

// 資産一つの設定
struct AssetConfig {
    Ratio collateralRatio;
    bool listed; // 0と「未登録」を区別する欄、assetsにあればtrue
}

contract Market {
    enum MarketStatus { Active, DepositPaused, Frozen }

    MarketStatus public status;
    Ratio public collateralRatio;
    address public admin;
    Rate public interestRate;
    IERC20[] public assets;                                          // キーの一覧、管理者だけがpush
    mapping(address asset => AssetConfig) public assetConfig;
    mapping(address asset => mapping(address user => Position)) public positions;
    mapping(address asset => Amount) public totalDeposits;           // 資産ごとの合計
    mapping(address asset => Amount) public totalBorrows;            // 資産ごとの合計

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
}
