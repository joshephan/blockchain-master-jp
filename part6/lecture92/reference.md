# 第92講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、バイトの長さ、gasUsed、デプロイアドレスは、すべて上の環境のローカルのanvilで直接実行した結果である（`forge inspect … bytecode`、`cast tx … input`、`cast codesize`、`cast send`、`cast receipt`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| コンストラクタの規則（作成時に一回実行、省略可能で一つだけ、引数はコードのあとにABIエンコードでつく、デプロイされたコードにコンストラクタのコードはない） | Solidity公式ドキュメント v0.8.36、Contractsの節 Creating Contracts | 2026-10-19 |
| `constructor`キーワードの0.4.22での導入 | SWC-118（Incorrect Constructor Name）Remediation | 2026-10-19 |
| 0.5.0から`constructor`キーワードでだけ定義 | Solidity公式ドキュメント、0.5.0 Breaking Changes（"Constructors must now be defined using the `constructor` keyword."） | 2026-10-19 |
| 0.7.0からコンストラクタの可視性が不要 | Solidity公式ドキュメント、0.7.0 Breaking Changes | 2026-10-19 |
| バイトの長さ、gasUsed、デプロイアドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Contractsの節 Creating Contracts、0.5.0・0.7.0 Breaking Changes）
- SWC-118 Incorrect Constructor Name
- Rubixiの事件：最初の名前はDynamicPyramid。デプロイ前にコントラクト名だけをRubixiに変え、コンストラクタとして使っていた関数の名前はそのままにした。その関数が誰でも呼べる公開関数として残り、誰でもcreatorになって貯まった手数料を持ち出せた。出典はSWC-118が参考として挙げているSigma Prime "Constructors with Care"。年は確認できなかった
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
