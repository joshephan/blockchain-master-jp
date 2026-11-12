# 第263講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| anvil | チェーン番号31337、デフォルトのテスト用キー | `anvil`の起動画面 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| Python | 標準ライブラリだけ（`ops/`） | - | 2026-10-21 |

付録の監視の周回の出力、警報、証明の確認、heartbeatの結果は、すべて上の環境のローカルのanvilで直接実行した結果である（文字列は日本語に訳した）。署名・送信はanvilのデフォルトのテスト用キーでだけ行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 監視のしきい値 | `ops/monitor.py`、設計ドキュメント15節（このリポジトリの運用値） | 2026-10-21 |
| アドレス・ブロック・数字 | 直接実行（第262講の順番でデプロイ・上場したあと、ユーザーの取引、直接送金、予定にない予約、価格0.9を順に作り、監視の周回を回した） | 2026-10-21 |
| ABIから数えた名前27個 | 直接実行（`python -I ops/abi.py --check`） | 2026-10-21 |
| 通知・スケジューラー | ローカルの受ける側と`ops/loop.py`まで（実際のサービスは確認していない） | 2026-10-21 |

## 参考資料

- Ethereum JSON-RPC `eth_getLogs`、`eth_getStorageAt`、`eth_getProof`、`eth_call`（`ops/indexer.py`、`ops/market_verify.py`、`ops/monitor.py`が使う）
- イーサリアムのイエローペーパー（RLP、ブロックヘッダー、マークルパトリシアトライ）: https://ethereum.github.io/yellowpaper/paper.pdf
- Foundry公式ドキュメント: https://getfoundry.sh/ （`cast call`、`cast sig`、`cast keccak`、anvil `evm_increaseTime`）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （ストレージの欄の配置、mappingの欄の位置keccak256(キー . スロット)、イベントのtopic0）
- OpenZeppelin Contracts 5.4.0 `TimelockController`（CallScheduled・CallExecuted・Cancelledイベント、作業id）
