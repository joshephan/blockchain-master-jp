# 第126講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| evm_version | solcをそのまま呼ぶとprague、forge 1.8.3はosaka | 直接実行 | 2026-10-19 |
| anvilのハードフォーク | Bpo1 | anvil | 2026-10-19 |
| node | v24.11.0 | `node --version` | 2026-10-19 |
| Python | 3.12.10 | `python --version` | 2026-10-19 |

付録のエラーの原文・値・ログは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントの原文 | argotorg/solidityのタグv0.8.36 `docs/…`（ethereum/solidityリポジトリがargotorgに移った）、比較用にv0.8.30・v0.7.6の`cheatsheet.rst` | 2026-10-19 |
| チートシートのバージョンの違い | `diff`の直接実行 | 2026-10-19 |
| エラー・警告の番号 | solc 0.8.30 `--error-codes --bin`の直接実行 | 2026-10-19 |
| ハードフォークとEIP | チートシートの原文、solcの警告の原文 | 2026-10-19 |
| 0x44 | solc 0.8.30 `--asm`・`--bin-runtime`、`cast disassemble` | 2026-10-19 |
| Globals126 | anvilにデプロイして`cast call` | 2026-10-19 |
| Ops126、Order126 | `forge test -vv`（既定の経路、`--via-ir`） | 2026-10-19 |
| ほかの言語での値 | 各言語の優先順位の規則、node・pythonの実行 | 2026-10-19 |
| Market 第126講のバージョン | `forge build --sizes`、`forge test`、コメントを除いたソースで`grep -o`で数える | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Cheatsheet（`docs/cheatsheet.rst`）: https://docs.soliditylang.org/en/v0.8.36/cheatsheet.html
  - 節は11、優先順位の表は`docs/types/operator-precedence-table.rst`をinclude。表の順序は"listed in order of evaluation"
- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variables（`docs/units-and-global-variables.rst`）: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
- Solidity公式ドキュメント v0.8.36、Expressions and Control Structures（`docs/control-structures.rst`、649行目に`require`の三つの形）: https://docs.soliditylang.org/en/v0.8.36/control-structures.html
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/cheatsheet.rst, https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/operator-precedence-table.rst
- 比較用のチートシート: argotorg/solidityのタグv0.8.30、v0.7.6の`docs/cheatsheet.rst`
- EIP-4399（prevrandao）: https://eips.ethereum.org/EIPS/eip-4399
- EIP-7516（blobbasefee）: https://eips.ethereum.org/EIPS/eip-7516
- EIP-6780（selfdestructの動作の変更）: https://eips.ethereum.org/EIPS/eip-6780
- Foundry公式ドキュメント: https://getfoundry.sh/
