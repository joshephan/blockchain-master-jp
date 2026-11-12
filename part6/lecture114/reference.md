# 第114講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のコード生成（legacy）、比較用に`--via-ir` | foundry.toml、forgeのフラグ | 2026-10-19 |
| anvil | 既定の設定、既定のアカウント0番・1番 | 直接実行 | 2026-10-19 |

付録のログ、ビルドエラーの原文、アドレス、サイズ、ガスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Marketのサイズ | 直接実行（`forge build --sizes`、`cast tx … input`） | 2026-10-19 |
| Marketのガス | 直接実行（`cast receipt`） | 2026-10-19 |
| CtorTestのテストのガス | 直接実行（`forge test -vv`、既定の設定と`--via-ir`） | 2026-10-19 |
| 初期化の順番 | 直接実行した二つの設定のログと、Solidity公式ドキュメント"Solidity IR-based Codegen Changes"の"Semantic Only Changes"の節が合うことを確認 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Contractsの章（Inheritanceの節のConstructors、Arguments for Base Constructors、Abstract Contracts）: https://docs.soliditylang.org/en/v0.8.36/contracts.html
  - 親のコンストラクタの引数は、継承の行と子のコンストラクタの横の二か所に書ける。両方書くとエラー、引数を渡さなければabstract
- Solidity公式ドキュメント v0.8.36 "Solidity IR-based Codegen Changes"、"Semantic Only Changes"の節：継承があるとき、従来のコード生成は階層全体の状態変数を初期化したあとにコンストラクタを基本から、新しいコード生成は基本からコントラクトごとに初期化とコンストラクタを一組で。どちらの方式でも、親のコンストラクタの引数はいちばん派生した側から計算
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント（`forge create`、`cast tx`、`cast abi-decode`、`cast codesize`）: https://getfoundry.sh/
