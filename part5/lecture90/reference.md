# 第90講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| solc（比較用） | 0.7.6 | `old/foundry.toml` `solc = "0.7.6"` | 2026-10-19 |

付録の出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| カスタムエラー、`require`の中のカスタムエラーの導入バージョン | Solidityの変更履歴（0.8.4、0.8.26、0.8.27の項目） | 2026-10-19 |
| 0.8.0より前の`assert`の動作 | Solidity 0.8.0の変更点、0.7.6・0.8.30のビルドを直接実行 | 2026-10-19 |
| セレクタ | `cast sig`、castの出力 | 2026-10-19 |
| Panicのコード | Solidity公式ドキュメント v0.8.36 Panic via assert and Error via requireの節 | 2026-10-19 |
| gasUsed、手数料 | ローカルのanvilで`cast send`、`cast balance`、`cast nonce`を直接実行 | 2026-10-19 |
| テストのガス | `forge test`を直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control StructuresのError handling: Assert, Require, Revert and Exceptionsの節（Panic via assert and Error via require、revert）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidityの変更履歴 v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント: https://getfoundry.sh/
