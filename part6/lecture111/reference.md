# 第111講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | 既定の設定、既定のアカウント0番 | 直接実行 | 2026-10-19 |

付録のビルドエラーの原文、ガス、サイズは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `virtual`/`override`の導入 | Solidity Changelog.md v0.6.0: "Introduce `virtual` and `override` keywords."、"Allow public variables to override external functions."、"`private` cannot be used together with `virtual`." | 2026-10-19 |
| 状態変更可能性を狭める | Solidity Changelog.md v0.7.0: "Allow overrides to have stricter state mutability: `view` can override `nonpayable` and `pure` can override `view`." | 2026-10-19 |
| インターフェースの関数での`override`の省略 | Solidity Changelog.md v0.8.8: "A function that overrides only a single interface function does not require the `override` specifier." | 2026-10-19 |
| modifierのオーバーライドの表示 | Solidity公式ドキュメント v0.8.36 Inheritanceの節 Modifier Overriding（"`virtual` modifiers are deprecated and scheduled for removal."）、直接ビルド | 2026-10-19 |
| bumpByのgasUsed、サイズ | 直接実行（`cast send`、`cast code`、`forge build --sizes`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Inheritanceの節（Function Overriding、Modifier Overriding）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/inheritance.rst
  - "The overriding function may only change the visibility of the overridden function from `external` to `public`."
  - "`nonpayable` can be overridden by `view` and `pure`."、"`view` can be overridden by `pure`."
  - "`payable` is an exception and cannot be changed to any other mutability."
  - "Functions with the `private` visibility cannot be `virtual`."
  - "Public state variables can override external functions"
- Solidity Changelog（v0.6.0、v0.7.0、v0.8.8）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント: https://getfoundry.sh/
