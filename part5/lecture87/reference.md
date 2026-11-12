# 第87講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| C99のスコープ規則と導入バージョン | Solidity公式ドキュメント v0.8.36 Scoping and Declarationsの節 | 2026-10-19 |
| エラー・警告の番号 | solc 0.8.30を直接実行した出力 | 2026-10-19 |
| gasUsed | `cast send`を直接実行した出力 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control StructuresのScoping and Declarationsの節（C99の規則、`for`の初期化の例外、関数の外の宣言は宣言の前でも見える、初期値はバイトがすべて0の値、`null`・`undefined`はない）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント: https://getfoundry.sh/
