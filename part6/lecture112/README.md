# 第112講 多重継承とC3線形化

第6部 言語の詳細 ③ コントラクト・第25章 継承

[← 第111講](../../part6/lecture111/) | [第6部 目次](../) | [第113講 →](../../part6/lecture113/)

## この講義の問い

親が複数あると、コンパイラはその関係をどんな順番で並べ、その順番がビルドの成否・同じ関数の選択・スロット番号をどう決めるのか。

## 実習資料

### 準備

第111講の終わりのMarketのプロジェクトから始め、上場資産の一覧を`AssetRegistry`に、預け入れの帳簿と引き出しを`Ledger`に切り出し、`contract Market is MarketBase, AssetRegistry, Ledger`で三つを継承する。線形化とスロットの順番は、別に作ったデモ用のプロジェクト（`demo`）の`Super.sol`・`Slots.sol`で見て、ビルドが止める場合は`errors/`の下のフォルダごとに別々にビルドする。線形化の順番は、`forge build --ast`の成果物（`out/<ファイル>/<コントラクト>.json`）の`ast`の中の`linearizedBaseContracts`（コントラクトidの一覧）を名前に置き換えて読む。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Super.sol](code/demo/src/Super.sol) | Base・A・Bと、`is A, B`のC、`is B, A`のDなどのひし形の継承 |
| [code/demo/src/Slots.sol](code/demo/src/Slots.sol) | `is`の順番だけが違うSAB（`is SA, SB`）とSBA（`is SB, SA`） |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/errors/](code/errors/) | ビルドの確認用のソース。wrongorder（5005）、selfbase（2449）、two_noov（6480）、two_ovone・two_ovplain（4327）、two_ovBA（通る）、diamond_ok（通る）、diamond_two・chain_lookup（6480）、twomod（6480）、twovar（9097・6480）、twoevent（5883）、twoerror（9097）、clash（1860） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第112講のバージョン。`MarketBase`、`AssetRegistry`、`Ledger is MarketBase`、`Market is MarketBase, AssetRegistry, Ledger` |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol)、[code/market/src/MockToken.sol](code/market/src/MockToken.sol) | インターフェースとテスト用のトークン |
| [code/market/test/Inherit.t.sol](code/market/test/Inherit.t.sol) | `test_slotOrder`を追加。親が三つでも、スロットが第109講のバージョンのスロットマップのままか |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト。親に移した関数・イベントを、宣言したコントラクトの名前かインスタンスで取り出すように直した |

### 実行結果

コンパイラが立てた順番（`forge build --ast`の`linearizedBaseContracts`、idを名前に置き換えた）。

| コントラクト | isのあと | linearizedBaseContracts |
|---|---|---|
| C | `is A, B` | C、B、A、Base |
| D | `is B, A` | D、A、B、Base |

自分自身が先頭で、`is`のあとの右の親ほど子に近く、親は常に自分の子より後ろに来る。この条件を満たせないと、ビルドが止まる（`errors/wrongorder`、`errors/selfbase`）。

```
Error (5005): Linearization of inheritance graph impossible
 --> src/X.sol:5:1:
  |
5 | contract C is A, Base { }
  | ^^^^^^^^^^^^^^^^^^^^^^^^^

Error (2449): Definition of base has to precede definition of derived contract
 --> src/X.sol:3:15:
  |
3 | contract A is A { }
  |               ^
```

互いに関係のないA・Bに同じ`f()`があるとき（`errors/two_noov`など）。

```
Error (6480): Derived contract must override function "f". Two or more base classes define function with same name and parameter types.
 --> src/X.sol:5:1:
Note: Definition in "A":
Note: Definition in "B":
```

| Cのfの宣言 | ビルドの結果 |
|---|---|
| 書き直さない | Error (6480) |
| `override(A)` | Error (4327): Function needs to specify overridden contract "B". |
| `override` | Error (4327): Function needs to specify overridden contracts "A" and "B". |
| `override(B, A)` | 通る（括弧の中の順番は関係ない） |

ひし形の構造。

