# 第37講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"`、コンパイル出力 | 2026-10-19 |
| ローカルチェーン | anvil、デフォルトアカウント0〜4を使用 | `anvil` | 2026-10-19 |

付録のガス、欄の番号、出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 例の原文 | Solidity公式ドキュメント v0.8.36、Solidity by ExampleのVotingの節 | 2026-10-19 |
| delegateのガス | `forge test --match-contract DelegateGas -vv`、gasleft()の差 | 2026-10-19 |
| anvilでの実演のgasUsed | `cast send`のレシート | 2026-10-19 |
| テストのガス | `forge test`の出力 | 2026-10-19 |
| Panicのコード0x32 | 直接実行の出力 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Solidity by Example（Voting）: https://docs.soliditylang.org/en/v0.8.36/solidity-by-example.html
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント: https://getfoundry.sh/
