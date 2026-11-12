# 第184講 コンパイラのバグデータベースの読み方

第11部 推奨事項：敵対的環境とバージョン履歴・第49章 既知のバグとバージョン移行

[← 第183講](../../part11/lecture183/) | [第11部 目次](../) | [第185講 →](../../part11/lecture185/)

## この講義の問い

自分が使うコンパイラのバージョンに既知のバグがあるかは、どこで見るのか。一覧にバグがあれば、自分のコードは危ないのか。自分のコードが該当するかしないかは、何で見分けるのか。

## 実習資料

### 準備

Solidityリポジトリの`docs/bugs.json`と`docs/bugs_by_version.json`（v0.8.36の写し）をPythonスクリプトで読んでバージョンごとの既知のバグを数え、0.8.30の四つをMarketのビルド設定とソースに当ててみる。プロジェクトは二つある。`bugs`はtransientストレージの消去のバグ（TransientStorageClearingHelperCollision）を再現する小さなFoundryプロジェクトで、forge-stdが必要である。via-IRでビルドする既定のプロファイルと、via-IRを切った`legacy`プロファイルを置く。`market`は通しプロジェクトMarketの第46章の終わりのバージョンで、この講義ではコードとテストを直さない。solc 0.8.30は新しく取得せず、手元にあったものを使った。anvilと外部への接続は使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/tools/bugs184.py](code/tools/bugs184.py) | `bugs.json`・`bugs_by_version.json`を読んでバージョンごとのバグの数を数え、0.8.30のバグごとに条件をMarketのビルド設定（optimizerオン、via-IRオン、osaka）に当ててみる。引数はリポジトリの`docs`フォルダ |
| [code/tools/recur184.py](code/tools/recur184.py) | solcの`--combined-json ast`の出力から、関数同士が呼ぶ辺を数え、互いに呼び合う循環を探す |
| [code/bugs/foundry.toml](code/bugs/foundry.toml) | solc 0.8.30、optimizerオン、via-IRオン、evm osaka、`legacy`プロファイル（via_ir = false） |
| [code/bugs/src/Clear184.sol](code/bugs/src/Clear184.sol) | Clear184（ストレージの欄sとtransientの欄tを一つのコントラクトで両方delete）、ClearOnly184（ストレージの欄だけをdelete） |
| [code/bugs/test/Clear184.t.sol](code/bugs/test/Clear184.t.sol) | Clear184Testの二つ：runのあとsとtが0か。via-IRのビルドで一つがわざと失敗するようにしたテスト |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（solc 0.8.30、optimizerオン、via-IRオン、evm osaka） |
| [code/market/src/](code/market/src/) | Marketの本体（第46章の終わりのバージョンのまま） |
| [code/market/test/](code/market/test/) | 第46章の終わりのバージョンまでに積み重なったテスト（そのまま） |

### 実行結果

`python -I -X utf8 tools/bugs184.py <リポジトリ>/docs`のバージョンごとの数（修正版の公開日の行は下の時効性の表に移した）：

```
bugs.jsonの項目 63 / バージョン 120
0.4.24 2018-05-16 既知のバグ 18
0.5.17 2020-03-17 既知のバグ 12
0.6.12 2020-07-22 既知のバグ 12
0.7.6 2020-12-16 既知のバグ 11
0.8.0 2020-12-16 既知のバグ 11
0.8.30 2025-05-07 既知のバグ 4
0.8.36 2026-07-09 既知のバグ 0
```

同じ出力の0.8.30の照合。四つとも設定の条件が一致する。

```
0.8.30 一覧とMarketのビルド設定(optimizerオン、via-IRオン、osaka)の照合
- SOL-2026-3 InheritanceOrderReversalOnStorageEndWarning | severity medium
  | introduced 0.8.29 fixed 0.8.36 | conditions (なし: 該当とみなす) | 設定の条件 一致
- SOL-2026-2 UnsoundSpillInMutualRecursion | severity medium
  | introduced 0.7.2 fixed 0.8.36 | conditions {'viaIR': True} | 設定の条件 一致
- SOL-2026-1 TransientStorageClearingHelperCollision | severity high
  | introduced 0.8.28 fixed 0.8.34 | conditions {'viaIR': True, 'evmVersion': '>=cancun'} | 設定の条件 一致
- SOL-2025-1 LostStorageArrayWriteOnSlotOverflow | severity low
  | introduced 0.1.0 fixed 0.8.32 | conditions (なし: 該当とみなす) | 設定の条件 一致
```

