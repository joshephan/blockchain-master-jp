# 第166講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30、via-IRオン・optimizerオン（runs 200）・evm osaka | `code/market/foundry.toml` | 2026-10-20 |
| Market | 第42章の終わりのバージョン（第164講のバージョン）のまま | 第164講のバージョンと比較 | 2026-10-20 |

付録のガス、ブロック内の位置、テスト結果は、すべて上の環境で直接実行した結果である。外部への接続はなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| anvilの設定と順番のルール | anvilの実行オプション（`--order fees`）と直接実行 | 2026-10-20 |
| 手数料の値、取引のガス、ブロック内の位置 | 直接実行（`cast send --gas-price --priority-gas-price`、`cast receipt --json`） | 2026-10-20 |
| テストのガス | 直接実行（`forge test --match-contract "PullTest|AccessTest|GuardsTest|StatusTableTest"`） | 2026-10-20 |
| 行番号 | Marketのソースのgrep五つ | 2026-10-20 |

## 参考資料

- Foundry公式ドキュメント（forge、cast、anvil）: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
