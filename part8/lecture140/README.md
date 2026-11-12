# 第140講 最適化結果の検証

第8部 コンパイラと内部構造・第34章 オプティマイザ

[← 第139講](../../part8/lecture139/) | [第8部 目次](../) | [第141講 →](../../part8/lecture141/)

## この講義の問い

optimizerを入れたビルドが切ったビルドと同じことをすると、何で確かめ、何が変わってもよく、確かめたあとMarketはどちらのビルドでデプロイするのか。

## 実習資料

### 準備

通しプロジェクトMarketの第139講のバージョン（optimizerを切る）と第140講のバージョン（デプロイのビルドをoptimizerを入れたruns 200に変え、リバートの行を探す`[profile.debug]`を足したバージョン）を並べて使う。二つのバージョンはコードが同じで、Market.solのバージョンを説明するコメント1行とfoundry.tomlだけが違う。デモのプロジェクト（`demo`）には、ガスを決めておいて呼ぶ例Gas140がある。solc 0.8.30、Foundry 1.8.3で、forge-stdが必要である（`lib/forge-std`）。

二つのビルドに同じ呼び出しを入れて突き合わせるときは、anvilを一つ立ち上げ、ブロック間隔を1秒にして自動マイニングを切る。アカウント0番が二つのバージョンをそれぞれ（MockToken二つ + Market）デプロイし、最初のトークンだけaddAsset 75をして、アカウント1〜3番にトークンごとに200ずつ配ってから、seedを固定したランダムな呼び出しを二つのバージョンに一つずつ送り、ブロックを一つマイニングする（同じブロック、同じ時刻）。呼び出しごとに、レシートのstatus、送る前の同じ状態で`eth_call`で受け取ったリバートデータ、ログ（アドレスは名前に置き換えて比べる）、読み取り関数24個、スロット0〜5を突き合わせる。突き合わせるツールが違いを捕まえるかは、MarketMath.solの38行目の`<`を`<=`に変えた1文字のバージョンで確かめる。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | default（optimizerを入れる、runs 200）、`[profile.ir]`（via-IR + optimizer）、`[profile.debug]`（optimizerを切る、out-debug） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | Market 第140講のバージョン（コードは第139講のバージョンと同じ、バージョンを説明するコメント1行） |
| [code/market/src/](code/market/src/) | IMarket・MarketMath・MarketTypes・MockToken |
| [code/market/test/](code/market/test/) | プロジェクトのテスト16ファイル、テスト60個 |
| [code/fail/test/Fail.t.sol](code/fail/test/Fail.t.sol) | わざと失敗するテスト二つ（deposit 0、withdraw 150）。`code/market/test/`にコピーして、二つのプロファイルのBacktraceを見る |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモのプロジェクトの設定、default（optimizerを切る）とopt（入れる） |
| [code/demo/src/Gas140.sol](code/demo/src/Gas140.sol) | Worker.work（繰り返しの計算）と、決めたガスだけを渡して呼ぶCaller.tryWork |
| [code/demo/test/Gas140.t.sol](code/demo/test/Gas140.t.sol) | `tryWork(w, 20, 5000)`が成功するかを見る`test_fixedGas` |

### 実行結果

第139講のバージョンのテストを、optimizerを入れて回し直した結果（`--optimize`はoutフォルダを入れたビルドで上書きするので、コピーで回す）。

```
$ forge test --offline
Ran 18 test suites …: 60 tests passed, 0 failed, 0 skipped (60 total tests)
$ forge test --offline --optimize
Ran 18 test suites …: 60 tests passed, 0 failed, 0 skipped (60 total tests)
```

デモのプロジェクトのGas140、同じソースの二つのプロファイル。

```
$ forge test --offline --match-path test/Gas140.t.sol -vvvv
[FAIL: assertion failed] test_fixedGas() (gas: 42119)
Logs:
  ok false
  r 0
  work(20) gas 13877
    ├─ [8994] Caller::tryWork(Worker: [0x5615…b72f], 20, 5000) [staticcall]
    │   ├─ [5000] Worker::work(20) [staticcall]
    │   │   └─ ← [OutOfGas] EvmError: OutOfGas
    ├─ [10541] Worker::work(20) [staticcall]
$ FOUNDRY_PROFILE=opt forge test --offline --match-path test/Gas140.t.sol -vvvv
[PASS] test_fixedGas() (gas: 28958)
Logs:
  ok true
  r 746433920910091424484602890
  work(20) gas 7562
    ├─ [7917] Caller::tryWork(Worker: [0x5615…b72f], 20, 5000) [staticcall]
    │   ├─ [4624] Worker::work(20) [staticcall]
    │   │   └─ ← [Return] 746433920910091424484602890 [7.464e26]
```

`work(20) gas`は関数の中のgasleftの差（呼び出しのコストを含む）、トレースの角かっこはworkの実行ガスである。Marketのsrcには、ガスを決めておいて呼ぶ行がない。

