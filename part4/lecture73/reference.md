# 第73講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のエラーの原文、ガスの数字、欄の値、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 変換のルール | Solidityのソースのタグv0.8.36 `docs/types/conversion.rst`。説明はsolc 0.8.30の実際の出力が基準 | 2026-10-19 |
| 0.8.0、0.8.1、0.8.5の変更 | Solidity `Changelog.md` | 2026-10-19 |
| OpenZeppelinのSafeCast | OpenZeppelin Contracts v5.4.0 `utils/math/SafeCast.sol` | 2026-10-19 |
| gasUsed | anvil、`cast send --json`（直接実行） | 2026-10-19 |
| anvilのブロックの時刻 | `cast call ... positions(...)`の出力のlastUpdate（直接実行） | 2026-10-19 |
| テストのアドレス | `forge create`の出力（直接実行） | 2026-10-19 |

## 参考資料

- Solidityドキュメントのソースv0.8.36、Conversions between Elementary Types、Conversions between Literals and Elementary Types: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/conversion.rst
- Solidity Changelog（0.8.0、0.8.1、0.8.5）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- OpenZeppelin Contracts v5.4.0、`utils/math/SafeCast.sol`
- Foundry公式ドキュメント: https://getfoundry.sh/
