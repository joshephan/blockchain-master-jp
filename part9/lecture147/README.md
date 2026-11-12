# 第147講 ドキュメントの生成と活用

第9部 最適化と規律・第37章 NatSpec

[← 第146講](../../part9/lecture146/) | [第9部 目次](../) | [第148講 →](../../part9/lecture148/)

## この講義の問い

書いておいたNatSpecはどの方法で取り出して使い、その方法ごとに何が抜けるのか。ドキュメントを直すとデプロイ物の何が変わり、ドキュメントの抜けや誤りはどこまで機械で防げるのか。

## 実習資料

### 準備

通しプロジェクトMarketの第146講のバージョンから始める。第147講のバージョンはコードが第146講のバージョンと同じで、ABIの項目ごとにuserdocのnoticeがあるかを見るテスト`test/Docs.t.sol`、そのテストが成果物のJSONを読めるようにするfoundry.tomlの`fs_permissions`の1行、コミット前の確認スクリプトの最後の`forge doc --out docs`の段階を足した。ドキュメントのページ（`docs/`）と記録ファイルはツールが作るものなので、ここには入れていない。テストにはforge-stdが必要である（`lib/forge-std`）。ドキュメントの変更がバイトコードとガスに与える影響は、バージョンごとに新しいanvilに第25章の方法でデプロイして測った。`forge doc`は接続なしで動く。ドキュメントのページをサイトとして立ち上げるにはnpmが必要である。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | 第146講のバージョンに`fs_permissions`（out、out-debug、out-legacyの読み取りを許可）の1行を足す |
| [code/market/src/](code/market/src/) | Market第147講のバージョン（第146講のバージョンとコードは同じ、バージョン説明のコメントを1行追加） |
| [code/market/test/Docs.t.sol](code/market/test/Docs.t.sol) | rawMetadataから、関数19個とコンストラクタのnotice、イベント・エラーのnoticeの数がABIの数（4、12）と同じかを確認。ガスの計測は止める |
| [code/market/test/](code/market/test/) | テスト20ファイル（67個のテスト） |
| [code/miss/src/IMarket.sol](code/miss/src/IMarket.sol) | ZeroAmountのnoticeの行を消したコピー |
| [code/paramonly/src/IMarket.sol](code/paramonly/src/IMarket.sol) | TransferFailedに`@param`だけを残したコピー |
| [code/noinh/src/Market.sol](code/noinh/src/Market.sol) | depositの`@inheritdoc IMarket`の行を消したコピー |
| [code/lie/src/IMarket.sol](code/lie/src/IMarket.sol) | withdrawのnoticeを「凍結した市場でも引き出せる」に変えた、うその文言のコピー |
| [code/one/src/IMarket.sol](code/one/src/IMarket.sol) | ZeroAmountのnoticeの末尾に「だ」を1文字付けたコピー（第146講のバージョン基準） |
| [code/zero/src/IMarket.sol](code/zero/src/IMarket.sol) | 「だ」を21文字付けたコピー。末尾のハッシュに00のバイトが一つ混じる（第146講のバージョン基準） |
| [code/demo/fd/src/Bad.sol](code/demo/fd/src/Bad.sol)、[code/demo/fd/foundry.toml](code/demo/fd/foundry.toml) | `@param amout`（名前の誤り）と`@foo`を書いたファイル。`forge doc`と`forge build`を比べる |
| [code/demo/t146/Dyn.sol](code/demo/t146/Dyn.sol) | バッククォートの`` `amount` ``を入れたnotice |
| [code/demo/t146/Ast.sol](code/demo/t146/Ast.sol) | 通常のコメントと`///`コメントを一緒に置いた、AST確認用のファイル |
| [code/demo/t146/OkCustomHyphen.sol](code/demo/t146/OkCustomHyphen.sol) | `@custom:fee-rate`タグ |

コピーのフォルダにはmarketと違うファイルだけを入れた。

### 実行結果

同じMarketのドキュメントを四つの方法で取り出して欄の数を数えた結果。すべての欄があるのはsolcの出力とrawMetadataだけである：

