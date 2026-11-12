# 第36講 言語の系譜と影響

第3部 Solidity入門・第9章 言語の性格と系譜

[← 第35講](../../part3/lecture35/) | [第3部 目次](../) | [第37講 →](../../part3/lecture37/)

## この講義の問い

この言語はどの言語から何を持ってきて、持ってきた文法の意味はどこで変わったのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトの`src`、`test`を下のファイルに置き換える。テストにはforge-stdが必要である（`lib/forge-std`）。コンパイルできない例二つは、`src`の外の`bad/`フォルダに置き、パスを指定して別にビルドする。そうしないと、ほかのビルドが止まってしまう。Java・Pythonの比較用ファイルはプロジェクトの外で実行する。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Wrap.sol](code/src/Wrap.sol) | `uint8`に1を足す関数、検査ありのバージョンと`unchecked`のバージョン |
| [code/test/Wrap.t.sol](code/test/Wrap.t.sol) | 255 + 1の二つの結果を見るテスト |
| [code/src/Order.sol](code/src/Order.sol) | `contract C is A, B`と`super`の呼び出し順序 |
| [code/src/Vault.sol](code/src/Vault.sol) | コンストラクタの引数を`private`の状態変数に入れるコントラクト |
| [code/bad/TryInternal.sol](code/bad/TryInternal.sol) | 内部関数に`try`を使ったバージョン（コンパイルエラー） |
| [code/bad/Rubixi.sol](code/bad/Rubixi.sol) | コントラクト名と同じ名前の関数を置いたバージョン（コンパイルエラー） |
| [code/compare/order.py](code/compare/order.py) | 同じ継承構造をPythonで書いた比較用 |
| [code/compare/Over.java](code/compare/Over.java) | Javaの`int`のあふれの比較用 |
| [code/compare/Renamed.java](code/compare/Renamed.java) | クラス名と違うコンストラクタ名（Javaのコンパイルエラー）の比較用 |

### 実行結果

`forge test`。`test_AddOne`のFAILは意図した結果である。0.8.0以降はあふれがリバートで終わることを見せるために、わざと0を期待するように書いた：

```
Ran 2 tests for test/Wrap.t.sol:WrapTest
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_AddOne() (gas: 5985)
[PASS] test_AddOneUnchecked() (gas: 6329)
Suite result: FAILED. 1 passed; 1 failed; 0 skipped
```

JavaとJavaScriptは、同じところでエラーなしに別の値を出す（`java Over.java`、`node -e "console.log(2**53 + 1)"`）：

```
-2147483648
9007199254740992
```

`forge build bad/TryInternal.sol`：

```
Error (2536): Try can only be used with external function calls and contract creation calls.
  --> bad/TryInternal.sol:10:13:
   |
10 |         try risky() returns (uint256 v) {
   |             ^^^^^^^
```

`Renamed.java`を`javac`でコンパイルすると、`error: invalid method declaration; return type required`が出る。

Order.solの`C`をローカルのanvilにデプロイして`who()`を呼んだ結果と、同じ構造のPythonの結果。親を書く順番の意味が逆である：

```
$ cast call <Cのアドレス> "who()(string)"
"C B A Base"
$ python order.py
C A B Base
```

`private`変数もチェーン上では読める。Vaultをコンストラクタ引数7777でデプロイしたあと：

```
$ cast call <Vaultのアドレス> "secret()(uint256)"
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast storage <Vaultのアドレス> 0
0x0000000000000000000000000000000000000000000000000000000000001e61
$ cast to-dec 0x...1e61
7777
```

`forge build bad/Rubixi.sol`。0.8.30では、コントラクト名と同じ名前の関数をそもそも受け付けない：

```
Error (5796): Functions are not allowed to have the same name as the contract. If you intend this to be a constructor, use "constructor(...) { ... }" to define it.
 --> bad/Rubixi.sol:7:5:
  |
7 |     function Rubixi() public {
  |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2519): This declaration shadows an existing declaration.
```

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると出力が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidity公式ドキュメントのバージョン | v0.8.36（Language Influencesの節） | 2026-10-19 |
| solcのバージョン | 0.8.30 | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| バージョンごとの変更 | 0.4.0 JavaScriptの影響を縮小、0.4.22 constructor、0.5.0 コントラクト名のコンストラクタを禁止・var・throwを削除、0.6.0 virtual/override、0.8.0 あふれの検査がデフォルト | 2026-10-19 |
| Panicのコード | 0x11 = 算術のあふれ | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 四つの可視性（public、external、internal、private）と状態変数の公開 | [第37講](../../part3/lecture37/)、[第95講](../../part6/lecture95/)、[第96講](../../part6/lecture96/)、[第97講](../../part6/lecture97/) |
| 整数型とあふれの検査、uncheckedを使う場面 | [第38講](../../part3/lecture38/)、[第51講](../../part4/lecture51/)、[第52講](../../part4/lecture52/)、[第88講](../../part5/lecture88/)、[第89講](../../part5/lecture89/) |
| revert、require、ユーザー定義エラー、try/catchの文法 | [第39講](../../part3/lecture39/)、[第90講](../../part5/lecture90/)、[第91講](../../part5/lecture91/) |
| 多重継承、override、C3線形化の規則 | [第41講](../../part3/lecture41/)、[第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| 0.5・0.6・0.7の変更履歴、0.8の検算付き算術 | [第184講](../../part11/lecture184/)、[第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| コントラクトのコードのレイアウトと命名規則 | [第148講](../../part9/lecture148/)、[第149講](../../part9/lecture149/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
