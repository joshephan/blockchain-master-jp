# 第33講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-18 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-18 |
| デフォルトのfuzz runs | 256 | 実行出力の`runs: 256` | 2026-10-18 |
| --checkが一致しないときの終了コード | 1 | 直接実行、`forge snapshot --help` | 2026-10-18 |

付録のガスの数字と出力は、すべて上記の環境で直接実行した結果である。

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
