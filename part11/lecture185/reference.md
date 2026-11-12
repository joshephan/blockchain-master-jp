# 第185講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01.Windows.msvc | `solc --version` | 2026-10-21 |
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| Solidityリポジトリの写し | v0.8.36、コミット8a079791（2026-07-09） | リポジトリの写し | 2026-10-21 |

付録のエラー一覧、テスト結果、ビルドの出力は、すべて上の環境で直接実行した結果である。古いコンパイラは今回回しておらず、古いバージョンのルールの値はドキュメントのルールで計算した。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| バージョンの公開日 | リポジトリの写しの`Changelog.md`のバージョンの見出し | 2026-10-21 |
| エラー番号とメッセージ | 直接実行（`tools/errs185.py`、`tools/errs185_full.py`） | 2026-10-21 |
| テストのガス | 直接実行（`forge test --match-contract Silent185Test`） | 2026-10-21 |
| Marketのビルド | 直接実行（`forge build --offline --force`） | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Solidity v0.5.0 Breaking Changes（`050-breaking-changes.rst`、Semantic Only Changes 18〜50行、予約語282〜285行、Interoperability With Older Contracts 287〜367行）: https://docs.soliditylang.org/en/v0.8.36/050-breaking-changes.html
- Solidity公式ドキュメント v0.8.36、Solidity v0.6.0 Breaking Changes（`060-breaking-changes.rst` 12〜20、38〜42、74〜85、117〜125行）: https://docs.soliditylang.org/en/v0.8.36/060-breaking-changes.html
- Solidity公式ドキュメント v0.8.36、Solidity v0.7.0 Breaking Changes（`070-breaking-changes.rst` 12〜19、81〜83、91〜93、108〜110行）: https://docs.soliditylang.org/en/v0.8.36/070-breaking-changes.html
- Solidity公式ドキュメント v0.8.36、Solidity v0.8.0 Breaking Changes（`080-breaking-changes.rst`の節の見出し）: https://docs.soliditylang.org/en/v0.8.36/080-breaking-changes.html
- Solidityリポジトリ v0.8.36 `Changelog.md`（0.5.0 "Warning: this may silently change the semantics of existing code!"）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- EIP-721のインターフェース（`pragma solidity ^0.4.20;`がついた原文）: https://eips.ethereum.org/EIPS/eip-721
