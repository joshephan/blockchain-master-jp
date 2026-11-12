# 第190講 報告書の作成

第12部 監査の実務・第50章 監査の方法論

[← 第189講](../../part12/lecture189/) | [第12部 目次](../) | [第191講 →](../../part12/lecture191/)

## この講義の問い

指摘事項をどう書けば、読む人が直して確かめられるのか。報告書には何が入り、何は入らないのか。監査する人はコードを直してくれるのか。

## 実習資料

### 準備

三つのプロジェクトを使う。監査対象のバージョンのMarketに再現テスト`Audit50.t.sol`を足した写し、直す前のバージョン（Frozenなら出金まで止めていたバージョン）の写し、直したバージョンに直す前のバージョンの再現テストを一字一句そのまま移した写しである。srcはどれも手を入れていない。三つともforge-std（1.17.0）が必要である（`lib/forge-std`）。この講義で書いた監査報告書一件も一緒に置く。anvilと外部への接続は使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/report/Market-audit.md](code/report/Market-audit.md) | この講義で書いたMarketの監査報告書（目次八つ、指摘事項の表、L-01・I-02・I-03・I-04の本文、M-01の修正確認、コマンドと出力） |
| [code/market/foundry.toml](code/market/foundry.toml) | 監査対象のバージョンのビルド設定 |
| [code/market/src/](code/market/src/) | 監査対象のMarketのソース |
| [code/market/test/Audit50.t.sol](code/market/test/Audit50.t.sol) | 指摘事項の再現テスト六つと、テスト用の1%手数料トークン |
| [code/market/test/](code/market/test/) | 基準のバージョンのテスト全体（Keys、Docsを含む） |
| [code/market164/](code/market164/) | 直す前のバージョンのソースと、`test_M01_frozenLocksWithdraw`が入った再現テスト |
| [code/fixcheck/test/FixCheck50.t.sol](code/fixcheck/test/FixCheck50.t.sol) | 直したバージョンに移した`test_M01_frozenLocksWithdraw`（修正確認用） |
| [code/fixcheck/src/](code/fixcheck/src/) | 直したバージョンのMarketのソース（監査対象のバージョンと同じ） |
| [code/fixcheck/foundry.toml](code/fixcheck/foundry.toml) | 直したバージョンのビルド設定 |

### 実行結果

報告書の目次は、要約、範囲と範囲外、深刻度の基準、指摘事項の表、指摘事項の本文、以前のバージョンで直した項目、信頼の前提と受け入れたリスク、付録（コマンドと出力）の八つの欄である。結果は低3、情報4、以前のバージョンで直した項目1（修正確認）、受け入れたリスク1である。

| ID | タイトル | 深刻度 | 頼った前提 | 修正の提案 | 状態 |
|---|---|---|---|---|---|
| L-01 | 手数料を引くトークンを上場すると、最後の出金が差し戻される | 低 | 管理者がboolを返す標準トークンだけを上場 | 上場前の確認手順（代案：受け取った量を残高の差で数える） | 提案 |
| L-02 | depositなしで送ったトークンは取り出す道がない | 低 | 帳簿で数える | ドキュメント化 | 了承 |
| L-03 | 鍵一つの管理者がFrozenをかけて鍵をなくすと、預け入れ・資産の追加が永遠に止まる | 低 | 管理者の席はマルチシグ、出金は状態に関係ない | マルチシグでのデプロイの決定のまま | 了承 |
| I-01 | totalBorrows・borrowed・useAsCollateralを書く行がなく、collateralCountは常に0 | 情報 | 借り入れ・担保の機能なし | 借り入れ機能のときに見直す | 了承 |
| I-02 | 空の席のelapsedOfがblock.timestampを返し、NatSpecと違う | 情報 | この値でお金を決める行なし | NatSpecに一行、または空の席で0を返す | 提案 |
| I-03 | collateralCountが上場した資産をすべて回る（ガス） | 情報 | 資産は管理者だけが上げる、view | ドキュメント化 | 了承 |
| I-04 | Market.sol 193行のコメントが直す前の動作を書いている | 情報 | コメントはバイトコードに入らない | 古い行を今の動作に直す | 提案 |

