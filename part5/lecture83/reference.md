# 第83講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forgeのテストの既定のガスリミット | 1,073,741,824 | `forge config`の出力のgas_limit | 2026-10-19 |

付録の出力とガスの値は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| コードの存在確認の規則 | Solidity 0.8.10の変更履歴。直接実行では、0.8.30で戻り値のある呼び出しがStopのあとリバートするトレースまで確認 | 2026-10-19 |
| 呼び出しオプションの文法 | Solidity 0.6.2・0.7.0の変更履歴、Error 1621の原文 | 2026-10-19 |
| 64分の63の規則 | EIP-150 | 2026-10-19 |
| イーサを載せた呼び出しのガス2300 | 直接実行、`forge test -vvvv` | 2026-10-19 |
| MarketのinterfaceId、コードの長さ | 直接実行、`forge test --match-test test_interfaceId`、`--match-contract TypesTest` | 2026-10-19 |
| トレースのガス | 直接実行、`cast run`、`forge test -vvvv`、`cast receipt` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control Structuresの節のExternal Function Calls（呼び出しオプション`{value: ..., gas: ...}`、コードの存在確認）: https://docs.soliditylang.org/en/v0.8.36/
- Solidity公式ドキュメント v0.8.36、Solidity by ExampleのSafe Remote Purchase（状態を先に変えてから送金する順番、"It is important to change the state first"）
- Solidityの変更履歴 v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- EIP-150（2016年10月のTangerine Whistle、呼び出すときに残りのガスの64分の1を残す）: https://eips.ethereum.org/EIPS/eip-150
- Foundry公式ドキュメント: https://getfoundry.sh/
