# 第84講 newによるコントラクトの作成とsaltつきの作成

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第83講](../../part5/lecture83/) | [第5部 目次](../) | [第85講 →](../../part5/lecture85/)

## この講義の問い

コードがコントラクトを作るとき何が起き、新しいアドレスは何で決まるのか。

## 実習資料

### 準備

空のFoundryプロジェクト一つから始める。foundry.tomlで`solc = "0.8.30"`に固定し、forge-stdを`lib/forge-std`に置く。ビルドエラーの例は`src`の外の`bad/`に置いて既定のビルドに混ざらないようにし、一つずつ`forge build --offline --force bad/<ファイル>`でビルドする。ほとんどは`forge test --offline -vv`（または`-vvvv`）で見て、アドレスの計算と失敗した作成は、ローカルのanvilに既定のアカウント0番（anvilの公開されたテスト用の鍵）でFactoryをデプロイし、`cast`で確かめる。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Child.sol](code/src/Child.sol) | コンストラクタでxを受け取るChild（xが0ならリバート）、payableなコンストラクタのPayChild、`make`・`makeSalted`・`makePaid`・`rawCreate`を置いたFactory |
| [code/src/Market.sol](code/src/Market.sol) | 通しプロジェクトのMarket、第83講までのバージョン。この講義で変えた行はない |
| [code/src/MockToken.sol](code/src/MockToken.sol) | 第83講のテスト用のトークン |
| [code/test/Market.t.sol](code/test/Market.t.sol) | setUpでMarket・MockTokenのアドレスを先に計算し、実際のアドレスと比べる |
| [code/test/Factory.t.sol](code/test/Factory.t.sol) | コードの長さ、CREATE・CREATE2のアドレスの計算、同じsaltで2回、作る前のアドレスの呼び出し、コンストラクタの失敗、`rawCreate`、イーサを載せた作成 |
| [code/bad/AddrMaker.sol](code/bad/AddrMaker.sol) | `new`の結果をaddressの変数に、Error 9574 |
| [code/bad/SelfMaker.sol](code/bad/SelfMaker.sol) | 自分自身を`new`、Error 7813 |
| [code/bad/ValueMaker.sol](code/bad/ValueMaker.sol) | payableでないコンストラクタに`{value: }`、Error 7006 |

### 実行結果

anvilにFactoryをデプロイしたあと、ナンス1で計算したアドレス（`$C1`）のコードの欄を`make(5)`の前後で見たもの（`forge create`・`cast send`の出力のうち該当する行だけ）。

```
$ forge create --offline src/Child.sol:Factory --private-key $PK0 --broadcast
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
$ cast nonce $F
1
$ cast compute-address $F --nonce 1
0xa16E02E87b7454126E5E10d957A927A7F5B5d2be
$ cast code $C1 | cut -c1-20
0x
$ cast send $F "make(uint256)" 5 --private-key $PK0
status               1 (success)
$ cast code $C1 | cut -c1-20
0x608060405234801560
$ cast call $C1 "x()(uint256)"
5
```

`forge test --offline -vvvv --mt test_type`のトレース（console.logの行は省略）。makeの下にコンストラクタが動く行が一段字下げして出て、172バイトが新しいアドレスのコードの欄に載る。

```
  [151720] FactoryTest::test_type()
    ├─ [133650] Factory::make(5)
    │   ├─ [56923] → new Child@0x104fBc016F4bb334D775a19E8A6510109AC63E00
    │   │   └─ ← [Return] 172 bytes of code
    │   └─ ← [Return] Child: [0x104fBc016F4bb334D775a19E8A6510109AC63E00]
    ├─ [2402] Child::x() [staticcall]
    │   └─ ← [Return] 5
```

`test_codeLength`のログ。Factoryのデプロイ済みコードの中には、Childの作成コードがそのまま一度入っている（`forge inspect --offline Factory deployedBytecode | grep -c`の結果は1）。MarketTestの中にもMarketの作成コードが一度入っている。

