# 第252講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| SMTChecker | CHCエンジン、目標assert・divByZero・outOfBounds・overflow・underflow、Hornソルバーなし | `foundry.toml` `[profile.smt.model_checker]` | 2026-10-21 |

付録のテスト結果、トレース、コンパイルエラー、SMTCheckerの警告は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| tool252のテストのガス、トレース | 直接実行（`forge test --offline -vvvv`） | 2026-10-21 |
| Error 7006 | 直接実行（`forge build --offline`） | 2026-10-21 |
| Marketの二つのバージョン | 第250講で直接実行した値 | 2026-10-21 |
| SMTChecker（Market） | 直接実行（`FOUNDRY_PROFILE=smt forge build --offline --force`） | 2026-10-21 |
| SimpleStorageの四つのバージョン | 第251講で直接実行した値 | 2026-10-21 |
| 前の章の表 | 第123講（Marketのアセンブリ変形版）・第125講（Tally）で直接実行した値 | 2026-10-21 |
| Vyperのセキュリティ勧告 | GitHub security advisories API（vyperlang/vyper） | 2026-10-21 |
| Vyperドキュメント | vyperlang/vyper タグv0.4.3 | 2026-10-21 |
| Solidityの既知のバグ | Solidityリポジトリ v0.8.36 `docs/bugs_by_version.json`（第184講の値） | 2026-10-21 |
| huff-rs | github.com/huff-language/huff-rs | 2026-10-21 |
| huff-neo | github.com/cakevm/huff-neo | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidityの既知のバグ一覧: https://github.com/argotorg/solidity/blob/v0.8.36/docs/bugs.json , https://github.com/argotorg/solidity/blob/v0.8.36/docs/bugs_by_version.json
- Vyperドキュメント v0.4.3 `docs/compiling-a-contract.rst`（`-f layout`、`-f source_map`・`source_map_runtime`、`-f integrity`、JSONの入出力）: https://github.com/vyperlang/vyper/tree/v0.4.3
- Vyperのセキュリティ勧告GHSA-5824-cm3x-3c38: https://github.com/vyperlang/vyper/security/advisories/GHSA-5824-cm3x-3c38
- huff-rsのREADME（"deprecated and no longer maintained, go see huff2 for the renewed compiler"）: https://github.com/huff-language/huff-rs
- huff-neoのREADME（"hard-fork from huff-rs, which is archived and discontinued, as is its planned successor huff2"）: https://github.com/cakevm/huff-neo
- Foundry公式ドキュメント（`vm.etch`、トレース）: https://getfoundry.sh/
