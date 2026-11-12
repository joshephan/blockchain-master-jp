# 第134講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| EVMのバージョン | osaka | foundry.toml、メタデータのsettings | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| サイズ・テスト | `forge build --sizes`、`forge test`、`FOUNDRY_PROFILE=ir`をつけた同じコマンド | 2026-10-20 |
| memoryguard | `forge inspect --via-ir test/Assembly.t.sol:MarketSlots irOptimized`、`RawCaller`で同じコマンド | 2026-10-20 |
| 四つのバージョンのガス | バージョンごとに新しいanvilにデプロイし、`cast send`で送ったレシートのgasUsedを直接測定 | 2026-10-20 |
| メタデータのsettings、storageLayout・ABI・セレクタ | out / out-irの成果物 | 2026-10-20 |
| CREATE2のアドレス | `cast keccak`、`cast create2`の直接実行 | 2026-10-20 |
| pcとソースマップ | forgeのbuild-infoの入力をsolc 0.8.30 `--standard-json`にviaIR false / trueで入れてビルド、anvil（`--steps-tracing`）にデプロイしてから`cast rpc debug_traceTransaction` | 2026-10-20 |
| Backtrace | `forge test --match-path test/Fail.t.sol -vvvvv`、同じコマンドに`--via-ir` | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Solidity IR-based Codegen Changes: https://docs.soliditylang.org/en/v0.8.36/ir-breaking-changes.html
- Solidity公式ドキュメント v0.8.36、Using the Compiler（Standard JSONの`viaIR`の欄）: https://docs.soliditylang.org/en/v0.8.36/using-the-compiler.html
- Solidity公式ドキュメント v0.8.36、Source Mappings: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/source_mappings.rst
- Foundry公式ドキュメント（プロファイル、`FOUNDRY_PROFILE`）: https://getfoundry.sh/
