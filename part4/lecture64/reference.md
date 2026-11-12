# 第64講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| anvilの既定のハードフォーク | `Bpo1` | `cast rpc anvil_nodeInfo` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のガスの数字、バイト数、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| データの場所の説明 | Solidity公式ドキュメントv0.8.36、Typesの節のReference Types / Data location | 2026-10-19 |
| sum・readCopy・readRef・readOnce・readThrice・MemGrow・StoreのgasUsed | anvilのレシート（直接実行） | 2026-10-19 |
| sumの呼び出しのcalldataのサイズ | 直接エンコード | 2026-10-19 |
| forge snapshot | `forge snapshot --diff`（直接実行） | 2026-10-19 |
| MLOAD / MSTORE / CALLDATALOAD | evm.codes | 2026-10-19 |
| SLOADのコールド・ウォームアクセス | EIP-2929 | 2026-10-19 |
| SSTORE 0から0でない値へ | EIP-2200、EIP-2929 | 2026-10-19 |
| メモリ拡張のコスト | イーサリアム・イエローペーパーのG_memory、MemGrowの実測と突き合わせた | 2026-10-19 |
| calldataのバイトの価格 | EIP-2028 | 2026-10-19 |
| calldataの下限 | EIP-7623、anvilのレシート（直接実行） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のReference Types / Data location: https://docs.soliditylang.org/en/v0.8.36/types.html
- EIP-2028 Transaction data gas cost reduction: https://eips.ethereum.org/EIPS/eip-2028
- EIP-2200 Structured Definitions for Net Gas Metering: https://eips.ethereum.org/EIPS/eip-2200
- EIP-2929 Gas cost increases for state access opcodes: https://eips.ethereum.org/EIPS/eip-2929
- EIP-7623 Increase calldata cost: https://eips.ethereum.org/EIPS/eip-7623
- イーサリアム・イエローペーパー（メモリ拡張のコストG_memory）: https://ethereum.github.io/yellowpaper/paper.pdf
- evm.codes（オペコードごとのガス）
- Foundry公式ドキュメント: https://getfoundry.sh/
