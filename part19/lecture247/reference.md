# 第247講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| anvil | ブロック間隔1秒、デフォルトのテスト用キー | `anvil`の起動オプション | 2026-10-21 |

付録のテスト結果、サイズ、ガス、アクセスリストは、すべて上の環境で直接実行した結果である。Solana・Anchor側はツールをインストールしておらず、引用したRustのコードと限度の値は下のドキュメントのコピーから移した。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Solanaドキュメントのコピー | solana-foundation/solana-com コミット0bcf693a | 2026-10-20 |
| ドキュメントが指すソースのバージョン | ドキュメント内のリンク（agave v3.1.8、solana-sdk clock@v2.2.3） | 2026-10-20 |
| Anchorドキュメント・ソースのコピー | solana-foundation/anchor コミット0d36a0b9 | 2026-10-20 |
| 基本手数料、取引一つあたりのコンピュートユニット上限 | Solanaドキュメント`index.mdx`のFeesカード | 2026-10-20 |
| アカウントのdataの最大、命令一つあたりのdata増加の限度、保存の保証金の式 | Solanaドキュメント`accounts_index.mdx`の限度表 | 2026-10-20 |
| 命令スタックの深さ | Solanaドキュメント`cpi_index.mdx`の限度表 | 2026-10-20 |
| Counterアカウントの保証金の計算 | 上の式で計算（移行案内の記事の`space = 8 + Counter::INIT_SPACE`） | 2026-10-21 |
| 移行案内の記事 | Solanaドキュメント`evm-to-svm.mdx`の冒頭 | 2026-10-20 |
| Cardanoドキュメント | docs.cardano.org "Extended UTXO model" | 2026-10-21 |
| access-list、Marketのガス | 直接実行（anvilにMarketのコピーをデプロイ、`cast access-list`、`cast index address`） | 2026-10-21 |
| acct247のサイズ・ガス | 直接実行（`forge build --offline --sizes`、`forge test`、anvil） | 2026-10-21 |

## 参考資料

- Solanaドキュメント（solana-foundation/solana-com コミット0bcf693a、`apps/docs/content/docs/en/core/`）：`accounts_index.mdx`、`accounts_account-structure.mdx`、`accounts_account-types.mdx`、`accounts_modification-rules.mdx`（変更規則の表 "Only the owner can modify data"）、`programs_index.mdx`、`programs_program-execution.mdx`、`instructions_index.mdx`（Instruction、AccountMeta、並列実行の原文）、`cpi_index.mdx`（MissingAccount、PrivilegeEscalation、再入の規則 "A->B->A returns ReentrancyNotAllowed"）、`pda_pda-derivation.mdx`（PDA計算）、`index.mdx`
- Solana, "Moving from Ethereum Development to Solana", 2024-04-16（`evm-to-svm.mdx`、Counterの二つのバージョン、"Solana's smart contracts are entirely stateless. State must be passed to accounts for them to execute on."）
- Anchor（solana-foundation/anchor コミット0d36a0b9）：`account-types.mdx`（`Account<'info, T>`、`UncheckedAccount<'info>`）、`lang/src/accounts/account.rs`（"Account checks that `Account.info.owner == T::owner()`."）
- SIMD-0268（CPIの深さの限度を9に増やす提案）
- Cardanoドキュメント "Extended UTXO model"、docs.cardano.org（取引の検証が取引と入力だけに依存するので並列検証が可能）
- EIP-1167 Minimal Proxy Contract: https://eips.ethereum.org/EIPS/eip-1167
- Foundry公式ドキュメント: https://getfoundry.sh/
