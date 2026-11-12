# 第125講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| anvilのハードフォーク | Bpo1 | anvil | 2026-10-19 |
| optimizer | 入れたバージョンはruns 200 | solcの既定値 | 2026-10-19 |

付録のサイズ・ガス・出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `--abi`のエラー | solc 0.8.30の実行の出力 | 2026-10-19 |
| EIP-1167のバイトと状態 | https://eips.ethereum.org/EIPS/eip-1167 | 2026-10-19 |
| コードの保存のガス | 長さだけが違う三つのinitcodeをanvilにデプロイして直接測定 | 2026-10-19 |
| Tally・転送役のサイズとデプロイのgasUsed | `solc --bin`、デプロイのあとの`cast code`、トランザクションのレシート | 2026-10-19 |
| 実行ガス | `cast call --trace`のいちばん上の行 | 2026-10-19 |
| Tally.solのIR | `solc --ir`、`--ir-optimized --optimize` | 2026-10-19 |
| MarketのIR | `forge inspect --offline src/Market.sol:Market ir` | 2026-10-19 |
| Marketの数 | `forge inspect`、`forge build --sizes`、`forge test` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Using the Compiler（`docs/using-the-compiler.rst`）: https://docs.soliditylang.org/en/v0.8.36/using-the-compiler.html
  - Standard JSONの出力の一覧 "ir - Yul intermediate representation of the code before optimization"、"irOptimized - Intermediate representation after optimization"
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/using-the-compiler.rst
- Solidity公式ドキュメント v0.8.36、Yulの節
- EIP-1167（ERC-1167: Minimal Proxy Contract、2018-06-22作成、Final）: https://eips.ethereum.org/EIPS/eip-1167
- Foundry公式ドキュメント: https://getfoundry.sh/