Marketのランタイムコードの末尾53バイト（CBORのメタデータ）。`00 08 1e`が0.8.30である。

```
a2 64 69706673 58 22 1220 de70fa9e…f0176fba
      "ipfs"        メタデータのハッシュ
64 736f6c63 43 00081e 0033
   "solc"      0.8.30 長さ0x33
```

バグの説明（description）から取り出したソースの条件を、コメントを除いたMarketのsrcで探した結果と`forge build --offline --force`。`.push(`の1か所はMarket.sol 136行の`assets.push(asset)`で、ビルドの警告がないので、ストレージの末尾の警告もない。

```
layout at: 0か所（コメントを除いたsrc）
transient: 0か所（コメントを除いたsrc）
delete : 0か所（コメントを除いたsrc）
.pop(): 0か所（コメントを除いたsrc）
unchecked: 0か所（コメントを除いたsrc）
assembly: 0か所（コメントを除いたsrc）
.push(: 1か所（コメントを除いたsrc）

$ forge build --offline --force
Compiling 66 files with Solc 0.8.30
Compiler run successful!
```

互いに呼び合う関数の循環はASTで数える。

```
$ solc-0.8.30 --combined-json ast src/*.sol > market_ast.json
$ python -I -X utf8 tools/recur184.py market_ast.json
srcの関数・modifier 54 / 関数同士が呼ぶ辺 18 / 循環に含まれる辺 0
```

| バグ | descriptionに書かれた形 | Marketで探した結果 |
|---|---|---|
| InheritanceOrderReversalOnStorageEndWarning | ストレージの末尾の警告が出るcustom layout | `layout at` 0か所、ビルドの警告0 |
| UnsoundSpillInMutualRecursion | 互いに呼び合う関数の循環 | 循環に含まれる辺0 |
| TransientStorageClearingHelperCollision | transient変数のdeleteとストレージの欄の消去が同じバイトコードに | `transient` 0か所、`delete` 0か所 |
| LostStorageArrayWriteOnSlotOverflow | ストレージの末尾にかかる配列 | `layout at` 0か所、配列はassets一つ（pushだけ） |

`bugs`で、デプロイの設定と同じvia-IRのビルドで`forge test --offline --match-contract Clear184Test -vv`。コンパイルは成功しソースも正しいのに、sが1のまま残る。

```
Ran 2 tests for test/Clear184.t.sol:Clear184Test
[FAIL: storage s: 1 != 0] test_deleteBothClears() (gas: 62248)
Logs:
  s after delete 1
  t after delete 0

[PASS] test_deleteStorageOnlyClears() (gas: 27162)
Suite result: FAILED. 1 passed; 1 failed; 0 skipped
```

via-IRを切った`FOUNDRY_PROFILE=legacy forge test --offline --match-contract Clear184Test -vv`：

```
Ran 2 tests for test/Clear184.t.sol:Clear184Test
[PASS] test_deleteBothClears() (gas: 50188)
Logs:
  s after delete 0
  t after delete 0

[PASS] test_deleteStorageOnlyClears() (gas: 27038)
Suite result: ok. 2 passed; 0 failed; 0 skipped
```

原因はIRで見える（`forge inspect --offline src/Clear184.sol:Clear184 ir`の消去のhelperの部分）。消去のhelperは一つだけで、本体はtransient側への書き込みである。`delete t`と`delete s`が同じhelperを同じ引数`(0x00, 0)`で呼ぶので、実際に消えたのはtransientの欄である。

```
function storage_set_to_zero_t_uint256(slot, offset) {
    let zero_0 := zero_value_for_split_t_uint256()
    update_transient_storage_value_t_uint256_to_t_uint256(slot, offset, zero_0)
}
...
    /// @src 0:326:334  "delete t"
    storage_set_to_zero_t_uint256(0x00, 0)
    /// @src 0:344:352  "delete s"
    storage_set_to_zero_t_uint256(0x00, 0)
```

### 試すときの注意