| 構造 | ビルドの結果 |
|---|---|
| Baseにf、A・Bどちらも書き直さない、`C is A, B` | 通る |
| Aだけがfを書き直す、`C is A, B` | Error (6480)、Note: Definition in "Base"、Definition in "A" |
| Aがfを書き直す、`C is Base, A` | Error (6480)、Note: Definition in "Base"、Definition in "A" |

同じ名前の別のもの。

| AとBに一緒に置いたもの | ビルドの結果 |
|---|---|
| `modifier m() virtual` | Error (6480): Derived contract must override modifier "m". |
| `uint256 public x` | Error (9097): Identifier already declared. / Error (6480) |
| `event E(uint256 v)` | Error (5883): Event with same name and parameter types defined twice. |
| `error E(uint256 v)` | Error (9097): Identifier already declared. |

`is`のあとの二つの単語の順番だけが違う二つのバージョンのスロット（`forge inspect SAB storageLayout`、`forge inspect SBA storageLayout`）。スロットは、線形化の順番を逆にたどって確保される。

| スロット | SAB（`is SA, SB`） | SBA（`is SB, SA`） |
|---|---|---|
| 0 | base | base |
| 1 | a | b |
| 2 | b | a |
| 3 | top | top |

名前と引数の型が違うのにセレクタが同じ二つのシグネチャを二つの親に分けて置くと、ビルドが止める（`cast sig`、`errors/clash`）。

```
$ cast sig "burn(uint256)"
0x42966c68
$ cast sig "collate_propagate_storage(bytes16)"
0x42966c68
$ forge build --offline
Error (1860): Function signature hash collision for burn(uint256)
 --> src/X.sol:5:1:
  |
5 | contract C is A, B { }
  | ^^^^^^^^^^^^^^^^^^^^^^
```

Marketの第112講のバージョンの線形化の順番はMarket、Ledger、AssetRegistry、MarketBaseで、スロットは第109講のバージョンのスロットマップと番号が同じである。

| スロット | 変数 | 宣言したコントラクト |
|---|---|---|
| 0 | status | MarketBase |
| 1 | assets | AssetRegistry |
| 2 | assetConfig | AssetRegistry |
| 3 | positions | Ledger |
| 4 | totalDeposits | Ledger |
| 5 | totalBorrows | Ledger |

`is`の行だけを変えた四つのバージョン（ほかの行はそのまま）。

| Marketのisの行 | ビルド | スロット |
|---|---|---|
| `is Ledger, AssetRegistry, MarketBase` | Error (5005) | なし |
| `is Ledger, MarketBase, AssetRegistry` | Error (5005) | なし |
| `is MarketBase, Ledger, AssetRegistry` | 通る、runtime 7,173 | status 0、positions 1、totalDeposits 2、totalBorrows 3、assets 4、assetConfig 5 |
| `is AssetRegistry, Ledger` | 通る、runtime 7,174 | assets 0、assetConfig 1、status 2、positions 3、totalDeposits 4、totalBorrows 5 |

ビルドできる二つのバージョンは警告なしでビルドされ、スロット番号を直接読むテストだけが失敗する（`forge test`、失敗の行と最後の行だけ）。

```
$ forge test --offline      # is MarketBase, Ledger, AssetRegistry
[FAIL: assertion failed: 0 != 1] test_slotOrder() (gas: 237129)
Ran 12 test suites: 42 tests passed, 1 failed, 0 skipped (43 total tests)

$ forge test --offline      # is AssetRegistry, Ledger
[FAIL: assertion failed: 0 != 1] test_slotOrder() (gas: 237130)
[FAIL: assertion failed: 0 != 2] test_statusInSlotZero() (gas: 55233)
Ran 12 test suites: 41 tests passed, 2 failed, 0 skipped (43 total tests)
```

親に移した関数を`Market.withdraw.selector`のように取り出すと、ビルドが止まる。インスタンス（`m.withdraw.selector`）か、宣言したコントラクトの名前（`Ledger.withdraw.selector`、`AssetRegistry.AssetAdded`、`Ledger.Deposited`）で取り出す。

```
Error (9582): Member "withdraw" not found or not visible after argument-dependent lookup in type(contract Market).
  --> test/Selectors.t.sol:16:45:
   |
16 |         assertEq(IMarket.withdraw.selector, Market.withdraw.selector);
   |                                             ^^^^^^^^^^^^^^^
```

