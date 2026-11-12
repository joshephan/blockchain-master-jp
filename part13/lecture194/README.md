# 第194講 定積の公式と価格の決まり方

第13部 DeFi・第52章 AMM

[← 第193講](../../part12/lecture193/) | [第13部 目次](../) | [第195講 →](../../part13/lecture195/)

## この講義の問い

トークンを交換してくれるコントラクトは、価格をどこから持ってくるのか。同じプールで一度にたくさん交換すると、何が変わるのか。小数のない機械で、割り算が捨てた分は誰のものになるのか。Marketはこの価格を担保の価値に使うべきか。

## 実習資料

### 準備

講義用のおもちゃのプールToyAmm（定積のプール、実在するプロトコルのコードではない）と、通しプロジェクトMarketのデモ用コピーの二つのプロジェクトを使う。ToyAmmにはforge-std（1.17.0）とOpenZeppelin Contracts 5.4.0（`Math.mulDiv`）が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。Marketのコピーはソースを変えず、確認テスト`Amm52.t.sol`と、そのテストが使うおもちゃのコピー（`test/amm/`）だけを足した。デプロイのデモはローカルのanvil一つで、anvilの既定のテスト用の鍵0番だけで行う。

### コード

| ファイル | 内容 |
|---|---|
| [code/amm/foundry.toml](code/amm/foundry.toml) | ビルド設定（via-IR、optimizerオン、OpenZeppelinのremapping、fuzz runs 256 seed 0x2a） |
| [code/amm/src/ToyErc20.sol](code/amm/src/ToyErc20.sol) | テスト用のトークンToyErc20・ToyToken（桁数を指定）・FeeToken（移すときに1%をバーン） |
| [code/amm/src/ToyAmm.sol](code/amm/src/ToyAmm.sol) | 定積のプール（LPトークンを兼ねる）。getAmountOutは切り捨て、getAmountInは切り上げ、swapの最後の積の確認 |
| [code/amm/test/Amm194.t.sol](code/amm/test/Amm194.t.sol) | 価格への影響の表、最小量、余り、桁数、手数料トークン、ファズ二つなどテスト11個 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのコピーのビルド設定（OpenZeppelinのremappingを追加） |
| [code/market/src/](code/market/src/) | Marketのソース（基準のバージョンのまま） |
| [code/market/test/Amm52.t.sol](code/market/test/Amm52.t.sol) | 資産ごとに金額が別々に記録されるかを確かめるテスト二つ |
| [code/market/test/amm/](code/market/test/amm/) | 確認テストが使うToyAmm・ToyErc20のコピー |
| [code/market/test/](code/market/test/) | Marketの基準のバージョンのテスト全体 |

### 実行結果

`forge test --offline --match-contract Amm194Test -vv`（11個通過）：

```
[PASS] testFuzz_kNeverDecreases(uint256) (runs: 256, μ: 206865, ~: 208089)
[PASS] testFuzz_roundTripNeverProfits(uint256) (runs: 256, μ: 312607, ~: 312895)
[PASS] test_decimalsSkewPrice() (gas: 406851)
Logs:
  raw 1000000
  adjusted 1000000000000000000
[PASS] test_dustGetsZero() (gas: 34986)
Logs:
  1 wei -> 0
  1000 wei -> 996
[PASS] test_feeTokenCountedByBalance() (gas: 610415)
Logs:
  reserve0 after add 990000000000000000000
  out for 100 sent 90661089388014913158
  quote for 99 90661089388014913158
[PASS] test_minOutReverts() (gas: 158317)
[PASS] test_priceImpactTable() (gas: 61865)
Logs:
  1 996006981039903216 996006981039903216
  10 9871580343970612988 987158034397061298
  100 90661089388014913158 906610893880149131
  500 332665999332665999332 665331998665331998
  1000 499248873309964947421 499248873309964947
[PASS] test_roundingFavorsPool() (gas: 54981)
Logs:
  need 99198694986057072316
  got 90000000000000000000
  got with need-1 89999999999999999999
[PASS] test_spotDivideFirst() (gas: 398844)
Logs:
  mul first 1500000000000000000
  div first 1000000000000000000
[PASS] test_swapNoFee() (gas: 382540)
Logs:
  no fee out 90909090909090909090
[PASS] test_swapWithFee() (gas: 227790)
```

1000/1000のプール（手数料0.3%）にAを100入れた交換の前後：

| | 交換の前 | 交換のあと |
|---|---|---|
| 残高 A / B | 1000 / 1000 | 1100 / 909.338… |
| 受け取ったB | | 90.661089388014913158 |
| spotPrice | 1.0 | 0.826671736919986442 |
| 積k | 1e42 | 1.0002728…e42（+0.027%） |

手数料がなければ、同じ交換で90.909090909090909090を受け取る。差し引いた0.3%はプールに残り、積kが増える。

入れる量ごとの受け取る量（同じ1000/1000のプール）：

| 入れるA | 受け取るB | 1個あたり |
|---|---|---|
| 1 | 0.996006981039903216 | 0.996 |
| 10 | 9.871580343970612988 | 0.987 |
| 100 | 90.661089388014913158 | 0.907 |
| 500 | 332.665999332665999332 | 0.665 |
| 1000 | 499.248873309964947421 | 0.499 |

ローカルのanvilでトークン二つとプール（手数料30）をデプロイし、1000/1000を入れたあとcastで読んだ値：

