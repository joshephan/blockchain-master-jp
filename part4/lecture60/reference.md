# 第60講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値）。サイズの比較だけoptimizerオン（200 runs） | foundry.toml `solc = "0.8.30"`、`--optimize --optimizer-runs 200` | 2026-10-19 |

付録のコンパイルエラー、欄の配置、ガス、サイズは、すべて上の環境とローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| type(E).min・max、ユーザー定義の値型の導入バージョン | docs.soliditylang.org v0.8.36 types.htmlのEnums・User-defined Value Typesの例のpragma（`^0.8.8`） | 2026-10-19 |
| 演算子定義の導入バージョン | docs.soliditylang.org v0.8.36 contracts.htmlのUsing Forの演算子の例のpragma（`^0.8.19`）、0.8.30でのローカルビルド | 2026-10-19 |
| 列挙型の名前の個数の上限 | ドキュメントの"Enums cannot have more than 256 members."、solc 0.8.30で直接実行した出力 | 2026-10-19 |
| StateBoxの欄 | `forge inspect storageLayout` | 2026-10-19 |
| poke(7)・PlainBox・PriceBoxのgasUsed | anvilでの`cast send`のレシート | 2026-10-19 |
| ガス見積もり | `cast estimate` | 2026-10-19 |
| デプロイのサイズ | `forge build --sizes` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36: https://docs.soliditylang.org/en/v0.8.36/
  - Typesの節のEnums、User-defined Value Types: https://docs.soliditylang.org/en/v0.8.36/types.html
  - Contractsの節のUsing For（ユーザー定義の演算子）: https://docs.soliditylang.org/en/v0.8.36/contracts.html
- Foundry公式ドキュメント: https://getfoundry.sh/
