// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// MarketとIMarketが共有する型。ストレージスロットの配置はdesign/architecture.md 2節

/// @notice Marketが呼ぶトークンの関数四つ
interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

/// @notice 価格の出どころ。secondsAgo秒前までに積み上がった価格の合計(価格 × 秒)。価格はトークン一個の値、倍率10の18乗
interface IPriceFeed {
    function cumulativePrice(uint32 secondsAgo) external view returns (uint256);
}

// 資産一つの設定。二スロット: +0 feed・decimals・collateralRatio・pausedBits・listed、+1 supplyCap
struct AssetConfig {
    IPriceFeed feed;
    uint8 decimals;
    uint8 collateralRatio; // パーセント、MAX_COLLATERAL_RATIO以下
    uint8 pausedBits; // 1は預け入れの停止、2は借り入れの停止
    bool listed;
    uint256 supplyCap; // 預け入れの合計(トークン量)の上限
}

// 資産一つの帳簿。五スロット。持ち分(scaled)に指数を掛けるとトークン量
struct Reserve {
    uint256 scaledDeposits;
    uint256 scaledBorrows;
    uint256 supplyIndex; // 倍率10の18乗、0は1と読む
    uint256 borrowIndex; // 倍率10の18乗、0は1と読む
    uint256 lastAccrual; // 最後に利息を積んだ時刻(秒)
}

// ユーザー一人の資産一つの持ち分。三スロット
struct Position {
    uint256 scaledDeposit;
    uint256 scaledDebt;
    bool useAsCollateral;
}
