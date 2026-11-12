# 第205講 ハートビート・偏差のしきい値・ステイルの処理

第14部 オラクル・クロスチェーン・ガバナンス・第56章 オラクルの統合

[← 第204講](../../part14/lecture204/) | [第14部 目次](../) | [第206講 →](../../part14/lecture206/)

## この講義の問い

フィードはいつ新しく書かれるのか。書かれないあいだ、その値はどれくらいずれうるのか。最後の値が古くなるとコントラクトは何をし、そのあいだ何が続けてできなければならないのか。

## 実習資料

### 準備

第204講と同じMarketのコピー（第53章の終わりのバージョンのMarket + テストのフォルダの価格フィード・アダプター）から始める。この講義で足したファイルはテスト`test/oracle/Stale205.t.sol`一つである。アダプターRoundFeedのmaxAgeの行は、第204講のファイルにすでにある。Marketのコードは変えない。依存はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`lib/`）である。anvilも外部への接続も使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka |
| [code/src/Market.sol](code/src/Market.sol) | Marketの本体（第53章の終わりのバージョン、変えない） |
| [code/test/oracle/RoundFeed.sol](code/test/oracle/RoundFeed.sol) | アダプター。最後の答えがmaxAge秒より古ければ`StaleRound`でリバート |
| [code/test/oracle/RoundAggregator.sol](code/test/oracle/RoundAggregator.sol) | テスト用のフィード |
| [code/test/oracle/Base56.sol](code/test/oracle/Base56.sol) | テスト共通の準備（aliceがCOL 1000を預けてUSD 700を借りる、bobがUSD 1000を預ける） |
| [code/test/oracle/Stale205.t.sol](code/test/oracle/Stale205.t.sol) | Stale205Testの四つ。`_simulate`は、外の価格1.0 → 0.9（60分、1分ごと）を偏差のしきい値・ハートビートでフィードに書くまね |
| [code/src/](code/src/)、[code/test/](code/test/)の残り | Marketの残りのソースと、前の講義までに積み上がったテスト |

### 実行結果

`forge test --offline --match-contract Stale205Test -vv`（ガス記録の比較を切った状態）：

```
Ran 4 tests for test/oracle/Stale205.t.sol:Stale205Test
[PASS] test_deviationLag() (gas: 4908468)
Logs:
  d=50bps rounds 20 max gap bps 36
    feed at 60min 900000000000000000 30min average at 60min 927500000000000000
  d=200bps rounds 5 max gap bps 199
    feed at 60min 900000000000000000 30min average at 60min 936000000000000000

[PASS] test_gapDownStillUnderwater() (gas: 513600)
[PASS] test_maxAgeBoundary() (gas: 61751)
[PASS] test_staleStopsBorrowNotRepay() (gas: 668649)
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

`d`は偏差のしきい値（bps、1万分の1）である。60分のあいだに外の価格が1.0から0.9へ均等に下がるとき：

| | 偏差のしきい値0.5% | 偏差のしきい値2% |
|---|---|---|
| 60分のあいだに書かれた回数 | 20回 | 5回 |
| フィードと外の価格のいちばん大きな差 | 0.36% | 1.99% |
| 60分目のフィードの値 | 0.9 | 0.9 |
| 同じ階段を30分平均した値 | 0.9275 | 0.936 |

残りのテスト：

| テスト | 結果 |
|---|---|
| test_gapDownStillUnderwater | 1.0 → 0.5を一度に書くと、同じブロックでpriceOf 0.5、清算ライン400、担保の値500 < 借金700。carolが700を清算してUSD 476.190477を払い、COL 1000を受け取る。残った借金223.809523を消し、bobの持ち分は1000 → 776.190477 |
| test_maxAgeBoundary | maxAge 4,200秒。4,200秒目は使える、4,201秒目は`StaleRound` |
| test_staleStopsBorrowNotRepay | 最後の答えが2時間前なら、borrow・担保の引き出し・liquidateが`StaleRound`。repay 100は成功（借金600）、bobの担保ではないUSD 300の引き出しも成功。新しい答えを書いたあとborrow 50が成功（借金650） |

### 試すときの注意

- フィードは、書く取引が入ってきたときにだけ変わる。取引が途切れると、`latestRoundData`はエラーなしに最後の答えをそのまま返し、`updatedAt`だけが昔の時刻のまま残る。answerだけを受け取ってupdatedAtを捨てると、何時間前の値なのかわからない。
- maxAgeをハートビートとまったく同じ（3,600秒）にすると、正常なフィードもハートビートのたびに少しずつ止まる。長すぎる（86,400秒）と、フィードが止まってから1日のあいだ古い価格で貸すことになる。テストの4,200秒は、ハートビート1時間に余裕10分を足した値である。
- 上限75%、清算ライン80%なら、上限まで借りたアカウントは約6.25%の下落（0.75 ÷ 0.80）で清算ラインに届く。偏差のしきい値がこれより大きいと、このすき間全体がフィードの誤差の中に入る。
- すでに階段状に書かれるフィードの値の上に30分平均をさらにかぶせると、遅れがもう一度積み重なる。
- ハートビート1時間、偏差のしきい値0.5%・2%、maxAge 4,200秒は講義用の設計値である。実在するフィードの値はフィードごとに違う。
- L2では、シーケンサーが止まっていたあいだを別に確かめる（シーケンサーの稼働フィード）。この実習にはない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンや公式ドキュメントが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30 | 2026-10-21 |
| Stale205Testのガス | deviationLag 4,908,468 / gapDownStillUnderwater 513,600 / maxAgeBoundary 61,751 / staleStopsBorrowNotRepay 668,649 | 2026-10-21 |
| 公式ドキュメントの原文 | 構造の概要のDeviation Threshold・Heartbeat Threshold、フィードの選び方のcircuit breakersと単一の出どころのフィードのMUSTの文 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 実在するフィードのハートビート・偏差の値 | 付録のデータシート |
| L2シーケンサーの稼働確認 | 付録（原文） |
| 古い値が来ていないかを見張る警報 | [第238講](../../part18/lecture238/) |
| フィード一つが止まったときにほかの出どころに切り替えること | [第207講](../../part14/lecture207/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
