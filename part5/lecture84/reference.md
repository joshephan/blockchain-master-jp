# 第84講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力、アドレス、ガスの値は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| コントラクトアカウントのナンスの開始値 | EIP-161、直接実行（`cast nonce`、`vm.getNonce`） | 2026-10-19 |
| saltを入れた作成の機械の命令 | EIP-1014 | 2026-10-19 |
| バイト長 | 直接実行、`forge test -vv`、`-vvvvv`のトレース | 2026-10-19 |
| ガス | 直接実行、`cast send`、`forge test -vvvv` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control Structuresの節のCreating Contracts via `new`、Salted contract creations / create2: https://docs.soliditylang.org/en/v0.8.36/
- EIP-161（State trie clearing、新しいコントラクトアカウントのナンスは1から始まる）: https://eips.ethereum.org/EIPS/eip-161
- EIP-1014（CREATE2、Constantinopleハードフォーク）: https://eips.ethereum.org/EIPS/eip-1014
- Foundry公式ドキュメント（チートコード`vm.computeCreateAddress`、`vm.computeCreate2Address`、`vm.getNonce`、`cast compute-address`）: https://getfoundry.sh/
