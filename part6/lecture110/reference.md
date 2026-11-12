# 第110講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | 既定の設定、既定のアカウント0番・1番 | 直接実行 | 2026-10-19 |

付録のサイズ、アドレス、ガス、ストレージの値は、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `virtual`/`override`の必須化のバージョン | 第36講のバージョン表・第104講のシートの値（0.6.0） | 2026-10-19 |
| デモ用のコントラクトのサイズ | 直接実行（`forge build --sizes`） | 2026-10-19 |
| Child・Counterの実測 | 直接実行（`forge create --json`、`cast send --json`、`cast storage`、`cast code`） | 2026-10-19 |
| Marketの二つのバージョン | 直接実行（`forge build --sizes`、`forge test`、`cast send --json`） | 2026-10-19 |
| 線形化の順番 | 直接実行（`forge build --ast`の`linearizedBaseContracts`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Contractsの章（Inheritanceの節）: https://docs.soliditylang.org/en/v0.8.36/contracts.html
  - "only a single contract is created on the blockchain"
  - "all internal calls to functions of base contracts also just use internal function calls"
  - "Base functions can be overridden by inheriting contracts to change their behavior if they are marked as `virtual`."
  - "State variable shadowing is considered as an error."
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント（`forge inspect`、`cast storage`、`cast code`）: https://getfoundry.sh/
