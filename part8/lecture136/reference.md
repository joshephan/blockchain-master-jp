# 第136講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| EVMのバージョン | デモ・通しプロジェクトはosaka、solcを直接呼ぶ場合の既定値はprague | foundry.toml、`forge config` | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| デモのガスと結果 | anvil（`--steps-tracing`）にコントラクトごとに新しくデプロイ、レシートのgasUsed、ログ、`cast call`、`cast storage`、`debug_traceTransaction`のgasCost | 2026-10-20 |
| shanghai / cancunの比較 | anvil `--hardfork shanghai`、`--hardfork cancun`に同じバイトコードをデプロイ | 2026-10-20 |
| エラー・警告の原文 | `solc --bin`、`solc --evm-version shanghai --bin`、`solc --abi`の直接実行。警告番号2394は`solc --standard-json`のerrorCode | 2026-10-20 |
| forgeの警告の設定 | `forge config`の`ignored_error_codes` | 2026-10-20 |
| transientに対応したバージョン | Solidity Changelog、ドキュメントv0.8.36 Transient Storageの節 | 2026-10-20 |
| Cancunの日付 | イーサリアムのアップグレードの記録 | 2026-10-20 |
| Marketのトレース | 第136講のバージョンをanvilにデプロイして、`debug_traceTransaction`でSSTORE・TLOAD・TSTOREを数える、`solc --transient-storage-layout src/Market.sol` | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Transient Storage（Composability of Smart Contracts and the Caveats of Transient Storageを含む）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/transient-storage.rst
- Solidity公式ドキュメント v0.8.36、Layout of State Variables in Storage and Transient Storage: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/layout_in_storage.rst
- EIP-1153, Transient storage opcodes: https://eips.ethereum.org/EIPS/eip-1153
- EIP-2929、EIP-2200、EIP-3529（SLOAD・SSTOREのガスと払い戻し）: https://eips.ethereum.org/EIPS/eip-2929, https://eips.ethereum.org/EIPS/eip-2200, https://eips.ethereum.org/EIPS/eip-3529
- Cancun（Dencun）アップグレード、イーサリアムメインネット2024-03-13
- Foundry公式ドキュメント（`forge config`、anvil `--hardfork`）: https://getfoundry.sh/
