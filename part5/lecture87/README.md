# 第87講 スコープと宣言

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第86講](../../part5/lecture86/) | [第5部 目次](../) | [第88講 →](../../part5/lecture88/)

## この講義の問い

宣言の1行はその名前について何を決め、同じ名前が二つあるとどちらが使われるのか。

## 実習資料

### 準備

どのプロジェクトも、空のFoundryプロジェクトでfoundry.tomlに`solc = "0.8.30"`を固定し、forge-stdを`lib/forge-std`に置く。`market`は第86講までの通しプロジェクトのMarket（第17章の終わりのバージョンに、第81講の`collateralCount`、第82講の`_credit`・`_debit`・`_touch`とwithdraw、第83講のトークンの呼び出しを足したバージョン）と、第83講のテスト用のトークンである。残りの四つは、このバージョンか第17章の終わりのバージョンのMarketから1、2行だけを変えたデモ用のバージョンである。コントラクトはローカルのanvilに既定のアカウント0番（anvilの公開されたテスト用の鍵）で`forge create`し、`cast`で読んだり送ったりする。Marketにはデプロイ直後に`addAsset(トークン, 75)`を先に送る。`demo/bad/`のファイルは`forge build --offline --force --contracts bad/<ファイル>`で一つずつビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第86講までのMarket。Positionを受け取る行はすべて`storage` |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | 第83講のテスト用のトークン（`mint`、`approve`、`transferFrom`、受け取ったcalldataを記録しておく） |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Scope.sol](code/demo/src/Scope.sol) | ブロックの中の宣言が見える範囲 |
| [code/demo/src/Shadow.sol](code/demo/src/Shadow.sol) | 内側のブロックで外側の名前を再宣言（警告2519） |
| [code/demo/src/Order.sol](code/demo/src/Order.sol) | 状態変数を関数より後ろで宣言したコントラクト |
| [code/demo/src/Kinds.sol](code/demo/src/Kinds.sol) | constant・immutable・状態変数。storageLayoutの比較用 |
| [code/demo/src/Defaults.sol](code/demo/src/Defaults.sol) | 値を入れていないローカル変数の初期値 |
| [code/demo/src/Token.sol](code/demo/src/Token.sol) | デモ用の最小限のトークン（`balanceOf`、`transfer`） |
| [code/demo/bad/BeforeDecl.sol](code/demo/bad/BeforeDecl.sol) | 宣言する前に使った名前、Error 7576 |
| [code/demo/bad/ForVar.sol](code/demo/bad/ForVar.sol) | `for`の括弧の中で宣言した`i`をループの外で使う、Error 7576 |
| [code/demo/bad/Redecl.sol](code/demo/bad/Redecl.sol) | 同じブロックで2回宣言、Error 2333 |
| [code/demo/bad/StoragePtr.sol](code/demo/bad/StoragePtr.sol) | 指す欄を決めていない`storage`のローカル変数、Error 3464 |
| [code/setstatus-shadow/src/Market.sol](code/setstatus-shadow/src/Market.sol) | `market`に、引数名が状態変数と同じ`setStatus(MarketStatus status)`を足したデモ用のバージョン |
| [code/setstatus-renamed/src/Market.sol](code/setstatus-renamed/src/Market.sol) | 同じ関数の引数を`newStatus`に変えたバージョン |
| [code/credit-memory/src/Market.sol](code/credit-memory/src/Market.sol) | `market`の`_credit`の1行を`Position memory p`に変えたバージョン（ビルドエラー9553） |
| [code/deposit-memory/src/Market.sol](code/deposit-memory/src/Market.sol) | 第17章の終わりのバージョンのMarketのdepositの1行を`Position memory p`に変えたバージョン（警告なしでビルドされる） |
| [code/deposit-memory/src/Token.sol](code/deposit-memory/src/Token.sol) | 上のバージョンで使った最小限のトークン |

四つのデモ用のバージョンのfoundry.tomlは`market`と同じである。

### 実行結果

`setstatus-shadow`のバージョンのビルド。警告が二つ出て、ビルドは通る。

```
Warning (2519): This declaration shadows an existing declaration.
  --> src/Market.sol:47:24:
   |
47 |     function setStatus(MarketStatus status) external {
   |                        ^^^^^^^^^^^^^^^^^^^
Note: The shadowed declaration is here:
  --> src/Market.sol:32:5:
   |
32 |     MarketStatus public status;
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^

Warning (2018): Function state mutability can be restricted to view
  --> src/Market.sol:47:5:
```

管理者のアカウントで`setStatus(2)`（Frozen）を送り、スロット0を読んだ結果。呼び出しは成功するが、スロット0（いちばん最後のバイトがstatus、その前がcollateralRatio、さらにその前の20バイトがadmin）はそのままである。

```
$ cast storage $M 0
0x00000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb922660000
$ cast send $M "setStatus(uint8)" 2 --private-key $PK0
status               1 (success)
$ cast storage $M 0
0x00000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb922660000
$ cast call $M "status()(uint8)"
0
```

