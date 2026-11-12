# 第31講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast） | 1.8.3 | `forge --version` | 2026-10-18 |
| solc | 0.8.30 | `forge build`の出力 | 2026-10-18 |
| ファズ・不変条件のデフォルト設定 | fuzz runs 256、invariant runs 256 / depth 500、shrink_run_limit 5000 | `forge config`の[fuzz]、[invariant]節 | 2026-10-18 |

付録の出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| デフォルトのfuzz runs、ファズ入力の候補の設定 | `forge config`の[fuzz]節 | 2026-10-18 |
| デフォルトのinvariant runs / depth、shrink_run_limit | `forge config`の[invariant]節、直したトークンの実行出力`calls: 128000` | 2026-10-18 |
| 実行時間、反例の値と呼び出しの順序 | 直接実行 | 2026-10-18 |
| 20261018のkeccak256 | `cast keccak` | 固定 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-stdリポジトリ: https://github.com/foundry-rs/forge-std（`bound`、`vm.assume`、`targetContract`）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
