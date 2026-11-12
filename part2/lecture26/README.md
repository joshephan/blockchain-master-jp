# 第26講 cast：チェーンと対話するツール

第2部 開発とテスト環境・第6章 Foundryの基本

[← 第25講](../../part2/lecture25/) | [第2部 目次](../) | [第27講 →](../../part2/lecture27/)

## この講義の問い

ノードに状態を問い合わせ、トランザクションを送る作業をコマンドで直接行うと、何が見え、誰を信じることになるのか。

## 実習資料

### 準備

Foundry（cast、anvil、forge）さえあればよい。メインネットの照会は、キーなしで使える公開RPC（`https://ethereum-rpc.publicnode.com`）に読み取りのリクエストだけを送る。このアドレスには`cast send`や`cast publish`を送らない。照会の対象はWETH（`0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`）である。書き込みの練習はローカルのanvilにCounterをデプロイして行い、署名にはanvilのデフォルトアカウント0番のテスト用の鍵を使う。

### コード

| ファイル | 内容 |
|---|---|
| [code/src/Counter.sol](code/src/Counter.sol) | anvilでの書き込み練習用のCounter（increment、decrement） |

### 実行結果

メインネットの値は照会するたびに変わる。以下は2026-10-18の結果である。

`curl`でJSON-RPCの`eth_blockNumber`を直接送った応答と、`cast block-number`、`cast to-dec`：

```
{"jsonrpc":"2.0","result":"0x19008c4","id":1}
26216644
26216644
```

WETHのアカウントを`cast nonce`、`cast balance`（wei、`--ether`）、`cast code`、`cast codesize`で読んだ値：

```
1
2209935198463847038813656
2209935.198463847038813656
0x6060604052600436106100af576000357c0100...
3124
```

`cast proof`はアカウントの四つの欄を一度に見せる。`cast keccak $(cast code ...)`でコードハッシュを直接計算すると、codeHashと同じになる。出力は元の実行結果の文字列だけを訳したもの。

```
"balance":     "0x1d3f8ca6b9ffdddc88ca0"
"codeHash":    "0xd0a06b12ac47863b5c7be4185c2deaad1c61557033f56c7d4ea74429cbb25e23"
"nonce":       "0x1"
"storageHash": "0xf7b74fdbd9fb2dbefb099f1684fae4c6f16d64e69f3613c79774489a822f6e17"
"accountProof": [ ノード9個 ]

0xd0a06b12ac47863b5c7be4185c2deaad1c61557033f56c7d4ea74429cbb25e23
```

`cast storage`で読んだWETHのストレージの0、1、2番の欄。0番は`cast to-ascii`で変換すると`Wrapped Ether`、1番は`WETH`、2番は0x12（18、小数点以下の桁数）である：

```
0x577261707065642045746865720000000000000000000000000000000000001a
0x5745544800000000000000000000000000000000000000000000000000000008
0x0000000000000000000000000000000000000000000000000000000000000012
```

`cast block 26216648`の主な欄：

```
number          26216648
timestamp       1792292771 (Sun, 18 Oct 2026 03:06:11 +0000)
gasLimit        60000000
gasUsed         51443668
baseFeePerGas   46516043
```

そのブロックの中の単純な送金一つを`cast receipt`で見た結果：

```
blockNumber          26216648
effectiveGasPrice    311002861
gasUsed              21000
logs                 []
status               1 (success)
transactionHash      0x9a2ff996c5c916cd79b5dc3f02a7c4077bf62c68adb6c0405a2b3e0619c0ea7e
transactionIndex     20
type                 2
```

`cast balance --block`で見た、ブロックごとに違うWETHの残高（ETH）：

```
--block 26216583  2209669.954447952961655456
--block 26216637  2209934.473676011900871954
latest            2209938.733884065014654263
```

200ブロック前を問い合わせると、公開ノードが拒否する：

```
Error: HTTP error 403 with body: {"jsonrpc":"2.0","error":
  {"code":-32602,"message":"Archive requests require a personal token. ..."}}
```

`cast sig`、`cast calldata`で作った関数セレクタと呼び出しデータ：

```
increment()          0xd09de08a
totalSupply()        0x18160ddd
balanceOf(address)   0x70a08231

$ cast calldata "balanceOf(address)" 0x68F6C528cf6b90d5144AE774c07D6d89BCbF8E5A
0x70a08231
  00000000000000000000000068f6c528cf6b90d5144ae774c07d6d89bcbf8e5a
```

`cast call`で読んだ`totalSupply()`（ブロック番号26216653の時点）。戻り値の型を書かないと32バイトのまま、`(uint256)`と書くと10進数で出る。同じブロックの`cast balance`と最後の桁まで同じである：

```
0x00000000000000000000000000000000000000000001d3f8df59b08d0ebe8536
2209936034119267553019190 [2.209e24]
2209936034119267553019190
```

`name()(string)`、`symbol()(string)`、`decimals()(uint8)`は`"Wrapped Ether"`、`"WETH"`、`18`である。

