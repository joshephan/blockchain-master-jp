# 第74講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のエラーの原文、ガスの数字、欄の値、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 三項演算子、複合代入・インクリメント／デクリメント、deleteのルール | Solidityのソースのタグv0.8.36 `docs/types/operators.rst` | 2026-10-19 |
| SSTOREの返金ルール | EIP-3529 | 2026-10-19 |
| Wipe・MapStruct・LedgerTotal・MarketのgasUsed | anvil、`cast send --json`（直接実行） | 2026-10-19 |
| anvilのブロックの時刻 | `cast call`の出力（直接実行） | 2026-10-19 |
| テストのアドレス | `forge create`の出力（直接実行） | 2026-10-19 |

## 参考資料

- Solidityドキュメントのソースv0.8.36、Ternary Operator・Compound and Increment/Decrement Operators・delete: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/operators.rst
- EIP-3529 Reduction in refunds: https://eips.ethereum.org/EIPS/eip-3529
- Foundry公式ドキュメント: https://getfoundry.sh/