```
## 1) solc --userdoc --devdoc src/Market.sol
src/Market.sol:Market devdoc {'details': 'デプロイするのはこのコントラクト一つ。三つの親(MarketBase、AssetRegistry、Ledger)はabstract', 'errors': 8, 'events': 4, 'kind': 'dev', 'methods': 10, 'stateVariables': 2, 'title': 'レンディング市場', 'version': 1}
src/Market.sol:Market userdoc {'errors': 12, 'events': 4, 'kind': 'user', 'methods': 20, 'notice': '管理者が上場したトークンを預けて引き出す市場。関数・イベント・エラーの説明はIMarket', 'version': 1}
## 2) forge inspect
userdoc {'version': 1, 'kind': 'user', 'methods': 20, 'events': 4, 'errors': 12, 'notice': '管理者が上場したトークンを預けて引き出す市場。関数・イベント・エラーの説明はIMarket'}
devdoc {'version': 1, 'kind': 'dev', 'details': 'デプロイするのはこのコントラクト一つ。三つの親(MarketBase、AssetRegistry、Ledger)はabstract', 'methods': 10, 'events': 4, 'errors': 8, 'title': 'レンディング市場'}
## 3) 成果物のJSONの二つの欄
metadata.output.userdoc {'kind': 'user', 'methods': 20, 'version': 1}
metadata.output.devdoc {'kind': 'dev', 'methods': 10, 'version': 1}
rawMetadata.output.userdoc {'errors': 12, 'events': 4, 'kind': 'user', 'methods': 20, 'notice': '管理者が上場したトークンを預けて引き出す市場。関数・イベント・エラーの説明はIMarket', 'version': 1}
rawMetadata.output.devdoc {'details': 'デプロイするのはこのコントラクト一つ。三つの親(MarketBase、AssetRegistry、Ledger)はabstract', 'errors': 8, 'events': 4, 'kind': 'dev', 'methods': 10, 'stateVariables': 2, 'title': 'レンディング市場', 'version': 1}
rawMetadataのバイト数 16973 \uエスケープの数 980
rawMetadataの中のZeroAmountの断片 "ZeroAmount()":[{"notice":"金額が0"}],"ZeroAsset
## 4) Standard JSON outputSelection
['userdoc', 'devdoc'] exit 0 受け取った欄 ['devdoc', 'userdoc']  errors []
['metadata'] exit 0 受け取った欄 ['metadata'] metadata.outputの欄 ['abi', 'devdoc', 'userdoc'] userdoc methods 20 errors []
['evm.bytecode.object'] exit 0 受け取った欄 ['evm']  errors []
```

`solc --ast-compact-json src/IMarket.sol`では、`///`コメントはdocumentationの節（37個）として残り、`src`のバイトでソースを切り出すとそのコメントがそのまま出てくる。`//`の通常のコメントはASTにない：

```
documentationの節の数 37 種類 ['ContractDefinition', 'EnumDefinition', 'ErrorDefinition', 'EventDefinition', 'FunctionDefinition']
FunctionDefinition deposit src 5388:219:0 text "@notice トークンを預ける。先にこの市場のアドレスにamount分のapproveが必要\n @param asset トークンのアドレス\n @param amount 預ける量(トークンの桁数のまま)"
   ソースのバイトを切り出す: "/// @notice トークンを預ける。先にこの市場のアドレスにamount分のapproveが必要\n    /// @param asset トークンのアドレス\n    /// @param amount 預ける量(トークンの桁数のまま)"
通常のコメント "第101講" がASTにあるか False
```

バージョンごとにバイトコードとメタデータを比べた結果。ランタイム3,260バイトのうち、末尾より前の部分はすべて同じで、末尾のハッシュだけが違う：

| バージョン | 変えたもの | rawMetadata | 末尾のハッシュの先頭4バイト | CREATE2アドレス（salt 0） |
|---|---|---|---|---|
| 第145講のバージョン | ドキュメントなし | 7,949 | `230ac442` | `0x0e6f26DbafB1e8eE8E591562280f9629841524Bc` |
| コメント1行のバージョン | `//`1行 | 7,949 | `bb4becd7` | `0xe06988d60a2968dBD7D134729aa10c473865Eb5E` |
| 第146講のバージョン | NatSpec | 16,973 | `928393e3` | `0x01977bcB821E1508A451F168d0c8eEee40d52899` |
| 第147講のバージョン | バージョン説明のコメント | 16,973 | `29d59302` | `0xee09C7adfe10b28A391f9312A14472194be03eE9` |
| 1文字のバージョン | noticeに「だ」 | 16,979 | `198c16c5` | `0x8420Cb8c494CAf2185ED4b8cDba547db178B2d4f` |
| 00が混じったバージョン | noticeに「だ」21文字 | 17,099 | `f44efdcf` | `0xfe48452576bBc122dd36DE98FdF06189659fA3eE` |

