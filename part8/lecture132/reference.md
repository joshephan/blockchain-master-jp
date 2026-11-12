# 第132講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| EVMのバージョン | forgeのビルドはosaka、solcを直接呼ぶ場合の既定値はprague | foundry.toml、メタデータのsettings | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Backtraceの行 | `forge test -vvvvv`、`forge test --optimize --optimizer-runs 200 -vvvvv`の直接実行 | 2026-10-20 |
| ソースマップの数字 | `solc --combined-json srcmap-runtime,bin-runtime,generated-sources-runtime`、`solc --asm`、forgeの成果物`out/Market.sol/Market.json`のdeployedBytecode.sourceMapと`out/build-info/*.json`のsource_id_to_path | 2026-10-20 |
| pcとリバートデータ | anvil（`--steps-tracing`）にデプロイしてから`cast send`、`cast rpc debug_traceTransaction`の直接実行 | 2026-10-20 |
| optimizerを入れたビルド | `forge verify-contract --show-standard-json-input`が出した入力のsettings.optimizerを`{"enabled": true, "runs": 200}`に変えて、solc `--standard-json`に入れる | 2026-10-20 |
| サイズ・テストの数 | `forge build --sizes`、`forge test` | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Source Mappings（`s:l:f:j:m`、圧縮の規則、-1、generatedSources、modifier depth）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/source_mappings.rst
- Solidity公式ドキュメント v0.8.36、Using the Compiler（Standard JSONの出力のsourceMap・generatedSourcesの欄）: https://docs.soliditylang.org/en/v0.8.36/using-the-compiler.html
- Solidity公式ドキュメント v0.8.36、Contract Metadata（outputの欄）: https://docs.soliditylang.org/en/v0.8.36/metadata.html
- Foundry公式ドキュメント: https://getfoundry.sh/
