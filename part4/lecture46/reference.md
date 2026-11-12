# 第46講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のサイズ、エラー、バイトコードの比較は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ランタイムのサイズ | `forge build --sizes` | 2026-10-19 |
| バイトコードの比較 | `forge inspect deployedBytecode` | 2026-10-19 |
| --skipの別名と成果物のパス | `forge build --help`、直接実行 | 2026-10-19 |
| エラー番号 | solc 0.8.30の出力 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36（Layout of a Solidity Source File）: https://docs.soliditylang.org/en/v0.8.36/
- 前の講義の元のコード：[第41講](../../part3/lecture41/)のモジュール式のコントラクト
- Foundry公式ドキュメント: https://getfoundry.sh/
