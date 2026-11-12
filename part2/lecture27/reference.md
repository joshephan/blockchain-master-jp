# 第27講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil、cast、forge） | 1.8.3 (cae51ad458 2026-09-15) | `anvil --version`など | 2026-10-18 |
| solc | 0.8.30 | `forge build --use 0.8.30 --offline` | 2026-10-18 |
| シェル | Git Bash（Windows） | 直接実行 | 2026-10-18 |

付録の出力は、すべて上記の環境で直接実行した結果である。外部への接続はない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| anvilのデフォルトアカウント数、テスト残高、チェーンID、Base Fee、Gas Limit、ニーモニック | anvilの起動出力 | 2026-10-18 |
| ブロックのtimestamp、state.jsonのサイズ、ブロックハッシュ | 直接実行 | 2026-10-18 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- anvil専用のRPCコマンド: `evm_mine`、`anvil_mine`、`anvil_setBalance`、`anvil_setStorageAt`、`anvil_impersonateAccount`、`evm_increaseTime`、`evm_setNextBlockTimestamp`、`evm_snapshot`、`evm_revert`、`anvil_dropTransaction`、`txpool_status`
