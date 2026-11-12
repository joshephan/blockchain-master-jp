# 第91講 try/catchと失敗データの処理

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第90講](../../part5/lecture90/) | [第5部 目次](../) | [第92講 →](../../part6/lecture92/)

## この講義の問い

他人がリバートさせた失敗を受け止められるのはどこで、受け止めたあとには何が残るのか。

## 実習資料

### 準備

`demo`（try/catchのデモ）と`market`（第90講の終わりのバージョンの通しプロジェクトのMarketとデモ用のバージョン）は、空のFoundryプロジェクトでfoundry.tomlに`solc = "0.8.30"`を固定し、forge-stdを`lib/forge-std`に置く。ほとんどは`forge test --offline`で動かし、Target・Catcher・Puller・NoReturnTokenはローカルのanvilに既定のアカウント0番（anvilの公開されたテスト用の鍵）で`forge create`して`cast`で呼ぶ。Catcherはコンストラクタの引数としてTargetのアドレスを受け取る。外部ネットワークへの接続はない。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Target.sol](code/demo/src/Target.sol) | `ok`、`failRequire`、`failAssert`、`failOverflow`、`failCustom`（`InsufficientDeposit(10, 30)`）、`failEmpty`（`revert()`）、`failBadError`（アセンブリ）、ガスを使い切る`burn` |
| [code/demo/src/Catcher.sol](code/demo/src/Catcher.sol) | Targetをtryで呼ぶ`tryRequire`、`tryBurn`、`tryLowGas`（`{gas: 5000}`） |
| [code/demo/src/SelfTry.sol](code/demo/src/SelfTry.sol) | `try this.check(x)`のバージョンのSelfTry、コンストラクタがリバートするChildと`try new Child(x)`のFactory |
| [code/demo/src/Shape.sol](code/demo/src/Shape.sol) | 戻り値のないNoReturnToken、`returns (bool)`と宣言したIERC20をtryで呼ぶPuller（`pull`、`ping`） |
| [code/demo/test/Route.t.sol](code/demo/test/Route.t.sol) | 失敗ごとに行くcatch節（RouteTest）、Error節だけを置いたバージョン（OnlyErrorTest） |
| [code/demo/test/SelfTry.t.sol](code/demo/test/SelfTry.t.sol) | `this.`の呼び出しのトレース、`try new`が失敗したあとのアドレス・ナンス |
| [code/demo/test/Shape.t.sol](code/demo/test/Shape.t.sol) | 戻り値の形が合わない呼び出しと、コードのないアドレスの呼び出し |
| [code/demo/bad/TrySelf.sol](code/demo/bad/TrySelf.sol) | 自分の関数にtry、Error 2536 |
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第90講の終わりのバージョンのMarket。トークンの呼び出しをtryで囲まない |
| [code/market/src/TryMarket.sol](code/market/src/TryMarket.sol) | デモ用。depositのトークンの呼び出しをtryで囲んでcatchを空にした`depositTry`と、理由をつけてリバートし直す`depositTryRevert`。Marketには入れない |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | デモ用のトークン。`setBroken(true)`ならtransfer・transferFromが"token paused"でリバートする |
| [code/market/src/Reader.sol](code/market/src/Reader.sol) | `catch (bytes)`でセレクタを比べるReader、Marketではないのに同じエラーを投げるLiar |
| [code/market/src/Collector.sol](code/market/src/Collector.sol) | 失敗を数えて`PullFailed`を出す`pull` |
| [code/market/test/Deposit.t.sol](code/market/test/Deposit.t.sol) | 壊れたトークンで三つのバージョンのdeposit |
| [code/market/test/Reader.t.sol](code/market/test/Reader.t.sol) | Market、Liar、金額0の要求でReaderが受け取るバイト |
| [code/market/test/Collector.t.sol](code/market/test/Collector.t.sol) | 成功の経路と失敗の経路のテスト |

### 実行結果

自分の関数にtryをつけたときのビルドエラー（`demo/bad/TrySelf.sol`）。