ローカルのanvilにCounterを`cast send --create`でデプロイし、読み取りと書き込みを交互に行った結果。読み取り（`cast call`）はブロック番号も残高もナンスも変えず、書き込み（`cast send`）は三つともすべて変える：

```
デプロイ                blockNumber 1   status 1 (success)   contractAddress 0x5FbDB2315678afecb367f032d93F642f64180aa3
count()                 0
count()                 0
block-number            1
balance                 9999999855500999855501
nonce                   1
send increment()        blockNumber 2   status 1 (success)   gasUsed 43539
block-number            2
balance                 9999999817351946933261
nonce                   2
count()                 1
```

`cast send`が一度に行う仕事を分けて行った結果。`cast mktx`でナンス2のトランザクションに署名だけしておくと、ブロック番号は2のままである。`cast decode-transaction`でほどくと：

```
"signer": "0xf39f...2266"   "chainId": "0x7a69"   "nonce": "0x2"
"gas": "0x6747"   "to": "0x5fbd...0aa3"   "input": "0xd09de08a"
```

`cast publish`で送ると`"status": "0x1"   "blockNumber": "0x3"`となり、レシートのgasUsedは26439、`count()`は2になる。同じ署名のかたまりをもう一度送ると拒否される：

```
Error: server returned an error response: error code -32003: nonce too low
```

### 試すときの注意

- この公開ノードは、ブロック番号を固定した`cast proof --block`を"distance to target block exceeds maximum proof window"で拒否した。`cast proof`は最新ブロック基準で実行した。
- この公開ノードは、最新から64ブロック前の状態までは応答し、127ブロック前からは403で拒否した。ノードのポリシーによって変わる。
- デプロイのガスは144499、incrementは1回目の呼び出しが43539、2回目の呼び出しが26439だった（solc 0.8.30）。

## 時効性のあるデータ

基準日時点の値。メインネットの値はブロックごとに変わる。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公開RPCのアドレス | `https://ethereum-rpc.publicnode.com`（キーなしで使える公開ノード） | 2026-10-18 |
| 最新のブロック番号 | 26216644（`0x19008c4`） | 2026-10-18 03:05 UTC |
| WETHのアドレス | `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` | 固定 |
| WETHのナンス / ランタイムコードのサイズ | 1 / 3,124バイト | 2026-10-18 |
| WETHの残高 | 2,209,935.198463847038813656 ETH（ブロック26216644） | 2026-10-18 |
| WETHのcodeHash / storageHash | `0xd0a06b12...25e23` / `0xf7b74fdb...f6e17`（storageHashはブロックごとに変わる） | 2026-10-18 |
| accountProofのノード数 | 9個 | 2026-10-18 |
| 照会したブロック26216648 | トランザクション202件、gasUsed 51,443,668 / gasLimit 60,000,000、baseFeePerGas 46,516,043 wei | 2026-10-18 03:06:11 UTC |
| 照会した送金トランザクション | `0x9a2ff996c5c916cd79b5dc3f02a7c4077bf62c68adb6c0405a2b3e0619c0ea7e`、gasUsed 21,000、effectiveGasPrice 311,002,861 wei | 2026-10-18 |
| 単純なイーサ送金のgasUsed | 21,000。ガスの価格表を変えるアップグレードのたびに確認が必要 | 2026-10-18 |
| ブロックごとのWETHの残高 | 26216583: 2,209,669.954 / 26216637: 2,209,934.474 / latest（26216647）: 2,209,938.734 ETH | 2026-10-18 |
| 公開ノードの過去の状態の応答範囲 | 最新から64ブロック前は応答、127・128・200・500ブロック前は拒否（403、Archive requests require a personal token）。ノードのポリシーによって変わる | 2026-10-18 |
| WETHのtotalSupply（ブロック26216653） | 2,209,936,034,119,267,553,019,190 wei、同じブロックのcast balanceと一致 | 2026-10-18 |
| 実行環境 | Foundry 1.8.3（cast、anvil、forge）、solc 0.8.30 | 2026-10-18 |
| anvilでの実行値 | デプロイgasUsed 144,499 / increment gasUsed 43,539（1回目の呼び出し）、26,439（2回目） | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ストレージの欄の番号が決まる規則 | [第135講](../../part8/lecture135/) |
| ABIエンコーディングの規則（32バイトへの埋め込み、動的型） | [第78講](../../part5/lecture78/)、[第141講](../../part8/lecture141/) |
| viewとpure、読み取り関数のコスト | [第97講](../../part6/lecture97/)、[第98講](../../part6/lecture98/) |
| ローカルチェーンの運用と状態の操作 | [第27講](../../part2/lecture27/) |
| ノードの直接運用、アーカイブノード、RPCの構造 | [第235講](../../part18/lecture235/)、[第236講](../../part18/lecture236/)、[第237講](../../part18/lecture237/) |
| トランザクション送信キューとナンスの競合 | [第239講](../../part18/lecture239/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
