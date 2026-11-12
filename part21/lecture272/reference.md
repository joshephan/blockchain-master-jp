# 第272講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version`、`anvil --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| anvil | ブロック間隔1秒、デフォルトのテスト用アカウント、開発用のコマンド`evm_snapshot`・`evm_revert` | `anvil`の起動画面 | 2026-10-21 |

付録のアドレス、ログ、ブロック番号、残高、レシート、バージョン説明のコメントの数は、すべて上の環境で直接実行した結果である。デプロイ・送信はローカルのanvilのデフォルトのテスト用アカウントでだけ行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ECB Digital euroの定義・進行・プライバシー・オフライン | ECBのDigital euroのページ（ecb.europa.eu/euro/digital_euro/html/index.en.html） | 2026-10-21 |
| 法令、国ごとのCBDCの進行状況 | 原文を確認できなかったので載せない | 2026-10-21 |
| 取り消し・ログの読み取りの結果 | 直接実行（anvilでcastでデプロイ・預け入れ・引き出し・取り消し） | 2026-10-21 |
| Marketが通ってきた道 | 直接実行（第53章末のバージョンとキャップストーンの最後のバージョンのコピーで`grep -c`） | 2026-10-21 |

## 参考資料

- European Central Bank, Digital euro（ecb.europa.eu/euro/digital_euro/html/index.en.html）：定義（"a digital form of cash, issued by the central bank"）、2025年10月の次の段階の決定、2026年7月のrulebook草案0.91、2027年の試験、2029年の最初の発行の準備の目標（2026年のEU法の採択が条件）、支払いデータで利用者を識別できないという文言、オンライン・オフラインの支払い
- DigiCash：匿名性を備えた電子マネー。約束を守る側がサーバー1か所で、そのサーバー1か所が崩れるとお金も一緒に消えた
- 通しプロジェクトMarketのキャップストーンの最後のバージョン`design/architecture.md`の決定記録D-01〜D-18、`design/requirements.md`の要件の表（F 10、S 8、A 5、O 5、N 9）
- Foundry公式ドキュメント: https://getfoundry.sh/
