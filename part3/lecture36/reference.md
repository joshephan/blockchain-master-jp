# 第36講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `forge --version`、`cast --version` | 2026-10-19 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"`、コンパイル出力 | 2026-10-19 |
| Java、Node.js、Python | 比較用の1行実行 | `java Over.java`、`node -e`、`python order.py` | 2026-10-19 |

付録の出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 影響を与えた言語 | Solidity公式ドキュメント v0.8.36、Language Influencesの節 | 2026-10-19 |
| バージョンごとの変更 | Solidity公式ドキュメント v0.8.36、Language Influencesの節とバージョンごとの変更の節（0.5.0、0.6.0、0.8.0） | 2026-10-19 |
| Panicのコード0x11 | 直接実行（`forge test`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/（Language Influences、ContractsのInheritance、Breaking Changesの各節）
- Solidityの提案: 2014年8月、ギャビン・ウッド（Gavin Wood）
- Rubixiの事件（2016年）: 最初DynamicPyramidという名前で書いたコントラクトの名前だけをRubixiに変えたため、同じ名前の関数をコンストラクタとして使う古い文法のせいで、コンストラクタが誰でも呼べる公開関数として残った事例
- Pythonの多重継承とC3線形化（比較対象）
- Vyper（同じEVMの上で継承とmodifierを入れなかった言語、比較のみ）
- Foundry公式ドキュメント: https://getfoundry.sh/