```
$ grep -rcE "gas:|gasleft|assembly" src
src/IMarket.sol:0
src/Market.sol:0
src/MarketMath.sol:0
src/MarketTypes.sol:0
src/MockToken.sol:0
```

二つのビルドに同じランダムな呼び出し300回（deposit 114、withdraw 68、トークンの停止29、addAsset 23、withdrawAll 23、deposit 0 22、setStatus 21、金額の候補1、5、30、100、150、250、2**255）を入れた結果。

```
off Market 0x9fe4…a6e0 … runtime 7353
opt Market 0xa51c…91c0 … runtime 3755
{"ops": 300, "same": 300, "diff": 0, "reverts": 195,
 "gas_off": 11675915, "gas_opt": 11398123, …} interestFor 200 mismatches 0
```

リバート195回の理由も、二つのバージョンで同じである。

| リバートデータの先頭4バイト | 理由 | 回数 |
|---|---|---|
| `0x1d61e8ee` / `0x25c3f46e` | NotActive / InsufficientDeposit | 49 / 33 |
| `0x08c379a0` / `0xb2ce2a93` | "token paused" / MarketFrozen | 30 / 26 |
| `0x1f2a2005` / `0x19cd4595` | ZeroAmount / AlreadyListed | 18 / 12 |
| `0x5d35c429` / `0x4e487b71` | NotListed / Panic | 8 / 8 |
| `0x17a84242` / `0x` / `0x7cde9b72` | NotAdmin / データ0バイト / ZeroAsset | 5 / 4 / 2 |

1文字のバージョン（MarketMath.solの38行目`if (have <= amount) …`、optimizerを切る）を同じ方法で突き合わせた結果と、そのバージョンのテスト。

```
{"ops": 300, "same": 42, "diff": 258, "reverts": 195, …}
DIFF (42, 'withdrawAll', …)
$ forge test --offline
[FAIL: InsufficientDeposit(100, 100)] test_withdrawAll() (gas: 166299)
[FAIL: Error != expected error: InsufficientDeposit(10, 10) != TransferFailed(0xF628…820a)] test_transferFailed() (gas: 186807)
[FAIL: InsufficientDeposit(100, 100)] test_depositWithdrawAllEmit() (gas: 269682)
Ran 18 test suites …: 57 tests passed, 3 failed, 0 skipped (60 total tests)
```

43番目の呼び出し（0から数えて42番、アカウント2番が2番目のトークンに預けた30をwithdrawAll）で分かれ、一度分かれるとそのあとの状態がすべて変わる。外から見えるものは、二つのバージョンで同じである。

| 項目 | 第139講のバージョン（切る） | 第140講のバージョン（入れる） |
|---|---|---|
| ABI | 36項目 | 同じ |
| セレクタ | 19個 | 同じ |
| storageLayoutのスロット・オフセット | status 0 … totalBorrows 5 | 同じ |
| immutableの位置の数 | 2・3・1 | 同じ |
| メタデータのoptimizer | `{"enabled": false, "runs": 200}` | `{"enabled": true, "runs": 200}` |

サイズ（`forge build --sizes`、バイト）とガス（バージョンごとに新しいanvil、ブロック間隔1秒、アカウント0番がMockToken → Marketをデプロイ、レシートのgasUsed）。

| バージョン | runtime | creation |
|---|---|---|
| 第139講のバージョン（切る） | 7,353 | 7,931 |
| 第140講のバージョンのdefault（入れる） | 3,755 | 4,013 |
| 第140講のバージョンのdebug（切る） | 7,353 | 7,931 |
| 第140講のバージョンのir（via-IR + 入れる） | 3,260 | 3,473 |

| トランザクション | 第139講のバージョン（切る） | 第140講のバージョン（入れる） |
|---|---|---|
| デプロイ | 1,645,279 | 867,827 |
| addAsset 75 | 93,730 | 92,576 |
| deposit 100 | 130,478 | 128,297 |
| withdraw 30 | 59,911 | 57,856 |
| setStatus 1 / setStatus 0 | 45,732 / 23,820 | 45,224 / 23,312 |
| 失敗するdeposit 0 | 26,869 | 26,409 |

debugのプロファイルで取ったスナップショットに対するdefault。

```
$ FOUNDRY_PROFILE=debug forge snapshot --offline --snap .gas-snapshot-debug
$ forge snapshot --offline --diff .gas-snapshot-debug
↓ RebuildTest::test_recordedLogsIncludeReverted() (gas: 222640 → 164513 | -58127 -26.108%)
Total tests: 60, ↑ 0, ↓ 58, ━ 2
Overall gas change: -227590 (-4.523%)
```

`Fail.t.sol`を入れて二つのプロファイルで回したBacktrace。

```
$ forge test --offline --match-path test/Fail.t.sol -vvvvv
[FAIL: InsufficientDeposit(0, 150)] test_withdrawOver() (gas: 124109)
Backtrace:
  at Market.withdraw (src/Market.sol:68:51)
$ FOUNDRY_PROFILE=debug forge test --offline --match-path test/Fail.t.sol -vvvvv
[FAIL: InsufficientDeposit(0, 150)] test_withdrawOver() (gas: 128164)
Backtrace:
  at Market.withdraw (src/MarketMath.sol:38:35)
```

