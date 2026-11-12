# 第195講 インパーマネントロス

第13部 DeFi・第52章 AMM

[← 第194講](../../part13/lecture194/) | [第13部 目次](../) | [第196講 →](../../part13/lecture196/)

## この講義の問い

プールに二つのトークンを預けた人は、何を受け取り、何を失うのか。価格が上がるだけでも損が出るのか。その損は誰のものになるのか。Marketはプールの持ち分を受け取ってよいのか。

## 実習資料

### 準備

講義用のおもちゃのプールToyAmm（定積のプール、LPトークンを兼ねる、実在するプロトコルのコードではない）と、通しプロジェクトMarketのデモ用コピーを使う。ToyAmmにはforge-std（1.17.0）とOpenZeppelin Contracts 5.4.0が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。Marketのコピーはソースを変えず、確認テスト`Amm52.t.sol`とおもちゃのコピー（`test/amm/`）、OpenZeppelinのremapping 1行だけを足した。anvilは使わない。テストの中の外の価格（1、1.21、2、4、9）はテストが決めた数字で、相場ではない。

### コード

| ファイル | 内容 |
|---|---|
| [code/amm/src/ToyAmm.sol](code/amm/src/ToyAmm.sol) | 定積のプール。addLiquidity（最初の提供は√(in0 × in1)、そのあとは残高の比率）、removeLiquidity（持ち分の比率だけ二つのトークン） |
| [code/amm/src/ToyErc20.sol](code/amm/src/ToyErc20.sol) | テスト用のトークン |
| [code/amm/test/Il195.t.sol](code/amm/test/Il195.t.sol) | インパーマネントロス、損失の表、価格が戻るとき、手数料でkが大きくなること、手数料と損失の比較のテスト五つ |
| [code/amm/foundry.toml](code/amm/foundry.toml) | ビルド設定（via-IR、optimizerオン、OpenZeppelinのremapping、fuzz seedを固定） |
| [code/market/test/Amm52.t.sol](code/market/test/Amm52.t.sol) | LPトークンをMarketに預けて引き出す確認テスト（`test_lpTokenDepositsLikeAnyToken`）など二つ |
| [code/market/test/amm/](code/market/test/amm/) | 確認テストが使うToyAmm・ToyErc20のコピー |
| [code/market/src/](code/market/src/) | Marketのソース（基準のバージョンのまま） |
| [code/market/test/](code/market/test/) | Marketの基準のバージョンのテスト全体 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのコピーのビルド設定 |

### 実行結果

`forge test --offline --match-contract Il195Test -vv`（五つ通過）。金額は18桁の整数（1e18 = 1個）である。

```
[PASS] test_feesGrowK() (gas: 14920311)
Logs:
  reserves after 50 round trips 1027279043615680002700 1000000000000000000000
  k grow x1e6 1027279
  lp gets 1027279043615680002700 1000000000000000000000
[PASS] test_feesVersusLoss() (gas: 15027772)
Logs:
  pool price 3887940696173895043
  lp A, B 514411138515613421483 2000000000000000000000
  lp value / hold x1e6 811528
[PASS] test_impermanentLoss() (gas: 710346)
Logs:
  arb got A 500000000000000000000
  pool price 4000000000000000000
  lp A 500000000000000000000
  lp B 2000000000000000000000
  lp value in B 4000000000000000000000
  hold value in B 5000000000000000000000
  arb profit in B 1000000000000000000000
[PASS] test_lossTable() (gas: 2251636)
Logs:
  121 1209999999999999999 995475
  200 1999999999999999999 942809
  400 4000000000000000000 800000
  900 8999999999999999999 600000
[PASS] test_lossVanishesWhenPriceReturns() (gas: 861167)
Logs:
  back B 1000000000000000000000
  reserves 1000000000000000000000 1000000000000000000000
  lp gets 1000000000000000000000 1000000000000000000000
Suite result: ok. 5 passed; 0 failed; 0 skipped
```

持ち分の計算：最初の提供がA 1000、B 1000なら持ち分は√(1000 × 1000) = 1000。2回目の提供A 100、B 100は残高の10分の1なので持ち分100（合計1100）。持ち分100をバーンすると、その瞬間の残高の1100分の100であるA 100、B 100を受け取る。

手数料0の1000/1000のプールで外の価格が1から4になると、裁定取引がBを1000入れてAを500取り出し、プールはA 500 / B 2000（プールの価格4）になる（`test_impermanentLoss`）。

| | 持っている量 | 外の価格4で数えた値（B） |
|---|---|---|
| LPが持ち分を全部引き出す | A 500、B 2000 | 4000 |
| 持っているだけ（プールに入れない） | A 1000、B 1000 | 5000 |
| 差 | A −500、B +1000 | −1000（−20%） |

差の1000は裁定取引の取り分と同じである。プールにBを1000入れて受け取ったA 500を外で4で売ると2000になり、1000が残る。テストの最後の行`assertEq(holdValue - lpValue, arbProfit)`が通る。

