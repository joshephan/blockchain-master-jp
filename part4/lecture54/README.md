# 第54講 addressとaddress payable

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第53講](../../part4/lecture53/) | [第4部 目次](../) | [第55講 →](../../part4/lecture55/)

## この講義の問い

同じ20バイトを指す型がなぜ二つあり、その区別は何を防ぎ、何を防げないのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める。anvilを立ち上げ、既定のアカウント0番（公開されたテスト用の鍵）でデプロイして送金する。コンパイルエラーの版（`bad/`）と比較用の二つの版（`same/`）は、一つずつ`src/`に入れてビルドする。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Addr.sol](code/src/Addr.sol) | address・address payableの状態変数、uint160・bytes20への変換、payableからaddressへ広げる |
| [code/bad/T1.sol](code/bad/T1.sol) | `address`に`transfer`（コンパイルエラー） |
| [code/bad/T1ok.sol](code/bad/T1ok.sol) | `payable(owner).transfer(...)`に直した版 |
| [code/bad/T2.sol](code/bad/T2.sol) | `msg.sender`をaddress payableの欄に代入（コンパイルエラー） |
| [code/bad/T3.sol](code/bad/T3.sol) | アドレスに`+ 1`（コンパイルエラー） |
| [code/bad/T4.sol](code/bad/T4.sol) | `uint256`から`address`への変換（コンパイルエラー） |
| [code/bad/T5.sol](code/bad/T5.sol) | addressをaddress payableとして返す（コンパイルエラー） |
| [code/same/A.sol](code/same/A.sol) | `address`版のSame |
| [code/same/B.sol](code/same/B.sol) | `address payable`版のSame |

### 実行結果

欄の配置（`forge inspect Addr storageLayout`）。address payableも20バイトで、後ろのboolは同じ欄のoffset 20に入る。

```
| owner    | address         | 0    | 0      | 20    | src/Addr.sol:Addr |
| feeTo    | address payable | 1    | 0      | 20    | src/Addr.sol:Addr |
| paused   | bool            | 1    | 20     | 1     | src/Addr.sol:Addr |
| guardian | address         | 2    | 0      | 20    | src/Addr.sol:Addr |
```

デプロイしたAddrの欄と、変換関数の呼び出し：

```
$ cast storage $A 0
0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
$ cast storage $A 1
0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
$ cast storage $A 2
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast call $A "guardian()(address)"
0x0000000000000000000000000000000000000000
$ cast call $A "toUint(address)(uint160)" 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
721457446580647751014191829380889690493307935711 [7.214e47]
$ cast call $A "toBytes(address)(bytes20)" 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
0x7e5f4552091a69125d5dfcb7b8c2659029395bdf
$ cast call $A "fromUint(uint160)(address)" 1
0x0000000000000000000000000000000000000001
```

エラーの版を一つずつ`src/`に入れて`forge build`した結果：

```
T1  Error (9862): "send" and "transfer" are only available for objects of type "address payable", not "address".
T2  Error (7407): Type address is not implicitly convertible to expected type address payable.
T3  Error (2271): Built-in binary operator + cannot be applied to types address and int_const 1. Arithmetic operations on addresses are not supported. Convert to integer first before using them.
T4  Error (9640): Explicit type conversion not allowed from "uint256" to "address".
T5  Error (6359): Return argument type address is not implicitly convertible to expected type (type of first return variable) address payable.
```

T1okはビルドを通過する。solcの警告はなく、forge lintが`uninitialized-state`、`arbitrary-send-eth`の案内を出すだけである。

二つの版のSameのABI（`forge inspect Same abi`）。セレクターは同じで、型の名前だけが違う。

```
| function | set(address) nonpayable     | 0x2801617e |
| function | to() view returns (address) | 0x13151981 |

| function | set(address payable) nonpayable     | 0x2801617e |
| function | to() view returns (address payable) | 0x13151981 |
```

