// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第115講: Market.solとIMarket.solが一緒に使う型。IMarket.solがMarket.solをインポートすると、MarketがIMarketを継承できない(Error 2449)

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
