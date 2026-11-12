# 第110講 単一継承と関数のオーバーライド

第6部 言語の詳細 ③ コントラクト・第25章 継承

[← 第109講](../../part6/lecture109/) | [第6部 目次](../) | [第111講 →](../../part6/lecture111/)

## この講義の問い

`contract Child is Counter`の一行を書くと、デプロイされるのは何で、継承した関数・スロット・名前は子のアドレスでどう動くのか。

## 実習資料

### 準備

第109講の終わりのMarketのプロジェクトから始め、市場の状態の部分（enum `MarketStatus`、`status`、`StatusChanged`、`notFrozen`・`whenActive`）を親の`MarketBase`に切り出し、`contract Market is MarketBase`で継承する。継承のデモは別に作ったデモ用のプロジェクト（`demo`）で行い、ローカルのanvilにChildとCounterをデプロイして呼び出しとストレージを見る。エラー・比較の例は、`examples/`の下のファイルごとに`forge build --force <ファイル>`で別々にビルドする。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Inh.sol](code/demo/src/Inh.sol) | 親の`Counter`（public・privateの変数、`virtual`関数`step`、`step`を呼ぶ`bumpBy`）、子の`Child`（`step`をオーバーライド）、オーバーロードした`Overload` |
| [code/demo/src/Alone.sol](code/demo/src/Alone.sol) | Counterをimportだけして継承しないコントラクト |
| [code/demo/src/Body.sol](code/demo/src/Body.sol) | 本体の大きさが違う`Light`・`Heavy`と、それを書き直した`OverLight`・`OverHeavy` |
| [code/demo/examples/](code/demo/examples/) | エラー・比較の例。NoMark・NoVirtual・NoOverride（9456・4334）、ReturnType（4822）、OverloadMark（7792）、Ambiguous（4487）、PrivFn・PrivVar（7576）、SameVar・FnVsVar（9097）、SamePrivVar（通る、スロット二つ）、SameShadow（警告2519）、InheritedShadow（警告なし）、ParamShadow（二つを一つのファイルに） |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第110講のバージョン。`MarketBase`（市場の状態、二つのmodifier、`_setStatus`）と、それを継承した`Market` |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol)、[code/market/src/MockToken.sol](code/market/src/MockToken.sol) | インターフェースとテスト用のトークン |
| [code/market/test/Inherit.t.sol](code/market/test/Inherit.t.sol) | この講義で加えたテスト。継承した`status`がMarketのアドレスのスロット0にあるか |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト。`Market.MarketStatus`・`Market.StatusChanged`を`MarketBase.…`に変えた |

### 実行結果

二つのコントラクトのサイズ（`forge build --sizes`、二行だけ）。importだけしたAloneは216バイトである。

```
| Contract  | Runtime Size (B) | Initcode Size (B) | Runtime Margin (B) | Initcode Margin (B) |
| Child     | 945              | 978               | 23,631             | 48,174              |
| Counter   | 819              | 852               | 23,757             | 48,300              |
```

Childだけをデプロイし、Childのソースにない`bump()`を送る。ログを出したアドレスはChildのアドレスである（`forge create`、`cast send`、`cast receipt`）。

```
$ forge create --offline --broadcast --json --unlocked --from $A --rpc-url $R src/Inh.sol:Child
"deployedTo": "0x5FbDB2315678afecb367f032d93F642f64180aa3"
$ cast send --unlocked --from $A --rpc-url $R --json $C "bump()"
{"type":"0x2","status":"0x1", ...}
$ cast receipt <トランザクションハッシュ> logs --rpc-url $R
[{"address":"0x5fbdb2315678afecb367f032d93f642f64180aa3",
  "topics":["0x5311a32e1bc07c65f9f3c57e845d29af6c46065a94add70de6af009b370c3389"], ...}]
$ cast call $C "count()(uint256)" --rpc-url $R
1
```

Childの関数セレクタには、継承した関数とゲッターが一緒にある（`forge inspect Child methodIdentifiers`、矢印は説明用）。

```
| bump()       | 68110b2f |   ← Counter
| bumpBy()     | cf29c8f9 |   ← Counter
| count()      | 06661abd |   ← Counterのpublic変数のゲッター
| extra()      | 190024e0 |
| lastCaller() | 2113522a |   ← Counterのpublic変数のゲッター
| step()       | e25fe175 |   ← Childが書き直した
| useShared()  | cd710a30 |
```

`cast code $C`は945バイトで`--sizes`のChildのランタイムのサイズと同じで、バイトの中にCounter・Childという名前はない。

Childの保存の欄（`forge inspect Child storageLayout`）。親の三つの変数が0〜2番、子の`extra`が3番である。

