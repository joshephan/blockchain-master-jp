# 第38講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"`、コンパイル出力 | 2026-10-19 |
| ローカルチェーン | anvil、デフォルトアカウント0〜3番と受益者の9番 | `anvil` | 2026-10-19 |

付録の出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 例の原文 | Solidityリポジトリのタグv0.8.36の`docs/examples/blind-auction.rst` | 2026-10-19 |
| メインネットのブロック時刻の規則 | イーサリアムのコンセンサス仕様（マージ以降はスロットの時刻、スロットは12秒） | 2026-10-19 |
| 実行例のブロック時刻 | 直接実行の出力 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Solidity by Example（Simple Open Auction、Blind Auction）: https://docs.soliditylang.org/en/v0.8.36/
- 例の元ファイル: https://github.com/argotorg/solidity/blob/v0.8.36/docs/examples/blind-auction.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
