# 第46講 ファイルの構成とプロジェクトのレイアウト

第4部 言語の詳細 ① ファイルと型・第11章 ソースファイルの構造

[← 第45講](../../part4/lecture45/) | [第4部 目次](../) | [第47講 →](../../part4/lecture47/)

## この講義の問い

コードをいくつのファイルにどう分けて置くかは、コンパイラが決めることなのか、人が決めることなのか。

## 実習資料

### 準備

[第41講](../../part3/lecture41/)のトークン・Callerのコードを、ファイルの配置だけを変えて三つのプロジェクトにする。三つとも`forge init`で作ったhelloプロジェクトからCounterのファイルを消して始め、foundry.tomlは第41講と同じである。テストにはforge-stdが必要である（`lib/forge-std`）。すべての実行はforgeの中だけで動き、anvilは立ち上げない。コンパイルできない例は`src`の外の`bad/`に置き、パスを指定して別々にビルドする。

- `one/`：第41講の`IToken.sol`一つのファイル（IToken、Caller、FakeToken）をそのまま置いた版と、ファイル内の配置の実験
- `three/`：同じ三つの定義を三つのファイルに分けた版
- `layout/`：第41講の`src/`の四つのファイルを、定義一つにファイル一つで分けた再配置版。第41講のModular.solのドキュメント原文のpragma（`>=0.5.0 <0.9.0`）は、再配置しながら`0.8.30`に合わせた

### コード

| ファイル | 内容 |
|---|---|
| [code/one/foundry.toml](code/one/foundry.toml) | solc 0.8.30に固定、ビルドのときのlintをオフ（三つのプロジェクトで同じ） |
| [code/one/src/IToken.sol](code/one/src/IToken.sol) | 第41講のファイルそのまま。インターフェースと実装二つが一つのファイル |
| [code/one/src/UseBelow.sol](code/one/src/UseBelow.sol) | 下で定義されたコントラクト・構造体を上で使うFactory |
| [code/one/consumer/Wallet.sol](code/one/consumer/Wallet.sol) | ITokenだけが必要な外側のコントラクト |
| [code/one/bad/TwoSpdx.sol](code/one/bad/TwoSpdx.sol) | SPDXの行が二つ |
| [code/one/bad/PragmaInside.sol](code/one/bad/PragmaInside.sol)、[ImportInside.sol](code/one/bad/ImportInside.sol) | コントラクトの波かっこの中のpragma、import |
| [code/one/bad/ParentBelow.sol](code/one/bad/ParentBelow.sol) | 親コントラクトが子より下 |
| [code/one/bad/PragmaBottom.sol](code/one/bad/PragmaBottom.sol)、[PragmaBottom2.sol](code/one/bad/PragmaBottom2.sol) | pragmaとimportをファイルのいちばん下に置いた版 |
| [code/three/src/interfaces/IToken.sol](code/three/src/interfaces/IToken.sol)、[Caller.sol](code/three/src/Caller.sol)、[FakeToken.sol](code/three/src/FakeToken.sol) | 三つの定義を三つのファイルに分けた版 |
| [code/three/src/v2/Caller.sol](code/three/src/v2/Caller.sol) | パスだけが違う同じ名前のCaller |
| [code/layout/src/](code/layout/src/) | Token、TokenInh、TokenPub、BalancesBase、Caller、`interfaces/IToken.sol`、`libraries/Balances.sol`、`libraries/BalancesPub.sol` |
| [code/layout/consumer/Wallet.sol](code/layout/consumer/Wallet.sol) | `interfaces/IToken.sol`だけをインポートするWallet |
| [code/layout/test/Caller.t.sol](code/layout/test/Caller.t.sol) | テストでだけ使うFakeTokenをテストファイルの中に置いた例 |

名前の実験は、`layout/`をコピーして`test/Caller.t.sol`のファイル名だけを`test/CallerTest.sol`に変えて実行する。

### 実行結果

ファイル内の配置のルール（`forge build --offline bad/<ファイル>`）：

```
TwoSpdx.sol
Error (3716): Multiple SPDX license identifiers found in source file. Use "AND" or "OR" to combine multiple licenses. Please see https://spdx.org for more information.

PragmaInside.sol (ImportInside.solも同じ)
Error (9182): Function, variable, struct or modifier declaration expected.
 --> bad/PragmaInside.sol:5:5:

ParentBelow.sol
Error (2449): Definition of base has to precede definition of derived contract
 --> bad/ParentBelow.sol:4:22:
```

逆に、`src/UseBelow.sol`のように下で定義されたコントラクト（Child）と構造体（Point）を上で使うのは通過する（`forge build --sizes`でChild 175、Factory 645バイト）。`bad/PragmaBottom.sol`も警告なしで`Compiler run successful!`である。いちばん下のpragmaを`0.8.20`に変えたPragmaBottom2.solは、その条件が読まれて止まる（オフラインなので0.8.20をダウンロードしない）：

```
Error: Encountered invalid compiler version in bad/PragmaBottom2.sol: No compiler version installed that matches the version requirement: =0.8.20
```

一つのファイルの版と三つのファイルの版のCallerのランタイムコード（`forge inspect Caller deployedBytecode`）。769バイトのうち先頭716バイトは一文字も違わず、末尾53バイトのメタデータのハッシュだけが違う。FakeTokenも先頭517バイトが同じである：

```
一つのファイルの版  0x6080604052...6fea2646970667358221220 987ac4be…b30913d 64736f6c634300081e0033
三つのファイルの版  0x6080604052...6fea2646970667358221220 45053c35…f2096c8 64736f6c634300081e0033
```

