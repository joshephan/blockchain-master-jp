# 第69講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version`、`anvil --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のエラーの原文、ガスの数字、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| スライスのルール | Solidityのソースのタグv0.8.36 `docs/types/reference-types.rst`（Array Slices） | 2026-10-19 |
| スライスの導入と変換が加わったバージョン（0.6.0、0.7.6、0.8.5） | Solidity `Changelog.md` | 2026-10-19 |
| 関数の実行ガス | `forge test --offline --match-contract GasTest --gas-report`、`-vvvv`のトレース（直接実行） | 2026-10-19 |
| トランザクションのgasUsed | `cast send`のあと`cast receipt <ハッシュ> gasUsed`、anvil 1.8.3の既定のハードフォーク（直接実行） | 2026-10-19 |
| トランザクションのgasUsedの解説 | 測定値とEIP-7623、EIP-2028の計算の突き合わせ | 2026-10-19 |
| テストのアドレス | `forge create`の出力（直接実行） | 2026-10-19 |

## 参考資料

- Solidityドキュメントのソースv0.8.36、Array Slices: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/reference-types.rst
- Solidity Changelog（0.6.0、0.7.6、0.8.5）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- EIP-7623 Increase calldata cost: https://eips.ethereum.org/EIPS/eip-7623
- EIP-2028 Transaction data gas cost reduction: https://eips.ethereum.org/EIPS/eip-2028
- Foundry公式ドキュメント: https://getfoundry.sh/
