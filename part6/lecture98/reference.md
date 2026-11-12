# 第98講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、ガス、残高、ブロックの時刻、アドレスは、すべて上の環境のローカルのanvilで直接実行した結果である（`cast send`、`cast balance`、`cast block -f timestamp`、`forge test -vvvv`、`forge create`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| view関数で状態の変更とみなす八つ、"Getter methods are automatically marked `view`."、0.5.0より前は`view`に`STATICCALL`を使わなかったというNote、ビザンチウム以上が対象なら`view`の呼び出しに`STATICCALL` | Solidity公式ドキュメント v0.8.36、Contractsの節 State Mutability、View Functions | 2026-10-19 |
| pure関数で状態の読み取りとみなす五つ、`msg.sig`・`msg.data`の例外、リバートは状態の変更とみなさない | 同じ節 Pure Functions | 2026-10-19 |
| `STATICCALL` | EIP-214 | 2026-10-19 |
| 第97講の読み取りのgasUsed、第47講のpreview() | 第97講・第47講の付録の値 | 2026-10-19 |
| この講義のガス、残高、ブロックの時刻、長さ | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Contractsの節 State MutabilityのView Functions、Pure Functions）
- EIP-214 New opcode STATICCALL: https://eips.ethereum.org/EIPS/eip-214
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
