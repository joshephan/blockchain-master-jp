# 第28講 forge testの基礎

第2部 開発とテスト環境・第7章 ローカルチェーンとテスト

[← 第27講](../../part2/lecture27/) | [第2部 目次](../) | [第29講 →](../../part2/lecture29/)

## この講義の問い

第22講でボタンを押して目で行っていた確認をコードで書くと、何を書くことになり、何が残るのか。

## 実習資料

### 準備

プロジェクトを二つ使う。`hello`は`forge init`が作ったプロジェクトに`solc = "0.8.30"`の1行を入れたもの、`counter`はhelloをもとにsrcとtestをincrement・decrementのCounterに変えたものである。どちらのプロジェクトもforge-std（`lib/forge-std`）が必要である。anvilは起動しない。テストはforgeの中のEVMでだけ動く。

### コード

| ファイル | 内容 |
|---|---|
| [code/hello/foundry.toml](code/hello/foundry.toml) | initの設定に`solc = "0.8.30"`を追加 |
| [code/hello/src/Counter.sol](code/hello/src/Counter.sol) | initのサンプルCounter |
| [code/hello/test/Counter.t.sol](code/hello/test/Counter.t.sol) | initのサンプルテスト（`test_Increment`、`testFuzz_SetNumber`） |
| [code/counter/foundry.toml](code/counter/foundry.toml) | solc 0.8.30に固定、optimizerをオンにした`ci`プロファイル |
| [code/counter/src/Counter.sol](code/counter/src/Counter.sol) | increment、decrementを持つCounter |
| [code/counter/test/Counter.t.sol](code/counter/test/Counter.t.sol) | テスト三つ（最終版）。0でのdecrementがリバートされるかを`vm.expectRevert(stdError.arithmeticError)`で確認 |

### 実行結果

helloで`forge test --offline`：

```
Ran 2 tests for test/Counter.t.sol:CounterTest
[PASS] testFuzz_SetNumber(uint256) (runs: 256, μ: 49958, ~: 52529)
[PASS] test_Increment() (gas: 51847)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 5.11ms (4.72ms CPU time)
```

起動したチェーンがないので`cast block-number`は接続拒否で終わるが、`forge test`はそのまま通る。出力は元の実行結果の文字列だけを訳したもの。

```
Error: MPP HTTP request to http://localhost:8545/ failed: HTTP request failed: error sending request: error sending request: client error (Connect): tcp connect error: 対象のコンピューターによって拒否されたため、接続できませんでした。 (os error 10061)
```

counterで、3番目のテストを`expectRevert`なしで`counter.decrement();`だけを呼ぶように書くと失敗する：

```
Ran 3 tests for test/Counter.t.sol:CounterTest
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_DecrementFromZero() (gas: 28743)
[PASS] test_Increment() (gas: 51882)
[PASS] test_IncrementTwice() (gas: 78816)
Suite result: FAILED. 2 passed; 1 failed; 0 skipped; finished in 749.40µs (519.70µs CPU time)
```

最終版：

```
Ran 3 tests for test/Counter.t.sol:CounterTest
[PASS] test_Increment() (gas: 51882)
[PASS] test_IncrementTwice() (gas: 78838)
[PASS] test_RevertWhen_DecrementFromZero() (gas: 32393)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 896.50µs (1.05ms CPU time)
```

わざと間違えて直したバージョン。`test_IncrementTwice`の期待値を3に変え、1からのdecrementがリバートされると期待するテストを足した：

```solidity
function test_RevertWhen_DecrementFromOne() public {
    counter.increment();
    vm.expectRevert(stdError.arithmeticError);
    counter.decrement();
}
```

```
Ran 4 tests for test/Counter.t.sol:CounterTest
[PASS] test_Increment() (gas: 51904)
[FAIL: assertion failed: 2 != 3] test_IncrementTwice() (gas: 81944)
[FAIL: next call did not revert as expected] test_RevertWhen_DecrementFromOne() (gas: 79323)
[PASS] test_RevertWhen_DecrementFromZero() (gas: 32327)
Suite result: FAILED. 2 passed; 2 failed; 0 skipped; finished in 2.69ms (2.34ms CPU time)
```

最終版で`vm.expectRevert();`のように括弧を空にすると、どんな理由でリバートされても通る（`test_RevertWhen_DecrementFromZero() (gas: 31596)`）。

間違えたバージョンで`forge test --offline --match-test test_IncrementTwice -vvvv`で見た呼び出しツリー：

