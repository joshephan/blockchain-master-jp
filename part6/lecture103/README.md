# 第103講 modifierの文法と実行の順番

第6部 言語の詳細 ③ コントラクト・第22章 modifier

[← 第102講](../../part6/lecture102/) | [第6部 目次](../) | [第104講 →](../../part6/lecture104/)

## この講義の問い

宣言の行にmodifierをいくつも書くと何がどんな順番で動き、引数はいつ計算され、本体が`return`したりリバートしたりすると`_;`のあとの行はどうなるのか。

## 実習資料

### 準備

通しプロジェクトのMarketのこの講義のバージョン（`market`）は、第102講のバージョンから検査の行を四つのmodifier（`onlyAdmin`、`notFrozen`、`whenActive`、`onlyListed(asset)`）に移し、市場の状態を変える`setStatus`を加えたバージョンである。`addAsset`には`onlyAdmin notFrozen`、`deposit`には`whenActive onlyListed(asset)`、`withdraw`には`notFrozen`をつけ、`withdrawAll`は中で呼ぶ`withdraw`の`notFrozen`を通る。`IMarket.sol`とセレクタのテストに`setStatus`を加え、`test/Status.t.sol`を新しく入れた。`demo`は`forge init`で作った空のプロジェクトからCounterの例を消して始めた。どちらのプロジェクトにもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。ローカルのanvilでのデモは、既定のアカウント0番（デプロイ、Marketの管理者）と1番（公開されたテスト用の鍵）を`--unlocked --from`で使った。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | この講義のバージョンのMarket。四つのmodifierと`setStatus` |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | `setStatus(uint8)`を加えたインターフェース |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Status.t.sol](code/market/test/Status.t.sol) | `setStatus`の権限、`addAsset`のmodifierの順番、預け入れの停止、凍結した市場の`withdrawAll`、登録されていない資産の預け入れ |
| [code/market/test/Selectors.t.sol](code/market/test/Selectors.t.sol) | `setStatus`のセレクタを加えたセレクタのテスト |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol)、[Getters.t.sol](code/market/test/Getters.t.sol)、[Receive.t.sol](code/market/test/Receive.t.sol)、[WithdrawAll.t.sol](code/market/test/WithdrawAll.t.sol) | 前の講義で加えたテスト |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Mod.sol](code/demo/src/Mod.sol) | 複数のmodifierの順番と引数の計算のタイミング（Order）、`_;`の回数（Count）、本体の`return`のあとの`_;`の次の行（After）、内部呼び出しと引数を受け取るmodifier（Inner） |
| [code/demo/test/Mod.t.sol](code/demo/test/Mod.t.sol) | 四つのコントラクトのテスト |
| [code/demo/bad/NoPlaceholder.sol](code/demo/bad/NoPlaceholder.sol) | `_;`のないmodifier（Error 2883） |
| [code/demo/bad/CallMod.sol](code/demo/bad/CallMod.sol) | 本体でmodifierを関数のように呼ぶ（Error 5704） |
| [code/demo/bad/ModRetVal.sol](code/demo/bad/ModRetVal.sol) | modifierの中の`return 3;`（Error 7552） |
| [code/demo/bad/ModReads.sol](code/demo/bad/ModReads.sol) | modifierの中で関数の引数を直接読む（Error 7576） |
| [code/demo/bad/ModRet.sol](code/demo/bad/ModRet.sol) | `_;`の前で`return;`するmodifier（Warning 5740） |
| [code/demo/bad/ViewWrite.sol](code/demo/bad/ViewWrite.sol) | 状態を書くmodifierをview関数につける（Error 8961） |
| [code/demo/bad/AfterEarly.sol](code/demo/bad/AfterEarly.sol) | Afterから`fail`を抜いたバージョン（警告なし） |

`bad/`のファイルは`forge build --offline --force bad/<ファイル>.sol`で一つずつビルドする。

### 実行結果

ビルドが止めるmodifier。

