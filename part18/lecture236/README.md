# 第236講 RPCのアーキテクチャ

第18部 インフラ運用とデータ・第64章 ノードとRPC

[← 第235講](../../part18/lecture235/) | [第18部 目次](../) | [第237講 →](../../part18/lecture237/)

## この講義の問い

自分のアプリのリクエストは、どんな道でノードに届くのか。ノードはRPCで何を開けているのか。同じアドレスに続けて尋ねたのに答えが違うなら、それはなぜか。複数のノードの答えをどう突き合わせるのか。

## 実習資料

### 準備

通しプロジェクトMarketのこの講義のバージョン（第53章の最終バージョンに運用ツール`ops/market_read.py`を加えたバージョン）から始める。Marketのコントラクトとテストは第199講のバージョンと同じで、この講義で加えたのは`ops/market_read.py`の1ファイルである。テストにはforge-stdが必要である（`lib/forge-std`）。運用ツールはPythonの標準ライブラリだけを使う。

デモは、ローカルのanvil二台（ノードAと、`--no-mining`で立ち上げてAのブロックを後から作るノードB）と、その二つの前に立てた小さなプロキシサーバー一つで行った。プロキシサーバーは読み取りのリクエストをAとBに交互に送り、送信はAにだけ送る。RPCプロバイダーがアドレス一つの後ろにノードを複数置く形を、ローカルでまねたものである。メインネットの公開ノードの値は、別に一度読み取っただけの値である（時効性のあるデータ）。

### コード

| ファイル | 内容 |
|---|---|
| [code/ops/market_read.py](code/ops/market_read.py) | Marketの運用ツールの最初のバージョン。複数のRPCに同じブロックハッシュ（EIP-1898 `blockHash`）でstatus・assetCount・totalDepositsを尋ねて並べる。ずれているか、知らないRPCがあれば終了コード1 |
| [code/foundry.toml](code/foundry.toml) | ビルド設定（solc 0.8.30、optimizer 200、via-IR、osaka） |
| [code/src/](code/src/) | Market、IMarket、MarketMath、MarketTypes、テスト用のMockToken（第199講のバージョンそのまま） |
| [code/test/](code/test/) | 基準バージョンのテスト（136個） |

使い方：`python -I ops/market_read.py <Market> <資産> <RPC 1> [RPC 2 …] [--tag latest|safe|finalized]`。基準のハッシュは、RPC 1がそのタグで教えたブロックのハッシュである。

### 実行結果

生のJSON-RPCのリクエストとレスポンス。残高は0xを付けた16進数で来て、まとめたリクエストは配列で送って配列で受け取る。メソッド名を間違えた要素だけがエラーになる。

```
リクエスト: {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
レスポンス: {"jsonrpc": "2.0", "id": 1, "result": "0x5"}
リクエスト: {"jsonrpc": "2.0", "method": "eth_getBalance", "params": ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "0x2"], "id": 2}
レスポンス: {"jsonrpc": "2.0", "id": 2, "result": "0x21e19d9cd61d5f92fe7"}
リクエスト: [{"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 3}, {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 4}, {"jsonrpc": "2.0", "method": "eth_getBalanc", "params": ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "latest"], "id": 5}]
レスポンス: [{"jsonrpc": "2.0", "id": 3, "result": "0x7a69"}, {"jsonrpc": "2.0", "id": 4, "result": "0x5"}, {"jsonrpc": "2.0", "id": 5, "error": {"code": -32601, "message": "Method not found"}}]
```

管理者でないアカウントで`setStatus(1)`を`eth_call`で呼んだ結果。リバートのデータの先頭4バイトがNotAdminのセレクター`0x17a84242`で、後ろの32バイトが呼んだアカウントである。

```
レスポンス: {"jsonrpc": "2.0", "id": 7, "error": {"code": 3, "message": "execution reverted: custom error 0x17a84242: 00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8", "data": "0x17a8424200000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8"}}
```

プロキシサーバーのアドレス一つで預け入れ50を送ったあと、同じ質問を2回ずつした結果。読み取りがAとBに交互に行くので、高さ・レシート・totalDepositsが交互に違って出る。

```
プロキシで送った預け入れ50の取引 0xedb08470c44eb96d87398bc008339df1559dd4da4562e34fc407f0791c225490
eth_blockNumber 6
eth_blockNumber 5
eth_blockNumber 6
eth_blockNumber 5
レシート status 1 ブロック 6
レシート None
totalDeposits latest 120
totalDeposits latest 70
```

同じ質問を、Aの最新のブロックハッシュに固定して尋ねた結果（EIP-1898）。そのブロックをまだ知らないBは、違う値を返す代わりに`-32001 Resource not found`で答える。

```
A 最新 6 0x9bf6fb54551a2cf7d9448f82152164e95e84391b7968a1a2780428e5f39b90da
totalDeposits @blockHash 120
totalDeposits @blockHash {'code': -32001, 'message': 'Resource not found'}
```

