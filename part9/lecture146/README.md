# 第146講 NatSpecのタグ体系

第9部 最適化と規律・第37章 NatSpec

[← 第145講](../../part9/lecture145/) | [第9部 目次](../) | [第147講 →](../../part9/lecture147/)

## この講義の問い

NatSpecのタグはどこに何を書けて、コンパイラはそのうち何を止め、何をドキュメントとして出力するのか。継承した関数とインターフェースに書いたドキュメントは、デプロイするコントラクトのドキュメントにどう入るのか。

## 実習資料

### 準備

通しプロジェクトMarketの第145講のバージョンから始める。第146講のバージョンはコードが第145講のバージョンと同じで、`IMarket.sol`のABIの項目ごとにNatSpecを書き、`Market.sol`の3か所（コントラクトの上、コンストラクタ、depositの`@inheritdoc`・`@dev`）にドキュメントを足した。第144講のバージョン説明のコメント1行も事実どおりに直した（GuardsのテストはInsufficientDepositのチェックを、`LibraryTest:test_amountOperators`はAmountの`-`のあふれのチェックを確かめ、assertの行を捕まえるテストはない）。テストにはforge-stdが必要である（`lib/forge-std`）。

タグのデモでは、solc 0.8.30を直接呼んで`solc --userdoc --devdoc ファイル.sol`で二つのドキュメントを出力する。エラー番号は、空のFoundryプロジェクト（`natspec/fb`）の`src/`に間違ったタグのファイルを一つずつ入れ、`forge build`で見る（solcを直接呼ぶと、同じ文に番号が付かない）。anvilは使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | 第145講のバージョンと同じ（defaultはvia-IR + optimizer、`legacy`・`debug`プロファイル） |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | 冒頭のtitle・notice・dev、enumのnotice、イベント四つ、エラー十二個（引数のある八つは`@param`）、関数十九個のNatSpec |
| [code/market/src/Market.sol](code/market/src/Market.sol) | コントラクトの上のtitle・notice・dev、コンストラクタのドキュメント、depositの上の`@inheritdoc IMarket`と`@dev` |
| [code/market/src/](code/market/src/) | 残りのソース（第145講のバージョンと同じ） |
| [code/market/test/](code/market/test/) | テスト19ファイル（65個のテスト） |
| [code/noinh/src/Market.sol](code/noinh/src/Market.sol) | depositの上の`/// @inheritdoc IMarket`の1行を抜いたコピー。ほかのファイルはmarketと同じ |
| [code/natspec/c/ex1.sol](code/natspec/c/ex1.sol) | 公式ドキュメントNatSpec Format 61〜104行の例（Tree、Plant、KumquatTree） |
| [code/natspec/t146/Kinds.sol](code/natspec/t146/Kinds.sol) | コントラクト・関数・publicのマッピング・internal変数・イベント・エラー・コンストラクタ・receive・enum・structにドキュメントを一つずつ書いたファイル |
| [code/natspec/t146/Inherit.sol](code/natspec/t146/Inherit.sol) | インターフェースIBoxと実装四つ（Aはドキュメントなし、Bは`@dev`1行、Cは引数名を変更、Dは`@inheritdoc IBox` + `@dev`） |
| [code/natspec/t146/TwoBases.sol](code/natspec/t146/TwoBases.sol) | 親が二つのとき（K1）、`@inheritdoc Tree`（K2）、親が一つ（K3） |
| [code/natspec/t146/SV.sol](code/natspec/t146/SV.sol) | public状態変数のドキュメントがどのコントラクトのdevdocに載るか |
| [code/natspec/t146/Block.sol](code/natspec/t146/Block.sol) | `/** */`の形、タグのない`///`2行、`@notice`を2回 |
| [code/natspec/t146/Dyn.sol](code/natspec/t146/Dyn.sol) | バッククォートを入れたnotice |
| [code/natspec/t146/](code/natspec/t146/) | `Bad*.sol`二十一ファイルと`OkCustomHyphen.sol`：タグを一つずつ間違えて書いたファイル |
| [code/natspec/fb/foundry.toml](code/natspec/fb/foundry.toml) | エラー番号を見る空のFoundryプロジェクトの設定 |

### 実行結果

`solc --userdoc --devdoc ex1.sol`のTreeの部分。公式ドキュメント204〜262行と同じで、キーの順番だけがアルファベット順である：

```
======= ex1.sol:Tree =======
Developer Documentation
{"author":"Larry A. Gardner","custom:experimental":"This is an experimental contract.","details":"All function calls are currently implemented without side effects","kind":"dev","methods":{"age(uint256)":{"details":"The Alexandr N. Tetearing algorithm could increase precision","params":{"rings":"The number of rings from dendrochronological sample"},"returns":{"_0":"Age in years, rounded up for partial years","_1":"Name of the tree"}},"leaves()":{"details":"Returns only a fixed number."}},"title":"A simulator for trees","version":1}
User Documentation
{"kind":"user","methods":{"age(uint256)":{"notice":"Calculate tree age in years, rounded up, for live trees"},"leaves()":{"notice":"Returns the amount of leaves the tree has."}},"notice":"You can use this contract for only the most basic simulation","version":1}
```

