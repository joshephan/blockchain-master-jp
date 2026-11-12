# 第149講 命名規則

第9部 最適化と規律・第38章 スタイルガイド

[← 第148講](../../part9/lecture148/) | [第9部 目次](../) | [第150講 →](../../part9/lecture150/)

## この講義の問い

スタイルガイドの名前の規則のうち、コンパイラが止めるもの、リントが捕まえるもの、人にしか見えないものはそれぞれ何か。規則に合わせようと名前を変えると、デプロイ物の何が変わるのか。

## 実習資料

### 準備

通しプロジェクトMarketの第148講のバージョンから始める。第149講のバージョンはコードが第148講のバージョンと同じで、PositionLibの`credit`・`debit`の最初の引数名だけを`p`から`self`に変えた（internal関数なのでABIとセレクタはそのまま）。コミット前の確認スクリプトの2番目の段階に、名前のチェックを四つ足した：`forge lint --offline --only-lint mixed-case-function mixed-case-variable pascal-case-struct screaming-snake-case-const --deny notes`。foundry.tomlには、immutableの大文字の規則を入れなかった理由をコメント1行で書いた。テストにはforge-stdが必要である（`lib/forge-std`）。

名前を一つずつビルドするデモは、solc 0.8.30を直接呼んで`solc --bin --error-codes ファイル.sol`で見る。リントのデモは、空のFoundryプロジェクト（`demo/p149`）で`forge lint --offline src/Names.sol --severity info`のようにパスを先に書く（`--severity`が値を複数受け取るため）。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | 第148講のバージョンに名前のチェックのコメント1行を足す |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | PositionLibの最初の引数`self` |
| [code/market/src/](code/market/src/) | Market第149講のバージョン |
| [code/market/test/](code/market/test/) | テスト20ファイル（67個のテスト） |
| [code/imm/src/Market.sol](code/imm/src/Market.sol) | immutableの`admin`を`ADMIN`に変えたコピー（IMarketはそのままなのでビルドが失敗） |
| [code/shadow/src/Market.sol](code/shadow/src/Market.sol) | MarketBaseのコンストラクタの引数`admin_`のアンダースコアを抜いたコピー |
| [code/namebad/src/Market.sol](code/namebad/src/Market.sol) | depositのローカル変数`ok`を`Ok`に変えたコピー（名前のチェックの段階で止まる） |
| [code/demo/p149/src/Names.sol](code/demo/p149/src/Names.sol) | スタイルガイドの名前の規則に反する名前を集めたファイル |
| [code/demo/p149/src/Caps.sol](code/demo/p149/src/Caps.sol) | `$balance`、interfaceとcontractの中の大文字の関数 |
| [code/demo/p149/foundry.toml](code/demo/p149/foundry.toml) | リントのデモ用プロジェクトの設定 |
| [code/demo/id149/](code/demo/id149/) | 名前を一つずつ宣言したファイル十六個（`alias`、`1st`、`$balance`、`残高`、`this`、`_`など） |

コピーのフォルダにはmarketと違うファイルだけを入れた。

### 実行結果

名前を一つずつ`solc --bin --error-codes`でビルドした結果：

```
== alias.sol: uint256 public alias;
Error (2314): Expected identifier but got reserved keyword 'alias'
exit 1
== at_.sol: uint256 public at;
exit 0
== digit.sol: uint256 public 1st;
Error (2314): Expected identifier but got 'ILLEGAL'
exit 1
== dollar.sol: uint256 public $balance;
exit 0
== error_.sol: uint256 public error;
exit 0
== hangul.sol: uint256 public 残高;
Error (2314): Expected identifier but got 'ILLEGAL'
exit 1
== keccak.sol: function keccak256(bytes memory) public pure returns (bytes32) {}
Warning (2319): This declaration shadows a builtin symbol.
exit 0
== layout_.sol: uint256 public layout;
exit 0
== leave_.sol: uint256 public leave;
exit 0
== msg_.sol: uint256 public msg;
Warning (2319): This declaration shadows a builtin symbol.
exit 0
== now_.sol: uint256 public now;
Warning (2319): This declaration shadows a builtin symbol.
exit 0
== super_.sol: uint256 public super;
Error (3726): The name "super" is reserved.
Warning (2319): This declaration shadows a builtin symbol.
exit 1
== this_.sol: uint256 public this;
Error (3726): The name "this" is reserved.
Warning (2319): This declaration shadows a builtin symbol.
exit 1
== transient_.sol: uint256 public transient;
exit 0
== underscore_only.sol: uint256 public _;
Error (3726): The name "_" is reserved.
exit 1
== var_.sol: uint256 public var;
Error (2314): Expected identifier but got reserved keyword 'var'
exit 1
```

