# 第213講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | foundry.toml | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。anvilのガスは、ローカルのanvil一つに既定のテスト用アカウントで送った取引のレシートの値である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Votes213Testのガスと結果 | 直接実行（`forge test --offline --match-contract Votes213Test -vvv`） | 2026-10-21 |
| 送金・委任のガス、チェックポイントの欄、CLOCK_MODE | 直接実行（ローカルのanvil、`cast send`・`cast call`） | 2026-10-21 |
| Votes.solのバージョンの表記 | OpenZeppelin Contracts 5.4.0 `contracts/governance/utils/Votes.sol`の先頭のコメント（last updated v5.2.0） | 2026-10-21 |
| 事件の年 | 講義の設計ドキュメントのポストモーテムの事件の割り当て | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0
  - `contracts/governance/utils/Votes.sol`：先頭のコメント（票として数えるには委任が必要、委任の記録をチェーンに残す理由と選べる委任）、`_moveDelegateVotes`など181〜213行目、`_validateTimepoint`（`ERC5805FutureLookup`）、`getPastVotes`、`delegateBySig`、`CLOCK_MODE`・`clock`
  - `contracts/utils/structs/Checkpoints.sol`：`Checkpoint208`、`_insert`
  - `contracts/token/ERC20/extensions/ERC20Votes.sol`：`_maxSupply`（type(uint208).max）
- EIP-712 型付き構造化データの署名: https://eips.ethereum.org/EIPS/eip-712
- ERC-20 トークン標準（approve・transferFromの上限との比較）: https://eips.ethereum.org/EIPS/eip-20
- ERC-5805 投票の委任（`ERC5805FutureLookup`）: https://eips.ethereum.org/EIPS/eip-5805
- Beanstalk（2022）：実行の瞬間の保有量で数えた票を、借りた票で満たして実行のしきい値を超えた事件
- Foundry公式ドキュメント（`forge create`、`cast send`）: https://getfoundry.sh/
