# 第240講 ガスの見積もりの失敗と再送信

第18部 インフラ運用とデータ・第65章 インデックス作成とトランザクション管理

[← 第239講](../../part18/lecture239/) | [第18部 目次](../) | [第241講 →](../../part18/lecture241/)

## この講義の問い

ガスの見積もりは、何を見て出した値なのか。見積もりが通ったのに、なぜブロックで失敗するのか。見積もりで止まった仕事はどうするのか。詰まったり消えたりした取引を送り直すときは、何を送り、いつ止めるのか。

## 実習資料

### 準備

第239講のバージョン（第53章の最終バージョンのMarket + 運用ツール五つ）から、送信キュー`ops/sendq.py`を直したバージョン（第65章の最終バージョン）から始める。Marketのコントラクトとテストは第199講のバージョンと同じである。テストにはforge-stdが必要である（`lib/forge-std`）。送信キューは、Pythonの標準ライブラリに`cast`（Foundry）を加えて使う。

デモは、ローカルのanvil一台を`--no-mining`で立ち上げ、ブロックを手で作りながら行った。最後の[7]だけは、別に`--hardfork osaka --enable-tx-gas-limit`で立ち上げたanvilで、第229講で使った、欄をn個新しく書くコントラクトFill229の`fill(n)`で行った。署名はanvilのデフォルトのテスト用の鍵だけで行った。

### コード

| ファイル | 内容 |
|---|---|
| [code/ops/sendq.py](code/ops/sendq.py) | 送信キューの第240講のバージョン。見積もりで止まると送らずに`estimate_failed`（ナンスを使わない）、一つの仕事に署名した取引・ハッシュを複数残す（`raws`・`hashes`）、確定の深さ`--confirm N`が過ぎると`done`、レシートが消えると同じバイトで送り直す、`bump()`で同じナンスに手数料を上げて署名し直す |
| [code/ops/indexer.py](code/ops/indexer.py)、[code/ops/market_read.py](code/ops/market_read.py)、[code/ops/market_verify.py](code/ops/market_verify.py)、[code/ops/mpt.py](code/ops/mpt.py) | 第236〜238講の運用ツール（そのまま） |
| [code/foundry.toml](code/foundry.toml) | ビルド設定（solc 0.8.30、optimizer 200、via-IR、osaka） |
| [code/src/](code/src/) | Market、IMarket、MarketMath、MarketTypes、テスト用のMockToken（第199講のバージョンそのまま） |
| [code/test/](code/test/) | 基準バージョンのテスト（136個） |

使い方：`python -I ops/sendq.py <RPC> <日誌ファイル> <運用アカウントの鍵> [--crash-after-send <id>] [--confirm N]`。

### 実行結果

[1] 市場を止めた状態で預け入れ・引き出しを見積もると、ノードがリバートのデータと一緒に拒否する（NotActive `0x1d61e8ee`、InsufficientDeposit `0x25c3f46e`）。キューは送らず、ナンスも使わない。`cast send`も同じところで止まる。

```
[1] paused market ['dep1 estimate failed, not sent, nonce 0 not used: execution reverted: 0x1d61e8ee0000000000000000000000000000000000000000000000000000000000000001', 'wd1 estimate failed, not sent, nonce 0 not used: execution reverted: 0x25c3f46e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001']
[1] cast send 1 Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x1d61e8ee: , data: "0x1d61e8ee00000000000000000000000000000000000000000000000000000000
[1] acct2 nonce latest/pending 0 0
```

[2] 見積もりが通った預け入れを送るあいだに、管理者がチップを多く付けて`setStatus(1)`を送った。同じブロックで管理者の取引が先に実行され、預け入れはstatus 0で入り、手数料は払う。出力は元の実行結果の文字列だけを訳したもの。そこに出るベースフィーは元の実行のデプロイが使ったガスで決まるので、このフォルダのコードで実行し直すとeffGasPrice、手数料、ハッシュが変わることがある。

```
[2] user estimate+send ['dep2 nonce 0 gas 102702 sent -> 0x11b4ad63']
[2] admin setStatus(1) higher tip 0xb7d11a90
[2] mined (10, 2)
[2] block order ['0xf39f', '0x3c44']
[2] after mine ['dep2 nonce 0 failed block 10 gasUsed 24179 by 0x11b4ad63 (hashes 1)']
[2] receipt status 0x0 gasUsed 24179 effGasPrice 1308179604 fee wei 31630474645116 logs 0
[2] cast run tail Traces: [2607] deposit(…, 5) → [Revert] NotActive(1) | Gas used: 24179
```

[3] 同じブロックで前の取引（withdrawAll）がアカウントの預け入れの欄を空にすると、預け入れは初めて書く欄が増え、見積もりよりガスが多くかかる。余裕0・20・50%はOutOfGasで失敗し、100%だけが通る。前の取引が待ち行列にあるときに`pending`で見積もると117,002が出る。

