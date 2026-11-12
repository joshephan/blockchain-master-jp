# 第30講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `forge --version` | 2026-10-18 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-18 |
| メインネット照会用のノード | `https://ethereum-rpc.publicnode.com` | 直接照会 | 2026-10-18 |
| キャッシュファイルの展開 | Node.js 24のzstdサポート | 直接実行 | 2026-10-18 |

付録の出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 固定したフォークのブロック | anvilのFork出力、`cast block` | 2026-10-18 |
| WETHのtotalSupply | forgeのテストログ、`cast call --block` | 2026-10-18 |
| ブロック番号なしの実行 | `forge test -vv` | 2026-10-18 |
| anvilのフォークでのdeposit | `cast send`、`cast call` | 2026-10-18 |
| 同じ時刻の公開ノード | `cast call` | 2026-10-18 |
| ブロック番号26216890の比較 | `eth_getBlockByNumber` | 2026-10-18 |
| フォークのブロック番号の停止 | `cast block-number` | 2026-10-18 |
| キャッシュファイル | `~/.foundry/cache/rpc/mainnet/26216889` | 2026-10-18 |
| 公開ノードの過去の状態への応答 | 公開ノードに直接照会 | 2026-10-18 |
| キャッシュの効果 | `forge test`の要約行 | 2026-10-18 |
| anvilのフォークでの照会時間 | 直接実行 | 2026-10-18 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-stdリポジトリ: https://github.com/foundry-rs/forge-std（`vm.createSelectFork`、`makeAddr`）
- WETH（Wrapped Ether）コントラクト: メインネット`0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`
