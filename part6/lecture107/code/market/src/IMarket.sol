// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20, Amount, Rate, Ratio} from "./Market.sol";

// 第101講: Marketの外部関数の一覧。セレクターはforge inspect Market methodIdentifiersと同じでなければならない
interface IMarket {
    // 第107講: 読む側に渡すイベントの規格。Marketの宣言とシグネチャ・indexedの配置が同じでなければならない
    event AssetAdded(address indexed asset, Ratio ratio);           // topic0 = keccak256("AssetAdded(address,uint8)")
    event StatusChanged(uint8 from, uint8 to);                       // keccak256("StatusChanged(uint8,uint8)")
    event Deposited(address indexed asset, address indexed user, uint256 amount); // keccak256("Deposited(address,address,uint256)")
    event Withdrawn(address indexed asset, address indexed user, uint256 amount); // keccak256("Withdrawn(address,address,uint256)")

    // 状態を変える関数 (第98講のnonpayable、第99講のイーサを受け取らない)
    function addAsset(IERC20 asset, Ratio ratio) external;          // 0x6127548a addAsset(address,uint8)
    function deposit(address asset, uint256 amount) external;       // 0x47e7ef24
    function withdraw(address asset, uint256 amount) external;      // 0xf3fef3a3
    function withdrawAll(address asset) external;                   // 0xfa09e630 (第100講)
    function setStatus(uint8 s) external;                           // 0x2e49d78b setStatus(uint8) (第103講、enum MarketStatusはABIではuint8)

    // 読み取り関数 (第98講のview・pure)
    function assetCount() external view returns (uint256);
    function interestFor(uint256 amount, Rate rate, uint256 elapsed) external pure returns (uint256);
    function elapsedOf(address asset, address user) external view returns (uint256);
    function collateralCount(address user) external view returns (uint256 count);

    // 自動ゲッター (第96講)
    function status() external view returns (uint8); // enum MarketStatusはABIではuint8
    function collateralRatio() external view returns (Ratio);
    function admin() external view returns (address);
    function interestRate() external view returns (Rate);
    function assets(uint256 index) external view returns (IERC20);
    function assetConfig(address asset) external view returns (Ratio collateralRatio, bool listed);
    function positions(address asset, address user)
        external view returns (Amount deposited, Amount borrowed, uint64 lastUpdate, bool useAsCollateral);
    function totalDeposits(address asset) external view returns (Amount);
    function totalBorrows(address asset) external view returns (Amount);
    function SECONDS_PER_YEAR() external view returns (uint256);
}
