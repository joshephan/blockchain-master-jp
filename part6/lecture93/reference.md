# 第93講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `anvil --version` | 2026-10-19 |
| anvilのハードフォーク | `Bpo1`（既定値latest） | `cast rpc anvil_nodeInfo` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、バイトの長さ、gasUsed、デプロイアドレスは、すべて上の環境のローカルのanvilで直接実行した結果である（`forge test --offline -vv --mt test_lengths`、`cast tx`、`cast codesize`、`cast send --create`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `type(C).creationCode`・`runtimeCode`、`immutable`、コンストラクタの規則 | Solidity公式ドキュメント v0.8.36 | 2026-10-19 |
| `type(C).creationCode`・`runtimeCode`の導入（0.5.3）、`immutable`の導入（0.6.5） | Solidityの変更履歴（実行では確かめていない） | 2026-10-19 |
| コードの欄のサイズの上限24,576バイト | EIP-170、直接実行（`cast send --create 0x6160005ff3` / `0x6160015ff3`） | 2026-10-19 |
| デプロイのコードのサイズの上限49,152バイト | EIP-3860、直接実行（JSON-RPC `eth_sendTransaction`） | 2026-10-19 |
| コード1バイトあたりの保存のガス200 | イーサリアムのイエローペーパー G_codedeposit（実行では確かめていない） | 2026-10-19 |
| バイトの長さ、デプロイアドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Units and Globally Available Variablesの節のType Information、Contractsの節のConstant and Immutable State Variables、Creating Contracts）
- EIP-170 Contract code size limit: https://eips.ethereum.org/EIPS/eip-170
- EIP-3860 Limit and meter initcode: https://eips.ethereum.org/EIPS/eip-3860
- イーサリアムのイエローペーパー: https://ethereum.github.io/yellowpaper/paper.pdf
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
