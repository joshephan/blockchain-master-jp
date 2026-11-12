# 第95講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、バイトの長さ、ガス、アドレスは、すべて上の環境で直接実行した結果である（ローカルのanvil、`forge test`、`forge inspect`、`cast send --json`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 状態変数の既定はinternal、external関数は中からは`this.f()`でだけ、internal関数はABIにないので内部の型の引数を受け取れる、private・internalの値もブロックチェーンの外では誰にでも見えるという警告 | Solidity公式ドキュメント v0.8.36、Contractsの節 Visibility and Getters | 2026-10-19 |
| 関数の可視性の必須化（0.4.17、0.4.21、0.5.0） | Solidity Changelog、Solidityドキュメント v0.4.24、v0.8.36 `050-breaking-changes.rst` | 2026-10-19 |
| public関数のcalldataの引数（0.6.9） | Solidity Changelog | 2026-10-19 |
| SWC-100 | SWC Registry、Function Default Visibility | 2026-10-19 |
| ガス、バイトの長さ、アドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Contractsの節 Visibility and Getters）
- Solidity 0.5.0 Breaking Changes: https://docs.soliditylang.org/en/v0.8.36/050-breaking-changes.html
- Solidityドキュメント v0.4.24（関数の既定の可視性が`public`だった時代のドキュメント）
- Solidity Changelog（0.4.17、0.4.21、0.5.0、0.6.9）
- SWC-100 Function Default Visibility: https://swcregistry.io/docs/SWC-100
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