コメント1行のバージョンは、メタデータのsourcesの欄の二つ（`keccak256`、`urls`）だけが変わる。レシートのgasUsedは六つのバージョンとも六つの呼び出しが同じで（addAsset 92,656、deposit 127,515、withdraw 57,448、setStatus 45,001 / 23,089、失敗26,264）、デプロイは760,316である。00が混じったバージョンだけデプロイが760,304である（デプロイデータの0でないバイトが3,311から3,310に一つ減り、16 - 4 = 12ガス少ない）。

`forge doc`は第147講のバージョンで`Generated 16 pages from 5 sources`で終わる。間違ったタグのファイル（`Bad.sol`）では、知らないタグだけを警告して終了コード0である：

```
warning[6546]: invalid natspec tag '@foo', custom tags must use format '@custom:name'
  ╭▸ src/Bad.sol:7:5
  │
7 │     /// @foo 存在しないタグ
  ╰╴    ━━━━━━━━━━━━━━━━━━━━━━━

Generating documentation...
Generated 1 page from 1 source in 5.37ms (render 2.54ms, site 2.82ms)
```

同じファイルを`forge build`すると、3881（`@param amout`）と6546（`@foo`）で失敗する。

Docsのテストをコピーで実行した結果：ZeroAmountのnoticeを消したバージョンと、TransferFailedに`@param`だけを残したバージョンは`[FAIL: assertion failed: 11 != 12]`、`@inheritdoc`を抜いたバージョンは`[FAIL: deposit(address,uint256)]`である。うその文言のバージョンはテスト67個がすべて通り、凍結した市場の引き出しを巻き戻すテスト（`test_marketFrozen`、`test_frozenBlocksWithdrawAll`）も通る。

第147講のバージョンの`forge test`のDocsの2行：

```
[PASS] test_everyEventAndErrorHasNotice() (gas: 3121)
[PASS] test_everyFunctionHasNotice() (gas: 3091)
```

サイズ（runtime / creation）はdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931で、三つのプロファイルともテスト67個が通る。五段階の確認は最後に`ci ok`を出力する。`.gas-snapshot`はDocsの2行が加わって67行、`snapshots/Market.json`は第145講のバージョンのままである。

### 試すときの注意

