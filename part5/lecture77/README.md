# 第77講 msgの属性

第5部 言語の詳細 ② グローバル変数と制御構造・第17章 単位とグローバル変数

[← 第76講](../../part5/lecture76/) | [第5部 目次](../) | [第78講 →](../../part5/lecture78/)

## この講義の問い

いまこの関数を誰が呼び、何を載せて送ったのかという情報はどこから来て、いつ変わるのか。

## 実習資料

### 準備

空のFoundryプロジェクト二つから始める。`demo`はビルドが通るバージョン、`errors`はビルドエラーを見るバージョンである。どちらもfoundry.tomlで`solc = "0.8.30"`に固定し、テストにはforge-std（`lib/forge-std`）が必要である。コントラクトはローカルのanvilに既定のアカウント0番で`forge create`し、アリスは既定のアカウント1番（anvilの公開されたテスト用の鍵）である。`forge create`では`--constructor-args`をいちばん最後に置く。前に置くと、後ろのオプションまでコンストラクタの引数として取り込んでしまう。`errors`のファイルは`forge build --offline --force src/<ファイル>`で一つずつビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Chain.sol](code/demo/src/Chain.sol) | A → B → Cと続けて呼ぶコントラクト三つ。Cが`msg.sender`と`tx.origin`を記録する |
| [code/demo/src/Who.sol](code/demo/src/Who.sol) | modifier、内部呼び出し、`this.viaThis()`での`msg.sender`をイベントで残す |
| [code/demo/src/Three.sol](code/demo/src/Three.sol) | transfer・send・callでイーサを送るSenderと、receiveで受け取るReceiver |
| [code/demo/src/Pay.sol](code/demo/src/Pay.sol) | payableの`pay()`とpayableでない`noPay()` |
| [code/demo/src/Echo.sol](code/demo/src/Echo.sol) | msgの四つをそのまま返す`echo`、`msg.data[4:]`、pureの`msg.sig`、viewの`msg.sender` |
| [code/demo/src/Wallet.sol](code/demo/src/Wallet.sol) | ユーザーの代わりにMarketの`deposit`を呼んでくれるウォレットコントラクト |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket（第72講のバージョン + 第75講の利息の下書き + 第76講の`elapsedOf`） |
| [code/demo/test/Chain.t.sol](code/demo/test/Chain.t.sol) | A・Bを経由した呼び出しと直接の呼び出し、`vm.prank`の引数二つ・一つ、Whoのトレース |
| [code/demo/test/Three.t.sol](code/demo/test/Three.t.sol) | 送金3種を受け取る側のトレース |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/MsgGas.sol](code/errors/src/MsgGas.sol) | `msg.gas`、Error 1400 |
| [code/errors/src/NoPayValue.sol](code/errors/src/NoPayValue.sol) | payableでない関数の`msg.value`、Error 5887 |
| [code/errors/src/ViewValue.sol](code/errors/src/ViewValue.sol) | view関数の`msg.value`、Error 5887 |
| [code/errors/src/PureSender.sol](code/errors/src/PureSender.sol) | pure関数の`msg.sender`、Error 2527 |
| [code/errors/src/PureValue.sol](code/errors/src/PureValue.sol) | pure関数の`msg.value`、Error 2527 |
| [code/errors/src/InternalValue.sol](code/errors/src/InternalValue.sol) | internal関数の中で読む`msg.value`。ビルドが通る |

### 実行結果

`forge test --offline --match-test test_throughAB -vvvv`。アリスがAを呼ぶと、Cが見る`msg.sender`はB、`tx.origin`はアリスである。

```
    ├─ [0] VM::prank(alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6])
    ├─ [77747] A::hit()
    │   ├─ [50775] B::hit()
    │   │   ├─ [44867] C::hit()
    │   │   │   └─ ← [Return] B: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6]
Logs:
  C.msg.sender 0x2e234DAe75C793f67A35089C9d99245E1C58470b
  C.tx.origin  0x328809Bc894f92807417D2dAD6b7C998c1aFdac6
```

anvilでアリスがAを経由して呼んだあとと、Cを直接呼んだあとの`lastSender`・`lastOrigin`。`0x0165...Eb8F`はBである。

```
$ cast send $A "hit()" --private-key $PK1
$ cast call $C "lastSender()(address)"
0x0165878A594ca255338adfa4d48449f69242Eb8F
$ cast call $C "lastOrigin()(address)"
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast send $C "hit()" --private-key $PK1
$ cast call $C "lastSender()(address)"
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast call $C "lastOrigin()(address)"
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

`vm.prank(bob)`のように引数を一つだけ渡すと、`tx.origin`はFoundryのテストの既定の送信元アドレスになる（`forge test --match-test test_prankOne -vv`）。

```
[PASS] test_prankOne() (gas: 88388)
Logs:
  C.msg.sender 0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e
  C.tx.origin  0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
```

Whoのトレース（`--match-test test_who -vvvv`）。modifierと内部関数には呼び出しの行がなく、`msg.sender`もそのままである。`this.viaThis()`だけが一段入った呼び出しになり、`msg.sender`がWho自身になる。

```
    ├─ [32647] Who::outer()
    │   ├─ emit Seen(where: "modifier", sender: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6])
    │   ├─ emit Seen(where: "outer", sender: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6])
    │   ├─ emit Seen(where: "inner", sender: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6])
    │   ├─ [2345] Who::viaThis()
    │   │   ├─ emit Seen(where: "viaThis", sender: Who: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9])
    │   │   └─ ← [Stop]
    │   ├─ emit Seen(where: "after", sender: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6])
    │   └─ ← [Stop]
