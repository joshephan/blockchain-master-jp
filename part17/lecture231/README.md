# 第231講 DAレイヤー分離の論争

第17部 スケーラビリティ・第62章 トリレンマとデータ可用性

[← 第230講](../../part17/lecture230/) | [第17部 目次](../) | [第232講 →](../../part17/lecture232/)

## この講義の問い

データ可用性は何を問うのか。チェーンにハッシュを載せることと、データを差し出すことはどう違うのか。データをイーサリアムの外に置くと何が安くなり、その代わりに誰を信じることになるのか。

## 実習資料

### 準備

Foundryプロジェクトなしで、コントラクト一つ（`Inbox231`）をsolc 0.8.30で直接コンパイルする（`solc --optimize --bin --abi`、警告なし）。anvilを`--hardfork osaka`で立ち上げ、アカウント2番を委員会として与えてデプロイする（331,019ガス）。バッチのデータ三つを、三種類の記録で載せる。

| 記録 | 載せたデータ | データを持っている側 |
|---|---|---|
| `postBlob()`にblobを載せる | `blob1.txt`（1,000バイト） | blobとしてネットワークに差し出す |
| `postAttested(h, v, r, s)` | "rollup batch 2: bob->carol 4 (given to committee only)"のハッシュ | 委員会だけが受け取る |
| `postHash(h)` | sha256("rollup batch 3: carol->dave 9 (never published)") | 誰も受け取れない |

委員会の署名は`cast wallet sign --private-key <アカウント2番のテスト用の鍵> <ハッシュ>`（EIP-191の前置き）で作り、コントラクトが同じ前置きで`ecrecover`する。アカウントはすべてanvilのデフォルトのテスト用アカウントで、外部のチェーンには接続しない。

### コード

| ファイル | 内容 |
|---|---|
| [code/src/Inbox231.sol](code/src/Inbox231.sol) | バッチの記録箱：`postBlob`（最初のblobのversioned hash、なければ`NoBlob`）、`postAttested`（委員会の署名を確認、違えば`NotCommittee(signer)`）、`postHash`（ハッシュだけ）、`batches`、`count` |
| [code/blob1.txt](code/blob1.txt) | blobに載せた1,000バイトの文字 |

### 実行結果

三つの記録を送る：

```
postBlob() （blobなし）
  → Failed to estimate gas: execution reverted: custom error 0xeb2c7b8e, …: NoBlob
postBlob() --blob --path blob1.txt
  → gasUsed 88,245, blobGasUsed 131,072
postAttested(h, v, r, s)   委員会の鍵で署名
  → gasUsed 76,422
postAttested(h, v, r, s)   アカウント3番の鍵で署名
  → Failed to estimate gas: execution reverted: custom error 0x2700fdd3: 0000…90f79bf6…b906
postHash(sha256("rollup batch 3: carol->dave 9 (never published)"))
  → gasUsed 71,744
```

0x2700fdd3は`NotCommittee`のセレクターで、後ろの32バイトが署名したアドレス（アカウント3番 0x90F7…b906）である。リバートした二つの取引はcastのガス見積もりで引っかかってチェーンには載らず、残りの三つの取引はstatus 1である。

| batches(i) | dataHash | 種類 / ブロック番号 |
|---|---|---|
| 0 | 0x01b3b340…2a2a | Blob / 2 |
| 1 | 0x2989b734…1507 | Attested / 3 |
| 2 | 0x8dab8f25…ad7f | HashOnly / 4 |

`count()`は3である。三つとも、チェーンには32バイトのハッシュ一つと種類・ブロック番号だけが残る。ノードにデータを求めると（anvil専用のRPC）：

```
anvil_getBlobByHash(batches(0)のハッシュ) → 131,072バイト
anvil_getBlobByHash(batches(1)のハッシュ) → null
anvil_getBlobByHash(batches(2)のハッシュ) → null
```

blob一つに付くセル証明（第230講の実習で`cast mktx --blob`が作った署名済みの取引をRLPでほどいて数えた）：

```
cast mktx --blob （デフォルトの形） → wrapper_version 1、blob 1、コミットメント1、セル証明128個（それぞれ48バイト）
cast mktx --blob --eip4844 → blob 1、コミットメント1、証明1個
```

セル証明128 × 48バイト = 6,144バイトである。拡張したblobのセルが128個（`CELLS_PER_EXT_BLOB`）で、送るblobはその半分である。

### 試すときの注意

- 三つの記録のガスを、確かめる量で比べない。`postBlob`が最初の記録なので、記録箱の長さの欄を0から初めて書く値が88,245に入っている。
- ハッシュは、どのデータなのかを決めるだけである。そのデータを誰が受け取って見られるのかは、ハッシュは教えてくれない。委員会の署名も、委員会の鍵がそのハッシュに署名したという事実までしか証明しない。
- `anvil_getBlobByHash`は、ローカルのノードが持っているコピーを返すanvil専用のRPCである。実際のネットワークではblobは決まった保管期間が過ぎると消されるので、期間内に受け取っておくのはデータが必要な側の仕事である。
- 拡張したセルの半分があれば元のデータが復元できるので、データを隠すには半分より多くを隠さなければならない。

## 時効性のあるデータ

基準日時点の値。名前だけを書いた行には、数値・シェア・価格を載せない。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（anvil・cast） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30+commit.73712a01 | 2026-10-21 |
| EIP-7594（PeerDAS） | Final、Fusaka（EIP-7607）のメインネット 2025-12-03 21:49:11 UTC | 2026-10-21 |
| データだけを受け持つネットワーク（例） | Celestia、Avail、EigenDA（名前のみ） | 2026-10-21 |
| L2の分類の公開サイト | L2BEAT。データの場所によってロールアップ、validiumなどに分けて呼ぶ分類（名前のみ） | 2026-10-21 |
| blobの保管 | `MIN_EPOCHS_FOR_BLOB_SIDECARS_REQUESTS` 4096エポック（約18日、エポック32スロット × 12秒と仮定） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| データを持って状態が間違っていることを争う手順 | [第232講](../../part17/lecture232/) |
| 運営者が止まったときに自分のお金を引き出す道 | [第233講](../../part17/lecture233/) |
| 受け取っておいたデータでイベント・状態を組み立て直すこと | [第238講](../../part18/lecture238/) |
| DAネットワークごとのバリデーター・署名の構造 | 付録 |
| データの場所によって信じる相手が変わることの全体のまとめ | [第237講](../../part18/lecture237/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
