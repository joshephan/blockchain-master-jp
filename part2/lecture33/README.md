# 第33講 ガスレポートとスナップショット

第2部 開発とテスト環境・第8章 デバッグ・計測・デプロイ

[← 第32講](../../part2/lecture32/) | [第2部 目次](../) | [第34講 →](../../part2/lecture34/)

## この講義の問い

コードを直すたびにガスがどう変わったかを数字で残すには、何を測り、何と比べるべきか。

## 実習資料

### 準備

第28講のCounterプロジェクト（`forge init`で作ったhelloプロジェクトのsrcとtestをCounterに変えたもの）から始める。すべての実行はanvilなしで、forgeの中でだけ動く。テストにはforge-stdが必要である（`lib/forge-std`）。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、optimizerをオンにした`ci`プロファイル |
| [code/src/Counter.sol](code/src/Counter.sol) | increment・decrementに`add`を足したCounter |
| [code/test/Counter.t.sol](code/test/Counter.t.sol) | テスト三つとファズテスト`testFuzz_Add` |

### 実行結果

基準のスナップショット（`.gas-snapshot`、addを入れる前）：

```
CounterTest:test_Increment() (gas: 51882)
CounterTest:test_IncrementTwice() (gas: 78838)
CounterTest:test_RevertWhen_DecrementFromZero() (gas: 32393)
```

`add`を追加したあとの`forge snapshot --diff`：

```
↑ CounterTest::test_Increment() (gas: 51882 → 51904 | 22 0.042%)
↑ CounterTest::test_IncrementTwice() (gas: 78838 → 78882 | 44 0.056%)
↑ CounterTest::test_RevertWhen_DecrementFromZero() (gas: 32393 → 32415 | 22 0.068%)

--------------------------------------------------------------------------------
Total tests: 3, ↑ 3, ↓ 0, ━ 0
Overall gas change: 88 (0.054%)
```

関数セレクタ（`forge inspect Counter methodIdentifiers`）：

```
| add(uint256) | 1003e2d2   |
| count()      | 06661abd   |
| decrement()  | 2baeceb7   |
| increment()  | d09de08a   |
```

アセンブリでセレクタを比較する順番は06661abd、1003e2d2、2baeceb7、d09de08aである。addを追加したあと、incrementの実行ガスは43539 → 43561、decrementは23510 → 23532に上がり、countは2402のままだった。

`ci`プロファイル（optimizerオン）で取った`--diff`：

```
↓ CounterTest::test_IncrementTwice() (gas: 78882 → 78356 | -526 -0.667%)
↓ CounterTest::test_Increment() (gas: 51904 → 51490 | -414 -0.798%)
↓ CounterTest::test_RevertWhen_DecrementFromZero() (gas: 32415 → 31828 | -587 -1.811%)
--------------------------------------------------------------------------------
Total tests: 3, ↑ 0, ↓ 3, ━ 0
Overall gas change: -1527 (-0.936%)
```

`--diff`はファイルを変えない。同じ状態で`--check`は終了コード1で終わる。

`testFuzz_Add`を追加したあとのスナップショット：

```
CounterTest:testFuzz_Add(uint128) (runs: 256, μ: 52575, ~: 52846)
CounterTest:test_Increment() (gas: 51904)
CounterTest:test_IncrementTwice() (gas: 78904)
CounterTest:test_RevertWhen_DecrementFromZero() (gas: 32349)
```

ファズのシードを変えた`--diff`（`--fuzz-seed 0x1234`）：

```
[PASS] testFuzz_Add(uint128) (runs: 256, μ: 52499, ~: 52846)
━ CounterTest::testFuzz_Add(uint128) (gas: 52846 → 52846 | 0 0.000%)
━ CounterTest::test_Increment() (gas: 51904 → 51904 | 0 0.000%)
━ CounterTest::test_IncrementTwice() (gas: 78904 → 78904 | 0 0.000%)
━ CounterTest::test_RevertWhen_DecrementFromZero() (gas: 32349 → 32349 | 0 0.000%)
Total tests: 4, ↑ 0, ↓ 0, ━ 4
```

### 試すときの注意

- `.gas-snapshot`ファイルは最後の行のあとに改行がない（git diffに`\ No newline at end of file`）。
- テストコントラクトもセレクタを分けて比較するので、テスト関数を一つ追加すると、ほかのテストのガスが上がることも下がることもある（78882 → 78904、32415 → 32349）。
- Windowsのgitでは、`.gas-snapshot`にLF/CRLFの警告が出ることがある。`core.autocrlf`の設定を確認する。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge）のバージョン | 1.8.3 (cae51ad) | 2026-10-18 |
| solcのバージョン | 0.8.30 | 2026-10-18 |
| デフォルトのfuzz runs | 256 | 2026-10-18 |
| forge testのファズのμ | 実行ごとに変動（52810、52496、52499） | 2026-10-18 |
| forge snapshotのファズのμ | 3回とも52575 | 2026-10-18 |
| --diff・--checkのファズの行の比較基準 | 中央値（~）。`--fuzz-seed 0x1234`でμが52499になっても差は0 | 2026-10-18 |
| --checkが一致しないときの終了コード | 1 | 2026-10-18 |
| --gas-reportのDeployment Costの欄 | 0と表示 | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| デプロイスクリプトとコントラクトの検証 | [第34講](../../part2/lecture34/) |
| 関数セレクタの計算と、コントラクトが関数を選ぶ方法 | [第101講](../../part6/lecture101/) |
| ストレージ書き込みのガスの規則（初回の書き込みと書き換え） | [第143講](../../part9/lecture143/) |
| 最適化がセキュリティを損なう場合 | [第144講](../../part9/lecture144/) |
| ベンチマーク、CIでのガスの回帰防止の設計（--toleranceなど） | [第145講](../../part9/lecture145/) |
| オプティマイザは何を減らすのか | [第139講](../../part8/lecture139/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
