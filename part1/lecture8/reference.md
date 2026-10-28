# 第8講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Node.js | v24.11.0 | `node --version` | 2026-10-17 |

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ビットコインの手数料の水準 | mempool.space `/api/v1/fees/recommended` | 2026-10-20 |
| ビットコインのブロックあたりのトランザクション数 | api.blockchain.info/stats | 2026-10-20 |
| 下の三つの記録の入力・出力 | mempool.space API | 2026-10-17 |

## 参考資料

ビットコインの初期の記録（値が変わらない固定の記録）：

| 記録 | 内容 | トランザクションID |
|---|---|---|
| ジェネシスブロックのコインベース（2009-01-03） | 入力1個（コインベース）、出力50 BTC 1個、入力欄の文言 "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks" | 4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b |
| サトシ → ハル・フィニーの最初の送金 | ブロック170、2009-01-12 03:30:25 UTC、入力50 BTC 1個、出力10 BTC + 40 BTC、手数料0 | f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16 |
| ラースロー・ハニエツのピザ1万BTC | ブロック57043、2010-05-22 18:16:31 UTC、入力131個（0.01 BTCのもの111個 + 大きな金額20個）合計10,000.99 BTC、出力10,000 BTC 1個、手数料0.99 BTC | a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d |

- Satoshi Nakamoto, "Bitcoin: A Peer-to-Peer Electronic Cash System"（2008）: https://bitcoin.org/bitcoin.pdf
