# 第231講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil・cast） | 1.8.3、commit cae51ad4 | `anvil --version`、`cast --version` | 2026-10-21 |
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-21 |
| anvil | `--hardfork osaka`、チェーン番号31337、デフォルトのテスト用アカウント | `anvil`の起動画面 | 2026-10-21 |

付録のガス、ハッシュ、エラー、ノードの応答はすべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIP-7594の状態、Fusakaのメインネットでの有効化 | EIP-7594原文の冒頭、EIP-7607原文のActivationの表 | 2026-10-21 |
| データだけを受け持つネットワーク、L2の分類のサイト | 名前のみ（公開資料） | 2026-10-21 |
| blobの保管 | EIP-4844原文56行目、エポックの長さを仮定して計算 | 2026-10-21 |
| ガス・記録・ノードの応答 | 直接実行（cast `send`・`send --blob`・`wallet sign`・`call`、`anvil_getBlobByHash`） | 2026-10-21 |
| セル証明の数 | 直接実行（`cast mktx --blob`をRLPでほどいて数えた、第230講の実習） | 2026-10-21 |

EIPの原文は、ethereum/EIPs masterのコミットcd7b26d2cf39d2eb071a26e1890e331f58767079のもの（2026-10-20）である。

## 参考資料

- EIP-4844 Shard Blob Transactions（56・360行目）: https://eips.ethereum.org/EIPS/eip-4844
- EIP-7594 PeerDAS - Peer Data Availability Sampling（20・26・30・55行目）: https://eips.ethereum.org/EIPS/eip-7594
- EIP-7607 Hardfork Meta - Fusaka: https://eips.ethereum.org/EIPS/eip-7607
- EIP-191 Signed Data Standard: https://eips.ethereum.org/EIPS/eip-191
- データだけを受け持つネットワーク：Celestia、Avail、EigenDA（名前のみ）
- L2の分類の公開サイト：L2BEAT（名前のみ）
- Foundry 公式ドキュメント: https://getfoundry.sh/
