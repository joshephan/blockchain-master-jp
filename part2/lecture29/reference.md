# 第29講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-18 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-18 |

付録のガスの数字と出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| vmのアドレス | `cast keccak "hevm cheat code"`、テストの中の`address(vm)` | 2026-10-18 |
| forgeの中のvmのアドレスのコード | テストの中の`address(vm).code` | 2026-10-18 |
| anvilのvmのアドレスのコード、warp(100)の結果 | `cast code`、`cast send`、`cast block` | 2026-10-18 |
| forgeのテストのデフォルト値 | Probeテストのログ | 2026-10-18 |
| テストのガスの値 | `forge test --offline` | 2026-10-18 |
| セレクタ | `cast sig` | 2026-10-18 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-stdリポジトリ: https://github.com/foundry-rs/forge-std（`Test`、`console`、`Vm`）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
