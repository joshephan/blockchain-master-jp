# 第264講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| anvil | チェーン番号31337、デフォルトのテスト用キー | `anvil`の起動画面 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts` | 2026-10-21 |
| Python | 標準ライブラリだけ（`ops/`） | - | 2026-10-21 |

付録のブロック、取引ハッシュ、警報、タイムライン、テスト結果は、すべて上の環境のローカルのanvilで直接実行した結果である（リハーサルの出力の文字列は日本語に訳した）。署名・送信はanvilのデフォルトのテスト用キーでだけ行った。取引ハッシュは実行し直すと変わる。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ブロック・ハッシュ、平均・清算ライン | 直接実行（デプロイスクリプトでデプロイしたあと、事故二つを順に作り、監視の周回と`ops/timeline.py`を回した） | 2026-10-21 |
| 境目225秒 | 直接実行（`forge test --offline --match-contract RehearsalTest -vv`） | 2026-10-21 |
| 監視のしきい値 | `ops/monitor.py`（このリポジトリの運用値） | 2026-10-21 |
| テストの合計 | 直接実行（`bash ci.sh`） | 2026-10-21 |
| キャップストーンのバージョンの最後の表 | 第253〜261講のバージョンはそのバージョンを作ったときに記録したciの値、第262〜264講のバージョンは直接実行し直したci | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/ （`forge script`、`forge test`、`cast call`、`cast send`、anvil `evm_increaseTime`）
- OpenZeppelin Contracts 5.4.0 `TimelockController`（予約・実行、最小待機）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （ユーザー定義エラー、immutable）
