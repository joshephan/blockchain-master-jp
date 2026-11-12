# 第150講 引き出しパターン

第9部 最適化と規律・第39章 共通パターン

[← 第149講](../../part9/lecture149/) | [第9部 目次](../) | [第151講 →](../../part9/lecture151/)

## この講義の問い

処理の中でお金を送ると、受け取る側に何を渡すことになるのか。受け取る分を書いておいて取りに来させると、何を得て、何を余分に払うのか。

## 実習資料

### 準備

公式ドキュメントCommon Patternsの引き出しパターンの例二つ（WithdrawalContract、SendContract）を、空のFoundryプロジェクト（`demo`、optimizerオフ、evm osaka）にそのまま移して始める。受け取る側のコントラクト三つ（受け取るときに巻き戻すRejecter、ガスを使い切るBurner、欄を一つだけ書き換えるWriter）と、リストに分けて送るバージョン二つを足した。デモでは、バージョンごとに新しいanvil（ブロック間隔1秒）に`forge create --unlocked`でデプロイし、`cast send --json`のstatusとgasUsedを読む。止められる呼び出しはcastのガス見積もりが拒否するので、`--gas-limit`を決めて送る。

通しプロジェクトMarketは第149講のバージョンから始める。第150講のバージョンはコードが第149講のバージョンと同じで、引き出しが取りに来る形であり、帳簿を先に減らすことを確かめるテスト`test/Pull.t.sol`を足した。テストにはforge-stdが必要である（`lib/forge-std`）。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、optimizerオフ（既定値） |
| [code/demo/src/WithdrawalContract.sol](code/demo/src/WithdrawalContract.sol) | ドキュメント30〜63行の例。押し出された人の取り分を`pendingWithdrawals`に書き、`withdraw`で取りに来させる |
| [code/demo/src/SendContract.sol](code/demo/src/SendContract.sol) | ドキュメント69〜93行の例。becomeRichestの中で押し出された人にすぐ送る |
| [code/demo/src/SendTransfer.sol](code/demo/src/SendTransfer.sol) | 送る行だけを`richest.transfer(msg.value);`に変えたバージョン |
| [code/demo/src/WithdrawalUnchecked.sol](code/demo/src/WithdrawalUnchecked.sol) | 取り分を足す1行だけを`unchecked`で囲んだバージョン |
| [code/demo/src/Receivers.sol](code/demo/src/Receivers.sol) | 受け取る側の三つ、Rejecter、Burner、Writer |
| [code/demo/src/Split.sol](code/demo/src/Split.sol) | リストに一度に送るPushSplit、取り分だけを書くPullSplit |
| [code/market/foundry.toml](code/market/foundry.toml) | 第149講のバージョンと同じ |
| [code/market/src/](code/market/src/) | Market第150講のバージョン（第149講のバージョンとコードは同じ、バージョン説明のコメントを1行追加） |
| [code/market/test/Pull.t.sol](code/market/test/Pull.t.sol) | 一つのアカウントにだけ送らないRefusingTokenと、transferの中でMarketを読むPeekTokenで、引き出しの順番を確認 |
| [code/market/test/](code/market/test/) | テスト21ファイル（69個のテスト） |

### 実行結果

SendContractでRejecterが2イーサでrichestになったあとは、誰がいくら払ってもbecomeRichestが失敗する：

```
== SendContract(call) + Rejecter
deploy 0x5FbDB2315678afecb367f032d93F642f64180aa3 254657
A1 Rejecter.play 2 ether (1, 51418)
richest 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 Rejecter 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
A2 becomeRichest 3 ether gas 200000 (0, 35501)
A2 becomeRichest 100 ether gas 200000 (0, 35501)
richest 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 mostSent 2000000000000000000 [2e18] bal 1000000000000000000
```

かっこの中は(status, gasUsed)である。同じRejecterをWithdrawalContractに入れると、次の人のbecomeRichestは成功し、Rejecterの引き出しだけが失敗する。Rejecterの取り分の3イーサは帳簿の欄にそのまま残る：

```
== WithdrawalContract + Rejecter
deploy 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 329122
A1 Rejecter.play 2 ether (1, 64235)
A2 becomeRichest 3 ether (1, 53858)
Rejecter.cashOut gas 200000 (0, 37611)
A0 withdraw (1, 28709)
richest 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC mostSent 3000000000000000000 [3e18] bal 4000000000000000000
pendingWithdrawals[Rejecter] slot 0xb3a8f172eacdb6175fe95f13e565549dcea98a18e111b1da328049958642073e 0x00000000000000000000000000000000000000000000000029a2241af62c0000
pendingWithdrawals[A0] 0x0000000000000000000000000000000000000000000000000000000000000000
```

