# 第52講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のテストの出力とガスは、すべて上の環境で`forge test`により直接実行した結果である。ローカルチェーンは使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのIntegers（Shifts、Division、Modulo、Exponentiation） | docs.soliditylang.org/en/v0.8.36/types.html | 2026-10-19 |
| 2倍にする関数の呼び出しのガス | `forge test --gas-report` | 2026-10-19 |
| 2倍にする関数の呼び出しのガス、optimizerオン | `FOUNDRY_OPTIMIZER=true forge test --offline --match-contract DoubleGasTest --gas-report` | 2026-10-19 |
| デプロイのサイズ | `forge build --sizes` | 2026-10-19 |
| 掛け算が先の版が巻き戻る金額 | 計算値、1e75の入力で実際にPanic 0x11を確認 | 2026-10-19 |
| ドキュメントの文 | 公式ドキュメントv0.8.36 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のIntegersのShifts、Division、Modulo、Exponentiation: https://docs.soliditylang.org/en/v0.8.36/types.html
- Foundry公式ドキュメント: https://getfoundry.sh/
