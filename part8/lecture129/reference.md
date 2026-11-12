# 第129講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | `solc --version` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3、`auto_detect_remappings = true`が既定 | `forge config` | 2026-10-20 |
| OS | Windows 11、大文字と小文字を区別しないファイルシステム | Case.solの実行 | 2026-10-20 |

付録のkeccak・エラーの文言・アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのバージョン | argotorg/solidityのタグv0.8.36 `docs/path-resolution.rst`、`docs/using-the-compiler.rst` | 2026-10-20 |
| パスの切り詰めの注記 | `path-resolution.rst` 409行目 | 2026-10-20 |
| Storeのkeccak、絶対パスの名前 | solc 0.8.30 `--bin`、`--metadata`の直接実行 | 2026-10-20 |
| A.sol | solc 0.8.30でビルド、anvilにデプロイして`cast call` | 2026-10-20 |
| Marketのコピー4組、Market 第129講のバージョン | `forge remappings`、`forge build --sizes`、`forge test`、build-info | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Import Path Resolution（`docs/path-resolution.rst`）: https://docs.soliditylang.org/en/v0.8.36/path-resolution.html
  - Virtual Filesystem、Import Callback、Imports、Relative Imports、Base Path and Include Paths、CLI Path Normalization and Stripping、Allowed Paths、Import Remapping
  - 409行目 "Prior to version 0.8.8, CLI path stripping was not performed"
- Solidity公式ドキュメント v0.8.36、Using the CompilerのBase Path and Import Remapping（`docs/using-the-compiler.rst`）: https://docs.soliditylang.org/en/v0.8.36/using-the-compiler.html
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/path-resolution.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
