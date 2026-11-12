# 第243講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| Marketのランタイム | 9,006バイト（第53章の最終バージョンとバイトまで同じ、末尾のメタデータハッシュの先頭4バイト`2fa6d798`） | チェーンのランタイムコードと照合 | 2026-10-21 |

付録の表と数字はすべて、ローカルのanvilに作ったおもちゃの7日間のチェーンをローカルの表に移してSQLを実行した結果である。分析サービスにログインしたりクエリを送ったりはしていない。日付はanvilで決めたおもちゃの時刻で、ガスの値はローカルのanvilの値である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Duneの公式ドキュメント | docs.dune.comの各ページの`.md`版（ドキュメントの一覧: https://docs.dune.com/llms.txt） | 2026-10-21 |
| DuneSQLの実行エンジン | Duneのドキュメント query engine overview 7行目 | 2026-10-21 |
| デコードの処理時間 | Duneのドキュメント decoded overview 29行目 | 2026-10-21 |

## 参考資料

行番号は2026-10-21に受け取った`.md`版（冒頭の案内3行を含む）を基準とする。

- Duneのドキュメント raw logs 13・20〜38行目（topic0はイベントのシグネチャのハッシュ、残りのtopicはindexedの引数）、raw blocks、raw transactions
- Duneのドキュメント query engine overview 7・19〜20行目
- Duneのドキュメント varbinary関数 11・13・156行目（バイトの位置で数える、`from_utf8`）
- Duneのドキュメント decoded overview 11・29・47行目、decoded event logs 19・31行目（`[projectname_blockchain].[contractName]_evt_[eventName]`）、decoded call tables 39・43行目（コントラクトのメモリの状態はDuneにない）、decoded contracts
- Duneのドキュメント decoding contracts 25〜29・45行目（バイトコードが100%同じときだけ、同じコントラクトのインスタンスとみなす）
- Foundry 公式ドキュメント: https://getfoundry.sh/
