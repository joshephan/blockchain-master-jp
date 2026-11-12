# 第153講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01.Windows.msvc | `solc --version` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| OS・ツール | Windows 11（10.0.26200）、Python 3.12.10、git 2.51.1 | `ver`、`python --version`、`git --version` | 2026-10-20 |
| コンパイラのリポジトリ | argotorg/solidityタグv0.8.36、コミット`8a079791d9cca7a6c03fd6a8429b93aa3bddefed` | `git log -1` | 2026-10-20 |

付録の出力と数字は、すべて上の環境で直接実行した結果である。issueとPRは実際には上げていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントの版と行番号 | リポジトリのタグv0.8.36 `docs/resources.rst`、`docs/contributing.rst`、`docs/brand-guide.rst`、`docs/index.rst` | 2026-10-20 |
| ツールの一覧の数とNote | `docs/resources.rst`をまとまりごとに数える | 2026-10-20 |
| チャンネル・チームコール | `docs/contributing.rst` 27〜38、579〜580行、`docs/resources.rst` 13〜14行 | 2026-10-20 |
| Changelogのバージョン・日付 | リポジトリの`Changelog.md` | 2026-10-20 |
| テストの数と0.8.30の結果 | 直接実行（リポジトリの`test/libsolidity/syntaxTests`、`test/cmdlineTests`、ドキュメントの例を簡易チェッカーで照合） | 2026-10-20 |
| テンプレートの欄 | リポジトリの`.github/ISSUE_TEMPLATE/`、PRテンプレート、`SECURITY.md` | 2026-10-20 |
| バウンティ | `SECURITY.md` 49〜50行 | 2026-10-20 |
| ドキュメントのビルド | リポジトリの`docs/docs.sh`、`docs/requirements.txt` | 2026-10-20 |
| ライセンス | リポジトリの`LICENSE.txt`、`docs/brand-guide.rst`、MarketのSPDXとrawMetadata、forge-std・OpenZeppelinのソース | 2026-10-20 |
| Marketのガス・サイズ・ハッシュ | 直接実行（新しいanvilのレシートのgasUsed、`forge build --sizes`、`forge inspect`） | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Resources：https://docs.soliditylang.org/en/v0.8.36/resources.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/resources.rst
- Solidity公式ドキュメントv0.8.36、Contributing（貢献できる場所5〜19行、バグ報告40〜57行、PR 59〜89行、AI-Assisted Contributions 94〜102行、文法テスト203〜291行、コマンドラインテスト292〜347行、ドキュメントへの貢献465〜553行、言語設計555〜582行）：https://docs.soliditylang.org/en/v0.8.36/contributing.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/contributing.rst
- Solidity公式ドキュメントv0.8.36、Brand Guide：https://docs.soliditylang.org/en/v0.8.36/brand-guide.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/brand-guide.rst
- コンパイラのリポジトリのタグv0.8.36：https://github.com/argotorg/solidity/tree/v0.8.36
- リポジトリの`Changelog.md`（0.8.31〜0.8.36）：https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- リポジトリの`SECURITY.md`：https://github.com/argotorg/solidity/blob/v0.8.36/SECURITY.md
- リポジトリの`LICENSE.txt`（GPL v3）：https://github.com/argotorg/solidity/blob/v0.8.36/LICENSE.txt
- リポジトリの`test/libsolidity/SyntaxTest.cpp`（87、136〜146行、バージョン・ライセンスの行を先頭に付ける動作）：https://github.com/argotorg/solidity/blob/v0.8.36/test/libsolidity/SyntaxTest.cpp
- リポジトリの`scripts/isolate_tests.py`（ドキュメントの例の抽出）：https://github.com/argotorg/solidity/blob/v0.8.36/scripts/isolate_tests.py
- Foundry公式ドキュメント：https://getfoundry.sh/
