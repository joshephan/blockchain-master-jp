# 第10講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Node.js | v24.11.0 | `node --version` | 2026-10-17 |

付録の実行結果は、上の環境で実際に実行した出力である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 現在のブロック高 | mempool.space API `blocks/tip/height` | 2026-10-20 |
| 次の半減期の予想時期 | mempool.space API `difficulty-adjustment`（timeAvg） | 2026-10-20 |
| 全体のハッシュレート | mempool.space API `mining/hashrate/3d` | 2026-10-20 |
| マイニング電力消費の推定値 | ccaf.io/cbnsi/cbeci（ケンブリッジ・ビットコイン電力消費指数）、digiconomist.net | 2026-10-20 |
| マイニングプールのシェア | mempool.space API `mining/pools/1w` | 2026-10-20 |

## 参考資料

- Satoshi Nakamoto, "Bitcoin: A Peer-to-Peer Electronic Cash System"（2008）、11節 Calculations（攻撃者成功確率の式と表）: https://bitcoin.org/bitcoin.pdf
- Cynthia Dwork, Moni Naor, "Pricing via Processing or Combatting Junk Mail"（1992）。迷惑メールを防ぐために計算コストを課そうという提案
- Adam Back, Hashcash（1997）
- 51%攻撃の事例：ビットコインゴールド（2018年5月）、イーサリアムクラシック（2019年1月、2020年8月）