```
A    0x5FbDB2315678afecb367f032d93F642f64180aa3
B    0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
pool 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
$ cast send $P "addLiquidity(uint256,uint256)" 1000ether 1000ether
gasUsed              187569
status               1 (success)
$ cast call $P "reserve0()(uint256)"
1000000000000000000000 [1e21]
$ cast call $P "reserve1()(uint256)"
1000000000000000000000 [1e21]
$ cast call $P "spotPrice()(uint256)"
1000000000000000000 [1e18]
$ cast call $P "quote(address,uint256)(uint256)" $A 100ether
90661089388014913158 [9.066e19]
```

最小量91を書いた交換は`Slippage`でリバートする（エラーデータの16進数は省略）。割り込んだ取引がなくても、手数料のせいで90.66 < 91である。

```
$ cast send $P "swap(address,uint256,uint256)" $A 100ether 91ether
Error: Failed to estimate gas: … execution reverted: custom error 0x2746152a: …
Slippage(90661089388014913158 [9.066e19], 91000000000000000000 [9.1e19])
```

最小量90で交換してから読み直すと、同じA 100の見積もりが90.66から75.57に下がる。変わったのは残高二つだけである。

```
$ cast send $P "swap(address,uint256,uint256)" $A 100ether 90ether
gasUsed              69118
status               1 (success)
$ cast call $P "reserve0()(uint256)"
1100000000000000000000 [1.1e21]
$ cast call $P "reserve1()(uint256)"
909338910611985086842 [9.093e20]
$ cast call $P "spotPrice()(uint256)"
826671736919986442 [8.266e17]
$ cast call $P "quote(address,uint256)(uint256)" $A 100ether
75569800273414114493 [7.556e19]
```

Marketのコピーで`forge test --offline --match-test test_amountsStayPerAsset -vv`。18桁のトークン100個はtotalDeposits 100e18、6桁のトークン100個は100e6と、資産ごとに別々に記録される。コピー全体は41スイート113個（基準のバージョン111 + 確認2）が通過する。

```
[PASS] test_amountsStayPerAsset() (gas: 1807313)
Suite result: ok. 1 passed; 0 failed; 0 skipped
```

Marketのソースには価格を読む行がない。

```
$ grep -n "price\|oracle\|reserve\|swap" src/*.sol | wc -l
0
```

この結果から書いた、価格の出どころの判断記録：

| 問い | 見たもの | 決定 | テスト |
|---|---|---|---|
| 担保の価値をプールの価格で決めるか | プールの価格はその瞬間の残高の比率。Aを1000入れる交換1回で1 → 0.25付近、桁数の違うトークンは残高の比率が10の12乗倍ずれる | 即時の価格は使わない。使うときは時間加重平均（TWAP）、桁数の補正は資産ごと。今のバージョンには貸す行がないので、価格を読む行は入れない | Amm194Test（test_priceImpactTable、test_decimalsSkewPrice）、Amm52Test:test_amountsStayPerAsset |

### 試すときの注意

- 受け取る量（getAmountOut）は切り捨て、入れる量（getAmountIn）は`Math.mulDiv(..., Math.Rounding.Ceil)`で切り上げである。切り上げで求めた99.198694986057072316を入れるとちょうどBを90受け取り、1 wei少なく入れると1 wei足りない。
- 1 weiを入れると0を受け取り、入れた1 weiはプールの残高に残る。価格を計算するときに割り算を先にすると、A 1000 / B 1500のプールで1.5が1.0になる。
- 18桁のトークンと6桁のトークンが1000個ずつのプールのspotPriceは1e6（1e18倍率で0.000000000001）である。10の12乗を掛けて補正してはじめて1.0になる。型は倍率を知らない。
- ToyAmmは受け取った量を引数で信じず、残高の差で数える。1%の手数料トークンを1000入れると、reserve0は990である。
- ファズテストはfoundry.tomlの`[fuzz] runs = 256`、`seed = "0x2a"`で固定してある。
- Marketのコピーのテストは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガス記録の照合を切って実行する。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールやライブラリのバージョンが変わると、ガスとアドレスが変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Uniswap v2 Coreホワイトペーパー | Hayden Adams、Noah Zinsmeister、Dan Robinson、2020年3月。引用：1節（v1の説明、30bp）、2.2節（価格の累積）、2.2.1節（uint112）、3.2節（残高の比較） | 2026-10-21 |
| 取引手数料 | v1・v2は30bp（0.30%）。ほかのバージョン・プロトコルは異なる | 2026-10-21 |
| Foundry | forge・cast・anvil 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| OpenZeppelin | 5.4.0 Math.mulDiv(Rounding.Ceil) | 2026-10-21 |
| anvilのデモ | A `0x5FbDB2315678afecb367f032d93F642f64180aa3`、B `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、プール `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、addLiquidity 187,569ガス、swap 69,118ガス | 2026-10-21 |
| テスト | Amm194Test 11個通過（ファズ256回、seed 0x2a）、Marketのデモ用コピー41スイート113個通過、test_amountsStayPerAsset 1,807,313ガス | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| プールの持ち分の計算とインパーマネントロス | [第195講](../../part13/lecture195/) |
| 集中流動性と√価格の計算、mulDivの本体 | [第196講](../../part13/lecture196/) |
| 担保の価値の計算と資産ごとの桁数の補正 | [第197講](../../part13/lecture197/) |
| 清算のときに担保をプールに売る価格への影響 | [第198講](../../part13/lecture198/)、[第199講](../../part13/lecture199/) |
| 複数のオラクルと平均の窓の長さの選び方 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| 最初の提供者の持ち分と直接送ったトークン（sync・skim） | 付録 |

出典と参考資料は[reference.md](reference.md)にまとめた。
