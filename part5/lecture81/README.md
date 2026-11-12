# 第81講 制御文

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第80講](../../part5/lecture80/) | [第5部 目次](../) | [第82講 →](../../part5/lecture82/)

## この講義の問い

ほかの言語でさんざん使ってきた`if`、`for`、`return`は、この機械の上では何が違うのか。

## 実習資料

### 準備

空のFoundryプロジェクト二つから始める。`demo`はビルドが通るバージョン、`errors`はビルドエラーを見るバージョンである。どちらもfoundry.tomlで`solc = "0.8.30"`に固定し、forge-stdを`lib/forge-std`に置く。コントラクトはローカルのanvil（ブロックガスリミットは既定値30,000,000）に既定のアカウント0番（anvilの公開されたテスト用の鍵）で`forge create`し、`cast call`・`cast send`で呼ぶ。`errors`のファイルは一つずつ`forge build --offline --force src/<ファイル>`でビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket（第17章の終わりのバージョン）に、担保資産を数える`collateralCount`と、三つの状態を`if`・`else if`で分けるデモ用の`statusNote`を足したバージョン |
| [code/demo/src/Loops.sol](code/demo/src/Loops.sol) | n回回る`run`、returnで終える`runCapped`（Counter）、`while`・`do while`・`break`・`continue`、終わらない`spin`（LoopKinds） |
| [code/demo/src/CondFixed.sol](code/demo/src/CondFixed.sol) | 条件に`x != 0`、`a != address(0)`を直接書いたバージョン |
| [code/demo/src/Guard.sol](code/demo/src/Guard.sol) | `enabled && oracle.ok()`の短絡評価の例 |
| [code/demo/test/Guard.t.sol](code/demo/test/Guard.t.sol) | `check(false)`、`check(true)`の二つのテスト。トレースの比較用 |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/Switch.sol](code/errors/src/Switch.sol) | `switch`、Error 6933 |
| [code/errors/src/Goto.sol](code/errors/src/Goto.sol) | `goto`、Error 7920 |
| [code/errors/src/IntCond.sol](code/errors/src/IntCond.sol) | 整数・アドレスを条件に、Error 7407 |
| [code/errors/src/BoolCast.sol](code/errors/src/BoolCast.sol) | `bool(x)`、Error 9640 |
| [code/errors/src/ForScope.sol](code/errors/src/ForScope.sol) | `for`の括弧の中の`i`をループの外で読む、Error 7576 |
| [code/errors/src/hook/Market.sol](code/errors/src/hook/Market.sol) | `collateralCount`の条件に預け入れ金額（uint256）を入れたバージョン、Error 7407 |

### 実行結果

`switch`と`goto`のビルドエラー。

```
Error (6933): Expected primary expression.
 --> src/Switch.sol:6:9:
  |
6 |         switch (x) {
  |         ^^^^^^
Error (7920): Identifier not found or not unique.
 --> src/Goto.sol:6:9:
  |
6 |         goto done;
  |         ^^^^
```

整数・アドレスを条件に入れたバージョンと、`bool(x)`に変換したバージョンのビルドエラー。

```
Error (7407): Type uint256 is not implicitly convertible to expected type bool.
 --> src/IntCond.sol:6:13:
  |
6 |         if (x) {
  |             ^
Error (7407): Type address is not implicitly convertible to expected type bool.
 --> src/IntCond.sol:9:13:
  |
9 |         if (a) {
  |             ^
Error (9640): Explicit type conversion not allowed from "uint256" to "bool".
 --> src/BoolCast.sol:6:13:
  |
6 |         if (bool(x)) {
  |             ^^^^^^^
```

`for`の括弧の中の変数を外で読んだときのビルドエラー。

```
Error (7576): Undeclared identifier.
 --> src/ForScope.sol:8:16:
  |
8 |         return i;
  |                ^
```

`cast call`で読んだ値。

| 呼び出し | 結果 |
|---|---|
| Market `statusNote()`（デプロイ直後） | `"open"` |
| CondFixed `check(5, アカウント0番のアドレス)` / `check(0, 0x0)` | 3 / 0 |
| `whileCount(3)` / `doWhileCount(3)` | 3 / 3 |
| `whileCount(0)` / `doWhileCount(0)` | 0 / 1 |
| `sumOdd(10, 100)` / `sumOdd(10, 6)` | 25 / 9 |
| `run(10)`（return行なしで名前つきの戻り値） | 45 |
| `runCapped(0, 100)` | 0 |
| `runCapped(200000, 100)` | 105 |

Counterの`run(n)`を`cast send`で送ったときのgasUsed。n=10は`last`の欄に初めて書くトランザクションである。

| n | gasUsed |
|---|---|
| 10 | 46,452 |
| 1,000 | 275,874 |
| 100,000 | 24,926,886 |

