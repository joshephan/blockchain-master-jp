# 第89講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvilのブロックガスリミット | 30,000,000 | `cast block latest --field gasLimit` | 2026-10-19 |

付録の出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `for`ループの増加の検査を省くバージョン | Solidity 0.8.22の変更履歴、0.8.30での直接測定 | 2026-10-19 |
| gas report、snapshot | `forge test --match-contract GasTest --gas-report --offline`、`forge snapshot --match-contract GasTest --offline`を直接実行 | 2026-10-19 |
| uint8のカウンタ n=300 | `cast send`を直接実行した出力 | 2026-10-19 |
| 前の講義の測定値（uncheckedのCounterの201ガスの差、uint8のカウンタで196ガス多い） | 第35講・第51講での直接測定 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control StructuresのChecked or Unchecked Arithmeticの節（uncheckedはブロックの代わりに使えず入れ子にもできない、文法上ブロックの中に書かれた文にだけ適用、呼んだ関数には引き継がれない、ゼロ除算・剰余の検査は切れない）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidityの変更履歴 v0.8.36（0.8.22の項目）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント: https://getfoundry.sh/
