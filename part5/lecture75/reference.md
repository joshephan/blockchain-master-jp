# 第75講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 単位の導入・削除のバージョン | Solidityリポジトリ v0.8.36 Changelog.md（"Add unit denomination gwei"）、公式ドキュメントTime Unitsの節の注 | 2026-10-19 |
| USDCの桁数 | イーサリアムメインネットの公開RPCで`cast call <USDCのアドレス> "decimals()(uint8)"` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variablesの節（Ether Units、Time Units）: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
  - Ether Units: "The only effect of the subdenomination suffix is a multiplication by a power of ten."
  - Time Units: 1年がいつも365日とは限らず、うるう秒のために1日がいつも24時間とは限らないので、暦の計算に注意せよという文言、接尾辞は変数につけられず`daysAfter * 1 days`の形で書くという例
- 同じドキュメントのrst原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- Solidityの変更履歴 v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント: https://getfoundry.sh/
