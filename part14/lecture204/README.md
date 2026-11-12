# 第204講 価格フィードの統合と検証

第14部 オラクル・クロスチェーン・ガバナンス・第56章 オラクルの統合

[← 第203講](../../part13/lecture203/) | [第14部 目次](../) | [第205講 →](../../part14/lecture205/)

## この講義の問い

チェーンの外の価格は、どんな形でチェーンに入ってくるのか。その値を読むとき、何を確かめるのか。Marketに付けるとき、Marketのコードを直すべきなのか。

## 実習資料

### 準備

通しプロジェクトMarketの第53章の終わりのバージョンから始める。Marketのコード（`src/`）はそのままにし、価格フィードとアダプターはテストのフォルダ`test/oracle/`にだけ置く。依存はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`lib/`）である。anvilも外部への接続も使わず、forgeのテストの中だけで動く。実在するフィードのアドレスやオラクルサービスの鍵は使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka |
| [code/src/Market.sol](code/src/Market.sol) | Marketの本体（第53章の終わりのバージョン、この講義では変えない）。`priceOf`、`setPriceFeed` |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | 価格の出どころのインターフェース`IPriceFeed`とMarketの型 |
| [code/src/IMarket.sol](code/src/IMarket.sol)、[code/src/MarketMath.sol](code/src/MarketMath.sol)、[code/src/MockToken.sol](code/src/MockToken.sol) | Marketのインターフェース、計算のライブラリ、テスト用のトークン |
| [code/test/oracle/IAggregatorV3.sol](code/test/oracle/IAggregatorV3.sol) | 押し込むタイプの価格フィードの関数の形（公式ドキュメントのAPIの関数名・戻り値の順番） |
| [code/test/oracle/RoundAggregator.sol](code/test/oracle/RoundAggregator.sol) | テスト用のフィード。答えを書くたびにラウンドの番号を上げて時刻を書く、終わっていないラウンドのまね`setRound` |
| [code/test/oracle/RoundFeed.sol](code/test/oracle/RoundFeed.sol) | フィードをMarketの価格の出どころにつなぐアダプター。0以下の答え、終わっていないラウンド、古い答えをリバートし、桁数を10の18乗に合わせる |
| [code/test/oracle/Base56.sol](code/test/oracle/Base56.sol) | テスト共通の準備（aliceがCOL 1000を預けてUSD 700を借りる、bobがUSD 1000を預ける） |
| [code/test/oracle/Feed204.t.sol](code/test/oracle/Feed204.t.sol) | Feed204Testの六つ |
| [code/test/](code/test/)の残り | 前の講義までに積み上がったMarketのテストと、テスト用の出どころ`TwapFeed`、プール`amm/` |

### 実行結果

`forge test --offline --match-contract Feed204Test -vv`（ガス記録の比較を切った状態）：

```
Ran 6 tests for test/oracle/Feed204.t.sol:Feed204Test
[PASS] test_castWraps() (gas: 338)
[PASS] test_decimalsScale() (gas: 1175264)
[PASS] test_minOutFromFeed() (gas: 2173108)
Logs:
  pool spot after sale 592125909653428705
  quote for 100 COL 58585646350817877100
  minOut from feed 99000000000000000000

[PASS] test_pushedPriceNoLag() (gas: 532585)
[PASS] test_rejectsIncompleteRound() (gas: 60882)
[PASS] test_rejectsNonPositive() (gas: 366929)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

テストごとに確かめたこと：

| テスト | 結果 |
|---|---|
| test_rejectsNonPositive | 答えが0ならborrowが`BadAnswer(0)`、答えが−1ならpriceOfが`BadAnswer(-1)`。そのあいだもrepay 100は成功し、借金700 → 600 |
| test_rejectsIncompleteRound | 答え1.0、書かれた時刻0のラウンドで`IncompleteRound(3)`（コンストラクタ1、setUp 2、setRound 3） |
| test_castWraps | int256の−1をuint256に変えると、リバートせずに`type(uint256).max` |
| test_decimalsScale | 桁数8の答え1e8と桁数18の答え1e18が、どちらも1e18 |
| test_pushedPriceNoLag | 1.0のとき上限750。0.85を書いた同じブロックでpriceOf 0.85、清算ライン680（借金700）、carolが350を清算したあとaliceの借金350 |
| test_minOutFromFeed | COL・USDが10,000ずつ入ったプール（手数料0.3%）でCOLを3,000売ったあと、プールの価格は約0.5921。COL 100の見積もり約58.59が、フィードの値で決めた最小量99より小さく、`Slippage`でリバート |

### 試すときの注意

- 確かめる順番が大事である。符号を先に見て、0より大きいときだけuint256に変える。逆にすると−1が2の256乗 − 1になり、「0より大きい」の検査を通る。
- フィードの桁数を18と思い込んで8桁の答えを読むと値が10の10乗倍小さくなり、逆に読むと10の10乗倍大きくなる。
- RoundFeedは、最後の答えを30分の窓全体で同じ値とみなして累積の合計を返す。だからMarketが出す平均は最後の答えと同じになる。
- 前のラウンドを番号でさかのぼって読まない。公式ドキュメントに、ラウンドの番号は順番に増えないと書かれている。
- Marketの`foundry.toml`はガス記録の比較（`gas_snapshot_check = true`）をオンにしてある。リポジトリにガス記録のフォルダ（`snapshots/`）を入れていないので、`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`をつけて実行する。
- テストの桁数8、答え1.0・0.85・0・−1、maxAge 4,200秒、プールの大きさと売却量はテストが決めた数字である。実在するフィードの値ではない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンや公式ドキュメントが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30 | 2026-10-21 |
| Feed204Testのガス | castWraps 338 / decimalsScale 1,175,264 / minOutFromFeed 2,173,108 / pushedPriceNoLag 532,585 / rejectsIncompleteRound 60,882 / rejectsNonPositive 366,929 | 2026-10-21 |
| 公式ドキュメントの原文 | latestRoundDataの戻り値五つ、answeredInRoundはDeprecated、decimals、「roundId is NOT incremental」、書かれた時刻0は終わっていないラウンド | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ハートビート・偏差のしきい値と古い値（maxAgeの選び方） | [第205講](../../part14/lecture205/) |
| 複数のフィードの集約とフォールバック | [第207講](../../part14/lecture207/) |
| プールの持ち分トークンの公正な価格の公式 | 付録（原文） |
| フィード側のノードのネットワークが値を集める方式 | 付録（原文） |
| アダプターをsrcに置くかどうか | [第270講](../../part21/lecture270/)、[第271講](../../part21/lecture271/)、[第272講](../../part21/lecture272/) |
| L2シーケンサーの稼働確認 | [第205講](../../part14/lecture205/)（データの行） |

出典と参考資料は[reference.md](reference.md)にまとめた。
