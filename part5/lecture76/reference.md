# 第76講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| anvilの既定のハードフォーク | Bpo1 | `cast rpc anvil_nodeInfo` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力は、すべて上の環境で直接実行した結果である。anvilの時刻に結びついた値は、実行ごとに変わる。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Solidityのバージョンごとの導入・削除 | Solidityリポジトリ v0.8.36 Changelog.md | 2026-10-19 |
| メインネットのブロック時刻の規則とブロックの例 | イーサリアムのコンセンサス仕様、公開RPC（https://ethereum-rpc.publicnode.com）に`cast block 26225110` | 2026-10-19 |
| EIP-2935のシステムコントラクト | anvilで`cast call`、公開RPCで`cast code` | 2026-10-19 |
| anvilの既定値 | `cast rpc anvil_nodeInfo`、`cast block latest` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variablesの節のBlock and Transaction Properties: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
  - `blockhash`は直近256ブロックにしか答えず、それ以外は0
  - `block.difficulty`はparis以降、`block.prevrandao`の非推奨の別名
  - トランザクションなしでノード上で実行すると、`block.*`、`tx.*`は実行する側が入れる任意の値になりうる
  - `msg.gas`は0.5.0で削除されて`gasleft()`に、`now`は0.7.0で削除
- 同じドキュメントのrst原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- Solidityの変更履歴 v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- 締め切りのmodifier `onlyBefore`・`onlyAfter`: Solidity公式ドキュメント v0.8.36 Solidity by Exampleのブラインドオークションの例
- EIP-4399 (PREVRANDAO): https://eips.ethereum.org/EIPS/eip-4399
- EIP-2935（直近のブロックハッシュを状態に保存）: https://eips.ethereum.org/EIPS/eip-2935
- Foundry公式ドキュメント: https://getfoundry.sh/
