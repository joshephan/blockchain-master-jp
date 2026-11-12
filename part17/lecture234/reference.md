# 第234講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| anvil | `--hardfork osaka`、チェーン番号31337、デフォルトのテスト用アカウント | `anvil`の起動画面 | 2026-10-21 |
| python | 標準ライブラリのみ（random、time）、乱数のシード234 | `poly234.py` | 2026-10-21 |

付録のテスト結果、ガス、計算結果はすべて上の環境で直接実行した結果である。秒単位の値は、実行したコンピューターでの値である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 証明方式の名前、KZG信頼設定のセレモニー、取引の内容を隠す設計 | 公開資料（名前のみ） | 2026-10-21 |
| EIP-1108のペアリングのガス | EIP-1108、第232講の測定値と比べた | 2026-10-21 |
| 多項式の確認の値 | 直接実行（`python -I -X utf8 poly234.py`） | 2026-10-21 |
| Schnorr234のテスト・anvilの値 | 直接実行（`forge test --offline --match-contract Schnorr234Test -vv`、anvilでcast `send`・`call`・`estimate`） | 2026-10-21 |

## 参考資料

- EIP-1108 Reduce alt_bn128 precompile gas costs: https://eips.ethereum.org/EIPS/eip-1108
- 証明方式：Groth16、PLONK、STARK（名前のみ）
- Foundry 公式ドキュメント: https://getfoundry.sh/
