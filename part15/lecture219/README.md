# 第219講 ERC-4337：UserOperation、Bundler、EntryPoint

第15部 アカウント抽象化・第59章 アカウント抽象化の構造

[← 第218講](../../part15/lecture218/) | [第15部 目次](../) | [第220講 →](../../part15/lecture220/)

## この講義の問い

チェーンを変えずにコードのアカウントを使うには、誰が何を送ればよいのか。代わりに送る側はどうやってお金を取り戻し、アカウントは何を信じるのか。署名はどこまで縛られるのか。

## 実習資料

### 準備

第59〜60章の共用のアカウント抽象化のプロジェクト`aa`から始める。この講義では、ERC-4337の構造体・インターフェース（`UserOp.sol`）、講義用のEntryPointのまね（`EntryPoint219.sol`）、講義用のアカウント（`Account219.sol`）とそのテストを使う。`EntryPoint219`は、標準の二つのループ（検証・実行）と預けたお金の精算だけを移したまねで、実際のEntryPointが行うシミュレーションの規則・ステーク・評判・Factory・Aggregatorはない。実際の資産には使わない。

テストの土台（`test/Base.sol`）が、通しプロジェクトMarket（第53章の終わりのバージョン）のsrcのコピーと標準のトークン`StdToken`を`src/market/`に置いてデプロイする。依存はforge-std（`lib/forge-std`）一つである。anvilのデモは、`script/Demo.s.sol`の`run219()`を`forge script`で回す：アカウント0番がデプロイし、持ち主の鍵（デモ用の鍵`0xA11CE`、実際の資産には使わない）はuserOpHashに署名だけをし、アカウント1番（バンドラー）が`handleOps`のトランザクションを送る。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシードを固定 |
| [code/src/UserOp.sol](code/src/UserOp.sol) | PackedUserOperation、IAccount、IPaymaster、PostOpMode、ValidationData |
| [code/src/EntryPoint219.sol](code/src/EntryPoint219.sol) | 講義用のEntryPointのまね：検証のループ・実行のループ、預けたお金、getUserOpHash（EIP-712のドメインにチェーンの番号・EntryPointのアドレス）、ナンスのkey・sequence、AAのエラー |
| [code/src/Account219.sol](code/src/Account219.sol) | 講義用のアカウント：validateUserOp（EntryPointだけ、署名が失敗なら1を返す）、execute・executeBatch（EntryPointだけ） |
| [code/test/Base.sol](code/test/Base.sol) | MarketとStdTokenをデプロイするテストの土台 |
| [code/test/OpBase.sol](code/test/OpBase.sol) | UserOperationを作って署名するテストの補助 |
| [code/test/EntryPoint219.t.sol](code/test/EntryPoint219.t.sol) | EntryPoint219Testの9個 |
| [code/script/Demo.s.sol](code/script/Demo.s.sol) | anvilのデモのスクリプト（`run219()`） |
| [code/src/Paymaster220.sol](code/src/Paymaster220.sol) | 第220講のペイマスター。`Demo.s.sol`が一緒に読み込むので、ビルドに必要で入れた |
| [code/src/market/Market.sol](code/src/market/Market.sol) | 通しプロジェクトMarket（第53章の終わりのバージョン）のコピー |
| [code/src/market/IMarket.sol](code/src/market/IMarket.sol) | Marketのインターフェース |
| [code/src/market/MarketMath.sol](code/src/market/MarketMath.sol) | 利息・ポジションの計算のライブラリ |
| [code/src/market/MarketTypes.sol](code/src/market/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/src/market/StdToken.sol](code/src/market/StdToken.sol) | 承認を要求するテスト用の標準のトークン |

### 実行結果

`forge test --offline --match-contract EntryPoint219Test -vv`：

