# 第97講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、anvilは既定の設定 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録のガス、残高、長さ、アドレスは、すべて上の環境のローカルのanvilで直接実行した結果である（anvilのレシート、`cast balance`、`cast codesize`、`forge inspect`、`cast send --create`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ゲッターと状態変数の可視性 | Solidity公式ドキュメント v0.8.36、Contractsの節 Visibility and Getters | 2026-10-19 |
| トランザクションの基本のガス21,000 | イーサリアムのイエローペーパー G_transaction、直接実行（`cast estimate`） | 2026-10-19 |
| スロットの読み取り・アカウントへのアクセスのコールド/ウォームのガス | EIP-2929（ベルリン、2021.04） | 2026-10-19 |
| コード1バイトあたりの保存のガス200 | イーサリアムのイエローペーパー G_codedeposit、直接実行（`cast send --create 0x60215ff3` / `0x60225ff3`） | 2026-10-19 |
| コードの欄のサイズの上限 | EIP-170 | 2026-10-19 |
| 読む道ごとのgasUsed、残高、長さ | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Contractsの節 Visibility and Getters）
- EIP-2929 Gas cost increases for state access opcodes: https://eips.ethereum.org/EIPS/eip-2929
- EIP-170 Contract code size limit: https://eips.ethereum.org/EIPS/eip-170
- イーサリアムのイエローペーパー: https://ethereum.github.io/yellowpaper/paper.pdf
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
