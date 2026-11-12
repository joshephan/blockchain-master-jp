# 第104講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、サイズ、ガス、アドレスは、すべて上の環境で直接実行した結果である（`forge test -vvvv`、`forge build --sizes`、`forge test --gas-report`、ローカルのanvilでの`cast send`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| modifierのオーバーライドは`virtual`のときだけ、複数のmodifierは書いた順に評価、本体を実行しないことがある | Solidity公式ドキュメント v0.8.36、Contractsの節 Function Modifiers | 2026-10-19 |
| オーバーライドのときに`override`が必須（0.6.0） | Solidity公式ドキュメント、0.6.0 Breaking Changes | 2026-10-19 |
| virtualのmodifierの廃止予定 | Solidity公式ドキュメント v0.8.36、Inheritanceの節 Modifier Overriding、solc 0.8.30のビルド | 2026-10-19 |
| onlyOwnerが`_checkOwner`を呼ぶ形 | OpenZeppelin Contracts 5.4.0 `contracts/access/Ownable.sol` | 2026-10-19 |
| サイズ、ガス、アドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Contractsの節 Function Modifiers、Inheritanceの節 Modifier Overriding、0.6.0 Breaking Changes）
- OpenZeppelin Contracts 5.4.0、`contracts/access/Ownable.sol`
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
