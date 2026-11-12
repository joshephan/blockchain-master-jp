// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第115講: Market.solとIMarket.solが一緒に使う型。IMarket.solがMarket.solをインポートすると、MarketがIMarketを継承できない(Error 2449)

type Amount is uint256; // 金額、資産トークンのdecimalsのまま
type Rate is uint256;   // 利率、倍率10の18乗
type Ratio is uint8;    // 担保比率、倍率100

// 第118講: Amount同士を足し引きする演算子。演算子はpureの自由関数にしか付けられず(Error 7775)、globalでなければならない(Error 3320)
// globalは型を宣言したこのファイルでしか書けない(Error 4117)。Amountをインポートして使うファイルはどこでもこの演算子を使う
// 本体は0.8のデフォルトの算術なので、あふれたり足りなかったりするとPanic 0x11で巻き戻す
function addAmount(Amount a, Amount b) pure returns (Amount) {
    return Amount.wrap(Amount.unwrap(a) + Amount.unwrap(b));
}

function subAmount(Amount a, Amount b) pure returns (Amount) {
    return Amount.wrap(Amount.unwrap(a) - Amount.unwrap(b));
}

using {addAmount as +, subAmount as -} for Amount global;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool); // 第78講
    function transfer(address to, uint256 amount) external returns (bool); // 第83講
}

// ユーザー一人分 (第70講)
struct Position {
    uint128 deposited;
    uint64 lastUpdate;
    bool useAsCollateral;
    uint128 borrowed;
}

// 資産一つの設定
struct AssetConfig {
    Ratio collateralRatio;
    bool listed;
}
