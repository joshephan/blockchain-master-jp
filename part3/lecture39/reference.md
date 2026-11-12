# 第39講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-19 |
| ローカルチェーン | anvil `--base-fee 0 --gas-price 0 --no-priority-fee` | 直接実行 | 2026-10-19 |

付録の残高、ガス、トレースは、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 例の原文と送金方式 | Solidityリポジトリのタグv0.8.36の`docs/examples/safe-remote.rst` | 2026-10-19 |
| 失敗したreceived()のトランザクション | 直接実行（anvilのレシート） | 2026-10-19 |
| forge testのガス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Solidity by Example（Safe Remote Purchase）: https://docs.soliditylang.org/en/v0.8.36/
- 例の元ファイル: https://github.com/argotorg/solidity/blob/v0.8.36/docs/examples/safe-remote.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
