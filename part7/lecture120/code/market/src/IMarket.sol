// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20, Amount, Rate, Ratio} from "./MarketTypes.sol";

// 第101講: Marketの外部関数の一覧。セレクターはforge inspect Market methodIdentifiersと同じでなければならない
// 第115講: Marketがこのインターフェースを継承(MarketBase is IMarket)。形が違えばビルドが止める
// enum・イベント・エラーはこのファイル一か所にだけ宣言
interface IMarket {
    // 第115講: Marketから移した市場の状態。ABIではuint8
    enum MarketStatus { Active, DepositPaused, Frozen }

    // 第107講: 読む側に渡すイベントの規格
    // 第115講: Marketはこの宣言を継承して出力する
    event AssetAdded(address indexed asset, Ratio ratio);           // topic0 = keccak256("AssetAdded(address,uint8)")
    event StatusChanged(MarketStatus from, MarketStatus to);         // keccak256("StatusChanged(uint8,uint8)")
    event Deposited(address indexed asset, address indexed user, uint256 amount); // keccak256("Deposited(address,address,uint256)")
    event Withdrawn(address indexed asset, address indexed user, uint256 amount); // keccak256("Withdrawn(address,address,uint256)")

    // 第108講: Marketが巻き戻すエラーの規格。呼ぶ側はこの宣言で巻き戻りデータの先頭4バイトに名前を付ける
    // 第115講: Marketはこの宣言を継承して巻き戻す
    error InsufficientDeposit(uint256 have, uint256 want); // 0x25c3f46e
    error ZeroAdmin();                                     // 0x7289db0e
    error NotAdmin(address caller);                        // 0x17a84242
    error MarketFrozen();                                  // 0xb2ce2a93
    error NotActive(MarketStatus status);                  // 0x1d61e8ee NotActive(uint8)
    error ZeroAsset();                                     // 0x7cde9b72
    error AlreadyListed(address asset);                    // 0x19cd4595
    error RatioAboveCap(Ratio ratio, Ratio cap);           // 0x56c44ccc RatioAboveCap(uint8,uint8)
    error NotListed(address asset);                        // 0x5d35c429
    error ZeroAmount();                                    // 0x1f2a2005
    error TransferFromFailed(address asset);               // 0x6e1c8d15
    error TransferFailed(address asset);                   // 0x39f1c8d9

    // 状態を変える関数 (第98講のnonpayable、第99講のイーサを受け取らない)
    function addAsset(IERC20 asset, Ratio ratio) external;          // 0x6127548a addAsset(address,uint8)
    function deposit(address asset, uint256 amount) external;       // 0x47e7ef24
    function withdraw(address asset, uint256 amount) external;      // 0xf3fef3a3 (Ledgerではpublic)
    function withdrawAll(address asset) external;                   // 0xfa09e630 (第100講)
    function setStatus(MarketStatus s) external;                    // 0x2e49d78b setStatus(uint8) (第103講、第115講でuint8をMarketStatusに)

    // 読み取り関数 (第98講のview・pure)
    function assetCount() external view returns (uint256);
    function interestFor(uint256 amount, Rate rate, uint256 elapsed) external pure returns (uint256);
    function elapsedOf(address asset, address user) external view returns (uint256);
    function collateralCount(address user) external view returns (uint256 count);

    // 自動ゲッター (第96講)
    function status() external view returns (MarketStatus); // 第115講: uint8をMarketStatusに。ABIはそのままuint8
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
