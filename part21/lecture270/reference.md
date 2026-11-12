# 第270講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Python | 標準ライブラリだけ（`fractions`、`urllib`、`json`） | `nakamoto270.py`の最初の行 | 2026-10-21 |
| Foundry（anvil） | 1.8.3、デフォルトの設定 | `anvil --version` | 2026-10-21 |

付録の係数の出力は、すべて上の環境で直接実行した結果である。持ち分はすべておもちゃのデータである。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ethereum.orgの攻撃と防御 | ethereum.org Proof-of-stake attack and defense（developers/docs/consensus-mechanisms/pos/attack-and-defense） | 2026-10-21 |
| ethereum.orgのクライアントの多様性 | ethereum.org Client diversity（developers/docs/nodes-and-clients/client-diversity） | 2026-10-21 |
| クライアントのシェア（載せなかった値の出典） | ethereum.org client-diversityのスナップショットの表（実行クライアントsupermajority.info、コンセンサスクライアントblockprint基準）、clientdiversity.org、ethernodes.org | 2026-10-21 |
| ナカモト係数という名前の出典 | 原文のページを開けなかったので載せない | 2026-10-21 |
| 係数の出力、anvilのminerの欄 | 直接実行（`nakamoto270.py`、anvilで`anvil_setCoinbase`・`anvil_mine`） | 2026-10-21 |

## 参考資料

- ethereum.org, Proof-of-stake attack and defense：33%はファイナリティの遅れ、66%以上は望むチェーンを単独でファイナライズ
- ethereum.org, Client diversity：33%を超えるコンセンサスクライアントのバグはファイナリティを妨げ、3分の2の多数を持つクライアントの致命的なバグはチェーンを誤って分岐させてファイナライズしうる
- Pythonの`fractions`モジュール（分数で持ち分を足して境目で間違えないように数える）
- Foundry公式ドキュメント: https://getfoundry.sh/
