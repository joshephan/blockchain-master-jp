# 第141講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | `solc --version` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| EVMのバージョン | osaka | foundry.toml | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| セレクタ | `forge inspect src/Abi141.sol:Abi141 methodIdentifiers`、`solc --hashes`、`cast sig`、`cast keccak` | 2026-10-20 |
| ドキュメントの例五つ | `cast calldata`で作り、`docs/abi-spec.rst`の16進数と比較 | 2026-10-20 |
| デモのバイトと値 | デモのプロジェクトで`forge test -vv`（Abi141・Call141・Coder141・Er141・Ev141・Key141・Packed141）、`cast abi-encode` | 2026-10-20 |
| イベントのトピック | `forge inspect src/Ev141.sol:Ev141 events`、`solc --hashes`、`cast keccak` | 2026-10-20 |
| エラー番号 | 同じファイルを`solc --standard-json`に入れたerrorCode（1860・1406・1855・9578） | 2026-10-20 |
| MarketのABI | `forge inspect src/Market.sol:Market abi --json`の項目・欄・internalTypeを数える | 2026-10-20 |
| サイズ・テスト・ガス | `forge build --sizes`、`forge test`（default・debug・ir）、新しいanvilにデプロイして順に送ったレシートのgasUsed | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Contract ABI Specification（Basic Design、Function Selector、Types、Formal Specification、Examples、Events、Errors、JSON、Strict Encoding Mode、Non-standard Packed Mode、Encoding of Indexed Event Parameters）: https://docs.soliditylang.org/en/v0.8.36/abi-spec.html
- 同じドキュメントのソース`docs/abi-spec.rst`: https://github.com/argotorg/solidity/blob/v0.8.36/docs/abi-spec.rst
- Foundry公式ドキュメント（`cast calldata`、`cast sig`、`cast abi-encode`、`forge inspect`）: https://getfoundry.sh/
