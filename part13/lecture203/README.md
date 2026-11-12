# 第203講 持続可能性の判定

第13部 DeFi・第55章 利回りの出どころを追う

[← 第202講](../../part13/lecture202/) | [第13部 目次](../) | [第204講 →](../../part14/lecture204/)

## この講義の問い

出どころを見つけた収益は、明日も1年後も出るのか。何を確かめれば、その判定をコードでできるのか。画面の年利回りは、何を仮定した数字なのか。

## 実習資料

### 準備

収益の出どころを分けたおもちゃ四つ（`Yield202.sol`）に判定のテスト`Judge203.t.sol`を足して使い、通しプロジェクトMarketのコピー（連鎖清算まで入ったバージョンのソースのまま、確認テスト`Yield55.t.sol`だけを足した）の支払い能力のテストも一緒に見る。おもちゃは実在する商品のコードではなく、パーセントはすべておもちゃの値である。二つのプロジェクトとも、forge-std（1.17.0）が必要である（`lib/forge-std`）。anvilと外部への接続は使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/yield/src/Yield202.sol](code/yield/src/Yield202.sol) | ToyToken（ownerがminterを変える）、LendPool202、FeePool202、Farm202（終わる時刻）、FixedYield202（`totalOwed`で約束した分の合計を数える） |
| [code/yield/test/Judge203.t.sol](code/yield/test/Judge203.t.sol) | 判定のテスト六つ（一人で預けた金庫、約束した分と金庫、先に引き出した人、返さない借り入れ、報酬の終わりと発行の権限、1年に引き延ばす） |
| [code/yield/foundry.toml](code/yield/foundry.toml) | ビルド設定（via-IR、optimizerオン） |
| [code/market/test/Yield55.t.sol](code/market/test/Yield55.t.sol) | Marketの確認テスト（`test_owedNeverAboveCash`を含む） |
| [code/market/test/Borrow.t.sol](code/market/test/Borrow.t.sol) | 借りるテスト（`test_solvencyTable`を含む） |
| [code/market/src/](code/market/src/) | Marketのソース（変えていない） |
| [code/market/test/](code/market/test/) | Marketの基準のバージョンのテスト全体 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |

### 実行結果

判定の問い三つ：① 払う側がい続けるか　② 約束した分の合計が金庫のトークンを超えないか　③ 画面の数字は、どんな期間をどう引き延ばした値か。

`forge test --offline --match-contract Judge203Test -vv`（六つ通過）：

