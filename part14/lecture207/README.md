# 第207講 複数のオラクルとフォールバックの設計

第14部 オラクル・クロスチェーン・ガバナンス・第56章 オラクルの統合

[← 第206講](../../part14/lecture206/) | [第14部 目次](../) | [第208講 →](../../part14/lecture208/)

## この講義の問い

出どころを複数使うと、何がよくなり何が悪くなるのか。主な出どころが止まると何に切り替わり、切り替わった値は信頼できるのか。出どころを変える権限は誰に置くのか。

## 実習資料

### 準備

第204講・第205講と同じMarketのコピー（第53章の終わりのバージョンのMarket + テストのフォルダの価格フィード・アダプター）から始める。この講義で足したファイルは`test/oracle/`の`MedianFeed.sol`、`FallbackFeed.sol`、`Multi207.t.sol`である。Marketのコードは変えない。依存はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`lib/`）である。anvilも外部への接続も使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka |
| [code/src/Market.sol](code/src/Market.sol) | Marketの本体（第53章の終わりのバージョン、変えない）。価格の出どころを変えたり消したりする関数なし |
| [code/test/oracle/MedianFeed.sol](code/test/oracle/MedianFeed.sol) | 三つの出どころの30分平均のうち中央値を出すアダプター。一つでもリバートすれば一緒にリバート、出どころはデプロイのときに決める |
| [code/test/oracle/FallbackFeed.sol](code/test/oracle/FallbackFeed.sol) | 主な出どころがリバートしたら予備の出どころを使うアダプター。二つが2%（`MAX_SPREAD_BPS` 200）より離れると`Diverged`、両方リバートすると`NoSource` |
| [code/test/oracle/Multi207.t.sol](code/test/oracle/Multi207.t.sol) | Multi207Testの七つ |
| [code/test/oracle/RoundFeed.sol](code/test/oracle/RoundFeed.sol)、[code/test/oracle/RoundAggregator.sol](code/test/oracle/RoundAggregator.sol)、[code/test/oracle/Base56.sol](code/test/oracle/Base56.sol) | 第204講のアダプター、テスト用のフィード、テスト共通の準備 |
| [code/test/Cascade199.t.sol](code/test/Cascade199.t.sol) | 時刻ごとにプールの価格を書くテスト用の`PoolFeed`と、連鎖清算のテスト |
| [code/src/](code/src/)、[code/test/](code/test/)の残り | Marketの残りのソースと、前の講義までに積み上がったテスト |

### 実行結果

`forge test --offline --match-contract Multi207Test -vv`（ガス記録の比較を切った状態）：

```
Ran 7 tests for test/oracle/Multi207.t.sol:Multi207Test
[PASS] test_fallbackDiverged() (gas: 5919119)
[PASS] test_fallbackNoSource() (gas: 5605198)
[PASS] test_fallbackUsesSpare() (gas: 5781654)
Logs:
  fallback price after 10min of 0.9 966666666666666666

[PASS] test_gasBySource() (gas: 21892267)
Logs:
  borrow gas RoundFeed 172817
  borrow gas TwapFeed 173723
  borrow gas MedianFeed 234113
  borrow gas FallbackFeed 214879

[PASS] test_medianIgnoresOneOutlier() (gas: 5924942)
[PASS] test_medianStopsIfOneStale() (gas: 5661773)
[PASS] test_sameUpstreamCountsOnce() (gas: 3091716)
Suite result: ok. 7 passed; 0 failed; 0 skipped
```

| 状況 | 結果 | テスト |
|---|---|---|
| 三つの出どころのうちcだけが16.0 | priceOf 1.0、aliceの上限750のまま。続いてbが1.01なら1.01 | test_medianIgnoresOneOutlier |
| 二つの出どころが同じフィードaを読み、aが16.0 | priceOf 16.0 | test_sameUpstreamCountsOnce |
| 2時間後にa・bだけ新しく書き、cは沈黙 | `StaleRound(t, 4200)`。中央値は三つそろってはじめて出す | test_medianStopsIfOneStale |
| 主な出どころが2時間沈黙、予備が0.9に変わって10分 | 予備に切り替わり、priceOf 0.9667（966,666,666,666,666,666） | test_fallbackUsesSpare |
| 主0.95、予備1.0 | borrowが`Diverged(0.95e18, 1e18)`、repay 100は成功 | test_fallbackDiverged |
| 主0.985（差1.5%） | priceOf 0.985 | test_fallbackDiverged |
| 主が沈黙 + 予備が停止 | `NoSource()` | test_fallbackNoSource |