```
| Name       | Type    | Slot | Offset | Bytes | Contract          |
| count      | uint256 | 0    | 0      | 32    | src/Inh.sol:Child |
| secret     | uint256 | 1    | 0      | 32    | src/Inh.sol:Child |
| lastCaller | address | 2    | 0      | 20    | src/Inh.sol:Child |
| extra      | uint256 | 3    | 0      | 32    | src/Inh.sol:Child |
```

子から親のprivateの関数・変数を呼ぶとビルドが止めるが（`examples/PrivFn.sol`、`examples/PrivVar.sol`のどちらも`Error (7576): Undeclared identifier.`）、private変数`secret`の値はChildのアドレスにあって誰でも読める（`cast storage`）。

```
$ cast storage $C 1 --rpc-url $R
0x000000000000000000000000000000000000000000000000000000000000002a
```

親と同じ名前のprivate変数を子でもう一度宣言すると、ビルドが通って欄が二つできる（`forge inspect examples/SamePrivVar.sol:C storageLayout`）。

```
| count | uint256 | 0    | 0      | 32    | examples/SamePrivVar.sol:C |
| count | uint256 | 1    | 0      | 32    | examples/SamePrivVar.sol:C |
```

アカウント1番がChildに`bumpBy()`を送ると、Counterのソースに書かれた`lastCaller = msg.sender`がアカウント1番を書く。`step()`はChildが書き直した10が動く。

```
$ cast send --unlocked --from $B --rpc-url $R --json $C "bumpBy()"
{"type":"0x2","status":"0x1", ...}
$ cast call $C "lastCaller()(address)" --rpc-url $R
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast call $C "count()(uint256)" --rpc-url $R
11
```

| アドレス | アカウント1番のbumpBy()の前 → 後のcount | そのアドレスのstep() |
|---|---|---|
| Counter 0xe7f1…0512 | 0 → 1 | 1 |
| Child 0x5FbD…0aa3 | 1 → 11 | 10 |

オーバーライドの表示と名前の重なりのエラー（`forge build --force <ファイル>`）。

```
NoMark.sol        Error (9456): Overriding function is missing "override" specifier.
                  Error (4334): Trying to override non-virtual function. Did you forget to add "virtual"?
NoVirtual.sol     Error (4334): Trying to override non-virtual function. Did you forget to add "virtual"?
NoOverride.sol    Error (9456): Overriding function is missing "override" specifier.
ReturnType.sol    Error (4822): Overriding function return types differ.
OverloadMark.sol  Error (7792): Function has override specified but does not override anything.
Ambiguous.sol     Error (4487): No unique declaration found after argument-dependent lookup.
SameVar.sol       Error (9097): Identifier already declared.
                  Error (9456): Overriding public state variable is missing "override" specifier.
                  Error (1452): Cannot override public state variable.
FnVsVar.sol       Error (9097): Identifier already declared.
                  Error (9456): Overriding function is missing "override" specifier.
                  Error (1452): Cannot override public state variable.
```

覆われた親の本体のサイズ（`forge build --sizes`）。誰も呼ばない覆われた本体は、デプロイされるものに入らない。

| コントラクト | f()の本体 | ランタイムのサイズ |
|---|---|---|
| Light | `return 1;` | 175 B |
| Heavy | ループ十回、keccak256、長い文字列 | 637 B |
| OverLight is Light | `return 2;`に書き直す | 175 B |
| OverHeavy is Heavy | `return 2;`に書き直す | 175 B |

オーバーライドはセレクタ一つのままで、オーバーロードはセレクタが一つ増える（`forge inspect Overload methodIdentifiers`）。

```
| step()       | e25fe175 |
| step(uint8)  | 04fbe299 |
```

関数の引数の名前が状態変数を隠すとき。一つのコントラクトの中なら警告が出て、継承した変数なら警告はない。

```
$ forge build --offline --force examples/SameShadow.sol
Warning (2519): This declaration shadows an existing declaration.
$ forge build --offline --force examples/InheritedShadow.sol
Compiler run successful!
```

Marketの第110講のバージョン。第109講のバージョンの`Market.MarketStatus`・`Market.StatusChanged`をそのままにすると、ビルドが止まる。継承したenumとイベントは、宣言したコントラクトの名前（`MarketBase.…`）で取り出す。

```
Error (7920): Identifier not found or not unique.
  --> src/Market.sol:34:17:
34 | error NotActive(Market.MarketStatus status); // ABIではNotActive(uint8)

Error (9582): Member "MarketStatus" not found or not visible after argument-dependent lookup in type(contract Market).
  --> test/Status.t.sol:27:26:
27 |         market.setStatus(Market.MarketStatus.Frozen);
```

