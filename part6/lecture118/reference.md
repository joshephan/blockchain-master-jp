# 第118講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン。比較用のバージョンはoptimizerを入れる（runs 200）、via-IR | foundry.toml | 2026-10-19 |
| anvil | 既定の設定、既定のアカウント0番・1番 | 直接実行 | 2026-10-19 |

付録のビルドエラーの原文、サイズ、バイトの比較、呼び出しの結果、ガスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `using for`の継承の規則 | Solidity Changelog.md v0.7.0: "Reference Resolver: `using A for B` only affects the contract it is mentioned in and not all derived contracts" | 2026-10-19 |
| ファイルレベルの`using`・`global` | Solidity Changelog.md v0.8.13: "`using M for Type;` is allowed at file level and `M` can now also be a brace-enclosed list of free functions or library functions."、"`using ... for T global;` is allowed at file level where the user-defined type `T` has been defined, resulting in the effect of the statement being available everywhere `T` is available." | 2026-10-19 |
| 演算子の定義 | Solidity Changelog.md v0.8.19: "Allow defining custom operators for user-defined value types via `using {f as +} for T global` syntax."、"TypeChecker: Also allow external library functions in `using for`." | 2026-10-19 |
| Fee・Shelf・Till・Marketのサイズ | 直接実行（三つの設定で`forge build --sizes`、`forge inspect … deployedBytecode`） | 2026-10-19 |
| ガス | 直接実行（`cast estimate`、`cast send --json`、バージョンごとに新しいanvil） | 2026-10-19 |
| テスト | 直接実行（`forge test`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Using Forの節: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/using-for.rst
  - "The directive `using A for B` can be used to attach functions (`A`) as operators to user-defined value types or as member functions to any type (`B`)."
  - "The member functions receive the object they are called on as their first parameter"
  - "If you define an operator … the type (`T`) must be a user-defined value type and the definition must be a `pure` function. Operator definitions must be global."
  - "unary and binary `-` need separate definitions"
  - "The `using A for B;` directive is active only within the current scope (either the contract or the current module/source unit) … and has no effect outside of the contract or module in which it is used."
  - "When the directive is used at file level and applied to a user-defined type which was defined at file level in the same file, the word `global` can be added at the end."
- Solidity Changelog（v0.7.0、v0.8.13、v0.8.19）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント（`forge build --sizes`、`cast disassemble`、`cast estimate`）: https://getfoundry.sh/
