# 第271講 ガバナンストークンの政治学

第21部 事件アーカイブと終章・第75章 権力・規制と設計思想

[← 第270講](../../part21/lecture270/) | [第21部 目次](../) | [第272講 →](../../part21/lecture272/)

## この講義の問い

ガバナンストークンが与える票は、誰の権力なのか。チェーンはなぜ人ではなくトークンを数え、その結果、票はどこに集まるのか。票のない人、お金を預けただけの人には何が残るのか。

## 実習資料

### 準備

通しプロジェクトMarketの第53章末のバージョン（srcは直さない）にOpenZeppelinのガバナー・タイムロックを付けてみるテスト用のコピーである。Marketのadminの席を、デプロイの引数でタイムロックに与える。テストファイルは、OpenZeppelin Contracts 5.4.0の`contracts/`フォルダを`lib/`の外の`vendor/oz/`に置き、相対パスで取り込む。forge-stdは`lib/forge-std`に置く。Marketの`foundry.toml`はガス記録を前の記録と照らし合わせるように（`gas_snapshot_check = true`）なっているので、このコピーでは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`を付けて実行する。すべての実行はanvilなしで、forgeの中だけで動く。

テストの土台は、ガバナンストークン1000個をデプロイしたアカウントがすべて受け取り、代理人五人（d1 160、d2 120、d3 90、d4 50、d5 30、合計450）に分けて、それぞれ自分に委任させた分布である。残りの550は、デプロイしたアカウントが委任なしで持つ。ガバナーの設定は、投票の遅延1ブロック、期間50ブロック、提案のしきい値0、定足数4%、タイムロックの最小待機2日である（すべておもちゃの値）。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ガス記録の照合 |
| [code/test/Politics271.t.sol](code/test/Politics271.t.sol) | Politics271Test七つ：アドレスを分けても票の合計はそのまま、委任していない分は票0、代理人一人が単独で通過、代理人二人が三人を上回る、お金を預けた側は票0だが待機のあいだに引き出して出ていく、休んでいた分が目を覚ます、金庫のトークンが投票で一人の代理人に委任される |
| [code/test/GovParts58.sol](code/test/GovParts58.sol) | テスト用のGovToken（ERC20Votes、コンストラクターでデプロイしたアカウントに全部発行）とGov58（Governor + Settings + CountingSimple + Votes + QuorumFraction + TimelockControl） |
| [code/test/GovMarket58.t.sol](code/test/GovMarket58.t.sol) | GovMarket58Test四つ：ガバナンスで資産を追加、admin = タイムロック、ガバナーはadminではない、停止も待機を待つ |
| [code/src/Market.sol](code/src/Market.sol) | 通しプロジェクトMarket（第53章末のバージョン） |
| [code/src/IMarket.sol](code/src/IMarket.sol) | Marketのインターフェース |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息・持ち分の計算ライブラリ |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/src/MockToken.sol](code/src/MockToken.sol) | テスト用のトークン |
| [code/test/](code/test/)の残り | 第53章末のバージョンのMarketのテスト全体（Keys.t.solなど）とテストの補助 |

### 実行結果

`forge test --offline --match-contract "Politics271Test|GovMarket58Test" -vv`と全体の`forge test --offline`：

```
Ran 7 tests for test/Politics271.t.sol:Politics271Test
[PASS] test_depositorHasNoVoteButCanLeave() (gas: 798674)
[PASS] test_idleHolderWakesUp() (gas: 681155)
[PASS] test_idleTokensHaveNoVotes() (gas: 83966)
[PASS] test_oneDelegatePasses() (gas: 196741)
[PASS] test_splitAddsNoVotes() (gas: 735312)
[PASS] test_treasuryVotesMovedByVote() (gas: 529733)
[PASS] test_twoDelegatesOutvoteThree() (gas: 504901)
Suite result: ok. 7 passed; 0 failed; 0 skipped

Ran 4 tests for test/GovMarket58.t.sol:GovMarket58Test
[PASS] test_addAssetThroughGovernance() (gas: 565523)
Logs:
  blocks waited: 52
  seconds waited: 172800

