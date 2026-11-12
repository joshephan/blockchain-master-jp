# 第195講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果とガスは、上の環境で直接実行した結果である（anvilなし、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| テストのガス、損失の表の値 | `forge test --offline --match-contract Il195Test`、`--match-test test_lpTokenDepositsLikeAnyToken`（直接実行） | 2026-10-21 |
| 外の価格 | `test/Il195.t.sol`が決めた数字 | 2026-10-21 |
| 手数料30bp | ToyAmm feeBps 30、Uniswap v2 Coreホワイトペーパー1節 | 2026-10-21 |
| 損失の式 | test_lossTableの値で確認 | 2026-10-21 |
| 最初の提供の持ち分 | Uniswap v2 Coreホワイトペーパー3.4節 | 2020-03 |

## 参考資料

- Hayden Adams, Noah Zinsmeister, Dan Robinson, "Uniswap v2 Core", 2020年3月: https://uniswap.org/whitepaper.pdf
  - 1節（手数料30bp）、3.4節（最初の提供の持ち分を、入れた量の幾何平均で発行）
- OpenZeppelin Contracts 5.4.0 `utils/math/Math.sol`（`sqrt`、`min`）
- EIP-20 トークン標準（LPトークンもERC-20）: https://eips.ethereum.org/EIPS/eip-20
- Foundry公式ドキュメント: https://getfoundry.sh/
