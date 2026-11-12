# 第261講 指摘への対応とパッチ

第20部 キャップストーンプロジェクト・第71章 検証と監査への対応

[← 第260講](../../part20/lecture260/) | [第20部 目次](../) | [第262講 →](../../part20/lecture262/)

## この講義の問い

指摘事項ごとに、どう答えるのか。直すとき何から変え、直したバージョンが正しいことは何で示すのか。

## 実習資料

### 準備

通しプロジェクトMarketの第260講のバージョン（監査したバージョン、ハッシュ`47ac4829`、77通過 / 3スキップ）から始める。この講義のバージョンが第71章末のバージョンである。直す順番は、要件の表・設計ドキュメント → 確認のテスト（`FIXED = true`） → コード → テスト全部 → 新しいビルドの範囲（`audit/scope.md`）である。依存関係はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0である。anvilは使わない。

講義で実行した比較用のコピー二つは、このバージョンと一か所だけが違う。

- 直した直後の状態：`test/Errors.t.sol`の`test_err_LossExceedsDeposits`関数だけを監査したバージョンの道（平均価格0）に戻す
- 確認の行を消したコピー：`src/Market.sol`のpriceOfで`if (p == 0) revert ZeroPrice(asset);`の1行だけを消す

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、`fs_permissions`、debugプロファイル、`[fuzz]`・`[invariant]`の設定 |
| [code/abi/IMarket.json](code/abi/IMarket.json) | リポジトリに置いたABIファイル。ciがビルドとdiff |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束（ABI）。`error ZeroPrice(address asset)`とnoticeを追加 |
| [code/src/Market.sol](code/src/Market.sol) | レンディングマーケットの本体。listAsset 71〜72、priceOf 250〜252に平均0の確認 |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息の曲線・丸めの計算ライブラリ |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | 共有する型、価格の出どころのインターフェース |
| [code/audit/README.md](code/audit/README.md) | 読む順番、等級の基準四つ、候補の選別 |
| [code/audit/known-issues.md](code/audit/known-issues.md) | 既知の問題K-01〜K-06 |
| [code/audit/response.md](code/audit/response.md) | 対応表：指摘事項ごとの修正・ドキュメントをコードに合わせる・設計どおりと、変えた箇所 |
| [code/audit/scope.md](code/audit/scope.md) | 監査範囲の表と監査したビルド、直したビルドの行 |
| [code/audit/self-audit.md](code/audit/self-audit.md) | 自己監査の報告書（指摘事項八つ） |
| [code/test/Access.t.sol](code/test/Access.t.sol) | 権限の要件A-01〜A-05 |
| [code/test/Docs.t.sol](code/test/Docs.t.sol) | ABIの項目ごとにnoticeがあるか（エラー23、notice 22） |
| [code/test/Errors.t.sol](code/test/Errors.t.sol) | エラー23ごとにテスト一つ。`test_err_ZeroPrice`を追加、`test_err_LossExceedsDeposits`は平均1 weiの道に変更 |
| [code/test/Events.t.sol](code/test/Events.t.sol) | イベント11の引数すべて |
| [code/test/Findings.t.sol](code/test/Findings.t.sol) | 指摘事項の確認テスト五つ（`FIXED = true`、五つとも通過） |
| [code/test/Functional.t.sol](code/test/Functional.t.sol) | 機能要件F-01〜F-10 |
| [code/test/Fuzz.t.sol](code/test/Fuzz.t.sol) | ファズテスト五つ |
| [code/test/Gas.t.sol](code/test/Gas.t.sol) | 測った呼び出し五つのガス |
| [code/test/Interface.t.sol](code/test/Interface.t.sol) | 関数の数とインターフェースID |
| [code/test/Invariant.t.sol](code/test/Invariant.t.sol) | 不変条件テスト（I-1〜I-5、一覧にない失敗0） |
| [code/test/Layout.t.sol](code/test/Layout.t.sol) | ストレージの欄の地図どおりに置かれているか |
| [code/test/Math.t.sol](code/test/Math.t.sol) | 計算の部品の曲線の値と丸めの方向 |
| [code/test/Ops.t.sol](code/test/Ops.t.sol) | 運用の要件O-01〜O-02 |
| [code/test/Rebuild.t.sol](code/test/Rebuild.t.sol) | ログだけで数え直した合計と状態の比較 |
| [code/test/Safety.t.sol](code/test/Safety.t.sol) | 安全の要件S-01〜S-08 |
| [code/test/Standards.t.sol](code/test/Standards.t.sol) | 標準の対照表の行ごとの確認 |
| [code/test/Trust.t.sol](code/test/Trust.t.sol) | 信頼の前提のテスト（T-01 出どころの停止・平均の遅れ、T-03 同じブロック） |
| [code/test/helpers/Accounts.sol](code/test/helpers/Accounts.sol) | テスト用のアカウントのコード二つ |
| [code/test/helpers/Base.sol](code/test/helpers/Base.sol) | テスト共用の土台（COL・USD、価格の出どころ二つ、前のバージョンと同じ場面） |
| [code/test/helpers/Handler.sol](code/test/helpers/Handler.sol) | 不変条件のハンドラー。価格0〜2.0、`ZeroPrice`を正常な失敗の一覧に |
| [code/test/helpers/HookToken.sol](code/test/helpers/HookToken.sol) | 移される瞬間にMarketの帳簿を読んで書き留めるテスト用トークン |
| [code/test/helpers/MultiSigAdmin.sol](code/test/helpers/MultiSigAdmin.sol) | テスト用のマルチシグ |
| [code/test/helpers/OddTokens.sol](code/test/helpers/OddTokens.sol) | 標準と違う動きをするテスト用トークン（手数料トークンなど） |
| [code/test/helpers/StdToken.sol](code/test/helpers/StdToken.sol) | テスト用の標準トークン |
| [code/test/helpers/TwapFeed.sol](code/test/helpers/TwapFeed.sol) | テスト用の価格の出どころ（積み上がった価格の合計、`stop()`、権限のない`setPrice`） |