```
Ran 9 tests for test/EntryPoint219.t.sol:EntryPoint219Test
[PASS] test_badSignatureRejected() (gas: 131389)
[PASS] test_executionRevertStillCharges() (gas: 228038)
Logs:
  reverted op cost 277268000000000

[PASS] test_handleOpsDepositsToMarket() (gas: 363574)
Logs:
  prefund 1650000000000000
  actualGasCost 525648000000000
  actualGasUsed 262824
  deposit left 1124352000000000

[PASS] test_noFundsRejected() (gas: 115351)
[PASS] test_nonceKeysIndependent() (gas: 509069)
[PASS] test_onlyEntryPointExecutes() (gas: 38230)
[PASS] test_otherChainSigRejected() (gas: 137563)
[PASS] test_sameOpTwiceRejected() (gas: 355754)
[PASS] test_userOpHashBindsChainAndEntryPoint() (gas: 58523)
Logs:
  0x448a789a30d3170f2aac53327c8e7f99b3437c2b63e2b4001f80c2308bc2036f
  0x53181a4ccd92734ade8ab63ee57431d40437e5503ff0dcf4c939381d6903ec5b
  0x00093d1d5f2784cf848fa8e0fe2e90e51e1b8937ac61454411aafcac05f60356

Suite result: ok. 9 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_handleOpsDepositsToMarket | 承認 + 預け入れのUserOperation一つで、positionsのアカウント100、持ち主のETH 0、getNonce 1。prefund 1,650,000,000,000,000 weiのうち実際のコスト525,648,000,000,000 wei、残った預けたお金1,124,352,000,000,000 wei |
| test_executionRevertStillCharges | 預け入れ0 → `Market::deposit`が`ZeroAmount`、アカウントが`CallFailed(1, 0x1f2a2005)`でリバートしても、コスト277,268,000,000,000 weiは払う |
| test_noFundsRejected | アカウントのETH 0、預けたお金0 → `FailedOp(0, "AA21 didn't pay prefund")`、handleOps全体がリバート |
| test_onlyEntryPointExecutes | バンドラーがアカウントのexecuteを直接呼ぶ → `NotEntryPoint` |
| test_userOpHashBindsChainAndEntryPoint | ハッシュ三つ：このチェーン・このEntryPoint `0x448a…036f`、ほかのEntryPoint `0x5318…ec5b`、チェーンの番号1 `0x0009…0356`。signatureの欄だけを変えると同じ値 |
| test_otherChainSigRejected | チェーンの番号1で作った署名 → `FailedOp(0, "AA24 signature error")` |
| test_badSignatureRejected | ほかの鍵で作った署名 → `FailedOp(0, "AA24 signature error")` |
| test_sameOpTwiceRejected | 処理されたUserOperationをもう一度出す → `FailedOp(0, "AA25 invalid account nonce")`、positions 100のまま |
| test_nonceKeysIndependent | key 1で10、key 0で20を預ける。getNonce(アカウント, 1) = (1 << 64) \| 1、getNonce(アカウント, 0)はkey 0を使う前は0。両方とも通り、positions 30 |

anvilで持ち主の鍵から直接送ろうとしたとき（ガスリミットを書いて見積もりを飛ばす）：

```
Error: server returned an error response: error code -32003: Insufficient funds for gas * price + value
```

`forge script`の`run219()`で送ったhandleOps 1回：

```
EntryPoint219 0x5FbDB2315678afecb367f032d93F642f64180aa3
Account219 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
Market 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
StdToken 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
owner 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7
userOpHash 0xb5cde71b732a4d1ac01c167b45c08418c29785ccfb3323caa694a7c2492f31d4

