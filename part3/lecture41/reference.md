# 第41講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerオフ（デフォルト） | foundry.tomlの`solc = "0.8.30"` | 2026-10-19 |
| ローカルチェーン | anvil、デフォルトアカウント0番 | 直接実行 | 2026-10-19 |

付録のサイズ、ガス、出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 例の原文 | Solidity公式ドキュメント v0.8.36、Solidity by ExampleのModular Contractsの節 | 2026-10-19 |
| ランタイムコードのサイズの上限 | EIP-170、`forge build --sizes`のRuntime Margin | 2026-10-19 |
| ランタイムのサイズ | `forge build --sizes`、成果物のJSON | 2026-10-19 |
| デプロイ・transfer・sendのガス | anvilのレシートのgasUsed | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Solidity by Example（Modular Contracts）: https://docs.soliditylang.org/en/v0.8.36/
- EIP-170 コントラクトのコードサイズの上限: https://eips.ethereum.org/EIPS/eip-170
- Foundry公式ドキュメント: https://getfoundry.sh/