### 実行結果

対応表（`audit/response.md`）：

| 番号 | 対応 | 変えた箇所 |
|---|---|---|
| M-01 | 修正 | 4節・T-01・D-14、IMarket ZeroPrice(asset)、Market priceOf・listAsset |
| L-01 | ドキュメントをコードに合わせる | F-08の文、4節の借金の消去 |
| I-01 | 設計どおり | 入れないものN-09、4節 |
| I-02 | 修正（M-01と同じ行） | listAssetが確認呼び出しの返り値で平均を計算 |
| I-03 | 設計どおり | なし（4節の順番、S-02） |
| I-04 | 修正（ドキュメント） | D-10、T-07、11節 → ファイル七つ |
| I-05 | 修正（ドキュメント） | N-05の理由の欄、T-02 |
| I-06 | 修正（ドキュメント） | T-04 |

変わったコード：

```solidity
// src/IMarket.sol
+    /// @notice 価格の出どころの30分平均が0(止まった出どころと同じに扱う)
+    error ZeroPrice(address asset);

// src/Market.sol listAsset 71~72
-        feed.cumulativePrice(TWAP_WINDOW); // 記録が30分より短い出どころは上場の前にリバート
+        uint256 past = feed.cumulativePrice(TWAP_WINDOW); // 記録が30分より短い出どころは上場の前にリバート
+        if ((feed.cumulativePrice(0) - past) / TWAP_WINDOW == 0) revert ZeroPrice(asset); // 平均0の出どころは上場しない(D-14)

// src/Market.sol priceOf 250~252
-        return (feed.cumulativePrice(0) - feed.cumulativePrice(TWAP_WINDOW)) / TWAP_WINDOW;
+        uint256 p = (feed.cumulativePrice(0) - feed.cumulativePrice(TWAP_WINDOW)) / TWAP_WINDOW;
+        if (p == 0) revert ZeroPrice(asset); // 平均0は止まった出どころと同じに(D-14、T-01)
+        return p;
```

`ZeroPrice`のセレクタは`0x4a6f5ccb`で、確認のテストに先に書いておいた値と同じである。

コードと確認のテストを直して`test_err_ZeroPrice`を加えたあと、`test_err_LossExceedsDeposits`の道だけを監査したバージョンのままにした状態で`forge test --offline`：

