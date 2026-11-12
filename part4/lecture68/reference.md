# 第68講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のエラーの原文、ガスの数字、欄の値は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| bytes・stringのルール | Solidity公式ドキュメントv0.8.36、Typesの節のBytes and string as Arrays、The functions bytes.concat and string.concat | 2026-10-19 |
| `bytes.concat`の導入 | Solidity Changelog.md 0.8.4 Language Features | 2026-10-19 |
| `string.concat` | Solidity Changelog.md 0.8.12 Bugfixes、Typesの節の例 | 2026-10-19 |
| cast calldataの長さ | `cast calldata`の出力（直接実行） | 2026-10-19 |
| メモリで作るgasUsed、TagsのaddのgasUsed | anvilでの`cast send`のレシート（直接実行） | 2026-10-19 |
| MarketのデプロイのgasUsed | anvilでの`cast receipt`（直接実行） | 2026-10-19 |
| テストのガス | `forge test -vv`（直接実行） | 2026-10-19 |
| 第59講のLabelのsetLabelのgasUsed | 第59講の実習の測定値 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のBytes and string as Arrays、The functions bytes.concat and string.concat: https://docs.soliditylang.org/en/v0.8.36/
- Solidity Changelog（0.8.4、0.8.12）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント: https://getfoundry.sh/
