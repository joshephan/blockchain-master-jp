# 第112講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | 既定の設定、バージョンごとに新しく立ち上げる | 直接実行 | 2026-10-19 |

付録の線形化の順番、スロット、ビルドエラーの原文、サイズ、ガスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 線形化の順番のフィールド | 直接ビルド（`forge build --ast`） | 2026-10-19 |
| サイズ | 直接実行（`forge build --sizes`） | 2026-10-19 |
| ガス | 直接実行（`forge create --json`、`cast send --json`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Inheritanceの節: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/inheritance.rst
  - Multiple Inheritance and Linearization: "You have to list the direct base contracts in the order from “most base-like” to “most derived”. Note that this order is the reverse of the one used in Python."、例`contract C is A, X {}`に"Linearization of inheritance graph impossible"
  - Function Overriding: "For multiple inheritance, the most derived base contracts that define the same function must be specified explicitly after the `override` keyword."
  - Inheriting Different Kinds of Members of the Same Name：同じ名前の定義が複数許される場合は、関数のオーバーロード、virtual関数のオーバーライド、状態変数のゲッターによるexternal virtual関数のオーバーライド、virtualのmodifierのオーバーライド、イベントのオーバーロード
- C3線形化（C3 linearization）：公式ドキュメントが"Solidity is similar to Python in that it uses C3 Linearization"と紹介
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント（`forge build --ast`、`forge inspect`、`cast sig`）: https://getfoundry.sh/
