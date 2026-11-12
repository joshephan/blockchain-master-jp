# 第258講 テストスイートの構築

第20部 キャップストーンプロジェクト・第71章 検証と監査への対応

[← 第257講](../../part20/lecture257/) | [第20部 目次](../) | [第259講 →](../../part20/lecture259/)

## この講義の問い

要件のテストが全部通ったバージョンで、まだテストしていないものはどこで見つけるのか。カバレッジが全部埋まれば、テストは終わりなのか。

## 実習資料

### 準備

通しプロジェクトMarketのキャップストーンのバージョン（第257講のバージョン、テスト38）から始める。この講義でテスト31を加え（信頼の前提3、エラー一覧22、イベント2、ログで数え直す2、ドキュメント2）、`src/`にはNatSpecのドキュメントだけを埋める。実行コードは1行も変わらない。依存関係はforge-std 1.17.0（`lib/forge-std`）とOpenZeppelin Contracts 5.4.0（`lib/openzeppelin-contracts`）である。ドキュメントのテストがforgeの成果物（`out/`）を読むので、`foundry.toml`に`fs_permissions`がある。デモはすべてforgeのテストで、anvilは使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、`fs_permissions`（outの読み取り）、debugプロファイル |
| [code/abi/IMarket.json](code/abi/IMarket.json) | リポジトリに置いたABIファイル（関数25・イベント11・エラー21）。ciの最後の段階がビルドとdiff |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束（ABI）。イベント11・エラー21にnoticeを埋めた |
| [code/src/Market.sol](code/src/Market.sol) | レンディングマーケット。定数八つ・自動ゲッター四つにnotice、setGuardianに`@inheritdoc IMarket` |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息の曲線・丸めの計算ライブラリ |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | 共有する型、価格の出どころのインターフェース |
| [code/test/Trust.t.sol](code/test/Trust.t.sol) | 信頼の前提のテスト3（T-01 出どころの停止、T-01 平均の遅れの分ごとの表、T-03 同じブロック） |
| [code/test/Errors.t.sol](code/test/Errors.t.sol) | エラー22ごとに`test_err_<名前>`一つ、巻き戻しデータ全体（セレクタと引数）を照合 |
| [code/test/Events.t.sol](code/test/Events.t.sol) | イベント11の引数すべて（`vm.expectEmit`）、Repaidに出る返した量 |
| [code/test/Rebuild.t.sol](code/test/Rebuild.t.sol) | ログだけでUSDの預けた合計・借りた合計を数え直して状態と比べる（利率0、利率あり） |
| [code/test/Docs.t.sol](code/test/Docs.t.sol) | ABIの項目ごとにnoticeがあるかをrawMetadataで確認 |
| [code/test/Functional.t.sol](code/test/Functional.t.sol) | 機能要件F-01〜F-10 |
| [code/test/Safety.t.sol](code/test/Safety.t.sol) | 安全の要件S-01〜S-08 |
| [code/test/Access.t.sol](code/test/Access.t.sol) | 権限の要件A-01〜A-05 |
| [code/test/Ops.t.sol](code/test/Ops.t.sol) | 運用の要件O-01〜O-02 |
| [code/test/Interface.t.sol](code/test/Interface.t.sol) | 関数の数とインターフェースID |
| [code/test/Math.t.sol](code/test/Math.t.sol) | 計算の部品の曲線の値と丸めの方向 |
| [code/test/Layout.t.sol](code/test/Layout.t.sol) | ストレージの欄の地図どおりに置かれているかを`vm.load`で確認 |
| [code/test/Gas.t.sol](code/test/Gas.t.sol) | 測った呼び出し五つのガス |
| [code/test/Standards.t.sol](code/test/Standards.t.sol) | 標準の対照表の行ごとの確認 |
| [code/test/helpers/Base.sol](code/test/helpers/Base.sol) | テスト共用の土台（COL・USD、価格の出どころ二つ、前のバージョンと同じ場面） |
| [code/test/helpers/TwapFeed.sol](code/test/helpers/TwapFeed.sol) | テスト用の価格の出どころ（積み上がった価格の合計、`stop()`、権限のない`setPrice`） |
| [code/test/helpers/StdToken.sol](code/test/helpers/StdToken.sol) | テスト用の標準トークン |
| [code/test/helpers/OddTokens.sol](code/test/helpers/OddTokens.sol) | 標準と違う動きをするテスト用トークン |
| [code/test/helpers/HookToken.sol](code/test/helpers/HookToken.sol) | 移される瞬間にMarketの帳簿を読んで書き留めるテスト用トークン |
| [code/test/helpers/MultiSigAdmin.sol](code/test/helpers/MultiSigAdmin.sol) | テスト用のマルチシグ |
| [code/test/helpers/Accounts.sol](code/test/helpers/Accounts.sol) | テスト用のアカウントのコード二つ |

