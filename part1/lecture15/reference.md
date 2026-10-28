# 第15講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil、cast） | 1.8.3 | `cast --version` | 2026-10-17 |
| solar | 0.2.0 | `solar --version` | 2026-10-17 |

付録の出力とガスの数字は、上の環境のローカルのテストチェーンで実際に実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| gasUsedの値 | ローカルのテストチェーンのレシートと`cast run`の出力（実際に実行） | 2026-10-17 |
| 64分の63の規則 | イーサリアムの実行仕様 | 2026-10-17 |

## 参考資料

- イーサリアムのイエローペーパー（CALL、STATICCALL、DELEGATECALLの定義）: https://ethereum.github.io/yellowpaper/paper.pdf
- EIP-150（呼び出し時に残りのガスの64分の63だけを渡す規則）: https://eips.ethereum.org/EIPS/eip-150
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント: https://getfoundry.sh/