```
[PASS] test_annualize() (gas: 44993)
[PASS] test_farmEndsAndMinterSeat() (gas: 364769)
[PASS] test_firstOutGetsAll() (gas: 502664)
[PASS] test_fixedYieldNoNextDepositor() (gas: 179475)
[PASS] test_lendBorrowerNotRepaid() (gas: 334370)
[PASS] test_owedVsCash() (gas: 517164)
Logs:
  day 0 owed 3000
  day 10 owed 3300
  day 20 owed 3600
  day 30 owed 3900
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

| テスト | 見たもの |
|---|---|
| test_fixedYieldNoNextDepositor | aliceが一人で1000を預けると、1日後にowedTo 1010、金庫1000。withdraw → `NoCash(1000, 1010)`。初日の利息10から払えない |
| test_owedVsCash | alice・bob・carolが同じ日に1000ずつ。約束した分の合計3000 → 3300 → 3600 → 3900（10日ごと）、金庫のトークンは3000のまま（`assertGt(v.totalOwed(), 3000)`） |
| test_firstOutGetsAll | 30日後にalice・bobが1300ずつ引き出すと、金庫に400。carolのwithdraw → `NoCash(400, 1300)` |
| test_lendBorrowerNotRepaid | 年10%、aliceが1000を預け、bobが500を借りて返さない。365日後にcash 500、aliceのwithdraw(1000) → NoCash、withdraw(500) → 500 |
| test_farmEndsAndMinterSeat | 毎秒1、終わる時刻100秒。200秒でclaim 100、1200秒でもpending 0・供給100。ownerがsetMinterで権限を持っていき1,000,000を発行すると供給1,000,100、そのあとFarm202のclaim → NotMinter |
| test_annualize | 1日0.1%を単利で引き延ばすと36.5%、毎日複利で引き延ばすと約44.03%、1時間0.1%を1年に引き延ばすと876% |

1年に引き延ばす二つの方法（1e18倍率、1e18 = 100%）：

| 引き延ばした期間 | 単利で引き延ばした値（APR） | 複利で引き延ばした値（APY） |
|---|---|---|
| 1日0.1% | 36.5% | 約44.03%（毎日複利） |
| 1時間0.1% | 876% | |
| 1日1%（FixedYield202） | 365% | |

四つの出どころと判定：

| 出どころ | ① 払う側がい続けるか | ② 約束した分の合計 ≤ 金庫 |
|---|---|---|
| 借りた人が払った利息 | 借りる人、返さないときに防ぐもの（担保と清算） | 返さなければ、金庫に残った分だけ |
| 取引した人が払った手数料 | 取引量 | 二つのトークンの個数が変わって戻ってくる |
| 新しく発行したトークン | 終わる時刻、上限、発行の権限を持つアドレス | トークンの値はチェーンの外 |
| あとから入ってきた人の預け入れ | 新しい預け入れが止まれば支払いも止まる | 約束した分の合計 > 金庫 |

Marketのコピーで`forge test --offline --match-test "test_owedNeverAboveCash|test_solvencyTable" -vv`。コピー全体は44スイート140個が通過する。

```
[PASS] test_owedNeverAboveCash() (gas: 484816)
[PASS] test_solvencyTable() (gas: 2301040)
```

- test_owedNeverAboveCash：借りる人なしでaliceが100、bobが300を預け、365日後にtotalDeposits 400 = Marketのトークン残高400、二人とも引き出すと帳簿0・金庫0
- test_solvencyTable：借りる人がいるとき、借り入れ・時間・返済の6回ごとに「金庫のトークン + 貸し出した借金 ≥ 預けた人が引き出す量」（借金は切り上げ、預けた持ち分は切り捨て）

### 試すときの注意

- 判定のテストは、新しい預け入れなしに時間だけを進める。約束した分の合計を数える関数と金庫のトークンをassertで並べると、支払いがいつ止まるかが見える。
- FixedYield202は書かれたとおりに実行される。withdrawを先に呼んだ人が多く受け取り、同じ日に同じ金額を預けた最後の人は1円も引き出せない。
- LendPool202には担保の確認がない（利息の流れだけを見せるおもちゃ）。Marketは担保と清算で返さない場合を防ぎ、回収できない借金は消したうえで、預けた人が持ち分に応じて分ける。
- 報酬トークンは、発行の権限を持つアドレスが誰かが判定の問いである。そのアドレスと鍵は、ソースではなくデプロイのトランザクションとストレージから読む。
- Marketのコピーのテストは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガス記録の照合を切って実行する。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。パーセントはすべておもちゃの値で、実際の商品の利回り・発行スケジュールではない。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30（`--offline`） | 2026-10-21 |
| おもちゃのテスト | Judge203Test 6個通過（ガス：annualize 44,993 / farmEndsAndMinterSeat 364,769 / firstOutGetsAll 502,664 / fixedYieldNoNextDepositor 179,475 / lendBorrowerNotRepaid 334,370 / owedVsCash 517,164） | 2026-10-21 |
| Marketのテスト | test_owedNeverAboveCash通過（ガス484,816）、test_solvencyTable通過（2,301,040）、全体44スイート140個通過 | 2026-10-21 |
| パーセント | 年10%、手数料0.3%、1日1%、1日0.1%、1時間0.1%、年5%はすべて講義用のおもちゃの値 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 報酬トークンを決めるガバナンス | [第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/)、[第215講](../../part14/lecture215/)、[第216講](../../part14/lecture216/) |
| 約束した分と金庫を比べる不変条件のテスト | [第256講](../../part20/lecture256/)、[第257講](../../part20/lecture257/)、[第258講](../../part20/lecture258/) |
| 事件を四つの出どころで分け直す | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| 設計ドキュメントに、収益の出どころ・約束した分・表示する数字の計算方法を書くこと | [第254講](../../part20/lecture254/) |
| チェーンの外の収入（現実の資産）をチェーンに載せる仕組み | 扱わない |
| 担保と清算、利率が借りた比率によって変わる仕組み | [第197講](../../part13/lecture197/)・[第198講](../../part13/lecture198/) |
| 手数料と、預けた二つのトークンの個数の変化 | [第195講](../../part13/lecture195/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
