# 第43講 三つのpragma

第4部 言語の詳細 ① ファイルと型・第11章 ソースファイルの構造

[← 第42講](../../part4/lecture42/) | [第4部 目次](../) | [第44講 →](../../part4/lecture44/)

## この講義の問い

ファイルのいちばん上の同じ場所に書く3種類のpragmaは、それぞれ何をし、ファイルが複数あるとどうなるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをそのまま使う。テストにはforge-stdが必要である（`lib/forge-std`）。foundry.tomlに`solc`の行がないので、コンパイラはpragmaの範囲の中でFoundryが選ぶ。実行例では、solc 0.8.30と0.7.6がインストールされていた。例は`src`の外の`demo/`の下にフォルダごとに置き、パスを指定して別々にビルドする。そうすれば、わざと失敗させるファイルがほかのビルドを止めない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | `forge init`の既定値（solcの固定なし） |
| [code/demo/nopragma/Main.sol](code/demo/nopragma/Main.sol)、[Helper.sol](code/demo/nopragma/Helper.sol) | pragmaのないファイルをimportするファイル |
| [code/demo/range/New.sol](code/demo/range/New.sol)、[Old.sol](code/demo/range/Old.sol) | バージョンの範囲が重ならない二つのファイル（`^0.8.28`が`<0.8.25`をimport） |
| [code/demo/range2/New.sol](code/demo/range2/New.sol)、[Old.sol](code/demo/range2/Old.sol) | 同じ範囲でimportを外した二つのファイル |
| [code/demo/range3/New.sol](code/demo/range3/New.sol)、[Old.sol](code/demo/range3/Old.sol) | 範囲が0.8.20〜0.8.24で重なる二つのファイル |
| [code/demo/wide/MyVote.sol](code/demo/wide/MyVote.sol)、[Ballot.sol](code/demo/wide/Ballot.sol) | 公式ドキュメントのVotingの例（`>=0.7.0 <0.9.0`）を`^0.8.28`のファイルで継承 |
| [code/demo/v1/Order.sol](code/demo/v1/Order.sol) | `pragma abicoder v1;`のファイルで構造体を受け取るexternal関数 |
| [code/demo/v1/OrderDefault.sol](code/demo/v1/OrderDefault.sol) | 同じコードからabicoderの行を消した版 |
| [code/demo/old/Order07.sol](code/demo/old/Order07.sol) | 同じコードを`pragma solidity <0.8.0;`に変えた版 |
| [code/demo/strict/Small_v1.sol](code/demo/strict/Small_v1.sol)、[Small_v2.sol](code/demo/strict/Small_v2.sol) | `uint8`を受け取って返す関数、abicoder v1 / v2 |
| [code/test/Strict.t.sol](code/test/Strict.t.sol) | 二つの版に`echo(uint8)`で300を送ってみるテスト |
| [code/demo/inherit/Packer.sol](code/demo/inherit/Packer.sol) | abicoder v2の親。構造体をエンコードするinternal関数 |
| [code/demo/inherit/Shop.sol](code/demo/inherit/Shop.sol) | Packerを継承したabicoder v1の子 |
| [code/demo/inherit/ShopDirect.sol](code/demo/inherit/ShopDirect.sol) | 同じエンコードをv1の子の中で直接行う版 |
| [code/test/Shop.t.sol](code/test/Shop.t.sol) | Shopの`packOne`の結果の確認 |
| [code/demo/exp/](code/demo/exp/) | `pragma experimental`の値ごとのファイル（ABIEncoderV2、SMTChecker、Foo、solidity、abicoder v1と重ねて書いたboth） |

### 実行結果

pragmaのないファイルをimportすると（`forge build demo/nopragma/Main.sol`）、警告が出るだけでビルドされる：

```
Compiler run successful with warnings:
Warning (3420): Source file does not specify required compiler version! Consider adding "pragma solidity ^0.8.30;"
--> demo/nopragma/Helper.sol
```

範囲が重ならない二つのファイルをimportでつなぐと：

```
$ forge build --offline demo/range/New.sol
Error: Found incompatible versions:
demo/range/New.sol ^0.8.28 imports:
    demo/range/Old.sol <0.8.25
```

importを外した二つのファイルは、それぞれ別のコンパイラでビルドされる（`<0.8.25`にはインストール済みの0.7.6が選ばれる）：

```
$ forge build --offline demo/range2/New.sol demo/range2/Old.sol
Compiling 1 files with Solc 0.8.30
Compiling 1 files with Solc 0.7.6
Compiler run successful!
```

`demo/wide/MyVote.sol`は、Ballotの広い範囲と重なる0.8.30一つでビルドされる（`Compiling 2 files with Solc 0.8.30`、`Compiler run successful!`）。

abicoder v1のファイルでの構造体の引数：

