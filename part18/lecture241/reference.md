# 第241講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| Python | 3.12、標準ライブラリのみ | `python --version` | 2026-10-21 |
| テスト | 143個が通る（BreakerTest 7個）、`forge fmt --check`が通る | `forge test --offline` | 2026-10-21 |
| コントラクトの大きさ | Market 9,006 / 9,233、FeeSwitchToken 892 / 960、MultiSigAdmin 2,559 / 3,101バイト | `forge build --offline --sizes` | 2026-10-21 |

付録の警報、ガス、取引のハッシュ、ブロック番号はすべて、ローカルのanvilとローカルの警報受信サーバーで直接実行した結果である。署名はanvilのデフォルトのテスト用の鍵だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 監視サービスの名前 | Forta文書（docs.forta.network）、OpenZeppelin Monitor文書（docs.openzeppelin.com/monitor）、Tenderly Alerts文書（docs.tenderly.co/alerts）。名前の確認のみ | 2026-10-21 |
| 通しプロジェクトのバージョン、大きさ | 直接実行（`forge test --offline`、`forge build --offline --sizes`） | 2026-10-21 |
| デモのガス | 直接実行 | 2026-10-21 |

## 参考資料

- Forta、OpenZeppelin Monitor、Tenderly Alertsの公式文書（名前のみ、推薦・比較なし）
- Foundry 公式ドキュメント（`anvil_setStorageAt`、`cast index`、`cast call`）: https://getfoundry.sh/
