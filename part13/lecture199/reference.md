# 第199講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果、ガス、サイズは、上の環境で直接実行した結果である（anvilなし、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 事件 | MakerDAO 2020年3月の事件（名前・年月・1行だけ） | 2026-10-21 |
| 平均の期間と操作のコスト | Uniswap v2 Coreホワイトペーパーの価格オラクルの節 | 2026-10-21 |
| デモの値 | `test/BadDebt.t.sol`、`test/Cascade199.t.sol`が決めた数字 | 2026-10-21 |
| 清算のガス | `forge test --offline --match-contract Gas199Test`（直接実行） | 2026-10-21 |
| Marketのサイズ・メタデータハッシュ | CIスクリプトの出力、`forge inspect`（直接実行） | 2026-10-21 |

## 参考資料

- MakerDAO、2020年3月（ブラックサーズデー）：価格の急落とネットワークの混雑のなかで、清算オークションの一部が競争なしに0に近い値で落札された事件
- Hayden Adams, Noah Zinsmeister, Dan Robinson, "Uniswap v2 Core", 2020年3月、価格オラクルの節: https://uniswap.org/whitepaper.pdf
- Foundry公式ドキュメント: https://getfoundry.sh/
