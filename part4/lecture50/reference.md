# 第50講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のコンパイルエラー、欄の配置、ガスは、すべて上の環境のローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのBooleans | docs.soliditylang.org/en/v0.8.36/types.html | 2026-10-19 |
| boolの保存サイズ | `forge inspect storageLayout` | 2026-10-19 |
| OneFlag・TwoFlags・ShortCircuit・OrderGasのgasUsed | anvilでの`cast send`のレシート | 2026-10-19 |
| 第47講の最初のvisit()のgasUsed | 第47講の時効性のあるデータ | 2026-10-19 |
| SSTORE・SLOADの価格 | 第16講の時効性のあるデータ、EIP-2200、EIP-2929 | ベルリン（2021.04）以降 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のBooleans（`!`、`&&`、`||`、`==`、`!=`と短絡評価）: https://docs.soliditylang.org/en/v0.8.36/types.html
- EIP-2200 Structured Definitions for Net Gas Metering: https://eips.ethereum.org/EIPS/eip-2200
- EIP-2929 Gas cost increases for state access opcodes: https://eips.ethereum.org/EIPS/eip-2929
- Foundry公式ドキュメント: https://getfoundry.sh/