| ファイル | 形 | 結果 |
|---|---|---|
| NoPlaceholder | `_;`のないmodifier | Error (2883) `Modifier body does not contain '_'.` |
| CallMod | 関数の本体で`m();` | Error (5704) `This expression is not callable.` |
| ModRetVal | modifierの中の`return 3;` | Error (7552) `Return arguments not allowed.` |
| ModReads | modifierの中で関数の引数`v`を直接読む | Error (7576) `Undeclared identifier.` |

```
Error (7576): Undeclared identifier.
 --> bad/ModReads.sol:5:28:
  |
5 |     modifier m() { require(v > 0); _; }
  |                            ^
```

`forge inspect src/Mod.sol:Count abi --offline`。modifierはABIにない。

```
| function | count() view returns (uint256)           | 0x06661abd |
| function | maybe(bool) nonpayable returns (uint256) | 0xe13e4d4f |
| function | three() nonpayable                       | 0x45caa117 |
| function | two() nonpayable                         | 0x5fdf05d7 |
```

`demo`をビルドすると、Afterの`fail`で`_;`のあとの行に届かないという警告が出る（`fail`を抜いたAfterEarlyは警告なし）。

```
Warning (5740): Unreachable code.
  --> src/Mod.sol:59:9:
   |
59 |         post += 1;
   |         ^^^^^^^^^
```

状態を書くmodifierをview関数につけると、次のようになる。

```
Error (8961): Function cannot be declared as view because this expression (potentially) modifies the state.
 --> bad/ViewWrite.sol:7:34:
  |
7 |     function get() external view counted returns (uint256) { return 1; }
  |                                  ^^^^^^^
```

`forge test --offline -vvvv`の`run()`のトレース。modifierの引数はそのmodifierの番に計算され、前半は左のmodifierから、`_;`のあとは右のmodifierから動く。

```
[59944] Order::run()
  ├─ emit Step(where: "arg of a", value: 1)
  ├─ emit Step(where: "a before", value: 1)
  ├─ emit Step(where: "arg of b", value: 2)
  ├─ emit Step(where: "b before", value: 2)
  ├─ emit Step(where: "body", value: 2)
  ├─ emit Step(where: "b after", value: 2)
  ├─ emit Step(where: "a after", value: 1)
  └─ ← [Stop]
```

`_;`が二回あれば本体が二回、ループの中にあれば三回動く（Countの`two()`のあと2、`three()`のあと5）。ローカルのチェーンで、`maybe(true)`のあと1だった`count`が`two()`のあと3になる。

```
├─ [43949] Count::two()
├─ [2402] Count::count() [staticcall]
│   └─ ← [Return] 2
├─ [27443] Count::three()
├─ [2402] Count::count() [staticcall]
│   └─ ← [Return] 5
```

```
1
gasUsed              26849
status               1 (success)
3
```

`onlyIf(false)`のように`_;`を飛ばすと、`maybe(false)`はリバートせずに0を返す。ローカルのチェーンで送ったトランザクションもstatus 1、logs `[]`で、`count`はそのままである。

modifierの中の`return;`は、そのあとの本体に届かない（`bad/ModRet.sol`）。

```
Warning (5740): Unreachable code.
 --> bad/ModRet.sol:7:32:
  |
7 |     function f() external stop { x = 1; }
  |                                ^^^^^^^^^^
```

内部呼び出しにもmodifierが動く。Innerの`outer(3)`は6を返して`checks`は2、`outer(0)`はリバートする。

```
├─ [44834] Inner::outer(3)
│   └─ ← [Return] 6
├─ [2402] Inner::checks() [staticcall]
│   └─ ← [Return] 2
├─ [27542] Inner::outer(0)
│   └─ ← [Revert] zero value
```

ローカルのチェーンのMarketを`setStatus(2)`で凍結したあとに呼んだ結果。管理者でないアカウントの`addAsset`は`onlyAdmin`が先なので理由は`not admin`、管理者の`addAsset`と`withdrawAll`は`frozen`である。enumの範囲外の値3は、理由なしでリバートする。

```
gasUsed              43828
status               1 (success)
2
Error: ... execution reverted: not admin
Error: ... execution reverted: frozen
Error: ... execution reverted: frozen
Error: ... execution reverted: not admin
Error: ... execution reverted, data: "0x"
```

