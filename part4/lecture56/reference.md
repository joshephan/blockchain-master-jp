# 第56講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のコンパイルエラー、欄の配置、トレースは、すべて上の環境とローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 高水準の呼び出しのコード存在確認 | 公式ドキュメントv0.8.36 Control Structures、External Function CallsのNote・Warning | 2026-10-19 |
| 低水準の呼び出しと存在しないアカウント | 公式ドキュメントv0.8.36 Error handlingの節のWarning | 2026-10-19 |
| ランタイムのサイズ | `forge test -vvvv`のデプロイのトレース | 2026-10-19 |
| Pool.payのガス | anvilのレシート、`cast run` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36: https://docs.soliditylang.org/en/v0.8.36/
  - Typesの節のContract Types
  - Control Structuresの節のExternal Function Calls（0.8.10から、戻り値を受け取る呼び出しのextcodesize確認を省略）
  - Control Structuresの節のError handling（低水準のcall・delegatecall・staticcallは存在しないアカウントにもtrue）
- Foundry公式ドキュメント（`cast rpc`、`cast sig`、`cast code`）: https://getfoundry.sh/
