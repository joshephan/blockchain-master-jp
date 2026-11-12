# 第53講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のコンパイルエラー、欄の配置、呼び出しの結果は、すべて上の環境とローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのFixed Point Numbers | docs.soliditylang.org、v0.8.36 | 2026-10-19 |
| Node.jsの`0.1 + 0.2` | `node -p`（第2講と同じ確認） | 2026-10-19 |
| ufixed128x18のサイズ | `forge inspect FixedDecl storageLayout` | 2026-10-19 |
| 固定小数点の代入・戻り値のエラー | solc 0.8.30で直接実行した出力 | 2026-10-19 |
| トークンの桁数の例 | 各トークンコントラクトの`decimals()` | 2026-10-19 |
| Depositのput()のgasUsed | anvilでの`cast send`のレシート | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のFixed Point Numbers: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント（`cast to-wei`、`cast to-unit`、`cast to-dec`）: https://getfoundry.sh/