KumquatTreeはageをドキュメントなしで継承し、leavesは自分のnoticeと`@inheritdoc Tree`で持ってきたdetailsを使う。コントラクトの上のtitle・author・noticeは継承しない：

```
======= ex1.sol:KumquatTree =======
Developer Documentation
{"kind":"dev","methods":{"age(uint256)":{"details":"The Alexandr N. Tetearing algorithm could increase precision","params":{"rings":"The number of rings from dendrochronological sample"},"returns":{"_0":"Age in years, rounded up for partial years","_1":"Name of the tree"}},"leaves()":{"details":"Returns only a fixed number."}},"version":1}
User Documentation
{"kind":"user","methods":{"age(uint256)":{"notice":"Calculate tree age in years, rounded up, for live trees"},"leaves()":{"notice":"Return the amount of leaves that this specific kind of tree has"}},"version":1}
```

間違ったタグのファイルを一つずつ`forge build`した結果：

```
== BadTitleFn
Error (6546): Documentation tag @title not valid for functions.
== BadReturnCount
Error (2604): Documentation tag "@return b 二つ目" exceeds the number of return parameters.
== BadReturnName
Error (5856): Documentation tag "@return b 名前が違う" does not contain the name of its return parameter.
== BadInheritNoSuch
Error (9397): Documentation tag @inheritdoc references inexistent contract "J".
== BadInheritNotBase
Error (4682): Documentation tag @inheritdoc references contract "J", but the contract does not contain a function that is overridden by this function.
== BadInheritContract
Error (6546): Documentation tag @inheritdoc not valid for contracts.
== BadCustomUpper
Error (2968): Invalid character in custom tag @custom:Fee. Only lowercase letters and "-" are permitted.
== BadCustomHyphen
Error (2968): Invalid character in custom tag @custom:-fee. Only lowercase letters and "-" are permitted.
== BadCustomEmpty
Error (6564): Custom documentation tag must contain a chosen name, i.e. @custom:mytag.
== BadReturnInternalVar
Error (6546): Documentation tag @return not valid for non-public state variables.
== BadParamInternalFn
Error (3881): Documented parameter "y" not found in the parameter list of the function.
== BadTagInternalFn
Error (6546): Documentation tag @foo not valid for functions.
== BadParamEvent
Error (3881): Documented parameter "who" not found in the parameter list of the function.
== BadParamError
Error (3881): Documented parameter "who" not found in the parameter list of the function.
== BadUpperNotice
Error (6546): Documentation tag @Notice not valid for functions.
== BadParamStateVar
Error (6546): Documentation tag @param not valid for public state variables.
== BadDevModifierParam
Error (3881): Documented parameter "z" not found in the parameter list of the function.
== OkCustomHyphen exit 0
== BadReturnEvent exit 0
== BadNoticeInternalVar exit 0
== BadNoticePrivateVar exit 0
```

（各エラーの前の`Error: Compiler run failed:`の行は省いた。）最後の四つは終了コード0である。`@custom:fee-rate`はdevdocにだけ載り、イベントの`@return`とinternal・private変数の`@notice`はエラーなしで出力から抜ける。

Inherit.solの結果の要約（userdocの`put`）：

| 実装 | 書いたもの | userdoc `put(uint256)` | devdoc `put(uint256)` |
|---|---|---|---|
| A | なし | インターフェースのnotice | インターフェースのdev・param |
| B | `@dev`1行 | なし | Bのdevだけ |
| C | 引数名をxに | なし | なし |
| D | `@inheritdoc IBox` + `@dev` | インターフェースのnotice | Dのdevとインターフェースのparam |

Market第146講のバージョンのドキュメントの欄の数（rawMetadata基準）：

```
raw bytes 16973 980
{'errors': 12, 'events': 4, 'kind': 'user', 'methods': 20, 'notice': '管理者が上場したトークンを預けて引き出す市場。関数・イベント・エラーの説明はIMarket', 'version': 1}
{'details': 'デプロイするのはこのコントラクト一つ。三つの親(MarketBase、AssetRegistry、Ledger)はabstract', 'errors': 8, 'events': 4, 'kind': 'dev', 'methods': 10, 'stateVariables': 2, 'title': 'レンディング市場', 'version': 1}
```

userdocの関数20個は、IMarketから継承した19個とMarketに書いたconstructorである。`@inheritdoc`の行を抜いたコピー（noinh）はuserdocの関数が19個で、depositがない。devdocのdepositには`@dev`だけが残る。

第146講のバージョンのサイズ（runtime / creation）はdefault 3,260 / 3,473、debug 7,353 / 7,931、legacy 3,755 / 4,013で、第145講のバージョンと同じである。三つのプロファイルともテスト65個が通り、`forge snapshot --check`は終了コード0、呼び出しのガスの記録もそのままである。ランタイムは末尾のメタデータのハッシュ32バイトだけが違う。

