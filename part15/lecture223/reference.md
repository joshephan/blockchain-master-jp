# 第223講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| anvil | `--hardfork osaka`、チェーンの番号31337、既定のテスト用の鍵 | `anvil`の起動画面 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |

付録のテスト結果、アドレス、ハッシュ、ガス、エラーは、すべて上の環境で直接実行した結果である。署名・送信は、ローカルのanvilの既定のテスト用の鍵とデモ用の鍵だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Vitalik Buterinの記事 | vitalik.eth.limo | 2026-10-21 |
| EIP-2612のpermitの欄 | OpenZeppelin Contracts v5.4.0 `contracts/token/ERC20/extensions/ERC20Permit.sol` 21〜22行目 | 2026-10-21 |
| ERC-1271の先頭の欄 | ethereum/ERCs master | 2026-10-21 |
| EIP-7702の原文 | raw.githubusercontent.com/ethereum/EIPs/master/EIPS/eip-7702.md | 2026-10-21 |
| コントラクトのサイズ | 直接実行（`forge build --offline --sizes`） | 2026-10-21 |
| anvilのgasUsed・時刻、デモのアドレス | 直接実行（anvilでcastによりデプロイ・署名・送信） | 2026-10-21 |
| テストのガス | 直接実行（`forge test --offline --match-contract Recovery223Test -vv`） | 2026-10-21 |

## 参考資料

- Vitalik Buterin, "Why we need wide adoption of social recovery wallets", 2021-01-11, vitalik.eth.limo（署名の鍵一つ、保護者の過半数が署名の鍵を替える、保護者の追加・削除は待ち時間のあと、保護者のリストの代わりにそのハッシュをチェーンに置く方法）
- EIP-2612 Permit Extension for EIP-20 Signed Approvals: https://eips.ethereum.org/EIPS/eip-2612
- EIP-712 Typed structured data hashing and signing: https://eips.ethereum.org/EIPS/eip-712
- ERC-1271 Standard Signature Validation Method for Contracts: https://eips.ethereum.org/EIPS/eip-1271
- EIP-7702 Set Code for EOAs（コミットbbc3f958のバージョン）: https://eips.ethereum.org/EIPS/eip-7702
- OpenZeppelin Contracts v5.4.0 `contracts/token/ERC20/extensions/ERC20Permit.sol`（PERMIT_TYPEHASH）
- Foundry公式ドキュメント: https://getfoundry.sh/