```
Error (2536): Try can only be used with external function calls and contract creation calls.
  --> bad/TrySelf.sol:10:13:
   |
10 |         try check(x) {
   |             ^^^^^^^^
```

`try new Child(0)`が失敗したあと（`forge test --offline --match-path test/SelfTry.t.sol -vv`）。先に計算したアドレスにコードはなく、ファクトリのナンスだけが1から2に上がった。

```
  make(0) returned 0x0000000000000000000000000000000000000000
  code at next     0
  factory nonce    2
  make(7) returned 0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3
```

失敗ごとに行くcatch節（`forge test --offline --match-test test_route -vv`）。最後のcount 0は、6回ともTarget側の変更がリバートされたという意味である。

```
[PASS] test_route() (gas: 335442)
Logs:
  require      catch Error  reason=too small
  assert       catch Panic  code=0x01
  overflow     catch Panic  code=0x11
  custom error catch (bytes) data=0x25c3f46e000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000001e
  revert()     catch (bytes) data=0x
  bad Error    catch (bytes) data=0x08c379a0
  count        0
```

Error節だけを置いたバージョン（`--match-contract OnlyErrorTest -vv`）。あふれは合う節がないので、そのまま伝わる。`test_onlyError_panic`は、これを見せるためにわざと失敗させたテストである。

```
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_onlyError_panic() (gas: 50545)
[PASS] test_onlyError_require() (gas: 54470)
Logs:
  too small
```

MarketがReaderに返したバイトを`cast decode-error`でほどいた結果。預け入れ0から30を要求し、`InsufficientDeposit(0, 30)`を受け取った。

```
$ cast decode-error --sig "InsufficientDeposit(uint256,uint256)" 0x25c3f46e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e
0
30
$ cast sig "InsufficientDeposit(uint256,uint256)"
0x25c3f46e
```

anvilでのCatcherの`tryRequire()`。トランザクションは成功し、Catcherのtriesだけが残る。receiptのlogsはCatcherが出したCaught一つで、TargetのTouchedは`cast run`のトレースにしか見えない。

```
$ cast send $K "tryRequire()" --private-key $PK0
gasUsed              75334
status               1 (success)
$ cast call $T "count()(uint256)"
0
$ cast call $K "tries()(uint256)"
1
$ cast sig-event "Caught(string)"
0x6a85348ba7e74d4be66ecd409bee781fdc5a2c7364abdf95bc8f5fe483ffabb5
$ cast sig-event "Touched(uint256)"
0xd7dc570e90ec0a5890fc446fdcecc2ecef02527b81ef9b2e3cdb2f39df229969
```

コードのないアドレスへのtry。どちらもcatchに行かず、リバートデータ0xでリバートする。`pull`（戻り値あり）は呼び出しのあと空のバイトをほどこうとして、`ping`（戻り値なし）は呼び出し前のコードの検査でリバートする。

```
$ cast code 0x000000000000000000000000000000000000bEEF
0x
$ cast send $PU "pull(address)" 0x000000000000000000000000000000000000bEEF --private-key $PK0
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast send $PU "ping(address)" 0x000000000000000000000000000000000000bEEF --private-key $PK0
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

ガスを使い切った相手。`cast send $K "tryBurn()" --gas-limit 1000000`はstatus 1で、`cast run`のトレースでburnに渡ったガスは958,668、catchの中に残ったガスは15,169、全体のgasUsedは986,028である。`tryLowGas()`は`{gas: 5000}`で呼んだ`ok`がガス不足で失敗し、catchの中に968,914が残る。

壊れたトークンでdeposit 100（`forge test --offline --match-path test/Deposit.t.sol -vv`）。

```
[PASS] test_market_brokenToken() (gas: 116503)
Logs:
  Market    totalDeposits 0
[PASS] test_tryMarket_brokenToken() (gas: 127124)
Logs:
  TryMarket totalDeposits 100
  TryMarket token balance 0
