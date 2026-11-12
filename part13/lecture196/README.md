# 第196講 集中流動性

第13部 DeFi・第52章 AMM

[← 第195講](../../part13/lecture195/) | [第13部 目次](../) | [第197講 →](../../part13/lecture197/)

## この講義の問い

預けたお金の大部分が取引に使われないなら、価格の近くにだけ集めると何が変わるのか。価格がその範囲を外れると、預けたお金はどうなるのか。小数のない機械で、√価格のような値はどう計算するのか。こういうプールの価格を読む側は、何を余計に見るべきなのか。

## 実習資料

### 準備

講義用のおもちゃのプールを二つ使う。全範囲の定積のプールToyAmmと、ポジション一つ・範囲一つだけの集中流動性のプールToyRangePoolである（どちらも実在するプロトコルのコードではない）。ToyRangePoolは手数料とトークンの移動を省き、帳簿の数字だけを扱う。forge-std（1.17.0）とOpenZeppelin Contracts 5.4.0（`Math.mulDiv`）が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。anvilと外部への接続は使わない。Marketのコードとテストは変えていない。

### コード

| ファイル | 内容 |
|---|---|
| [code/src/ToyRangePool.sol](code/src/ToyRangePool.sol) | 集中流動性のおもちゃのプール。流動性Lと√価格（1e18倍率）を記録、swap1For0・swap0For1、範囲の外なら`OutOfRange` |
| [code/src/ToyAmm.sol](code/src/ToyAmm.sol) | 比較用の全範囲の定積のプール |
| [code/src/ToyErc20.sol](code/src/ToyErc20.sol) | テスト用のトークン |
| [code/test/Range196.t.sol](code/test/Range196.t.sol) | 範囲のプールの量、深さの比較、範囲の端、損失、mulDivのテストなど九つ |
| [code/test/Extra196.t.sol](code/test/Extra196.t.sol) | 全範囲のプールで実際に使われる分、下の端、範囲への再進入、同じ深さの全範囲のプールのテスト四つ |
| [code/foundry.toml](code/foundry.toml) | ビルド設定（via-IR、optimizerオン、OpenZeppelinのremapping、fuzz runs 256 seed 0x2a） |

### 実行結果

おもちゃのプールの設定：今の価格1、範囲0.81〜1.21（√価格0.9〜1.1）、流動性L = 10000。実際に入っている量はA = 10000 × (1 − 1/1.1) = 909.09、B = 10000 × (1 − 0.9) = 1000である。

`forge test --offline --match-contract Range196Test -vv`（九つ通過）：

```
[PASS] testFuzz_mulDivMatchesPlain(uint128,uint128,uint128) (runs: 256, μ: 4073, ~: 4073)
[PASS] test_capitalForSameDepth() (gas: 3532)
Logs:
  full range needs 10000000000000000000000 10000000000000000000000
[PASS] test_deeperInRange() (gas: 61885)
Logs:
  range out 99009900990099009900
  full out 90909090909090909090
  range price after 1020100000000000000
[PASS] test_exitRange() (gas: 83060)
Logs:
  out at edge 909090909090909090909
  left A, B 0 2000000000000000000000
  price at edge 1210000000000000000
[PASS] test_lossAmplified() (gas: 250456)
Logs:
  range lp / hold x1e6 952380 2000000000000000000000 2099999999999999999999
  full lp / hold x1e6 995475 2200000000000000000001 2210000000000000000000
  full price 1209999999999999999
[PASS] test_mulDivFullPrecision() (gas: 130450)
[PASS] test_mulDivRounding() (gas: 726)
[PASS] test_rangeAmounts() (gas: 14522)
Logs:
  range A 909090909090909090909
  range B 1000000000000000000000
[PASS] test_swapDown() (gas: 78567)
Logs:
  A 100 in, B out 99009900990099000000
  price after 980296049406920892
Suite result: ok. 9 passed; 0 failed; 0 skipped
```

`forge test --offline --match-contract Extra196Test -vv`（四つ通過）：

