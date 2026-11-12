# 第167講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30。p167はevm osaka・optimizer既定値（オフ）、Marketはvia-IRオン・optimizerオン（runs 200） | 各`foundry.toml` | 2026-10-20 |
| fuzz | runs 256、seed 0x2a | `code/p167/foundry.toml` | 2026-10-20 |

付録のガス、カバレッジ、ファズの結果は、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| lintの警告 | 直接実行（`forge build --offline --force`） | 2026-10-20 |
| Airdropのカバレッジ | 直接実行（`forge coverage --match-contract AirdropTest --report summary`） | 2026-10-20 |
| テストのガス、ファズのμ | 直接実行（`forge test`、`--fuzz-runs 10000`、`FOUNDRY_FUZZ_SEED`） | 2026-10-20 |
| Marketのカバレッジと実行されなかった行 | 直接実行（`forge coverage --report summary`、`--report lcov`） | 2026-10-20 |
| 二つの環境変数、coverageの前のビルド | 直接実行（環境変数の有無、ビルドの有無を変えて比較） | 2026-10-20 |

## 参考資料

- Foundry公式ドキュメント（forge testのファジング、forge coverage）: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