positions deposited 100
getNonce key0 1
account ETH 998350000000000000
account EP deposit 1279719734507736
owner ETH 0, owner nonce 0
bundler ETH before 10000000000000000000000 after 10000000274427644299298
UserOperationEvent ... success 1 actualGasCost 370280265492264 actualGasUsed 262824
tx ...: from 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 to 0x5fbdb2315678afecb367f032d93f642f64180aa3 gasUsed 234443 effectiveGasPrice 408852562
```

バンドラーが稼いだお金は、アカウントが払ったコストから、バンドラーが払ったトランザクションの手数料を引いた値である：370,280,265,492,264 − 234,443 × 408,852,562 = 274,427,644,299,298 wei（残高の差と同じ）。`cast run`のトレースで`Market::deposit`を呼んだアドレスはアカウントで、トランザクションの`from`はバンドラーである。

### 試すときの注意

- UserOperationは、アカウントがすることを書いて持ち主が署名したデータである。チェーンに載るトランザクションは、バンドラーが作る`handleOps`一つである。
- 検証のループの順番：ナンスの確認（AA25） → アカウントのコードがあるか（AA20） → prefund = （検証 + 実行 + preVerificationGasの上限） × maxFeePerGas → アカウントの`validateUserOp`（署名が失敗ならAA24） → 預けたお金からprefundを確保（AA21）。実行のループで実行がリバートしても、ガスのコストは払う。
- アカウントの`validateUserOp`は、署名が間違っていてもリバートせずに1（SIG_VALIDATION_FAILED）を返す。復元の結果が`address(0)`かを先にはじく行は、アカウントのコードの役目である。
- `actualGasUsed`（262,824）がトランザクションのgasUsed（234,443）より大きいのは、preVerificationGas 50,000を足したからである。
- バンドラーは、どのUserOperationを入れるかと順番を選ぶが、署名された中身は変えられない（変えるとAA24）。
- ナンスは、上の192ビットのkeyと下の64ビットのsequenceに分かれる。keyごとにsequenceを別に数えるので、一つのkeyが詰まっても、ほかのkeyのUserOperationは入る。
- まねのEIP-712のドメインの名前・バージョン（"ERC4337"/"1"）は講義用の値である。実際のEntryPointのバージョンのドメインの値と同じかは確かめていない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。標準のドキュメント、デプロイのバージョン、ツールのバージョンが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| ERC-4337の原文のバージョン | status Final、created 2021-09-29、requires 712・7702、ファイルの最後のコミットc8d8c210（2026-06-02、"Update ERC-4337: Move to Final"） | 2026-10-21 |
| 原文の定数 | MAX_VERIFICATION_GAS 500,000、PRE_VERIFICATION_OVERHEAD_GAS 50,000、UNUSED_GAS_PENALTY_PERCENT 10、PENALTY_GAS_THRESHOLD 40,000 | 2026-10-21 |
| EntryPoint v0.6 | 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789、2023-04-24 | 2026-10-21 |
| EntryPoint v0.7 | 0x0000000071727De22E5E9d8BAf0edAc6f37da032、2024-02-22 | 2026-10-21 |
| EntryPoint v0.8 | 0x4337084d9e255ff0702461cf8895ce9e3b5ff108、2025-03-26 | 2026-10-21 |
| EntryPoint v0.9 | 0x433709009B8330FDa32311DF1C2AFA402eD8D009、SenderCreator 0x0A630a99Df908A81115A3022927Be82f9299987e、2025-11-16 | 2026-10-21 |
| まねのドメインの値 | 名前"ERC4337"、バージョン"1"（講義用の値）。実際のバージョンのEntryPointのドメインの値は確かめていない | 2026-10-21 |
| バンドラーの実装のリスト | AA Reference Bundler、Stackup Bundler、Silius、Skandha、Voltaire、OKBund、Transeptor、Alto、Rundler（互換性テストの画面のResourcesのリスト、基準のバージョン0.8） | 2026-10-21 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-21 |
| solc・設定 | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| サイズ（runtime / initcodeのバイト） | Account219 1,443 / 1,637、EntryPoint219 5,222 / 5,248 | 2026-10-21 |
| テストのガス | handleOpsDepositsToMarket 363,574 / executionRevertStillCharges 228,038 / badSignatureRejected 131,389 / noFundsRejected 115,351 / nonceKeysIndependent 509,069 / onlyEntryPointExecutes 38,230 / otherChainSigRejected 137,563 / sameOpTwiceRejected 355,754 / userOpHashBindsChainAndEntryPoint 58,523 | 2026-10-21 |
| テストの中の値 | prefund 1,650,000,000,000,000、actualGasCost 525,648,000,000,000、actualGasUsed 262,824、残った預けたお金1,124,352,000,000,000、実行の失敗のコスト277,268,000,000,000 | 2026-10-21 |
| anvilの値 | handleOps gasUsed 234,443、effectiveGasPrice 408,852,562、actualGasCost 370,280,265,492,264、actualGasUsed 262,824、バンドラー +274,427,644,299,298 wei、アカウントの預けたお金1,279,719,734,507,736 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ほかのアカウントがガスを払うペイマスター、paymasterAndData | [第220講](../../part15/lecture220/) |
| initCode・Factoryでのアカウントの作成、反事実的なアドレス（counterfactual） | 付録（ERC-4337の原文613〜630行目） |
| EIP-7702のアカウントと`0x7702`の表記 | [第221講](../../part15/lecture221/) |
| ナンスのkeyで権限を分ける | [第222講](../../part15/lecture222/) |
| ステーク | [第220講](../../part15/lecture220/)（名前まで） |
| シミュレーションの規則・評判（バンドラー側） | 付録 |
| 実際のEntryPointのコードを読む | 付録（バージョンのアドレスは時効性のあるデータ） |
| 使わなかったガスのペナルティ（UNUSED_GAS_PENALTY_PERCENT） | 付録（ERC-4337の原文249〜251行目） |

出典と参考資料は[reference.md](reference.md)にまとめた。
