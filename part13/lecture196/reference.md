# 第196講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果、ガス、トレースは、上の環境で直接実行した結果である（anvilなし、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| v3ホワイトペーパーの引用位置、手数料の等級、`sqrtPriceX96` | Uniswap v3 Coreホワイトペーパー1節、2節、3.1節、5.2節、6.1節、6.2節 Table 1、6.2.1節、6.3.1節 | 2026-10-21 |
| OpenZeppelinのバージョン | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |
| テストのガス | `forge test --offline --match-contract Range196Test`・`Extra196Test`（直接実行） | 2026-10-21 |

## 参考資料

- Hayden Adams, Noah Zinsmeister, Moody Salem, River Keefer, Dan Robinson, "Uniswap v3 Core", 2021年3月
  - 2節（集中流動性の定義、範囲を外れたポジション）、5.2節（Geometric Mean Price Oracle）、6.1節 式(6.1)（ティックの価格1.0001^i）、6.2節 Table 1（Global State）、6.2.1節（Lと√P）、6.3.1節（Crossing a Tick）
- Hayden Adams, Noah Zinsmeister, Dan Robinson, "Uniswap v2 Core", 2020年3月（v3ホワイトペーパーの参考文献[1]）: https://uniswap.org/whitepaper.pdf
- OpenZeppelin Contracts 5.4.0 `utils/math/Math.sol`（`mulDiv`、`mul512`、`Rounding.Ceil`）
- Foundry公式ドキュメント: https://getfoundry.sh/
