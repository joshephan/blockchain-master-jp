# 第85講 評価の順番

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第84講](../../part5/lecture84/) | [第5部 目次](../) | [第86講 →](../../part5/lecture86/)

## この講義の問い

1行の中のいくつもの式はどんな順番で計算され、その順番は誰が決めるのか。

## 実習資料

### 準備

空のFoundryプロジェクト一つ（`demo`）から始める。foundry.tomlで`solc = "0.8.30"`に固定し、forge-stdを`lib/forge-std`に置く。同じソースを既定のコード生成と`--via-ir`の二つのビルドでローカルのanvilにデプロイし（既定のアカウント0番、anvilの公開されたテスト用の鍵）、結果を比べる。`forge create`と`forge test`に`--via-ir`をつけるとIRビルドになる。`count_effects.py`はPython 3の標準ライブラリだけを使い、`demo`フォルダで`python -I -X utf8 ../count_effects.py src/<ファイル>`として実行する。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Order.sol](code/demo/src/Order.sol) | 自分の番号をlogに書くg・hで、`f(g(), h())`、`g() + h()`の計算の順番を記録 |
| [code/demo/src/Pick.sol](code/demo/src/Pick.sol) | `&&`・`\|\|`の短絡評価（`andLeft`、`orLeft`）と三項演算子（`pick`） |
| [code/demo/src/Touch.sol](code/demo/src/Touch.sol) | 第74講の`arr[i++] += 1` |
| [code/demo/src/Twice.sol](code/demo/src/Twice.sol) | 1行に副作用を二つ（`inc() * 10 + inc()`、`inc() + inc()`、`a[i] = i++`）置いたTwiceと、1行に一つずつに分けたTwiceSplit |
| [code/demo/src/Pay.sol](code/demo/src/Pay.sol) | 引数の二つの位置に残高の読み取りとトークンを送る外部呼び出しを置いたPay、デモ用の最小限のToken |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket、第84講までのバージョン。この講義で変えた行はない |
| [code/demo/test/Twice.t.sol](code/demo/test/Twice.t.sol) | `tens()`の結果を21と期待したテスト |
| [code/demo/test/Pay.t.sol](code/demo/test/Pay.t.sol) | `payOne`のあと`seen`が100かを確かめる |
| [code/count_effects.py](code/count_effects.py) | 1行に状態を変えうる式（代入、複合代入、`++`、`--`、push、pop、delete、view・pureでない関数の呼び出し）がいくつあるかを数える目安のツール |

### 実行結果

`cast call`で返ってきたlog（計算の順番）。`$OL`は既定のビルド、`$OI`は`--via-ir`のビルド、`$PI`はPickである。

| 呼び出し | 既定のビルド | `--via-ir` |
|---|---|---|
| `args()`: `f(g(), h())` | [1, 2] | [1, 2] |
| `plus()`: `g() + h()` | [2, 1] | [1, 2] |

| Pickの呼び出し | 結果 |
|---|---|
| `andLeft(false)` / `andLeft(true)` | [] / [1] |
| `orLeft(true)` / `orLeft(false)` | [] / [1] |
| `pick(true)` / `pick(false)` | [1] / [2] |

`x = inc() * 10 + inc();`を二つのビルドで送った結果。どちらもビルドと実行に成功し、値だけが違う。

```
$ cast send $TL "tens()" --private-key $PK0
status               1 (success)
$ cast call $TL "x()(uint256)"
21
$ cast send $TI "tens()" --private-key $PK0
status               1 (success)
$ cast call $TI "x()(uint256)"
12
```

同じテストが、ビルドのオプション一つで分かれる。

```
$ forge test --offline --match-test test_tens
[PASS] test_tens() (gas: 73554)
$ forge test --offline --via-ir --match-test test_tens
[FAIL: assertion failed: 12 != 21] test_tens() (gas: 81731)
```

Twice.solは、既定のビルドでも`--via-ir`のビルドでも、エラーも警告もなくビルドされる。`a[i] = i++`（最初はi = 1）は、二つのビルドとも右側の`i++`を先に計算してa[2]を書き換える。

```
$ cast call $TL "i()(uint256)"
1
$ cast send $TL "slot()" --private-key $PK0
status               1 (success)
$ cast call $TL "i()(uint256)"
2
$ cast call $TL "a(uint256)(uint256)" 1
0
$ cast call $TL "a(uint256)(uint256)" 2
1
```

1行に一つずつに分けたTwiceSplitは、`tens()`・`slot()`のあと`x()`が12、`a(1)`が1である。第74講のTouchの`touch()`は、二つのビルドともi 1、arr[0] 1である。

`count_effects.py`でTwice.solを数えた結果。

```
$ python -I -X utf8 ../count_effects.py src/Twice.sol
状態を変える関数: inc, slot, sum, tens
 11 [1] c += 1;
 16 [3] x = inc() + inc();
 20 [3] x = inc() * 10 + inc();
 24 [2] a[i] = i++;
 36 [1] c += 1;
 41 [1] uint256 first = inc();
 42 [1] uint256 second = inc();
 43 [1] x = first * 10 + second;
 48 [1] i = k + 1;
 49 [1] a[k] = k;
2個以上の行: 3
```