`market`で`forge build --offline --sizes`（Marketの行）、`forge test --offline`、`cast sig "setStatus(uint8)"`。

```
| Contract  | Runtime Size (B) | Initcode Size (B) |
| Market    | 8,002            | 8,705             |
```

```
Ran 6 test suites ...: 16 tests passed, 0 failed, 0 skipped (16 total tests)
0x2e49d78b
```

### 試すときの注意

- modifierは、つけた関数ごとにコードがコピーされる。Marketのランタイムコードは、第102講のバージョンの7,145バイトから8,002バイトに増えた。
- 宣言の行にmodifierが二つ以上あると、書いた順に検査する。リバートの理由は、先に引っかかったmodifierのものである。
- modifierの中では、関数の引数を名前で読めない。必要なら`onlyListed(asset)`のように引数として渡す。
- 本体で`return`しても、`_;`のあとの行は動く。`_;`を飛ばすmodifierは、リバートせずに既定値を返す。
- `status()`はABIでは`uint8`である。そのため`cast send … "setStatus(uint8)" 2`で呼び、IMarketには`setStatus(uint8)`と書く。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、サイズとガスが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節 Function Modifiers。引数を計算するタイミングを書いた文はない | 2026-10-19 |
| `_`がないときのエラー、`return`のあとの`_`のあとの行 | 0.4.0のbreaking change: "Modifiers are required to contain ``_``"、"Modifiers: return does not skip part in modifier after ``_``." | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 第48講のサイズ | Ballot 4,059 / Ballot3Mod 4,656 / Ballot3Inline 4,656 B、一か所あたり142 B | 2026-10-19 |
| Marketのサイズ | 第102講のバージョンのruntime 7,145 / creation 7,841 B、第103講のバージョンのruntime 8,002 / creation 8,705 B | 2026-10-19 |
| デモ用のコントラクトのサイズ | Order 1,969 / Count 627 / After 783 / Inner 825 B（テストでのデプロイが返したコード） | 2026-10-19 |
| forge testのガス | Order.run 59,944、runSwapped 59,922、Count.two 43,949、three 27,443、maybe(false) 21,852、maybe(true) 27,082、After.early(true) 44,144、early(false) 49,333、fail 26,747、Inner.outer(3) 44,834、outer(0) 27,542 | 2026-10-19 |
| anvilのgasUsed（Count） | maybe(false) 21,852（status 1、logs []、count 0のまま）、maybe(true) 44,182（count 1）、two() 26,849（count 3） | 2026-10-19 |
| anvilのgasUsed（Market） | addAsset 91,963、deposit 100 128,284、setStatus 2 43,828 | 2026-10-19 |
| ローカルのanvilのアドレス | 一つ目のCount `0x5FbDB2315678afecb367f032d93F642f64180aa3`、二つ目のCount `0x610178dA211FEF7D417bC0e6FeD39F05609AD788`、MockToken `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、Market `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707`、二つ目のMockToken `0x8A791620dd6260079BF849Dc5567aDC3F2FdC318` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| modifierの誤った使い方（名前と中身の食い違い、状態を変えるmodifier、リバートせずに飛ばすmodifier）と代わりの手 | [第104講](../../part6/lecture104/) |
| modifierのオーバーライド（`virtual`、`override`）と継承 | [第104講](../../part6/lecture104/)、[第110講](../../part6/lecture110/)、[第111講](../../part6/lecture111/)、[第112講](../../part6/lecture112/)、[第113講](../../part6/lecture113/) |
| イベント・カスタムエラーの文法 | [第105講](../../part6/lecture105/)、[第106講](../../part6/lecture106/)、[第107講](../../part6/lecture107/)、[第108講](../../part6/lecture108/)、[第109講](../../part6/lecture109/) |
| modifierの本体の中のアセンブリブロック | [第123講](../../part7/lecture123/) |
| ランタイムコードのサイズとガス最適化の優先順位 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| `_;`のあとの行を使うよく知られたパターン | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
