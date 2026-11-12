# 第227講 バンドルの構成とFlashbotsへの送信

第16部 MEVサーチャー実習・第61章 攻撃者の道具

[← 第226講](../../part16/lecture226/) | [第16部 目次](../) | [第228講 →](../../part16/lecture228/)

## この講義の問い

公開の待合室の外で順番を決める道は、どんな形をしているのか。ユーザーがその道で自分の取引を送ると、何が見えなくなり、その代わりに誰を信じることになるのか。

## 時効性のあるデータ

基準日に閲覧した公開文書の値。文書が改訂されると変わることがある。この講義は外部のエンドポイント（リレー、Protect、テストネット）に何も送らず、文書だけを読んだ。

| 項目 | 値 | 基準日 |
|---|---|---|
| Flashbotsの文書の概要 | docs.flashbots.net/flashbots-auction/overview | 2026-10-21 |
| Understanding Bundles | docs.flashbots.net/flashbots-auction/advanced/understanding-bundles | 2026-10-21 |
| JSON-RPC Endpoints | docs.flashbots.net/flashbots-auction/advanced/rpc-endpoint | 2026-10-21 |
| MEV Protection Overview | docs.flashbots.net/flashbots-protect/overview | 2026-10-21 |
| バンドルのリレーのアドレス | メインネット `https://relay.flashbots.net`、Sepolia `https://relay-sepolia.flashbots.net` | 2026-10-21 |
| リクエスト・バンドルの上限 | IPあたり毎秒10,000リクエスト、バンドル一つに取引100個・300,000バイト | 2026-10-21 |
| `eth_sendPrivateTransaction`の試行期間 | 次の25ブロック | 2026-10-21 |
| Protectのエンドポイント | `rpc.flashbots.net/fast`（`eth_sendRawTransaction`） | 2026-10-21 |
| eth_sendBundleの欄 | txs、blockNumber、minTimestamp、maxTimestamp、revertingTxHashes、replacementUuid、builders | 2026-10-21 |
| 順番を決める側にもブロックの前には見せない設計 | overview 55行目のロードマップ "Complete Privacy" | 2026-10-21 |
| 第225講のfeesのほうの値 | 13番ブロック、アカウント1番の交換 status 0・ガス47,273・手数料56,982,293,309,376 wei | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 自分の取引が見えていて順番は他人が決めるとき、ユーザーとプロトコルが引く線 | [第228講](../../part16/lecture228/) |
| 公開のメンプールがないL2の順番 | [第233講](../../part17/lecture233/) |
| 順番を決める側にもブロックの前には見せない設計（overview 55行目のロードマップ "Complete Privacy"） | 時効性のあるデータ |

出典と参考資料は[reference.md](reference.md)にまとめた。
