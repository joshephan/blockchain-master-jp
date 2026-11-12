# 第214講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka | `foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のテスト結果とガスは、すべて上の環境で`forge test --offline`によって直接実行した結果である。anvilと外部への接続は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Gov58の設定 | `test/Count214.t.sol` setUp | 2026-10-21 |
| GovLateの設定 | `src/Gov58.sol`、`test/Count214.t.sol` | 2026-10-21 |
| おもちゃの配分 | `test/Count214.t.sol` | 2026-10-21 |
| テストのガス | 直接実行（`forge test --offline --match-contract Count214Test -vvv`） | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0
  - `governance/Governor.sol`：`state`の比較の順番、`_propose`のsnapshot = clock() + votingDelay()、deadline = snapshot + votingPeriod、`_castVote`が`proposalSnapshot`で票を読む
  - `governance/extensions/GovernorVotesQuorumFraction.sol` 62〜64行目：`quorum`
  - `governance/utils/Votes.sol`：getPastTotalSupplyのNOTE（委任していない票も総供給量に入る）、先頭のコメント"to protect against flash loans and double voting"
  - `governance/extensions/GovernorCountingSimple.sol` 15〜19行目（VoteType）、32〜34行目（COUNTING_MODE）、52〜65行目（`_quorumReached`、`_voteSucceeded`）
  - `governance/extensions/GovernorPreventLateQuorum.sol`：先頭のコメントと`_tallyUpdated`
- Foundry公式ドキュメント: https://getfoundry.sh/
