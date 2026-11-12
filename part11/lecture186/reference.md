# 第186講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30（ローカル、新しく取得していない） | `bugs/foundry.toml`、`market/foundry.toml` | 2026-10-21 |
| solc 0.7.6の成果物 | 以前に作ったOldのビルド成果物（新しくコンパイルしていない） | `cast code`の末尾`430007060033` | 2026-10-21 |
| 秘密鍵 | anvilの既定のテスト用の鍵（アカウント0番）だけ | ローカルのanvil | 2026-10-21 |

付録のcastの出力、テスト結果、IR、lintの出力は、すべて上の環境で直接実行した結果である。外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| anvilのデプロイのアドレスと二つのバージョンの答え | 直接実行（ローカルのanvil、`cast send --create`、`cast call`） | 2026-10-21 |
| Changelogのバージョンの日付 | Solidityリポジトリv0.8.36の写し（コミット8a079791）の`Changelog.md` | 2026-10-21 |
| 0.8.30の既知のバグ | 同じ写しの`docs/bugs_by_version.json`・`docs/bugs.json`（`tools/bugs184.py`で読む） | 2026-10-21 |
| ループのガス、テストのガス | 直接実行（via-IRの既定のプロファイルとlegacyプロファイル） | 2026-10-21 |
| 2^64秒 | 計算 | 2026-10-21 |
| BEC事件 | 事件の名前・年 | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Solidity v0.8.0 Breaking Changes（`080-breaking-changes.rst` 10〜17行 Silent Changesと算術、22〜31行 ABI coder v2、33〜34行 べき乗、38〜44行 Panic、149行 符号なし整数の単項マイナス、174行 `x**y**z`を`(x**y)**z`に）: https://docs.soliditylang.org/en/v0.8.36/080-breaking-changes.html
- Solidity公式ドキュメント v0.8.36、Control StructuresのPanic番号の一覧（`control-structures.rst` 635〜643行）: https://docs.soliditylang.org/en/v0.8.36/control-structures.html
- Solidity公式ドキュメント v0.8.36、OptimizerのUnchecked Loop Increment（`internals/optimizer.rst` 1425〜1454行）: https://docs.soliditylang.org/en/v0.8.36/internals/optimizer.html
- Solidityリポジトリ v0.8.36 `Changelog.md`（0.8.4 カスタムエラー、0.8.22 forのカウンタのオーバーフローチェックの除去、0.8.31 既定のEVMのosakaと非推奨の警告、0.8.34、0.8.35 `erc7201`、0.8.36 イベントの`@return`の禁止）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Solidityリポジトリ v0.8.36 `docs/bugs.json`、`docs/bugs_by_version.json`: https://github.com/argotorg/solidity/blob/v0.8.36/docs/bugs.json
- BeautyChain（BEC）トークン事件（2018）：0.8より前のバージョンの既定の算術で掛け算一行がオーバーフローし、残高のチェックを通り抜けた事件。この講義は名前・年とオーバーフローした掛け算一行だけを扱う
