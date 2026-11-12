// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20, Amount, Rate, Ratio} from "./MarketTypes.sol";

// 第101講: Marketの外部関数の一覧。セレクターはforge inspect Market methodIdentifiersと同じでなければならない
// 第115講: Marketがこのインターフェースを継承(MarketBase is IMarket)。形が違えばビルドが止める
// enum・イベント・エラーはこのファイル一か所にだけ宣言
// 第146講: ABIの項目ごとにNatSpecをこのファイル一か所にだけ書く。Marketの関数・自動ゲッターはドキュメントを継承
/// @title レンディング市場Marketの外部仕様
/// @notice 管理者が上場したトークンを預けて引き出す市場
/// @dev MarketがMarketBaseを経由して継承。イベント・エラーの宣言とドキュメントはこのファイルにだけある
interface IMarket {
    // 第115講: Marketから移した市場の状態。ABIではuint8
    /// @notice 市場の状態。Activeはすべて許可、DepositPausedは預け入れだけ止める、Frozenは資産の追加と引き出しまで止める
    enum MarketStatus { Active, DepositPaused, Frozen }

    // 第107講: 読む側に渡すイベントの規格
    // 第115講: Marketはこの宣言を継承して出力する
    /// @notice 管理者が資産を上場する
    /// @param asset 上場したトークンのアドレス
    /// @param ratio その資産の担保比率(パーセント)
    event AssetAdded(address indexed asset, Ratio ratio);           // topic0 = keccak256("AssetAdded(address,uint8)")
    /// @notice 管理者が市場の状態を変える
    /// @param from 変更前の状態
    /// @param to 変更後の状態
    event StatusChanged(MarketStatus from, MarketStatus to);         // keccak256("StatusChanged(uint8,uint8)")
    /// @notice トークンを預ける
    /// @param asset 預けたトークンのアドレス
    /// @param user 預けたアカウント
    /// @param amount 預けた量(トークンの桁数のまま)
    event Deposited(address indexed asset, address indexed user, uint256 amount); // keccak256("Deposited(address,address,uint256)")
    /// @notice 預けたトークンを引き出す
    /// @param asset 引き出したトークンのアドレス
    /// @param user 引き出したアカウント
    /// @param amount 引き出した量(トークンの桁数のまま)
    event Withdrawn(address indexed asset, address indexed user, uint256 amount); // keccak256("Withdrawn(address,address,uint256)")

    // 第108講: Marketが巻き戻すエラーの規格。呼ぶ側はこの宣言で巻き戻りデータの先頭4バイトに名前を付ける
    // 第115講: Marketはこの宣言を継承して巻き戻す
    /// @notice 預けた量より多く引き出そうとする
    /// @param have 預けた量
    /// @param want 引き出そうとする量
    error InsufficientDeposit(uint256 have, uint256 want); // 0x25c3f46e
    /// @notice デプロイ時に管理者のアドレスが0
    error ZeroAdmin();                                     // 0x7289db0e
    /// @notice 管理者でないアカウントが管理者関数を呼ぶ
    /// @param caller 呼んだアカウント
    error NotAdmin(address caller);                        // 0x17a84242
    /// @notice 凍結した市場で資産の追加や引き出しを呼ぶ
    error MarketFrozen();                                  // 0xb2ce2a93
    /// @notice 市場がActiveでないときに預け入れを呼ぶ
    /// @param status 今の市場の状態
    error NotActive(MarketStatus status);                  // 0x1d61e8ee NotActive(uint8)
    /// @notice 資産のアドレスが0
    error ZeroAsset();                                     // 0x7cde9b72
    /// @notice すでに上場した資産をもう一度上場する
    /// @param asset トークンのアドレス
    error AlreadyListed(address asset);                    // 0x19cd4595
    /// @notice 担保比率が上限より大きい
    /// @param ratio 入れた比率(パーセント)
    /// @param cap 上限(パーセント)
    error RatioAboveCap(Ratio ratio, Ratio cap);           // 0x56c44ccc RatioAboveCap(uint8,uint8)
    /// @notice 上場していない資産を預けようとする
    /// @param asset トークンのアドレス
    error NotListed(address asset);                        // 0x5d35c429
    /// @notice 金額が0だ
    error ZeroAmount();                                    // 0x1f2a2005
    /// @notice トークンのtransferFromがfalseを返した
    /// @param asset トークンのアドレス
    error TransferFromFailed(address asset);               // 0x6e1c8d15
    /// @notice トークンのtransferがfalseを返した
    /// @param asset トークンのアドレス
    error TransferFailed(address asset);                   // 0x39f1c8d9

