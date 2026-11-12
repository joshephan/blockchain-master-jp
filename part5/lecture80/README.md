# 第80講 コントラクト関連のグローバルとselfdestruct

第5部 言語の詳細 ② グローバル変数と制御構造・第17章 単位とグローバル変数

[← 第79講](../../part5/lecture79/) | [第5部 目次](../) | [第81講 →](../../part5/lecture81/)

## この講義の問い

コントラクトが自分自身について読む値は何で、`selfdestruct`は名前とは違っていま何をするのか。

## 実習資料

### 準備

空のFoundryプロジェクト四つから始める。`demo`は既定のEVMバージョンでビルドするバージョン、`shanghai`は同じBombを`evm_version = "shanghai"`でビルドするバージョン、`interface-id`はinterfaceIdのXORを確かめるバージョン、`errors`はビルドエラーを見るバージョンである。どれもfoundry.tomlで`solc = "0.8.30"`に固定し、テストにはforge-std（`lib/forge-std`）が必要である。anvilは既定（ハードフォークlatest）、`--hardfork shanghai`、`--hardfork cancun`の三つを一つずつ立ち上げる。既定のanvilにはアカウント0番（anvilの公開されたテスト用の鍵）でVault、Types、NoReceive、Market、Token、OneTx、Self、Bomb（1イーサを載せてデプロイ）の順にデプロイし、Marketのイーサのデモの直前にBombをもう一つ（1イーサ）デプロイする。`errors`のファイルは`forge build --offline --force src/ThisAddr.sol`でビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定、既定のEVMバージョン |
| [code/demo/src/Self.sol](code/demo/src/Self.sol) | 同じ関数`who`を名前で呼ぶバージョンと`this.who()`で呼ぶバージョン、`address(this)` |
| [code/demo/src/Vault.sol](code/demo/src/Vault.sol) | 状態変数なしで`address(this).balance`と`msg.value`を返すpayable関数 |
| [code/demo/src/Types.sol](code/demo/src/Types.sol) | `type(Market).name`、`type(IERC20).interfaceId`、`type(uint64).max`、creationCode・runtimeCodeの長さ |
| [code/demo/src/Bomb.sol](code/demo/src/Bomb.sol) | selfdestructするBomb、receiveもfallbackもないNoReceive、作ったトランザクションの中でselfdestructするOneTx |
| [code/demo/src/Token.sol](code/demo/src/Token.sol) | デモ用の最小限のトークン（balanceOf、transfer） |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket（第72講のバージョン + 第75講の利息の下書き + 第76講の`elapsedOf` + 第78講のIERC20の`transferFrom`の宣言）に、デモ用の`heldBalance`をつけたバージョン |
| [code/demo/test/Self.t.sol](code/demo/test/Self.t.sol) | `viaInternal`と`viaThis`のトレースの比較 |
| [code/shanghai/foundry.toml](code/shanghai/foundry.toml) | solc 0.8.30、`evm_version = "shanghai"` |
| [code/shanghai/src/Bomb.sol](code/shanghai/src/Bomb.sol) | demoと同じBomb.sol。shanghai・cancunの二つのチェーンに同じバイトコードで載せる |
| [code/interface-id/foundry.toml](code/interface-id/foundry.toml) | solc 0.8.30に固定 |
| [code/interface-id/src/I2.sol](code/interface-id/src/I2.sol) | balanceOfとtransferFromの二つの関数を置いたインターフェース |
| [code/interface-id/test/I2.t.sol](code/interface-id/test/I2.t.sol) | `type(I2).interfaceId`を出力するテスト |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/ThisAddr.sol](code/errors/src/ThisAddr.sol) | `address a = this;`、Error 9574 |

### 実行結果

receiveもfallbackもないNoReceiveにイーサを載せて送ると、リバートする。

