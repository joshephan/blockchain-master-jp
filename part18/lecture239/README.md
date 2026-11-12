# 第239講 ナンスの競合と送信キュー

第18部 インフラ運用とデータ・第65章 インデックス作成とトランザクション管理

[← 第238講](../../part18/lecture238/) | [第18部 目次](../) | [第240講 →](../../part18/lecture240/)

## この講義の問い

一つのアカウントで取引を複数の場所から送ると、何が壊れるのか。送って応答を受け取れなかったとき、送り直してもよいのか。取引を一度だけ、順番どおりに出すには、サーバーは何を書いておかなければならないのか。

## 実習資料

### 準備

第238講のバージョン（第53章の最終バージョンのMarket + 運用ツール四つ）に、送信キュー`ops/sendq.py`を加えたバージョンから始める。Marketのコントラクトとテストは第199講のバージョンと同じである。テストにはforge-stdが必要である（`lib/forge-std`）。送信キューは、Pythonの標準ライブラリに、署名・calldataを作る`cast`（Foundry）を加えて使う。

デモは、ローカルのanvil一台を`--no-mining`で立ち上げ、ブロックを手で作りながら行った。Marketをデプロイし、addAssetまで行ったあと、運用アカウント一つ（アカウント0番）でトークンの支給だけを送る。署名はanvilのデフォルトのテスト用の鍵だけで行った。

- 競合：ワーカー二つが同じアカウントの同じナンスを受け取って送る（同じ手数料、二つ目が多く払う）
- `latest`でナンスを受け取り直して送る、ナンスを一つ飛ばして送る（空いた番号）、応答を失ったとみなして新しいナンスで送り直す
- 送信キューの3周（送った直後、日誌に書く前に死ぬ → 起動し直す → 確認）、キューの外から同じアカウントで送る

### コード

| ファイル | 内容 |
|---|---|
| [code/ops/sendq.py](code/ops/sendq.py) | 運用アカウント一つの送信キュー（第239講のバージョン）。ナンスはこのキューだけが採番し、送る前に署名した取引を日誌に先に書く（signed）。起動し直すと、書いておいた同じバイトを送り直す。状態 new → signed → sent → mined / failed / send_error・conflict |
| [code/ops/indexer.py](code/ops/indexer.py)、[code/ops/market_read.py](code/ops/market_read.py)、[code/ops/market_verify.py](code/ops/market_verify.py)、[code/ops/mpt.py](code/ops/mpt.py) | 第236〜238講の運用ツール（そのまま） |
| [code/foundry.toml](code/foundry.toml) | ビルド設定（solc 0.8.30、optimizer 200、via-IR、osaka） |
| [code/src/](code/src/) | Market、IMarket、MarketMath、MarketTypes、テスト用のMockToken（第199講のバージョンそのまま） |
| [code/test/](code/test/) | 基準バージョンのテスト（136個） |

使い方：`python -I ops/sendq.py <RPC> <日誌ファイル> <運用アカウントの鍵> [--crash-after-send <id>]`。1回呼ぶたびに1周する。`cast`は`~/.foundry/bin`から探す。

### 実行結果

同じナンスの競合。手数料が同じなら二つ目の取引は`replacement transaction underpriced`で拒否され、二つ目が多く払うと一つ目を押し出す（一つ目のレシートなし）。

```
race [same fee] worker0 nonce 3 pay acct1 10 -> 0xae2cd020… | worker1 nonce 3 pay acct2 20 -> replacement transaction underpriced
  mined (4, 1) acct1 0 -> 10 acct2 0 -> 0
race [second pays more] worker0 nonce 4 pay acct1 10 -> 0x2946ac28… | worker1 nonce 4 pay acct2 20 -> 0x635a2e71…
  mined (5, 1) acct1 10 -> 10 acct2 0 -> 20
  worker0 receipt False
  worker1 receipt True
```

ブロックに入る前に`latest`でナンスを受け取り直すと、同じ番号が出る。ナンス6を飛ばして7・8を送るとqueuedにとどまり、空のブロックが三つ過ぎても入らず、6を埋めると三つが一つのブロックに入る。

