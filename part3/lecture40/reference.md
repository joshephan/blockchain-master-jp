# 第40講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-19 |
| ローカルチェーン | anvil `--base-fee 0 --gas-price 0 --no-priority-fee`、デフォルトアカウント0・1・2番 | 直接実行 | 2026-10-19 |

付録のハッシュ、署名、ガス、アドレスは、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 例の原文、終了方式、pragma | Solidity公式ドキュメント v0.8.36、Solidity by ExampleのMicropayment Channelの節 | 2026-10-19 |
| 署名の前置きの規則 | EIP-191、ドキュメントの`prefixed`関数、`cast wallet sign --help` | 2026-10-19 |
| cast wallet signのデフォルトの動作 | `cast wallet sign --help` | 2026-10-19 |
| ガスの実測、ブロック時刻 | ローカルのanvilのレシート、直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Solidity by Example（Micropayment Channel）: https://docs.soliditylang.org/en/v0.8.36/solidity-by-example.html
- EIP-191 署名データの規格: https://eips.ethereum.org/EIPS/eip-191
- Foundry公式ドキュメント: https://getfoundry.sh/
