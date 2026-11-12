# 第127講 言語の文法規格の読み方

第7部 アセンブリとYul・第29章 チートシートと文法の定義

[← 第126講](../../part7/lecture126/) | [第7部 目次](../) | [第128講 →](../../part8/lecture128/)

## この講義の問い

Solidityの文法規格のファイルはどう読み、そのファイルは何に答えて何に答えず、コンパイラとバージョンが変わるときそのファイルをどこまで信じられるのか。

## 実習資料

### 準備

文法ファイルは、Solidity v0.8.36タグの`SolidityParser.g4`・`SolidityLexer.g4`を取得して読み、比較用にv0.8.30の文法ファイル二つと、v0.7.6の`Solidity.g4`・`SolidityLexer.g4`もあわせて取得した。コンパイルの事例は、solc 0.8.30と0.7.6の実行ファイルを直接呼び、パースの段階まで（`--stop-after parsing`）回した結果と、コンパイル全体（`--error-codes --bin`）の結果を並べて見た。`pow.sol`は二つのバージョンでそれぞれビルドし、ローカルのanvilでアカウント0番が`cast send --create`でデプロイした。`market`は通しプロジェクトMarketの第127講のバージョンで、forge-stdが必要である。

### コード

| ファイル | 内容 |
|---|---|
| [code/c127/typeerr.sol](code/c127/typeerr.sol) | `uint8 x = 300` |
| [code/c127/ifacevar.sol](code/c127/ifacevar.sol) | インターフェースの中の状態変数 |
| [code/c127/ifacebody.sol](code/c127/ifacebody.sol) | インターフェースの関数に本体 |
| [code/c127/ifacector.sol](code/c127/ifacector.sol) | インターフェースの中のコンストラクタ |
| [code/c127/nobody.sol](code/c127/nobody.sol) | abstractなしで本体のない関数 |
| [code/c127/libvar.sol](code/c127/libvar.sol) | ライブラリの中の状態変数 |
| [code/c127/sar.sol](code/c127/sar.sol) | `>>>`演算子 |
| [code/c127/reserved.sol](code/c127/reserved.sol) | 変数名`let` |
| [code/c127/erroridt.sol](code/c127/erroridt.sol) | 変数名`error` |
| [code/c127/uncheckedif.sol](code/c127/uncheckedif.sol) | `if`のすぐうしろに`unchecked`ブロック |
| [code/c127/layout.sol](code/c127/layout.sol) | `contract C layout at 10` |
| [code/c127/pragjunk.sol](code/c127/pragjunk.sol) | pragmaの中に`@@` |
| [code/c127/pragfoo.sol](code/c127/pragfoo.sol) | 知らないpragma `foo` |
| [code/c127/yul.sol](code/c127/yul.sol)、[code/c127/clz.sol](code/c127/clz.sol)、[code/c127/ds.sol](code/c127/ds.sol) | アセンブリブロックで`clz`、`datasize` |
| [code/c127/unch.sol](code/c127/unch.sol) | `unchecked`ブロック。0.7.6と0.8.30のパースの比較 |
| [code/c127/pow.sol](code/c127/pow.sol) | `x - 1`、`-x ** 2`、`a ** b ** c`。0.7.6と0.8.30の結果の比較 |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第127講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第127講のバージョン |
| [code/market/test/](code/market/test/) | Marketのテスト55個 |

### 実行結果

文法ファイルの大きさ: SolidityParser.g4は622行・パーサの規則94個、SolidityLexer.g4は368行・トークンの規則180個（+ fragment 15）・モード三つ。パーサのファイルで記号を数えると（コメント・引用符の語を除く）、`|` 202、`?` 54、`*` 38、`+` 8、`+=` 25、`#` 26、条件`{…}?` 31、`<assoc=right>` 3である。v0.8.30とv0.8.36のパーサのファイルは同じで、レキサは303行目に`'clz'`の1語が足された（YulEVMBuiltin 79個 → 80個）。

solc 0.8.30でパースの段階まで回した結果と、コンパイル全体の結果。

| ファイル | `--stop-after parsing` | コンパイル全体 |
|---|---|---|
| typeerr.sol | 通る | Error (9574): Type int_const 300 is not implicitly convertible to expected type uint8. Literal is too large to fit in uint8. |
| ifacevar.sol | 通る | Error (8274): Variables cannot be declared in interfaces. |
| ifacebody.sol | 通る | Error (4726): Functions in interfaces cannot have an implementation. |
| ifacector.sol | 通る | Error (4726)、Error (6482): Constructor cannot be defined in interfaces. |
| nobody.sol | 通る | Error (3656): Contract "C" should be marked as abstract. / Error (5424): Functions without implementation must be marked virtual. |
| libvar.sol | 通る | Error (9957): Library cannot have non-constant state variables |
| sar.sol | 通る | Error (2271): Built-in binary operator >>> cannot be applied to types uint256 and int_const 1. |
| reserved.sol | Error (2314): Expected ';' but got reserved keyword 'let' | 同じ |
| erroridt.sol | 通る | エラーなし |
| uncheckedif.sol | Error (5296): "unchecked" blocks can only be used inside regular blocks. | 同じ |
| layout.sol | 通る | エラーなし |
| pragjunk.sol | Error (6281): Token incompatible with Solidity parser as part of pragma directive. | 6281が二つ、Error (1684) |
| pragfoo.sol | 通る | Error (4936): Unknown pragma "foo"、Warning (3420) |
| clz.sol、ds.sol | 通る | Error (4619): Function "clz" not found. / Function "datasize" not found.、8678 |

