# 第238講 イベントのインデックス化とreorgへの対応

第18部 インフラ運用とデータ・第65章 インデックス作成とトランザクション管理

[← 第237講](../../part18/lecture237/) | [第18部 目次](../) | [第239講 →](../../part18/lecture239/)

## この講義の問い

ログを読んで帳簿を組み立て直すプログラムは、どこまで読んだかを何で記録すべきか。同じ番号のブロックが変わったら、何を戻すのか。何ブロック待つのか。自分が組み立てた帳簿が合っているかどうかは、どうやってわかるのか。

## 実習資料

### 準備

第237講のバージョン（第53章の最終バージョンのMarket + 運用ツール三つ）に、インデクサー`ops/indexer.py`を加えたバージョンから始める。Marketのコントラクトとテストは第199講のバージョンと同じである。テストにはforge-stdが必要である（`lib/forge-std`）。インデクサーはPythonの標準ライブラリだけを使い、読み取りのリクエストだけを送る。

デモはローカルのanvil一台で行った（`anvil_setBlockTimestampInterval 1`）。MarketとMockTokenをデプロイし、同じ形のDepositedログを出す偽のコントラクトLookAlike（`test/Rebuild.t.sol`の中）をもう一つデプロイしたあと、取引七つ（トークンの支給二つ、預け入れ100・50、引き出し30、失敗する預け入れ0、偽のログ1000）を送る。同じチェーンを、インデクサーの三つのバージョンで読む。

- ハッシュ版（デフォルト）：ブロックごとにハッシュを書いておき、次の周回で比べて、分岐したブロックを戻す
- 番号版（`--naive`）：ブロック番号だけでつないで読む（比較用）
- 確定の深さ版（`--confirm 3`）：最新から3ブロック後ろまでだけを読む

再編成は`anvil_reorg`で深さ2と深さ5を作った。新しいログの購読は`cast`で行った。

### コード

| ファイル | 内容 |
|---|---|
| [code/ops/indexer.py](code/ops/indexer.py) | Marketのログ（AssetAdded、StatusChanged、Deposited、Withdrawn）で預け入れの帳簿を組み立て直すインデクサー。ブロックごとにハッシュを`eth_getLogs` `blockHash`で尋ね、書いておいたハッシュと違えば、そのブロックで反映した分だけ戻す。確定の深さの外のブロックが変わるとSTOP。状態ファイルは一時ファイルに書いてから差し替える |
| [code/ops/market_read.py](code/ops/market_read.py)、[code/ops/market_verify.py](code/ops/market_verify.py)、[code/ops/mpt.py](code/ops/mpt.py) | 第236・237講の運用ツール（そのまま） |
| [code/foundry.toml](code/foundry.toml) | ビルド設定（solc 0.8.30、optimizer 200、via-IR、osaka） |
| [code/src/](code/src/) | Market、IMarket、MarketMath、MarketTypes、テスト用のMockToken（第199講のバージョンそのまま） |
| [code/test/](code/test/) | 基準バージョンのテスト（136個）。デモで使ったLookAlikeは`test/Rebuild.t.sol`の中にある |

使い方：`python -I ops/indexer.py <RPC> <Market> <状態ファイル> [--confirm N] [--naive]`。1回呼ぶたびに1周（再編成の確認 → 確定の深さまでブロックを一つずつ読む → 状態ファイルの保存）する。

### 実行結果

送った取引七つ。預け入れ0はstatus 0である。

```
give 1 block 5 status 1 gasUsed 51423
give 2 block 6 status 1 gasUsed 51411
acct1 deposit 100 block 7 status 1 gasUsed 136902
acct2 deposit 50 block 8 status 1 gasUsed 102702
acct1 withdraw 30 block 9 status 1 gasUsed 66415
acct2 deposit 0 (fails) block 10 status 0 gasUsed 26356
lookalike fake 1000 block 11 status 1 gasUsed 23952
```

最初の周回。ハッシュ版と番号版は120 / 70 / 50、確定の深さ3版は8番ブロックまでだけを読んで150 / 100 / 50である。帳簿を同じブロック基準のチェーンの状態と突き合わせると同じである。

```
[safe] round1 ... next 12 total 120 pos アカウント1 70, アカウント2 50
[naive] round1 ['read 0..11 logs 4'] next 12 total 120
[conf] round1 ... next 9 total 150 pos アカウント1 100, アカウント2 50
  check 11 total indexer 120 chain 120 OK
```

topic0だけで尋ねると偽のコントラクトのログまで混ざり、アドレスまで指定するとMarketのログだけが残る。失敗した取引はログがなく、logsBloomも空である。

```
  getLogs topic0 only [('0xe7f172', 100), ('0xe7f172', 50), ('0xcf7ed3', 1000)]
  getLogs address+topic0 [('0xe7f172', 100), ('0xe7f172', 50)]
  block 10 receipt status 0x0 gasUsed 26356 logs 0
  bloom 8 nonzero bytes 12
  bloom 9 nonzero bytes 12
  bloom 10 nonzero bytes 0
  bloom 11 nonzero bytes 12
```

預け入れ20（12番ブロック）と引き出し70（13番ブロック）を読んだあと、深さ2の再編成で二つのブロックを入れ替えた（新しく作った12番ブロックの中には預け入れ5だけがある）。ハッシュ版は、書いておいたハッシュと変わったブロックを戻して読み直して合い、番号版はすでに通り過ぎた番号なので何もせず、ずれる。

