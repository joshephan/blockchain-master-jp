// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第115講: Market.solとIMarket.solが一緒に使う型。IMarket.solがMarket.solをインポートすると、MarketがIMarketを継承できない(Error 2449)

type Amount is uint256; // 金額、資産トークンのdecimalsのまま
type Rate is uint256; // 利率、倍率10の18乗
type Ratio is uint8; // 担保比率、倍率100

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
    function decimals() external view returns (uint8); // 第197講: 価格の出どころを付けるときに一回読む
}

// 第197講: 価格の出どころ。secondsAgo秒前までに積み上げた価格の合計(価格 × 秒)。価格はトークン一個の価値、倍率10の18乗
// Marketは二つの時点の合計を引いて時間加重平均を直接出す。その瞬間の価格を返す関数は置かない
interface IPriceFeed {
    function cumulativePrice(uint32 secondsAgo) external view returns (uint256);
}

// ユーザー一人分 (第70講)
// 第197講: deposited・borrowedは資産ごとの利息の指数で割った取り分。指数が1ならトークンの量と同じ
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

// 第197講: 資産一つの利息の指数二つ(倍率10の18乗)と最後に利息を積んだ時刻。指数0はまだ1として読む
struct Reserve {
    uint256 borrowIndex; // 借りた取り分一つが返す量
    uint256 supplyIndex; // 預けた取り分一つが引き出す量
    uint64 lastAccrual;
}

// 第197講: 資産一つの価格の出どころとトークンの小数点以下の桁数
struct PriceConfig {
    IPriceFeed feed;
    uint8 decimals;
}
