# 第260講 自己監査の実施

第20部 キャップストーンプロジェクト・第71章 検証と監査への対応

[← 第259講](../../part20/lecture259/) | [第20部 目次](../) | [第261講 →](../../part20/lecture261/)

## この講義の問い

自分が書いたコードを自分で監査するとき、何を先に決めるのか。テストが見た世界の外は、どうやって開くのか。見つけたものは、何になれば指摘事項なのか。

## 実習資料

### 準備

通しプロジェクトMarketの第259講のバージョン（不変条件のバージョン、テスト75）を監査する。監査したビルドは末尾のメタデータハッシュの先頭4バイトが`47ac4829`、Marketのランタイムは8,739バイトである。この講義ではMarketのコードは変えず、`audit/`のドキュメント四つと確認のテスト`test/Findings.t.sol`（五つ）を加え、要件のドキュメントの反証・判定の行を直す。依存関係はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0である。anvilは使わない。

講義で実行した比較用のコピー二つは、このバージョンと1行だけが違う。

- 広げたコピー：第259講のバージョンの`test/helpers/Handler.sol`で`uint256 public minPrice = 0.2e18;`を`0`に
- スキップしないコピー：この講義のバージョンの`test/Findings.t.sol`で`bool constant FIXED = false;`を`true`に（このバージョンはfalse）

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、`fs_permissions`、debugプロファイル、`[fuzz]`・`[invariant]`の設定 |
| [code/abi/IMarket.json](code/abi/IMarket.json) | リポジトリに置いたABIファイル。ciがビルドとdiff |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束（ABI）：関数・イベント・エラーとNatSpec |
| [code/src/Market.sol](code/src/Market.sol) | レンディングマーケットの本体 |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息の曲線・丸めの計算ライブラリ |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | 共有する型、価格の出どころのインターフェース |
| [code/audit/README.md](code/audit/README.md) | 読む順番、等級の基準四つ（High・Medium・Low・Info）、候補の選別 |
| [code/audit/known-issues.md](code/audit/known-issues.md) | 既知の問題K-01〜K-06 |
| [code/audit/scope.md](code/audit/scope.md) | 監査範囲の表11行（行数、sha256、メタデータのkeccak256）と監査したビルドのハッシュ |
| [code/audit/self-audit.md](code/audit/self-audit.md) | 自己監査の報告書：ツール、攻撃の地図、信頼の前提の読み、キーの表、反証、指摘事項八つ |
| [code/test/Access.t.sol](code/test/Access.t.sol) | 権限の要件A-01〜A-05 |
| [code/test/Docs.t.sol](code/test/Docs.t.sol) | ABIの項目ごとにnoticeがあるか |
| [code/test/Errors.t.sol](code/test/Errors.t.sol) | エラー22ごとに、そのエラーで巻き戻るテスト一つ（巻き戻しデータ全体） |
| [code/test/Events.t.sol](code/test/Events.t.sol) | イベント11の引数すべて |
| [code/test/Findings.t.sol](code/test/Findings.t.sol) | 指摘事項の確認テスト五つ（M-01の三つは`FIXED = false`なのでスキップ、L-01・I-01は通過）。直したバージョンで通る形で書いた |
| [code/test/Functional.t.sol](code/test/Functional.t.sol) | 機能要件F-01〜F-10 |
| [code/test/Fuzz.t.sol](code/test/Fuzz.t.sol) | ファズテスト五つ（計算の部品二つ、丸めが金庫の側か三つ） |
| [code/test/Gas.t.sol](code/test/Gas.t.sol) | 測った呼び出し五つのガス |
| [code/test/Interface.t.sol](code/test/Interface.t.sol) | 関数の数とインターフェースID |
| [code/test/Invariant.t.sol](code/test/Invariant.t.sol) | 設計ドキュメント5節の不変条件I-1〜I-5と一覧にない失敗0、不変条件六つ |
| [code/test/Layout.t.sol](code/test/Layout.t.sol) | ストレージの欄の地図どおりに置かれているか |
| [code/test/Math.t.sol](code/test/Math.t.sol) | 計算の部品の曲線の値と丸めの方向 |
| [code/test/Ops.t.sol](code/test/Ops.t.sol) | 運用の要件O-01〜O-02 |
| [code/test/Rebuild.t.sol](code/test/Rebuild.t.sol) | ログだけで数え直した合計と状態の比較 |
| [code/test/Safety.t.sol](code/test/Safety.t.sol) | 安全の要件S-01〜S-08 |
| [code/test/Standards.t.sol](code/test/Standards.t.sol) | 標準の対照表の行ごとの確認 |
| [code/test/Trust.t.sol](code/test/Trust.t.sol) | 信頼の前提のテスト（T-01 出どころの停止・平均の遅れ、T-03 同じブロック） |
| [code/test/helpers/Accounts.sol](code/test/helpers/Accounts.sol) | テスト用のアカウントのコード二つ |
| [code/test/helpers/Base.sol](code/test/helpers/Base.sol) | テスト共用の土台（COL・USD、価格の出どころ二つ、前のバージョンと同じ場面） |
| [code/test/helpers/Handler.sol](code/test/helpers/Handler.sol) | 不変条件テストのハンドラー（動作十四、価格の範囲、正常な失敗の一覧） |
| [code/test/helpers/HookToken.sol](code/test/helpers/HookToken.sol) | 移される瞬間にMarketの帳簿を読んで書き留めるテスト用トークン |
| [code/test/helpers/MultiSigAdmin.sol](code/test/helpers/MultiSigAdmin.sol) | テスト用のマルチシグ |
| [code/test/helpers/OddTokens.sol](code/test/helpers/OddTokens.sol) | 標準と違う動きをするテスト用トークン（手数料トークンなど） |
| [code/test/helpers/StdToken.sol](code/test/helpers/StdToken.sol) | テスト用の標準トークン |
| [code/test/helpers/TwapFeed.sol](code/test/helpers/TwapFeed.sol) | テスト用の価格の出どころ（積み上がった価格の合計、`stop()`、権限のない`setPrice`） |

