# 第249講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |

付録のテスト結果、サイズ、ガスは、すべて上の環境で直接実行した結果である。CosmWasm側はツールをインストールしておらず、引用したRustのコードと規則は下のドキュメントから移した。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| CosmWasmドキュメントのコピー | CosmWasm/docs コミットf6672ac0 | 2025-12-03 |
| cosmwasmリポジトリ、最新リリース | CosmWasm/cosmwasm コミット160f8c53、リリース一覧 | 2026-10-21 |
| wasmd | CosmWasm/wasmd コミット64b9bea7、`proto/cosmwasm/wasm/v1/tx.proto` | 2026-10-21 |
| Solanaドキュメントのコピー | solana-foundation/solana-com コミット0bcf693a | 2026-10-20 |
| migrate_versionマクロ | CosmWasmドキュメント`core_entrypoints_migrate.mdx` | 2025-12-03 |
| actor249のサイズ | 直接実行（`forge build --offline --sizes`） | 2026-10-21 |
| actor249のテストのガス | 直接実行（`forge test --offline -vv`） | 2026-10-21 |

## 参考資料

- CosmWasmドキュメント（CosmWasm/docs コミットf6672ac0）：`core.mdx`（ContractとInstance）、`core_architecture_actor-model.mdx`（アクターモデル、郵便受けの段落、"Why can't I just call another contract?"）、`core_architecture_semantics.mdx`（CEIを強制する、サブメッセージの深さ優先の順番）、`core_architecture_transactions.mdx`（メッセージ一つが失敗すると取引全体を巻き戻す）、`core_entrypoints.mdx`、`core_entrypoints_query.mdx`（queryはストレージを読むだけ）、`core_entrypoints_reply.mdx`（`ReplyOn::Success`がデフォルト値）、`core_entrypoints_migrate.mdx`、`core_architecture_gas.mdx`
- CosmWasm/wasmd コミット64b9bea7 `proto/cosmwasm/wasm/v1/tx.proto`（"Admin is an optional address that can execute migrations"）
- Solanaドキュメント（solana-foundation/solana-com コミット0bcf693a）`programs_index.mdx`（loader-v3のアップグレード権限）
- Foundry公式ドキュメント: https://getfoundry.sh/