サイズ（`forge build --sizes`）。デプロイするコントラクトはMarket一つで、`forge test`は43個が通る。

| コントラクト | runtime (B) | initcode (B) |
|---|---|---|
| Marketの第111講のバージョン | 7,189 | 7,763 |
| Marketの第112講のバージョン | 7,173 | 7,740 |
| AssetRegistry | 885 | 913 |
| Ledger | 2,948 | 2,976 |
| MarketBase | 268 | 296 |

継承の構造の表。

| コントラクト | 受け持つこと | 継承するコントラクト | 状態変数（スロット） | 外の関数 / デプロイ |
|---|---|---|---|---|
| MarketBase | 市場の状態、状態を見る二つのmodifier | なし | status(0) | statusのゲッター / 別にはデプロイしない |
| AssetRegistry | 上場資産の一覧 | なし | assets(1)、assetConfig(2) | assetCount、ゲッター二つ / 別にはデプロイしない |
| Ledger | 預け入れの帳簿、引き出し | MarketBase | positions(3)、totalDeposits(4)、totalBorrows(5) | withdraw、withdrawAll、elapsedOf、ゲッター三つ / 別にはデプロイしない |
| Market | 管理者、預け入れ、利息、担保の数 | MarketBase、AssetRegistry、Ledger | スロットなし（immutableが三つだけ） | setStatus、addAsset、deposit、interestFor、collateralCount、ゲッター四つ / デプロイする一つ |

### 試すときの注意

- `is`のあとには、いちばん基本の親から書く。Pythonとは逆の順番である。
- `override(A, B)`は二つとも書かせるだけで、実行されるのは子が新しく書いた本体一つである。
- `is`のあとの順番を変えると、ビルドできてもスロット番号が変わる。スロット番号を直接読むテスト（`vm.load`）を置けば、この変化を捕まえられる。
- 継承した親どうしは一つのコントラクトにまとめてコンパイルされるので、セレクタの重なりはビルドが止める。別々にデプロイしたコントラクトどうしでは、止める場所がない。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンや実行環境が変わると、数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 線形化の順番のフィールド | `forge build --ast`の成果物`out/<ファイル>/<コントラクト>.json`の`ast`の中のContractDefinitionノードの`linearizedBaseContracts`（コントラクトidの一覧） | 2026-10-19 |
| サイズ（runtime / initcode） | Marketの第111講のバージョン7,189 / 7,763、第112講のバージョン7,173 / 7,740。AssetRegistry 885 / 913、Ledger 2,948 / 2,976、MarketBase 268 / 296。`is MarketBase, Ledger, AssetRegistry`のバージョン7,173 / 7,740、`is AssetRegistry, Ledger`のバージョン7,174 / 7,741 | 2026-10-19 |
| ガス（第111講のバージョン / 第112講のバージョン） | デプロイ1,609,772 / 1,606,559、addAsset 93,730 / 93,769、deposit 100 130,240 / 130,240、withdraw 30 59,692 / 59,692、setStatus 1 45,761 / 45,761、setStatus 0 23,849 / 23,849、失敗deposit 0 26,759 / 26,759 | 2026-10-19 |
| ガスの実測の条件 | バージョンごとに新しいanvil、ブロックの間隔1秒（`cast rpc anvil_setBlockTimestampInterval 1`）、アカウント0番がMockToken・Marketをデプロイ（コンストラクタの引数はアカウント0番・5e16・80）、順番はaddAsset 75 → deposit 100 → withdraw 30 → setStatus 1 → setStatus 0 → 失敗deposit 0（`--gas-limit 100000`） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 線形化の順番で親の関数を順に呼ぶ（`super`） | [第113講](../../part6/lecture113/) |
| 親のコンストラクタの順番とコンストラクタの引数 | [第114講](../../part6/lecture114/) |
| 本体のない親とインターフェース | [第115講](../../part6/lecture115/) |
| スロット番号の規則の全体と、デプロイ後の親の順番 | [第135講](../../part8/lecture135/) |
| 別々にデプロイしたコントラクトどうしのセレクタの重なり（プロキシ） | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 継承の構造を読む精読 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
