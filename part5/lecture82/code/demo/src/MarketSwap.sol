// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Amount, Rate, Ratio, IERC20, Position, AssetConfig} from "./Market.sol";

// デモ用: 状態変数の欄はMarketと同じ、depositの二つの版だけ
contract MarketSwap {
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

    // 位置引数、assetとuserを取り違えて書く
    function deposit(address asset, uint256 amount) external {
        require(assetConfig[asset].listed, "not listed");
        _credit(msg.sender, asset, amount);
    }

    // 名前指定引数、書く順番だけを変える
    function depositNamed(address asset, uint256 amount) external {
        require(assetConfig[asset].listed, "not listed");
        _credit({user: msg.sender, amount: amount, asset: asset});
    }

    function _credit(address asset, address user, uint256 amount) internal {
        Position storage p = positions[asset][user];
        p.deposited = Amount.wrap(Amount.unwrap(p.deposited) + amount);
        p.lastUpdate = uint64(block.timestamp);
        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) + amount);
    }
}
