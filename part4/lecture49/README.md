# 第49講 構造体と列挙型の概観

第4部 言語の詳細 ① ファイルと型・第12章 コントラクトの構造

[← 第48講](../../part4/lecture48/) | [第4部 目次](../) | [第50講 →](../../part4/lecture50/)

## この講義の問い

複数の値を一つにまとめたり、いくつかの場合に名前をつけたりすると、チェーンには何が保存されるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める。`src/Purchase.sol`（第39講）と`src/Ballot.sol`（第37講）は、公式ドキュメントの例の原文そのままである。anvilを立ち上げ、既定のアカウント0番（デプロイ・売り手）と1番（買い手）を使う。anvilの既定のアカウントの鍵は公開されたテスト用の鍵である。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/VoterTypeOnly.sol](code/src/VoterTypeOnly.sol) | Ballotの`struct Voter`の宣言だけがあるコントラクト |
| [code/src/VoterWithVar.sol](code/src/VoterWithVar.sol) | 同じ宣言に`Voter public first`と`voters`マッピングを加えたコントラクト |
| [code/src/Orders.sol](code/src/Orders.sol) | フィールドの順番だけが違う`OrderLoose`（欄三つ）と`OrderTight`（欄二つ） |
| [code/src/EnumDemo.sol](code/src/EnumDemo.sol) | `enum State`を引数として受け取る`set`、数値を変換する`setRaw` |
| [code/src/EnumReordered.sol](code/src/EnumReordered.sol) | メンバーの順番を変えた同じ名前の列挙型 |
| [code/src/types/Types.sol](code/src/types/Types.sol) | ファイルレベルで宣言した`enum State`と`struct Order` |
| [code/src/Shop.sol](code/src/Shop.sol) | Types.solから二つの型をインポートして使うコントラクト |
| [code/src/Purchase.sol](code/src/Purchase.sol) | 公式ドキュメントの例Purchase（第39講のファイル） |
| [code/src/Ballot.sol](code/src/Ballot.sol) | 公式ドキュメントの例Ballot（第37講のファイル） |

### 実行結果

構造体の宣言に変数をつけた側の欄の配置（`forge inspect VoterWithVar storageLayout`）。宣言だけのVoterTypeOnlyは表が空である。

```
| first  | struct VoterWithVar.Voter                     | 0    | 0      | 96    | src/VoterWithVar.sol:VoterWithVar |
| voters | mapping(address => struct VoterWithVar.Voter) | 3    | 0      | 32    | src/VoterWithVar.sol:VoterWithVar |
```

`--json`のtypesのメンバーで見ると、weightが0番の欄、votedが1番の欄のoffset 0、delegateが1番の欄のoffset 1、voteが2番の欄である。

フィールドの順番だけが違う二つのOrderに、同じ値を`cast send ... "save(uint128,uint256,uint64)" 5000 1001 1760000000`で保存したレシートと欄の内容：

```
OrderLoose gasUsed   89195
OrderTight gasUsed   67344
Loose slot 0 0x0000000000000000000000000000000000000000000000000000000000001388
Loose slot 1 0x00000000000000000000000000000000000000000000000000000000000003e9
Loose slot 2 0x0000000000000000000000000000000000000000000000010000000068e77800
Tight slot 0 0x00000000000000010000000068e7780000000000000000000000000000001388
Tight slot 1 0x00000000000000000000000000000000000000000000000000000000000003e9
Tight slot 2 0x0000000000000000000000000000000000000000000000000000000000000000
```

`cast estimate`で見た`order()`の読み取りのガスは、OrderLooseが28308、OrderTightが26357である。

Purchaseを2 etherでデプロイしたあと`state`を読み、買い手が`confirmPurchase`を呼んだあとにもう一度読んだ結果。stateは、buyerと同じ2番の欄のoffset 20に1バイトで入る。

```
$ cast call $P "state()(uint8)"
0
$ cast storage $P 2
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast send $P "confirmPurchase()" --value 2ether --private-key <アカウント1>
status               1 (success)
$ cast call $P "state()(uint8)"
1
$ cast storage $P 2
0x00000000000000000000000170997970c51812dc3a010c7d01b50e0d17dc79c8
```

```
| value  | uint256             | 0 | 0  | 32 |
| seller | address payable     | 1 | 0  | 20 |
| buyer  | address payable     | 2 | 0  | 20 |
| state  | enum Purchase.State | 2 | 20 | 1  |
```

