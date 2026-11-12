# 第91講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version`、`cast --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| try/catch、`catch Panic`節、コードのないアドレスの検査の導入バージョン | Solidityの変更履歴（0.6.0、0.8.1、0.8.10の項目）。コードのないアドレスの動作はsolc 0.8.30のトレースで直接確認 | 2026-10-19 |
| 64分の63の規則 | EIP-150 | 2026-10-19 |
| セレクタ | `cast sig`、テストの出力 | 2026-10-19 |
| トレースのガス | `cast run`、`cast receipt`を直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control StructuresのError handlingの節とtry/catch
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidityの変更履歴 v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- EIP-150（呼び出しに渡すガスを残りのガスの64分の63に制限）: https://eips.ethereum.org/EIPS/eip-150
- Foundry公式ドキュメント: https://getfoundry.sh/
