# 第135講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| EVMのバージョン | デモ・通しプロジェクトはosaka、solcを直接呼ぶ場合の既定値はprague | foundry.toml | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 例Cの配置 | `solc --storage-layout --transient-storage-layout src/DocC.sol` | 2026-10-20 |
| スロットの値 | デモのプロジェクトで`forge test --match-path test/Layout135.t.sol -vv`、同じコマンドに`--via-ir`（test_badStr） | 2026-10-20 |
| `layout at`のエラー | `solc --storage-layout --transient-storage-layout`でWrap・Abs・Mid・TrLayout・Ercを直接実行 | 2026-10-20 |
| SLOAD・SSTOREのガスと一つの欄への書き込みのガス | anvil（`--steps-tracing`）にバージョンごとに新しくデプロイ、レシートのgasUsedと`debug_traceTransaction`のgasCost | 2026-10-20 |
| Marketの欄の値 | anvilにアカウント0番でデプロイしてから`cast storage`、`cast keccak`、`cast index address <トークン> 2` | 2026-10-20 |
| storageLayoutとastId | `forge inspect src/Market.sol:Market storageLayout --json`（四つのバージョン）、`solc --storage-layout src/Market.sol` | 2026-10-20 |
| ERC-7201の開始のスロット | `cast index-erc7201 market.main` | 2026-10-20 |
| SLOAD・SSTOREのガスの規則 | EIP-2929、EIP-2200、EIP-3529 | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Layout of State Variables in Storage and Transient Storage（規則5行、例C、マッピング・動的配列、bytes・string、JSON Output）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/layout_in_storage.rst
- Solidity公式ドキュメント v0.8.36、Custom Storage Layout（`layout at`）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/custom-storage-layout.rst
- EIP-2929, Gas cost increases for state access opcodes: https://eips.ethereum.org/EIPS/eip-2929
- EIP-2200, Structured Definitions for Net Gas Metering: https://eips.ethereum.org/EIPS/eip-2200
- EIP-3529, Reduction in refunds: https://eips.ethereum.org/EIPS/eip-3529
- ERC-7201, Namespaced Storage Layout: https://eips.ethereum.org/EIPS/eip-7201
- Foundry公式ドキュメント（`cast storage`、`cast index`、`cast index-erc7201`）: https://getfoundry.sh/