EnumDemoのセレクター（`forge inspect EnumDemo methodIdentifiers`）。列挙型の引数は`uint8`と書かれる。

```
| locked()        | cf309012   |
| set(uint8)      | 24b8ba5f   |
| setRaw(uint256) | 5dcbb36c   |
| state()         | c19d93fb   |
```

範囲外の数値7を入れたとき。引数として受け取ると空のデータで巻き戻り、数値を変換するとPanic 0x21で巻き戻る。

```
$ cast call $E "set(uint8)" 7
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call $E "setRaw(uint256)" 7
Error: execution reverted: panic: failed to convert value into enum type (0x21)
$ cast send $E "set(uint8)" 7 --gas-limit 100000
gasUsed              21510
status               0 (failed)
$ cast send $E "setRaw(uint256)" 7 --gas-limit 100000
gasUsed              21659
status               0 (failed)
revertReason         panic: failed to convert value into enum type (0x21), data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000021"
```

メンバーの順番を変えると、同じ名前が別の数値になる。`EnumDemo.locked()`は1、`EnumReordered.locked()`は0を返す。

ABIには列挙型のメンバー名がない（`forge inspect Purchase abi`）。JSONのstateの出力はtype `uint8`、internalType `enum Purchase.State`で、`--json`の出力で`Locked`を探すと0件である。

```
| function    | state() view returns (Purchase.State)   | 0xc19d93fb |
```

ファイルレベルの型をインポートしたShopの欄の配置（`forge inspect Shop storageLayout`）：

```
| state | enum State   | 0    | 0      | 1     | src/Shop.sol:Shop |
| order | struct Order | 1    | 0      | 64    | src/Shop.sol:Shop |
```

### 試すときの注意

- 構造体の宣言だけではストレージの欄はできない。その型で状態変数を作って初めて欄が確保される（ランタイムのサイズもVoterTypeOnlyが62バイト、VoterWithVarが623バイト）。
- 構造体は新しい欄から始まり、フィールドの順番によって欄の数が変わる。Orderは順番を変えただけで欄が三つから二つになり、保存のガスが21851減った。
- 範囲外の列挙型の値は、入ってくる経路によって巻き戻しの形が違う。引数のデコードで引っかかれば空のデータ`0x`、数値の変換で引っかかればPanic 0x21である。
- 列挙型のメンバーの順番をデプロイ後に変えると、すでに保存された数値の意味が変わる。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Structure of a Contractの節、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| Voter構造体のサイズ | 96バイト（欄三つ）、voted・delegateで一つの欄 | 2026-10-19 |
| Orderの二つの版のサイズ | OrderLoose 96バイト（欄三つ） / OrderTight 64バイト（欄二つ） | 2026-10-19 |
| saveのgasUsed | OrderLoose 89,195 / OrderTight 67,344（差21,851） | 2026-10-19 |
| order()のガス見積もり | OrderLoose 28,308 / OrderTight 26,357 | 2026-10-19 |
| SSTOREの価格 | 0の欄に新しい値20,000、コールドな欄は+2,100（第16講の値のまま） | 2026-10-19 |
| 範囲外のenumの巻き戻し | 引数：空のデータ0x / 変換：Panic 0x21 | 2026-10-19 |
| デプロイのサイズ | Purchaseのランタイム2,718バイト、EnumDemo 763、OrderLoose 882、OrderTight 880、Shop 674、VoterTypeOnly 62、VoterWithVar 623 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 列挙型の文法全体（type(State).min・max、変換のルール） | [第60講](../../part4/lecture60/) |
| ユーザー定義の値型（`type Price is uint256`） | [第60講](../../part4/lecture60/) |
| 構造体の文法全体（入れ子、配列とマッピングを入れる、delete） | [第70講](../../part4/lecture70/) |
| 関数に渡すときのコピーと参照（storage、memory、calldata） | [第62講](../../part4/lecture62/)、[第63講](../../part4/lecture63/)、[第64講](../../part4/lecture64/) |
| ストレージの欄の配置のルール全体（構造体は新しい欄から始まる、動的型） | [第135講](../../part8/lecture135/) |
| 欄の配置でガスを減らす | [第143講](../../part9/lecture143/) |
| ABIエンコードのルール（列挙型がuint8と書かれるルール、セレクターの計算） | [第141講](../../part8/lecture141/) |
| チェーンのデータをABIでデコードしてクエリし、指標を作る（Dune） | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| Panicコードの一覧と巻き戻しデータの受け取り | [第90講](../../part5/lecture90/)、[第91講](../../part5/lecture91/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
