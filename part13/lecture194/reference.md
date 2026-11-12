# 第194講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果、ガス、ローカルのanvilのアドレスとcastの出力は、すべて上の環境で直接実行した結果である（外部への接続なし、anvilの既定のテスト用の鍵だけを使用）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Uniswap v2ホワイトペーパーの引用位置、手数料30bp | Uniswap v2 Coreホワイトペーパー1節、2.2節、2.2.1節、3.2節 | 2026-10-21 |
| Foundry・solc・OpenZeppelinのバージョン | `forge --version`、`foundry.toml`、`lib/openzeppelin-contracts` | 2026-10-21 |
| anvilのアドレス・ガス | ローカルのanvilで`forge create`、`cast send`、`cast call`（直接実行） | 2026-10-21 |
| テストの数とガス | `forge test --offline`（直接実行） | 2026-10-21 |

## 参考資料

- Hayden Adams, Noah Zinsmeister, Dan Robinson, "Uniswap v2 Core", 2020年3月: https://uniswap.org/whitepaper.pdf
  - 1節 Introduction（v1の定積の公式、積が減らない不変条件、30bpの手数料）
  - 2.2節（ブロックごとの価格の累積、時間加重平均）
  - 2.2.1節（残高をuint112に保存）
  - 3.2節（記録した残高と今の残高を比べて、受け取った量を数える）
- OpenZeppelin Contracts 5.4.0 `utils/math/Math.sol`（`mulDiv`、`Rounding.Ceil`）
- EIP-20 トークン標準: https://eips.ethereum.org/EIPS/eip-20
- Foundry公式ドキュメント: https://getfoundry.sh/
