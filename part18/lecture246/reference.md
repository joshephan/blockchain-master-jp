# 第246講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka、`bytecode_hash = "ipfs"`、`cbor_metadata = true` | `foundry.toml`、コードの末尾 | 2026-10-21 |
| Market | 第53章の最終バージョン、ランタイム9,006バイト | チェーンのランタイムコード | 2026-10-21 |

付録の表と数字はすべて、ローカルのanvilに作ったおもちゃの7日間のチェーンをローカルの表に移してSQLを実行した結果である。日付はおもちゃの時刻で、閾値（1件20%、1時間30%）は講義用の値である。セレクターと逆アセンブルは、`cast sig`、`cast disassemble`で直接確かめた。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Duneのアラート | Duneのドキュメント alerts 11・12・32・36行目（ドキュメントの一覧: https://docs.dune.com/llms.txt） | 2026-10-21 |
| Duneのデコード（プロキシ・ダイヤモンド） | Duneのドキュメント decoding contracts 79〜96行目 | 2026-10-21 |
| クエリの結果すべて | 直接実行（ローカルのanvilのチェーン、ローカルの表） | 2026-10-21 |

## 参考資料

行番号は2026-10-21に受け取った`.md`版を基準とする。

- Duneのドキュメント alerts 32行目（クエリの実行後にアラート、遅れることがある、失敗した配信の再試行なし）
- Duneのドキュメント decoding contracts 81行目（"Submit using the proxy address but with the ABI of the implementation."）
- Foundry 公式ドキュメント（`cast sig`、`cast disassemble`）: https://getfoundry.sh/