```
  Child creationCode   529
  Child runtimeCode    172
  Factory creationCode 2385
  Factory runtimeCode  2357
```

ビルドエラー。

```
Error (9574): Type contract Child is not implicitly convertible to expected type address.
 --> bad/AddrMaker.sol:8:9:
Error (7813): Circular reference to contract bytecode either via "new" or "type(...).creationCode" / "type(...).runtimeCode".
 --> bad/SelfMaker.sol:6:16:
Error (7006): Cannot set option "value", since the constructor of contract Child is not payable.
 --> bad/ValueMaker.sol:8:16:
```

`test_paid`で`makePaid{value: 1 ether}(5)`によって作ったPayChildの残高は1000000000000000000である。

`test_createAddress`のログ。Factoryのナンスは1から始まって作るたびに1ずつ増え、先に計算したアドレスと実際のアドレスは同じである。

```
  nonce 1
  predicted 0x104fBc016F4bb334D775a19E8A6510109AC63E00
  actual    0x104fBc016F4bb334D775a19E8A6510109AC63E00
  nonce 2
  predicted 0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3
  actual    0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3
  nonce after 3
```

`test_create2Address`、`test_create2Nonce`のログ。saltを入れたnewは、ナンスに関係なくsalt・作成コード・引数でアドレスが決まる。

```
  predicted x=5 0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8
  actual    x=5 0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8
  predicted x=7 0x2981612774DfE7090c61f3f4E800f6dc4912630E
  after two make, salted x=5 0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8
```

| salt | 引数x | アドレス |
|---|---|---|
| 1 | 5 | 0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8 |
| 1 | 7 | 0x2981612774DfE7090c61f3f4E800f6dc4912630E |
| 2 | 5 | 0xed1de37d0aB3cDa9bd100B9e6EB0fD40E8B79B4b |

同じsaltで2回作った`forge test --offline -vvvv --mt test_sameSaltTwice`。2回目はCreateCollisionでリバートする（わざと失敗させたテスト）。

```
[FAIL: EvmError: Revert] test_sameSaltTwice() (gas: 1040455510)
  [1040455510] FactoryTest::test_sameSaltTwice()
    ├─ [134136] Factory::makeSalted(0x0000000000000000000000000000000000000000000000000000000000000001, 5)
    │   ├─ [56923] → new Child@0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8
    │   │   └─ ← [Return] 172 bytes of code
    │   └─ ← [Return] Child: [0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8]
    ├─ [1040314753] Factory::makeSalted(0x0000000000000000000000000000000000000000000000000000000000000001, 5)
    │   ├─ [0] → new Child@0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8
    │   │   └─ ← [CreateCollision]
    │   └─ ← [Revert] EvmError: Revert
    └─ ← [Revert] EvmError: Revert
```

anvilでsalt 1、x 5で計算したアドレス（`$C2`）に先に1イーサを送ってから、`makeSalted`で作ったもの。コードのないアドレスに送ったイーサが、作ったあとも残る（`cast send`の出力のうちstatusの行だけ）。

```
$ S=0x0000000000000000000000000000000000000000000000000000000000000001
$ INIT=$(cast concat-hex $(forge inspect --offline Child bytecode) $(cast abi-encode "f(uint256)" 5))
$ cast compute-address $F --salt $S --init-code $INIT
0x0d22babb0ae8aCbf2B25B5e76A4cBB9f26981444
$ cast code $C2
0x
$ cast send $C2 --value 1ether --private-key $PK0
status               1 (success)
$ cast balance $C2
1000000000000000000
$ cast send $F "makeSalted(bytes32,uint256)" $S 5 --private-key $PK0
status               1 (success)
$ cast code $C2 | cut -c1-20
0x608060405234801560
$ cast balance $C2
1000000000000000000
$ cast call $C2 "x()(uint256)"
5
```

`test_callBeforeCreate`のログ。作る前にそのアドレスを呼ぶと、コードがないので呼び出しは成功し、返ってくるバイトはない。

