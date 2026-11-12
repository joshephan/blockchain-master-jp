# 第26講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（cast、anvil、forge） | 1.8.3 | `forge --version` | 2026-10-18 |
| solc | 0.8.30 | `forge build --use 0.8.30` | 2026-10-18 |
| メインネット照会用のノード | `https://ethereum-rpc.publicnode.com` | 直接照会 | 2026-10-18 |

付録の出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 最新のブロック番号 | `curl`でのeth_blockNumber、`cast block-number` | 2026-10-18 |
| WETHのナンス、コードサイズ、残高 | `cast nonce`、`cast codesize`、`cast balance` | 2026-10-18 |
| WETHのcodeHash、storageHash、accountProof | `cast proof` | 2026-10-18 |
| ブロック26216648 | `cast block` | 2026-10-18 |
| 送金トランザクション | `cast tx`、`cast receipt` | 2026-10-18 |
| ブロックごとのWETHの残高 | `cast balance --block` | 2026-10-18 |
| 公開ノードの過去の状態の応答範囲 | 公開ノードに直接照会 | 2026-10-18 |
| WETHのtotalSupply | `cast call`、`cast balance` | 2026-10-18 |
| anvilでの実行値 | ローカルのテストチェーンのレシート | 2026-10-18 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- WETH（Wrapped Ether）コントラクト: メインネット`0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`
- イーサリアムJSON-RPC: `eth_blockNumber`、`eth_call`