```
  after reorg block 12 0xc8ad5733 -> 0xfd0b4c73 txs 1
  after reorg block 13 0xca038701 -> 0x7715b0a0 txs 0
[safe] round3 ['reorg: block 13 0xca038701 -> 0x7715b0a0, undo 1 logs', 'reorg: block 12 0xc8ad5733 -> 0xfd0b4c73, undo 1 logs', 'block 12 0xfd0b4c73 logs 1'] next 14 total 125
  check 13 total indexer 125 chain 125 OK
  check 13 pos アカウント2 indexer 55 chain 55 OK
  check 13 pos アカウント1 indexer 70 chain 70 OK
[naive] round3 [] next 14 total 70
  check 13 total indexer 70 chain 125 MISMATCH
  check 13 pos アカウント2 indexer 70 chain 55 MISMATCH
  check 13 pos アカウント1 indexer 0 chain 70 MISMATCH
```

確定の深さ3版は、変わったブロックをまだ読んでおらず、そのあとで読んで合う。深さ5の再編成が来ると、すでに確定とみなしたブロックが変わったので、直さずに止まる。

```
[conf] round4 ['block 12 0xfd0b4c73 logs 1'] next 14 total 125
  check 13 total indexer 125 chain 125 OK
[conf] deep reorg ['STOP: confirmed block 13 changed 0x7715b0a0 -> 0x41469110 (reorg deeper than 3)']
[safe] deep reorg ['reorg: block 13 0x7715b0a0 -> 0x41469110, undo 0 logs', 'reorg: block 12 0xfd0b4c73 -> 0x4c01f640, undo 1 logs'] total 120
  check 16 total indexer 120 chain 120 OK
```

購読の側は、分岐したブロックのログを`removed: true`で送り直す。

```
12 0xc8ad5733 Deposited 20 removed false
13 0xca038701 Withdrawn 70 removed false
12 0xc8ad5733 Deposited 20 removed true
13 0xca038701 Withdrawn 70 removed true
12 0xfd0b4c73 Deposited 5 removed false
```

押し出されたブロックのハッシュで尋ねると、メソッドごとに違う答えが来る。

```
eth_getLogs {'jsonrpc': '2.0', 'id': 1, 'error': {'code': -32000, 'message': 'unknown block'}}
eth_getBlockByHash {'jsonrpc': '2.0', 'id': 1, 'result': None}
eth_call {'jsonrpc': '2.0', 'id': 1, 'error': {'code': -32001, 'message': 'Resource not found'}}
```

ブロックのタグ。高さ16ではsafe・finalizedが0で、空のブロックを100個足すと116 / 84 / 52である。

`forge lint --offline`は、外部呼び出しのあとにイベントを出す行に`reentrancy-events`の警告を出す（Market.sol 179:9 Deposited、201:9 Withdrawn、そのほか418:9、428:9、449:9）。

出力で、帳簿の欄のアカウントのアドレスはアカウント1・アカウント2に縮め、ハッシュは先頭8桁だけを残した。

### 試すときの注意

- ブロックハッシュは実行するたびに違う。ガス・ブロック番号・帳簿の値は、`anvil_setBlockTimestampInterval 1`を基準に同じに出る。
- インデクサーはMarketのイベント四つだけを読む。清算はDeposited・Withdrawnなしで担保の欄を移し、利子はログなしで指数を上げるので、借りる人が出てくると、この預け入れの帳簿はチェーンの状態と突き合わせたときにずれる。
- 帳簿と突き合わせるtotalDeposits・positionsの欄は、利子の指数で割った持ち分である。このデモは借りた人がいないので指数が1で、持ち分とトークンの量が同じである。
- 失敗した取引は、レシートにログがない。ログで数える帳簿には、失敗した試みは残らない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（anvil・cast・forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| メインネットのsafe・finalizedの距離 | 公開RPC（ethereum-rpc.publicnode.com、reth/v2.7.0） latest 26,235,715 / safe 26,235,663（52後ろ） / finalized 26,235,632（83後ろ、時刻の差1,008秒） | 2026-10-20 18:54 UTC |
| 公開RPCの`eth_getLogs`の区間 | 同じノードで、WETHのアドレスの直近10・100・1,000・10,000ブロックにログ659・5,802・57,578・574,255個、1万ブロックの区間も拒否なし。プロバイダーごとに違う | 2026-10-20 19:14 UTC |
| インデクサーサービスの名前 | The Graph、Ponder、Envio、Goldskyなど（再編成の扱い方はサービスごとに違い、確かめていない、推薦ではない） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 複数のノードから受け取ったログを突き合わせること、RPCプロバイダーの`eth_getLogs`の区間の上限 | [第235講](../../part18/lecture235/)、[第236講](../../part18/lecture236/)、[第237講](../../part18/lecture237/) |
| 帳簿がずれたときにアラートを鳴らして止まる手順 | [第241講](../../part18/lecture241/)、[第242講](../../part18/lecture242/) |
| ログを原材料に使う分析 | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| インデクサーサービスの選び方 | データの行 |

出典と参考資料は[reference.md](reference.md)にまとめた。