L-01の再現（`forge test --offline --match-test test_L01 -vv`）：

```
[PASS] test_L01_feeTokenLastWithdrawReverts() (gas: 722614)
```

`-vvvv`で見た最後の出金。トークン側のtransferが、Marketの実際の残高98から100を引こうとして、オーバーフローチェック（panic 0x11）にかかる（トレースの前の行は省略）。

```
├─ [40225] Market::withdraw(FeeToken50: [0xa0Cb…7598], 100)
│   │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
│   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
```

ドキュメントのテスト（`test/Docs.t.sol`）の二つは通る。ドキュメントがあるかだけを確かめるので、I-02のようにドキュメントと動作が違うものは捕まえられない。

```
[PASS] test_everyEventAndErrorHasNotice() (gas: 3121)
[PASS] test_everyFunctionHasNotice() (gas: 3091)
```

M-01の修正確認。同じテストを、直す前のバージョンと直したバージョンで回す。直したバージョンで失敗することが、再現しないという意味である。

```
直す前のバージョン
[PASS] test_M01_frozenLocksWithdraw() (gas: 253663)
直したバージョン
[FAIL: next call did not revert as expected] test_M01_frozenLocksWithdraw() (gas: 240033)
```

直したバージョンのKeysのテスト：

```
[PASS] test_frozenStillWithdraws() (gas: 428326)
[PASS] test_lostKeyFrozenStillWithdraws() (gas: 433327)
```

監査対象のバージョンの`forge inspect Market deployedBytecode`は2,990バイト、末尾のメタデータのハッシュ`de70fa9e…`で、監査の範囲の表のビルドと同じである。全体の`forge test --offline`は41スイート117個が通る。

### 試すときの注意

- テストを回す前に、`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガスの記録の照合を切る。`snapshots/`は添付していない。
- 再現テストは縮めて書く。test_L01には、手数料トークン一つ、人二人、預け入れ二つ、引き出し二つだけが入っていて、利息計算・状態の変更はない。
- I-04のようにコメントだけを直しても、メタデータのハッシュが変わる。直したあとは、監査の範囲の表のビルドのハッシュを合わせ直す。
- `--match-contract "KeysTest|DocsTest"`で、KeysとDocsのテスト8個だけを回せる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンや公開場所は変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30+commit.73712a01.Windows.msvc、sha256 `ccbd3ed44d5fbd26fe039702d403421f1212d2e8752e3cbe3bfd074986911586`（Windowsの実行ファイル） | 2026-10-21 |
| Marketのビルド | optimizerオン（runs 200）、via-IRオン、evm osaka、bytecode_hash ipfs。ランタイム2,990バイト、末尾のメタデータのハッシュ`de70fa9e1585f2dae1720ff3231bcf64fa6532a535aa3488b797d723f0176fba` | 2026-10-21 |
| 範囲の行数 | IMarket 164/47、Market 267/123、MarketMath 43/21、MarketTypes 41/26、合計515/217 | 2026-10-21 |
| 再現テストのガス | test_L01 722,614 / test_M01 直す前253,663・直したバージョン240,033 / Keys 428,326・433,327 / I-03 資産1個14,198・100個469,049 | 2026-10-21 |
| テストの数 | 監査用の写しで41スイート117個（もとの111 + 再現6）が通過 | 2026-10-21 |
| 公開監査報告書を出しているところ（例） | Trail of Bits（公開リポジトリpublications）、OpenZeppelin（監査記事の公開） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| コンテストの提出様式との違い | [第191講](../../part12/lecture191/)、[第193講](../../part12/lecture193/) |
| 手数料トークンを受け付ける帳簿の設計 | [第256講](../../part20/lecture256/) |
| 報告書の公開範囲（非公開の報告書と公開の報告書） | 付録 |
| L-02・L-03・I-01の本文全体 | 報告書ファイル |

出典と参考資料は[reference.md](reference.md)にまとめた。
