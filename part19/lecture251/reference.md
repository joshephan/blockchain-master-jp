# 第251講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil・cast） | 1.8.3 (cae51ad4) | `anvil --version`、`cast --version` | 2026-10-21 |
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-21 |
| anvil | ブロック間隔1秒（`anvil_setBlockTimestampInterval 1`）、0番アカウントunlocked | 起動オプション | 2026-10-21 |

付録のバイト数、ガス、呼び出し結果は、すべて上の環境で直接実行した結果である。Huffのコンパイラは使っておらず、Huffのソースは下のドキュメントで読んだ。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| huff-docsの状態 | github.com/huff-language/huff-docs | 2026-10-21 |
| huff-rsの状態 | github.com/huff-language/huff-rs | 2026-10-21 |
| huff-neoのバージョン | github.com/cakevm/huff-neo | 2026-10-21 |
| 四つのバージョンの値、ドキュメントのバージョンの三つの動作、subの二つのバージョン | 直接実行（anvilに`cast send --create`、`cast call`、`cast estimate`、`cast codesize`） | 2026-10-21 |
| Solidityのバージョンのメタデータの尾 | 直接実行（`solc --bin-runtime`） | 2026-10-21 |
| SSTOREの0から値へ | ガスの章でトレースで測った値 | 2026-10-21 |

## 参考資料

- huff-docs（アーカイブされたリポジトリ）: https://github.com/huff-language/huff-docs
  - `get-started/overview.md`
  - `tutorial/simple-storage.md`（SimpleStorageのソース、スタックのコメント）
  - `get-started/huff-by-example.md`（Jump Labels：ラベルはジャンプする場所にすぎず、止めなければ下の命令が続けて実行される、デフォルトのCONSTRUCTORとbootstrapコード）
- huff-rs（アーカイブ済み、"deprecated and no longer maintained"）: https://github.com/huff-language/huff-rs
- huff-neo（huff-rsのハードフォーク）: https://github.com/cakevm/huff-neo
- Solidity公式ドキュメント v0.8.36（Yul、インラインアセンブリ）: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント（`cast disassemble`、`cast sig`）: https://getfoundry.sh/