### 実行結果

監査範囲はビルドのメタデータのsourcesから取り出す。`forge build --offline`のあと、`out/Market.sol/Market.json`のrawMetadataからファイルごとにkeccak256の先頭4バイトを出力した結果（11行、`audit/scope.md`の範囲表と同じファイル）：

```
lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol 0xd5ea0736
lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol 0x0afcb7e7
lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol 0x1a622131
lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol 0x74ed01eb
lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol 0xd6fa4088
lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol 0x982c5cb7
lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol 0x8891738f
src/IMarket.sol 0x5178257c
src/Market.sol 0x76051f36
src/MarketMath.sol 0xd18e811c
src/MarketTypes.sol 0xbe3dddd5
```

設計ドキュメントが書いたOpenZeppelinのファイルは四つだが、ビルドには七つが入る（`interfaces/IERC20.sol`、`interfaces/IERC165.sol`、`utils/introspection/IERC165.sol`が多い）。これが、コードを開く前に出た指摘事項I-04である。

`forge lint --offline src`の警告十一と判定：

| 警告 | Market.solの行 | 判定 |
|---|---|---|
| unused-return 1 | 71 | 候補 → I-02 |
| reentrancy-events 5 | 124、154、163、189、285 | 設計ドキュメント4節の順番（イベントが最後）、I-03 Infoとして記録 |
| block-timestamp 2 | 294、309 | K-02 |
| calls-loop 2、require-revert-in-loop 1 | 249（2か所）、268 | K-03 |

コンパイラのバグ一覧（bugs.json 63項目・バージョン120）で0.8.30が該当するバグ四つを、設定とソースに当てた結果：

| バグ | 設定の条件 | ソースの条件（Market） |
|---|---|---|
| SOL-2026-3 InheritanceOrderReversalOnStorageEndWarning | 合う（条件なし） | layout at 0か所 |
| SOL-2026-2 UnsoundSpillInMutualRecursion | 合う（via-IR） | 互いに呼ぶ関数の輪0（関数98、辺115） |
| SOL-2026-1 TransientStorageClearingHelperCollision | 合う（via-IR、cancun以上） | transient 0か所 |
| SOL-2025-1 LostStorageArrayWriteOnSlotOverflow | 合う（条件なし） | ストレージの終わりにかかる配列なし（assetsはスロット0、pushだけ） |

関数の輪は、`solc --combined-json ast`で取り出したASTで関数と呼び出しの辺を数えて確認した（関数98、辺115、輪0）。

広げたコピー（ハンドラーの価格の下限0）で`forge test --offline --match-contract InvariantTest`：