引数名を変えた`setstatus-renamed`のバージョンは警告なしでビルドされ、同じ呼び出しのあとスロット0の最後のバイトが02になる。

```
0x00000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb922660002
```

`demo/bad/`のビルドエラー。

```
Error (7576): Undeclared identifier. "b" is not (or not yet) visible at this point.
 --> bad/BeforeDecl.sol:6:21:
Error (2333): Identifier already declared.
 --> bad/Redecl.sol:7:9:
Error (3464): This variable is of storage pointer type and can be accessed without prior assignment, which would lead to undefined behaviour.
  --> bad/StoragePtr.sol:14:9:
```

Shadowの`f()`は1を返す（内側のxはブロックが終わると消える）。Orderは`bump()`を2回送ったあと`count()`が2である。`forge inspect`のstorageLayoutで、Orderの`count`はスロット0で、Kindsには`total`の1行しかない（constantとimmutableには欄がない）。

```
| count | uint256 | 0    | 0      | 32    | src/Order.sol:Order |
| total | uint256 | 0    | 0      | 32    | src/Kinds.sol:Kinds |
```

`market`のバージョンで、アカウント0番がトークン100をapproveしたあと`deposit(トークン, 100)`。pがpositionsの欄を指しているので、欄に100（0x64）が残る。`$J`は`cast index address`を2回使って計算した`positions[トークン][アカウント0番]`の欄である。

```
$ cast call $M "positions(address,address)(uint256,uint256,uint64,bool)" $TK $A0
100
0
1792399391 [1.792e9]
false
$ cast call $M "totalDeposits(address)(uint256)" $TK
100
$ cast storage $M $J
0x0000000000000000000000000000000000000000000000000000000000000064
```

`credit-memory`のバージョンは、`_touch(Position storage p)`がmemoryを受け取れないので、ビルドで止まる。

```
Error (9553): Invalid type for argument in function call. Invalid implicit conversion from struct Position memory to struct Position storage pointer requested.
  --> src/Market.sol:69:16:
```

`deposit-memory`のバージョンは警告なしでビルドされ、同じdepositのあと合計だけが100で、ユーザーの欄は空である。

```
$ cast call $MM "positions(address,address)(uint256,uint256,uint64,bool)" $TK $A0
0
0
0
false
$ cast call $MM "totalDeposits(address)(uint256)" $TK
100
$ cast storage $MM $J
0x0000000000000000000000000000000000000000000000000000000000000000
```

Defaultsの`show()`は、`0`、`false`、`0x0000000000000000000000000000000000000000`、`0`（空の配列の長さ）を返す。

### 試すときの注意

- ブロックの中の宣言は、宣言のすぐ次から、その宣言を囲むいちばん小さな波括弧の終わりまで見える。`for`の初期化の位置の宣言はループの終わりまでである。関数の外の宣言（関数、状態変数、型）は、宣言の順番に関係なく見える。
- 同じブロックの同じ名前はエラー（2333）で、内側のブロックや引数で外側の名前を使い直すのは警告（2519）だけである。`Position memory p`のように名前は一つなのに指す先がコピーである場合は、何の警告も出ない。
- `setStatus`の警告2018（viewに変えてよい）は、状態を変えるつもりだった関数が実際には状態を変えていないという合図である。
- デモ用の`setStatus`の二つのバージョンはMarketに入れない。Marketの引数名は状態変数と重ならない（`asset`と`assets`は1文字違い）。
- `lastUpdate`の値はanvilのブロックの時刻なので、実行するたびに変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| C99のスコープ規則 | Solidity 0.5.0から。それ以前は、関数の中のどこで宣言しても関数全体で見える規則 | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| エラー・警告の番号 | 7576 Undeclared identifier、2333 Identifier already declared、2519 shadows an existing declaration、2018 mutability can be restricted、3464 storage pointer without prior assignment | 2026-10-19 |
| deposit 100のgasUsed（参考） | `market`のバージョン 280,743（テスト用のトークンが受け取ったcalldataを欄に記録する）、第17章の終わりのバージョンのstorage版 91,697、memory版 54,144 | 2026-10-19 |
| setStatusのgasUsed（参考） | 隠すバージョン 23,828、newStatusのバージョン 26,913 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| コンストラクタと状態変数の初期化の順番 | [第92講](../../part6/lecture92/) |
| 状態変数の可視性とgetter | [第97講](../../part6/lecture97/) |
| constantとimmutable | [第102講](../../part6/lecture102/) |
| 継承した状態変数・関数の名前を隠す場合 | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| アセンブリブロックで外側の名前を使う規則 | [第120講](../../part7/lecture120/) |
| importのパスとファイルレベルの名前 | [第129講](../../part8/lecture129/) |
| スロットに複数の値が一緒に入る配置の規則 | [第135講](../../part8/lecture135/) |
| 監査で名前と宣言を読む順番 | [第188講](../../part12/lecture188/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
