# 第222講 セッションキーと権限の範囲

第15部 アカウント抽象化・第60章 アカウント抽象化の実践

[← 第221講](../../part15/lecture221/) | [第15部 目次](../) | [第223講 →](../../part15/lecture223/)

## この講義の問い

鍵一つがアカウントのすべての仕事をする構造で、毎日使う鍵ができることをどう減らすのか。範囲には何まで書けば範囲と言えて、範囲の外の要求はどこで止まるのか。

## 実習資料

### 準備

第59〜60章の共用のアカウント抽象化のプロジェクト`aa`から始める。この講義では、講義用のセッションキーのアカウント`Account222.sol`とそのテスト、anvilのデモのスクリプト`Demo222.s.sol`を使い、第219講のEntryPointのまね（`EntryPoint219.sol`、`UserOp.sol`）に入れて回す。テストの土台（`test/Base.sol`）とデモのスクリプトが、通しプロジェクトMarket（第53章の終わりのバージョン）のsrcのコピーと標準のトークン`StdToken`を`src/market/`に置いてデプロイする。依存はforge-std（`lib/forge-std`）一つである。

anvilは`--hardfork osaka`で立ち上げ、`forge script`で`runA`（デプロイ、持ち主のUserOperationで承認300 + セッションの書き込み、セッションのUserOperationで預け入れ100）、`runC`（セッションキーでトークンを送る）、`evm_increaseTime`で1時間を越えたあと`runB`（同じセッションキーで預け入れ50）を順に回す。持ち主の鍵`0xA11CE`とセッションキー`0x5E55`は誰でも知っているデモ用の鍵なので、実際の資産には使わない。`Account222`は講義用のアカウントである。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシードを固定 |
| [code/src/Account222.sol](code/src/Account222.sol) | 講義用のセッションキーのアカウント：Sessionの7欄（target、selector、asset、limit、spent、validAfter、validUntil）、addSession・revokeSession（自分だけ）、validateUserOpの持ち主/セッションの分岐、`_checkSession`、execute・executeBatch（EntryPointだけ） |
| [code/src/EntryPoint219.sol](code/src/EntryPoint219.sol) | 第219講のEntryPointのまねのまま |
| [code/src/UserOp.sol](code/src/UserOp.sol) | PackedUserOperation、IAccount、ValidationData |
| [code/test/Base.sol](code/test/Base.sol) | MarketとStdTokenをデプロイするテストの土台 |
| [code/test/Account222.t.sol](code/test/Account222.t.sol) | Account222Testの13個 |
| [code/script/Demo222.s.sol](code/script/Demo222.s.sol) | anvilのデモのスクリプト（runA、runB、runC） |
| [code/src/market/Market.sol](code/src/market/Market.sol) | 通しプロジェクトMarket（第53章の終わりのバージョン）のコピー |
| [code/src/market/IMarket.sol](code/src/market/IMarket.sol) | Marketのインターフェース |
| [code/src/market/MarketMath.sol](code/src/market/MarketMath.sol) | 利息・ポジションの計算のライブラリ |
| [code/src/market/MarketTypes.sol](code/src/market/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/src/market/StdToken.sol](code/src/market/StdToken.sol) | 承認を要求するテスト用の標準のトークン |

### 実行結果

`forge test --offline --match-contract Account222Test -vv`（長いcalldataのログは省略）：