- 成果物のJSONの`metadata`の欄はforgeが書き直した整理版なので、userdocのevents・errors・notice、devdocのevents・errors・stateVariables・title・detailsが抜ける。ハッシュと一致し、欄がすべてあるのは`rawMetadata`である。DocsのテストがrawMetadataを読む理由である。
- `fs_permissions`の行を抜いても、Foundryの既定値が`out`の読み取りを許可しているので、defaultの`forge test`は通る。`FOUNDRY_PROFILE=debug`・`legacy`では`vm.readFile: the path out-debug/Market.sol/Market.json is not allowed to be accessed for read operations`でDocsの二つのテストが失敗する。この行はバイトコードとrawMetadataを変えない。
- Docsのテストから`vm.pauseGasMetering()`を抜くと、テストのガス（317,170 / 208,794）が読むJSONの長さと成果物のパスの長さによって変わる。noticeの末尾に「だ」を21文字足すと317,979 / 209,696に変わり、`forge snapshot --check`が失敗した。止めたバージョンはパスが違っても3,121 / 3,091である。
- Standard JSONで`evm.bytecode.object`だけを選んでも、生成コードの末尾のハッシュはドキュメントが入ったメタデータのハッシュである。ドキュメントの出力を選ばなくても、メタデータにはドキュメントが入る。
- `forge doc`のページはソースを別に読んで作る。Marketのページには、Marketに書いたものとMarketで宣言した関数だけが出て、depositはLedgerのページにある。internal関数も説明が空欄のままページに出る。
- バッククォートで囲んだ`` `amount` ``は、solc 0.8.30がそのまま渡す。値を埋めて見せるのは読むプログラムの役目である。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。コンパイラとツールのバージョンが変わると、出力の形と数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。第147講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyがデフォルトの経路 + optimizerオン、debugがデフォルトの経路でoptimizerオフ、evm_version osaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| 公式ドキュメントの版 | Solidity NatSpec Format v0.8.36。引用18〜20、22〜23、30〜32、140〜156、180〜185行。Contract Metadata 243〜254行 | 2026-10-20 |
| forgeの整理版で抜ける欄 | `forge inspect … devdoc`：stateVariablesなし。成果物のJSONの`metadata`の欄：userdocのevents・errors・notice、devdocのevents・errors・stateVariables・title・detailsなし。欄がすべてあるのは`rawMetadata`とsolcの出力 | 2026-10-20 |
| forge docの出力の形 | `docs/src/pages/**.mdx`とvocsのサイトのひな形（package.json、vocs.config.ts、vocs.sidebar.ts）、サイトとして立ち上げるには`npm install --legacy-peer-deps`・`npm run dev`。間違った`@param`の名前は警告なしで通す、知らないタグは`warning[6546]` | 2026-10-20 |
| Foundryの既定のfs_permissions | `[[profile.default.fs_permissions]] access = "read" path = "out"`（行を書かないとき） | 2026-10-20 |
| rawMetadataのサイズ | 第145講のバージョン7,949バイト、第146・147講のバージョン16,973バイト（`\u` 980個）、noticeに1文字のバージョン16,979、00が混じったバージョン17,099 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第145講のバージョン`230ac442`、コメント1行のバージョン`bb4becd7`、第146講のバージョン`928393e3`、第147講のバージョン`29d59302`、noticeに1文字のバージョン`198c16c5`、00が混じったバージョン`f44efdcf`（ハッシュの中ほど`…0315c70200fb5025…`） | 2026-10-20 |
| CREATE2アドレス | デプロイヤー`0x4e59b44847b379578588920cA78FbF26c0B4956C`、salt 0、生成コード + コンストラクタの引数（アカウント0番、5e16、80）3,569バイト。第145講のバージョン`0x0e6f26DbafB1e8eE8E591562280f9629841524Bc`、コメント1行`0xe06988d60a2968dBD7D134729aa10c473865Eb5E`、第146講のバージョン`0x01977bcB821E1508A451F168d0c8eEee40d52899`、第147講のバージョン`0xee09C7adfe10b28A391f9312A14472194be03eE9`、1文字`0x8420Cb8c494CAf2185ED4b8cDba547db178B2d4f`、00が混じったバージョン`0xfe48452576bBc122dd36DE98FdF06189659fA3eE` | 2026-10-20 |
| デプロイデータのバイトの値 | 0のバイト4、0でないバイト16（EIP-2028）。デプロイの入力の0でないバイト3,311（00が混じったバージョンは3,310） | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第145・146・147講のバージョン、コメント1行のバージョン、1文字のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264。00が混じったバージョンはデプロイ760,304、呼び出しは同じ | 2026-10-20 |
| Docsのテストのガス | `vm.pauseGasMetering`あり3,121 / 3,091。抜いたコピー317,170 / 208,794、そこにnoticeの「だ」21文字317,979 / 209,696、同じコピーをパスの長さが違うフォルダ（159文字、206文字）で317,093 / 208,726、317,247 / 208,862、debugプロファイル506,559 / 342,637。ありのバージョンはパスの長さ6文字・158文字・163文字・206文字のフォルダで3,121 / 3,091、`forge snapshot --check`が通る | 2026-10-20 |
| サイズ（runtime / creation） | 第147講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 行番号 | 第147講のバージョンdebug deposit 0 src/Market.sol 160:33、NotActive 75行、`contract Market` 204行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（anvilの既定のアカウント、公開されたテスト用の鍵） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ドキュメントのページをサイトとして立ち上げ、リポジトリのサーバーで作る | [第258講](../../part20/lecture258/) |
| 検証サービスに上げたメタデータのドキュメントを見る | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| 監査でドキュメントとコードが食い違う場所を見つける | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| `@custom`タグを読む分析・検証ツール | [第182講](../../part11/lecture182/)、[第183講](../../part11/lecture183/) |
| アップグレードツールが読む印と実装コントラクトのドキュメント | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| デプロイのcalldataの0のバイトと手数料 | [第229講](../../part17/lecture229/)〜[第234講](../../part17/lecture234/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