### 実行結果

テストを加える前のキャップストーンのバージョンの`bash ci.sh`の合計：

```
Ran 9 test suites: 38 tests passed, 0 failed, 0 skipped (38 total tests)
ci ok
```

`forge test --offline --match-contract TrustTest -vv`。COLの価格を1.0から0.3に一度に落とし、分ごとに30分平均、清算ライン（aliceがCOL 1000を担保、借金700）、100を返して受け取るCOLとそのCOLの0.3での価値を出力する：

```
[PASS] test_T01_feedStoppedRepayStillWorks() (gas: 443770)
[PASS] test_T01_twapLagsRealDrop() (gas: 1183851)
Logs:
  minute: 0
    price: 1.000000000000000000
    liquidation line: 800.000000000000000000
  minute: 5
    price: 0.883333333333333333
    liquidation line: 706.666666666666666400
  minute: 6
    price: 0.860000000000000000
    liquidation line: 688.000000000000000000
    seize per 100 repaid: 122.093023255813953488
    worth at 0.3: 36.627906976744186046
  minute: 10
    price: 0.766666666666666666
    liquidation line: 613.333333333333332800
    seize per 100 repaid: 136.956521739130434901
    worth at 0.3: 41.086956521739130470
  minute: 15
    price: 0.650000000000000000
    liquidation line: 520.000000000000000000
    seize per 100 repaid: 161.538461538461538461
    worth at 0.3: 48.461538461538461538
  minute: 20
    price: 0.533333333333333333
    liquidation line: 426.666666666666666400
    seize per 100 repaid: 196.875000000000000123
    worth at 0.3: 59.062500000000000036
  minute: 30
    price: 0.300000000000000000
    liquidation line: 240.000000000000000000
    seize per 100 repaid: 350.000000000000000000
    worth at 0.3: 105.000000000000000000

[PASS] test_T03_sameBlockSameIndex() (gas: 3656518)
Logs:
  debt after 1 second: 700000001
```

6分目に清算ライン（688）が借金700の下に下がる。そのとき清算すると、100を返して受け取るCOL 122.09の今の価値は36.63である。T-01の出どころの停止のテストの結果は次のとおりである。

| 呼び出し（COLの出どころの`stop()`のあと） | 結果 |
|---|---|
| alice borrow 1、COL withdraw 1 | `Stopped()` |
| carol liquidate、借金の消去 | `Stopped()` |
| alice repay 100 | 成功、借金600 |
| bobがUSD 300を引き出す（担保ではない） | 成功 |

`forge test --offline --match-contract ErrorsTest`（22通過）の巻き戻しデータの一部：

| テスト | 巻き戻しデータ |
|---|---|
| 上限1000に600を預けたあと401 | `SupplyCapExceeded(1000e6, 1001e6)`（400は入る、合計1000） |
| 1000を預けたマーケットで700が出ていったあと、daveが301を借りる | `InsufficientLiquidity(300e6, 301e6)` |
| 価格1.0でaliceを清算 | `NotLiquidatable(800e18, 700e18)` |
| 担保が残っているaliceの借金の消去 | `HasCollateral(1000e18)` |
| 担保としてオンにしていないUSDを清算で | `NotCollateral(USD)` |
| 金額0：deposit・withdraw・borrow・repay・liquidate | 五つとも`ZeroAmount()` |
| 借り入れを止めたUSDで借り入れ | `ActionPaused(USD, 2)` |

