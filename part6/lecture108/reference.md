# 第108講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | 既定の設定、Marketのコンストラクタはアカウント0番・5e16・80 | 直接実行 | 2026-10-19 |

付録のアドレス、セレクタ、リバートデータ、ガスの数字は、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| カスタムエラーの導入バージョン | Solidity Changelog.md v0.8.4: "Support custom errors via the `error` keyword and introduce the `revert` statement." | 2026-10-19 |
| `require(条件, カスタムエラー)` | Solidity Changelog.md v0.8.26 "Introduce a new overload `require(bool, Error)`…"、v0.8.27 "Make `require(bool, Error)` available when using the legacy pipeline."、直接実行 | 2026-10-19 |
| `abi.encodeError` | 直接実行（ビルドエラーの原文） | 2026-10-19 |
| `cast decode-error`の既定の照会先 | `cast decode-error --help`（Foundry 1.8.3） | 2026-10-19 |
| Marketのサイズ | 直接実行（`forge build --sizes`） | 2026-10-19 |
| デモのgasUsed | 直接実行（`cast send --json`） | 2026-10-19 |
| テストのgas | 直接実行（`forge test`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Contractsの章（Custom Errorsの節）: https://docs.soliditylang.org/en/v0.8.36/contracts.html
  - "They can be defined inside and outside of contracts (including interfaces and libraries)."
  - "Errors cannot be overloaded or overridden but are inherited."
  - "If you do not provide any parameters, the error only needs four bytes of data."
  - "the revert data of inner calls is propagated back through the chain of external calls by default."
- Solidity Changelog（v0.8.4、v0.8.26、v0.8.27）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント（`cast decode-error`、`forge inspect`）: https://getfoundry.sh/
- forge-std（`stdError.arithmeticError`、`vm.expectRevert`）
