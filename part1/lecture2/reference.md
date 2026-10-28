# 第2講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Node.js | v24.11.0 | `node -v` | 2026-10-16 |

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ビットコインの毎秒の処理件数 | api.blockchain.info/stats（24時間のトランザクション数） | 2026-10-20 |
| イーサリアムの毎秒の処理件数 | 公開RPC（ethereum-rpc.publicnode.com）`eth_getBlockByNumber`、直近24時間のブロック300個の標本 | 2026-10-20 |
| ビットコインのノード数 | bitnodes.io API `snapshots/latest`（04:35 UTC） | 2026-10-20 |
| イーサリアムのノード数 | etherscan.io/nodetracker（直近24時間に検出） | 2026-10-20 |
| 取引所ごとの入金反映の基準ブロック数 | Bithumbの入出金状況ページ（bithumb.com/react/info/inout-condition）、Binance `getNetworkCoinAll`のminConfirm、CoinbaseのヘルプConfirmationsとapi.exchange.coinbase.com/currencies | 2026-10-20 |
| イーサリアムのフルノードの推奨ディスク容量 | ethereum.org/developers/docs/nodes-and-clients/run-a-node（2026-07-13更新）、EIP-7870 | 2026-10-20 |

## 参考資料

- EIP-7870（ノードのハードウェア推奨仕様）: https://eips.ethereum.org/EIPS/eip-7870
- 2017年8月のビットコインキャッシュの分裂（ブロックサイズ論争の末に分かれていったチェーン）
- 2017年12月のクリプトキティーズの混雑（ゲーム一つでイーサリアムのネットワーク全体が詰まった出来事）