```
  code length before 0
  call ok true
  ret length 0
  code length after  172
```

コンストラクタがリバートする`make(0)`。ガスの見積もりで止まり、`--gas-limit`でブロックに入れると失敗し、madeもFactoryのナンスもそのままである。

```
$ cast call $F "made()(uint256)"
1
$ cast send $F "make(uint256)" 0 --private-key $PK0
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: x is zero, data: "0x08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000978206973207a65726f0000000000000000000000000000000000000000000000": Error("x is zero")
$ cast send $F "make(uint256)" 0 --gas-limit 300000 --private-key $PK0
gasUsed              59862
logs                 []
status               0 (failed)
$ cast call $F "made()(uint256)"
1
$ cast nonce $F
2
```

`test_rawCreate`のログ。機械の命令`create`は、コンストラクタがリバートしてもリバートせずに0を返す。失敗した作成もナンスを一つ使うので、次のx = 5はナンス2のアドレスにできる。

```
  rawCreate x=0 0x0000000000000000000000000000000000000000
  rawCreate x=5 0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3
  made 0
```

`forge test --offline -vv --mc MarketTest`のsetUpのログ。

```
  nonce before    1
  predicted Market 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
  actual Market    0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
  predicted Token  0x2e234DAe75C793f67A35089C9d99245E1C58470b
  actual Token     0x2e234DAe75C793f67A35089C9d99245E1C58470b
```

### 試すときの注意

- `test_sameSaltTwice`と`test_constructorRevert`は、リバートを見せるためにわざと失敗させたテストである。
- `forge test -vvvv`は、コンストラクタがリバートした作成の行（`test_constructorRevert`、`test_rawCreate`のx = 0）を`new StdConstants@0x104f…`のような見当違いの名前で出力する。コードが載らなかったので名前を見つけられなかったものと見られる。ログの値で確かめる。
- 同じsaltでの2回目の`makeSalted`のガス（1,040,314,753）は、forge testの既定のガスリミットでの値である。
- Childのソースを書き換えるとメタデータが変わり、saltで計算したアドレスが変わる。上のアドレスは、このリポジトリのChild.solをsolc 0.8.30、optimizerは切ってビルドした値である。
- Marketはほかのコントラクトを作らない。資産のトークンは、外で作られたアドレスを`addAsset`で受け取る。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| コントラクトアカウントのナンスの開始値 | 1（EIP-161）。Factory・テストコントラクトとも`cast nonce`・`vm.getNonce`で1を確認 | 2026-10-19 |
| saltを入れた作成の機械の命令 | CREATE2（EIP-1014、Constantinopleハードフォーク） | 2026-10-19 |
| バイト長 | Child creationCode 529 / runtimeCode 172、Factory creationCode 2,385 / runtimeCode 2,357、Market creationCode 6,113 / runtime 6,021、MockToken runtime 3,577（solc 0.8.30、optimizerは切る） | 2026-10-19 |
| ガス（参考） | anvilのmake(5)のgasUsed 133,650、makeSalted 117,036、make(0)の失敗 59,862、コードのないアドレスへのイーサの送金 21,000 / テストでの同じsaltの2回目のmakeSalted 1,040,314,753（forge testの既定のガスリミットでの値） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `new`で作ったコントラクトを`try`で受け取る方法 | [第91講](../../part5/lecture91/) |
| コンストラクタの文法と初期化の順番 | [第92講](../../part6/lecture92/) |
| 作成コードとランタイムコードの区別 | [第93講](../../part6/lecture93/) |
| CREATEとCREATE2のアドレスの計算式 | [第94講](../../part6/lecture94/) |
| 受け取る関数を通らずに入ってくるイーサ | [第99講](../../part6/lecture99/) |
| アセンブリの`create`と低水準の呼び出しのパターン | [第122講](../../part7/lecture122/) |
| 先に計算したアドレスを使う設計（ファクトリ、プロキシ） | [第94講](../../part6/lecture94/)、[第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
