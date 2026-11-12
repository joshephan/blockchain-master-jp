# 第59講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version`、`cast --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のコンパイルエラー、テストの出力、欄の内容、ガスは、すべて上の環境とローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのString Literals and Types、Unicode Literals、Hexadecimal Literals、Address Literals | docs.soliditylang.org、v0.8.36 | 2026-10-19 |
| アドレスリテラルの桁数のルール | solc 0.8.30で直接実行した出力（`bad/Addr38~42.sol`、`Uint40.sol`、`Prepend.sol`） | 2026-10-19 |
| エラーの原文 | solc 0.8.30で直接実行した出力 | 2026-10-19 |
| setLabelのgasUsed | anvilでの`cast send`のレシート | 2026-10-19 |
| EIP-55 | eips.ethereum.org/EIPS/eip-55（第6講の時効性のあるデータと同じ） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のString Literals and Types、Unicode Literals、Hexadecimal Literals、Address Literals: https://docs.soliditylang.org/en/v0.8.36/
- EIP-55 Mixed-case checksum address encoding（2016）: https://eips.ethereum.org/EIPS/eip-55
- Foundry公式ドキュメント（`cast to-ascii`、`cast to-check-sum-address`）: https://getfoundry.sh/