```
$ forge test --offline
Ran 12 test suites: 42 tests passed, 0 failed, 0 skipped (42 total tests)
$ forge inspect --offline Market storageLayout
| status        | enum MarketBase.MarketStatus                            | 0    | 0      | 1     | src/Market.sol:Market |
| assets        | contract IERC20[]                                       | 1    | 0      | 32    | src/Market.sol:Market |
```

| | 第109講のバージョン | 第110講のバージョン |
|---|---|---|
| ランタイム / デプロイのコードのサイズ | 7,177 / 7,751 B | 7,189 / 7,763 B |
| テスト | 41個 | 42個 |
| `--sizes`の表のMarketBase | なし | 268 B（別にはデプロイしない） |

継承の構造の表。

| コントラクト | 受け持つこと | 継承するコントラクト | 状態変数（スロット） | デプロイ |
|---|---|---|---|---|
| MarketBase | 市場の状態、状態を見る二つのmodifier | なし | status(0) | 別にはデプロイしない、Marketに合わさる |
| Market | 管理者、資産の一覧、預け入れの帳簿、利息 | MarketBase | assets(1)、assetConfig(2)、positions(3)、totalDeposits(4)、totalBorrows(5) | デプロイする一つ |

線形化の順番はMarket、MarketBaseで、デプロイされるのはMarket一つ（runtime 7,189バイト）である。

### 試すときの注意

- オーバーライドには、親に`virtual`、子に`override`の両方が必要である。引数の型が違えばオーバーライドではなくオーバーロードで、そこに`override`を書くとError 7792になる。
- 継承した状態変数を関数の引数の名前で隠しても、コンパイラは警告しない。同じ形を一つのコントラクトの中に書くと、Warning 2519が出る。
- `forge build --sizes`の表に親（MarketBase）が別に見えても、デプロイするのは子一つである。
- MarketBaseの`notFrozen`・`whenActive`も、Marketの関数の中にコピーされる。modifierを親に移しても、つけた関数の数だけランタイムコードが増える。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンや実行環境が変わると、数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| `virtual`/`override`の必須化 | 0.6.0から | 2026-10-19 |
| デモ用のコントラクトのサイズ（runtime / initcode） | Counter 819 / 852、Child 945 / 978、Alone 216 / 242、Overload 991 / 1,024、Light 175 / 201、Heavy 637 / 665、OverLight 175 / 201、OverHeavy 175 / 201 | 2026-10-19 |
| Child・Counterの実測 | Child：アカウント0番のbump()のgasUsed 67,374（count 1）、アカウント1番のbumpBy()のgasUsed 31,560（count 11、lastCallerはアカウント1番）。Counter：アカウント1番のbumpBy()のgasUsed 65,760（count 1）。Childのスロット0 0x…0b、1 0x…2a、2 アカウント1番のアドレス、3 0。`cast code` Child 945・Counter 819バイト | 2026-10-19 |
| Marketの二つのバージョン（第109講のバージョン / 第110講のバージョン） | runtime / creation 7,177 / 7,751、7,189 / 7,763。MarketBase 268 / 296。デプロイのgasUsed 1,607,168 / 1,609,772、addAsset 75 93,730 / 93,730、deposit 100 130,240 / 130,240、withdraw 30 59,692 / 59,692、setStatus 1 45,732 / 45,761、setStatus 0 23,820 / 23,849、失敗deposit 0 26,759 / 26,759。テスト41 / 42 | 2026-10-19 |
| Marketの実測の条件 | バージョンごとに新しいanvil、ブロックの間隔1秒（`cast rpc anvil_setBlockTimestampInterval 1`）、アカウント0番、MockTokenをデプロイしたあとMarketのコンストラクタの引数はアカウント0番・5e16・80、順番：デプロイ → addAsset 75 → deposit 100 → withdraw 30 → setStatus 1 → setStatus 0 → 失敗deposit 0（`--gas-limit 100000`） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `virtual`/`override`の規則の詳細（可視性、状態変更可能性、public変数） | [第111講](../../part6/lecture111/) |
| 親が複数のとき、C3線形化、スロットの順番 | [第112講](../../part6/lecture112/) |
| 覆われた親の本体を呼ぶ（`super`） | [第113講](../../part6/lecture113/) |
| 継承するときのコンストラクタの引数 | [第114講](../../part6/lecture114/) |
| 抽象コントラクトとインターフェース | [第115講](../../part6/lecture115/) |
| ライブラリで分ける（[第35講](../../part3/lecture35/)の文の後半） | [第116講](../../part6/lecture116/)、[第117講](../../part6/lecture117/)、[第118講](../../part6/lecture118/) |
| スロット番号の規則の全体 | [第135講](../../part8/lecture135/) |
| ABIエンコードとセレクタの規則の全体 | [第141講](../../part8/lecture141/) |
| 標準の実装を継承する判断 | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| 継承したコードまで読む精読の手順 | [第188講](../../part12/lecture188/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
