# 第222講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| anvil | `--hardfork osaka`、チェーンの番号31337、既定のテスト用の鍵 | `anvil`の起動画面 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |

付録のテスト結果、アドレス、calldata、ガス、エラーは、すべて上の環境で直接実行した結果である。署名・送信は、ローカルのanvilの既定のテスト用の鍵と、デモ用の鍵`0xA11CE`・`0x5E55`だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIP-7702の原文 | raw.githubusercontent.com/ethereum/EIPs/master/EIPS/eip-7702.md | 2026-10-21 |
| ERC-4337の原文 | raw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-4337.md | 2026-10-21 |
| モジュール・権限のERCの先頭の欄 | ethereum/ERCs masterの各ERCのファイルの先頭の欄 | 2026-10-21 |
| コントラクトのサイズ | 直接実行（`forge build --offline --sizes`） | 2026-10-21 |
| anvilのgasUsed・時刻、デモのアドレス | 直接実行（`forge script` runA・runC・runB、`evm_increaseTime`） | 2026-10-21 |
| テストのガス | 直接実行（`forge test --offline --match-contract Account222Test -vv`） | 2026-10-21 |

## 参考資料

- ERC-4337 Account Abstraction Using Alt Mempool（コミットc8d8c210のバージョン）: https://eips.ethereum.org/EIPS/eip-4337 （rawファイルの218〜224行目、関数セレクタでナンスのkeyを分けるADMIN_METHODSIGの例）
- EIP-7702 Set Code for EOAs（コミットbbc3f958のバージョン）: https://eips.ethereum.org/EIPS/eip-7702 （rawファイルの41〜44行目、274〜277行目）
- ERC-7579 Minimal Modular Smart Accounts: https://eips.ethereum.org/EIPS/eip-7579
- ERC-6900 Modular Smart Contract Accounts: https://eips.ethereum.org/EIPS/eip-6900
- ERC-7710 Smart Contract Delegation: https://eips.ethereum.org/EIPS/eip-7710
- ERC-7715 Request Permissions from Wallets: https://eips.ethereum.org/EIPS/eip-7715
- Foundry公式ドキュメント: https://getfoundry.sh/