```

| バージョン | 壊れたトークンでdeposit 100 | 帳簿とトークン |
|---|---|---|
| Market（tryなし） | "token paused"で全体がリバート | どちらも0 |
| catchを空にした`depositTry` | 成功 | 帳簿100、トークン0 |
| 理由を書いてリバートし直す`depositTryRevert` | "token failed: token paused"で全体がリバート | どちらも0 |

`forge test --offline --match-test test_pull -vvvv`の失敗の経路のテスト`test_pull_tokenPaused`は通る（gas 127285）。成功のテストだけを動かすと、catch側は一度も動かない。

### 試すときの注意

- tryは外部呼び出しと`new`にしかつかない。自分の関数でも`this.f()`で呼べば外部呼び出しになり、新しいコールコンテキストが開く。
- catch節はリバートデータの先頭4バイトで分かれる。`0x08c379a0`で文字列としてほどければ`Error`、`0x4e487b71`なら`Panic`、それ以外は`(bytes)`、それもなければ`catch`。合う節がなければ、失敗はそのまま伝わる。
- セレクタが同じでも、送った側が誰かはバイトからはわからない（Liar）。`abi.decode`はバイトの形しか見ない。
- 失敗を受け止めても、相手側の状態の変更とログは消え、使ったガスは戻らない。
- catchに行かない失敗：自分の関数の中の失敗、合う節がない失敗、戻り値をreturnsの型でほどけない場合、コードのないアドレス、catchの中でガスが足りない場合。
- 相手に渡せるガスは、残りのガスの64分の63までである。
- `tryLowGas`を`--gas-limit`なしで送ると、castが見積もった上限がぎりぎりで、catchの中のgasleftが1,197と出る。100万を指定して送った値が968,914である。
- `test/Shape.t.sol`の三つのテスト（test_noReturn、test_noCode_returns、test_noCode_noReturns）は、catchに行かないことを見せるためのものなので、三つともFAILで終わる。
- Marketはトークンの呼び出しをtryで囲まない。トークンの呼び出しが失敗すると、deposit・withdraw全体がリバートする。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| try/catchの導入 | solc 0.6.0 | 2026-10-19 |
| `catch Panic(uint)`節の導入 | solc 0.8.1 | 2026-10-19 |
| コードのないアドレスの検査 | 0.8.10から、戻りデータをデコードする外部呼び出しは呼び出し前のコード長の検査を省き、デコードの失敗でリバートする。戻り値のない呼び出しは呼び出し前に検査する | 2026-10-19 |
| セレクタ | `Error(string)` `0x08c379a0`、`Panic(uint256)` `0x4e487b71`、`InsufficientDeposit(uint256,uint256)` `0x25c3f46e` | 2026-10-19 |
| トレースのガス | tryRequire 54,270（内側のfailRequire 24,184）、gasUsed 75,334 / tryBurn 964,964（burn 958,668）、catchの中のgasleft 15,169、gasUsed 986,028 / tryLowGasのcatchの中のgasleft 968,914、gasUsed 32,283 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| コンストラクタの文法と初期化の順番 | [第92講](../../part6/lecture92/) |
| カスタムエラーの宣言とエンコード、受け取ったバイトから引数をほどくこと | [第108講](../../part6/lecture108/) |
| requireの文字列とカスタムエラーの比較、ガス | [第109講](../../part6/lecture109/) |
| ガスを使い切る相手と引き出しパターン | [第150講](../../part9/lecture150/) |
| 相手のコードが動いている間に再び入ってくる呼び出し | [第168講](../../part11/lecture168/) |
| 外部呼び出しの結果を扱う実務の基準（tryと低水準の呼び出しのどちらを選ぶか、pull payment） | [第170講](../../part11/lecture170/) |
| 戻り値のないトークンのような、標準を守らないトークン | [第171講](../../part11/lecture171/) |
| 失敗の経路まで含めた不変条件とファジング | [第183講](../../part11/lecture183/) |
| テストスイートの構成 | [第258講](../../part20/lecture258/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
