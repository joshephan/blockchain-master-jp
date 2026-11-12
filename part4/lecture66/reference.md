# 第66講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvilのブロックガスリミット | 30,000,000（既定値） | `cast block latest --field gasLimit` | 2026-10-19 |

付録のエラーの原文、ガスの数字、欄の値、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| push・popのルール | Solidityのソースのタグv0.8.36 `docs/types/reference-types.rst`（Arrays、Array Members） | 2026-10-19 |
| lengthへの代入が禁止されたバージョン | Solidityのソースのタグv0.8.36 `docs/060-breaking-changes.rst` | 2026-10-19 |
| push・pop・sum・fillのgasUsed | anvil、`cast send --json`（直接実行） | 2026-10-19 |
| メインネットのブロックガスリミット | `cast block latest --field gasLimit --rpc-url https://ethereum-rpc.publicnode.com` | 2026-10-19 |
| メインネットのトランザクション一つのガスの上限 | EIP-7825、EIP-7607 | 2026-10-19 |
| sumのおおよその最大の長さ | 上の測定値から計算 | 2026-10-19 |
| SLOAD・SSTOREの価格 | EIP-2200、EIP-2929 | ベルリン（2021.04）以降 |

## 参考資料

- Solidityドキュメントのソースv0.8.36、Arrays・Array Members: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/reference-types.rst
- Solidityドキュメントのソースv0.8.36、Solidity v0.6.0 Breaking Changes: https://github.com/argotorg/solidity/blob/v0.8.36/docs/060-breaking-changes.rst
- Solidity公式ドキュメントv0.8.36、Layout of State Variables in Storage: https://docs.soliditylang.org/en/v0.8.36/
- EIP-7825 Transaction Gas Limit Cap: https://eips.ethereum.org/EIPS/eip-7825
- EIP-7607 Hardfork Meta - Fusaka: https://eips.ethereum.org/EIPS/eip-7607
- EIP-2200 Structured Definitions for Net Gas Metering: https://eips.ethereum.org/EIPS/eip-2200
- EIP-2929 Gas cost increases for state access opcodes: https://eips.ethereum.org/EIPS/eip-2929
- Foundry公式ドキュメント: https://getfoundry.sh/
