# 第127講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30、0.7.6 | `solc --version` | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| evm_version | solcをそのまま呼ぶとprague、forgeのビルドはosaka | 直接実行 | 2026-10-19 |

付録のエラーの原文・値・サイズは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントの原文 | argotorg/solidityのタグv0.8.36 `docs/…`（ethereum/solidityリポジトリがargotorgに移った） | 2026-10-19 |
| 文法ファイルの大きさ、記号の数 | 取得した文法ファイルを`grep`、`wc -l`で数え、コメント・引用符の語を除いた記号の数を数える | 2026-10-19 |
| 文法ファイルのバージョンの違い | v0.8.30 / v0.8.36の文法ファイルの`diff` | 2026-10-19 |
| ANTLRのバージョン | v0.8.36タグの`scripts/test_antlr_grammar.sh`（antlr-4.8-complete.jar） | 2026-10-19 |
| エラー番号 | solc 0.8.30 / 0.7.6の`--error-codes`の出力 | 2026-10-19 |
| Powの二つのバージョン | anvilにデプロイして`cast code`、`cast call` | 2026-10-19 |
| Market 第127講のバージョン | `forge build --sizes`、`forge test`、solc 0.8.30 `--stop-after parsing` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Language Grammar（`docs/grammar.rst`）: https://docs.soliditylang.org/en/v0.8.36/grammar.html
  - 本文は`.. syntax:autogrammar:: SolidityParser.g4`、`.. syntax:autogrammar:: SolidityLexer.g4`の指示文2行
- Solidityの文法ファイル v0.8.36: `SolidityParser.g4`（622行）、`SolidityLexer.g4`（368行）。比較用にv0.8.30の同じ二つのファイル、v0.7.6の`Solidity.g4`（336行目`<assoc=right> expression Exp expression # ExpOperation`）・`SolidityLexer.g4`
- Solidity公式ドキュメント v0.8.36、Yul（`docs/yul.rst`）: https://docs.soliditylang.org/en/v0.8.36/yul.html
- Solidity公式ドキュメント v0.8.36、Solidity v0.8.0 Breaking Changes（`docs/080-breaking-changes.rst`）: https://docs.soliditylang.org/en/v0.8.36/080-breaking-changes.html
- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variables（`docs/units-and-global-variables.rst`）: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
- Solidity公式ドキュメント v0.8.36、TypesのShiftsの項目（`docs/types/value-types.rst`の70〜89行目）
- ANTLR 4.8: https://www.antlr.org/download/antlr-4.8-complete.jar （test_antlr_grammar.shに書かれたアドレス）
- Foundry公式ドキュメント: https://getfoundry.sh/
