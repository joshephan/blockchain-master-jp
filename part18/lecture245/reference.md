# 第245講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| Market | 第53章の最終バージョン、ランタイム9,006バイト、totalDepositsの欄の番号4 | `cast index`、`eth_getStorageAt` | 2026-10-21 |

付録のパネルと数字はすべて、ローカルのanvilに作ったおもちゃの7日間のチェーンをローカルの表に移してSQLを実行した結果である。日付はおもちゃの時刻である。集中の閾値40%は講義用の値である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Duneのダッシュボード | Duneのドキュメント dashboards 13行目（ドキュメントの一覧: https://docs.dune.com/llms.txt） | 2026-10-21 |
| Duneの予約実行 | Duneのドキュメント query scheduler 11・13・29行目 | 2026-10-21 |
| パネルの値すべて | 直接実行（ローカルのanvilのチェーン、ローカルの表） | 2026-10-21 |

## 参考資料

行番号は2026-10-21に受け取った`.md`版を基準とする。

- Duneのドキュメント dashboards 13行目（"Dashboards on Dune consist of widgets."）
- Duneのドキュメント query scheduler 11・13・29行目（あまり見られないダッシュボードのデータは古いことがある、予約実行のエンジン・クレジット）
- Foundry 公式ドキュメント（`cast index`）: https://getfoundry.sh/
