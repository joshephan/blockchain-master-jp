# 第115講 抽象コントラクトとインターフェース

第6部 言語の詳細 ③ コントラクト・第25章 継承

[← 第114講](../../part6/lecture114/) | [第6部 目次](../) | [第116講 →](../../part6/lecture116/)

## この講義の問い

本体のない関数を置いた`abstract`コントラクトと`interface`は、それぞれ何を止め、MarketがIMarketを継承するとビルドは何を確かめ、何は相変わらず誰も確かめないのか。

## 実習資料

### 準備

第114講の終わりのMarketのプロジェクトから始め、MarketがIMarketを継承するようにする（`abstract contract MarketBase is IMarket`）。二つのファイルが一緒に使う型は新しいファイル`src/MarketTypes.sol`に切り出し、enum `MarketStatus`・四つのイベント・十二個のエラーはIMarketの一か所にだけ置く。abstractとinterfaceの規則は、`errors/`の下のフォルダごとに別々にビルドして見る。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/errors/](code/errors/) | abstract：nobody_concrete（3656）、nobody_novirtual（5424）、child_noimpl（3656）、abstract_new（4614）、super_unimpl（9582）、abstract_ok・abstract_unused（通る）。interface：if_statevar（8274）、if_ctor（6482・5700）、if_body（4726）、if_public（1560）、if_modifier（6408）、if_inherit_contract（6536）、if_new（2971）、if_ok・iface_impl（通る） |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | この講義で作ったファイル。Amount・Rate・Ratio、IERC20、Position、AssetConfig |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | enum MarketStatus、四つのイベント、十二個のエラー、19個の関数を一か所に置いたインターフェース |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第115講のバージョン。abstractのMarketBase is IMarket、abstractのAssetRegistry・Ledger、デプロイするMarket |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Inherit.t.sol](code/market/test/Inherit.t.sol) | `test_marketIsIMarket`を追加。Marketを変換なしでIMarketの変数に入れて呼ぶ |
| [code/market/test/Selectors.t.sol](code/market/test/Selectors.t.sol) | 形の照合はビルドがするので、手で書いたシグネチャと照合するように変えた |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト。イベント・エラーを`IMarket.…`で取り出すように直した |
| [code/wrap/test/Wrap.t.sol](code/wrap/test/Wrap.t.sol) | Marketのプロジェクトの`test/`に入れて走らせたテストファイル。`IMarket im = market;`と、MockTokenのアドレスにIMarketをかぶせた呼び出し |

### 実行結果

本体のない関数とabstract（`forge build`、`errors/`）。

```
contract A { function f() public virtual returns (uint256); }
Error (3656): Contract "A" should be marked as abstract.
Note: Missing implementation:

abstract contract A { function f() public returns (uint256); }
Error (5424): Functions without implementation must be marked virtual.

abstract contract A { function f() public virtual returns (uint256); }  contract C is A { }
Error (3656): Contract "C" should be marked as abstract.

abstract contract A { ... }  ...  new A()
Error (4614): Cannot instantiate an abstract contract.
```

abstractのコントラクトは状態変数、コンストラクタ、本体のある関数を持つことができ、本体のない関数が一つもなくてもつけられる（`errors/abstract_ok`、`errors/abstract_unused`は通る）。Marketのabstractの親にはbytecodeがない。

```
$ forge inspect --offline AssetRegistry bytecode
0x
$ forge create --offline src/Market.sol:AssetRegistry --rpc-url $R --unlocked --from $A --broadcast
Error: no bytecode found in bin object for AssetRegistry
```

インターフェースが止めるもの（ソース一つに一種類ずつ）。

| 入れてみたもの | エラー |
|---|---|
| 状態変数`uint256 x;` | 8274 Variables cannot be declared in interfaces. |
| コンストラクタ`constructor();` | 6482 Constructor cannot be defined in interfaces. / 5700 Constructor must be implemented if declared. |
| 本体`{ return 1; }` | 4726 Functions in interfaces cannot have an implementation. |
| `function f() public;` | 1560 Functions in interfaces must be declared external. |
| `modifier m() { _; }` | 6408 Modifiers cannot be defined or declared in interfaces. |
| `interface I is A`（Aはコントラクト） | 6536 Interfaces can only inherit from other interfaces. |
| `new I()` | 2971 Cannot instantiate an interface. |

インターフェースどうしの継承と、enum・struct・event・errorはできる（`errors/if_ok`は通る）。

| | abstractのコントラクト | インターフェース |
|---|---|---|
| 状態変数・コンストラクタ・modifier | できる | できない |
| 本体のある関数 | できる | できない |
| 関数の可視性 | 制限なし | externalのみ |
| 継承できるもの | コントラクト・インターフェース | インターフェースのみ |
| デプロイ | できない | できない |