Names.solに既定の`forge lint`をかけても、名前のnoteは一つも出ない。`--severity info`を付けると出る（前半）：

```
note[pascal-case-struct]: struct name is not `PascalCase`
  ╭▸ src/Names.sol:4:8
  │
4 │ struct bank {
  │        ━━━━ help: consider using: `Bank`
note[screaming-snake-case-const]: constant name is not `SCREAMING_SNAKE_CASE`
   ╭▸ src/Names.sol:21:22
   │
21 │     uint256 constant maxBlocks = 10;
   │                      ━━━━━━━━━ help: consider using: `MAX_BLOCKS`
note[screaming-snake-case-immutable]: immutable name is not `SCREAMING_SNAKE_CASE`
   ╭▸ src/Names.sol:23:23
   │
23 │     address immutable creator;
   │                       ━━━━━━━ help: consider using: `CREATOR`
note[mixed-case-variable]: mutable variable name is not `mixedCase`
   ╭▸ src/Names.sol:25:20
   │
25 │     uint256 public TotalSupply;
   │                    ━━━━━━━━━━━ help: consider using: `totalSupply`
```

forge lintが捕まえる名前は、構造体、定数、immutable、状態変数、関数、modifier、引数、ローカル変数である。コントラクト・ライブラリ・enum・enumの値・イベント・エラーの名前、l・O・I、略語、ライブラリの最初の引数`self`、アンダースコアの規則は捕まえない。interfaceの中の大文字の関数は捕まえず、contractの中は捕まえる。

第148講のバージョンのMarketに既定の`forge lint`をかけると、warningを五つ（unsafe-typecast二つ、reentrancy-events二つ、missing-zero-check一つ）出して終了コード0である。名前の話は出ない。第149講のバージョンに`--severity info`を付けると、immutable三つに`screaming-snake-case-immutable`のnoteが付く。

ABIに出る名前を変えると、セレクタが変わる（`cast sig`）：

```
admin() 0xf851a440
ADMIN() 0x2a0acc6a
interestRate() 0x7c3a00fd
INTEREST_RATE() 0x5b72a33a
collateralRatio() 0xb4eae1cb
COLLATERAL_RATIO() 0xd9e69a05
SECONDS_PER_YEAR() 0xe6a69ab8
secondsPerYear() 0x252e40b1
```

Market.solのimmutableだけを`ADMIN`に変えたコピーは、IMarketの`admin()`が実装されないのでビルドが失敗する：

```
Error (3656): Contract "Market" should be marked as abstract.
   --> src/Market.sol:206:1:
    |
206 | contract Market is AssetRegistry, Ledger {
    | ^ (Relevant source part starts here and spans across multiple lines).
Note: Missing implementation: 
   --> src/IMarket.sol:129:5:
    |
129 |     function admin() external view returns (address);
    |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

コンストラクタの引数のアンダースコアを抜いたコピーは警告一つでビルドが終わり、immutableのadminには値が入らない：

```
Warning (2519): This declaration shadows an existing declaration.
  --> src/Market.sol:56:17:
   |
