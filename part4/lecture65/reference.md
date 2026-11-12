# 第65講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のエラーの原文、ガスの数字、欄の値、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 配列の表記とアクセスの方向 | Solidity公式ドキュメントv0.8.36、Typesの節のArrays | 2026-10-19 |
| 固定サイズの配列の保存サイズ | `forge inspect storageLayout`（直接実行） | 2026-10-19 |
| set・delete・sum・listedCountのgasUsed | anvilのレシート（直接実行） | 2026-10-19 |
| 第37講のdelegateのガス | 第37講の実習の`gasleft()`の差の測定 | 2026-10-19 |
| SLOADの価格 | EIP-2929 | ベルリン（2021.04）以降 |
| gasEstimates | `forge inspect gasEstimates`（直接実行） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のArrays: https://docs.soliditylang.org/en/v0.8.36/types.html
- EIP-2929 Gas cost increases for state access opcodes: https://eips.ethereum.org/EIPS/eip-2929
- Foundry公式ドキュメント: https://getfoundry.sh/