受け取る側の三つと送る形の二つ：

```
== SendContract(call) + Burner, gas limit 1,000,000 / 5,000,000
A1 Burner.play 2 ether (1, 51418)
A2 becomeRichest 3 ether gas 1e6 (0, 985032)
A2 becomeRichest 3 ether gas 5e6 (0, 4922532)
== SendContract(call) + Writer
A1 Writer.play 2 ether (1, 51440)
A2 becomeRichest 3 ether (1, 63403)
Writer.got 3000000000000000000 [3e18]
== SendTransfer + Writer / Burner
A1 Writer.play 2 ether (1, 51239)
A2 becomeRichest 3 ether gas 200000 (0, 37164)
A1 Burner.play 2 ether (1, 51217)
A2 becomeRichest 3 ether gas 1e6 (0, 37164)
```

Burnerは渡されたガスをほとんど燃やして失敗する。`transfer`は受け取る側に2,300しか渡さないので、欄を一つ書き換えるWriterも受け取れない（Rejecter 35,228、Burner・Writer 37,164、いずれも失敗）。

アカウントどうしでの二つの形のガス：

```
== gas: push vs pull vs unchecked (EOA richest)
Send A1 becomeRichest 2 (1, 41041)
Send A2 becomeRichest 3 (1, 41041)
Withdrawal A1 becomeRichest 2 (1, 53858)
Withdrawal A2 becomeRichest 3 (1, 53858)
Withdrawal A0 withdraw (1, 28709)
Withdrawal A1 withdraw (1, 28709)
Withdrawal A1 withdraw again (0) (1, 24009)
Unchecked A1 becomeRichest 2 (1, 53679)
Unchecked A2 becomeRichest 3 (1, 53679)
Unchecked A0 withdraw (1, 28709)
```

取りに来る形はbecomeRichest 53,858とwithdraw 28,709を合わせて82,567で、送る形の41,041の約2倍になり、受け取る人がトランザクションをもう一つ送る。足す行を`unchecked`で囲むと179ガス減る。

リストの長さごとのpayAll：

```
== split N=10
PushSplit payAll (1, 144414)
PullSplit payAll (1, 272386)
== split N=100
PushSplit payAll (1, 1231524)
PullSplit payAll (1, 2511046)
== split N=1000
PushSplit payAll (1, 12102624)
PullSplit payAll (1, 24897646)
```

10人のうち5人目がRejecterだと、PushSplitは全体が失敗し（`(0, 184288)`）、PullSplitは成功してRejecterの取り分1,000も書かれる。取り分だけを書くバージョンも長さに比例してガスがかかるので、anvilのブロックガスリミット30,000,000を超える長さでは、どちらのバージョンも実行できない。

Market第150講のバージョンの`forge test --match-contract PullTest`：

```
[PASS] test_refusedWithdrawStaysWithCaller() (gas: 780522)
[PASS] test_tokenSeesDebitedLedger() (gas: 714657)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 722.30µs (548.50µs CPU time)
```

`test_refusedWithdrawStaysWithCaller`は、トークンが受け取りを拒否したアカウントのwithdrawだけが`refused`で巻き戻り、ほかのアカウントの引き出しと帳簿はそのままかを見る。`test_tokenSeesDebitedLedger`は、100を預けて30を引き出すとき、トークンがtransferの中で読んだMarketの値が預け入れ額70、合計70、トークン残高100かを見る。帳簿を先に減らしてからトークンを送るということである。

第150講のバージョンのサイズ（runtime / creation）はdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931、テスト69個が通り、コミット前の確認は`ci ok`である。レシートのgasUsedはデプロイ760,316、addAsset 92,656、deposit 127,515、withdraw 57,448、setStatus 45,001 / 23,089、失敗26,264である。

### 試すときの注意

