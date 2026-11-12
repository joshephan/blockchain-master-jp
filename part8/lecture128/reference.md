# 第128講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-20 |
| Foundry（forge・cast） | 1.8.3 | `forge --version` | 2026-10-20 |
| evm_versionの既定値 | solcのコマンドラインはprague、forgeはosaka | `solc --help`、`forge config` | 2026-10-20 |

付録のサイズ・keccak・エラーの文言は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのバージョン | argotorg/solidityのタグv0.8.36 `docs/using-the-compiler.rst`（88、185、203、424〜425行目） | 2026-10-20 |
| solcのオプション・既定値 | `solc --version`、`solc --help` | 2026-10-20 |
| Foundryの既定値 | `forge config` | 2026-10-20 |
| forgeのbuild-infoの形式 | `forge build --build-info`が作った`out/build-info/*.json` | 2026-10-20 |
| `forge verify-contract` | `forge verify-contract --help` | 2026-10-20 |
| エラーの文言、Storeの値 | solc 0.8.30の直接実行、`cast keccak`、`cast create2` | 2026-10-20 |
| Marketの値 | `forge build --sizes`、`forge test`、solcのStandard JSONの出力 | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Using the Compiler（`docs/using-the-compiler.rst`）: https://docs.soliditylang.org/en/v0.8.36/using-the-compiler.html
  - Using the Commandline Compiler、Setting the EVM Version to Target（osakaが既定値、amsterdamは実験的）、Compiler Input and Output JSON Description
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/using-the-compiler.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