```
$ cast send $N --value 1ether --private-key $PK0
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

`this`の型はコントラクト型なので、addressにそのまま入れられない。

```
Error (9574): Type contract ThisAddr is not implicitly convertible to expected type address.
```

`forge test --offline -vvvv`（Self）。名前で呼んだ`who()`には呼び出しの行がなく、`msg.sender`はテストコントラクトである。`this.who()`は一段入った呼び出しになり、`msg.sender`はSelf自身である。

```
[PASS] test_internal() (gas: 9375)
  [9375] SelfTest::test_internal()
    ├─ [457] Self::viaInternal() [staticcall]
    │   └─ ← [Return] SelfTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]

[PASS] test_this() (gas: 18456)
  [18456] SelfTest::test_this()
    ├─ [3818] Self::viaThis() [staticcall]
    │   ├─ [401] Self::who() [staticcall]
    │   │   └─ ← [Return] Self: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]
    │   └─ ← [Return] Self: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]
```

状態変数がないVault（`forge inspect --offline Vault storageLayout`は空の表）にも残高がある。1イーサがあるVaultに2イーサを載せた呼び出しは、中で残高3イーサを読む。

```
$ cast send $V "pay()" --value 1ether --private-key $PK0
$ cast balance $V
1000000000000000000
$ cast call $V "pay()(uint256,uint256)" --value 2ether --from $A0
3000000000000000000 [3e18]
2000000000000000000 [2e18]
$ cast balance $V
1000000000000000000
```

Typesの`info()`。`0x5318f0ec`は`cast sig "balanceOf(address)"`（0x70a08231）と`cast sig "transferFrom(address,address,uint256)"`（0x23b872dd）のXORである。`interface-id`プロジェクトの`forge test -vv`も同じ値を出力する。

```
$ cast call $T "info()(string,bytes4,uint64,uint256,uint256)"
"Market"
0x5318f0ec
18446744073709551615 [1.844e19]
4785
4693
```

Bombをビルドすると警告が出る。

```
Warning (5159): "selfdestruct" has been deprecated. Note that, starting from the Cancun hard fork, the underlying opcode no longer deletes the code and data associated with an account and only transfers its Ether to the beneficiary, unless executed in the same transaction in which the contract was created (see EIP-6780). Any use in newly deployed contracts is strongly discouraged even if the new behavior is taken into account. Future changes to the EVM might further reduce the functionality of the opcode.
```

`shanghai`で一度ビルドした同じバイトコードを、shanghaiのanvilとcancunのanvilに載せて`boom(NoReceive)`を呼んだ前後。各行はBombの`cast codesize`、`cast storage $B 0`、`cast balance`である。

```
shanghai
before: codesize 384 slot0 0x000000000000000000000000000000000000000000000000000000000000002a bal 1000000000000000000
after: codesize 0 slot0 0x0000000000000000000000000000000000000000000000000000000000000000 bal 0 NoReceive bal 1000000000000000000

cancun
before: codesize 384 slot0 0x000000000000000000000000000000000000000000000000000000000000002a bal 1000000000000000000
after: codesize 384 slot0 0x000000000000000000000000000000000000000000000000000000000000002a bal 0 NoReceive bal 1000000000000000000
```

作ったトランザクションの中でselfdestructするOneTxのバージョン。既定のanvilでもコードと保存値が消える（新しいコントラクトのアドレスは`cast compute-address $O --nonce 1`）。

```
$ cast send $O "makeAndBoom(address)" $N --value 1ether --private-key $PK0
$ cast compute-address $O --nonce 1
0x61c36a8d610163660E21a8b7359e1Cac0C9133e1
$ cast code 0x61c36a8d610163660E21a8b7359e1Cac0C9133e1
0x
```

既定のanvilでのBombの`boom(NoReceive)`。NoReceiveのコードは1行も動いていないのに（`pings`は0、トレースにNoReceiveの呼び出しなし）、残高が1イーサになる。

```
$ cast send $B "boom(address)" $N --private-key $PK0
$ cast balance $N
1000000000000000000
$ cast call $N "pings()(uint256)"
0
$ cast run <boomのトランザクションハッシュ>
Traces:
  [8047] 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853::boom(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0)
    └─ ← [SelfDestruct]
