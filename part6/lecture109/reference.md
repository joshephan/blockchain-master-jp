# 第109講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvilのハードフォーク | `Bpo1`（既定値）、chainId 31337 | `cast rpc anvil_nodeInfo` | 2026-10-19 |

付録のサイズ、ガス、リバートデータは、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `require(条件, カスタムエラー)`のバージョン | Solidity Changelog.md v0.8.26 "Introduce a new overload `require(bool, Error)`"、v0.8.27 "Make `require(bool, Error)` available when using the legacy pipeline" | 2026-10-19 |
| カスタムエラーの導入 | 第48講のシートの値（Solidity Changelog.md v0.8.4） | 2026-10-19 |
| `abi.encodeError` | 直接ビルド（`code/demo/bad/EncErr.sol`） | 2026-10-19 |
| Marketの三つのバージョン、whenActiveだけを変えたバージョン | 直接実行（`forge build --sizes`、`cast send --json`、`cast rpc eth_call`） | 2026-10-19 |
| Cmp・Len・Eval | 直接実行（`forge inspect`、`cast send --json`、`cast call`、`cast rpc eth_call`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Control Structuresの章（Error handlingの節）: https://docs.soliditylang.org/en/v0.8.36/control-structures.html
  - "`require` arguments are evaluated unconditionally"
  - "in `require(condition, CustomError(f()));` and `require(condition, f());`, function `f()` will be called regardless of whether the supplied condition is `true` or `false`."
- Solidity Changelog（v0.8.26、v0.8.27）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント（`forge build --sizes`、`forge inspect`、`cast rpc`）: https://getfoundry.sh/
