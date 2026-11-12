# 第214講 スナップショットと投票の集計

第14部 オラクル・クロスチェーン・ガバナンス・第58章 ガバナンスの実装

[← 第213講](../../part14/lecture213/) | [第14部 目次](../) | [第215講 →](../../part14/lecture215/)

## この講義の問い

票を数えるブロックはいつ決まるのか。定足数は何の何%なのか。賛成・反対・棄権は、それぞれ何に入るのか。同じ票が二度数えられないのは、どこで防ぐのか。チェーン上の投票は隠せるのか。

## 実習資料

### 準備

第58章の共用のガバナンスのプロジェクト`gov`から始める。第213講の投票権トークン`GovToken`と、OpenZeppelinのガバナーの組み立て`Gov58`をそのまま使い、この講義のテストファイル`Count214.t.sol`を足す。依存はOpenZeppelin Contracts 5.4.0（`lib/openzeppelin-contracts`）とforge-std（`lib/forge-std`）で、`foundry.toml`のremappingsが二つのパスを指す。すべての実行は、anvilなしでforgeの中だけで動く。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、OZ・forge-stdのremappings |
| [code/src/GovToken.sol](code/src/GovToken.sol) | ERC20Votesの投票権トークン（コンストラクタで発行） |
| [code/src/Gov58.sol](code/src/Gov58.sol) | Gov58（Settings・CountingSimple・Votes・QuorumFraction・TimelockControlの組み立て）、締め切りを延ばすGovLate（PreventLateQuorum）、提案の対象Box |
| [code/test/Count214.t.sol](code/test/Count214.t.sol) | Count214Testの11個：数えるブロックと締め切り、定足数の分母、賛成・反対・棄権、二重投票、公開の投票、最後のブロックの大きな票 |

### 実行結果

`forge test --offline --match-contract Count214Test -vvv`：

```
Ran 11 tests for test/Count214.t.sol:Count214Test
[PASS] test_abstainCountsForQuorum() (gas: 320253)
[PASS] test_doubleVoteReverts() (gas: 244079)
[PASS] test_forAloneBelowQuorum() (gas: 229611)
[PASS] test_hiddenVoteWithoutSalt() (gas: 2727)
[PASS] test_lastBlockWithoutExtension() (gas: 246806)
[PASS] test_lateQuorumExtends() (gas: 446992)
[PASS] test_quorumFromPastTotalSupply() (gas: 142395)
[PASS] test_sameTokensVoteOnce() (gas: 426472)
[PASS] test_snapshotAndDeadline() (gas: 212013)
[PASS] test_tieIsDefeated() (gas: 326149)
[PASS] test_votesArePublic() (gas: 212302)
Suite result: ok. 11 passed; 0 failed; 0 skipped
```

テストが確かめた値：

| テスト | 結果 |
|---|---|
| test_snapshotAndDeadline | 提案のブロック10 → snapshot 11（10 + 投票の遅延1）、deadline 61（11 + 期間50）。11 Pending、12 Active、61 Active、62 Defeated（誰も投票しない） |
| test_quorumFromPastTotalSupply | 委任した票は450だけなのに、quorum(11) = 40（総供給量1000の4%） |
| test_forAloneBelowQuorum | 賛成30だけ → Defeated（定足数に届かない） |
| test_abstainCountsForQuorum | 賛成30 + 棄権20 → Succeeded（棄権は定足数だけを満たす） |
| test_tieIsDefeated | 賛成100、反対100 → Defeated（同じなら否決） |
| test_doubleVoteReverts | 同じアカウントの2回目のcastVote → `GovernorAlreadyCastVote` |
| test_sameTokensVoteOnce | aliceが投票した100をfrankに渡すと、frankの今の票は100でもcastVoteの重みは0 |
| test_votesArePublic | `VoteCast(alice, id, 1, 100, "yes")`のログ、hasVoted true |
| test_hiddenVoteWithoutSalt | 票の値だけをハッシュすると0・1・2を入れてみて見つけられ、秘密の値を一緒に入れると見つけられない |
| test_lastBlockWithoutExtension | 最後のブロック61、carolの賛成200 → 62 Succeeded |
| test_lateQuorumExtends | 同じ票で締め切り61 → 71、延びた期間に反対200が入って同数で否決 |

`-vvvv`のトレースから読んだ行（アドレスは省略）：

```
├─ [0] VM::expectRevert(GovernorAlreadyCastVote(0x...A11cE))
├─ emit DelegateVotesChanged(delegate: 0x...A11cE, previousVotes: 100, newVotes: 0)
├─ emit DelegateVotesChanged(delegate: 0x...F4a2, previousVotes: 0, newVotes: 100)
├─ emit VoteCast(voter: 0x...F4a2, proposalId: ..., support: 1, weight: 0, reason: "")
├─ emit ProposalExtended(proposalId: ..., extendedDeadline: 71)
```

### 試すときの注意

- 票は`proposalSnapshot`（11番ブロック）の記録で読む。11番ブロックの中で`getPastVotes(alice, 11)`を呼ぶと`ERC5805FutureLookup`でリバートするので、投票は12番ブロックから受け付ける。
- `GovernorCountingSimple`の票の値は、0が反対、1が賛成、2が棄権である。`COUNTING_MODE`は`support=bravo&quorum=for,abstain`なので、定足数には賛成と棄権が入り、通る条件は賛成 > 反対である。
- `GovernorPreventLateQuorum`は、定足数に初めて届いたブロック + 延ばす期間で、締め切りを一度だけ延ばす。早く届けば（例：ブロック20 + 10 = 30 < 61）元の締め切り61のままである。
- テストの中の設定（投票の遅延1ブロック、期間50ブロック、定足数4%、延ばす期間10ブロック）は講義用のおもちゃの値である。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールとライブラリのバージョンが変わると、数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | 2026-10-21 |
| Gov58の設定（おもちゃの値） | 投票の遅延1ブロック、投票の期間50ブロック、提案のしきい値0、定足数4%、タイムロックの最小待ち時間2日 | 2026-10-21 |
| GovLateの設定（おもちゃの値） | 投票の遅延1ブロック、投票の期間50ブロック、しきい値0、定足数4%、延ばす期間10ブロック | 2026-10-21 |
| おもちゃの配分 | 1000を発行、alice 100、bob 100、carol 200、dave 30、erin 20、frank 0（全員が自分に委任）、デプロイしたアカウント550（委任なし） | 2026-10-21 |
| テストのガス（gov） | abstainCountsForQuorum 320,253 / doubleVoteReverts 244,079 / forAloneBelowQuorum 229,611 / hiddenVoteWithoutSalt 2,727 / lastBlockWithoutExtension 246,806 / lateQuorumExtends 446,992 / quorumFromPastTotalSupply 142,395 / sameTokensVoteOnce 426,472 / snapshotAndDeadline 212,013 / tieIsDefeated 326,149 / votesArePublic 212,302 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 隠した投票（コミット・リビールの投票）のコントラクト | 付録（扱わない） |
| チェーンの外で署名だけを集めて数える投票と、実行とのつなぎ | 付録（扱わない） |
| 票を分けて投じる集計（GovernorCountingFractional） | 付録（扱わない） |
| 定足数を時間で変えることと、超定足数（GovernorSuperQuorum） | 付録（扱わない） |
| 提案のid、提案のしきい値、取り消し、状態の流れ全体 | [第215講](../../part14/lecture215/) |
| タイムロックの待ち時間と実行 | [第216講](../../part14/lecture216/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
