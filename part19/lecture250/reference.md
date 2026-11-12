# 第250講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | `foundry.toml` | 2026-10-21 |
| デプロイ用ビルド | via-IR、optimizerオン（runs 200）、evm osaka | `foundry.toml` `[profile.default]` | 2026-10-21 |
| debugビルド | optimizerオフ、via-IRオフ | `foundry.toml` `[profile.debug]` | 2026-10-21 |
| Python | 整数の割り算の確認用 | `python -c` | 2026-10-21 |

付録のテスト結果、サイズ、ガス、セレクタ・スロットの比較は、すべて上の環境で直接実行した結果である。Vyperのコンパイラは使っておらず、Vyper側の値とソースは下のドキュメントの原文から移した。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Vyperドキュメントの基準のバージョン | vyperlang/vyper タグv0.4.3 `docs/release-notes.rst` | 2026-10-21 |
| Vyperのセキュリティ勧告 | GitHubのセキュリティ勧告GHSA-5824-cm3x-3c38 | 2026-10-21 |
| Vyper 0.3.1のリリース | vyperlang/vyper `docs/release-notes.rst` | 2026-10-21 |
| Solidityドキュメント | Solidity公式ドキュメント v0.8.36 | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 `contracts/utils/ReentrancyGuard.sol` | 2026-10-21 |
| サイズ | 直接実行（`forge build --offline --sizes`、デプロイ用・debugプロファイル） | 2026-10-21 |
| ガス | 直接実行（GasTestのガス記録） | 2026-10-21 |
| Lang250のテストのガス | 直接実行（`forge test --offline -vv`） | 2026-10-21 |

## 参考資料

- Vyperドキュメント v0.4.3（vyperlang/vyper タグv0.4.3）: https://github.com/vyperlang/vyper/tree/v0.4.3
  - `docs/index.rst`（三つの原則、"Vyper **does not** provide the following features"の8行とその理由、"Bounds and overflow checking"、"Decidability"）
  - `docs/types.rst`（算術演算子の表、負の数の割り算のnote、`DynArray`、decimalは`--enable-decimals`でオン）
  - `docs/control-structures.rst`（デコレーターの表、`range(stop, bound=N)`、`@nonreentrant`のグローバルロックとスロット0）
  - `docs/release-notes.rst`（v0.4.3の日付、v0.3.1のFixes、v0.3.0冒頭の警告）
  - 例`storage.vy`、`safe_remote_purchase.vy`
- Vyperのセキュリティ勧告GHSA-5824-cm3x-3c38 "Incorrectly allocated named re-entrancy locks"（0.2.15、0.2.16、0.3.0、修正バージョン0.3.1、公開2023-08-05）: https://github.com/vyperlang/vyper/security/advisories/GHSA-5824-cm3x-3c38
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Safe Remote Purchaseの例`examples/safe-remote-purchase.rst`、Language Influences：modifierはPythonのデコレーターをまねた）
- OpenZeppelin Contracts 5.4.0 `contracts/utils/ReentrancyGuard.sol`（NOT_ENTERED・ENTERED、`_status`、`nonReentrant`）
- Foundry公式ドキュメント: https://getfoundry.sh/