`run(200000)`をそのまま送るとガスの見積もりで拒否され、上限を自分で指定するとブロックに入って失敗する（`cast send`の出力はgasUsed・statusの行だけ）。

```
$ cast block latest --field gasLimit
30000000
$ cast send $C "run(uint256)" 200000 --private-key $PK0
Error: Failed to estimate gas: server returned an error response: error code -32003: Out of gas: gas required exceeds allowance: 30000000
$ cast send $C "run(uint256)" 200000 --gas-limit 30000000 --private-key $PK0
gasUsed              30000000
status               0 (failed)
```

`spin()`も`--gas-limit 30000000`で送るとgasUsed 30000000、status 0で、`spins()`は0のままである。`runCapped(200000, 100)`はgasUsed 31335、status 1で終わる。終わったあとの`cast storage $C 0`（lastの欄）は、失敗した`run(200000)`のあとでは`0x186a0`（その前のrunの値100,000）、`runCapped`のあとでは`0x30d40`（200,000）である。

失敗した`run(200000)`の`cast receipt`の出力のうち5行。

```
blockNumber          7
from                 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
gasUsed              30000000
logs                 []
status               0 (failed)
```

Guardのテストの`forge test --offline -vvvv`のトレース。`enabled`がfalseならOracleの呼び出しの行がない。

```
[PASS] test_false() (gas: 6136)
Traces:
  [6136] GuardTest::test_false()
    ├─ [623] Guard::check(false) [staticcall]
    │   └─ ← [Return] false
    └─ ← [Stop]
[PASS] test_true() (gas: 11644)
Traces:
  [11644] GuardTest::test_true()
    ├─ [6085] Guard::check(true) [staticcall]
    │   ├─ [316] Oracle::ok() [staticcall]
    │   │   └─ ← [Return] true
    │   └─ ← [Return] true
    └─ ← [Stop]
```

Marketに`addAsset`で資産を増やしながら、`collateralCount(アカウント0番)`を`cast send`で送ったときのgasUsed。資産一つにつき約4,860ガス増える。

| 資産の数（`assetCount()`） | gasUsed |
|---|---|
| 1 | 29,122 |
| 10 | 72,907 |
| 100 | 510,757 |

### 試すときの注意

- 条件の位置にはboolしか来ない。整数・アドレスは`bool(x)`でも変換できないので、`x != 0`、`a != address(0)`のように比較を書く。
- `do while`は条件を見る前に本体を1回回る（`doWhileCount(0)`が1）。
- 繰り返しの回数を引数や配列の長さが決めると、ガスの上限もコードでは決められない。`collateralCount`は`assets`全体を回り、その長さは管理者が`addAsset`で決める。
- デモ用の`statusNote`は、この講義での確認用である。Marketを続けて使うときは`collateralCount`だけを残す。状態の欄の配置（スロット0〜6）は変わらない。
- `useAsCollateral`をオンにする関数がまだないので、`collateralCount`の戻り値は0である。テスト用の資産のアドレスは`0x…1001`から順に使った。
- ガスの値は、solc 0.8.30、optimizerは切る（既定値）、Foundry 1.8.3、anvilでの値である。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| anvilのブロックガスリミット | 既定値30,000,000 | 2026-10-19 |
| イーサリアムメインネットのブロックガスリミット | 約6,000万ガス（直近24時間のブロック300個の標本で59,941,351〜60,058,592）。既定値60MはEIP-7935 | 2026-10-20 |
| run(n)のgasUsed | n=10 46,452（lastの欄への初めての書き込みを含む）、n=1,000 275,874、n=100,000 24,926,886、n=200,000 30,000,000で失敗 | 2026-10-19 |
| runCapped(200000, 100) | gasUsed 31,335、戻り値105 | 2026-10-19 |
| spin() | gasUsed 30,000,000で失敗 | 2026-10-19 |
| Guardのトレースのガス | check(false) 623 / check(true) 6,085（内側のOracle::ok 316）、テスト 6,136 / 11,644 | 2026-10-19 |
| collateralCountのgasUsed | 資産1個 29,122、10個 72,907、100個 510,757 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 内部関数の呼び出しと外部関数の呼び出し | [第82講](../../part5/lecture82/)、[第83講](../../part5/lecture83/) |
| 1行の中の計算の順番 | [第85講](../../part5/lecture85/) |
| `for`の括弧の中の変数が見える範囲、宣言の規則 | [第87講](../../part5/lecture87/) |
| ループの中のあふれの検査と`unchecked` | [第88講](../../part5/lecture88/)、[第89講](../../part5/lecture89/) |
| リバートさせる文法（`require`、`revert`、`assert`） | [第90講](../../part5/lecture90/) |
| `try`/`catch`の文法 | [第91講](../../part5/lecture91/) |
| `switch`があるYul | [第119講](../../part7/lecture119/) |
| ループのガスを減らすこと | [第143講](../../part9/lecture143/) |
| 上限を超えるループで止まる関数と、分割して処理すること | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
