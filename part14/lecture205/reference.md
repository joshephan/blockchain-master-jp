# 第205講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | foundry.toml | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。外部への接続、オラクルサービスへの要求、鍵は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Stale205Testのガスとログ | 直接実行（`forge test --offline --match-contract Stale205Test -vv`） | 2026-10-21 |
| Deviation Threshold、Heartbeat Threshold | Chainlink 構造の概要（分散モデル）: https://docs.chain.link/architecture-overview/architecture-decentralized-model | 2026-10-21 |
| circuit breakers、単一の出どころのフィードの追加の安全装置 | Chainlink Data Feeds フィードの選び方: https://docs.chain.link/data-feeds/selecting-data-feeds | 2026-10-21 |

実在するフィードのハートビート・偏差の値は確かめていない。フィードごとに違い、フィード側で変わることがあるので、使う前にそのフィードの公式ドキュメントで確かめる。

## 参考資料

- Chainlink 構造の概要の原文: Deviation Threshold "A new aggregation round starts when a node identifies that the off-chain values deviate by more than the defined deviation threshold from the onchain value.", Heartbeat Threshold "A new aggregation round starts after a specified amount of time from the last update."
- Chainlink フィードの選び方の原文: "Circuit breakers are safety measures that monitor data feeds for unexpected scenarios such as stale prices"、単一の出どころのフィードは "MUST implement additional safeguards such as value bounds, caps, circuit breakers, freshness checks, fallback behavior"
- L2シーケンサーの稼働フィード: Chainlink公式ドキュメント（この講義では原文を確かめていない）
- Foundry公式ドキュメント: https://getfoundry.sh/
