# 第253講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

付録のテスト結果とセレクタは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| このバージョンのテスト | 直接実行（`forge test --offline`） | 2026-10-21 |
| IMarketのセレクタ・インターフェースID | 直接実行（`forge inspect ... methodIdentifiers`、`cast sig`、InterfaceTest） | 2026-10-21 |
| 前のバージョンの数字 | 通しプロジェクトMarket第53章末のバージョンのソース（`wc -l`、コメント行の数え上げ、テスト関数の数え上げ） | 2026-10-21 |
| 監査範囲 | 第53章末の監査範囲の表 | 2026-10-21 |
| 前のバージョンのガス | 前のバージョンのガス記録（deposit100）、第53章の清算のガスのデモ（資産二つ） | 2026-10-21 |
| 講義用の設計値 | `design/requirements.md` | 2026-10-21 |

## 参考資料

- 判別ワークシート（第3講）：四つの質問、コストの質問、反証の項目と使い方
- 前のバージョンの信頼の前提の「管理者の鍵」の行と、第50章の自己監査の指摘事項七つ（L-01〜L-03、I-01〜I-04）
- EIP-20 Token Standard: https://eips.ethereum.org/EIPS/eip-20
- Foundry公式ドキュメント（`vm.skip`、`forge snapshot --check`、`forge lint`）: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
