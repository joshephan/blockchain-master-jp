# 第267講 出典

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 事件の年と1行の性格 | 前の講義（第173・179・180・181・201・212講）の事件カード | 2026-10-21 |
| 2022年の事件の月 | 一次の原文の確認に失敗（Ronin・Nomadの事後の記事は404・403、BNB Chain公式ブログ "BNB Chain Ecosystem Update" は2022-10-07付で開いたが、事件の日付の文言がない） | 2026-10-21 |
| アルゴリズム型ステーブルコインの償還の表 | 第201講`Algo201Test`（`test_spiralMarketValueFixed`、`test_spiralMarketValueFalling`）の出力 | 2026-10-21 |

## 参考資料

- 事件（2022年。月はTerra USTだけ確認、損失額は載せない）
  - 鍵の席：Ronin、Harmony Horizon。受け取る側のコードは署名を正しく確認し、しきい値の分だけの署名の鍵を奪われた。コードは書かれたとおりに動いた
  - 確認の行の席：Wormhole、Nomad、BNB Chainのブリッジ。証明や署名を確認する行が間違っていた（Nomadは空の欄が受け取りとして読まれた）
  - 前提の席：Wintermute OP。ほかのチェーンにまだないマルチシグのアドレスにトークンが行った。コントラクトのコードより「このアドレスは向こうのチェーンでも自分のもの」という前提が間違っていた
  - 経済の席：Beanstalk（借りた票でガバナンスの提案を通した）、Mango（その場の価格を揺らして担保の価値を膨らませた）、Terra UST（2022年5月。対のトークンの値が担保のすべてで、償還が集中するほど多く刷らなければならなかった）。コードは書かれたとおりに動いた
  - 画面の席：Curve DNS。ドメインがチェーンの外で別のところに向けられた。コードは変わっていない
- 前の講義のテスト（この講義では実行し直さず結果を引用）
  - 第212講`DefaultsTest`：`test_zeroIdNeverVerified`、`test_unsubmittedHeaderNeverVerified`、`test_defaultStatusNotDelivered`
  - 第211講`test_dailyCapDefers`（二つ目の100 → `MintCapExceeded(200, 150)`）、`test_pauseDefersMint`（`Paused()`）
  - 第180講`test_votesCountedAtSnapshot`（getVotes 900 / 重み0 / 賛成100）
  - 第201講`Algo201Test`：`test_spiralMarketValueFixed`、`test_spiralMarketValueFalling`