第114講のバージョンのIMarket.solがMarket.solの型を取り込んだまま`abstract contract MarketBase is IMarket`に変えると、二つのファイルが互いを取り込んでいるので止まる。

```
Error (2449): Definition of base has to precede definition of derived contract
  --> src/Market.sol:50:33:
   |
50 | abstract contract MarketBase is IMarket {
   |                                 ^^^^^^^
```

型をMarketTypes.solに切り出してビルドし直すと、エラーが五系統出る（一部の行）。

```
Error (4822): Overriding public state variable return types differ.
  --> src/Market.sol:30:5:
30 |     MarketStatus public status;
Note: Overridden public state variable is here:
  --> src/IMarket.sol:42:5:
42 |     function status() external view returns (uint8); // enum MarketStatusはABIではuint8

Error (9914): Function overload clash during conversion to external types for arguments.
  --> src/IMarket.sol:33:5:
33 |     function setStatus(uint8 s) external;

Error (5883): Event with same name and parameter types defined twice.
  --> src/Market.sol:92:5:
92 |     event AssetAdded(address indexed asset, Ratio ratio);

Error (3656): Contract "Market" should be marked as abstract.
Note: Missing implementation:
  --> src/IMarket.sol:33:5:

Error (9553): Invalid type for argument in function call. Invalid implicit conversion from enum MarketBase.MarketStatus to uint8 requested.
  --> src/Market.sol:58:61:
58 |         if (status != MarketStatus.Active) revert NotActive(status); // 第108講
```

enumをIMarketの中に移し、イベント・エラーをIMarketにだけ置くとビルドが通り、セレクタとtopic0はそのままである（`forge inspect`、`cast keccak`、該当する行だけ）。

```
$ forge inspect --offline Market errors
| NotActive(IMarket.MarketStatus)      | 1d61e8ee |
$ forge inspect --offline Market events
| StatusChanged(IMarket.MarketStatus,IMarket.MarketStatus) | 0xe1377aa21d49fa10bb9ece6a0cd4f75597a90a80c3750f7f7674967f49ab9a62 |
$ forge inspect --offline Market methodIdentifiers
| setStatus(uint8)                     | 2e49d78b   |
| status()                             | 200d2ed2   |
$ cast keccak "StatusChanged(uint8,uint8)"
0xe1377aa21d49fa10bb9ece6a0cd4f75597a90a80c3750f7f7674967f49ab9a62
```

デプロイされるコードは、メタデータを除けばそのままである。同じanvilに同じコンストラクタの引数で二つのバージョンをデプロイして比べた。デプロイのgasUsedの差12は、メタデータハッシュの中の0のバイトが一つ減った分のcalldataの料金である。

| | 第114講のバージョンのMarket | 第115講のバージョンのMarket |
|---|---|---|
| ランタイムコード | 7,233 B | 7,233 B |
| initcode | 7,811 B | 7,811 B |
| デプロイのgasUsed | 1,619,356 | 1,619,344 |

`cast code`で受け取った二つのランタイムコードは、違うバイト32個がすべて最後の53バイト（メタデータとその長さの表示）の中にあり、それ以外は同じである。第115講のバージョンの`--sizes`の表にはMarketだけが残り、MarketBase・IMarketのbytecodeは0xである。

```
$ forge build --offline --sizes     # 第115講のバージョン
| Market     | 7,233            | 7,811             | 17,343             | 41,341              |
$ forge inspect --offline MarketBase bytecode
0x
$ forge inspect --offline IMarket bytecode
0x
```

継承したインターフェースが確かめるものと確かめないもの。第115講のバージョンでは`IMarket im = market;`が通り、第114講のバージョンに同じ行を入れるとビルドが止まる。

```
$ forge test --offline --match-contract InheritTest
[PASS] test_marketIsIMarket() (gas: 156669)
Ran 1 test suite: 5 tests passed, 0 failed, 0 skipped (5 total tests)

Error (9574): Type contract Market is not implicitly convertible to expected type contract IMarket.
  --> test/Wrap.t.sol:19:9:
19 |         IMarket im = market;
```

MockTokenのアドレスにIMarketをかぶせた呼び出しは、ビルドが通って実行でリバートする（`forge test -vvvv`、setUpのトレースは省略）。

```
$ forge test --offline --match-contract WrapTest -vvvv
[FAIL: EvmError: Revert] test_wrongAddress() (gas: 5254)
  [5254] WrapTest::test_wrongAddress()
    ├─ [189] MockToken::status() [staticcall]
    │   └─ ← [Revert] unrecognized function selector 0x200d2ed2 for contract 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, which has no fallback function.
    └─ ← [Revert] EvmError: Revert
```

`forge test`は46個が通る。継承の構造の表の最終版。