Market.solの68行目は`NotActive(status)`の行である。deposit 0（ZeroAmount）は、どちらのプロファイルでもMarket.sol 150:33である。Market 第140講のバージョン。

```
$ forge build --offline --force --sizes
| Market      | 3,755            | 4,013             | 20,821             | 45,139              |
$ forge test --offline
Ran 18 test suites …: 60 tests passed, 0 failed, 0 skipped (60 total tests)
$ FOUNDRY_PROFILE=debug forge test --offline
Ran 18 test suites …: 60 tests passed, 0 failed, 0 skipped (60 total tests)
$ FOUNDRY_PROFILE=ir forge test --offline
Ran 18 test suites …: 60 tests passed, 0 failed, 0 skipped (60 total tests)
```

### 試すときの注意

- テストは、デプロイするビルドで回す。切ったビルドで通ったテストは、切ったビルドのバイトコードを検査した結果である。
- optimizerを入れると、同じ呼び出しでもガスが変わる。渡すガスを決めておいて呼ぶコード（`{gas: g}`）や`gasleft`を読むコードは、ビルドによって成功と失敗が分かれることがある。
- 二つのビルドを突き合わせるとき、状態、リバートデータ、ログは同じでなければならず、ガスは違ってもよい。ブロックの時刻が違うとlastUpdateのような値が変わるので、同じブロックに入れる。
- 突き合わせた範囲は、入れてみた入力までである。1文字のバージョンのように違いをわざと入れて、ツールが捕まえるかを先に確かめる。
- 入れたビルドは、ブロックをまとめるためにソースマップが別の行を指すことがある。リバートした行は、optimizerを切ったdebugのプロファイルで同じ呼び出しを回し直して探す。debugのプロファイルのoutを分けておかないと、debugのビルドのたびに、デプロイする成果物が切ったビルドで上書きされる。
- 第140講のバージョンのdebugのランタイムは、第139講のバージョンのランタイムと末尾のメタデータハッシュだけが違う（バージョンを説明するコメント1行の違い）。第140講のバージョンのデプロイのガス867,827は、第139講のバージョンのコピーのruns 200の値と同じである。ハッシュは違っても、その中の0でないバイトの数が同じだからである（デプロイの入力は0のバイトが4ガス、0でないバイトが16ガス）。
- runs 10000はruns 200より呼び出しごとに7〜149ガス少ないが、デプロイが217,520多くかかる。withdrawだけで埋め合わせるには、1,460回くらい呼ぶ必要がある。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンやソースのコメントが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。第140講のバージョンのdefaultはoptimizerを入れるruns 200、debugは切る、irはvia-IR + 入れる、evm_version osaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| ドキュメントのwarning | The OptimizerのYul-Based Optimizer Moduleのwarningの文言は、バージョンごとに変わりうる | 2026-10-20 |
| optimizer runs | 既定200、最大値2**32-1（ドキュメント） | 2026-10-20 |
| Gas140 | 切る: work(20)の実行10,541（関数の中のgasleftの差13,877）、`ok false` / 入れる: 4,624（7,562）、`ok true`。テストのガス42,119 / 28,958 | 2026-10-20 |
| 二つのビルドの突き合わせ | seed 140、300回、リバート195回、ガスの合計11,675,915 / 11,398,123、interestFor 200回 | 2026-10-20 |
| 1文字のバージョン | 最初の42回は同じ、258回は違う、テスト57 / 60 | 2026-10-20 |
| 通しプロジェクトのガス | 上の二つのバージョンの表 | 2026-10-20 |
| runsの表（第139講のバージョンのコピー） | runs 1 / 200 / 10000: runtime 3,676 / 3,755 / 4,795、デプロイ850,725 / 867,827 / 1,085,347 | 2026-10-20 |
| スナップショット | debugに対するdefault: ↑ 0、↓ 58、━ 2、-227,590（-4.523%） | 2026-10-20 |
| 行番号 | 第140講のバージョンのwithdraw 150は、入れるとsrc/Market.sol 68:51 / debugでsrc/MarketMath.sol 38:35、deposit 0は150:33。バージョンを説明するコメントが変わると変わる | 2026-10-20 |
| サイズ | 第140講のバージョンのdefault 3,755 / 4,013、debug 7,353 / 7,931、ir 3,260 / 3,473 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| runs・via-IRをガスで選び直す判断、via-IRとoptimizerを一緒に入れるかどうか | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 二つのビルドをファジングと不変条件で突き合わせる方法 | [第183講](../../part11/lecture183/) |
| オプティマイザの欠陥の事例とバージョンごとのバグの一覧 | [第184講](../../part11/lecture184/) |
| メタデータのsettingsの欄の一つひとつ | [第142講](../../part8/lecture142/) |
| 監査でデプロイのビルドの設定と行を確かめる | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