[PASS] test_adminIsTimelock() (gas: 8395)
[PASS] test_governorIsNotAdmin() (gas: 61823)
[PASS] test_pauseWaitsForDelay() (gas: 1248942)
Suite result: ok. 4 passed; 0 failed; 0 skipped

Ran 2 test suites: 11 tests passed, 0 failed, 0 skipped (11 total tests)
(全体) Ran 46 test suites: 160 tests passed, 0 failed, 0 skipped (160 total tests)
```

| テスト | 確かめたこと |
|---|---|
| test_splitAddsNoVotes | 160をアドレス四つに分けても票の合計は160（委任していないアドレスは0） |
| test_idleTokensHaveNoVotes | 委任していない550は票0、定足数は供給量基準で40 |
| test_oneDelegatePasses | d1（160）が単独で定足数を満たし、提案が通過 |
| test_twoDelegatesOutvoteThree | d1・d2（280）が残りの三人（170）を上回る |
| test_depositorHasNoVoteButCanLeave | 100を預けたbobは票0、停止の提案が通っても2日の待機のあいだに100を引き出して出ていく、実行後のMarketの状態は`DepositPaused` |
| test_idleHolderWakesUp | 休んでいた550が自分への委任1回で目を覚まし、代理人五人（450）を上回る（賛成550、反対450、Succeeded） |
| test_treasuryVotesMovedByVote | タイムロックの金庫が持つ550は票0、投票でd1に委任するとd1の票は710 |

### 試すときの注意

- チェーンは人を数えられず、トークンを数える。アドレスを複数に分けても票は増えず、一人がアドレスを千個作れるので、アドレスを数えることも人を数えることではない。
- ERC20Votesでは、委任するまで残高は票にならない。休んでいる分も、委任1回ですぐに票になる。定足数は委任された票ではなく供給量基準である。
- 最初の持ち分は、コンストラクターの引数一つ（`GovToken(1000)`）でデプロイしたアカウントに集まる。誰がいくら最初に受け取るかが、最初の投票の結果を決める。
- 金庫（タイムロック）が持つトークンには票がないが、金庫を動かす投票で委任先を決めれば、その分が一人の代理人に積み上がる。
- お金を預けた側に残る道は、待機時間のあいだの引き出しである。タイムロックが待っているあいだに引き出せてこそ、その道が生きる。
- テストの設定値（遅延1ブロック、期間50ブロック、しきい値0、定足数4%、待機2日）とトークンの分布はおもちゃの値である。

## 時効性のあるデータ

基準日時点の値。ライブラリとツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| OpenZeppelin Contracts | 5.4.0（Governor、GovernorSettings、GovernorCountingSimple、GovernorVotes、GovernorVotesQuorumFraction、GovernorTimelockControl、TimelockController、ERC20Votes、ERC20Permit） | 2026-10-21 |
| テストの設定値 | 投票の遅延1ブロック、期間50ブロック、提案のしきい値0、定足数4%、タイムロックの最小待機2日（おもちゃの値） | 2026-10-21 |
| ツール | Foundry 1.8.3、solc 0.8.30 | 2026-10-21 |
| テストのバージョン | 第53章末のバージョンのMarketのコピー（srcはそのまま、admin = タイムロックはデプロイの引数） | 2026-10-21 |
| Marketの基準のバージョン（判断） | キャップストーンの最後のバージョン（要件N-03「投票の道は作らない」、決定記録D-13 設定キー = タイムロック2日・停止キー = マルチシグが直接、A-03、S-01） | 2026-10-21 |
| Beanstalk | 2022 | 2026-10-21 |
| 実在するプロトコルのトークンの分布・投票率 | 載せない | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| チェーンの外の署名投票ツールと実行の連結 | 付録（第58章と同じ） |
| 票を売り買いする市場・賄賂の形 | 扱わない |
| 実在するプロトコルのトークンの分布・投票率 | 扱わない |
| 一人一票をチェーンで行おうとする身元の証明 | 扱わない |
| キャップストーンのバージョンのキーの分割とガバナンス | [第257講](../../part20/lecture257/)（この講義でその役割の分け方をもう一度使う） |
| 預け入れの集中と分散化の測定（[第18講](../../part1/lecture18/)の先送りにしたテーマ） | この講義（おもちゃの分布まで） |

出典と参考資料は[reference.md](reference.md)にまとめた。
