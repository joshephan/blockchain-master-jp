# 第39講 安全なリモート購入

第3部 Solidity入門・第10章 Solidity by Example

[← 第38講](../../part3/lecture38/) | [第3部 目次](../) | [第40講 →](../../part3/lecture40/)

## この講義の問い

互いを信用できない売り手と買い手が仲介者なしで取引を終えるには、コードは何を賭けさせるべきか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトから`src`、`test`、`script`のCounterのファイルを消し、Solidity公式ドキュメントv0.8.36のSafe Remote Purchaseの例の原文を`src/Purchase.sol`にそのまま移す。テストにはforge-stdが必要である（`lib/forge-std`）。ローカルのanvilは、ガス代が残高の計算をぼかさないように`--base-fee 0 --gas-price 0 --no-priority-fee`で起動し、トランザクションは`--legacy --gas-price 0`で送る。アカウント0番が売り手、1番が買い手である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Purchase.sol](code/src/Purchase.sol) | 公式ドキュメントの例の原文（状態四つ、modifier四つ、カスタムエラー四つ） |
| [code/src/PurchaseNoInState.sol](code/src/PurchaseNoInState.sol) | abortの`inState(State.Created)`の1行を消したコピー |
| [code/src/PurchaseNoRequire.sol](code/src/PurchaseNoRequire.sol) | confirmReceivedの`require(success)`を消したコピー |
| [code/src/RefusingBuyer.sol](code/src/RefusingBuyer.sol) | イーサを受け取ると必ずリバートする買い手のコントラクト |
| [code/test/Purchase.t.sol](code/test/Purchase.t.sol) | 受け取りを拒否する買い手、inStateを外したコピーで売り手が全部持っていく場合 |
| [code/test/NoRequire.t.sol](code/test/NoRequire.t.sol) | requireを外したコピーでお金がコントラクトに残る場合 |

### 実行結果

正常な流れでの段階ごとの残高（ether）と`state()`。売り手が2 etherでデプロイし、買い手がconfirmPurchase、confirmReceivedを呼び、売り手がrefundSellerを呼ぶ：

```
after deploy          contract 2 | seller 9998  | buyer 10000 | state 0
after confirmPurchase contract 4 | seller 9998  | buyer 9998  | state 1
after confirmReceived contract 3 | seller 9998  | buyer 9999  | state 2
after refundSeller    contract 0 | seller 10001 | buyer 9999  | state 3
```

`forge inspect Purchase storageLayout`では、buyerとstateは同じ2番の欄に入る（buyerはoffset 0、20バイト / stateはoffset 20、1バイト）。confirmPurchaseのあとの2番の欄（`cast storage`）：

```
0x00000000000000000000000370997970c51812dc3a010c7d01b50e0d17dc79c8
```

奇数のwei（1000000000000000001）でデプロイすると、コンストラクタが`ValueNotEven`でリバートし、そのアドレスにはコードがない：

```
contractAddress      0x5FbDB2315678afecb367f032d93F642f64180aa3
logs                 []
status               0 (failed)
revertReason         custom error 0xbe3e4c42, data: "0xbe3e4c42"
$ cast code 0x5FbDB2315678afecb367f032d93F642f64180aa3
0x
```

modifierが止める呼び出し三つ：

```
買い手がabort                      execution reverted: custom error 0x85d1f726 ... OnlySeller
買い手が1イーサでconfirmPurchase   execution reverted, data: "0x"
Lockedで売り手がabort              execution reverted: custom error 0xbaf3f0f7 ... InvalidState
```

`forge test`：

```
[PASS] test_RevertWhen_BuyerRefusesPayment() (gas: 117583)
[PASS] test_SellerTakesAllWithoutInState() (gas: 101543)
```

RefusingBuyerが購入したあと、`received()`を`--gas-limit 200000`でブロックに入れると失敗し、コントラクトはLocked（1）のまま4 etherを抱えて残る：

