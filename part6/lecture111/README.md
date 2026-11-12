# 第111講 virtualとoverride

第6部 言語の詳細 ③ コントラクト・第25章 継承

[← 第110講](../../part6/lecture110/) | [第6部 目次](../) | [第112講 →](../../part6/lecture112/)

## この講義の問い

`virtual`と`override`の二つの表示は、それぞれ何を許して何を止め、コンパイラが確かめてくれないのは何か。

## 実習資料

### 準備

第110講のCounter・Childのデモ用のプロジェクト（`demo`）に、名前を打ち間違えたバージョン`ChildTypo`と本体だけを変えたバージョン`ChildZero`を加え、エラー・比較の例は`cases/`の下のファイルごとに`forge build --force <ファイル>`で別々にビルドする。ローカルのanvilにChild、Counter、ChildTypo、ChildZeroを順にデプロイし、`bumpBy`を呼ぶ。Marketの第111講のバージョンは、第110講のバージョンとコードが同じで、コメントだけが違う。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Inh.sol](code/demo/src/Inh.sol) | 第110講のCounter、Child、Overload |
| [code/demo/src/Typo.sol](code/demo/src/Typo.sol) | `stpe`と名前を打ち間違えた`ChildTypo`、`step`が0を返すように書き直した`ChildZero` |
| [code/demo/cases/](code/demo/cases/) | エラー・比較の例二十三個。ReOverride・VirtOverride、LaterV1・LaterV2・LaterV2Parent（親があとからfを加えたバージョン）、TypoOverride、可視性・状態変更可能性・戻り値の型を変えたバージョン、ViewCaller、PrivVirt、四つの状態変数（StateVirtual、StateOv、StateNoOv、StatePubFn）、IfaceImpl、ModOv |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第111講のバージョン。第110講のバージョンとコードは同じ、`virtual`がないというコメント一行 |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol)、[code/market/src/MockToken.sol](code/market/src/MockToken.sol) | インターフェースとテスト用のトークン |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト（42個） |

### 実行結果

二つの表示と、抜けたときのエラー。

| 表示 | 書く場所 | 意味 | 抜けると |
|---|---|---|---|
| `virtual` | 親の関数 | 継承する側が書き直してよい | Error 4334 |
| `override` | 子の関数 | 親の関数を書き直す | Error 9456 |
| `virtual override` | 書き直した関数 | 書き直したうえで、下でまた書き直してよい | 下で書き直すと4334 |

一度書き直した関数をその下でまた書き直すと止まり（`cases/ReOverride.sol`）、真ん中の関数を`virtual override`に変えた`cases/VirtOverride.sol`は通る。

```
$ forge build --offline --force cases/ReOverride.sol
Error (4334): Trying to override non-virtual function. Did you forget to add "virtual"?
 --> cases/ReOverride.sol:8:5:
```

親の第1版（`cases/LaterV1.sol`）はビルドできるが、親が同じ名前の`f`を加えた第2版（`cases/LaterV2.sol`）では、子のコードを変えていないのにビルドが止まる。親の第2版だけを別にビルドすると（`cases/LaterV2Parent.sol`）通る。

```
$ forge build --offline --force cases/LaterV2.sol
Error (9456): Overriding function is missing "override" specifier.
  --> cases/LaterV2.sol:10:5:
Error (4334): Trying to override non-virtual function. Did you forget to add "virtual"?
 --> cases/LaterV2.sol:7:5:
```

`override`なしで`stpe`と打ち間違えたChildTypoはビルドでき、新しい関数が一つできる。`bumpBy`はCounterの`step`（1）を動かす。

```
$ cast send $TY "bumpBy()" --unlocked --from $A --rpc-url $R | grep -E "^(status|gasUsed)"
gasUsed              65782
status               1 (success)
$ cast call $TY "count()(uint256)" --rpc-url $R
1
$ cast call $TY "step()(uint256)" --rpc-url $R
1
$ cast call $TY "stpe()(uint256)" --rpc-url $R
10
```