```
[FAIL: Error != expected error: ZeroPrice(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f) != LossExceedsDeposits(1000057078 [1e9], 1000057077 [1e9])] test_err_LossExceedsDeposits() (gas: 663584)
Ran 17 test suites in 7.49s (7.94s CPU time): 80 tests passed, 1 failed, 0 skipped (81 total tests)
```

直したコードが正しく、間違っているのはテストが選んだ道（平均価格0）である。残りの要件のテストは前のバージョンと同じ数字で通過した（上限750と`InsufficientCollateral(750e18, 751e18)`、1年の利息のあとの借金515.625、30分平均1.1で上限825、0.3で返した285.714286・消した借金414.285714・bob 585.714286、全部返して全部引き出したあとの金庫のかけら2以下）。

`LossExceedsDeposits`に届く残りの道は平均価格1 weiである。清算が担保2000を全部持っていき、返す量は1単位なのに、減る持ち分は切り捨てで0なので借金がそのまま残る。`forge test --offline --mt test_err_LossExceedsDeposits -vv`：

```
[PASS] test_err_LossExceedsDeposits() (gas: 1012460)
Logs:
  loss: 1000057078
  deposits: 1000057077
```

確認のテスト（`forge test --offline --match-contract FindingsTest`、`FIXED = true`）：

```
[PASS] test_I01_nonCollateralDepositStaysWithOwner() (gas: 737983)
[PASS] test_L01_dustCollateralCountsAsNone() (gas: 1847520)
[PASS] test_M01_listAssetRejectsZeroAverage() (gas: 935298)
[PASS] test_M01_zeroPriceStopsLiquidation() (gas: 332576)
[PASS] test_M01_zeroPriceStopsWriteOff() (gas: 178755)
```

ハンドラーの価格の下限を0に広げ、`ZeroPrice`を正常な失敗の一覧に入れた不変条件の結果（今回の実行の値）：

```
[PASS] invariant_noUnexpectedFailure
 InvariantTest invariants (runs: 128, calls: 25600, reverts: 7978)
| Handler  | liquidate     | 2594  | 364     | 1838     |
| Handler  | writeOff      | 2581  | 365     | 2183     |
```

確認の行を消したコピーで`forge test --offline`：

```
[FAIL: Error != expected error: panic: division or modulo by zero (0x12) != ZeroPrice(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f)] test_M01_zeroPriceStopsLiquidation() (gas: 256887)
[FAIL: next call did not revert as expected] test_M01_zeroPriceStopsWriteOff() (gas: 243191)
[FAIL: next call did not revert as expected] test_err_ZeroPrice() (gas: 100656)
[FAIL: 0x4e487b71: 1 != 0] invariant_noUnexpectedFailure
Ran 17 test suites in 9.93s (10.32s CPU time): 77 tests passed, 4 failed, 0 skipped (81 total tests)
```

`test_M01_listAssetRejectsZeroAverage`は、listAssetに別の確認の行があるので通過する。

監査したバージョンと直したバージョン：

| 値 | 監査したバージョン | 直したバージョン |
|---|---|---|
| Market runtime / creation（バイト） | 8,739 / 9,070 | 8,921 / 9,252 |
| 末尾のメタデータハッシュの先頭4バイト | `47ac4829` | `d551e83c` |
| セレクタ / イベント / エラー | 38 / 11 / 22 | 38 / 11 / 23 |
| IMarketのインターフェースID、ストレージの欄 | `0x7edbb9ad`、スロット0〜4 | そのまま |
| STATICCALL | 6 | 7 |
| 測った呼び出しborrow / liquidate | 160,196 / 235,771 | 160,238 / 235,855 |
| lint unused-return / require-revert-in-loop | 1 / 1 | 0 / 2 |

deposit 139,186・repay 63,348・withdraw 64,696はそのままである。直したビルドの値（`audit/scope.md`の直したビルドの行と同じ形、行数・sha256の先頭16桁・メタデータのkeccak256の先頭4バイト）：

