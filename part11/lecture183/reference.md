# 第183講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30+commit.73712a01.Windows.msvc | `solc --version` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts` | 2026-10-21 |
| forgeのファズ・不変条件の既定値 | fuzz runs 256 / invariant runs 256、depth 500、workers auto、fail_on_revert false、shrink_run_limit 5000 | `forge config` | 2026-10-21 |

付録の反例、呼び出しの数、実行時間、カバレッジは、すべて上の環境で直接実行した結果である。anvilは使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ファズ・不変条件の結果と反例 | 直接実行（スイートを一つずつ、seed 0x2a、ワーカー一つ、保存された失敗を消す） | 2026-10-21 |
| 反例が揺れた値 | 同じ設定で別の写しで回し直した結果と比較 | 2026-10-21 |
| 実行時間 | 直接実行したPCの値 | 2026-10-21 |
| カバレッジ | 直接実行（`forge coverage --report summary`） | 2026-10-21 |
| SMTソルバー | インストールの有無を直接確認 | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0 `token/ERC20/extensions/ERC4626.sol`（金庫Vaultが継承）
- Foundry公式ドキュメント（ファズテスト、不変条件のテスト、ハンドラ、`targetContract`、`cache/invariant/failures`、`forge coverage`）: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36（チェック付き算術とPanic 0x11、assertのPanic 0x01）: https://docs.soliditylang.org/en/v0.8.36/