```

送金3種を受け取る側のトレース（`--match-contract ThreeTest -vvvv`）。3回ともreceiveが受け取り、`msg.value`だけが違う。

```
    ├─ [32884] Sender::viaTransfer{value: 1000000000}(Receiver: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   ├─ [1625] Receiver::receive{value: 1000000000}()
    │   │   ├─ emit Got(sender: Sender: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 1000000000 [1e9])
    ├─ [32863] Sender::viaSend{value: 2000000000}(Receiver: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   ├─ [1625] Receiver::receive{value: 2000000000}()
    │   │   ├─ emit Got(sender: Sender: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 2000000000 [2e9])
    ├─ [33107] Sender::viaCall{value: 3000000000}(Receiver: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   ├─ [1625] Receiver::receive{value: 3000000000}()
    │   │   ├─ emit Got(sender: Sender: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 3000000000 [3e9])
```

Payにイーサを載せた呼び出し。payableでない`noPay()`に1 weiを載せるとリバートデータなしでリバートし、値なしで呼ぶと1が返る。

```
$ cast call $PAY "pay()(uint256)" --value 1ether --from $ALICE
1000000000000000000 [1e18]
$ cast send $PAY "noPay()" --value 1 --private-key $PK1
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call $PAY "noPay()(uint256)" --from $ALICE
1
```

`msg.value`・`msg.sender`・`msg.gas`のビルドエラー。

```
Error (1400): "msg.gas" has been deprecated in favor of "gasleft()"
Error (5887): "msg.value" and "callvalue()" can only be used in payable public functions. Make the function "payable" or use an internal function to avoid this error.
Error (2527): Function declared as pure, but this expression (potentially) reads from the environment or state and thus requires "view".
```

Echoで読んだmsgの四つ。1行目の`msg.data`は`cast calldata`の結果と、2行目の`msg.sig`は`cast sig "echo(uint256,address)"`の結果と同じである。

```
$ cast call $ECHO "echo(uint256,address)(bytes,bytes4,address,uint256)" 30 0x0000000000000000000000000000000000000b0b --value 5 --from $ALICE
0x02e4373f000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000b0b
0x02e4373f
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
5
$ cast call $ECHO "args(uint256,address)(bytes)" 30 0x0000000000000000000000000000000000000b0b
0x000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000b0b
```

pure関数`pureSig()`はビルドが通り、0x33bf9e86（`cast sig "pureSig()"`と同じ）を返す。

Marketにアリスが直接500を、Walletを経由して300を預けたあとの欄。300はWalletのアドレスの欄に入り、Marketの記録にアリスは出てこない。

```
$ cast call $MARKET "positions(address,address)(uint256,uint256,uint64,bool)" $AAAA $ALICE
500
0
1792394654 [1.792e9]
false
$ cast call $MARKET "positions(address,address)(uint256,uint256,uint64,bool)" $AAAA $WALLET
300
0
1792394655 [1.792e9]
false
$ cast call $MARKET "totalDeposits(address)(uint256)" $AAAA
800
```

アリスの`addAsset`は`not admin`で、イーサを載せた`deposit`はリバートデータなしでリバートする。Marketにはpayableの関数がない。

```
$ cast send $MARKET "addAsset(address,uint8)" $AAAA 75 --private-key $PK1
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: not admin, data: "0x08c379a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000096e6f742061646d696e0000000000000000000000000000000000000000000000": Error("not admin")
$ cast send $MARKET "deposit(address,uint256)" $AAAA 500 --value 1 --private-key $PK1
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

### 試すときの注意

- `$AAAA`は`0x000000000000000000000000000000000000AAAA`で、管理者（既定のアカウント0番）が比率75で先に登録する。
- `forge inspect --offline C storageLayout`には自分で書いた欄二つだけが出て、msgの値はどこにも保存されない。前の呼び出しの`msg.sender`が必要なら、欄に自分で書いておく。
- `forge inspect --offline Market abi --json`のstateMutabilityは、nonpayable・pure・viewの三つだけである。
- `lastUpdate`の値はanvilを立ち上げた時刻が基準なので、実行し直すと変わる。
- pure関数で読めるのは`msg.sig`と`msg.data`だけである。`msg.value`はviewでも読めず、payable関数でだけ読める。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| `msg.gas` | 0.4.21で非推奨、0.5.0で削除、`gasleft()`に置き換え | 2026-10-19 |
| `msg.sender`の型 | 0.8.0からaddress（それ以前はaddress payable） | 2026-10-19 |
| pure・viewの規則 | pureでblock・tx・msgのメンバーを読むことは状態の読み取りとみなす、`msg.sig`と`msg.data`だけが例外 | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| Foundryのテストの既定の送信元アドレス | `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38`（`vm.prank`の引数が一つのときのtx.origin） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `this.f()`が外部呼び出しになる理由、`this`の型 | [第80講](../../part5/lecture80/) |
| calldataのバイトを値にほどく関数（`abi.decode`）とバイトを作る関数 | [第78講](../../part5/lecture78/) |
| 内部関数の呼び出しの文法 | [第82講](../../part5/lecture82/) |
| 外部関数の呼び出しと呼び出しオプション | [第83講](../../part5/lecture83/) |
| `receive`、`fallback` | [第99講](../../part6/lecture99/) |
| view・pureの規則全体 | [第98講](../../part6/lecture98/) |
| 関数セレクタの計算 | [第101講](../../part6/lecture101/)、[第141講](../../part8/lecture141/) |
| modifierの実行順序 | [第103講](../../part6/lecture103/) |
| ライブラリの呼び出しと`delegatecall`でのmsg | [第116講](../../part6/lecture116/)、[第117講](../../part6/lecture117/) |
| 受け取った`msg.data`をそのまま渡すプロキシ | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 権限チェックに何を使うか（`msg.sender`と`tx.origin`） | [第151講](../../part9/lecture151/)、[第176講](../../part11/lecture176/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
