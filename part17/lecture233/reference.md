# 第233講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| anvil | `--hardfork osaka`、チェーン番号31337、デフォルトのテスト用アカウント | `anvil`の起動画面 | 2026-10-21 |

付録のテスト結果、ガス、エラー、calldataはすべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| シーケンサーの運営方式、やり直せる入金・脱出の道の名前、L2の段階の分類 | 各実装と分類サイトの公開資料（名前のみ） | 2026-10-21 |
| rollupのテスト・anvilの値 | 直接実行（`forge test --offline --match-contract "Inbox233Test\|Exit233Test" -vv`、anvilでcast `send`・`call`、`evm_increaseTime`） | 2026-10-21 |
| Marketのテスト・calldata | 直接実行（`forge test --offline --match-test ...`、`cast calldata`） | 2026-10-21 |

## 参考資料

- やり直せる入金：Arbitrum retryable ticket（名前のみ）
- 脱出の道：StarkEx escape hatch、zkSync priority queue（名前のみ）
- L2の段階の分類：L2BEAT Stages（名前のみ）
- Foundry 公式ドキュメント: https://getfoundry.sh/
