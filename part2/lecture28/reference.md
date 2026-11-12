# 第28講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-18 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-18 |
| デフォルトのfuzz runs | 256 | `forge test`の出力の`runs: 256`（foundry.tomlにfuzz設定なし） | 2026-10-18 |
| シェル | Git Bash（Windows） | 直接実行 | 2026-10-18 |

付録のガスの数字と出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Foundryのバージョン | `forge --version` | 2026-10-18 |
| デフォルトのfuzz runs | `forge test`の出力 | 2026-10-18 |
| solc | foundry.toml | 2026-10-18 |
| ガス・デプロイサイズ | 直接実行 | 2026-10-18 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-stdリポジトリ: https://github.com/foundry-rs/forge-std（`Test`、`stdError.arithmeticError`）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
