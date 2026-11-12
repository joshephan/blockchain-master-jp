# 第131講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| evm_version | solcをそのまま呼ぶとprague、forgeのビルドはosaka | 直接実行 | 2026-10-20 |
| 実測の条件 | Windows 11、ソースの改行はLF | | 2026-10-20 |

付録のAST・バイト・命令の数は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのバージョン | argotorg/solidityのタグv0.8.36 `docs/internals/source_mappings.rst` 39〜41行目、`docs/metadata.rst` 220〜222行目 | 2026-10-20 |
| forgeのbuild-info | `forge build --build-info`の成果物 | 2026-10-20 |
| StoreのAST・バイト | solc 0.8.30 `--ast-compact-json`、`--stop-after parsing`、`--asm`、`--bin`、`--bin-runtime`、`--hashes`、`cast disassemble` | 2026-10-20 |
| MarketのAST・バイト | build-infoのAST、forgeの成果物、`--show-standard-json-input`で取り出した入力をsolcに入れ直した結果、`cast sig` | 2026-10-20 |
| Market 第131講のバージョンの末尾 | `forge inspect --offline src/Market.sol:Market deployedBytecode` | 2026-10-20 |
| 完全一致・部分一致の呼び名 | `docs.sourcify.dev/docs/exact-match-vs-match`、etherscan.ioの検証済みのコントラクトの画面 | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Source Mappings（`docs/internals/source_mappings.rst`）: https://docs.soliditylang.org/en/v0.8.36/internals/source_mappings.html
  - 39〜41行目: ASTの`src`は`s:l:f`（開始のバイト、長さ、ソースファイルの番号）
- Solidity公式ドキュメント v0.8.36、Contract MetadataのEncoding of the Metadata Hash in the Bytecode（`docs/metadata.rst`）: https://docs.soliditylang.org/en/v0.8.36/metadata.html
  - 220〜222行目: バイトコードの最後の2バイトがCBORの情報の長さ
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/source_mappings.rst, https://github.com/argotorg/solidity/blob/v0.8.36/docs/metadata.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
