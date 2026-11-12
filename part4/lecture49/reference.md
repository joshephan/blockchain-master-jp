# 第49講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の欄の配置、ガス、巻き戻しの出力は、すべて上の環境のローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Voter構造体のサイズ | `forge inspect VoterWithVar storageLayout` | 2026-10-19 |
| Orderの二つの版のサイズ | `forge inspect storageLayout` | 2026-10-19 |
| saveのgasUsed | anvilでの`cast send`のレシート | 2026-10-19 |
| order()のガス見積もり | `cast estimate` | 2026-10-19 |
| SSTOREの価格 | 第16講の時効性のあるデータ | 2026-10-19 |
| 範囲外のenumの巻き戻し | solc 0.8.30で直接実行した出力 | 2026-10-19 |
| デプロイのサイズ | `forge build --sizes` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36: https://docs.soliditylang.org/en/v0.8.36/
  - Structure of a Contractの節（コントラクトに置ける七つ：状態変数、関数、modifier、イベント、エラー、構造体、列挙型）
  - 例Voting（Ballotコントラクトの`struct Voter`、`struct Proposal`）
  - 例Safe Remote Purchase（Purchaseコントラクトの`enum State`）
- Foundry公式ドキュメント: https://getfoundry.sh/