```
Ran 13 tests for test/Account222.t.sol:Account222Test
[PASS] test_ownerAddsSession() (gas: 25977)
Logs:
  0xadb348b4...
[PASS] test_ownerNotLimited() (gas: 248030)
[PASS] test_reAddSessionResetsSpent() (gas: 595494)
[PASS] test_revokedSessionRejected() (gas: 226116)
[PASS] test_sessionBatchRejected() (gas: 117668)
[PASS] test_sessionCannotAddSession() (gas: 119761)
[PASS] test_sessionDepositsWithinLimit() (gas: 291620)
[PASS] test_sessionExpiredRejected() (gas: 130637)
[PASS] test_sessionNonceKeyIndependent() (gas: 381843)
Logs:
  session nonce key 771094214915819952224106437499867297935000105970
[PASS] test_sessionNotYetValidRejected() (gas: 130623)
[PASS] test_sessionOtherSelectorRejected() (gas: 117117)
[PASS] test_sessionOtherTargetRejected() (gas: 124586)
[PASS] test_sessionOverLimitRejected() (gas: 379256)
Suite result: ok. 13 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_ownerAddsSession | 持ち主のUserOperation一つで7欄が書かれる、セッションの書き込みのcalldata `0xadb348b4…` |
| test_sessionDepositsWithinLimit | 預け入れ100、spent 100 |
| test_sessionOverLimitRejected | 200のあと200 → `FailedOp(0, "AA24 signature error")`、positions 200 |
| test_sessionOtherTargetRejected | トークンのtransfer → AA24、アカウントのトークン1000のまま |
| test_sessionOtherSelectorRejected | Marketのwithdraw → AA24 |
| test_sessionBatchRejected | executeBatch → AA24 |
| test_sessionCannotAddSession | execute(アカウント, addSession(上限最大)) → AA24 |
| test_sessionExpiredRejected | 終わりの時刻 + 1 → "AA22 expired or not due" |
| test_sessionNotYetValidRejected | 始まりの時刻 − 1 → AA22 |
| test_revokedSessionRejected | 持ち主が消したあと → AA24 |
| test_sessionNonceKeyIndependent | 持ち主の列で出すとAA24、自分の列では通る。セッションの列のgetNonce = (uint160(セッションキー) << 64) \| 1、持ち主の列1 |
| test_ownerNotLimited | 持ち主は1000を預ける |
| test_reAddSessionResetsSpent | 200使ったあと同じ範囲を書き直すとspentは0から、さらに300を預けてpositions 500、spent 300 |

anvilの`runA`。持ち主が署名したセッションの書き込みのcalldataを`cast decode-calldata`でデコードし、状態を読んだ結果：

```
-- 持ち主が署名したセッションの書き込みのcalldataをデコード
0x87110f79f69670eE8dEd56E2231882D06b2873F2
(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, 0x47e7ef24, 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, 300, 0, 1792527374, 1792530974)
-- sessions(セッションキー): 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 0x47e7ef24 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 300 100 1792527374 1792530974
-- positions(アカウント) 100
-- getNonce key0 1, key(セッション) 14224177639270121043906949944737479533353022185091802203961184747521
-- 持ち主のETH 0、セッションキーのETH 0
-- トークンの承認 アカウント→Market 200
```

handleOpsのトランザクション二つ（アカウント1番が送る）のgasUsedは、持ち主のUserOperation 233,717、セッションのUserOperation 229,586である。

`runC`（セッションキーでトークンを送る）と、1時間後の`runB`（預け入れ50）：

```
== C. セッションキーでトークンを送る
Error: script failed: FailedOp(0, "AA24 signature error")
== B. 1時間後に同じセッションキーで預け入れ50
block time 1792530988
Error: script failed: FailedOp(0, "AA22 expired or not due")
```

時刻の値はanvilの時計に従うので、実行するたびに違う。

### 試すときの注意

- セッションを与えるときに持ち主が署名するのは、セッションの書き込みのcalldataである。署名の前に`cast decode-calldata`で、セッションキーのアドレス、対象、セレクタ、資産、上限、始まり・終わりの時刻をデコードして読む。
- `_checkSession`は、セッションがあるか、ナンスの列、executeか、target・value・長さ・セレクタ、最初の引数の資産、合計の上限を順に見る。範囲は画面の文言ではなく、callDataから直接読む。
- 期限（validAfter・validUntil）はアカウントがvalidationDataで返し、確かめるのはEntryPointである（AA22）。期限だけでは範囲にならない。1時間のあいだ範囲が広ければ、1時間のあいだ広い。
- セッションキーは自分のナンスの列（key = セッションキーのアドレス）を使う。持ち主の列が詰まっても、セッションの列は別に進む。
- セッションキーが`addSession`を呼ぶ道（executeでアカウント自身を呼ぶ）を防がなければならない（`test_sessionCannotAddSession`）。
- セッションを書き直すと、使った量は0から数え直す。新しい上限は、すでに使った量の上に足されるものとして書く。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。標準のドキュメントとツールのバージョンが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| EIP-7702の原文 | status Final、ファイルの最後のコミットbbc3f958（2025-10-07） | 2026-10-21 |
| ERC-4337の原文 | コミットc8d8c210 | 2026-10-21 |
| モジュール・権限のERCの先頭の欄 | ERC-7579 "Minimal Modular Smart Accounts" Draft 2023-12-14 / ERC-6900 "Modular Smart Contract Accounts" Draft 2023-04-18 / ERC-7710 "Smart Contract Delegation" Draft 2024-05-20 / ERC-7715 "Request Permissions from Wallets" Draft 2024-05-24（本文は読んでいない、名前と状態だけ） | 2026-10-21 |
| Foundry | forge・cast・anvil 1.8.3、anvil `--hardfork osaka` | 2026-10-21 |
| solc・設定 | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| コントラクトのサイズ（ランタイム/initcodeのバイト） | Account222 3,575/3,769、EntryPoint219 5,222/5,248 | 2026-10-21 |
| anvilのgasUsed | 持ち主のUserOperation（承認300 + セッションの書き込み）のhandleOps 233,717 / セッションのUserOperation（預け入れ100） 229,586 | 2026-10-21 |
| anvilの時刻 | 始まり1792527374、終わり1792530974、段階Bのブロックの時刻1792530988（anvilの時計、実行ごとに違う） | 2026-10-21 |
| テストのガス（Account222Test） | ownerNotLimited 248,030 / reAddSessionResetsSpent 595,494 / revokedSessionRejected 226,116 / sessionBatchRejected 117,668 / sessionCannotAddSession 119,761 / sessionDepositsWithinLimit 291,620 / sessionExpiredRejected 130,637 / sessionNonceKeyIndependent 381,843 / sessionNotYetValidRejected 130,623 / sessionOtherSelectorRejected 117,117 / sessionOtherTargetRejected 124,586 / sessionOverLimitRejected 379,256 / ownerAddsSession 25,977 | 2026-10-21 |
| デモのアドレス・鍵 | 持ち主の鍵0xA11CE → 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7、セッションキー0x5E55 → 0x87110f79f69670eE8dEd56E2231882D06b2873F2（どちらもデモ用の公開された鍵、実際のお金には使わない）、EntryPoint219 0x5FbDB2315678afecb367f032d93F642f64180aa3、StdToken 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512、Market 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0、Account222 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9、アカウント1番0x70997970C51812dc3A010C7d01b50e0d17dc79C8 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 鍵をなくしたときの持ち主の鍵の交換 | [第223講](../../part15/lecture223/) |
| 署名一つで生まれる承認（permit、EIP-2612）を、ウォレットがデコードして見せること | [第223講](../../part15/lecture223/) |
| モジュールの標準（ERC-7579・6900）と、ウォレットに権限を要求する標準（ERC-7715） | 付録（時効性のあるデータ） |
| 1日の上限のように、時間ごとにまた満ちる上限 | 付録 |
| 範囲の検査がアカウントのストレージを使うことと、バンドラーの検証の規則 | 付録 |

出典と参考資料は[reference.md](reference.md)にまとめた。
