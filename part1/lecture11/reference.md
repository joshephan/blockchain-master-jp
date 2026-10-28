# 第11講 出典

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ビットコインの手数料水準 | mempool.space `/api/v1/fees/recommended` | 2026-10-20 |
| 取引所ごとの入金確定ブロック数 | Bithumbの入出金状況ページ（bithumb.com/react/info/inout-condition）、Binance `getNetworkCoinAll`のminConfirm、CoinbaseのヘルプConfirmationsとapi.exchange.coinbase.com/currencies | 2026-10-20 |
| ノードソフトウェアの置き換えの既定動作 | bitcoin/bitcoinリポジトリ `doc/release-notes` 28.0、29.0、30.0 | 2026-10-20 |

## 参考資料

- BIP-125（手数料を上げて送り直す置き換え、RBF、2015）: https://github.com/bitcoin/bips/blob/master/bip-0125.mediawiki
- マウントゴックス（Mt. Gox）のトランザクション展性の主張（2014年2月）：出金トラブルの原因として、署名の内容を変えずにトランザクションIDを変えられる問題を挙げた
- セグウィット（SegWit）の有効化（2017年8月）：トランザクション展性の問題を防いだ