```
send nonce 5 0x2c9d3227…
latest again 5 ->  replacement transaction underpriced | pending says 6
gap: skip nonce 6 send 7 0xd39786ce… send 8 0x41aff3a6…
  pool {'pending': '0x0', 'queued': '0x2'}
  mined (7, 0) pool {'pending': '0x0', 'queued': '0x2'}
  mined (8, 0) pool {'pending': '0x0', 'queued': '0x2'}
  mined (9, 0) pool {'pending': '0x0', 'queued': '0x2'}
  fill nonce 6 0x01491c2c…
  mined (10, 3) pool {'pending': '0x0', 'queued': '0x0'} nonce 9
```

応答を失ったとみなして新しいナンスで送り直すと、2回とも入り、受け取る側の残高が2回増える。

```
naive retry: first nonce 9 0x0955c344 | retry nonce 10 0x41b4d25b
  mined (11, 2) acct3 5 -> 65
```

送信キューの3周。1周目はpay2を送った直後、日誌にsentを書く前に死ぬ。起動し直すと、日誌に書いておいた同じバイトを送り直し、ノードは`already imported`と答える。三つとも1回ずつだけ入る。

```
queue run1 ['pay1 nonce 11 gas 34311 sent -> 0x6be3772d', "pay2 nonce 12 sent, CRASH before writing 'sent'"]
  journal [('pay1', 11, 'sent'), ('pay2', 12, 'signed'), ('pay3', None, 'new')]
queue run2 (restart) ['pay1 nonce 11 resend same raw -> transaction already imported', 'pay2 nonce 12 resend same raw -> transaction already imported', 'pay3 nonce 13 gas 34311 sent -> 0xaf47ebbe']
  pool {'pending': '0x3', 'queued': '0x0'}
  mined (12, 3)
queue run3 ['pay1 nonce 11 mined block 12 gasUsed 34311 by 0x6be3772d (hashes 1)', 'pay2 nonce 12 mined block 12 gasUsed 34311 by 0x5d42fa8c (hashes 1)', 'pay3 nonce 13 mined block 12 gasUsed 34311 by 0xaf47ebbe (hashes 1)']
  acct3 65 -> 86 nonce 14
  resend mined raw nonce too low
```

キューの外から同じアカウントでナンス14を使ってしまうと、キューの次の仕事は拒否され、キューが止まる。

```
outside sender nonce 14 0x6f1374dc…
queue after outside send ['pay4 nonce 14 REJECTED nonce too low, queue stops']
```

同じナンスの置き換えの幅を別に測ると、anvilは同じ手数料を拒否し、5%上げると受け付ける。

ハッシュは先頭部分だけを残して縮めた。

### 試すときの注意

- ナンスを採番する場所が二つあると（ワーカー二つ、キューと運用者のノートパソコン）、同じ番号が出る。一つのアカウントのナンスは一か所でだけ採番する。
- 送る前に署名したバイトを日誌に先に書いておけば、死んでから起動し直しても、新しいナンスで署名し直さずに同じバイトを送り直せる。同じバイトは同じハッシュなので、2回入ることはない。
- `txpool_status`のqueuedは、前の番号が空いていて待っている取引である。空いた番号が埋まるまでは、ブロックが過ぎても入らない。
- 置き換えのルールの幅はクライアントごとに違う（時効性のあるデータ）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（anvil・cast） | 1.8.3 (cae51ad4) | 2026-10-21 |
| anvilの同じナンスの置き換え | 同じ手数料は`replacement transaction underpriced`、5%上げると受け付ける | 2026-10-21 |
| gethの置き換えのルールのデフォルト値 | `--txpool.pricebump value (default: 10)`、blobプール`--blobpool.pricebump` 100 | 2026-10-16 |
| ウォレットライブラリのナンス管理 | ethers v6 `NonceManager`（"wraps another Signer and automatically manages the nonce"）、viem `nonceManager`・`createNonceManager`（`viem/nonce`、Local Account用）。名前のみ、推薦ではない | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 詰まった取引を同じナンスで置き換えて送ること、ガスの見積もりが外れるとき | [第240講](../../part18/lecture240/) |
| キューを複数台に増やして切り替える運用 | [第241講](../../part18/lecture241/)、[第242講](../../part18/lecture242/) |
| 運用アカウントの鍵の保管と署名サーバー | [第254講](../../part20/lecture254/)〜[第260講](../../part20/lecture260/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
