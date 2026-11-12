# 第31講 ファズテストと不変条件テスト入門

第2部 開発とテスト環境・第7章 ローカルチェーンとテスト

[← 第30講](../../part2/lecture30/) | [第2部 目次](../) | [第32講 →](../../part2/lecture32/)

## この講義の問い

入力を人が選ばずにツールに選ばせると、テストには何を書くべきで、それでも見つけられないものは何か。

## 実習資料

### 準備

`forge init`で作ったプロジェクト（forge-stdを含む）を`fuzz`という名前でコピーして始める。forge-stdは新しくダウンロードせず、すべてのビルドに`--offline`をつける。ハッシュ比較の実験は、Plainのない別のプロジェクト`gate`（foundry.tomlとlibだけをコピー）で行う。

### コード

| ファイル | 内容 |
|---|---|
| [code/fuzz/foundry.toml](code/fuzz/foundry.toml) | `forge init`の基本設定 |
| [code/fuzz/src/Counter.sol](code/fuzz/src/Counter.sol)、[code/fuzz/test/Counter.t.sol](code/fuzz/test/Counter.t.sol) | initのサンプルCounterとファズテスト`testFuzz_SetNumber` |
| [code/fuzz/src/Fee.sol](code/fuzz/src/Fee.sol) | 金額の0.3%を差し引く手数料関数 |
| [code/fuzz/test/Fee.t.sol](code/fuzz/test/Fee.t.sol) | 例のテスト一つと規則のテスト三つ（`bound`、`vm.assume`） |
| [code/fuzz/src/Token.sol](code/fuzz/src/Token.sol) | mint、transfer、burnだけがあるトークン（直したtransfer） |
| [code/buggy/src/Token.sol](code/buggy/src/Token.sol) | 同じトークンのバグのあるバージョン。transferが二つの残高を先に読んでおいて上書きする |
| [code/fuzz/test/Token.t.sol](code/fuzz/test/Token.t.sol) | ハンドラー（ユーザー三人、金額を残高の範囲にbound）と不変条件「供給量 = 残高の合計」 |
| [code/fuzz/src/Plain.sol](code/fuzz/src/Plain.sol)、[code/fuzz/test/Plain.t.sol](code/fuzz/test/Plain.t.sol) | x == 20261018のときだけfalseを返す関数とファズテスト |
| [code/gate/src/Gate.sol](code/gate/src/Gate.sol)、[code/gate/test/Gate.t.sol](code/gate/test/Gate.t.sol)、[code/gate/foundry.toml](code/gate/foundry.toml) | 同じ条件をxのkeccak256ハッシュで比較する関数とファズテスト |

`code/buggy/src/Token.sol`は、そのフォルダだけではビルドできない。`code/fuzz/src/Token.sol`と入れ替えて同じテストを実行する。

### 実行結果

initのサンプルのファズテスト（`forge test --offline --match-contract CounterTest`）：

```
[PASS] testFuzz_SetNumber(uint256) (runs: 256, μ: 51361, ~: 52529)
[PASS] test_Increment() (gas: 51847)
```

手数料関数（`forge test --offline --match-contract FeeTest`）。例のテストは通り、規則二つが反例を出す。一つ目はuint256の最大値に3を掛けてあふれたもの、二つ目は1 × 3 / 1000 = 0である。範囲を`bound(amount, 0, 1e30)`で決めたテストは、256回すべて通る：

```
[FAIL: panic: arithmetic underflow or overflow (0x11);
  counterexample: calldata=0x24462fc1ffff...ffff
  args=[115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]]]
  testFuzz_FeeNotAboveAmount(uint256) (runs: 65, μ: 6857, ~: 6857)
[FAIL: assertion failed: 0 <= 0;
  counterexample: calldata=0xd041faa2...0001 args=[1]]
  testFuzz_FeeNotZero(uint256) (runs: 24, μ: 10829, ~: 11504)
[PASS] test_Fee() (gas: 6720)
```

バグのあるトークンの不変条件テスト（`forge test --offline --match-contract TokenTest`）。10回で失敗し、forgeが呼び出しの順序を2個に縮めた。残った二つの呼び出しは、ボブ（`70 % 3`）へのmint、続いてボブ（`7216 % 3`）からボブ（`100 % 3`）へのtransferである：

```
[FAIL: assertion failed: 628945774002701578146495 != 628945774002701578147320]
  [Sequence] (original: 10, shrunk: 2)
    ... calldata=mint(uint256,uint256) args=[70, 2827]
    ... calldata=transfer(uint256,uint256,uint256) args=[7216, 100, 51729 [5.172e4]]
 invariant_SupplyEqualsBalances() (runs: 1, calls: 10, reverts: 0)
[PASS] test_Transfer() (gas: 138310)
```

