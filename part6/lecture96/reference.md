# 第96講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、バイトの長さ、セレクタ、ガス、アドレスは、すべて上の環境で直接実行した結果である（`forge inspect … bytecode`・`deployedBytecode`・`methodIdentifiers`、`cast sig`、`cast call --trace`、`forge test`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ゲッター関数の可視性はexternal、中で名前で使うと状態変数で、`this.`で使うと関数 | Solidity公式ドキュメント v0.8.36、Contractsの節 Visibility and Getters、Getter Functions | 2026-10-19 |
| 配列のゲッターは要素を一つずつだけ返す（配列全体を返す高いガスのコストを避けるため） | 同じ節 Getter Functions | 2026-10-19 |
| 構造体のゲッターではマッピングと配列（バイト配列を除く）の欄が抜ける | 同じ節 Getter Functions | 2026-10-19 |
| public状態変数にはゲッターだけを作り、セッターは作らない | 同じ節 State Variable Visibility | 2026-10-19 |
| バイトの長さ、セレクタ、ガス、アドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Contractsの節 Visibility and GettersのState Variable Visibility、Getter Functions）
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
