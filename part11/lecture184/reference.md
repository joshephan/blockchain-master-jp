# 第184講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30+commit.73712a01（ローカル、新しく取得していない） | `solc-0.8.30 --version` | 2026-10-21 |
| Solidityリポジトリの写し | v0.8.36、コミット8a079791（2026-07-09） | リポジトリの写し | 2026-10-21 |

付録の数、テスト結果、IR、ビルド結果は、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| bugs.jsonの項目数、バージョンごとの数、0.8.30の四つ | 直接実行（`tools/bugs184.py`でリポジトリの写しの`docs/bugs.json`、`docs/bugs_by_version.json`を読む） | 2026-10-21 |
| バージョンの公開日 | `docs/bugs_by_version.json`のreleased | 2026-10-21 |
| キーの数、optimizerの条件の項目 | リポジトリの写しの`docs/bugs.json`から数えた | 2026-10-21 |
| Changelog | リポジトリの写しの`Changelog.md` 0.8.34（2026-02-18）Important Bugfixes | 2026-10-21 |
| Marketのビルド | 直接実行（`forge build --offline --force`、`out/Market.sol/Market.json`のdeployedBytecode） | 2026-10-21 |
| Clear184のテストのガス | 直接実行（既定のプロファイルとlegacyプロファイル） | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、List of Known Bugs（`docs/bugs.rst`、9〜10行 "some of the known security-relevant bugs"、22〜31行 疑う基準三つ、キーの説明）: https://docs.soliditylang.org/en/v0.8.36/bugs.html
- Solidityリポジトリ v0.8.36 `docs/bugs.json`: https://github.com/argotorg/solidity/blob/v0.8.36/docs/bugs.json
- Solidityリポジトリ v0.8.36 `docs/bugs_by_version.json`: https://github.com/argotorg/solidity/blob/v0.8.36/docs/bugs_by_version.json
- Solidityリポジトリ v0.8.36 `Changelog.md`（0.8.34 Important Bugfixes）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- 0.8.30の四つを知らせたSolidityブログの記事（`bugs.json`のlink）
  - LostStorageArrayWriteOnSlotOverflow（2025-12-18）: https://blog.soliditylang.org/2025/12/18/lost-storage-array-write-on-slot-overflow-bug/
  - TransientStorageClearingHelperCollision（2026-02-18）: https://blog.soliditylang.org/2026/02/18/transient-storage-clearing-helper-collision-bug/
  - UnsoundSpillInMutualRecursion（2026-07-09）: https://blog.soliditylang.org/2026/07/09/unsound-spill-in-mutual-recursion-bug/
  - InheritanceOrderReversalOnStorageEndWarning（2026-07-09）: https://blog.soliditylang.org/2026/07/09/inheritance-order-reversal-on-storage-end-warning-bug/
- ツールチェーンの事件Curve Vyper（2023）：コンパイラが、ソースの再入ロックをバイトコードで正しく作れなかった事件。この講義は名前・年だけを扱う