```
[FAIL: 0x4e487b71: 1 != 0] invariant_noUnexpectedFailure
	[Sequence] (original: 130, shrunk: 4)
		... calldata=openPosition(uint256,uint256,uint256,uint256,uint256) args=[12, 623716554 [6.237e8], 2832519640 [2.832e9], 16920 [1.692e4], 7857]
		... calldata=setPrice(uint256,uint256) args=[14116 [1.411e4], 0]
		... calldata=warp(uint256) args=[61861444035461 [6.186e13]]
		... calldata=liquidate(uint256,uint256,uint256,uint256,uint256) args=[10646 [1.064e4], 4458, 8, 135, ...]

InvariantTest invariants: 1/6 invariants broken
```

縮めた手順は、借金を負う → 価格0 → 時間 → 清算である（順番と引数は実行ごとに違う）。`--mt invariant_noUnexpectedFailure -vvvv`の跡：

```
    ├─ [185873] Market::liquidate(0x00000000000000000000000000000000000A11cE, FeeSwitchToken: [...], StdToken: [...], 1550460392508759828550 [1.55e21])
    │   ├─ ...
    │   ├─ [4209] TwapFeed::cumulativePrice(0) [staticcall]
    │   │   └─ ← [Return] 3600000000000000000000 [3.6e21]
    │   ├─ [4209] TwapFeed::cumulativePrice(1800) [staticcall]
    │   │   └─ ← [Return] 3600000000000000000000 [3.6e21]
    │   └─ ← [Revert] panic: division or modulo by zero (0x12)
```

今と30分前の積み上がった合計が同じなので平均が0になり、受け取る担保を数えるときに0で割る（監査したビルドの`src/Market.sol` 249・364行）。

指摘事項八つ（`audit/self-audit.md` 3節）：

| 番号 | 等級 | 根本原因 | 確認のテスト |
|---|---|---|---|
| M-01 | Medium | priceOfが平均0をはじかない（249） | test_M01_*の三つ（スキップ） |
| L-01 | Low | F-08の文とコードで担保の値0の条件が違う（193〜194） | test_L01_dustCollateralCountsAsNone |
| I-01 | Info | 担保はアカウントがオンにしたものだけ（F-03） | test_I01_nonCollateralDepositStaysWithOwner |
| I-02 | Info | listAssetの71の確認呼び出しの返り値を捨てる | test_M01_listAssetRejectsZeroAverage |
| I-03 | Info | トークンを移したあとにイベント（4節の順番） | S-02 |
| I-04 | Info | 取り込んだファイル四つ（ドキュメント）vs 七つ（ビルド） | scope.md |
| I-05 | Info | N-05の理由の欄が受け取るときの確認だけを言う | - |
| I-06 | Info | T-04の文言が広い | F-07 |

M-01は原因一つに症状が三つである。借金の消去が担保トークンの残ったアカウントの借金を消し、清算が0除算のPanic 0x12で止まり、その担保での借り入れ・担保の引き出しが`InsufficientCollateral`になる。aliceがCOL 1000を担保・借金700なら、借金が消えてCOL 1000はaliceにそのまま残り、損失はUSDを預けた人たちが持ち分に応じて負う。

確認のテストは、直したバージョンで通る形で先に書く。まだないエラー`ZeroPrice`は、テストの中にセレクタ（`0x4a6f5ccb`）としてだけ置く。スキップしないコピーで`forge test --offline --match-contract FindingsTest`：

```
[PASS] test_I01_nonCollateralDepositStaysWithOwner() (gas: 737794)
[PASS] test_L01_dustCollateralCountsAsNone() (gas: 1840644)
[FAIL: next call did not revert as expected] test_M01_listAssetRejectsZeroAverage() (gas: 998714)
[FAIL: Error != expected error: panic: division or modulo by zero (0x12) != custom error 0x4a6f5ccb: 0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f] test_M01_zeroPriceStopsLiquidation() (gas: 256893)
[FAIL: next call did not revert as expected] test_M01_zeroPriceStopsWriteOff() (gas: 243191)
Suite result: FAILED. 2 passed; 3 failed; 0 skipped; finished in 1.78ms (2.90ms CPU time)
```

このバージョン（`FIXED = false`、テストの最初の行`vm.skip(!FIXED);`）の`bash ci.sh`：