全体の出力には、Sequenceの前にJSON 1行（`{"timestamp":...,"event":"failure",...}`）と、関数ごとの呼び出し数の表（burn 2、mint 4、transfer 4）も出る。

transferを、残高からすぐ引いてすぐ足す形に直したあとで同じコマンド。256 × 500 = 128,000回の呼び出しがすべて通る（関数ごとにburn 42746、mint 42451、transfer 42803）：

```
[PASS] invariant_SupplyEqualsBalances() (runs: 256, calls: 128000, reverts: 0)
[PASS] test_Transfer() (gas: 138322)
```

x == 20261018をそのまま比較するPlainでは、forgeが反例を正確に見つける（`forge test --offline --match-contract PlainTest`）：

```
[FAIL: assertion failed; counterexample: calldata=0x88cddd05...0135289a
  args=[20261018 [2.026e7]]] testFuzz_Plain(uint256) (runs: 36, μ: 6408, ~: 6408)
```

Gateのコードに書かれた定数は、20261018のハッシュである（`cast keccak $(cast abi-encode "f(uint256)" 20261018)`）：

```
0x25cbcc7eb4cc357312d8bada948e6254c329b5007dd242ed95169991bf96730d
```

gateプロジェクトでは、256回でも10万回でも通る（`forge test --offline`、`rm -rf cache/fuzz`のあと`--fuzz-runs 100000`）：

```
[PASS] testFuzz_Gate(uint256) (runs: 256, μ: 6708, ~: 6708)
[PASS] testFuzz_Gate(uint256) (runs: 100000, μ: 6708, ~: 6708)
```

### 試すときの注意

- 同じフォルダにPlain.solがあると、Gateのファズテストも反例20261018を見つける。GateがPlainをimportもデプロイもしていないのにそうなる。同じプロジェクトでコンパイルされるソースに書かれた数字を集めて、入力の候補として使っているように見える。そのためgateプロジェクトを別に置く。テストファイルに`20261018`と書いても、同じ理由で見つける。
- 一度見つけた反例は`cache/fuzz`に残り、次の実行でまた使われる。新しく探させるには、`rm -rf cache/fuzz`のあとで実行する。
- setUpはファズ実行全体で一度だけ動き、各実行はsetUp直後の状態から始まる。
- 入力が一つのファズテストの反例は、より小さな値に縮めてはくれなかった（オーバーフローの反例が最小値ではなく最大値の近く）。縮小（shrunk）は不変条件テストの呼び出しの順序で見られる。
- 反例の値と呼び出しの順序は実行ごとに違う。

## 時効性のあるデータ

基準日時点の値。Foundryのバージョンが変わると、デフォルト値が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 実行環境 | Foundry 1.8.3（forge、cast）、solc 0.8.30、すべてのビルドで`--offline` | 2026-10-18 |
| デフォルトのfuzz runs | 256 | 2026-10-18 |
| デフォルトのinvariant runs / depth | 256 / 500（1回の実行で500呼び出し、合計128,000呼び出し） | 2026-10-18 |
| 不変条件の失敗時に呼び出しの順序を縮める上限 | shrink_run_limit = 5000 | 2026-10-18 |
| ファズ入力の候補の設定 | dictionary_weight 40、include_push_bytes true、max_fuzz_dictionary_literals 6553600 | 2026-10-18 |
| 直したトークンの不変条件テストの実行時間 | 約11.7秒（128,000呼び出し） | 2026-10-18 |
| Gateの10万回の実行時間 | 539.20ms | 2026-10-18 |
| 反例の値と呼び出しの順序 | 実行ごとに違う。実行結果の出力は1回の実行の値 | 2026-10-18 |
| 20261018のkeccak256(abi.encode) | 0x25cbcc7eb4cc357312d8bada948e6254c329b5007dd242ed95169991bf96730d | 固定 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 失敗したテストの呼び出しツリーとデバッガー | [第32講](../../part2/lecture32/) |
| 目的を持って1か所を狙う考え方 | [第167講](../../part11/lecture167/) |
| SMTChecker、記号実行のように入力全体を調べるツール | [第182講](../../part11/lecture182/) |
| 不変条件の設計、ハンドラーの設計、runs・depthの調整のようなファジングの戦略 | [第183講](../../part11/lecture183/) |
| 設計文書に不変条件を書く | [第254講](../../part20/lecture254/) |
| 監査での不変条件とファジング、自己監査 | [第259講](../../part20/lecture259/)、[第260講](../../part20/lecture260/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
