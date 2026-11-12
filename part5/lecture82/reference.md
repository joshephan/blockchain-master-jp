# 第82講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のコード生成 | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力とガスの値は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 再帰のdepthの最大 | 直接実行、`cast call`でnを二分探索 | 2026-10-19 |
| トレースのガス | 直接実行、`forge test -vvvv` | 2026-10-19 |
| gasUsed | 直接実行、`cast send` | 2026-10-19 |
| 内部関数の値 | 直接実行、`cast call ptr()`と`debug_traceCall`の構造ログ | 2026-10-19 |
| スタックの深さの上限1024個 | EVMの規則（イーサリアムのイエローペーパー） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control Structuresの節のFunction Calls（Internal Function Calls、Function Calls with Named Parameters）: https://docs.soliditylang.org/en/v0.8.36/
- イーサリアムのイエローペーパー: https://ethereum.github.io/yellowpaper/paper.pdf
- Foundry公式ドキュメント: https://getfoundry.sh/
