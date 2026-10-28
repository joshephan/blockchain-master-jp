# 第17講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil、cast） | 1.8.3 | `anvil --version` | 2026-10-17 |

付録の出力は、上の環境のローカルのテストチェーンで実際に実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ブロックガスリミット | 公開RPC（ethereum-rpc.publicnode.com）`eth_getBlockByNumber`、直近24時間のブロック300個の標本、EIP-7935 | 2026-10-20 |
| ブロックのガスの目標値 | EIP-1559の規則（リミットの半分） | 2026-10-20 |
| ブロックあたりの単純な送金の数 | 上の値 ÷ 21,000 | 2026-10-20 |
| 最近のベースフィーの範囲 | 公開RPC（publicnode）`eth_feeHistory`、etherscan.io/chart/gasprice | 2026-10-20 |

## 参考資料

- EIP-1559（ベースフィーと優先手数料、2021年8月5日 ロンドンアップグレード）: https://eips.ethereum.org/EIPS/eip-1559
- EIP-4844（blobの手数料）: https://eips.ethereum.org/EIPS/eip-4844
- EIP-7935（ブロックガスリミットの既定値60M）: https://eips.ethereum.org/EIPS/eip-7935
- クリプトキティーズの混雑（2017年12月）
- Foundry公式ドキュメント: https://getfoundry.sh/
