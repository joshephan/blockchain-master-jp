# 第228講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `mev/foundry.toml`、`market264/foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のテスト結果、ガス、ログ、エラーはすべて上の環境で直接実行した結果である。anvilも外部への接続も使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Guard228のガス・ログ | 直接実行（`forge test --offline --match-contract Guard228Test -vv`、トレースは`-vvvv`） | 2026-10-21 |
| Order228のガス・ログ | 直接実行（`forge test --offline --match-contract Order228Test -vv`） | 2026-10-21 |
| Marketのテスト数 | 直接実行（`forge test --offline`） | 2026-10-21 |
| 第225講の二つのほうの値 | 第225講の直接実行の結果 | 2026-10-21 |

## 参考資料

- 通しプロジェクトMarketのキャップストーン最終バージョンの設計文書`design/architecture.md` 6節 T-04（順番）、7節 攻撃マップ（順番操作の行）
- `IMarket.sol` 131行目 `NotLiquidatable(limit, debt)`
- Foundry 公式ドキュメント: https://getfoundry.sh/