```
Ran 1 test for test/Counter.t.sol:CounterTest
[FAIL: assertion failed: 2 != 3] test_IncrementTwice() (gas: 81944)
Traces:
  [8576] CounterTest::setUp()
    ├─ [0] VM::deployCode("src/Counter.sol:Counter")
    │   ├─ [84933] → new Counter@0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
    │   │   └─ ← [Return] 424 bytes of code
    │   └─ ← [Return] Counter: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]
    └─ ← [Stop]

  [81944] CounterTest::test_IncrementTwice()
    ├─ [43539] Counter::increment()
    │   └─ ← [Stop]
    ├─ [26439] Counter::increment()
    │   └─ ← [Stop]
    ├─ [2402] Counter::count() [staticcall]
    │   └─ ← [Return] 2
    ├─ [0] VM::assertEq(2, 3) [staticcall]
    │   └─ ← [Revert] assertion failed: 2 != 3
    └─ ← [Revert] assertion failed: 2 != 3

Backtrace:
  at VM.assertEq
  at CounterTest.test_IncrementTwice
```

最終版に戻したあと`forge test --offline --gas-report`（空の区切り行は一部省略）：

```
╭----------------------------------+-----------------+-------+--------+-------+---------╮
| src/Counter.sol:Counter Contract |                 |       |        |       |         |
+=======================================================================================+
| Deployment Cost                  | Deployment Size |       |        |       |         |
|----------------------------------+-----------------+-------+--------+-------+---------|
|                                0 |             452 |       |        |       |         |
|----------------------------------+-----------------+-------+--------+-------+---------|
| Function Name                    | Min             | Avg   | Median | Max   | # Calls |
|----------------------------------+-----------------+-------+--------+-------+---------|
| count                            |            2402 |  2402 |   2402 |  2402 |       2 |
|----------------------------------+-----------------+-------+--------+-------+---------|
| decrement                        |           23510 | 23510 |  23510 | 23510 |       1 |
|----------------------------------+-----------------+-------+--------+-------+---------|
| increment                        |           26439 | 37839 |  43539 | 43539 |       3 |
╰----------------------------------+-----------------+-------+--------+-------+---------╯
```

`--match-test test_Increment`は、名前にその文字列を含む`test_Increment`と`test_IncrementTwice`を両方実行する。末尾を固定した`'test_Increment$'`は`Warning: No tests found in project!`で終わる。

`FOUNDRY_PROFILE=ci forge test --offline`（optimizerオン、runs 10000）：

```
[PASS] test_Increment() (gas: 51468)
[PASS] test_IncrementTwice() (gas: 78312)
[PASS] test_RevertWhen_DecrementFromZero() (gas: 31806)
```

同じプロファイルのガスの表では、Deployment Sizeは303、count 2259、decrement 23403、increment 26327 / 37727 / 43427 / 43427である。

### 試すときの注意

- `--gas-report`のDeployment Costの欄は、このバージョンの出力では0と表示される。
- `--match-test 'test_Increment\('`はtest_Incrementを一つだけ実行した。このバージョンは名前を、括弧までついた`test_Increment()`の形と照らし合わせているように見える。一つだけ実行するときは、重ならない名前を使うほうが簡単である。
- プロファイルを変えると設定が変わり、全体を再コンパイルする。defaultに戻るときも同じである。
- テスト関数の構成が変わると、ほかのテストのガスも少しずつ変わる（テスト関数が四つのときtest_Incrementは51904）。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundryのバージョン | forge 1.8.3 (Commit cae51ad4) | 2026-10-18 |
| デフォルトのfuzz runs | 256 | 2026-10-18 |
| solc | 0.8.30 | 2026-10-18 |
| ガス・デプロイサイズの数字 | 実行結果の値。Foundry・solcのバージョン、テスト関数の構成が変わると変わる（例：テスト関数が四つのときtest_Incrementは51904） | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| vmの正体とcheatcode（時刻、送り手を変える） | [第29講](../../part2/lecture29/) |
| ほかのアカウントが呼ぶ場合のテスト | [第29講](../../part2/lecture29/) |
| 本物のチェーンの状態の上でのテスト | [第30講](../../part2/lecture30/) |
| testFuzzとrunsの動作、書かなかった値を入れてみる | [第31講](../../part2/lecture31/) |
| 呼び出しツリーを詳しく読む、デバッガー | [第32講](../../part2/lecture32/) |
| ガスレポートの比較とスナップショット | [第33講](../../part2/lecture33/) |
| ストレージ書き込みのガスの規則（初回の書き込みと書き換え） | [第143講](../../part9/lecture143/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