借りるガス（aliceがborrow USD 10、同じテストの中で最初に呼ぶ値なのでコールドアクセスを含む）：

| 出どころの形 | ガス |
|---|---|
| RoundFeed（フィード一つ） | 172,817 |
| TwapFeed（30分平均） | 173,723 |
| MedianFeed（フィード三つ） | 234,113 |
| FallbackFeed（フィード + 予備） | 214,879 |

担保の資産10個がそれぞれ出どころを持つ場合を別に測った確認テストでは、RoundFeed 564,411、MedianFeed 1,177,371で、差は612,960（= 61,296 × 10）だった。資産一つなら203,222と264,518で、差は61,296である。

コピー全体の`forge test --offline`は48スイート156個が通過する（Marketの基準のバージョン136個 + 第53章のデモ3個 + 第56章17個）。

### 試すときの注意

- 中央値は間違った値一つには強くなるが、停止一つには弱くなる。三つのうち一つだけが古くなっても一緒に止まる。
- 出どころのアドレスが三つでも、同じところから値を受け取っていれば一つである。数えるのは、値を決めるところの数である。
- 離れ幅の上限2%は、主な出どころの偏差のしきい値とかみ合う。偏差のしきい値が2%のフィードを主な出どころに使うと、何事もない日にも`Diverged`が多い。
- 予備の出どころは、主な出どころが止まった日、つまりいちばん荒れた日に使われる。予備にプールの平均を使うと、そのプールの深さと、清算で売った担保がプールの価格を動かすことが一緒に入ってくる。プールの平均を使うなら、累積の合計の記録が30分の窓より長くなければならない。
- 上限の計算は、担保としてオンにした資産と借りた資産の価格だけを読む。出どころの形が重いと、その資産の数だけガスが増える。
- Marketと三つのアダプターのどれにも、出どころを変える関数がない。出どころを直す道は、新しい出どころを付けた新しい資産だけである。
- 出どころ三つ、離れ幅2%、maxAge 4,200秒、窓30分は講義用の設計値である。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30 | 2026-10-21 |
| Multi207Testのガス | fallbackDiverged 5,919,119 / fallbackNoSource 5,605,198 / fallbackUsesSpare 5,781,654 / gasBySource 21,892,267 / medianIgnoresOneOutlier 5,924,942 / medianStopsIfOneStale 5,661,773 / sameUpstreamCountsOnce 3,091,716 | 2026-10-21 |
| 借りるガス（出どころの形ごと） | RoundFeed 172,817 / TwapFeed 173,723 / MedianFeed 234,113 / FallbackFeed 214,879（同じテストの中で最初に呼ぶ値） | 2026-10-21 |
| 担保の資産10個の借りるガス | aliceがborrow USD 10：RoundFeed 564,411 / MedianFeed 1,177,371、差612,960。1個なら203,222 / 264,518、差61,296 | 2026-10-21 |
| デモ用コピー全体のテスト | 48スイート156個通過 | 2026-10-21 |
| Marketの監査範囲 | src四つ1,014 / 513行、セレクタ38、ハッシュの先頭4バイト`2fa6d798` | 2026-10-21 |
| 事件の年 | bZx 2020、Mango Markets 2022 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 出どころを変える鍵を縛ること（時間的な遅延・投票） | [第216講](../../part14/lecture216/) |
| オラクルの様式で実在するフィードを埋める | 付録のデータシート |
| 複数の出どころが互いに違う運営者かを確かめること | [第254講](../../part20/lecture254/)、[第255講](../../part20/lecture255/)、[第256講](../../part20/lecture256/) |
| 実在するプールの観測の欄（累積の合計の記録の長さ）の原文 | 付録（原文） |
| オラクルの失敗の事件の分け直し | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| アダプターをsrcに置いて作り直す | [第270講](../../part21/lecture270/)、[第271講](../../part21/lecture271/)、[第272講](../../part21/lecture272/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
