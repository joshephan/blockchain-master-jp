# 第80講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| anvilの既定のハードフォーク | latest（Bpo1） | `cast rpc anvil_nodeInfo` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力とガスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| selfdestructの動作の変更 | EIP-6780、solcの警告5159の原文 | 2026-10-19 |
| selfdestructの非推奨の警告の導入バージョン | Solidityの変更履歴（直接実行で確かめた値ではない） | 2026-10-19 |
| `type(I).interfaceId` | Solidity公式ドキュメントType Information、変更履歴 | 2026-10-19 |
| Marketのバイト長 | 直接実行、`cast call info()` | 2026-10-19 |
| トレースのガス、gasUsed | 直接実行、`forge test -vvvv`、`cast send` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variablesの節のContract-related（`this`、`selfdestruct`）とType Information（`name`、`creationCode`、`runtimeCode`、`interfaceId`、`min`、`max`）: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
- 同じドキュメントのrst原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- Solidity公式ドキュメント v0.8.36 Solidity by Example、Micropayment Channel（selfdestructの代わりに`freeze()`で閉じるバージョン）
- Solidityの変更履歴 v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- EIP-6780 (SELFDESTRUCT only in same transaction): https://eips.ethereum.org/EIPS/eip-6780
- EIP-165 (Standard Interface Detection): https://eips.ethereum.org/EIPS/eip-165
- Foundry公式ドキュメント（`anvil --hardfork`、`cast run`、`cast compute-address`）: https://getfoundry.sh/
