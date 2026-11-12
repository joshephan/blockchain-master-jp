# 第40講 マイクロペイメントチャネル

第3部 Solidity入門・第10章 Solidity by Example

[← 第39講](../../part3/lecture39/) | [第3部 目次](../) | [第41講 →](../../part3/lecture41/)

## この講義の問い

チェーンに載せずにやり取りする署名1枚は、何によって守られるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトから`src`、`test`、`script`のCounterのファイルを消し、Solidity公式ドキュメントv0.8.36のSolidity by ExampleにあるMicropayment Channelの節の二つの例を、全体を原文のまま移す。テストファイルはなく、すべてローカルのanvil（`--base-fee 0 --gas-price 0 --no-priority-fee`）で`cast`を使って確認する。anvilのデフォルトアカウント0・1・2番を、アリス（支払う側）、ボブ（受け取る側）、キャロルとして使う。署名は`cast wallet sign`で作る。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/ReceiverPays.sol](code/src/ReceiverPays.sol) | 公式ドキュメントの原文。署名した小切手を受け取る側が請求するコントラクト（Owned、Freezableを含む） |
| [code/src/SimplePaymentChannel.sol](code/src/SimplePaymentChannel.sol) | 公式ドキュメントの原文。一方向のマイクロペイメントチャネル |

### 実行結果

`forge build`は、"Compiler run successful!"のあとにlintの警告だけを出す（missing-zero-check、ecrecoverの署名の展性、arbitrary-send-eth、block-timestamp）。コンパイラの警告はない。

ReceiverPays（1 etherでデプロイ）に使う小切手一枚。ボブのアドレス、金額0.1 ether、番号1、コントラクトのアドレスをつなげて（`cast concat-hex`）ハッシュし、アリスの鍵で署名する：

```
$ echo $MSG
0x70997970C51812dc3A010C7d01b50e0d17dc79C8000000000000000000000000000000000000000000000000016345785d8a000000000000000000000000000000000000000000000000000000000000000000015FbDB2315678afecb367f032d93F642f64180aa3
$ echo $HASH
0x5f4c646fcd0a08f3c8643176e57920820659596cf9f1dd4753a20ad910441fe6
$ echo $SIG
0xccbfa06e5d094b350f5d1fbd14101b1e91b6086729502d73a38ea34c56f8978b2f509a90bbad58ad074ca004a2d36c3d4786cf97ff4cea4d67db27325384a9a61b
```

ボブが`claimPayment`で請求すると0.1 etherを受け取り、同じ小切手をもう一度出すと番号がすでに使われているためリバートされる：

