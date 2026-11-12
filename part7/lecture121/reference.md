# 第121講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る、既定のcodegen | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| Deepのビルド設定 | `via_ir = true`、`optimizer = false` | foundry.toml | 2026-10-19 |

付録の出力・エラーの原文は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `memory-safe`の表示の導入 | solc Changelog.md（v0.8.36タグ）0.8.13（2022-03-16）"Allow annotating inline assembly as memory-safe…" | 2026-10-19 |
| コメントの形の非推奨 | solc Changelog.md 0.8.31（2025-12-03）、公式ドキュメント v0.8.36 Memory Safety、0.8.30での直接のビルド | 2026-10-19 |
| アカウント0番・1番 | anvilの既定のアカウント | 2026-10-19 |
| Market 第121講のバージョン | `forge build --sizes`、`forge test` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Inline Assembly（`docs/assembly.rst`）: https://docs.soliditylang.org/en/v0.8.36/assembly.html
  - Conventions in SolidityのMemory Management: 0x00〜0x3fはscratch、0x40〜0x5fはフリーメモリポインタ、0x60〜0x7fはゼロの欄、0x80から割り当て。"There is no built-in mechanism to release or free allocated memory."
  - Values of Typed Variables: 短い型の上位ビットは、メモリに書く直前や比較の直前に必要なときだけ消す
  - Memory Safety: 安全なメモリの範囲四つ（自分で割り当てたメモリ、Solidityが割り当てたメモリ、0〜64のscratch、ブロックの開始時にフリーメモリポインタのうしろにある一時メモリ）、メモリに触らないブロックは表示がなくてもmemory-safeとみなす、"It is your responsibility to make sure that the assembly actually satisfies the memory model."、コメントの形は"deprecated and scheduled for removal"
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/assembly.rst
- Solidity Changelog: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント: https://getfoundry.sh/
