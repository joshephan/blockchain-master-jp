# 第85講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| via_ir、evm_versionの既定値 | false、osaka | `forge config` | 2026-10-19 |

付録の出力とガスの値は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 測定結果 | 直接実行、`cast call`、`forge test` | 2026-10-19 |
| gasUsed | 直接実行、`cast send` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control Structuresの節のOrder of Evaluation of Expressions（式の評価の順番は決められておらず、文の順番とブール値の短絡評価だけが保証される）: https://docs.soliditylang.org/en/v0.8.36/control-structures.html
  - rst原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/control-structures.rst
- Solidity公式ドキュメント v0.8.36、Solidity IR-based Codegen Changes（既定のコード生成は式の評価の順番が未規定、IRコード生成はソースの順番を試みるが保証しない、関数の引数は`addmod`・`mulmod`だけが例外）: https://docs.soliditylang.org/en/v0.8.36/ir-breaking-changes.html
  - rst原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/ir-breaking-changes.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
