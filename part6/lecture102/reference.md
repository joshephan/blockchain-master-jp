# 第102講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、anvilは既定の設定 | `cast --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、ガス、長さ、アドレスは、すべて上の環境のローカルのanvilで直接実行した結果である（`cast codesize`、`cast send --json`、`cast storage`、`forge inspect`、成果物`out/…/Market.json`の`immutableReferences`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| コンパイラがストレージのスロットを確保しない、constantはコンパイル時に決まる値を宣言で代入、immutableの値は読む場所ごとにコードにコピー、もっと小さくても32バイトを確保、対応する型は文字列（constantのみ）と値型 | Solidity公式ドキュメント v0.8.36、Contractsの節 Constant and Immutable State Variables | 2026-10-19 |
| コンストラクタの中のimmutableの規則の緩和（0.8.21）、作成中の読み取り（0.8.8） | Solidity Changelog.md（ethereum/solidity develop） | 2026-10-19 |
| immutableの導入（0.6.5） | Solidityの変更履歴（第93講の値、実行では確かめていない） | 2026-10-19 |
| コールドのSLOAD 2,100 | EIP-2929 | 2026-10-19 |
| ガス、長さ、アドレス、adminのバイトの位置 | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Contracts: https://docs.soliditylang.org/en/v0.8.36/contracts.html （Constant and Immutable State Variables）
- Solidity Changelog（0.6.5、0.8.8、0.8.21）
- EIP-2929 Gas cost increases for state access opcodes: https://eips.ethereum.org/EIPS/eip-2929
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