`test_lossTable`の列は、外の価格 × 100 / 動いたあとのプールの価格（1e18 = 1） / LP ÷ 持っているだけ（× 1e6）である。毎回新しい1000/1000のプール、手数料0である。プールの価格の末尾の9は、整数の割り算が捨てた余りである。

| 外の価格 | LP ÷ 持っているだけ | インパーマネントロス |
|---|---|---|
| 1.21倍 | 0.995475 | −0.45% |
| 2倍 | 0.942809 | −5.7% |
| 4倍 | 0.8 | −20% |
| 9倍 | 0.6 | −40% |

外の価格がr倍のとき、LP ÷ 持っているだけ = 2√r / (1 + r)である（手数料0の定積のプール）。r = 4とr = 1/4がどちらも0.8なので、上がっても下がっても同じ倍率なら同じ損失である。

| いつ引き出すか | 受け取る量 | 持っているだけとの差 |
|---|---|---|
| 価格4で | A 500、B 2000 | −1000（価格4で計算） |
| 価格が1に戻ったあと | A 1000、B 1000 | 0 |

手数料0.3%のプール：

| プール | 1 → 4のあとのLP ÷ 持っているだけ | 条件 |
|---|---|---|
| 手数料0 | 0.8 | 往復なし、プールの価格4 |
| 手数料0.3% | 0.811528 | 往復50回（k 1.027279倍）、プールの価格3.888 |
| 差 | +1.15%p | 取引量・価格の変化はテストが決める |

Marketのコピーで`forge test --offline --match-test test_lpTokenDepositsLikeAnyToken -vv`。aliceがプールにA 1000、B 1000を入れてLP 1000を受け取り、管理者がLPトークンをaddAssetしたMarketに400を預ける。裁定取引でプールの価格が4になっても、Marketの帳簿のaliceの400はそのままで、withdraw 400のあとaliceはLP 1000を再び持つ。Marketは資産ごとに個数だけを数える。

```
[PASS] test_lpTokenDepositsLikeAnyToken() (gas: 2492382)
```

この結果から書いた、価格の出どころの判断記録：

| 問い | 見たもの | 決定 | テスト |
|---|---|---|---|
| プールの持ち分（LPトークン）を担保として受け取るか | LPトークンもERC-20なので、登録すれば預けて引き出せる。Marketは個数だけを数える。持ち分一つの価値は二つのトークンの価格によって変わり（インパーマネントロス）、残高で値をつけると即時の価格の問題がそのまま入ってくる | 価値で貸す機能ができたら、LPトークンは担保として登録しない | Il195Test:test_impermanentLoss、Amm52Test:test_lpTokenDepositsLikeAnyToken |

### 試すときの注意

- プールは外の価格を知らない。プールの価格と外の価格を合わせるのは誰かが呼ぶswap（裁定取引）で、プールの側から見ると特別なコードのないswap 1回である。
- インパーマネントロスは、LPが持ち分を引き出す瞬間に確定する。引き出したあとはプールの残高が動いても、受け取った量はそのままである。
- `test_feesVersusLoss`のプールの価格3.888は、手数料のせいで4に届かない状態で測った値である。
- Marketのコピーのテストは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガス記録の照合を切って実行する。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わるとガスが変わりうる。テストの価格はテストが決めた数字である。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| Il195Testのガス | feesGrowK 14,920,311 / feesVersusLoss 15,027,772 / impermanentLoss 710,346 / lossTable 2,251,636 / lossVanishesWhenPriceReturns 861,167 | 2026-10-21 |
| Amm52Testのガス | test_lpTokenDepositsLikeAnyToken 2,492,382 | 2026-10-21 |
| 外の価格 | 1、1.21、2、4、9はテストが決めた数字。実際の相場・見通しではない | 2026-10-21 |
| 手数料 | 0（損失のテスト）、0.3%（feeBps 30、手数料のテスト）。Uniswap v2ホワイトペーパーの30bpと同じ値を選んだ | 2026-10-21 |
| 損失の式 | 2√r / (1 + r)、手数料0の定積のプール | 2026-10-21 |
| 最初の提供の持ち分 | 入れた二つの量の幾何平均（Uniswap v2 Coreホワイトペーパー3.4節） | 2020-03 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 集中流動性で損失が大きくなる度合い | [第196講](../../part13/lecture196/) |
| プールの手数料がどこから来るのかと、持続可能かどうか | [第202講](../../part13/lecture202/)、[第203講](../../part13/lecture203/) |
| LPトークンの価値を残高で決めるときの操作 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| 裁定取引とブロックの順番 | [第224講](../../part16/lecture224/)、[第225講](../../part16/lecture225/)、[第226講](../../part16/lecture226/)、[第227講](../../part16/lecture227/)、[第228講](../../part16/lecture228/) |
| 担保のリストと上場の基準を担保の価値に使う | [第197講](../../part13/lecture197/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