二つの版の`deployedBytecode`から末尾のメタデータ（最後の2バイトが長さ）を外して比べると、実行コードはどちらも394バイトで同じで、メタデータだけが違う。storageLayoutもType列以外は同じである（スロット0、offset 0、20バイト）。

秘密鍵1のアドレスの最後の文字を変えた、鍵のないアドレスに1イーサを送った結果：

```
$ cast wallet address --private-key <値が1の32バイトのキー>
0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
$ cast to-check-sum-address 0x7e5f4552091a69125d5dfcb7b8c2659029395bde
0x7E5F4552091a69125d5Dfcb7b8c2659029395bDe
$ cast balance $X ; cast code $X ; cast nonce $X
0
0x
0
$ cast send $X --value 1ether --private-key $K
gasUsed              21000
status               1 (success)
transactionHash      0x7ba34cc55731ba914a35348384e6d3379deb3d952d584491b26d14e4ee76afaf
$ cast balance $X ; cast balance $X --ether ; cast code $X ; cast nonce $X
1000000000000000000
1.000000000000000000
0x
0
```

### 試すときの注意

- address payableは、コンパイラだけが知っている区別である。欄のサイズ、セレクター、実行コードはaddressと同じである。
- `msg.sender`は0.8.0から`address`である。payableの欄に入れるには`payable(msg.sender)`に変える。
- アドレスには算術がなく、`uint256`から直接変換できない。`uint160`を経由する。
- 鍵のないアドレスにもイーサはそのまま送られ（gasUsed 21000）、取り戻す方法はない。チェーンは、受け取るアドレスに鍵があるかどうかをチェックしない。
- デプロイのアドレスは、送るアカウントのナンスで決まる。上のAddrのアドレスは、同じアカウントが送金を1回したあと（ナンス1）の値なので、順番を変えると違ってくる。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると出力が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Types、Value TypesのAddressの節、v0.8.36 | 2026-10-19 |
| addressとaddress payableが分かれたバージョン | 0.5.0 | 2026-10-19 |
| msg.sender・tx.originの型 | 0.8.0からaddress（それ以前はaddress payable）、アドレスリテラルと`address(...)`の変換結果もaddress | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| `transfer`を使ったときのコンパイラの警告 | solc 0.8.30ではなし（`Compiler run successful!`、forge lintのarbitrary-send-ethの案内だけを出力） | 2026-10-19 |
| イーサだけを送るトランザクションのgasUsed | 21000 | 2026-10-19 |
| 鍵のないアドレスに送ったトランザクション | 0x7ba34cc55731ba914a35348384e6d3379deb3d952d584491b26d14e4ee76afaf（ローカルのanvil） | 2026-10-19 |
| Sameの二つの版の実行コード | 394バイトで同一、deployedBytecode 896文字（0xを含む）、メタデータだけが違う | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| addressのメンバー全体（balance、code、codehash、call、delegatecall、staticcall）と、transfer・send・callによる送金の違い | [第55講](../../part4/lecture55/) |
| 受け取る側がイーサを拒否したときに、送る側で起きること | [第55講](../../part4/lecture55/) |
| アドレスがコントラクトかどうかを問う（code.length）、コントラクト型 | [第56講](../../part4/lecture56/) |
| チェックサムが捕まえる打ち間違いと、アドレスリテラルのルール | [第59講](../../part4/lecture59/) |
| 暗黙的・明示的な変換のルール全体 | [第73講](../../part4/lecture73/) |
| requireで条件を書く（address(0)の拒否など） | [第90講](../../part5/lecture90/) |
| payable関数の表示、イーサを受け取るreceiveとfallback | [第99講](../../part6/lecture99/) |
| イーサを受け取る人が自分で引き出しに来る設計 | [第170講](../../part11/lecture170/) |
| ABIエンコードのルールとinternalType | [第141講](../../part8/lecture141/) |
| アドレスで権限を分けること（tx.originを含む）、鍵の管理とマルチシグ | [第176講](../../part11/lecture176/)、[第178講](../../part11/lecture178/) |
| ストレージの欄の配置のルール全体 | [第135講](../../part8/lecture135/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
