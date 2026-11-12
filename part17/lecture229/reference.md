# 第229講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil・cast・forge） | 1.8.3、commit cae51ad4 | `anvil --version`、`cast --version` | 2026-10-21 |
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-21 |
| anvil | `--hardfork osaka`、チェーン番号31337、デフォルトのテスト用アカウント | `anvil`の起動画面、0番ブロックの照会 | 2026-10-21 |

付録のガス、ブロックの値、状態のコピーの大きさ、エラーはすべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| anvil osakaのデフォルト値 | 直接実行（0番ブロックの照会） | 2026-10-21 |
| Fill229・Marketのガス、状態のコピーの大きさ | 直接実行（cast `send`・`run`、`eth_estimateGas`、`anvil_dumpState`） | 2026-10-21 |
| メインネットのブロックのガスリミットの提案 | EIP-7935原文14行目（ethereum/EIPs masterのコミットcd7b26d2cf39d2eb071a26e1890e331f58767079） | 2026-10-20 |
| 取引一つのガス上限 | EIP-7825原文15・36行目 | 2026-10-21 |
| Fusakaのメインネットでの有効化 | EIP-7607原文49行目の表 | 2026-10-21 |
| EIP-4844の状態・作成日 | EIP-4844原文の冒頭、22行目 | 2026-10-20 |
| ブロックの間隔 | 12秒のスロットと仮定して計算 | 2026-10-21 |

## 参考資料

- EIP-7825 Transaction Gas Limit Cap: https://eips.ethereum.org/EIPS/eip-7825
- EIP-7935 Set default gas limit to 60M: https://eips.ethereum.org/EIPS/eip-7935
- EIP-7607 Hardfork Meta - Fusaka: https://eips.ethereum.org/EIPS/eip-7607
- EIP-4844 Shard Blob Transactions（22行目 "Rollups are in the short and medium term, and possibly in the long term, the only trustless scaling solution for Ethereum."）: https://eips.ethereum.org/EIPS/eip-4844
- 0の欄に初めて書く22,100ガス：第143講のコストの表
- Foundry 公式ドキュメント: https://getfoundry.sh/
