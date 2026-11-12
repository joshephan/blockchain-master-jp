# 第201講 USTの崩壊の検証

第13部 DeFi・第54章 ステーブルコイン

[← 第200講](../../part13/lecture200/) | [第13部 目次](../) | [第202講 →](../../part13/lecture202/)

## この講義の問い

担保の金庫がないステーブルコインは、何で1ドルを守るのか。ふだんはなぜ持ちこたえ、償還が集中するとなぜ崩れるのか。コードにバグが一つもないのに崩れたなら、何を直すべきだったのか。同じ価格の下落で、担保型は何が違うのか。

## 実習資料

### 準備

講義用のアルゴリズム型ステーブルコインAlgoStable（1ドルを目標にするトークンAUSDと、対になるトークンVOLを交換するルールだけを組み直したおもちゃ）と、比較用の暗号資産担保型VaultUSDを使う。どちらも実在するプロトコルのコードではない。テストにはforge-std（1.17.0）が必要である（`lib/forge-std`）。anvilと外部への接続は使わない。価格を揺さぶる側のコードは作っておらず、前のブロックの価格で防がれることだけをテストで示す。テストの中の価格と市場価値はテストが決めたおもちゃの数字で、実際の事件の価格・発行量ではない。

### コード

| ファイル | 内容 |
|---|---|
| [code/src/AlgoStable.sol](code/src/AlgoStable.sol) | mintStable（VOLをバーンしてそのドルの値だけAUSD）、redeemStable（AUSDをバーンして1ドル相当のVOLを新しく発行、上限なし）。担保の金庫なし |
| [code/src/Toys.sol](code/src/Toys.sol) | テスト用のSimpleTokenと、前のブロックまでに書かれた値を返すToyOracle（`settledPrice`） |
| [code/src/VaultUSD.sol](code/src/VaultUSD.sol) | 比較用の暗号資産担保型の金庫（担保率150%） |
| [code/test/Algo201.t.sol](code/test/Algo201.t.sol) | 出発の状態、1ドルの下・上での裁定取引、償還の表二つ、同じブロックの価格、VaultUSDとの比較のテスト七つ |
| [code/foundry.toml](code/foundry.toml) | ビルド設定（via-IR、optimizerオン、fuzz seedを固定） |

### 実行結果

出発の状態：10番ブロックでVOL 1個 = 10ドル、aliceがVOLを6,000個受け取る。11番ブロックでaliceがVOL 5,000個をmintStableでバーンし、AUSD 50,000を受け取る。AUSD 50,000個の裏に残ったのはVOL 1,000個 × 10ドル = 1万ドルで、AlgoStableのアドレスのAUSD・VOLの残高は0である（`test_setup`）。

`forge test --offline --match-contract Algo201Test -vv`（七つ通過）：

```
[PASS] test_abovePegMint() (gas: 139292)
[PASS] test_belowPegRedeem() (gas: 146813)
[PASS] test_sameBlockPriceNotUsed() (gas: 233530)
[PASS] test_setup() (gas: 28094)
[PASS] test_spiralMarketValueFalling() (gas: 1474925)
Logs:
  round | VOL minted | VOL supply | VOL price(1/10000 USD)
  0 0 1000 100000
  1 500 1500 53333
  2 937 2437 26256
  3 1904 4341 11792
  4 4240 8581 4772
  5 10475 19057 1719
  6 29079 48137 544
  7 91814 139952 149
  8 333672 473624 35
  9 1411511 1885136 7
  10 7022680 8907817 1
  first round VOL 500 now worth cents 6
[PASS] test_spiralMarketValueFixed() (gas: 1475262)
Logs:
  round | VOL minted | VOL supply | VOL price(1/10000 USD)
  0 0 1000 100000
  1 500 1500 66666
  2 750 2250 44444
  3 1125 3375 29629
  4 1687 5062 19753
  5 2531 7593 13168
  6 3796 11390 8779
  7 5695 17085 5852
  8 8542 25628 3901
  9 12814 38443 2601
  10 19221 57665 1734
  first round VOL 500 now worth cents 8670
[PASS] test_vaultDoesNotMintCollateral() (gas: 353125)
Suite result: ok. 7 passed; 0 failed; 0 skipped
```

1ドル付近の裁定取引（外の市場の0.98・1.02ドルはテストが仮定した数字）：

| テスト | したこと | 結果 |
|---|---|---|
| test_belowPegRedeem | 0.98ドルで買ったAUSD 100個をredeemStable | VOL 10個（100ドル相当）、AUSDの供給50,000 → 49,900、VOLの供給1,000 → 1,010、2ドル残る |
| test_abovePegMint | VOL 10個をmintStableしてAUSD 100個を1.02ドルで売る | VOLの供給1,000 → 990、2ドル残る |

償還の表二つは、回ごとにAUSD 5,000を償還し、価格を次のブロックに書く。価格の列はログの1万分の1ドル単位である。

- test_spiralMarketValueFixed：市場がVOL全体につける値が1万ドルのままだと仮定。発行する量が回ごとに1.5倍、供給は最初の57倍（57,665）になり、価格は0.1734ドル。最初の回に受け取ったVOL 500個は86.70ドルになる。
- test_spiralMarketValueFalling：受け取ったVOLが売られ、市場価値が回ごとに20%減ると仮定。供給8,907,817、最初の回のVOL 500個の最後の値は6セント。
- 二つのテストとも、最後にAUSDの供給0、VOLの供給が最初の50倍を超えることを確かめる。あふれもリバートもなく、書かれたとおりに発行する。

