# 第254講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

付録のテスト結果は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| このバージョンのテスト | 直接実行（`forge test --offline`、`--match-contract MathTest -vv`） | 2026-10-21 |
| 平らなバージョン | 第250講の結果の表、第252講の言語の前提の行 | 2026-10-21 |
| 前のバージョンの清算のガス | 第53章の清算のガスのデモ（資産数を変えて測定） | 2026-10-21 |
| 講義用の設計値 | `design/architecture.md` 10節D-04 | 2026-10-21 |

## 参考資料

- 設計ドキュメントの土台：前のバージョン（通しプロジェクトMarket第53章末のバージョン）のスロットマップ、権限リスト、信頼の前提、攻撃の地図、不変条件の表
- EIP-20 Token Standard: https://eips.ethereum.org/EIPS/eip-20
- Solidity公式ドキュメント v0.8.36（ストレージの配置、ライブラリ）: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント: https://getfoundry.sh/