末尾が変わった理由は、メタデータに書かれたファイルのパスである（`forge inspect Caller metadata`のsourcesとsettings.compilationTarget）：

```
一つのファイルの版  ['src/IToken.sol']  {'src/IToken.sol': 'Caller'}
三つのファイルの版  ['src/Caller.sol', 'src/interfaces/IToken.sol']  {'src/Caller.sol': 'Caller'}
```

Walletをビルドすると（`forge build --sizes consumer/Wallet.sol`、ビルドの前に`out/`、`cache/`を消す）、ITokenだけを選んでインポートしても、ファイル全体がコンパイルされる：

```
一つのファイルの版をインポートするとき              Caller 769 / FakeToken 570 / Wallet 603
                                                    out/IToken.sol/Caller.json, FakeToken.json, IToken.json, out/Wallet.sol/Wallet.json
インターフェースのファイルだけをインポートするとき  Wallet 603
                                                    out/IToken.sol/IToken.json, out/Wallet.sol/Wallet.json
```

Foundryの成果物のパスは`out/<ファイル名>/<コントラクト名>.json`である。三つのファイルの版の`src/interfaces/IToken.sol`は、`out/IToken.sol/IToken.json`として出る（フォルダ名なし）。`src/v2/Caller.sol`を加えると、名前が重なってフォルダ名がつく：

```
$ forge build --offline
Compiling 4 files with Solc 0.8.30
Compiler run successful!

out/Caller.sol/Caller.json
out/v2/Caller.sol/Caller.json

$ forge inspect --offline Caller abi
Error: Multiple contracts found with the name `Caller`

$ forge inspect --offline src/v2/Caller.sol:Caller abi
| function | ping() pure returns (uint256) | 0x5c36b186 |
```

再配置版の`forge build --sizes`（Runtime Sizeの欄のみ）とTokenPubのlinkReferences。サイズと空欄の位置は第41講と同じで、ライブラリのファイルのパスだけが変わる：

```
| Token     | 2,337 |
| TokenInh  | 2,312 |
| TokenPub  | 2,173 |
| Caller    | 769   |
| FakeToken | 570   |

第41講     {'src/PublicLib.sol': {'BalancesPub': [{'start': 957, ...}, {'start': 1204, ...}]}}
再配置版   {'src/libraries/BalancesPub.sol': {'BalancesPub': [{'start': 957, ...}, {'start': 1204, ...}]}}
```

テストファイルの名前を`CallerTest.sol`に変えても`forge test`はそのまま通過するが、`forge build --skip test`がコンパイルするファイルの数が変わる。`--skip test`は、名前に`.t.sol`が入ったファイルを外す別名だからである：

```
Ran 1 test for test/CallerTest.sol:CallerTest
[PASS] test_FakeTokenSaysTrue() (gas: 240405)

test/Caller.t.solにしたプロジェクト    Compiling 8 files with Solc 0.8.30
test/CallerTest.solにしたプロジェクト  Compiling 28 files with Solc 0.8.30
```

28個には、テストファイルとforge-stdのファイルまで入る。

### 試すときの注意

- Walletのサイズを比べるときは、ビルドの前に`out/`、`cache/`を消す。そうすれば、そのビルドで出た成果物だけが見える。
- バイトコードの比較は、二つの版の`deployedBytecode`から最後の106文字（53バイト）を除いた前の部分を、文字列として比べた。
- 同じ名前のコントラクトが二つあると、`forge inspect`、`forge create`のように名前で探すコマンドには`パス:名前`をつける。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge）のバージョン | 1.8.3 (cae51ad) | 2026-10-19 |
| 一つのファイルの版・三つのファイルの版のランタイムのサイズ | Caller 769 / FakeToken 570（バイト）、二つの版で同じ | 2026-10-19 |
| バイトコードの比較 | Callerは先頭716バイト、FakeTokenは先頭517バイトが一致、末尾53バイトだけが違う | 2026-10-19 |
| 再配置版のランタイムのサイズ | Token 2,337 / TokenInh 2,312 / TokenPub 2,173 / Caller 769 / FakeToken 570（バイト） | 2026-10-19 |
| Walletのランタイムのサイズ | 603バイト | 2026-10-19 |
| --skip testでコンパイルされるファイル数 | .t.solの名前で8個、.t.solを外した名前で28個 | 2026-10-19 |
| Foundryのファイル名の慣例 | `--skip`の別名 test = .t.sol、script = .s.sol / 成果物はout/<ファイル>/<コントラクト>.json、名前が重なるとフォルダ名をつける | 2026-10-19 |
| エラー番号 | 3716（SPDXが二つ）、9182（波かっこの中のpragma・import）、2449（親が子より下） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| インポートパスの解決のルール全体（ソースユニット名、基準パス、remappingの優先順位） | [第128講](../../part8/lecture128/)、[第129講](../../part8/lecture129/) |
| メタデータの中身全体 | [第142講](../../part8/lecture142/) |
| ソースレイアウトのルールと命名のルール（スタイルガイド） | [第148講](../../part9/lecture148/)、[第149講](../../part9/lecture149/) |
| 継承の文法全体（線形化、super、多重継承） | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| ライブラリの文法とリンクの方式 | [第116講](../../part6/lecture116/)、[第117講](../../part6/lecture117/)、[第118講](../../part6/lecture118/) |
| 監査でコードを読む順番 | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/) |
| コントラクトの中の構成要素（状態変数、関数、イベントなど） | [第47講](../../part4/lecture47/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
