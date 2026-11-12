# 第230講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil・cast） | 1.8.3、commit cae51ad4 | `anvil --version`、`cast --version` | 2026-10-21 |
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-21 |
| anvil | `--hardfork osaka`（1回は`cancun`）、`--no-mining`、チェーン番号31337、デフォルトのテスト用アカウント | `anvil`の起動画面 | 2026-10-21 |

付録のガス、手数料、ハッシュ、ブロックの値、エラーはすべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ハードフォークのメインネットでの有効化 | EIP-7569・7600・7607原文のActivationの表 | 2026-10-21 |
| blobの目標・最大 | EIP-4844原文49〜50行目（ガスの値 ÷ 131,072）、EIP-7691原文31〜32行目 | 2026-10-21 |
| 取引一つのblobの最大 | EIP-7594原文32行目 | 2026-10-21 |
| blobの保管 | EIP-4844原文56行目、エポックの長さを仮定して計算 | 2026-10-21 |
| ガス・手数料・blobの値段の変化 | 直接実行（cast `send --blob`・`mktx --blob`、`anvil_getBlobsByTransactionHash`、`evm_mine`） | 2026-10-21 |

EIPの原文は、ethereum/EIPs masterのコミットcd7b26d2cf39d2eb071a26e1890e331f58767079のもの（2026-10-20）である。

## 参考資料

- EIP-4844 Shard Blob Transactions（パラメーター42〜56行目、16〜17・33・107・166・186・192・230〜231・236・361・364〜365行目、プリコンパイル0x0A 50,000ガス47〜48行目、バージョン付きハッシュ77〜80行目）: https://eips.ethereum.org/EIPS/eip-4844
- EIP-1559 Fee market change for ETH 1.0 chain: https://eips.ethereum.org/EIPS/eip-1559
- EIP-7623 Increase calldata cost（31・33・67行目）: https://eips.ethereum.org/EIPS/eip-7623
- EIP-7691 Blob throughput increase: https://eips.ethereum.org/EIPS/eip-7691
- EIP-7594 PeerDAS - Peer Data Availability Sampling: https://eips.ethereum.org/EIPS/eip-7594
- EIP-7918 Blob base fee bounded by execution cost（49〜52行目）: https://eips.ethereum.org/EIPS/eip-7918
- EIP-7892 Blob Parameter Only Hardforks: https://eips.ethereum.org/EIPS/eip-7892
- EIP-7569 Hardfork Meta - Dencun: https://eips.ethereum.org/EIPS/eip-7569
- EIP-7600 Hardfork Meta - Pectra: https://eips.ethereum.org/EIPS/eip-7600
- EIP-7607 Hardfork Meta - Fusaka: https://eips.ethereum.org/EIPS/eip-7607
- Solidity 公式ドキュメント v0.8.36 `units-and-global-variables.rst` 77〜82行目（`blobhash`、`block.blobbasefee`）: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
- Foundry 公式ドキュメント: https://getfoundry.sh/
