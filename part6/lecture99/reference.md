# 第99講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、ガス、長さ、アドレスは、すべて上の環境のローカルのanvilで直接実行した結果である（`cast send --json`、`cast run`、`forge test`、`cast codesize`）。2300ガスはトレースの`[2300]`で確かめた。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| receive・fallbackの規則、2300の文、受け取る関数なしでイーサを受け取る場合 | Solidity公式ドキュメント v0.8.36、Contractsの節のReceive Ether Function、Fallback Function | 2026-10-19 |
| receive・fallbackの分離（0.6.0） | Solidity公式ドキュメント、0.6.0 Breaking Changes | 2026-10-19 |
| バリデーターの引き出し | EIP-4895 | 2026-10-19 |
| 2300で壊れた事例（SLOAD・BALANCE・EXTCODEHASHのガスの引き上げ） | EIP-1884、第55講の付録 | 2026-10-19 |
| selfdestructの動作の変更 | EIP-6780、solc Warning 5159の原文 | 2026-10-19 |
| ガス、長さ、アドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Contractsの節のReceive Ether Function、Fallback Function、0.6.0 Breaking Changes）
- EIP-1884 Repricing for trie-size-dependent opcodes: https://eips.ethereum.org/EIPS/eip-1884
- EIP-4895 Beacon chain push withdrawals as operations: https://eips.ethereum.org/EIPS/eip-4895
- EIP-6780 SELFDESTRUCT only in same transaction: https://eips.ethereum.org/EIPS/eip-6780
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