Payの`payOne`のトレース（`forge test --offline --match-test test_payOne -vvvv`）。今回は二つのビルドともbalanceOfのあとにtransferの順番で、seenは100である。transferが先に動くと99になる。

```
Traces:
  [88026] PayTest::test_payOne()
    ├─ [79539] Pay::payOne(0x000000000000000000000000000000000000bEEF)
    │   ├─ [2801] Token::balanceOf(Pay: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]) [staticcall]
    │   │   └─ ← [Return] 100
    │   ├─ [26534] Token::transfer(0x000000000000000000000000000000000000bEEF, 1)
    │   │   └─ ← [Return] true
    │   └─ ← [Stop]
    ├─ [2425] Pay::seen() [staticcall]
    │   └─ ← [Return] 100
    └─ ← [Stop]
```

Market.solを数えた結果。104行目の2は`collateralCount`のローカルのカウンタ`i = 0`と`i++`なので、状態の欄ではない。状態の欄を二つ以上変える行はない。Pay.solの`payOne`の行は2と出る。

```
$ python -I -X utf8 ../count_effects.py src/Market.sol
状態を変える関数: _credit, _debit, _touch, addAsset, deposit, transfer, transferFrom, withdraw
 43 [1] admin = msg.sender;
 49 [1] assets.push(asset);
 50 [1] assetConfig[address(asset)] = AssetConfig({collateralRatio: ratio, listed: true});
 55 [1] _credit({asset: asset, user: msg.sender, amount: amount});
 56 [1] bool ok = IERC20(asset).transferFrom(msg.sender, address(this), amount);
 61 [1] _debit({asset: asset, user: msg.sender, amount: amount});
 62 [1] bool ok = IERC20(asset).transfer(msg.sender, amount);
 68 [1] p.deposited = Amount.wrap(Amount.unwrap(p.deposited) + amount);
 69 [1] _touch(p);
 70 [1] totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) + amount);
 75 [1] p.deposited = Amount.wrap(Amount.unwrap(p.deposited) - amount);
 76 [1] _touch(p);
 77 [1] totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) - amount);
 81 [1] p.lastUpdate = uint64(block.timestamp);
104 [2] for (uint256 i = 0; i < assets.length; i++) {
106 [1] count++;
2個以上の行: 1
```

### 試すときの注意

- 言語が決めている順番は、文の順番と`&&`・`||`の短絡評価だけである。関数の引数と`a[i] = i++`は今回の二つのビルドで同じ順番だったが、保証されたものではない。
- `test_tens`は既定のビルドでだけ通る。テストが通ったというのは、いまのコンパイラと設定が選んだ順番で通ったということである。
- 1行に状態を変える式は一つだけ置く。分ければ、順番は文の順番が決める。
- `count_effects.py`は正規表現で数える目安のツールである。ほかのコントラクトの関数名は、同じファイルに宣言があるときだけ拾い（Marketの`transferFrom`はIERC20の宣言で拾われる）、ローカル変数への代入も数える。
- `cast call`は、状態を変える関数でもブロックに残さず、実行してみた結果だけを返す。

## 時効性のあるデータ

基準日時点の値。コンパイラのバージョンや設定が変わると結果が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、via_irの既定値false（`forge config`）、evm_versionの既定値osaka | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 測定結果 | Order `args` 既定 [1, 2] / IR [1, 2]、`plus` 既定 [2, 1] / IR [1, 2]; Twice `tens` 既定 21 / IR 12、`slot` 二つのビルドでa[2] = 1; Touch 二つのビルドでi 1、arr[0] 1; Pay `seen` 二つのビルドで100 | 2026-10-19 |
| gasUsed（参考） | tens 既定 66,762 / IR 68,526 / 分けたバージョン 66,808; slot 既定 48,622 / IR 49,734 / 分けたバージョン 48,561; touch 既定 65,795 / IR 67,092; payOne 既定 79,755 / IR 63,965 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 複数の値を一度に受け取る代入（分割代入）と受け取らなかった戻り値 | [第86講](../../part5/lecture86/) |
| modifierが関数の本体とどんな順番で動くか | [第103講](../../part6/lecture103/) |
| 演算子の優先順位と演算子の総覧 | [第126講](../../part7/lecture126/) |
| コマンドラインのオプションとStandard JSONの`viaIR`の設定 | [第128講](../../part8/lecture128/) |
| IRコード生成と既定のコード生成の違い全般 | [第133講](../../part8/lecture133/) |
| 外部呼び出しの間に相手が再び入ってくる攻撃と、防ぐ順番 | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| 不変条件とファジングで順番への依存を見つけること | [第183講](../../part11/lecture183/) |
| バージョンごとの変更履歴と検算つきの算術 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| コード精読のチェックリスト（1行に副作用二つの項目） | [第188講](../../part12/lecture188/) |
| 順番に依存する欠陥の深刻度の判定 | [第189講](../../part12/lecture189/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