    // 状態を変える関数 (第98講のnonpayable、第99講のイーサを受け取らない)
    /// @notice 預けられるトークンを上場する。管理者のみ、凍結した市場では止まる
    /// @param asset トークンのアドレス
    /// @param ratio 担保比率(パーセント)。collateralRatio以下
    function addAsset(IERC20 asset, Ratio ratio) external;          // 0x6127548a addAsset(address,uint8)
    /// @notice トークンを預ける。先にこの市場のアドレスにamount分のapproveが必要
    /// @param asset トークンのアドレス
    /// @param amount 預ける量(トークンの桁数のまま)
    function deposit(address asset, uint256 amount) external;       // 0x47e7ef24
    /// @notice 預けたトークンを引き出す。凍結した市場では止まる
    /// @param asset トークンのアドレス
    /// @param amount 引き出す量(トークンの桁数のまま)
    function withdraw(address asset, uint256 amount) external;      // 0xf3fef3a3 (Ledgerではpublic)
    /// @notice 預けたトークンを全部引き出す
    /// @param asset トークンのアドレス
    function withdrawAll(address asset) external;                   // 0xfa09e630 (第100講)
    /// @notice 市場の状態を変える。管理者のみ
    /// @param s 変更する状態
    function setStatus(MarketStatus s) external;                    // 0x2e49d78b setStatus(uint8) (第103講、第115講でuint8をMarketStatusに)

    // 読み取り関数 (第98講のview・pure)
    /// @notice 上場した資産の数
    /// @return 個数
    function assetCount() external view returns (uint256);
    /// @notice 預けた量に付く利息。状態を読まない計算
    /// @param amount 金額(トークンの桁数のまま)
    /// @param rate 年利(倍率10の18乗)
    /// @param elapsed 経過した秒数
    /// @return 利息(トークンの桁数のまま)
    function interestFor(uint256 amount, Rate rate, uint256 elapsed) external pure returns (uint256);
    /// @notice そのアカウントの欄を最後に直してから経過した秒数
    /// @param asset トークンのアドレス
    /// @param user アカウント
    /// @return 経過した秒数
    function elapsedOf(address asset, address user) external view returns (uint256);
    /// @notice そのアカウントが担保に使う資産の数
    /// @param user アカウント
    /// @return count 個数
    function collateralCount(address user) external view returns (uint256 count);

    // 自動ゲッター (第96講)
    /// @notice 今の市場の状態
    /// @return 市場の状態
    function status() external view returns (MarketStatus); // 第115講: uint8をMarketStatusに。ABIはそのままuint8
    /// @notice 資産ごとに決める担保比率の上限(パーセント)
    /// @return 上限
    function collateralRatio() external view returns (Ratio);
    /// @notice 管理者のアドレス
    /// @return 管理者
    function admin() external view returns (address);
    /// @notice 年利(倍率10の18乗)
    /// @return 利率
    function interestRate() external view returns (Rate);
    /// @notice 上場した資産一覧の一つの欄
    /// @param index 位置(0から)
    /// @return トークンのアドレス
    function assets(uint256 index) external view returns (IERC20);
    /// @notice 資産一つの設定
    /// @param asset トークンのアドレス
    /// @return collateralRatio 担保比率(パーセント)
    /// @return listed 上場したか
    function assetConfig(address asset) external view returns (Ratio collateralRatio, bool listed);
    /// @notice アカウント一つの欄
    /// @param asset トークンのアドレス
    /// @param user アカウント
    /// @return deposited 預けた量
    /// @return borrowed 借りた量
    /// @return lastUpdate 最後に直した時刻
    /// @return useAsCollateral 担保に使うか
    function positions(address asset, address user)
        external view returns (Amount deposited, Amount borrowed, uint64 lastUpdate, bool useAsCollateral);
    /// @notice 資産ごとの預けた量の合計
    /// @param asset トークンのアドレス
    /// @return 合計
    function totalDeposits(address asset) external view returns (Amount);
    /// @notice 資産ごとの借りた量の合計
    /// @param asset トークンのアドレス
    /// @return 合計
    function totalBorrows(address asset) external view returns (Amount);
    /// @notice 利息の計算に使う1年の秒数
    /// @return 秒数
    function SECONDS_PER_YEAR() external view returns (uint256);
}
