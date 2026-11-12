# 第63講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の警告・エラーの原文、ガスの数字、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 代入のルール | Solidity公式ドキュメントv0.8.36、Typesの節のData location and assignment behavior | 2026-10-19 |
| markVotedのgasUsed | anvilでの`cast send`のレシート（直接実行） | 2026-10-19 |
| ビルドの警告 | `forge build --offline --force`（直接実行） | 2026-10-19 |
| エラーの原文 | solc 0.8.30の出力（直接実行） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のData location and assignment behavior: https://docs.soliditylang.org/en/v0.8.36/
- Solidity公式ドキュメントv0.8.36、Solidity by Exampleの節のVotingの例（`src/Ballot.sol`の原文）
- Foundry公式ドキュメント: https://getfoundry.sh/
