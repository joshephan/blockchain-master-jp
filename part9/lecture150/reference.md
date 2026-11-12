# 第150講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| anvilのブロックガスリミット | 30,000,000 | `cast block latest -f gasLimit` | 2026-10-20 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcの設定 | foundry.toml、`forge build` | 2026-10-20 |
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36 `docs/common-patterns.rst` | 2026-10-20 |
| 2300、64分の63 | Solidityのドキュメント、EIP-150、前の講義の実測 | 2026-10-20 |
| メインネットのブロックガスリミット | 公開RPC（ethereum-rpc.publicnode.com）の`eth_getBlockByNumber`で直近24時間のブロック300個の標本、EIP-7935 | 2026-10-20 |
| トランザクションのガスの上限 | EIP-7825 | 2026-10-20 |
| イーサの総量 | https://etherscan.io/stat/supply | 2026-10-20 |
| 詰まり・ガスを燃やす・二つの形のガス・長さごとのpayAll | 直接実行（バージョンごとに新しいanvil、`cast send --json`のstatus・gasUsed、`cast storage`） | 2026-10-20 |
| Marketのガス | 直接実行（新しいanvil、レシートのgasUsed） | 2026-10-20 |
| テストのガス | `forge snapshot` | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| アカウント | anvilの既定のアカウント | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Common PatternsのWithdrawal from Contracts（`docs/common-patterns.rst` 13〜106行、WithdrawalContract 30〜63行、SendContract 69〜93行）：https://docs.soliditylang.org/en/v0.8.36/common-patterns.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/common-patterns.rst
- EIP-150, Gas cost changes for IO-heavy operations（呼び出しに渡すガスの64分の63）：https://eips.ethereum.org/EIPS/eip-150
- EIP-7935（既定のブロックガスリミット60M）：https://eips.ethereum.org/EIPS/eip-7935
- EIP-7825, Transaction Gas Limit Cap（トランザクション一つ16,777,216、Fusaka 2025-12-03）：https://eips.ethereum.org/EIPS/eip-7825
- Foundry公式ドキュメント：https://getfoundry.sh/