`SupplyCapExceeded`は、キャップストーンのバージョンのテスト38で一度も出なかったエラーである。

`forge test --offline --match-contract "EventsTest|RebuildTest" -vv`。0.3で借金699を全部返すと言っても、Liquidatedには実際に返した285.714286と受け取った担保1000が出て、`repay(USD, type(uint256).max)`のRepaidには返した量700が出る。ログだけで数え直したUSDの預けた合計と状態の欄：

```
[PASS] test_O01_logsMissInterest() (gas: 4237582)
Logs:
  deposits from logs: 984035210
  deposits from state: 985714283

[PASS] test_O01_logsRebuildTotalsNoInterest() (gas: 4245857)
Logs:
  deposits from logs: 985714286
  deposits from state: 985714285
  borrows from logs: 0
  borrows from state: 0
```

利率0なら差は1（持ち分で保存して切り捨てで取り出す）である。利率があると、積み上がった利息がどのイベントにもないので差が大きくなる。

ドキュメントのテスト（`forge test --offline --match-contract DocsTest`）を、ドキュメントを埋める前のバージョンに入れて最初に実行した結果：

```
[FAIL: vm.parseJsonKeys: key ".output.userdoc.events" must return exactly one JSON object] test_everyEventAndErrorHasNotice()
[FAIL: CLOSE_FACTOR()] test_everyFunctionHasNotice()
```

定数八つ・自動ゲッター四つ、イベント十一、エラー二十一にnoticeを埋めたあとも一つ残った：

```
[PASS] test_everyEventAndErrorHasNotice()
[FAIL: setGuardian(address)] test_everyFunctionHasNotice()
```

`setGuardian`に`/// @inheritdoc IMarket`の1行を付けて解決した。ドキュメントを埋める前とあとのビルド：

| 項目 | キャップストーンのバージョン | ドキュメントを埋めたバージョン |
|---|---|---|
| Market runtime / creation（バイト） | 8,739 / 9,070 | 8,739 / 9,070 |
| 実行コードの本体のsha256の先頭16桁 | `85ce365c848a7fc9` | `85ce365c848a7fc9` |
| 末尾のメタデータハッシュの先頭4バイト | `ef24c031` | `47ac4829` |
| 測った呼び出し五つのガス | 同じ | 同じ |

`forge coverage --offline --ir-minimum --report summary`のMarketの行：

| バージョン | Marketの行 | Marketの分岐 |
|---|---|---|
| キャップストーンのバージョン（テスト38） | 234/238 | 29/42 |
| テスト31を加えたバージョン（テスト69） | 234/238 | 41/42 |

テストを加える前に届かなかった分岐十三は、ほとんどがエラーの行だった（コンストラクターのZeroAddress、setGuardianの0アドレス、ZeroAmount五つ、SupplyCapExceeded、借り入れのInsufficientLiquidity、NotCollateral、NoDebt、LossExceedsDeposits、NotListed）。加えたあとも、lcovにはテストがあるのに0と数えた行が残る：

```
DA:65,0     _onlyAdmin();    // listAsset
DA:80,0     _onlyAdmin();    // setSupplyCap
DA:95,0     _onlyAdmin();    // unpause
DA:103,0    _onlyAdmin();    // setGuardian
BRDA:104,6,0,0   if (guardian_ == address(0)) revert ZeroAddress();
```

`LossExceedsDeposits`に届く道は一つだった。bobがUSD 1000を預け、aliceがCOL 2000を担保に1000を全部借りたあと（借りた比率100%、年100%）、30分後にCOLの平均価格を0にして借金を消す。`forge test --offline --match-test test_err_LossExceedsDeposits -vv`の巻き戻しは`LossExceedsDeposits(1000057078, 1000057077)`である（借金1,000.057078、預けた合計1,000.057077）。

テストを全部加えたあとの`bash ci.sh`（七つの段階、最後はABIファイルのdiff）：

```
Ran 14 test suites: 69 tests passed, 0 failed, 0 skipped (69 total tests)
ci ok
```

### 試すときの注意