同じ打ち間違いに`override`を書くと、ビルドが止める。

```
$ forge build --offline --force cases/TypoOverride.sol
Error (7792): Function has override specified but does not override anything.
 --> cases/TypoOverride.sol:7:33:
  |
7 |     function stpe() public pure override returns (uint256) {
  |                                 ^^^^^^^^
```

本体だけを`return 0;`に変えたChildZeroは、警告なしでビルドでき、呼び出しも成功し、countは0のままである。

```
$ cast send $ZE "bumpBy()" --unlocked --from $A --rpc-url $R | grep -E "^(status|gasUsed)"
gasUsed              45859
status               1 (success)
$ cast call $ZE "count()(uint256)" --rpc-url $R
0
```

書き直すときに変えられるもの（`cases/`のビルド結果）。

| 親 → 子 | ビルド |
|---|---|
| 引数の名前`amount` → `x` | 通る |
| 戻り値の型`uint256` → `uint8` | Error (4822): Overriding function return types differ. |
| `external` → `public` | 通る |
| `public` → `external` | Error (9098): Overriding function visibility differs. |
| `internal` → `external` | Error (9098): Overriding function visibility differs. |
| `view` → `pure` | 通る |
| 表示なし（nonpayable） → `view` | 通る |
| `pure` → `view` | Error (6959): Overriding function changes state mutability from "pure" to "view". |
| `payable` → 表示なし | Error (6959): Overriding function changes state mutability from "payable" to "nonpayable". |

親の`view`関数が呼ぶ`f`を、子が状態を変えるように書き直すと止まる（`cases/ViewCaller.sol`）。

```
Error (6959): Overriding function changes state mutability from "view" to "nonpayable".
  --> cases/ViewCaller.sol:11:5:
```

書き直せないもの。

```
$ forge build --offline --force cases/PrivVirt.sol
Error (3942): "virtual" and "private" cannot be used together.
$ forge build --offline --force cases/StateVirtual.sol
Error (2314): Expected identifier but got 'virtual'
```

public状態変数が親の関数を書き直す場合。

| 親 | 子 | ビルド |
|---|---|---|
| `function x() external view virtual returns (uint256)` | `uint256 public override x = 7;` | 通る |
| 同じ | `uint256 public x = 7;` | Error (9456): Overriding public state variable is missing "override" specifier. |
| `function x() public view virtual returns (uint256)` | `uint256 public override x = 7;` | Error (5225): Public state variables can only override functions with external visibility. |

通ったバージョンのセレクタは、親の関数`x()`と同じ`0c55699c`一つである（`forge inspect cases/StateOv.sol:C methodIdentifiers`）。インターフェースの関数を実装するときは、`override`なしでビルドできる（`cases/IfaceImpl.sol`）。modifierのオーバーライド（`cases/ModOv.sol`）は、solc 0.8.30では警告なしで通る。

デプロイされたCounterは今も`bumpBy`が1ずつ上げ、書き直したChildは別のアドレスに別のコードとしてある。

```
$ cast call $CO "count()(uint256)" --rpc-url $R
1
$ cast call $CH "count()(uint256)" --rpc-url $R
10
$ cast code $CO --rpc-url $R | python -c "import sys; print((len(sys.stdin.read().strip())-2)//2)"
819
$ cast code $CH --rpc-url $R | python -c "import sys; print((len(sys.stdin.read().strip())-2)//2)"
945
```

Marketの第111講のバージョンで`grep -n "virtual"`で探すと、出てくる行はすべてコメントで、コードに`virtual`はない。Marketを継承して`_checkAdmin`・`onlyAdmin`・`notFrozen`を空の本体で書き直そうとするバージョンを加えてビルドすると、三か所とも止まる（Noteの行は省略）。

