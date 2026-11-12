# 第27講 anvil：ローカルチェーンの運用と状態の操作

第2部 開発とテスト環境・第7章 ローカルチェーンとテスト

[← 第26講](../../part2/lecture26/) | [第2部 目次](../) | [第28講 →](../../part2/lecture28/)

## この講義の問い

自分のコンピュータにチェーンを一つ立ち上げると、本物のチェーンと何が同じで、何を自分の思いどおりに変えられるのか。

## 実習資料

### 準備

Foundry（anvil、cast、forge）だけを使う。外部への接続はない。Counterをsolc 0.8.30でビルドして（`forge build --use 0.8.30 --offline`）ローカルのanvilにデプロイし、その上でanvil専用のRPCコマンドを使ってブロック、残高、ストレージ、時刻、状態を変えてみる。署名には、anvilが起動するときに表示するデフォルトアカウントのテスト用の鍵を使う。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | `forge init`の基本設定 |
| [code/src/Counter.sol](code/src/Counter.sol) | increment、decrementを持つCounter |

### 実行結果

anvilを2回起動して、起動出力のPrivate Keysの部分を比べると同じである。デフォルトアカウントは10個、アカウントごとに10,000 ETH、チェーンIDは31337である。新しく立ち上げたチェーンの`cast block-number`は0である。

`forge create`でCounterをデプロイするとブロック1ができ（`Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3`）、`increment()`を送るとブロック2ができる。トランザクションがなくてもブロックを作れる：

```
cast rpc evm_mine          → "0x0"   (ブロック番号 3)
cast rpc anvil_mine 0x5    → null    (ブロック番号 8)
```

`--block-time 12`で起動すると、12秒ごとにブロックができる。ブロック1〜3のtimestampは1792295831、1792295843、1792295855だった。

空のアドレス`0x000000000000000000000000000000000000bEEF`の残高を`anvil_setBalance`で500 ETHに変え（ブロック番号は8のまま）、Counterの0番のストレージの欄を`anvil_setStorageAt`で0x2aに変えると、`count()`が42になる。鍵のないそのアドレスで`cast send --unlocked`を実行すると拒否され、`anvil_impersonateAccount`のあとは通る：

```
error code -32602: No Signer available
...
blockNumber 9, from 0x000000000000000000000000000000000000bEEF, status 1
count() → 43
```

時刻の操作（`cast block latest -f timestamp`で確認）：

```
ブロック 9                                          1792295724
evm_increaseTime 86400 + evm_mine → ブロック 10     1792382130
evm_setNextBlockTimestamp 1900000000 → ブロック 11  1900000000
```

1900000000は2030年3月17日17:46:40 UTCである。

スナップショットと巻き戻し。countが43、ブロック番号が11の状態で`evm_snapshot`（`"0x0"`）を取り、incrementを3回行うとcountは46、ブロックは14になる。`evm_revert 0x0`は`true`を返し、countは43、ブロックは11に戻る。同じスナップショットでもう一度巻き戻すと`false`である。

`--dump-state state.json --state-interval 1`で起動したチェーンにデプロイし、countを42にしてから終了すると、state.json（15,829バイト）が残る。`--load-state state.json`で2回起動し、次のブロックの時刻を1900000000に固定して同じincrementを送ると、2回とも同じ値が出る：

```
blockHash        0x26e2e6525e62311d4d7c3894d329b67be62c0ef51509ed6963dc1fb5585bd347
transactionHash  0x47b45e1155bbe28950e048fb85676dc579208917dcdecce4526066079d6f9584
```

時刻を固定しないと、ブロックハッシュは毎回違う（0x61b29b09...6336aと0x82413912...72f8b、timestampは1792295772と1792295774）。

`--no-mining`で起動し、三つのアカウントが`--async`でincrement（2 gwei）、decrement（10 gwei）、increment（3 gwei）を送ると、ブロック番号は1、countは42のままで、待機列に三つがたまる。一つを`anvil_dropTransaction`で外して`evm_mine`を実行すると：

```
txpool_status                 {"pending":"0x3","queued":"0x0"}
anvil_dropTransaction 後      {"pending":"0x2","queued":"0x0"}
evm_mine 後 block-number      2
increment(2 gwei) 順序        1
decrement(10 gwei) 順序       0
count()                       42
外したtx cast tx              Error: tx not found
```

ガス価格の高いdecrementが先に入り、incrementと相殺されてcountは42である。

### 試すときの注意

- Windowsでanvilを`kill`で終了すると、終了時の状態保存は保証されない。`--dump-state`と一緒に`--state-interval 1`を指定する。
- `--priority-gas-price 5gwei`で送ると`max priority fee per gas (5000000000) cannot exceed max fee per gas (2000000001)`で拒否される。順番の比較は`--gas-price`で行う。
- `--no-mining`の状態では、`cast receipt`はブロックに入るまで待つ。`evm_mine`のあとに実行する。
- anvilのデフォルトのニーモニックとテスト用の鍵は誰でも知っている値である。ローカルチェーンでだけ使う。

## 時効性のあるデータ

基準日時点の値。Foundryのバージョンが変わると、デフォルト値が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundryのバージョン | anvil・cast・forge 1.8.3 (cae51ad458 2026-09-15) | 2026-10-18 |
| solc | 0.8.30（`forge build --use 0.8.30 --offline`） | 2026-10-18 |
| anvilのデフォルトアカウント数 / アカウントあたりのテスト残高 | 10個 / 10,000 ETH | 2026-10-18 |
| anvilのデフォルトのチェーンID / Base Fee / Gas Limit | 31337 / 1000000000 wei（1 gwei） / 30000000 | 2026-10-18 |
| anvilのデフォルトのニーモニック | test test test test test test test test test test test junk | 2026-10-18 |
| ブロックのtimestampの例 | 1792295724（9番）、1792382130（10番）、1900000000（11番） | 2026-10-18 |
| state.jsonのサイズ | 15,829バイト | 2026-10-18 |
| 同じ状態で2回実行したときのブロックハッシュ | `0x26e2e652...5bd347`（時刻固定） | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 確認をコードで書くテスト | [第28講](../../part2/lecture28/) |
| テストの中で時刻・残高・呼び出し元を変える（cheatcode） | [第29講](../../part2/lecture29/) |
| メインネットの状態を持ってきて立ち上げるフォーク | [第30講](../../part2/lecture30/) |
| ガススナップショット | [第33講](../../part2/lecture33/) |
| ストレージの欄の番号が決まる規則 | [第135講](../../part8/lecture135/) |
| この部屋にない四つ目、敵対性 | [第167講](../../part11/lecture167/)・第11部 |
| ブロック提案者の順番の選択から生じる利益 | [第172講](../../part11/lecture172/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
