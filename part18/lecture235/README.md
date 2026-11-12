# 第235講 ノードの自力運用

第18部 インフラ運用とデータ・第64章 ノードとRPC

[← 第234講](../../part17/lecture234/) | [第18部 目次](../) | [第236講 →](../../part18/lecture236/)

## この講義の問い

ノードを自分で動かすとは、何を動かすことなのか。ノードは、他人が作ったブロックをどうやって自分のものとして受け入れるのか。自分のノードは何をどれだけ持っていて、そのためには何が要るのか。

## 実習資料

### 準備

anvil二台を同じジェネシス（`--timestamp 1790000000`）で立ち上げ、ノードAとノードBとして使う。Aは自分でブロックを作り、Bは`--no-mining`で立ち上げて、Aが渡した取引のバイトだけでブロックを後から作る。AにデプロイするMarketは第53章の最終バージョン（第199講のバージョン）そのままで、この講義で直したコードはない。Marketのソースは[第199講の付録のcode/](../../part13/lecture199/code/)にある。外部への接続は使わない。

デモは四つの段階である。

- A1：anvilにノードの情報を尋ねる（`web3_clientVersion`、`eth_chainId`、`eth_syncing`、`net_peerCount`、`net_listening`、`anvil_nodeInfo`）。
- A2：AにMockToken・Marketをデプロイ、addAsset、預け入れ100、引き出し30、1 ETHの送金三つ（ブロック八つ）。Bには、ブロックごとに`evm_setNextBlockTimestamp` → `eth_sendRawTransaction` → `evm_mine`で、同じ時刻、同じ取引を渡す。
- A3：4番ブロックの預け入れの取引一つだけを抜いて、Bを新しく立ち上げて同じことをする。
- A4：anvilのデフォルトのほうと`--prune-history 4`のほうに1 ETHの送金を10回送ったあと、ブロック1・5・6・10の時点の残高を`eth_getBalance`で尋ねる。

### 実行結果

A1. anvilにノードの情報を尋ねた結果。ピアを数えるメソッドがなく、合意クライアントもない。出力は元の実行結果の文字列だけを訳したもの。

```
web3_clientVersion {"jsonrpc": "2.0", "id": 1, "result": "anvil/v1.8.3"}
eth_chainId {"jsonrpc": "2.0", "id": 2, "result": "0x7a69"}
eth_syncing {"jsonrpc": "2.0", "id": 3, "result": false}
net_peerCount {"jsonrpc": "2.0", "id": 4, "error": {"code": -32601, "message": "Method not found"}}
net_listening {"jsonrpc": "2.0", "id": 5, "result": true}
anvil_nodeInfo hardFork Bpo1 chainId 31337
```

A2. BがAから取引だけを受け取って再実行した結果。ブロック1〜8のステートルートとブロックハッシュがすべて同じである。出力は元の実行結果の文字列だけを訳したもの。

```
A 高さ 8 MockToken 0x5FbDB2315678afecb367f032d93F642f64180aa3 Market 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
B 開始の高さ 0 ジェネシスブロックのハッシュが同じ True
ブロック | 取引数 | Aのヘッダーのステートルート | Bが再実行したステートルート | ルートが同じ | ブロックハッシュが同じ
1 | 1 | 0xd2820795b249… | 0xd2820795b249… | True | True
2 | 1 | 0x5614d3780678… | 0x5614d3780678… | True | True
3 | 1 | 0x2e17b47d9645… | 0x2e17b47d9645… | True | True
4 | 1 | 0x69cba9d16404… | 0x69cba9d16404… | True | True
5 | 1 | 0xb1b20713a338… | 0xb1b20713a338… | True | True
6 | 1 | 0xc81b04fe1a9c… | 0xc81b04fe1a9c… | True | True
7 | 1 | 0x77434b8f05cc… | 0x77434b8f05cc… | True | True
8 | 1 | 0xaeca76d89db1… | 0xaeca76d89db1… | True | True
BのtotalDeposits 70
```

A3. 4番ブロックの預け入れの取引（先頭4バイト`0x47e7ef24`）を抜いた結果。ブロック1〜3は同じで、ブロック4から8までステートルートとブロックハッシュがすべて違う。出力は元の実行結果の文字列だけを訳したもの。

