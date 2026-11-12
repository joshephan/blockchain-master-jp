# 第57講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のテストの出力、コンパイルエラー、欄の内容は、すべて上の環境とローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのFixed-size byte arrays | docs.soliditylang.org、v0.8.36 | 2026-10-19 |
| 初めて書くsetのgasUsed | anvilでの`cast send`のレシート | 2026-10-19 |
| テストのガス | `forge test -vv` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のFixed-size byte arrays: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント（`cast parse-bytes32-string`、`cast keccak`、`cast to-dec`、`cast to-hex`）: https://getfoundry.sh/
