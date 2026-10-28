# 第13講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil、cast） | 1.8.3 | `cast --version` | 2026-10-17 |

付録のステートルート、証明ノード、ハッシュ値は、上の環境のローカルのテストチェーンで実際に実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 全体のアカウント数 | etherscan.io/chart/address | 2026-10-20 |
| ブロックあたりに変わる状態の値の数 | 公開RPC（eth.drpc.org）`debug_traceBlockByNumber` prestateTracer（diffMode）、ブロック7個の標本 | 2026-10-20 |
| SSTORE、ADDのガスコスト | evm.codes（fork=osaka）、EIP-2200、EIP-2929 | 2026-10-20 |
| 現在の状態の大きさ | etherscan.io/chartsync/chaindefault、chainarchive | 2026-10-20 |
| ツリー置き換え研究の現状 | EIPリポジトリ（github.com/ethereum/EIPs） | 2026-10-20 |
| ノード数 | bitnodes.io API `snapshots/latest`（04:35 UTC）、etherscan.io/nodetracker | 2026-10-20 |

## 参考資料

- Donald R. Morrison, "PATRICIA: Practical Algorithm To Retrieve Information Coded in Alphanumeric"（1968）
- マークル・パトリシア・トライ（MPT）：イーサリアムの状態ツリー、ストレージツリー、トランザクションツリー、レシートツリーの構造
- EIP-2200: https://eips.ethereum.org/EIPS/eip-2200
- EIP-2929: https://eips.ethereum.org/EIPS/eip-2929
- EIP-6800（バークルツリー）: https://eips.ethereum.org/EIPS/eip-6800
- EIP-7864（バイナリツリー）: https://eips.ethereum.org/EIPS/eip-7864
- Foundry公式ドキュメント: https://getfoundry.sh/