### 試すときの注意

- 第145講のバージョン（ドキュメントなし）では、`forge inspect Market userdoc`は`{"version": 1, "kind": "user"}`の二つの欄しか見えない。`methods`の欄まで入った形はrawMetadataにある。
- `forge inspect Market devdoc`（Foundry 1.8.3）にはstateVariablesの欄が見えない。欄をすべて見るには`out/Market.sol/Market.json`のrawMetadataを開く。
- solcの出力とrawMetadataの中の日本語は`\uXXXX`エスケープで出る（例：`"引き出す"` = 「引き出す」）。`forge inspect`は文字に戻して見せる。
- 自動ゲッターの`@return`・`@param`は、その変数を宣言したコントラクトのdevdocのstateVariablesに載る。Marketの自動ゲッター八つは親で宣言しているので、MarketのdevdocのstateVariablesにはない。
- public変数に`@dev`だけを書くと、userdocからそのゲッターが抜ける（継承が切れる）。
- enum・enumの値・structの上のドキュメントと、receiveの上のドキュメントは、solc 0.8.30の出力にない。ドキュメントのタグの表にはenum・structがある。
- `/** */`の形は行頭の空白が残り、`@notice`を2回書くと間に空白なしで`最初のnotice二つ目のnotice`とつながる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。コンパイラとツールのバージョンが変わると、出力の形と数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメントの版 | Solidity NatSpec Format v0.8.36。引用7〜9・18〜20・22〜23・39〜42・55〜59・61〜104・111〜114・116〜127・129〜133・163〜168・180〜185・189〜191・204〜262・221〜224行 | 2026-10-20 |
| solc | 0.8.30。第146講のバージョンはdefaultがvia-IR + optimizerオン、legacyがデフォルトの経路 + optimizerオン、debugがデフォルトの経路でoptimizerオフ | 2026-10-20 |
| Foundry（forge） | 1.8.3 | 2026-10-20 |
| エラー番号 | 6546（その場所に使えないタグ）、2604（`@return`の個数超過）、5856（戻り値の名前がない）、3881（ドキュメントの引数名がない、イベント・エラー・modifierでも"of the function"）、9397（`@inheritdoc`が存在しないコントラクト）、4682（`@inheritdoc`が親でない）、2968（customの名前の文字）、6564（customの名前がない）。solcを直接呼ぶと同じ文に番号なし | 2026-10-20 |
| 出力にないドキュメント | solc 0.8.30：enum・enumの値・structの上のドキュメント、receiveの上のドキュメント、イベントの`@return`、internal・private変数の`@notice`は終了コード0で、userdoc・devdocにない。ドキュメントのタグの表にはenum・structがある | 2026-10-20 |
| forgeの整形版 | `forge inspect Market devdoc`（1.8.3）にはstateVariablesの欄が見えない。欄の全体は`out/Market.sol/Market.json`のrawMetadata | 2026-10-20 |
| 日本語のドキュメントの形 | solcの出力とrawMetadataの中では`\uXXXX`エスケープ（例：`"引き出す"` = 「引き出す」）、forge inspectは文字に戻して見せる。第146講のバージョンのrawMetadata 16,973バイト（`\u` 980個）、第145講のバージョン7,949バイト | 2026-10-20 |
| サイズ（runtime / creation） | 第146講のバージョンdefault 3,260 / 3,473、debug 7,353 / 7,931、legacy 3,755 / 4,013（第145講のバージョンと同じ） | 2026-10-20 |
| 末尾のハッシュ | 第145講のバージョン`230ac442…`、第146講のバージョン`928393e3…`（ランタイムの末尾53バイトのうち32バイトだけが違う） | 2026-10-20 |
| 行番号 | 第146講のバージョンdebug deposit 0 src/Market.sol 159:33、NotActive 74行、`contract Market` 203行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| ガス | Marketの呼び出しのガスは第145講のバージョンのまま（snapshots/Market.json：addAsset75 92656、deposit100 127515、failDeposit0 26264、setStatus0 23089、setStatus1 45001、withdraw30 57448）、`.gas-snapshot` 65行もそのまま | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| NatSpecがメタデータのハッシュ・デプロイ物・ガスに与える影響 | [第147講](../../part9/lecture147/) |
| ドキュメントの出力を取り出す方法（solc、forge、Standard JSON）とドキュメントのページ | [第147講](../../part9/lecture147/) |
| コメント・NatSpecの位置と書く順番の規則 | [第148講](../../part9/lecture148/) |
| 監査でドキュメントとコードが食い違う場所を見つける | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| プロキシの後ろの実装コントラクトのドキュメント | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| `@custom`タグを読む分析・検証ツール | [第182講](../../part11/lecture182/)、[第183講](../../part11/lecture183/) |
| enum・structのドキュメントが出力に入るバージョン | 付録の時効性シート |

出典と参考資料は[reference.md](reference.md)にまとめた。
