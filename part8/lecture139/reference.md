# 第139講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | `solc --version` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| EVMのバージョン | osaka（forgeのビルド） | foundry.toml | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| MarketのYulの行数 | `forge inspect src/Market.sol:Market ir`・`irOptimized`（optimizerを切る / 入れるバージョン）を`wc -l`、`grep -c "function "` | 2026-10-20 |
| DocOpt139・Dedup139・Runs139・Loop139・Storeのサイズ | solc 0.8.30のStandard JSONと`solc --asm --optimize`、`--optimize-runs`の直接実行 | 2026-10-20 |
| Marketの命令の数 | optimizerを切る / 入れる成果物のランタイムを先頭から命令に分けて数える | 2026-10-20 |
| Marketの設定ごとのサイズ・Backtrace | 第139講のバージョンをコピーし、foundry.tomlのoptimizerの欄と`optimizer_details`だけを変えたバージョンごとに`forge build --sizes`、`forge test`、`Fail.t.sol -vvvvv` | 2026-10-20 |
| Marketのガス | バージョンごとに新しいanvilにデプロイし、同じ順序で送ったレシートのgasUsed | 2026-10-20 |
| detailsの打ち間違いとメタデータのsettings | `solc --standard-json`の直接実行 | 2026-10-20 |
| 既定のステップの順序の文字列 | メタデータの`settings.optimizer.details.yulDetails.optimizerSteps` | 2026-10-20 |
| Opt124の順序ごと、Deepのmemoryguard | `solc --ir-optimized --optimize --yul-optimizations '…'`、`solc --via-ir --ir-optimized`・`--bin-runtime` | 2026-10-20 |
| デモのプロジェクトのテストの値 | プロファイルごとに`forge test --match-path test/Dedup139.t.sol -vvvvv`、`test/Loop139.t.sol -vv` | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、The Optimizer（三つの層、opcodeオプティマイザと例、Simple Inlining、Yulオプティマイザ・ステップの表・Selecting Optimizations、Unchecked Loop Increment）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/optimizer.rst
- Solidity公式ドキュメント v0.8.36、Using the Compiler（Optimizer Options、Standard JSONの`optimizer`の欄の注釈）: https://docs.soliditylang.org/en/v0.8.36/using-the-compiler.html
- Solidity公式ドキュメント v0.8.36、Yul（Yul Optimizer）: https://docs.soliditylang.org/en/v0.8.36/yul.html
- Foundry公式ドキュメント（プロファイル、`optimizer_details`、`forge inspect`）: https://getfoundry.sh/
