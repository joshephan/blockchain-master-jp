# 第86講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力とガスの値は、すべて上の環境で直接実行した結果である。比較用のビルドは`--optimize`、`--via-ir`、`--via-ir --optimize`のフラグで作った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 0に戻す書き込みの払い戻し | EIP-3529 | 2026-10-19 |
| トレースのガス、PureThreeの呼び出しのガス | 直接実行、`forge test --offline -vvvv` | 2026-10-19 |
| gasUsed | 直接実行、anvilで`cast send` | 2026-10-19 |
| 数の違うタプルの代入の規則 | 公式ドキュメントDestructuringの節の注記（0.5.0より前は短いほうを埋める代入になり、0.5.0からは両側の数が同じでなければならない）。直接実行で確かめたものではない | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control Structuresの節のAssignment（Destructuring Assignments and Returning Multiple Values、Complications for Arrays and Structs）、Order of Evaluation of Expressions: https://docs.soliditylang.org/en/v0.8.36/
- EIP-3529（Reduction in refunds、Londonアップグレード）: https://eips.ethereum.org/EIPS/eip-3529
- Foundry公式ドキュメント: https://getfoundry.sh/
