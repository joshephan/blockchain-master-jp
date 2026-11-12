# 第192講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | 二つのプロジェクトのfoundry.tomlの`solc = "0.8.30"` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

行数、デプロイのアドレスと値、テスト結果とガスは、すべて上の環境で直接実行した結果である（ローカルのanvil、外部への接続は公開ドキュメントの閲覧だけ）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 行数 | 空行・コメント行を除いた行の数え上げ（直接実行） | 2026-10-21 |
| デプロイのアドレス、デプロイの値 | ローカルのanvilで`forge create`、`cast call`、`cast storage`、`cast tx`（直接実行） | 2026-10-21 |
| テストのガス | `forge test --offline --match-contract Contest51Test`・`Escrow51Test`（直接実行） | 2026-10-21 |
| Sherlockの判定基準 | https://docs.sherlock.xyz/audit-contests-deprecated-replaced-by-audit-engine/judging/guidelines | 2026-10-21 |
| Code4renaの深刻度の分類 | https://docs.code4rena.com/competitions/severity-categorization | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- EIP-20トークン標準（READMEの使うトークンの欄）: https://eips.ethereum.org/EIPS/eip-20
- Sherlockの旧コンテストの判定基準のドキュメント、Code4renaの深刻度の分類のドキュメント（上のデータの出典のアドレス）