```
$ forge build --offline --force
Error (4334): Trying to override non-virtual modifier. Did you forget to add "virtual"?
   --> src/Market.sol:104:5:
    |
104 |     modifier onlyAdmin() {
Error (4334): Trying to override non-virtual modifier. Did you forget to add "virtual"?
  --> src/Market.sol:55:5:
   |
55 |     modifier notFrozen() {
Error (4334): Trying to override non-virtual function. Did you forget to add "virtual"?
   --> src/Market.sol:147:5:
    |
147 |     function _checkAdmin() internal view {
```

```
$ forge test --offline
Ran 12 test suites: 42 tests passed, 0 failed, 0 skipped (42 total tests)
$ forge build --offline --sizes
| Market     | 7,189            | 7,763             | 17,387             | 41,389              |
| MarketBase | 268              | 296               | 24,308             | 48,856              |
```

| 表示 | 許すもの | 止めるもの | 確かめないもの |
|---|---|---|---|
| `virtual` | 継承する側が書き直す | 書いていない関数の書き直し（4334） | デプロイされたコードは変えない |
| `override` | 親の関数を書き直す | ない関数の書き直し（7792）、表示なしの上書き（9456） | 新しく書いた本体 |
| 書き直すとき | external → public、状態変更可能性を狭める、引数の名前 | 戻り値の型（4822）、可視性（9098）、状態変更可能性を広げる（6959） | 新しく書いた本体 |

### 試すときの注意

- `override`なしで名前を打ち間違えると、エラーなしで新しい関数ができる。書き直そうとする関数に`override`を書いておけば、名前の打ち間違いをビルドが捕まえる。
- `override`は本体を見ない。書き直した本体が正しいかは、テストで確かめる。
- 状態変更可能性は、nonpayable → view → pureの方向にだけ狭められ、`payable`はほかのものに変えられない。
- 公式ドキュメントは、modifierのオーバーライドをdeprecatedと書いている。solc 0.8.30のビルドでは警告は出ない。
- `cases/`のファイルは、一つずつ`forge build --offline --force cases/<名前>.sol`でビルドする。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| `virtual`/`override`の導入 | 0.6.0（2019-12-17）。public変数がexternal関数を書き直す規則、`private`と`virtual`を一緒に使えない規則も同じバージョン | 2026-10-19 |
| 状態変更可能性を狭める | 0.7.0（2020-07-28）から | 2026-10-19 |
| インターフェースの関数での`override`の省略 | 0.8.8（2021-09-27）から。同じ関数が複数の親にあるときは例外 | 2026-10-19 |
| modifierのオーバーライドの表示 | 公式ドキュメントはModifier Overridingの節をdeprecatedと表示。solc 0.8.30のビルドは警告なし | 2026-10-19 |
| bumpByのgasUsed（anvilの既定の設定、最初の呼び出し） | Counter 65,760、Child 65,760、ChildTypo 65,782、ChildZero 45,859 | 2026-10-19 |
| サイズ | Counter 819、Child 945（`cast code`）、Marketの第111講のバージョンのruntime 7,189 / initcode 7,763、MarketBase 268 / 296（第110講のバージョンと同じ） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 親が複数のときの`override(A, B)` | [第112講](../../part6/lecture112/) |
| 書き直した関数の中で親のバージョンを呼ぶ（`super`） | [第113講](../../part6/lecture113/) |
| インターフェースと`override`の省略の規則の全体 | [第115講](../../part6/lecture115/) |
| アセンブリの`memory-safe`のようなほかの表示 | [第121講](../../part7/lecture121/) |
| デプロイのあとで動作を変える構造（プロキシ） | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 継承したコントラクトで検査を変える場合 | [第167講](../../part11/lecture167/)、[第176講](../../part11/lecture176/) |
| `virtual`/`override`が入ったバージョンと、それ以前のコード | [第185講](../../part11/lecture185/) |
| 精読でvirtualの一覧を探す | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