`clz.sol`は`--evm-version osaka`でビルドしても、0.8.30では4619である。`unch.sol`は0.7.6ではパースの段階で`Error (6933): Expected primary expression.`で、0.8.30では通る。

`pow.sol`の二つのバージョン（ランタイムは0.7.6が387バイト、0.8.30が1,595バイト）。

```
$ cast call <Pow 0.7.6> "dec(uint256)(uint256)" 0
115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]
$ cast call <Pow 0.7.6> "negPow(int256)(int256)" 3
9
$ cast call <Pow 0.7.6> "powPow(uint256,uint256,uint256)(uint256)" 2 3 2
64
$ cast call <Pow 0.8.30> "dec(uint256)(uint256)" 0
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call <Pow 0.8.30> "negPow(int256)(int256)" 3
9
$ cast call <Pow 0.8.30> "powPow(uint256,uint256,uint256)(uint256)" 2 3 2
512
```

同じソースでも、0.7.6はオーバーフローのチェックがなく、`**`を左から結合する（`(2 ** 3) ** 2` = 64）。v0.7.6の文法ファイル`Solidity.g4`の336行目は`<assoc=right> expression Exp expression`で、右から結合すると書かれていて、コンパイラと食い違う。0.8.30は右から結合して`2 ** (3 ** 2)` = 512である。

Market 第127講のバージョンは、srcの五つのファイルが`solc --stop-after parsing`を通り、`forge build --sizes`でruntime 7,353 / creation 7,931（initcodeの余裕41,221）、`forge test`の55個が通り、`grep -n assembly src/*.sol`は0行である。

### 試すときの注意

- 文法ファイルを通ってもビルドできるとは限らない。型・インターフェース・ライブラリの規則は、パースのあとの段階で引っかかる。
- `let`は予約語なので変数名に使えないが、`error`は使える。
- 文法ファイルに`clz`があっても、コンパイラのバージョンが0.8.30ならアセンブリで呼べない。文法ファイルと、使うコンパイラのバージョンをそろえて読む。
- 計算の順番とオーバーフローのチェックは文法ファイルにない。説明のドキュメント（0.8.0 Breaking Changesなど）で探す。

## 時効性のあるデータ

基準日時点の値。ドキュメントやコンパイラのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメントのバージョン | Language Grammar、Yul、Solidity v0.8.0 Breaking Changes、Units and Globally Available Variables、Types（`types/value-types.rst`の70〜89行目、Shiftsの項目）はv0.8.36タグ。比較用にv0.8.30の文法ファイル二つ、v0.7.6の`Solidity.g4`・`SolidityLexer.g4` | 2026-10-19 |
| 文法ファイルの大きさ | SolidityParser.g4 622行・パーサの規則94個、SolidityLexer.g4 368行・トークンの規則180個（+ fragment 15）・モード三つ | 2026-10-19 |
| パーサのファイルの記号の数 | `\|` 202、`?` 54、`*` 38、`+` 8、`+=` 25、`#` 26、条件`{…}?` 31、`<assoc=right>` 3 | 2026-10-19 |
| 文法ファイルのバージョンの違い | v0.8.30 / v0.8.36: パーサのファイルは同じ、レキサの303行目に`'clz'`の1語。YulEVMBuiltinはv0.8.36で80個 / v0.8.30で79個 | 2026-10-19 |
| ANTLR | test_antlr_grammar.shがantlr-4.8-complete.jarでパーサを作る | 2026-10-19 |
| solc | 0.8.30（直接呼ぶとevm_versionはprague）、0.7.6 | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3、forgeのビルドのevm_versionはosaka | 2026-10-19 |
| エラー番号 | 9574、8274、4726・6482、3656・5424、9957、2271、4936・3420、2314、5296、6281・1684、4619・8678、6933、5473 | 2026-10-19 |
| Powの二つのバージョン | 0.7.6はデプロイのコード387バイト、dec(0)は2の256乗から1を引いた数、negPow(3) 9、powPow(2, 3, 2) 64 / 0.8.30は1,595バイト、dec(0)はPanic 0x11、negPow(3) 9、powPow 512 | 2026-10-19 |
| Market 第127講のバージョン | runtime 7,353 / creation 7,931、initcodeの余裕41,221、テスト55個、linkReferences {}、`grep -n assembly src/*.sol` 0行、srcの五つのファイルがパースを通る | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| コマンドラインのオプションとStandard JSON（`--stop-after`を含む） | [第128講](../../part8/lecture128/) |
| バージョン・設定をそろえて作り直すことと、ソースの検証 | [第130講](../../part8/lecture130/) |
| ASTのノードとバイトコードの構造 | [第131講](../../part8/lecture131/) |
| ソースマッピング | [第132講](../../part8/lecture132/) |
| 二つのコード生成の経路 | [第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| 命名規則と慣例 | [第149講](../../part9/lecture149/) |
| 不変条件とファジング | [第183講](../../part11/lecture183/) |
| コンパイラのバグの一覧 | [第184講](../../part11/lecture184/) |
| バージョンごとの変更履歴 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 監査で文法の外を確かめる方法 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
