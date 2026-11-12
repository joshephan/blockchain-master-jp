# 第103講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、サイズ、ガス、アドレスは、すべて上の環境で直接実行した結果である（`forge build --sizes`、`forge test -vvvv`、ローカルのanvilでの`cast send --json`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 複数のmodifierは書いた順に評価、関数の引数は明示的にだけ渡る、`_`は何回も置けて出てくる場所ごとに本体に置き換わる、明示的な`return`はそのmodifierか本体だけを抜けて前のmodifierの`_`のあとに続く、modifierの引数には任意の式 | Solidity公式ドキュメント v0.8.36、Contractsの節 Function Modifiers | 2026-10-19 |
| `_`がないときのエラー、`return`が`_`のあとの行を飛ばさない（0.4.0） | Solidity Changelog.md | 2026-10-19 |
| 第48講のサイズ | 第48講の付録 | 2026-10-19 |
| サイズ、ガス、アドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Contractsの節 Function Modifiers）
- Solidity Changelog（0.4.0）
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
