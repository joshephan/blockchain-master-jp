# 第215講 Governorの実装

第14部 オラクル・クロスチェーン・ガバナンス・第58章 ガバナンスの実装

[← 第214講](../../part14/lecture214/) | [第14部 目次](../) | [第216講 →](../../part14/lecture216/)

## この講義の問い

ガバナーは、どんな部品をどうつなぎ合わせて作るのか。提案のidは何のハッシュで、だから投票する人は何を読むべきなのか。誰でも提案できるのか。提案は誰がいつ取り消すのか。ガバナー自身の設定は誰が変えるのか。

## 実習資料

### 準備

第58章の共用のガバナンスのプロジェクト`gov`（投票権トークン`GovToken`、ガバナーの組み立て`Gov58`、提案の対象`Box`）に、この講義のテストファイル`Gov215.t.sol`を足す。依存はOpenZeppelin Contracts 5.4.0（`lib/openzeppelin-contracts`）とforge-std（`lib/forge-std`）である。`noover`は`Gov58`から`state`のoverrideを一つ抜いたコピーで、ビルドがどう失敗するかを見るためだけに使う（同じ`lib/`が必要である）。anvilなしでforgeとcastだけを使う。

### コード

| ファイル | 内容 |
|---|---|
| [code/gov/foundry.toml](code/gov/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、OZ・forge-stdのremappings |
| [code/gov/src/GovToken.sol](code/gov/src/GovToken.sol) | ERC20・ERC20Permit・ERC20Votesの投票権トークン（コンストラクタで発行） |
| [code/gov/src/Gov58.sol](code/gov/src/Gov58.sol) | Gov58（モジュール六つを継承、override九つ）、GovLate、Box |
| [code/gov/test/Gov215.t.sol](code/gov/test/Gov215.t.sol) | Gov215Testの9個：提案のid、同じ提案を2回、提案のしきい値、提案者の表示、取り消し、まとめての実行、設定の変更、状態の流れ |
| [code/noover/foundry.toml](code/noover/foundry.toml) | govと同じ設定 |
| [code/noover/src/Gov58.sol](code/noover/src/Gov58.sol) | `state`のoverrideを抜いたGov58（ビルドの失敗の確認用） |

### 実行結果

`forge test --offline --match-contract Gov215Test -vvv`：

```
Ran 9 tests for test/Gov215.t.sol:Gov215Test
[PASS] test_batchIsAllOrNothing() (gas: 689414)
[PASS] test_cancelOnlyPendingByProposer() (gas: 183061)
[PASS] test_cancelWhilePending() (gas: 154125)
[PASS] test_lifecycle() (gas: 606887)
[PASS] test_proposalIdIsHash() (gas: 140361)
Logs:
  proposalId: 0x1de73a3b699f260a7e570db8c20b03ea6e2fd82ddfd2c428c3dbeeac62970d33
  box: 0x15cF58144EF33af1e14b5208015d11F9143E27b9

[PASS] test_proposerSuffix() (gas: 177300)
[PASS] test_sameProposalTwiceReverts() (gas: 233306)
[PASS] test_settingsOnlyByGovernance() (gas: 535418)
[PASS] test_thresholdBlocksSmallProposer() (gas: 68624)
Suite result: ok. 9 passed; 0 failed; 0 skipped
```

提案のidをcastで計算し直した結果。`cast calldata`で呼び出しのバイトを、`cast keccak`で説明のハッシュを作り、`cast abi-encode "f(address[],uint256[],bytes[],bytes32)"`で四つの値をまとめてもう一度`cast keccak`すると、テストのidと同じになる：

```
setValue(42) calldata:     0x55241077000000000000000000000000000000000000000000000000000000000000002a
"set value 42" のハッシュ: 0x2654f36f35a1cfb56c1ded31c39e57b2f716da7168c0a19ec8cb899c3ed569c6
提案のid:                  0x1de73a3b699f260a7e570db8c20b03ea6e2fd82ddfd2c428c3dbeeac62970d33
```

`cast decode-calldata "setValue(uint256)" 0x5524...002a`は`42`を返す。

`-vvvv`のトレースで確かめたリバートと値：

| テスト | 結果 |
|---|---|
| test_sameProposalTwiceReverts | `GovernorUnexpectedProposalState(id, 0, 0x00…00)`、説明を変えると別のid |
| test_thresholdBlocksSmallProposer | `GovernorInsufficientProposerVotes(dave, 5, 10)` |
| test_proposerSuffix | 説明の末尾が`#proposer=<alice>`の提案をbobが上げると`GovernorRestrictedProposer(bob)` |
| test_cancelOnlyPendingByProposer | 他人のPendingに`GovernorUnableToCancel(id, bob)`、提案者でもActiveでは`GovernorUnableToCancel(id, alice)` |
| test_batchIsAllOrNothing | `Box::setValue(42)`の成功のあと`setValue(7)`が`NotOwner()`でリバートして全体が戻り、最初のBoxの値は0、提案はQueued(5) |
| test_settingsOnlyByGovernance | 直接の呼び出しは`GovernorOnlyExecutor(alice)`、投票を経たあとタイムロックが`setVotingPeriod(10)`を呼び、`VotingPeriodSet(50, 10)` |
| test_lifecycle | state 0 → 1 → 4 → 5（eta 172801） → 7、Box 42 |

`noover`で`forge build --offline`：

```
Error (6480): Derived contract must override function "state". Two or more base classes define function with same name and parameter types.
  --> src/Gov58.sol:15:1:
```

### 試すときの注意

- 提案のidは、呼び出しの対象・値・calldata・説明のハッシュだけをまとめたハッシュである。チェーンの番号とガバナーのアドレスは入らない（`hashProposal`のコメント）。同じ提案をもう一度上げるには、説明を変えなければならない。
- ガバナーは、説明とcalldataが合っているかを突き合わせない。説明が"set value 42"でもcalldataが`setValue(7)`ならそのまま実行される。投票の前にcalldataをデコードして読む。
- 提案のしきい値の比較は、直前のブロック（`clock() - 1`）の票で行う。
- 説明の末尾の`#proposer=`の接尾辞が42文字のアドレスでなければ、制限はかからない。
- OZ 5.4.0で`Expired`(6)を返すのは`GovernorTimelockCompound.state`だけである。`GovernorTimelockControl.state`は、Queuedをタイムロックの作業の状態で分け直す（タイムロックで直接実行されていればExecuted、取り消されていればCanceled）。
- `onlyGovernance`のコメントのとおり、タイムロックに提案者の役割を追加でもらったアカウントも、ガバナーの設定は投票なしに変えられない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールとライブラリのバージョンが変わると、数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | 2026-10-21 |
| Gov58の設定（おもちゃの値） | 投票の遅延1ブロック、投票の期間50ブロック、提案のしきい値10票、定足数4%、タイムロックの最小待ち時間2日（172800秒） | 2026-10-21 |
| トークンの配分（おもちゃの値） | 1000のうちalice 100、bob 100、dave 5、残り795はデプロイしたアカウント（委任しない） | 2026-10-21 |
| 提案のid・アドレス | id `0x1de73a3b699f260a7e570db8c20b03ea6e2fd82ddfd2c428c3dbeeac62970d33`、Box `0x15cF58144EF33af1e14b5208015d11F9143E27b9`、説明のハッシュ`0x2654f36f35a1cfb56c1ded31c39e57b2f716da7168c0a19ec8cb899c3ed569c6` | 2026-10-21 |
| テストのガス（gov） | batchIsAllOrNothing 689,414 / cancelOnlyPendingByProposer 183,061 / cancelWhilePending 154,125 / lifecycle 606,887 / proposalIdIsHash 140,361 / proposerSuffix 177,300 / sameProposalTwiceReverts 233,306 / settingsOnlyByGovernance 535,418 / thresholdBlocksSmallProposer 68,624 | 2026-10-21 |
| Expiredを返すモジュール | OZ 5.4.0の時点でGovernorTimelockCompoundだけ | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 提案のidを連番に変えるモジュール（GovernorSequentialProposalId）・提案を保存するモジュール（GovernorStorage） | 付録 |
| 提案の監視者（GovernorProposalGuardian） | [第216講](../../part14/lecture216/) |
| ガバナーが直接お金を受け取るrelay | [第216講](../../part14/lecture216/) |
| チェーンの外の署名の投票ツール、票を分けて投じる集計（GovernorCountingFractional・Overridable） | 付録 |
| ガバナンスの層の分析 | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
