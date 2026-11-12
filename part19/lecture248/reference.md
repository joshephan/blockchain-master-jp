# 第248講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml`、`solc --version` | 2026-10-21 |

付録の警告、テスト結果、ガスは、すべて上の環境で直接実行した結果である。Move側はツールをインストールしておらず、引用したMoveのコードと規則は下のドキュメントから移した。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Move本の元のバージョン | move-language/move コミットc453c909（アーカイブされたリポジトリ） | 2024-05-04 |
| Move本のSui側のバージョン | MystenLabs/move-book コミットd060f943 | 2026-08-31 |
| solcの警告 | 直接実行（`solc --error-codes --via-ir --optimize --evm-version osaka --bin`） | 2026-10-21 |
| 不変条件の結果、テストのガス | 直接実行（`forge test --offline -vv --fuzz-seed 0x248`） | 2026-10-21 |

## 参考資料

- Move本の元のバージョン（move-language/move コミットc453c909）：`introduction.md`（リソース型、Diem）、`abilities.md`（四つの能力copy・drop・store・key）、`variables.md`（moveとcopy）、`structs-and-resources.md`（リソースの定義、モジュールの中でだけ分解、Coinの例）、`bytecode-verifier-README.md`（Resource Safety）、`integers.md`（算術エラーはabort）、`global-storage-structure.md`、`global-storage-operators.md`（`move_to`、`move_from`）
- Move本のSui側のバージョン（MystenLabs/move-book コミットd060f943、reference）：`abilities.md`（Suiでは`key`はオブジェクト）、`abilities_object.md`（オブジェクトの最初の欄は`id: sui::object::UID`、オブジェクトに`copy`・`drop`はない）
- Foundry公式ドキュメント（不変条件テスト）: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