```
blockNumber          9
gasUsed              42038
logs                 []
status               0 (failed)
$ cast call $P2 "state()(uint8)"
1
$ cast balance $P2 --ether
4.000000000000000000
```

そのトランザクションの`cast run`のトレース（アドレスはコントラクト名に置き換えて記載）。トレースのemitは実行をもう一度動かした画面にすぎず、チェーンに残るログではない：

```
  [20974] RefusingBuyer::received()
    ├─ [15865] Purchase::confirmReceived()
    │   ├─ emit ItemReceived()
    │   ├─ [45] RefusingBuyer::receive{value: 1000000000000000000}()
    │   │   └─ ← [Revert] EvmError: Revert
    │   └─ ← [Revert] EvmError: Revert
    └─ ← [Revert] EvmError: Revert
```

この状態では、売り手の`refundSeller`、`abort`もすべて`InvalidState`で止められる。Lockedから出る道はconfirmReceivedの一つだけで、売り手の2 etherと買い手の2 etherを取り出す関数はコードにない。

requireを外したコピー（`forge test`）。コンパイラが戻り値を使わない低水準の呼び出しに警告し、送金が失敗してもstateだけがRelease（2）に進む。売り手がrefundSellerで3 etherを持っていったあと、買い手の取り分1 etherがコントラクトに残る：

```
Warning (9302): Return value of low-level calls not used.
   --> src/PurchaseNoRequire.sol:105:9:

[PASS] test_NoRequire() (gas: 179295)
Logs:
  state 2
  contract 4000000000000000000
  after refund contract 1000000000000000000
  seller 11000000000000000000
```

### 試すときの注意

- 止められる呼び出しは、`cast send`のガス見積もりの段階でリバートのメッセージが出て、トランザクションは送信されない。失敗したトランザクションをブロックに入れてレシートを見るには、`--gas-limit`を指定する。
- ItemReceivedのトピック（`cast keccak "ItemReceived()"`）は0xe89152acd703c9d8c7d28829d443260b411454d45394e7995815140c8cbcbcf7である。正常なconfirmReceivedのレシートのlogsにはあり、失敗したreceived()のレシートのlogsは`[]`である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 例の原文 | Solidityドキュメント v0.8.36、docs/examples/safe-remote.rst（`pragma solidity ^0.8.4;`） | 2026-10-19 |
| ドキュメントの版の送金方式 | `call{value: ...}("")` + `require(success)`（abort、confirmReceived、refundSeller） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| solc | 0.8.30 | 2026-10-19 |
| anvilの実行オプション | `--base-fee 0 --gas-price 0 --no-priority-fee`、トランザクションは`--legacy --gas-price 0` | 2026-10-19 |
| 失敗したreceived()のトランザクション | ブロック9、gasUsed 42038、ハッシュ0x341ccf58fcc8550d74f5aad489523b14dbe410cfa9e3358042adf65cff2729b4 | 2026-10-19 |
| forge testのガス | test_RevertWhen_BuyerRefusesPayment 117583、test_SellerTakesAllWithoutInState 101543、test_NoRequire 179295 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 状態を先に変えてからイーサを送る順番の理由 | [第83講](../../part5/lecture83/) |
| modifier、イベント、エラーの文法 | [第48講](../../part4/lecture48/) |
| enumの文法の詳細 | [第49講](../../part4/lecture49/) |
| addressとaddress payable、payable()の変換 | [第54講](../../part4/lecture54/) |
| transfer・send・callの送金方式の違い | [第55講](../../part4/lecture55/) |
| require・revertの詳細、try/catchと失敗データ | [第90講](../../part5/lecture90/)、[第91講](../../part5/lecture91/) |
| イベントログと失敗 | [第105講](../../part6/lecture105/) |
| 段階を状態変数で管理する設計 | [第152講](../../part9/lecture152/)、[第258講](../../part20/lecture258/) |
| チェーンの外の事実をチェーンに持ってくる方法 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