- デプロイのときに載せた1イーサは、ドキュメントの例の二つのバージョンとも引き出す関数がない。ドキュメントの例をそのまま使わない理由である。
- 止められる呼び出しは、`cast send`がガス見積もりで`execution reverted`として拒否し、トランザクションが出ていかない。チェーンに失敗として残すには`--gas-limit`を決めて送る。失敗した試みの手数料は送った人が払う。
- WithdrawalContractのwithdrawは、欄を先に0にしてから送る（ドキュメント57〜58行のコメント）。Marketのwithdrawも、`_debit`で帳簿を先に減らしてからトークンを送る。
- anvilはトランザクションのガス16,777,216、16,777,217、30,000,000をすべて受け付ける。メインネットはトランザクション一つのガスの上限が16,777,216である（下の時効性のあるデータ）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョン、ハードフォーク、ネットワークの状態によって変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ用プロジェクトはoptimizerオフ（Foundryの既定値）・evm osaka。Market第150講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyがデフォルトの経路 + optimizerオン、debugがデフォルトの経路でoptimizerオフ | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| 公式ドキュメントの版 | Solidity v0.8.36 `docs/common-patterns.rst`（393行）。引用13〜18、20〜26、48〜53、55〜62（コメント57〜58）、85〜92（コメント87、送る行88）、95〜102、104〜106行 | 2026-10-20 |
| 2300 | `transfer`・`send`が受け取る側に渡すガス（基本の支給分） | 2026-10-20 |
| 64分の63 | 呼び出すときに渡せるガスは残りのガスの64分の63まで（EIP-150） | 2026-10-20 |
| anvilのブロックガスリミット | anvil 30,000,000（`cast block latest -f gasLimit`）、トランザクションのガス16,777,216・16,777,217・30,000,000をすべて受け付ける。メインネット：約6,000万ガス（直近24時間のブロック300個の標本59,941,351〜60,058,592）。既定値60MはEIP-7935。トランザクション一つのガスの上限16,777,216（2の24乗）、EIP-7825、Fusaka（2025-12-03）で適用 | 2026-10-20 |
| イーサの総量と2の256乗 | 2の256乗は約1.16 × 10^77 wei。イーサの総量122,146,594.27 ETH（約1.22 × 10^26 wei） | 2026-10-20 |
| 送る形の詰まり | SendContract + Rejecter：becomeRichest 3・100イーサ `--gas-limit 200000` status 0・35,501、richest・mostSent 2e18はそのまま、残高1イーサ | 2026-10-20 |
| ガスを燃やす | SendContract + Burner：リミット1,000,000 → 985,032、5,000,000 → 4,922,532、どちらもstatus 0 | 2026-10-20 |
| 受け取る側の三つ × 送る形の二つ | call：Rejecter 35,501 失敗、Burner 985,032 失敗（リミット1,000,000）、Writer 63,403 成功。transfer：Rejecter 35,228、Burner 37,164、Writer 37,164 すべて失敗。play（参加）のガス51,418・51,440（callのバージョン）、51,217・51,239（transferのバージョン） | 2026-10-20 |
| 取りに来る形 | WithdrawalContract + Rejecter：play 64,235、アカウント2番のbecomeRichest 53,858、cashOut status 0・37,611、アカウント0番のwithdraw 28,709、Rejecterの欄`0x…29a2241af62c0000`（スロット`0xb3a8…073e`）、アカウント0番の欄0、残高4イーサ | 2026-10-20 |
| 二つの形のガス（アカウントどうし） | SendContract becomeRichest 41,041。WithdrawalContract becomeRichest 53,858、withdraw 28,709、欄が0のときのwithdraw 24,009。WithdrawalUnchecked becomeRichest 53,679。SendTransfer becomeRichest 40,840。デプロイ：SendContract 254,657、WithdrawalContract 329,122 | 2026-10-20 |
| 長さごとのpayAll | PushSplit 10・100・1,000人 144,414 / 1,231,524 / 12,102,624、PullSplit 272,386 / 2,511,046 / 24,897,646（受け取るアカウントの残高を1 weiにして事前に作る、取り分の欄は新しい欄）。10人のうち5人目がRejecter：PushSplit 184,288 status 0、PullSplit 272,386 成功、owed 1,000・1,000 | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第150講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ（runtime / creation） | 第150講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| テストのガス | PullTest:test_refusedWithdrawStaysWithCaller 780,522、test_tokenSeesDebitedLedger 714,657（`.gas-snapshot` 69行） | 2026-10-20 |
| 行番号・末尾のハッシュ | 第150講のバージョンdebug deposit 0 src/Market.sol 163:33、NotActive 78行、`contract Market` 207行、withdraw 167〜173行、_debit 187〜192行、collateralCount 242〜248行。末尾のハッシュの先頭4バイトdefault `5a115f7a`。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`、1番 `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`、2番 `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`（anvilの既定のアカウント、公開されたテスト用の鍵） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ドキュメント57〜58行のコメントが防ぐ攻撃と、その順番の名前 | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/) |
| 受け取る側がwithdrawの間にMarketを読んだり再び呼んだりするとき | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第171講](../../part11/lecture171/) |
| 外部呼び出しの結果を扱う実務の基準とpull payment | [第170講](../../part11/lecture170/) |
| 長さが伸びるリストを分けて処理する方法 | [第170講](../../part11/lecture170/)、[第183講](../../part11/lecture183/) |
| トークンがtransferの中で受け取る側のコードを呼ぶ標準 | [第156講](../../part10/lecture156/)、[第171講](../../part11/lecture171/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
