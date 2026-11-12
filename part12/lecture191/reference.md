# 第191講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果と行数は、上の環境で直接実行した結果である（anvilなし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| テストの数、CIの結果、ランタイムのサイズ | `forge test --offline`、CIのスクリプト（直接実行） | 2026-10-21 |
| 行数 | 空行・コメント行を除いた行の数え上げ、`wc -l`（直接実行） | 2026-10-21 |
| Code4renaの段階、参加 | https://docs.code4rena.com/competitions | 2026-10-21 |
| Code4renaの等級 | https://docs.code4rena.com/competitions/severity-categorization | 2026-10-21 |
| Code4renaの提出 | https://docs.code4rena.com/competitions/submission-guidelines | 2026-10-21 |
| Code4renaの判定 | https://docs.code4rena.com/competitions/judging-criteria | 2026-10-21 |
| Code4renaの報酬 | Code4renaのドキュメントのawardingの側 | 2026-10-21 |
| Sherlockのドキュメントの構成 | https://docs.sherlock.xyz | 2026-10-21 |
| Sherlockの旧判定 | https://docs.sherlock.xyz/audit-contests-deprecated-replaced-by-audit-engine/judging | 2026-10-21 |
| Sherlockの旧基準 | 上のjudgingの下のguidelinesのドキュメント | 2026-10-21 |
| Sherlock Audit Engine | https://docs.sherlock.xyz/audit-engine/judging | 2026-10-21 |
| Sherlockへの参加 | https://docs.sherlock.xyz/audit-engine/for-participants | 2026-10-21 |
| バウンティのアドレス | Solidityリポジトリの`SECURITY.md` 49行 | 2026-10-20 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidityリポジトリの`SECURITY.md`（27行 報告の案内、49行 バウンティのアドレス）: https://github.com/argotorg/solidity/blob/v0.8.36/SECURITY.md
- Ethereum bounty program: bounty.ethereum.org
- EIP-20トークン標準（模擬READMEの使うトークンの欄）: https://eips.ethereum.org/EIPS/eip-20
- Code4renaの公開ドキュメント（competitions、severity-categorization、submission-guidelines、judging-criteria）
- Sherlockの公開ドキュメント（旧コンテストのjudging・guidelines、Audit Engineのjudging・for-participants）