```
[PASS] test_fullRangeUsedShare() (gas: 1000476)
Logs:
  B 100 in, A out 90909090909090909090
  price 1209999999999999999
  A 111.11 in, B out 100000000000000000000
  price 809999999999999999
[PASS] test_lowerEdgeAllA() (gas: 10329)
Logs:
  at 0.81, A, B 2020202020202020202020 0
[PASS] test_reenterRange() (gas: 77445)
Logs:
  A 100 in at edge, B out 119683481701285850000
  A, B after 99999999999999995278 1880316518298714150000
  price after 1183812875383638533
[PASS] test_sameDepthFullRange() (gas: 500407)
Logs:
  10000/10000 pool, B 100 in, A out 99009900990099009900
  price 1020099999999999999
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

全範囲の1000/1000のプールで価格が0.81〜1.21を行き来するあいだに動く量は、A 90.9、B 100だけである。残りのA 909、B 900は、価格がこの範囲を大きく外れてはじめて使われる。

同じBを100入れるとき（どちらのプールも手数料なし）：

| | 範囲のプール（A 909 + B 1000） | 全範囲のプール（A 1000 + B 1000） | 全範囲のプール（L 10000） |
|---|---|---|---|
| 預けたお金 | A 909 + B 1000 | A 1000 + B 1000 | A 10000 + B 10000 |
| 受け取るA | 99.009900990099009900 | 90.909090909090909090 | 99.009900990099009900 |
| 交換のあとの価格 | 1.0201 | 1.21 | 1.0201 |

Bを入れると√価格がΔB / Lだけ上がる（1 + 100/10000 = 1.01、価格1.0201）。新しい√価格は、Bを入れるときは切り捨て、Aを入れるときは切り上げで求める。どちらもプールが少なく払う側である。だからA 100 → Bは99.009900990099000000で、B 100 → Aより末尾が9,900 wei少ない。

掛けた途中の値があふれる場合（`test_mulDivFullPrecision`、`-vvvv`のトレース1行）。x = 2の200乗、y = 2の100乗、d = 2の150乗で、そのままのx × y ÷ dは積2の300乗でリバートし、`Math.mulDiv(x, y, d)`は2の150乗を返す。

```
← [Revert] panic: arithmetic underflow or overflow (0x11)
```

切り捨てと切り上げ：10 ÷ 3は切り捨てで3、切り上げ（`Math.Rounding.Ceil`）で4。9 ÷ 3は切り上げでも3である。

範囲の端からもう一歩出ると`OutOfRange`でリバートする。リバートのデータは、次の√価格、下の端、上の端である。1行目は範囲の端でBを少し余計に入れた場合、2行目は価格1でAを2000入れて√価格が0.826まで下がらなければならない場合である。

```
← [Revert] OutOfRange(1100000000000000001 [1.1e18], 900000000000000000 [9e17], 1100000000000000000 [1.1e18])
← [Revert] OutOfRange(826446280991735538 [8.264e17], 900000000000000000 [9e17], 1100000000000000000 [1.1e18])
```

価格1 → 1.21の損失（価値はB基準、外の価格1.21はテストが決めた数字）：

| | 範囲のポジション | 全範囲 1000/1000 |
|---|---|---|
| 最初 | A 909.09 + B 1000 | A 1000 + B 1000 |
| 1.21でプールに残った分 | A 0 + B 2000 = 2000 | A 909.09 + B 1100 = 2200 |
| 持っていたら | 1100 + 1000 = 2100 | 1210 + 1000 = 2210 |
| 持っているだけとの比 | 0.952380（−4.76%） | 0.995475（−0.45%） |

同じBを1000入れても、範囲のプールは価格が1 → 1.21に動いてそのあとは深さ0になり、全範囲の1000/1000のプールは1 → 4に動く。

この結果から書いた、価格の出どころの判断記録：

| 問い | 見たもの | 決定 | テスト |
|---|---|---|---|
| どのプールを価格の出どころに使うか | 集中流動性のプールは、今の価格の近くの深さがポジションごと・時間ごとに違う。範囲のプールはB 1000で価格が1 → 1.21になり、そのあとは範囲の外 | 平均の窓の長さと一緒に、今の価格の近くの深さ（最小の流動性）を条件にする。条件の値は貸す機能と同じバージョンで決める | Range196Test（test_exitRange、test_deeperInRange） |

### 試すときの注意

- Solidityには小数の型がない。√価格は1e18倍率の整数（0.9 → 900000000000000000）で記録する。
- 1e18倍率の値を二つ掛けると倍率が1e36になり、Lまで掛けると途中の値が先にあふれる。割った答えが256ビットに収まっても、積があふれればリバートするので`mulDiv`を使う。
- ファズテスト`testFuzz_mulDivMatchesPlain`は、uint128の範囲の値三つで、mulDivとそのままの計算が同じ答えを出すかを256回確かめる。
- 範囲の外にいるあいだ、そのポジションには一種類の資産だけが残り、取引に使われない。価格が範囲に戻ると再び使われる（`test_reenterRange`）。
- `forge test --offline`全体は29個通過である（このフォルダにはこの講義のテストだけを添付した）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールやライブラリのバージョンが変わるとガスが変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Uniswap v3 Coreホワイトペーパー | Hayden Adams、Noah Zinsmeister、Moody Salem、River Keefer、Dan Robinson、2021年3月。2節の最初の文（集中流動性の定義）、2節の範囲の外の段落、5.2節 Geometric Mean Price Oracle、6.1節 ティックの価格1.0001^i（式6.1）、6.2節 Table 1 Global State（`uint128 liquidity`、`uint160 sqrtPriceX96`）、6.2.1節（プールが記録する二つの値Lと√P）、6.3.1節 Crossing a Tick | 2026-10-21 |
| v3の手数料の等級 | 手数料が0.30%に固定されていない。ホワイトペーパーの最初にサポートする等級は0.05%、0.30%、1% | 2026-10-21 |
| `sqrtPriceX96` | 名前のX96は、√価格に2の96乗を掛けて整数で入れるという印（整数64ビット・小数96ビット、Q64.96の形）。ホワイトペーパーの本文に「Q64.96」という言葉はなく、Table 1の変数名だけがある | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0、`utils/math/Math.sol` mulDiv・mul512 | 2026-10-21 |
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| テストのガス | test_rangeAmounts 14,522 / test_deeperInRange 61,885 / test_swapDown 78,567 / test_exitRange 83,060 / test_lossAmplified 250,456 / test_mulDivFullPrecision 130,450 / ファズ μ 4,073 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 利息の計算式と倍率の掛け算 | [第197講](../../part13/lecture197/) |
| 清算のときに薄いプールに担保を売ること | [第198講](../../part13/lecture198/)、[第199講](../../part13/lecture199/) |
| 複数のプール・複数のオラクルを混ぜる価格の出どころ | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| ティックの横断・複数のポジションの合算・手数料の取り分の分配 | 付録（ホワイトペーパーの原文） |
| 範囲のポジションで稼ぐ手数料の出どころ | [第202講](../../part13/lecture202/)、[第203講](../../part13/lecture203/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
