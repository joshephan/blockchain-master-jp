# 第94講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| anvilのハードフォーク | 既定値`latest`、hardFork `Bpo1` | `anvil --help`、`cast rpc anvil_nodeInfo` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、バイトの長さ、ガス、アドレスは、すべて上の環境で直接実行した結果である。二つのチェーンの比較は、ローカルのanvil二つ（チェーンID 31337、31338）で動かした。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `{salt: }`で作るコントラクト | Solidity公式ドキュメント v0.8.36、Expressions and Control Structuresの節のSalted contract creations / create2 | 2026-10-19 |
| `{salt: }`の文法の導入（0.6.2） | Solidityの変更履歴 | 2026-10-19 |
| RLP（Recursive Length Prefix） | イーサリアムの実行仕様 | 2026-10-19 |
| コントラクトアカウントのナンスの初期値1 | EIP-161、直接実行 | 2026-10-19 |
| CREATE2アドレスの式、0xffの接頭バイト | EIP-1014 | 2026-10-19 |
| アドレスの衝突の規則 | EIP-684 | 2026-10-19 |
| selfdestructの動作の変更 | EIP-6780、solc Warning 5159の原文 | 2026-10-19 |
| バイトの長さ、ガス、アドレス | 直接実行（`forge inspect`、`cast codesize`、`cast send`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Expressions and Control Structuresの節のSalted contract creations / create2）
- EIP-161 State trie clearing: https://eips.ethereum.org/EIPS/eip-161
- EIP-684 Revert creation in case of collision: https://eips.ethereum.org/EIPS/eip-684
- EIP-1014 Skinny CREATE2: https://eips.ethereum.org/EIPS/eip-1014
- EIP-6780 SELFDESTRUCT only in same transaction: https://eips.ethereum.org/EIPS/eip-6780
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