```

Marketにdepositを通さずにトークン300を直接送った結果。合計の欄は0で、トークンの残高は300である。

```
$ cast send $M "addAsset(address,uint8)" $TK 75 --private-key $PK0
$ cast send $TK "transfer(address,uint256)" $M 300 --private-key $PK0
$ cast call $M "totalDeposits(address)(uint256)" $TK
0
$ cast call $M "heldBalance(address)(uint256)" $TK
300
```

payable関数がないMarketはイーサの送金をリバートするが、新しくデプロイしたBombのselfdestructではイーサが入ってくる。

```
$ cast send $M --value 1ether --private-key $PK0
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast balance $M
0
$ cast send $B2 "boom(address)" $M --private-key $PK0
$ cast balance $M
1000000000000000000
```

### 試すときの注意

- 出力の`--rpc-url`は省略した。
- shanghai・cancunの比較は、anvilを一つずつ立ち上げてNoReceiveとBomb（1イーサ）をデプロイし、`boom(NoReceive)`の前後でBombのcodesize、0番スロット、残高とNoReceiveの残高を読んだものである。
- `this.f()`は同じオブジェクトのメソッド呼び出しではなく、自分のアドレスに送る外部呼び出しである。`msg.sender`が変わり、ガスも多くかかる。
- payable関数の中の`address(this).balance`は、すでに`msg.value`が足された値である。入ってくる前の残高は`address(this).balance - msg.value`である。
- receiveがないコントラクトでも、selfdestructやブロック報酬の受け取りアドレスの指定で残高が増えることがある。会計は合計の欄で行い、コントラクトの残高は会計に使わない。`heldBalance`はデモ用である。
- MarketのcreationCode・runtimeCodeの長さ（4785、4693）は、このバージョンでの値である。第72講のバージョンに`heldBalance`だけを足すと4026、3934になる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン（`demo`）、`shanghai`だけevm_version shanghai | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| anvilの既定のハードフォーク | `--hardfork`の既定値latest、`anvil_nodeInfo`のhardFork `Bpo1` | 2026-10-19 |
| selfdestructの動作の変更 | EIP-6780、Cancunハードフォーク（イーサリアムメインネット 2024年3月）。作ったトランザクションの外ではイーサだけを送り、コード・ストレージを消さない | 2026-10-19 |
| selfdestructの非推奨の警告 | solc 0.8.18から | 2026-10-19 |
| `type(I).interfaceId` | solc 0.6.7から。インターフェース自身の関数セレクタをXORした値（継承した関数は除く）、EIP-165の識別子 | 2026-10-19 |
| Marketのバイト長 | creationCode 4,785バイト、runtimeCode 4,693バイト | 2026-10-19 |
| トレースのガス | viaInternal 457、viaThis 3,818（内側のwho 401）、テスト 9,375 / 18,456 | 2026-10-19 |
| gasUsed（参考） | boom 29,479（三つのチェーンで同じ）、makeAndBoom 161,638 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 内部呼び出しと外部呼び出しの違いの整理、名前つき引数 | [第82講](../../part5/lecture82/) |
| 外部呼び出しが渡す制御権と呼び出しオプション | [第83講](../../part5/lecture83/) |
| `new`で作るコントラクトとアドレスの計算 | [第84講](../../part5/lecture84/) |
| creationCodeとruntimeCodeの区別 | [第93講](../../part6/lecture93/) |
| receiveとfallback、受け取る関数を通らないイーサ | [第99講](../../part6/lecture99/) |
| コントラクトの残高を基準にした計算の危険、引き出しパターン | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |
| ERC-165とインターフェースの確認 | [第159講](../../part10/lecture159/) |
| アップグレード可能な構造とチェーンの規則の変化 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/)、[第269講](../../part21/lecture269/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
