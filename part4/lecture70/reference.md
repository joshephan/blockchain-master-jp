# 第70講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のエラー・警告の原文、ガスの数字、欄の値、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 構造体のルール | Solidityのソースのタグv0.8.36 `docs/types/reference-types.rst`（Structs）。説明はsolc 0.8.30の実際の出力が基準 | 2026-10-19 |
| ファイルレベルの構造体の導入（0.6.0）、マッピングを含む構造体のmemory・calldataでの禁止（0.7.0） | Solidity `Changelog.md` | 2026-10-19 |
| save・作成・直す・deleteのgasUsed | `cast send --json`のgasUsed、anvil 1.8.3の既定のハードフォーク（直接実行） | 2026-10-19 |
| anvilのブロックの時刻 | `cast call`の出力（直接実行） | 2026-10-19 |
| テストのアドレス | `forge create`の出力（直接実行） | 2026-10-19 |

## 参考資料

- Solidityドキュメントのソースv0.8.36、Structs: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/reference-types.rst
- Solidity Changelog（0.6.0、0.7.0）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント: https://getfoundry.sh/