```
gasUsed              61670
status               1 (success)
$ cast balance $BOB --ether
10000.099999999999938330
$ cast balance $RP --ether
0.900000000000000000
(同じ小切手をもう一度)
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

同じようにリバートされる場合：0.1 etherの小切手で0.5 etherを請求、ボブの分の小切手をキャロルが請求、あるReceiverPays用の小切手を新しくデプロイした別のReceiverPaysに請求。ボブが自分の分の小切手を正しい金額で出すと成功する。

EIP-191の前置きを手でつけたハッシュと、そのハッシュと署名をecrecoverのプリコンパイルコントラクト（アドレス0x01）に入れた結果。アリスのアドレスが出る：

```
$ cast keccak $(cast concat-hex $(cast from-utf8 $'\x19Ethereum Signed Message:\n32') $HASH)
0x5c1e781fb45cfe6b714131d7f7d6136da841d0c950b1460a4f52297ef69c67c4
$ cast call 0x0000000000000000000000000000000000000001 <ハッシュ, v, r, s>
0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
```

SimplePaymentChannelを、受け取る側をボブ、期間3600秒、1 etherでデプロイ：

```
Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
$ cast call $CH1 "expiration()(uint256)"
1792377822 [1.792e9]
$ cast block latest --field timestamp
1792374222
```

チャネルのアドレスと金額だけをつなげて署名したメモ（0.1、0.3 ether）で`close`を呼んだ結果。アリスが呼ぶとリバートされ、ボブがメモより大きい金額（0.9）を書くとリバートされ、正しい金額（0.3）なら成功し、閉じたチャネルにもう一度呼ぶと凍結で止められる：

```
Error: ... execution reverted, data: "0x"
Error: ... execution reverted, data: "0x"
gasUsed              53692
status               1 (success)
Error: ... execution reverted: Inactive Contract., data: "0x08c379a0..."
```

2番目のチャネルでは、最初のチャネル用のメモは通らない。期限前の`claimTimeout`とボブの`extend`もリバートされる。`cast rpc evm_increaseTime 3600`、`evm_mine`のあと、アリスの`claimTimeout`は成功し、チャネルの残高は0になる：

```
gasUsed              35844
status               1 (success)
0.000000000000000000
```

3番目のチャネルでは、期限の時刻を過ぎたあとでも（`evm_increaseTime`の累積出力10800）アリスがまだ`claimTimeout`を呼んでいないので、ボブの`close`が成功する。4番目のチャネルで残高（1 ether）より大きい2 etherのメモで`close`すると、送金が失敗して全体がリバートされ、残高は1 etherのままである。

### 試すときの注意

- `cast wallet sign`は、0xで始まるメッセージをバイトにほどき、EIP-191の前置きをつけてハッシュしてから署名する。そのためドキュメントの`prefixed`と一致する。`--no-hash`を指定すると、前置きなしでそのまま署名する。
- `cast hash-message $HASH`は、0xの文字列を文字どおり66バイトのメッセージとみなしてハッシュするので（0x474ff21e...）、ドキュメントの`prefixed`の値とは違う結果になる。前置きの確認は、上のように`cast keccak`と`cast concat-hex`で行う。
- anvilを`--gas-price 0`で起動しても、`cast send`はガス価格1 weiで送られるので、残高の末尾がgasUsedの分だけ減る。
- 新しいanvilで同じ順番でデプロイしないと、上のアドレスはそのとおりに出ない。ブロック時刻は実行のたびに違う。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメントの版 | Solidity v0.8.36、Solidity by Example > Micropayment Channel | 2026-10-19 |
| ドキュメントの例の終了方式 | close・claimTimeout・shutdownはすべてfreeze()で凍結してから残高を送金、selfdestructは不使用（"selfdestruct, which is currently deprecated"） | 2026-10-19 |
| ドキュメントの例のpragma | `>=0.7.0 <0.9.0`（二つの例とも） | 2026-10-19 |
| 署名の前置きの規則 | EIP-191、`"\x19Ethereum Signed Message:\n32"` + 32バイトのハッシュ | 2026-10-19 |
| solc | 0.8.30 | 2026-10-19 |
| Foundry（forge、cast、anvil） | 1.8.3 | 2026-10-19 |
| cast wallet signのデフォルトの動作 | 0xのメッセージはバイトにほどき、EIP-191の前置きをつけてハッシュしてから署名、`--no-hash`ならそのまま署名 | 2026-10-19 |
| ガスの実測 | イーサ送金21000、ReceiverPaysのデプロイ605901、claimPayment 61670、チャネルのデプロイ779313、close 53692、claimTimeout 35844 | 2026-10-19 |
| ブロック時刻 | expiration 1792377822、デプロイしたブロック1792374222（実行時刻によって毎回違う） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ecrecoverのv・r・s、失敗時のゼロアドレスの返却、署名の展性 | [第79講](../../part5/lecture79/) |
| splitSignatureのインラインアセンブリの行の解説（mload、byte） | [第119講](../../part7/lecture119/)、[第120講](../../part7/lecture120/)、[第121講](../../part7/lecture121/) |
| selfdestructの現在の動作と使用の非推奨 | [第80講](../../part5/lecture80/) |
| abi.encodePackedとabi.encodeの違い、つなげたときの衝突 | [第78講](../../part5/lecture78/) |
| block.timestampを誰がどれだけ動かせるか | [第76講](../../part5/lecture76/)、[第172講](../../part11/lecture172/) |
| メッセージにチェーン番号がないときに起きること、署名メッセージの設計全般 | [第172講](../../part11/lecture172/)、[第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/)、[第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| ステートチャネルとロールアップの脱出の保証、シーケンサー | [第229講](../../part17/lecture229/)〜[第234講](../../part17/lecture234/) |
| closeの「送ってからrequire」という順番と、受け取りを拒否する受取人 | [第83講](../../part5/lecture83/)、[第170講](../../part11/lecture170/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