```
抜いた取引 0x962f9b1de1ee2d86eaf8d6b71aa8bb2e961a596ad001fc2ac1412c2cbffa382f inputの先頭4バイト 0x47e7ef24
ブロック | 取引数 | Aのヘッダーのステートルート | Bが再実行したステートルート | ルートが同じ | ブロックハッシュが同じ
1 | 1 | 0xd2820795b249… | 0xd2820795b249… | True | True
2 | 1 | 0x5614d3780678… | 0x5614d3780678… | True | True
3 | 1 | 0x2e17b47d9645… | 0x2e17b47d9645… | True | True
4 | 1 | 0x69cba9d16404… | 0x543feb706249… | False | False
5 | 1 | 0xb1b20713a338… | 0xb3eeba613ea3… | False | False
6 | 1 | 0xc81b04fe1a9c… | 0xc3eb287d3076… | False | False
7 | 1 | 0x77434b8f05cc… | 0x56b75a438e88… | False | False
8 | 1 | 0xaeca76d89db1… | 0xd0eece173ccf… | False | False
```

A4. 状態を全部置くノードと最近の状態だけを置くノードに、過去のブロックの残高を尋ねた結果。刈り込んだほうも、ブロックのヘッダーは返す。出力は元の実行結果の文字列だけを訳したもの。

```
全部置く(anvilデフォルト) 高さ 10
  ブロック 1 時点のアカウント1番の残高: 10001000000000000000000
  ブロック 5 時点のアカウント1番の残高: 10005000000000000000000
  ブロック 6 時点のアカウント1番の残高: 10006000000000000000000
  ブロック 10 時点のアカウント1番の残高: 10010000000000000000000
最近だけ(--prune-history 4) 高さ 10
  ブロック 1 時点のアカウント1番の残高: {'code': -32602, 'message': 'BlockOutOfRangeError: block height is 10 but requested was 1'}
  ブロック 5 時点のアカウント1番の残高: {'code': -32602, 'message': 'BlockOutOfRangeError: block height is 10 but requested was 5'}
  ブロック 6 時点のアカウント1番の残高: 10006000000000000000000
  ブロック 10 時点のアカウント1番の残高: 10010000000000000000000
  ブロック 1 ヘッダー(stateRoot) 0x91edc5ea22d7…
```

### 試すときの注意

- ブロックの時刻が状態に入るので、BがAと同じルートを作るには、ブロックごとにAと同じ時刻を先に決めてやらなければならない（`evm_setNextBlockTimestamp`）。
- A4の1番ブロックのヘッダーのステートルートは、最初の送金がanvilを立ち上げてから何秒目に届くかによって、`0x91ed…`または`0xc6df…`に変わる。Marketとは関係ない。
- ブロックハッシュは前のブロックのハッシュを含むので、取引一つが変わると、そのブロックから後ろのブロックハッシュがすべて変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（anvil・cast・forge） | 1.8.3 (cae51ad4)、anvil_nodeInfo hardFork Bpo1 | 2026-10-21 |
| 実行クライアントの名前 | Geth、Nethermind、Besu、Erigon、Reth、ethrex、EthereumJS（ベータ） | 2026-10-20 |
| 合意クライアントの名前 | Lighthouse、Lodestar、Nimbus、Prysm、Teku、Grandine | 2026-10-20 |
| ハードウェアの仕様 | 最小16GB RAM・2TB NVMe SSD、推奨32GB RAM・4TB NVMe SSD | 2026-10-20 |
| クライアントごとのディスク | スナップ：Geth・Nethermind 500GB+、Besu 800GB+ / アーカイブ：Geth・Nethermind・Besu 12TB+、Erigon 2.5TB+、Reth 2.2TB+ / Erigon・Rethのフル刈り込み約2TB・1.2TB / 合意側でさらに約200GB | 2026-10-20 |
| gethのアーカイブ | ハッシュベースは20TBを超えることがある、パスベースは約2TB（トライの履歴まで含めて約6.5TB）、v1.16.xのアーカイブは過去のブロックのeth_getProofができない | 2026-10-16 |
| gethのデフォルトのポート | JSON-RPC 8545、Engine API 8551、P2P 30303 | 2026-10-16 |
| イーサリアムのノード数 | 11,955台（直近24時間で検出） | 2026-10-20 |
| クライアントのシェア | 文書作成時点で「Geth 約85%」（実行側はsupermajority.info 2025-10-26、合意側はblockprintを引用） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 自分のリクエストがノードに届く道とRPCプロバイダー | [第236講](../../part18/lecture236/) |
| 他人のノードの答えを確かめる方法と、チェックポイントを信じる問題 | [第237講](../../part18/lecture237/) |
| 分岐したブロックが入れ替わったときに、受け取った記録を直すこと | [第238講](../../part18/lecture238/) |
| ノードの状態の監視とアラート | [第241講](../../part18/lecture241/) |
| バリデータークライアントとブロックの提案 | 付録 |
| 過去のブロック本体・レシートの削除（history expiry） | 付録のデータシート（gethのHistory pruningの原文） |
| 脱出に使うデータを受け取っておき、組み立て直すこと | [第238講](../../part18/lecture238/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