```
$ forge build --offline demo/v1/Order.sol
Error (4957): This type is only supported in ABI coder v2. Use "pragma abicoder v2;" to enable the feature.
  --> demo/v1/Order.sol:11:20:
   |
11 |     function place(Order calldata order) external pure returns (uint256) {
   |                    ^^^^^^^^^^^^^^^^^^^^
```

`pragma abicoder v2;`に変えた版と行を消した版（OrderDefault.sol）は、どちらもビルドされる。同じコードを`<0.8.0`に変えると0.7.6が選ばれ、行がなければv1が既定なので同じエラーになる：

```
$ forge build --offline demo/old/Order07.sol
Compiling 1 files with Solc 0.7.6
Error (4957): This type is only supported in ABI coder v2. Use "pragma abicoder v2;" to enable the feature.
demo/old/Order07.sol:10:20: TypeError: This type is only supported in ABI coder v2. Use "pragma abicoder v2;" to enable the feature.
```

`uint8`の場所に300を送った結果（`forge test --match-contract StrictTest -vv`）。v1は受け取って44（300 mod 256）として使い、v2はリバートする：

```
[PASS] test_Send300() (gas: 329116)
Logs:
  v1 ok: true
  v1 returned: 44
  v2 ok: false
  v2 return length: 0
```

v2の親を継承したv1の子。Shopはビルドされ、`packOne(7)`が構造体をエンコードした64バイトを返すが、同じエンコードをv1のファイルの中で直接行うShopDirectはビルドされない：

```
$ forge test --offline --match-contract ShopTest -vv
[PASS] test_PackOne() (gas: 204376)
Logs:
  0x0000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e14960000000000000000000000000000000000000000000000000000000000000007

$ forge build --offline demo/inherit/ShopDirect.sol
Error (2056): This type cannot be encoded.
 --> demo/inherit/ShopDirect.sol:9:27:
  |
9 |         return abi.encode(Order(msg.sender, amount));
  |                           ^^^^^^^^^^^^^^^^^^^^^^^^^
```

`pragma experimental`の値ごとのビルド：

```
===== ABIEncoderV2
Compiler run successful!
===== SMTChecker
Compiler run successful with warnings:
Warning (8158): Solver z3 was selected for SMTChecker but it is not available.
Warning (5523): The SMTChecker pragma has been deprecated and will be removed in the future. Please use the "model checker engine" compiler setting to activate the SMTChecker instead. If the pragma is enabled, all engines will be used.
Warning (7649): CHC analysis was not possible since no Horn solver was found and enabled. The accepted solvers for CHC are Eldarica and z3.
Warning (7710): BMC analysis was not possible since no SMT solver was found and enabled. The accepted solvers for BMC are cvc5 and z3.
===== Foo
Error (8491): Unsupported experimental feature name.
===== both
Error (8273): ABI coder v1 has already been selected through "pragma abicoder v1".
```

### 試すときの注意

- `--offline`では、インストールされたコンパイラの中からだけ選ぶ。range3のように二つの範囲が0.8.20〜0.8.24で重なっていても、その区間のコンパイラがインストールされていなければ、rangeと同じ`Found incompatible versions`が出る。
- ドキュメントのリストにない`pragma experimental solidity;`（E_solidity.sol）は、0.8.30では`Error: Unimplemented feature`で終わる。
- SMTCheckerの警告のうち、solverがないという行（8158、7649、7710）は、実行したPCにz3などがなかったために出たものである。インストール状況によって変わる。

## 時効性のあるデータ

基準日時点の値。コンパイラのバージョンが変わると反応が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidity公式ドキュメントのバージョン | v0.8.36（Layout of a Solidity Source File、Pragmasの節） | 2026-10-19 |
| solcのバージョン | 0.8.30、0.7.6 | 2026-10-19 |
| Foundry（forge）のバージョン | 1.8.3 | 2026-10-19 |
| abicoder v2が既定値になったバージョン | 0.8.0 | 2026-10-19 |
| experimentalの値（ドキュメント基準） | ABIEncoderV2、SMTChecker | 2026-10-19 |
| 0.8.30のexperimentalへの反応 | ABIEncoderV2は通過（=abicoder v2）、SMTCheckerは警告5523（廃止予定）、存在しない名前はエラー8491 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ABIエンコードのルールとセレクター、v1・v2コーダーのバイトの違い | [第141講](../../part8/lecture141/) |
| importの文法と別名 | [第44講](../../part4/lecture44/) |
| インポートパスの解決のルール全体 | [第129講](../../part8/lecture129/) |
| コンパイルの再現性とソース検証におけるpragma | [第130講](../../part8/lecture130/) |
| 継承のルール（多重継承、override、線形化） | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| SMTCheckerの使い方 | [第182講](../../part11/lecture182/) |
| 0.5・0.6・0.7の変更履歴、0.8のチェック付き算術 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 言語の文法仕様の読み方 | [第127講](../../part7/lecture127/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