`ops/market_read.py`をA、B、プロキシの三つに対して実行した結果。Bが6番ブロックを後から作る前はずれ（終了コード1）、作ったあとは三つが同じ答え（終了コード0）である。

```
基準ブロック: latest 6 0x9bf6fb54551a2cf7d9448f82152164e95e84391b7968a1a2780428e5f39b90da (RPC 1が教えたもの)
RPC        status                    assetCount                totalDeposits
ノードA    0                         1                         120
ノードB    不明(Resource not found)  不明(Resource not found)  不明(Resource not found)
プロキシ   0                         不明(Resource not found)  120
違い: status -> ['0', '不明(Resource not found)']
違い: assetCount -> ['1', '不明(Resource not found)']
違い: totalDeposits -> ['120', '不明(Resource not found)']
結果: ずれあり
終了コード 1

基準ブロック: latest 6 0x9bf6fb54551a2cf7d9448f82152164e95e84391b7968a1a2780428e5f39b90da (RPC 1が教えたもの)
RPC        status  assetCount  totalDeposits
ノードA    0       1           120
ノードB    0       1           120
プロキシ   0       1           120
結果: すべてのRPCが同じ答え
終了コード 0
```

RPC欄のローカルのアドレスはノードA、ノードB、プロキシに書き換え、列の間隔だけを詰めた。

Aに空のブロックを埋めて高さ100にしたあと、ブロックのタグが指す番号：

```
{'latest': 100, 'safe': 68, 'finalized': 36, 'earliest': 0}
```

`eth_getLogs`もブロックハッシュで尋ねられる。4番ブロックのハッシュで尋ねるとログは一つ（topic `0x8752a472` = `Deposited(address,address,uint256)`）で、知らないハッシュを与えるとエラーになる。

```
anvil eth_getLogs blockHash ブロック 4: ログ 1 ['0x8752a472']
知らないハッシュ {"jsonrpc": "2.0", "id": 4, "error": {"code": -32000, "message": "unknown block"}}
```

テストは`forge test --offline`で136個がすべて通る（ガスの記録の比較を切るには`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`）。

### 試すときの注意

- プロキシサーバーの最初の`eth_blockNumber`がAに行っても、Aが預け入れの取引をまだブロックに入れる前なら5が出ることがある。最初の実行では高さが5・5・6・5と出た。実行するたびに違うことがある。
- レシートが`None`なのは失敗ではなく、「このノードはまだその取引を知らない」という意味でありうる。同じ取引を送り直す前に、どのノードに尋ねたのかをまず見る。
- ブロックがないときのエラー番号はノードごとに違う。anvilは`eth_call`に`-32001 Resource not found`、`eth_getLogs`に`-32000 unknown block`を返した。geth文書は、許可していない名前空間に-32602と書いているが、公開ノードは-32601で答えた。
- 公開ノードにPythonのデフォルトのUser-Agentで送るとHTTP 403になった。ツールは`User-Agent: market-ops`を付ける。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（anvil・cast・forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| 公開RPC | ethereum-rpc.publicnode.com、clientVersion reth/v2.7.0-3d592ec（6回とも同じ）、net_peerCount 0x27、eth_syncing false | 2026-10-20 18:54 UTC |
| メインネットのタグ | latest 26,235,715 / safe 26,235,663（52後ろ） / finalized 26,235,632（83後ろ、時刻の差1,008秒） | 2026-10-20 18:54 UTC |
| 公開ノードが塞いだメソッド | admin_nodeInfo -32601 Method not found / debug_getRawHeader -32601 does not exist/is not available | 2026-10-20 18:54 UTC |
| 公開ノードのeth_getLogsの区間 | WETHのアドレス、直近10・100・1,000・10,000ブロック → 659・5,802・57,578・574,255個、1万ブロックの区間も拒否しない。ノード・プロバイダーごとに違う | 2026-10-20 19:14 UTC |
| ノードサービス | ethereum.org Nodes as a serviceに30か所（AlchemyからZeeveまで）。無料プラン・リクエストの上限は所ごとに違う。推薦ではない | 2026-10-20 |
| gethのデフォルトのポート | HTTP JSON-RPC 127.0.0.1:8545、Engine API 8551 | 2026-10-16 |
| 公開ノードのリクエストのヘッダー | PythonのデフォルトのUser-Agentで送るとHTTP 403、名前を付けると受け付ける | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| RPCの答えを証明で確かめる | [第237講](../../part18/lecture237/) |
| 新しいブロック・ログを購読する接続（WebSocket eth_subscribe）とログの収集 | [第238講](../../part18/lecture238/) |
| 同じナンスで複数の取引を送るときの、ノードごとに違う待ち行列 | [第239講](../../part18/lecture239/) |
| ガスの見積もりをどのノード・どのブロックで行うか | [第240講](../../part18/lecture240/) |
| RPCの応答の遅れ・高さの差の監視 | [第241講](../../part18/lecture241/) |
| RPCプロバイダーごとのリクエストの上限と値段 | 付録のデータシート |

出典と参考資料は[reference.md](reference.md)にまとめた。