```
直したビルド(指摘への対応のあと): Marketのランタイム8,921バイト、ハッシュd551e83c。変わったファイルは二つ(IMarket.sol、Market.sol)
| src/IMarket.sol | 142 → 144 | cd6c25df1f75c710 → e7bc5ac183f0db40 | 5178257c → e4b7aafe |
| src/Market.sol | 421 → 424 | 84cd1be9ce7f760e → 8460b76110cc2afb | 76051f36 → 1bde19a3 |
```

直したバージョンの`bash ci.sh`：

```
Ran 17 test suites in 7.43s (7.78s CPU time): 81 tests passed, 0 failed, 0 skipped (81 total tests)
ci ok
```

### 試すときの注意

- 指摘ごとの答えは三つのうち一つである。直すか、ドキュメントをコードに合わせるか、設計どおりだと根拠を示す。等級は監査のときに決めた基準のままにして答えを決める。
- L-01には二つの道があった。コードを持ち分で数えると、1 weiのかけら一つで借金の消去を防げてしまうので、F-08の文をコードに合わせる方を選んだ（値が0に切り捨てられるかけらはアカウントに残る）。
- I-01は設計どおりである。担保としてオンにしていないお金を清算・借金の消去が持っていくと、担保のオフが意味をなさなくなるので、「入れないもの」N-09に理由と一緒に書いた。
- コードよりドキュメントを先に直す。コードから直すと、ドキュメントがコードと違う話をすることになる。平均0を止まった出どころと同じに扱えば、T-01の文がそのまま正しく、新しい規則がいらない（D-14）。
- エラー一覧のテストはABIのエラーごとに一つなので、エラーが増えればテストも一つ増える（エラー23、ドキュメントのテストのnotice 22）。
- 確認のテストは直したあとも消さない。
- priceOfを呼ぶところは四つである（`_value`、`_seizeFor`、`_repayFor`、外からの読み取り）。直した行とその行を呼ぶ行を読み直す。
- 平均0の資産を担保に使うアカウントは、借り入れ・担保の引き出し・清算・借金の消去が`ZeroPrice`で巻き戻り、返済と担保ではない引き出しはできる。出どころが止まったときと同じである。
- borrow・liquidateのガスが増えた理由は別に測っていない。コードを読むと、価格を読むたびに0の確認1行が加わったためと見られる。インターフェースIDは関数のセレクタだけで数えるので、エラーが増えてもそのままである。
- 直したバージョンは新しいビルドである。範囲表のハッシュを新しく書く。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると変わることがあり、不変条件の表の数字は実行ごとに違う。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry・solc | forge 1.8.3（commit cae51ad4）、solc 0.8.30 | 2026-10-21 |
| 直したビルド | Market runtime 8,921 / creation 9,252、ハッシュ`d551e83c`、セレクタ38・イベント11・エラー23、インターフェースID `0x7edbb9ad`、STATICCALL 7 | 2026-10-21 |
| 監査したビルド | runtime 8,739 / creation 9,070、ハッシュ`47ac4829`、エラー22、STATICCALL 6 | 2026-10-21 |
| 測った呼び出し（GasTest） | 監査したバージョンdeposit 139,186・borrow 160,196・repay 63,348・withdraw 64,696・liquidate 235,771 / 直したバージョン139,186・160,238・63,348・64,696・235,855 | 2026-10-21 |
| forge lint（src） | 直したバージョン十一：unused-return 0、reentrancy-events 5、block-timestamp 2、calls-loop 2、require-revert-in-loop 2 | 2026-10-21 |
| 不変条件の表（直したバージョン） | 128 × 200、reverts 7,978、liquidate 2,594・364・1,838、writeOff 2,581・365・2,183（実行ごとに違う） | 2026-10-21 |
| テストの合計 | 直した直後80通過 / 1失敗（81）、直したバージョン81 / 0 / 0、確認の行を消したコピー77 / 4 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 外部監査人による直したバージョンの確認の手順 | 扱わない |
| 直したバージョンのデプロイと移行 | [第262講](../../part20/lecture262/) |
| 監視が数える巻き戻しにZeroPriceを加える | [第263講](../../part20/lecture263/) |
| 平均0の出どころでその資産を担保にするアカウントの清算が止まる状況の練習 | [第264講](../../part20/lecture264/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
