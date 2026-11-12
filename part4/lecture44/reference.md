# 第44講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のサイズ、エラー、バイトコードの比較は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| importの文法の四つの形 | Solidity公式ドキュメントv0.8.36、Layout of a Solidity Source FileのImporting other Source Filesの節 | 2026-10-19 |
| ランタイム・作成コードのサイズ | `forge build --offline --sizes` | 2026-10-19 |
| flattenの行数 | `forge flatten src/forms/Pick.sol \| wc -l` | 2026-10-19 |
| OpenZeppelinを使った前の講義の数値 | [第25講](../../part2/lecture25/)の付録（OpenZeppelin v5.4.0） | 2026-10-18 |

## 参考資料

- Solidity公式ドキュメントv0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント: https://getfoundry.sh/
