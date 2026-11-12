# 第216講 タイムロックと実行

第14部 オラクル・クロスチェーン・ガバナンス・第58章 ガバナンスの実装

[← 第215講](../../part14/lecture215/) | [第14部 目次](../) | [第217講 →](../../part14/lecture217/)

## この講義の問い

タイムロックは何を待たせ、誰が何をできるのか。ガバナーにタイムロックを付けると、呼び出しは誰が送るのか。タイムロック自体の設定は誰が変えるのか。デプロイした人に残る権限はないのか。Marketの管理者の座を、ガバナンス + タイムロックに移すべきか。

## 実習資料

### 準備

プロジェクトは二つである。`gov`は、第58章の共用のガバナンスのプロジェクト（投票権トークン`GovToken`、ガバナー`Gov58`、提案の対象`Box`）に、この講義のテスト`Timelock216.t.sol`を足したものである。依存はOpenZeppelin Contracts 5.4.0（`lib/openzeppelin-contracts`）とforge-std（`lib/forge-std`）である。

`market`は、通しプロジェクトMarket（第53章の終わりのバージョン、srcは直さない）にガバナー・タイムロックを付けてみるテスト二つを足したコピーである。テストファイルは、OpenZeppelin Contracts 5.4.0の`contracts/`フォルダを`lib/`の外の`vendor/oz/`に置き、相対パスで読み込む。forge-stdは`lib/forge-std`に置く。Marketの`foundry.toml`は、ガス記録を前回の記録と照合する（`gas_snapshot_check = true`）ようになっているので、このコピーでは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`をつけて実行する。すべての実行は、anvilなしでforgeの中だけで動く。

### コード

| ファイル | 内容 |
|---|---|
| [code/gov/foundry.toml](code/gov/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、OZ・forge-stdのremappings |
| [code/gov/src/GovToken.sol](code/gov/src/GovToken.sol) | ERC20Votesの投票権トークン |
| [code/gov/src/Gov58.sol](code/gov/src/Gov58.sol) | Gov58（GovernorTimelockControlを含む）、GovLate、Box |
| [code/gov/test/Timelock216.t.sol](code/gov/test/Timelock216.t.sol) | Timelock216Testの8個（最小の待ち時間、役割、作業のid、先行する作業、待ち時間の変更、デプロイの管理者）、GovTimelock216Testの4個（実行するアドレス、取り消しの役割） |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（solc 0.8.30、optimizer runs 200、via-IR、evm osaka、ガス記録の検査） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 通しプロジェクトMarket（第53章の終わりのバージョン） |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | Marketのインターフェース |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | 利息・ポジションの計算のライブラリ |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/GovParts58.sol](code/market/test/GovParts58.sol) | テスト用のGovTokenとGov58（`vendor/oz`のコピーを読み込む） |
| [code/market/test/GovMarket58.t.sol](code/market/test/GovMarket58.t.sol) | GovMarket58Testの4個：admin = タイムロックでデプロイしたMarketのガバナンスの経路 |

### 実行結果

`gov`で`forge test --offline --match-contract "Timelock216Test|GovTimelock216Test" -vvv`：

```
Ran 4 tests for test/Timelock216.t.sol:GovTimelock216Test
[PASS] test_executorIsTimelock() (gas: 612539)
[PASS] test_guardianCancelsQueued() (gas: 689447)
[PASS] test_guardianCannotSchedule() (gas: 41935)
[PASS] test_permissionOnGovernorFails() (gas: 615129)
Suite result: ok. 4 passed; 0 failed; 0 skipped

Ran 8 tests for test/Timelock216.t.sol:Timelock216Test
[PASS] test_deployAdminSkipsDelay() (gas: 1496746)
[PASS] test_minDelayEnforced() (gas: 50442)
[PASS] test_noDeployAdmin() (gas: 32508)
[PASS] test_operationIdIsHash() (gas: 22633)
[PASS] test_predecessorOrder() (gas: 289594)
[PASS] test_readyThenDoneOnce() (gas: 295770)
[PASS] test_strangerCannotSchedule() (gas: 51520)
[PASS] test_updateDelayOnlySelf() (gas: 135828)
Suite result: ok. 8 passed; 0 failed; 0 skipped

Ran 2 test suites: 12 tests passed, 0 failed, 0 skipped (12 total tests)
```

`market`で`forge test --offline --match-contract GovMarket58Test -vvv`（ガス記録の検査を切ったまま）：

```
Ran 4 tests for test/GovMarket58.t.sol:GovMarket58Test
[PASS] test_addAssetThroughGovernance() (gas: 565523)
Logs:
  blocks waited: 52
  seconds waited: 172800

[PASS] test_adminIsTimelock() (gas: 8395)
[PASS] test_governorIsNotAdmin() (gas: 61823)
[PASS] test_pauseWaitsForDelay() (gas: 1248942)
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

`-vvvv`のトレースで確かめたリバートと値：