56 |     constructor(address admin) {
   |                 ^^^^^^^^^^^^^
Note: The shadowed declaration is here:
  --> src/Market.sol:53:5:
   |
53 |     address public immutable admin;
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

そのコピーの`forge test`：

```
Ran 22 test suites in 6.33ms (17.72ms CPU time): 9 tests passed, 24 failed, 0 skipped (33 total tests)
[FAIL: assertion failed: 0x0000000000000000000000000000000000000000 != 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496] test_constructorArgsReachBases() (gas: 8764)
```

ローカル変数の名前を`Ok`に変えたコピーは、コミット前の確認の2番目の段階で止まる：

```
note[mixed-case-variable]: mutable variable name is not `mixedCase`
    ╭▸ src/Market.sol:154:14
    │
154 │         bool Ok = IERC20(asset).transferFrom(msg.sender, address(this), amount); // 第83講
    │              ━━ help: consider using (notice the capitalization): `ok`
    │
    ╰ help: https://getfoundry.sh/forge/linting/mixed-case-variable
Error: aborting due to 1 linter note(s)
exit 1
```

第149講のバージョンは名前のチェック四つが終了コード0、サイズ（runtime / creation）はdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931、三つのプロファイルでテスト67個が通る。コミット前の確認は`ci ok`で終わる。レシートのgasUsedはデプロイ760,316（第148講のバージョンも760,316）、六つの呼び出しも同じである（addAsset 92,656、deposit 127,515、withdraw 57,448、setStatus 45,001 / 23,089、失敗26,264）。PositionLibの引数名を変えただけで末尾のメタデータのハッシュは変わるが、ハッシュの中の0のバイトの数が同じなので、デプロイのガスは変わらない。

### 試すときの注意

- 既定の`forge lint`はseverityのhigh・med・lowだけを見せ、名前のチェック（info）は見せない。静かだからといって名前がすべて合っているわけではない。
- forge lintの`screaming-snake-case-immutable`と`interface-file-naming`は、スタイルガイドにない規則である。immutable三つを大文字に変えると自動ゲッターのセレクタが変わるので、Marketはこの規則を名前のチェックから外した。
- スタイルガイドにはエラーの名前の節がない。Marketのエラーはイベントと同じくCapWordsで書いた。
- 定数`SECONDS_PER_YEAR`の自動ゲッターは関数なのに大文字である。定数の規則と関数の規則がぶつかる場所である。
- `forge lint --deny warnings`をオンにすると、第149講のバージョンも残った警告五つのために失敗する。これらの警告はコミット前の確認に入れていない。
- 0.8.30では`this`・`super`・`_`はすでに3726で止められ、ドキュメントのnoteが今後止める名前として挙げた`at`、`error`、`layout`、`leave`、`transient`は通る。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。コンパイラとツールのバージョンが変わると、規則と数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。第149講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyがデフォルトの経路 + optimizerオン、debugがデフォルトの経路でoptimizerオフ、evm_version osaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3（Commit `cae51ad`） | 2026-10-20 |
| 公式ドキュメントの版 | v0.8.36。style-guide.rst 1102〜1111（名前の規則の冒頭）、1120〜1128（名前の形と略語のnote）、1134〜1139（l・O・I）、1145〜1147（コントラクト・ファイルの名前）、1233・1239・1245・1251・1253〜1254・1260・1266〜1267・1273・1279（項目別）、1285〜1288（末尾のアンダースコア）、1293〜1303（先頭のアンダースコア）。SolidityLexer.g4 3〜10（ReservedKeywords）、251〜259（Identifier）。units-and-global-variables.rst 429〜442（Reserved Keywordsとnote）。ドキュメントにエラーの名前の節はない | 2026-10-20 |
| エラー番号（solc 0.8.30） | 2314 Expected identifier、3726 name is reserved、2319 shadows a builtin symbol、2519 shadows an existing declaration、3656 should be marked as abstract | 2026-10-20 |
| 0.8.30がすでに止める名前 | `this`、`super`、`_`（3726）。ドキュメントのnoteの`at`、`error`、`layout`、`leave`、`transient`は通る | 2026-10-20 |
| forge lint（1.8.3） | 既定のseverityはhigh・med・low、名前のチェックはinfo。名前の規則五つmixed-case-function、mixed-case-variable、pascal-case-struct、screaming-snake-case-const、screaming-snake-case-immutable。ファイル名interface-file-naming。noteの文言`help: consider using: …`。`--deny warnings`・`--deny notes`で終了コード1。`--severity`は値を複数受け取るのでパスを先に書く | 2026-10-20 |
| セレクタ | `admin()` 0xf851a440、`ADMIN()` 0x2a0acc6a、`interestRate()` 0x7c3a00fd、`INTEREST_RATE()` 0x5b72a33a、`collateralRatio()` 0xb4eae1cb、`COLLATERAL_RATIO()` 0xd9e69a05、`SECONDS_PER_YEAR()` 0xe6a69ab8 | 2026-10-20 |
| サイズ（runtime / creation） | 第149講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第148講のバージョンdefault `edd3401a`、legacy `2db8a714`、debug `8d2b6100` / 第149講のバージョン`f97f2ac0`、`9985f39b`、`324d571b` | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第149講のバージョンのデプロイ760,316（第148講のバージョンも760,316）、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264。MockToken `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Market `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` | 2026-10-20 |
| 行番号 | 第149講のバージョンdebug deposit 0 src/Market.sol 162:33、NotActive 77行、`contract Market` 206行。リントの警告MarketMath 33・41、Market 156・166・171。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（anvilの既定のアカウント、公開されたテスト用の鍵）。テストコントラクトのアドレス`0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496` | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Marketに残ったリントの警告：reentrancy-events二つ | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/) |
| Marketに残ったリントの警告：missing-zero-check一つ | [第170講](../../part11/lecture170/)、[第176講](../../part11/lecture176/) |
| Marketに残ったリントの警告：unsafe-typecast二つ | [第186講](../../part11/lecture186/) |
| 同じ名前の関数・イベントがほかのコントラクトと重なることと標準の名前 | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| プロキシの後ろの実装で名前を変えること | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 監査で名前とやることが食い違う場所を見つける | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| リポジトリのサーバーでリントを実行する | [第258講](../../part20/lecture258/) |
| 予約語がバージョンごとに変わった履歴 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/)、付録の時効性シート |

出典と参考資料は[reference.md](reference.md)にまとめた。
