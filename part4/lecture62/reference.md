# 第62講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のエラーの原文、ガスの数字、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ドキュメントのバージョン、Reference Types / Data locationの節 | Solidity公式ドキュメントv0.8.36 | 2026-10-19 |
| public関数のパラメーターでのcalldataの許可（0.6.9） | Solidity Changelog 0.6.9 "Permit calldata location for all variables."、ドキュメントv0.8.36 Data locationの節のNote | 2026-10-19 |
| データの場所の表示の義務化（0.5.0） | ドキュメントv0.8.36 Data locationの節のNote | 2026-10-19 |
| transient状態変数 | Solidity Changelog 0.8.28、ドキュメントv0.8.36、solc 0.8.30の出力 | 2026-10-19 |
| メモリ・ストレージのガス | EIP-2929、EIP-2200 | ベルリン（2021.04）以降 |
| Places.bump()のgasUsed | anvilのレシート、`forge test -vvvv`（直接実行） | 2026-10-19 |
| エラー番号 | solc 0.8.30の出力（直接実行） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のReference Types / Data location: https://docs.soliditylang.org/en/v0.8.36/
- Solidity Changelog 0.5.0、0.6.9、0.8.28
- EIP-2929 Gas cost increases for state access opcodes: https://eips.ethereum.org/EIPS/eip-2929
- EIP-2200 Structured Definitions for Net Gas Metering: https://eips.ethereum.org/EIPS/eip-2200
- Foundry公式ドキュメント: https://getfoundry.sh/
