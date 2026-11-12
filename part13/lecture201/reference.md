# 第201講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果、ガス、トレースは、上の環境で直接実行した結果である（anvilなし、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| おもちゃの値、償還の表の仮定、VaultUSDの値 | `test/Algo201.t.sol`、`src/VaultUSD.sol` | 2026-10-21 |
| テストのガス | `forge test --offline --match-contract Algo201Test -vv`（直接実行） | 2026-10-21 |
| MarketのpriceOf | 通しプロジェクトMarket `src/Market.sol` 504行目 | 2026-10-21 |
| 事件の年月 | Terra USTの崩壊、2022年5月 | 2026-10-21 |

## 参考資料

- Terra UST、2022年5月：担保の金庫なしに、対になるトークンLUNAを新しく発行して1ドルの償還を約束したアルゴリズム型ステーブルコイン。償還が集中するとLUNAの発行が膨らみ、二つが一緒に崩れた事件（損失額・時間帯ごとの価格は載せない）
- Foundry公式ドキュメント: https://getfoundry.sh/
- EIP-20 トークン標準: https://eips.ethereum.org/EIPS/eip-20
