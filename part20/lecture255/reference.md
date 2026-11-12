# 第255講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

付録のテスト結果、サイズ、ガス、lintの警告は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| このバージョンのテスト | 直接実行（`forge test --offline`、`--match-contract ... -vv`） | 2026-10-21 |
| Marketのサイズ | 直接実行（`forge build --offline --sizes`） | 2026-10-21 |
| 測った呼び出し五つ | 直接実行（`test/Gas.t.sol`のログ） | 2026-10-21 |
| forge lint | 直接実行（`forge lint --offline src`） | 2026-10-21 |
| 切り捨て・切り上げの箇所 | `src/Market.sol`で`MarketMath.mulDivDown`・`MarketMath.mulDivUp`を数えた | 2026-10-21 |
| 講義用の設計値 | `src/Market.sol`の定数、`design/architecture.md` | 2026-10-21 |

## 参考資料

- 前のバージョン（通しプロジェクトMarket第53章末のバージョン）のテスト：上限・1年の利息・30分平均・半分の清算・借金の消去の値（`Borrow.t.sol`、`Liquidate.t.sol`、`BadDebt.t.sol`）
- EIP-20 Token Standard: https://eips.ethereum.org/EIPS/eip-20
- Foundry lintの規則（unused-return、reentrancy-eventsなど）: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