- テストの一覧を取り出す場所は三つである。要件の表（25行、F-07がテスト二つなのでテスト26）、設計ドキュメント6節の信頼の前提（T-01〜T-09）、エラー一覧（IMarket 21 + 取り込んだSafeERC20 1 = 22）。テスト名は出どころの番号で始める（F・S・A・O、T、err）。
- エラーのテストはセレクタだけを見ず、引数まで照合する。セレクタだけを見ると、見当違いの値を比べても通る。
- `vm.warp`と権限のない`setPrice`で作った状態がチェーンで起こりうるかは、ツールは検査しない。テストごとに、その状態がチェーンで起こる道（出どころが止まる、価格が一度に落ちる、時間が流れる）をコメント1行で書いた。
- インデクサーが呼び出しの引数（699、最大値）で数えると、清算・返済の二か所で間違える。イベントの引数で数える。
- `vm.getRecordedLogs()`は巻き戻った呼び出しのログまで返す。ログで数え直すテストは、すべての呼び出しが成功する順番で書いた。
- ドキュメントのテストはnoticeがあるかだけを見る。`CLOSE_FACTOR`の値を60に変えてもDocsTestは通る。
- NatSpecだけを直すと、runtimeのサイズ、実行コードの本体のハッシュ、呼び出しのガスはそのままで、バイトコードの末尾のメタデータハッシュだけが変わる。監査するビルドは`47ac4829`として書いておく。
- インターフェースIDは関数のセレクタだけから作られる。イベント・エラーが変わったことはABIファイルのdiffが捕まえる。
- `--ir-minimum`のカバレッジが`_onlyAdmin();`の4行とsetGuardianの0アドレスの分岐を0と数える理由は確かめられなかった（観察のみ）。
- 平均価格0は`LossExceedsDeposits`のテスト一つにだけ入り、上限・清算・借金の消去のほかの行に入ったことはない。設計ドキュメント13節の最後に「テストに入れたことのない値」として書いた。

## 時効性のあるデータ

基準日時点の値。ツールやライブラリのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry・solc・ライブラリ | forge 1.8.3（commit cae51ad4）、solc 0.8.30、forge-std 1.17.0、OpenZeppelin Contracts 5.4.0 | 2026-10-21 |
| キャップストーンのバージョン（第257講のバージョン） | テスト38 / 0 / 38、runtime 8,739 / creation 9,070、末尾のメタデータハッシュ`ef24c031`、セレクタ38・イベント11・エラー22 | 2026-10-21 |
| テストスイートのバージョン（第258講のバージョン） | テスト69 / 0 / 69、runtime 8,739 / creation 9,070、ハッシュ`47ac4829`、実行コードの本体のsha256の先頭16桁`85ce365c848a7fc9`（二つのバージョンで同じ）、IMarket 142（68）・Market 421（328）行 | 2026-10-21 |
| カバレッジ（`--ir-minimum`） | 第257講のバージョンMarketの行234/238・分岐29/42、第258講のバージョン234/238・41/42 | 2026-10-21 |
| 測った呼び出し五つ（GasTest） | deposit 139,186・borrow 160,196・repay 63,348・withdraw 64,696・liquidate 235,771（二つのバージョンで同じ） | 2026-10-21 |
| ABIファイル | `abi/IMarket.json` 関数25・イベント11・エラー21、インターフェースID `0x7edbb9ad` | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ランダムな順番で不変条件五つを確認 | [第259講](../../part20/lecture259/) |
| 平均価格0を上限・清算・借金の消去に入れてみる | [第260講](../../part20/lecture260/) |
| リポジトリサーバーの設定ファイル | 扱わない |
| バグ一覧の照合をリポジトリサーバーで | [第260講](../../part20/lecture260/) |
| 本物のチェーンのフォークでガスを測る | 確かめられなかった |
| ドキュメントのページをサイトとして公開する | 扱わない |
| ログで数え直した合計を運用の監視に | [第263講](../../part20/lecture263/) |
| 二つの形・二つの言語のバージョンのテスト設計・同等性、形式検証 | 該当なし |

出典と参考資料は[reference.md](reference.md)にまとめた。
