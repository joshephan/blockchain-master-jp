# 第204講 出典

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
| Feed204Testのガスとログ | 直接実行（`forge test --offline --match-contract Feed204Test -vv`） | 2026-10-21 |
| latestRoundDataの戻り値、answeredInRound、decimals | Chainlink Data Feeds APIリファレンス: https://docs.chain.link/data-feeds/api-reference | 2026-10-21 |
| roundIdが順番に増えないこと、書かれた時刻0の意味 | Chainlink Data Feeds 過去のデータ: https://docs.chain.link/data-feeds/historical-data | 2026-10-21 |

## 参考資料

- Chainlink Data Feeds APIリファレンスの原文: "uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound", answeredInRound "Deprecated - Previously used when answers could take multiple rounds to be computed", decimals "Get the number of decimals present in the response value."
- Chainlink Data Feeds 過去のデータの原文: "roundId is NOT incremental. Not all roundIds are valid.", "A timestamp with zero value means the round is not complete and should not be used."
- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36（明示的な変換にはあふれの検査がつかない）: https://docs.soliditylang.org/en/v0.8.36/