- バグ一覧は、バージョンごとに既知のバグの名前を書いたファイルである。自分のコードが該当するかは、そのバグの条件を自分の設定とソースに当ててみないとわからない。設定の条件が合えば、次はdescriptionに書かれたコードの形が自分のソースにあるかを探す。
- conditionsのない項目は、ドキュメントのとおり「該当するとみなす」（"If no conditions are given, assume that the bug is present."）。
- `bugs.rst`のキーの説明と`bugs.json`の実際のキーが食い違う。conditionsは説明では`optimizer`・`evmVersion`の二つだけだが、ファイルでは`ABIEncoderV2`・`optimizer`・`yulOptimizer`・`viaIR`・`evmVersion`の五つが使われ、checkは説明の"source-regex"がファイルでは`regex-source`である。ツールを書くときは、ファイルを基準に読む。
- optimizerの条件を`optimizer = false`の一行で済ませない。そのバグがかかる最適化の段階（yulOptimizerなど）が実際に切れているかを見る。
- 一覧にないから安全というわけではない。0.8.30の四つは、すべて0.8.30が出たあとに知られた。バグが新しく知られると古いバージョンの行にも名前が足されるので、写しを取り直すたびに自分のバージョンの行を見直す。
- ソースの条件はコメントを除いて探す（`bugs.rst` "after stripping comments"）。互いに呼び合う関数の循環のようにgrepでは見えない形は、ASTで数える。
- デプロイするビルドでテストを回す。legacyだけで回していたら、Clear184はPASSが二つだった。Clear184からtransientを除くと（ClearOnly184）、via-IRでもPASSである。
- このバグを直した行は、`Changelog.md` 0.8.34のImportant Bugfixesの"Yul IR Code Generation: Fix a bug that could result in clearing a storage variable instead of a transient storage variable at the same position in the layout (and vice-versa)."である。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。バグ一覧は、新しいバグが知られるたびに変わる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solcリポジトリの写し | v0.8.36、コミット8a079791（2026-07-09） | 2026-10-21 |
| bugs.json | 項目63、バージョン120（bugs_by_version.json） | 2026-10-21 |
| バージョンごとの既知のバグの数 | 0.4.24 18・0.5.17 12・0.6.12 12・0.7.6 11・0.8.0 11・0.8.30 4・0.8.36 0 | 2026-10-21 |
| 0.8.30の四つ | SOL-2026-3 InheritanceOrderReversalOnStorageEndWarning（medium、0.8.29〜、0.8.36で修正、条件なし） / SOL-2026-2 UnsoundSpillInMutualRecursion（medium、0.7.2〜、0.8.36、viaIR） / SOL-2026-1 TransientStorageClearingHelperCollision（high、0.8.28〜、0.8.34、viaIR・evmVersion >=cancun） / SOL-2025-1 LostStorageArrayWriteOnSlotOverflow（low、0.1.0〜、0.8.32、条件なし） | 2026-10-21 |
| バージョンの公開日 | 0.8.30 2025-05-07、0.8.32 2025-12-18、0.8.34 2026-02-18、0.8.36 2026-07-09 | 2026-10-21 |
| キーの数 | conditions：ABIEncoderV2 10、optimizer 8、yulOptimizer 6、viaIR 3、evmVersion 2 / check：regex-source 2、ast-compact-json-path 1 / publish 0 / severity：low 23、very low 20、medium 12、medium/high 4、high 3、low/medium 1 | 2026-10-21 |
| optimizerの条件の項目 | optimizer・yulOptimizerの条件13個、0.8.xで直した四つ：KeccakCaching（0.8.3）、FullInlinerNonExpressionSplitArgumentEvaluationOrder（0.8.21）、StorageWriteRemovalBeforeConditionalTermination（0.8.17）、InlineAssemblyMemorySideEffects（0.8.15） | 2026-10-21 |
| Foundry（forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| solc | 0.8.30+commit.73712a01 | 2026-10-21 |
| Marketのビルド | ランタイム2,990バイト、末尾のハッシュの先頭4バイト`de70fa9e`、`forge build`の警告なし | 2026-10-21 |
| Clear184のテストのガス | via-IR：deleteBothClears 62,248 / deleteStorageOnlyClears 27,162。legacy：50,188 / 27,038 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| バージョンを上げる手順とChangelogの照合 | [第186講](../../part11/lecture186/) |
| 監査の範囲にコンパイラのバージョン・設定を入れる | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/) |
| デプロイされた他人のコントラクトからバージョンを読んで一覧に当てる | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| リポジトリのサーバーでバグ一覧の照合を自動で回す | [第258講](../../part20/lecture258/) |
| 条件が合うほかのバグ（UnsoundSpillInMutualRecursionなど）の再現 | 付録 |
| オプティマイザの欠陥の事例それぞれの内容 | 付録 |

出典と参考資料は[reference.md](reference.md)にまとめた。