| コントラクト / ファイル / 種類 | 受け持つこと / 継承するもの | 状態変数（スロット） / コンストラクタの引数 | virtual | 外の関数 |
|---|---|---|---|---|
| IMarket / IMarket.sol / interface | enum MarketStatus、四つのイベント、十二個のエラー、19個の関数の形 / なし | なし / なし | 関数すべて（本体なし） | 19個の形 |
| MarketBase / Market.sol / abstract | 市場の状態、管理者 / IMarket | status(0) / admin_ | `_checkDeposit`（空の本体） | setStatus、status・adminのゲッター |
| AssetRegistry / Market.sol / abstract | 上場資産の一覧 / MarketBase | assets(1)、assetConfig(2) / cap | `_checkDeposit` virtual override | addAsset、assetCount、collateralRatio・assets・assetConfigのゲッター |
| Ledger / Market.sol / abstract | 預け入れの帳簿、預け入れ、引き出し / MarketBase | positions(3)、totalDeposits(4)、totalBorrows(5) / なし | `_checkDeposit` virtual override | deposit、withdraw、withdrawAll、elapsedOf、ゲッター三つ |
| Market / Market.sol / デプロイ | 利息、担保の数、三つの親をまとめる / AssetRegistry、Ledger | なし（interestRateはimmutable） / admin_、interestRate_、collateralRatio_ → MarketBase(admin_) AssetRegistry(collateralRatio_) | `_checkDeposit` override(AssetRegistry, Ledger)、virtualなし | interestFor、collateralCount、interestRate・SECONDS_PER_YEARのゲッター |

線形化はMarket、Ledger、AssetRegistry、MarketBase、IMarketで、superの順番（`_checkDeposit`）はMarket → Ledger → AssetRegistry → MarketBase、コンストラクタの順番はMarketBase → AssetRegistry → Ledger → Marketである。

### 試すときの注意

- 互いを取り込む二つのファイルでは、一方がもう一方を継承できない（2449）。一緒に使う型を三つ目のファイルに切り出す。
- enumはABIでは`uint8`である。インターフェースに`uint8`と書き、実装の側にenumと書くと、戻り値の型（4822）と引数の変換（9914）のエラーが出る。enumをインターフェースの中に置けば、セレクタを変えずに合わせられる。
- インターフェースの関数を実装する関数とpublic状態変数には、`override`を書かなくてよい（0.8.8から）。IMarketの`status()`・`admin()`のような位置は、public状態変数のゲッターが埋める。
- インターフェースを継承すれば、形の照合はビルドがする。しかし、あるアドレスにインターフェースをかぶせて呼ぶとき、そのアドレスが本当にそのコントラクトかは、相変わらず確かめられない。
- 新しいファイル（MarketTypes.sol）にも`pragma solidity 0.8.30;`を書く。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | 2026-10-19 |
| `abstract`キーワードの必須化 | 0.6.0（2019-12-17）から | 2026-10-19 |
| インターフェースの関数での`override`の省略 | 0.8.8（2021-09-27）から | 2026-10-19 |
| サイズ | 第114講のバージョンのMarketのruntime 7,233 / initcode 7,811、MarketBase 883 / 1,259。第115講のバージョンのMarket 7,233 / 7,811、MarketBase・AssetRegistry・Ledger・IMarketのbytecodeは0x | 2026-10-19 |
| デプロイのgasUsed | 第114講のバージョンのMarket 1,619,356、第115講のバージョンのMarket 1,619,344（コンストラクタの引数はアカウント0番・5e16・80。差はメタデータハッシュの0のバイトの数によるcalldataの料金） | 2026-10-19 |
| ランタイムコードの比較 | 二つのバージョンとも7,233バイト、違うバイト32個（オフセット7190〜7221）、最後の53バイト（CBORのメタデータ51バイト + 長さ2バイト）を除けば同じ | 2026-10-19 |
| セレクタ・topic0 | setStatus(uint8) 2e49d78b、status() 200d2ed2、NotActive 1d61e8ee、StatusChangedのtopic0 0xe1377aa2…9a62（二つのバージョンで同じ）、methodIdentifiers 19行 | 2026-10-19 |
| テスト | 第115講のバージョンは46個が通る（InheritTest 5個） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ライブラリで分ける | [第116講](../../part6/lecture116/)、[第117講](../../part6/lecture117/)、[第118講](../../part6/lecture118/) |
| 関数の宣言の文法の規格で、本体のない形を探す | [第127講](../../part7/lecture127/) |
| スロット番号の規則の全体 | [第135講](../../part8/lecture135/) |
| 標準のインターフェース（ERC-20など）と実装 | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| インターフェースの対応を問い合わせる（ERC-165） | [第159講](../../part10/lecture159/) |
| かぶせて呼んだ相手の答えを信じるか | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| インターフェースを置いたアップグレードの構造 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