```
[SKIP] test_M01_listAssetRejectsZeroAverage() (gas: 0)
[SKIP] test_M01_zeroPriceStopsLiquidation() (gas: 0)
[SKIP] test_M01_zeroPriceStopsWriteOff() (gas: 0)
Ran 17 test suites in 8.02s (8.51s CPU time): 77 tests passed, 0 failed, 3 skipped (80 total tests)
ci ok
```

### 試すときの注意

- コードを開く前に三つを先に書く。範囲（`audit/scope.md`、ビルドのハッシュとファイル一覧）、既知の問題（`audit/known-issues.md`、K-01〜K-06）、等級の基準（`audit/README.md`）。読む順番はscope.md → known-issues.md → 設計ドキュメント6節の信頼の前提 → コードである。
- 範囲表のいちばん上にビルドのハッシュを書いておくと、直したあとに別のビルドだとすぐわかる。範囲外はtest/、価格の出どころのアダプター、運用ツール、タイムロック・マルチシグのコード、OpenZeppelinの残りのファイルである。
- 等級の基準（High、Medium、Low、Info）は影響と条件で決める。見つけたあとで決めると、基準が見つけたものに合わせて動く。
- lintの警告は候補にすぎない。十一のうち指摘事項になったのはunused-return一つ（I-02）で、残りは設計の順番か既知の問題だった。
- 関数の輪のツールは、ASTのすべてのsources（OpenZeppelinを含む）を数える。
- 監査は、テストが絞っておいた範囲（ハンドラーの価格0.2〜2.0）から開き直す。下限を0に広げるとM-01が出た。
- 候補ごとに、範囲の中か、すでに知られているか、お金や機能が実際に傷つくかを問う。直せば一緒に消える症状は1件として書く。
- 確認のテストが作る状況は、価格の出どころが0を返すこと一つで、Marketが防ぐかだけを見る。スキップ一つが直す仕事一つなので、ciは通り続ける。
- I-03（トークンが移す途中でMarketを呼び返す場合）は読んで判断し、テストはない。
- forge lintが指すblock-timestampの行は比較式（294、309）で、block.timestampを読む行は293である。
- 式で証明するツールと記号実行のツールは、この監査では使っていない。
- 反証の項目「最終決定権の行き着く先が結局一つの主体の鍵か？」に、キャップストーンのバージョンはいいえに近い。残るのは、署名者三人が一か所にいる場合と価格の出どころの運営者（T-01）である。

## 時効性のあるデータ

基準日時点の値。ツール・ライブラリのバージョンとコンパイラのバグ一覧が変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry・solc | forge 1.8.3（commit cae51ad4）、solc 0.8.30 | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0、ビルドに入るファイル七つ | 2026-10-21 |
| 監査したビルド | Market runtime 8,739 / creation 9,070、末尾のメタデータハッシュの先頭4バイト`47ac4829`、セレクタ38・イベント11・エラー22 | 2026-10-21 |
| コンパイラのバグ一覧 | bugs.json 63項目・バージョン120、0.8.30の既知のバグ四つ | 2026-07-09（Solidityリポジトリ コミット8a079791） |
| 関数の輪 | 関数98、辺115、輪0 | 2026-10-21 |
| forge lint（src） | 十一：unused-return 1（71）、reentrancy-events 5（124・154・163・189・285）、block-timestamp 2（294・309）、calls-loop 2（249）、require-revert-in-loop 1（268） | 2026-10-21 |
| カバレッジ | Marketの行234/238、分岐41/42（`--ir-minimum`） | 2026-10-21 |
| 広げたコピー | 縮めた手順四つ（openPosition → setPrice 0 → warp → liquidate）、Panic 0x12、128 × 200呼び出し（実行ごとに順番・数字が違う） | 2026-10-21 |
| テストの合計 | 77通過 / 0失敗 / 3スキップ（80） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 外部の公開リポジトリを同じ手順で読む | 扱わない |
| 式で証明するツール・記号実行のツール | 扱わない（確かめられなかった） |
| 外部監査・コンテストに出す | 扱わない |
| 指摘事項への対応と直したバージョン | [第261講](../../part20/lecture261/) |
| キーの保管・署名サーバー | [第262講](../../part20/lecture262/) |
| 広げた価格範囲で監視の判定範囲を選ぶ | [第263講](../../part20/lecture263/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
