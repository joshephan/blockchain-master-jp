# 第242講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| Python | 3.12、標準ライブラリのみ | `python --version` | 2026-10-21 |
| テスト | 143個が通る | `forge test --offline` | 2026-10-21 |

付録のレシート、トレース、ログ、タイムラインはすべて、ローカルのanvilに作った練習用の事故のチェーンで直接実行した結果である。署名はanvilのデフォルトのテスト用の鍵だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Compound 2021 | Tally Compoundのガバナンス提案64の原文（tally.xyz/gov/compound/proposal/64） | 2026-10-21 |
| Euler 2023 | Euler公式ブログ "War & Peace: Behind the Scenes of Euler's $240M Exploit Recovery"（2024-01-10、euler.finance） | 2026-10-21 |
| Ronin 2022、Nomad 2022 | 公式の事後報告書のページを開けなかったので、名前・年だけを書いた | 2026-10-21 |
| SEAL 911 | securityalliance.org | 2026-10-21 |
| 通しプロジェクトのバージョン | 直接実行（`forge test --offline`） | 2026-10-21 |

## 参考資料

- Compound 提案64 "Fix COMP Accrual Bug"（提案62が入れたCOMPの分配の誤りを直すこともガバナンスの提案で行い、2021-10-02の提案から2021-10-09の実行まで）
- Euler, "War & Peace: Behind the Scenes of Euler's $240M Exploit Recovery"（2024-01-10）：2023-03-13の事件、チェーンの外での交渉で取り戻した
- Security Alliance SEAL 911（事故対応を手伝う団体、名前のみ）
- Foundry 公式ドキュメント（`cast receipt`、`cast run`、`cast logs`、`cast call --block`）: https://getfoundry.sh/