```
[3] estimate deposit 5 at latest 68502
[3] margin 0% after mine ['wdall nonce 1 done block 12 gasUsed 54010 …', 'dep3 nonce 2 failed block 12 gasUsed 68502 …'] position 0
[3] cast run tail Traces: [46930] deposit(…, 5) → [OutOfGas] EvmError: OutOfGas | Gas used: 68502
[3] margin 20% after mine [… 'dep3 nonce 2 failed block 12 gasUsed 82202 …'] position 0
[3] margin 50% after mine [… 'dep3 nonce 2 failed block 12 gasUsed 102522 …'] position 0
[3] margin 100% after mine [… 'dep3 nonce 2 done block 12 gasUsed 117002 …'] position 5
[3] withdrawAll in pool; estimate deposit 5 at latest 68502 pending 0x1c90a
[3] after withdrawAll mined: estimate deposit 5 119802 market token balance 0
```

[4b] ベースフィーが2倍に上がると、同じバイトを送り直しても受け付けない。`bump()`で同じナンスに150%上げて署名し直すと入り、日誌にはハッシュが二つ残る。最初のハッシュのレシートはない。出力は元の実行結果の文字列だけを訳したもの。そこに出るベースフィーは元の実行のデプロイが使ったガスで決まるので、このフォルダのコードで実行し直すとベースフィー、maxFee、bumpの手数料、ハッシュが変わることがある。

```
[4b] base fee 269834968 send maxFee 296818464 ['pay nonce 1 gas 51411 sent -> 0xaf37792e'] pool {'pending': '0x1', 'queued': '0x0'}
[4b] mined (12, 0) base 539669936 pool {'pending': '0x0', 'queued': '0x0'} byHash None
[4b] next round ['pay nonce 1 resend same raw -> max fee per gas less than block base fee']
[4b] pay nonce 1 bump 150% fee 742046160 tip 2 -> 0x3797adc7f93175de1a2ddad22f7f4c62cb0f24669f00142fc0e5fe16677d884f
[4b] mined (13, 1)
[4b] after mine ['pay nonce 1 done block 13 gasUsed 51411 by 0x3797adc7 (hashes 2)'] first hash receipt None
```

[5]・[6] 待ち行列から取引が消えると（`anvil_dropTransaction`）、同じバイトを送り直す。入ったブロックが再編成で入れ替わってレシートが消えると、`sent`に戻して同じバイトを送り直し、確定の深さ3が過ぎると`done`である。

```
[5] next round ['pay5 nonce 2 resend same raw -> 0x617b96b0e068683b98b659942f70f61b2e011c7e1597dd767847e03eb2705521']
[5] after mine ['pay5 nonce 2 mined block 15 gasUsed 34311 by 0x617b96b0 (hashes 1)']
[6] reorg depth 1, receipt None
[6] next round ['pay5 nonce 2 receipt gone (block 15 replaced)', 'pay5 nonce 2 resend same raw -> 0x617b96b0e068683b98b659942f70f61b2e011c7e1597dd767847e03eb2705521']
[6] after mine ['pay5 nonce 2 mined block 16 gasUsed 34311 by 0x617b96b0 (hashes 1)']
[6] after 3 more ['pay5 nonce 2 done block 16 gasUsed 34311 by 0x617b96b0 (hashes 1)']
```

[7] 取引一つのガス上限をオンにしたosakaのほう。`fill(1000)`は見積もりは出るが、送ると上限を超えるとして拒否される。`fill(700)`は上限の下である。

```
[7] estimate fill(1000) 22346629 None
[7] cast send 1 Error: server returned an error response: error code -32000: intrinsic gas too high -- tx.gas_limit > resolved tx gas limit cap
[7] estimate fill(700) 15655729
```

`cast run`のトレースは行をつなげ、ツリーの記号を外した。繰り返しの行は`…`で縮めた。

### 試すときの注意

- ガスの見積もりは、指定したブロックの状態で一度実行してみた値である。実際に入るときに前の取引が状態を変えると、結果もガスも変わる。
- 見積もりは、実行にかかるガスだけを数える。ノードがその取引を受け付けるかどうか（取引一つのガス上限のようなルール）は見ない。
- ベースフィーは、前のブロックのガス使用量で決まる。Marketのバージョンが変わってガスが変わると、[4b]の手数料の数字も一緒に変わる。
- 取引のハッシュは実行するたびに違うことがある。同じバイトを送り直すと同じハッシュである（[5]・[6]）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（anvil・cast・forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| gethの置き換えのルールのデフォルト値 | `--txpool.pricebump value (default: 10)` | 2026-10-16 |
| anvilの置き換えの幅 | 同じ手数料は拒否、5%上げると受け付ける | 2026-10-21 |
| osakaの取引一つのガス上限 | 16,777,216（EIP-7825） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 失敗した取引の数と無駄になった手数料を指標で見ること | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| キューが止まったときのアラートと対応の手順 | [第241講](../../part18/lecture241/)、[第242講](../../part18/lecture242/) |
| 公開のメンプールを通らない送信の運用（バンドル・非公開の送信） | データの行 |

出典と参考資料は[reference.md](reference.md)にまとめた。
