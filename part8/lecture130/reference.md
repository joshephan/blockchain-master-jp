# 第130講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version`、メタデータのcompilerの欄 | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| evm_version | solcをそのまま呼ぶとprague、forgeのビルドはosaka | 直接実行 | 2026-10-20 |

付録のkeccak・バイトの比較・アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのバージョン | argotorg/solidityのタグv0.8.36 `docs/metadata.rst`・`using-the-compiler.rst`・`installing-solidity.rst` | 2026-10-20 |
| forgeの検証のコマンド | Foundry 1.8.3 `forge verify-contract --help`、`forge verify-bytecode --help` | 2026-10-20 |
| 外部の検証サービス | `docs.sourcify.dev/docs/exact-match-vs-match`、`docs.sourcify.dev/docs/api`、etherscan.ioの検証済みのコントラクトの画面、`docs.etherscan.io` | 2026-10-20 |
| Storeの11行 | solc 0.8.30 `--bin`、`cast keccak` | 2026-10-20 |
| メタデータのハッシュ | `solc --metadata`の出力を自分でハッシュ（CIDv0、UnixFSのファイル一つ、sha256）、`cast keccak` | 2026-10-20 |
| Marketの入力を2回 | `solc --standard-json`を同じ入力で2回 | 2026-10-20 |
| anvilでのデプロイ、Marketの突き合わせ | anvilにデプロイしてから`cast code`、`cast tx`、成果物の`immutableReferences`とバイトの比較 | 2026-10-20 |
| Market 第130講のバージョン | `forge build --sizes`、`forge test` | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Contract Metadata（`docs/metadata.rst`）: https://docs.soliditylang.org/en/v0.8.36/metadata.html
  - Encoding of the Metadata Hash in the Bytecode、Usage for Source Code Verification。Sourcify（https://sourcify.dev）の"full/perfect verification"
- Solidity公式ドキュメント v0.8.36、Using the CompilerのLibrary Linking、Metadata Options（`docs/using-the-compiler.rst`）: https://docs.soliditylang.org/en/v0.8.36/using-the-compiler.html
- Solidity公式ドキュメント v0.8.36、Installing the Solidity CompilerのStatic Binaries（`docs/installing-solidity.rst`）: https://docs.soliditylang.org/en/v0.8.36/installing-solidity.html
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/metadata.rst
- Sourcify: https://sourcify.dev
- Foundry公式ドキュメント: https://getfoundry.sh/
