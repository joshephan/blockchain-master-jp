# 第149講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-20 |
| solc | 0.8.30 | `solc --version`、foundry.toml `solc = "0.8.30"` | 2026-10-20 |

付録の出力とガスの数字は、すべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcの設定 | foundry.toml、`forge config` | 2026-10-20 |
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36 `docs/style-guide.rst`、`docs/grammar/SolidityLexer.g4`、`docs/units-and-global-variables.rst` | 2026-10-20 |
| エラー番号、すでに止められる名前 | 直接実行（`solc --bin --error-codes`、`forge build`） | 2026-10-20 |
| forge lintの規則と出力 | 直接実行（`forge lint`、`--severity info`、`--only-lint`、`--deny`） | 2026-10-20 |
| セレクタ | `cast sig` | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| 末尾のハッシュ | 直接実行（第148講のバージョン・第149講のバージョンの三つのプロファイルの成果物を比較） | 2026-10-20 |
| ガス | 直接実行（バージョンごとに新しいanvil、レシートのgasUsed） | 2026-10-20 |
| 行番号 | 第149講のバージョンの`src`、`forge lint`の出力 | 2026-10-20 |
| アカウント0番、テストコントラクトのアドレス | anvilの既定のアカウント、`forge test`の出力 | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Style GuideのNaming Conventions（`docs/style-guide.rst` 1102〜1303行）：https://docs.soliditylang.org/en/v0.8.36/style-guide.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/style-guide.rst
- Solidityの文法ファイルv0.8.36、`docs/grammar/SolidityLexer.g4`（ReservedKeywords 3〜10行、Identifier 251〜259行）：https://github.com/argotorg/solidity/blob/v0.8.36/docs/grammar/SolidityLexer.g4
- Solidity公式ドキュメントv0.8.36、Units and Globally Available VariablesのReserved Keywords（`docs/units-and-global-variables.rst` 429〜442行）：https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- Foundry公式ドキュメント（`forge lint`の規則）：https://getfoundry.sh/
