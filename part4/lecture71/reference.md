# 第71講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | `--accounts 101` | 実行オプション | 2026-10-19 |

付録のエラーの原文、ガスの数字、欄の値、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| マッピングのルール | Solidityのソースのタグv0.8.36 `docs/types/mapping-types.rst`。説明はsolc 0.8.30の実際の出力が基準 | 2026-10-19 |
| マッピングのキーとして許される型 | ビルドの出力（直接実行、Keys、KeyStruct、KeyArray、KeyMapping） | 2026-10-19 |
| キーの型が増えたバージョン（0.1.1、0.6.3、0.8.8）、マッピングの名前の文法（0.8.18） | Solidity `Changelog.md` | 2026-10-19 |
| 読み書きのgasUsed | anvil、`cast send --json`（直接実行） | 2026-10-19 |
| SLOADの価格 | EIP-2929 | ベルリン（2021.04）以降 |
| ブロックの時刻 | anvil（直接実行） | 2026-10-19 |

## 参考資料

- Solidityドキュメントのソースv0.8.36、Mapping Types: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/mapping-types.rst
- Solidity Changelog（0.1.1、0.6.3、0.8.8、0.8.18）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- EIP-2929 Gas cost increases for state access opcodes: https://eips.ethereum.org/EIPS/eip-2929
- Foundry公式ドキュメント: https://getfoundry.sh/
