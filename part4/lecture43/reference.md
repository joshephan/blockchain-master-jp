# 第43講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、0.7.6 | コンパイルの出力`Compiling ... with Solc ...` | 2026-10-19 |
| forge-std | `forge init`のときに取得した版 | `lib/forge-std` | 2026-10-19 |

付録の出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| abicoder v2が既定値になったバージョン | Solidity公式ドキュメント、0.7.6の実行出力（行がなければv1） | 2026-10-19 |
| experimentalの値のリスト | Solidity公式ドキュメントv0.8.36、Pragmasの節 | 2026-10-19 |
| 0.8.30の反応 | 直接実行した出力 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36（Layout of a Solidity Source File、Pragmasの節）: https://docs.soliditylang.org/en/v0.8.36/
- 公式ドキュメントのVotingの例（demo/wide/Ballot.solの元）、[第37講](../../part3/lecture37/)を参照
- Foundry公式ドキュメント: https://getfoundry.sh/
