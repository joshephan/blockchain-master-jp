# 第193講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | `escrow/foundry.toml`の`solc = "0.8.30"` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果とガスは、上の環境で直接実行した結果である（anvilなし、提出なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| テストのガス（escrow、contest） | `forge test --offline --match-contract Escrow51Test`・`Contest51Test`（直接実行） | 2026-10-21 |
| Code4renaの提出ルール | https://docs.code4rena.com/competitions/submission-guidelines | 2026-10-21 |
| Code4renaの判定 | https://docs.code4rena.com/competitions/judging-criteria | 2026-10-21 |
| Code4renaの等級 | https://docs.code4rena.com/competitions/severity-categorization | 2026-10-21 |
| Code4renaの報酬 | https://docs.code4rena.com/awarding | 2026-10-21 |
| Sherlockの判定基準（旧コンテスト） | https://docs.sherlock.xyz/audit-contests-deprecated-replaced-by-audit-engine/judging/guidelines | 2026-10-21 |
| Sherlockの旧コンテストの判定の段階 | https://docs.sherlock.xyz/audit-contests-deprecated-replaced-by-audit-engine/judging | 2026-10-21 |
| Sherlock Audit Engineへの参加 | https://docs.sherlock.xyz/audit-engine/for-participants | 2026-10-21 |
| Sherlockのドキュメントの構成 | https://docs.sherlock.xyz | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidityリポジトリのバグ報告の様式（Environmentの欄の名前：Compiler version、Compilation pipeline、Target EVM version、Framework）
- Solidityリポジトリの`SECURITY.md`（デプロイされたコードで新たに見つけたものの報告経路）: https://github.com/argotorg/solidity/blob/v0.8.36/SECURITY.md
- EIP-20トークン標準（READMEの使うトークンの欄）: https://eips.ethereum.org/EIPS/eip-20