同じブロックで書いた価格は使われない（`forge test --offline --match-test test_sameBlockPriceNotUsed -vvvv`、burn・mint・prankの行は省略）。12番ブロックで20ドルと書いても、同じブロックの発行は10ドルで数えてAUSD 100、13番ブロックになってはじめて20ドルで数えてAUSD 200である。

```
├─ [0] VM::roll(12)
├─ [33719] ToyOracle::update(20000000000000000000 [2e19])
├─ [73342] AlgoStable::mintStable(10000000000000000000 [1e19])
│   ├─ [4500] ToyOracle::settledPrice() [staticcall]
│   │   └─ ← [Return] 10000000000000000000 [1e19]
│   └─ ← [Return] 100000000000000000000 [1e20]
├─ [0] VM::roll(13)
├─ [56229] AlgoStable::mintStable(10000000000000000000 [1e19])
│   ├─ [4487] ToyOracle::settledPrice() [staticcall]
│   │   └─ ← [Return] 20000000000000000000 [2e19]
│   └─ ← [Return] 200000000000000000000 [2e20]
```

| 防ぐもの | 防げないもの |
|---|---|
| 1ブロックの中で揺さぶった価格での発行・償還 | 償還が集中するときに増える発行 |
| 借りる → 揺さぶる → 発行 → 返す、の1トランザクション | 正直に読んだ価格が下がること |
| test_sameBlockPriceNotUsed：同じブロック100、次のブロック200 | 償還の表：価格を書いて次のブロックで償還しても57,665個・0.1734ドル |

同じ価格の下落でのVaultUSDとの比較（`test_vaultDoesNotMintCollateral`：COL 150個でVUSD 100を発行したあとCOLの価格0.6、担保の値90 < 借金100、COLの供給150のまま）：

| | VaultUSD | AlgoStable |
|---|---|---|
| 価格が下がると | 担保の値が借金を下回る（90 < 100） | 償還ごとにVOLをさらに発行 |
| 担保トークンの数 | 150のまま | 1,000 → 57,665 |
| 崩れる道 | 担保の値が借金より速く下がるとき | 償還が集中するとき |

通しプロジェクトMarketのpriceOfは、価格の出どころの累積の合計二つ（今、30分前）で30分平均を直接出す。同じブロックで書いた値は0秒間あった値なので、平均に入らない。

```solidity
function priceOf(address asset) public view returns (uint256) {
    IPriceFeed feed = priceConfig[asset].feed;
    if (address(feed) == address(0)) revert NoPriceFeed(asset);
    return (feed.cumulativePrice(0) - feed.cumulativePrice(TWAP_WINDOW)) / TWAP_WINDOW;
}
```

### 試すときの注意

- AlgoStableには保存の欄がない（三つともimmutable）。VOLを預かっておかずにバーンするので、AUSDの裏にあるのは市場がVOLにつける値だけである。
- redeemStableは誰でも呼べ、発行する量に上限がない。価格が半分になると発行する量は2倍になる。デプロイのあとでは、この上限を入れる道がコードの中にない。
- ToyOracleは、このブロックで最初に書くときにその前の値をprevPriceに移し、settledPriceは前のブロックで書いた値だけを返す。
- おもちゃと事件の対応：AlgoStableはUST 1個と1ドル相当のLUNAを交換していたチェーン内の機能、VOLはLUNAに当たる。Terraは自分のチェーンのトークンで、イーサリアムのトークンではない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。おもちゃの値はテストが決めた数字で、実際の事件の値ではない。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka | 2026-10-21 |
| おもちゃの値 | VOLは最初10ドル、aliceのVOL 6,000個のうち5,000個 → AUSD 50,000、残ったVOL 1,000個、外の市場の仮定0.98・1.02ドル | 2026-10-21 |
| 償還の表の仮定 | VOLの市場価値1万ドルで固定 / 回ごとに20%減少、回ごとにAUSD 5,000を償還、10回 | 2026-10-21 |
| VaultUSDの値 | 担保率150%、COL 150個（1ドル） → VUSD 100、価格0.6 | 2026-10-21 |
| テストのガス | abovePegMint 139,292 / belowPegRedeem 146,813 / sameBlockPriceNotUsed 233,530 / setup 28,094 / spiralMarketValueFalling 1,474,925 / spiralMarketValueFixed 1,475,262 / vaultDoesNotMintCollateral 353,125 | 2026-10-21 |
| Marketのバージョン | 連鎖清算まで入ったバージョン（テスト136個、ランタイム9,006バイト）、priceOf 504行目、TWAP_WINDOW 30分 | 2026-10-21 |
| 事件の年月 | Terra UST 2022年5月 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| アルゴリズム型ステーブルコインへの攻撃（フラッシュローンの講義から移した） | この講義で扱う |
| アルゴリズム型ステーブルコインと経済設計の崩壊（経済的攻撃の講義から移した） | この講義で扱う |
| 高い預け入れの利息がどこから来たのか | [第202講](../../part13/lecture202/)、[第203講](../../part13/lecture203/) |
| オラクルの設計と時間平均 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| 連鎖清算と担保型の崩壊 | [第199講](../../part13/lecture199/) |
| 事件を軸で分け直す | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| Terraチェーンの構造 | 扱わない |

出典と参考資料は[reference.md](reference.md)にまとめた。
