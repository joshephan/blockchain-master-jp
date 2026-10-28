# 第7講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（cast） | 1.8.3 | `cast --version` | 2026-10-16 |

付録のハッシュ値は、上の環境で`cast keccak`を実際に実行した出力である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| イーサリアムのフルノードの推奨ディスク容量 | ethereum.org/developers/docs/nodes-and-clients/run-a-node（2026-07-13更新）、EIP-7870 | 2026-10-20 |
| シンクコミッティーの規模と交代周期 | ethereum/consensus-specs `presets/mainnet/altair.yaml` | 2026-10-20 |
| ビットコインのブロックあたりのトランザクション数 | api.blockchain.info/stats | 2026-10-20 |
| イーサリアムのブロックあたりのトランザクション数 | 公開RPC（publicnode）のブロック標本 | 2026-10-20 |

## 参考資料

- Satoshi Nakamoto, "Bitcoin: A Peer-to-Peer Electronic Cash System"（2008）、8節 Simplified Payment Verification: https://bitcoin.org/bitcoin.pdf
- ラルフ・マークル（Ralph Merkle）のハッシュツリーの特許（1979）
- イーサリアムのアルテア（Altair）アップグレード（2021年10月）：シンクコミッティー512人を導入
- EIP-7870（ノードのハードウェア推奨仕様）: https://eips.ethereum.org/EIPS/eip-7870
- Foundry公式ドキュメント: https://getfoundry.sh/
