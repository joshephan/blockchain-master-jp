# 第133講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-20 |
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-20 |
| EVMのバージョン | forgeのビルドはosaka、solcを直接呼ぶ場合の既定値はprague | foundry.toml | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| via-IRの既定値 | Solidityドキュメント v0.8.36 Using the CompilerのStandard JSONの`viaIR`の欄の注釈、オプションなしの`solc --bin`の直接実行 | 2026-10-20 |
| Storeのサイズとasm・IR | `solc --bin`・`--via-ir --bin`・`--bin-runtime`・`--asm`・`--ir`・`--strict-assembly --bin`・`--combined-json generated-sources-runtime,srcmap-runtime`の直接実行 | 2026-10-20 |
| Marketのサイズ四つ | Marketのコードはそのままで、foundry.tomlの`via_ir`・`optimizer`の2行だけを変えた四つのバージョンで`forge build --sizes` | 2026-10-20 |
| ビルドの時間 | `forge build --offline --force`のsolcの時間の直接実行 | 2026-10-20 |
| ドキュメントの例の値 | デモのプロジェクトで`forge test --match-path test/Diff133.t.sol -vv`、同じコマンドに`--via-ir` | 2026-10-20 |
| MarketのIR | `forge inspect src/Market.sol:Market ir` | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Solidity IR-based Codegen Changes（二つの方法、導入の理由、初期化の順番、structのdelete、modifier、計算の順番、addmod・mulmod、フリーメモリポインタの上限、Cleanup）: https://docs.soliditylang.org/en/v0.8.36/ir-breaking-changes.html
- Solidity公式ドキュメント v0.8.36、Using the Compiler（Standard JSONの`viaIR`の欄）: https://docs.soliditylang.org/en/v0.8.36/using-the-compiler.html
- Solidity公式ドキュメント v0.8.36、The Optimizer（legacy pipeline / IR-based pipeline）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/optimizer.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