| テスト | 結果 |
|---|---|
| test_minDelayEnforced | 1日でかけると`TimelockInsufficientDelay(86400, 172800)` |
| test_strangerCannotSchedule | 提案の役割のないアカウント → `AccessControlUnauthorizedAccount(アカウント, PROPOSER_ROLE)` |
| test_readyThenDoneOnce | すぐのexecuteと2回目のexecuteのどちらも`TimelockUnexpectedOperationState` |
| test_predecessorOrder | 先行する作業の前に実行 → `TimelockUnexecutedPredecessor`、順番どおりにするとBox 7 |
| test_updateDelayOnlySelf | 直接の呼び出し → `TimelockUnauthorizedCaller`、自分にかける作業で`MinDelayChange(172800, 259200)` |
| test_deployAdminSkipsDelay | デプロイの管理者が待ち時間なしに`RoleGranted(PROPOSER, …)`、renounceのあとは`AccessControlUnauthorizedAccount` |
| test_permissionOnGovernorFails | Boxのowner = ガバナー → `NotOwner()`、提案はQueued(5)に残る |
| test_guardianCancelsQueued | 取り消しの役割のアドレスが`Cancelled` → 提案はCanceled(2)、あとのexecuteは`GovernorUnexpectedProposalState`、Box 0 |
| test_governorIsNotAdmin | ガバナーとaliceが直接呼ぶと`NotAdmin` |
| test_pauseWaitsForDelay | 停止の提案が待っているあいだ預け入れ50・引き出し30は成功、実行のあと`setStatus(1)`、預け入れ1 → `NotActive(1)`、引き出し120は成功 |

### 試すときの注意

- TimelockControllerのコンストラクタは、DEFAULT_ADMIN_ROLEをタイムロック自身に必ず与え、admin引数が0アドレスでなければそのアカウントにも与える。デプロイが終わったらそのアカウントの役割を捨て、チェーンで`hasRole`で確かめる。
- 実行の役割を0アドレスに与えると、誰でも実行できる（`onlyRoleOrOpenRole`）。待ち時間が終わっても、誰かがexecuteを送らなければ実行されない。
- タイムロックの作業の状態はUnset・Waiting・Ready・Doneの四つである。
- GovernorTimelockControlがタイムロックの作業に使うsaltは、`bytes20(ガバナーのアドレス) ^ 説明のハッシュ`である。
- ガバナーにタイムロックを付けると、呼び出しを送るアドレスはタイムロックである。権限とお金はタイムロックに置く。
- ガバナー以外のアドレスに取り消しの役割を与えると、投票で通った提案も止められる（GovernorTimelockControlのWARNING）。
- テストの中の待ち時間2日、投票の遅延1ブロック、投票の期間50ブロックは講義用のおもちゃの値である。実際のチェーンでは、ブロック52個を待つのにもっと時間がかかる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールとライブラリのバージョンが変わると、数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0（govは`lib/`、marketのテスト用は`vendor/oz/`） | 2026-10-21 |
| タイムロック・ガバナーの設定（おもちゃの値） | 最小の待ち時間2日（172800秒）、投票の遅延1ブロック、投票の期間50ブロック、提案のしきい値0、定足数4%、待ち時間の変更のテスト3日（259200秒） | 2026-10-21 |
| Marketのガバナンスの経路 | 提案から実行までブロック52個・172,800秒 | 2026-10-21 |
| テストのガス（gov） | deployAdminSkipsDelay 1,496,746 / minDelayEnforced 50,442 / noDeployAdmin 32,508 / operationIdIsHash 22,633 / predecessorOrder 289,594 / readyThenDoneOnce 295,770 / strangerCannotSchedule 51,520 / updateDelayOnlySelf 135,828 / executorIsTimelock 612,539 / guardianCancelsQueued 689,447 / guardianCannotSchedule 41,935 / permissionOnGovernorFails 615,129 | 2026-10-21 |
| テストのガス（market） | addAssetThroughGovernance 565,523 / adminIsTimelock 8,395 / governorIsNotAdmin 61,823 / pauseWaitsForDelay 1,248,942 | 2026-10-21 |
| Marketの基準のバージョン | 第53章の終わりのバージョン（テスト136個）。このコピーはテストを17個足して153個通過、srcの差なし | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Marketの管理者の役割を二つに分ける（停止はマルチシグ、設定はタイムロック） | 第70〜72章の再構築（第253講〜[第264講](../../part20/lecture264/)） |
| タイムロックの待ち時間を関数ごとに変える形（GovernorTimelockAccess） | 付録 |
| アップグレードの鍵をタイムロックで縛ること | [第256講](../../part20/lecture256/) |
| ガバナーのrelayと、ガバナーが受け取った資産 | 付録 |
| マルチシグの署名の運用（署名するハッシュ、署名の順番） | [第217講](../../part14/lecture217/) |
| ガバナンスの層の分析 | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
