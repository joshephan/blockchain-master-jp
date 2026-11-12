# 第116講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | 既定の設定、既定のアカウント0番・1番 | 直接実行 | 2026-10-19 |

付録のビルドエラーの原文、サイズ、バイトの比較、アドレス、ガス、ストレージの値は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| メタデータの長さ | 直接確認（成果物のJSONのdeployedBytecodeの最後の2バイト） | 2026-10-19 |
| Feeの四つのバージョン・Percentの成果物 | 直接実行（`forge build --sizes`、`forge inspect`、最後の53バイトを外したsha256の比較） | 2026-10-19 |
| 本体を変えたPercentのバージョン | 直接実行（`forge build --sizes`、`cast call`） | 2026-10-19 |
| anvilのデモのガス | 直接実行（`cast send --json`、`cast run`） | 2026-10-19 |
| Marketのサイズ・ガス・テスト | 直接実行（`forge build --sizes`、成果物のJSON、`cast send`、`forge test`） | 2026-10-19 |
| OpenZeppelin Contracts | v5.4.0のパッケージのソースで`public`・`external`の関数の行を検索（0個） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Librariesの節: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/libraries.rst
  - 制約："they cannot have state variables"、"they cannot inherit nor be inherited"、"they cannot receive Ether"、"they cannot be destroyed"
  - "the code of internal library functions that are called from a contract and all functions called from therein will at compile time be included in the calling contract, and a regular `JUMP` call will be used instead of a `DELEGATECALL`."
  - "Calling a public library function with `L.f()` results in an external call (`DELEGATECALL` to be precise)."
- OpenZeppelin Contracts v5.4.0: `utils/Strings.sol`（library Strings）、`utils/math/Math.sol`（library Math）
- EIP-6780（`selfdestruct`の動作の変更、警告5159の原文が指す）: https://eips.ethereum.org/EIPS/eip-6780
- Foundry公式ドキュメント（`forge inspect`、`cast disassemble`、`cast index`、`cast run`）: https://getfoundry.sh/
