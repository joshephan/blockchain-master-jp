# 第116講 ライブラリの基礎とinternalのリンク

第6部 言語の詳細 ③ コントラクト・第26章 ライブラリとusing for

[← 第115講](../../part6/lecture115/) | [第6部 目次](../) | [第117講 →](../../part6/lecture117/)

## この講義の問い

`library`と書いたコードは何ができず、internal関数だけのライブラリを呼ぶと、そのコードはどこに入って、誰の`msg`とストレージで動くのか。

## 実習資料

### 準備

第115講の終わりのMarketのプロジェクトから始め、利息の計算とPositionを書き換える計算を、新しいファイル`src/MarketMath.sol`の二つのライブラリ（InterestMath、PositionLib）に切り出す。ライブラリのデモは別に作ったデモ用のプロジェクト（`demo`）で行い、ローカルのanvilにWho・Shelf・FeeLibをデプロイして呼び出しとストレージを見る。ライブラリが止めるものは、`errors/`の下のフォルダごとに別々にビルドする。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Percent.sol](code/demo/src/Percent.sol) | internal関数が一つのPercent、呼ばない関数を19個加えたPercentMany |
| [code/demo/src/Fee.sol](code/demo/src/Fee.sol) | 同じ計算をライブラリで（FeeLib）、コントラクトの中のinternal関数で（FeeInline）、親で（FeeInherit）、PercentManyで（FeeMany） |
| [code/demo/src/Who.sol](code/demo/src/Who.sol) | ライブラリ関数の中で`msg.sender`と`address(this)`をイベントで出すWhoLibとWho |
| [code/demo/src/Shelf.sol](code/demo/src/Shelf.sol) | `Box storage`を受け取って書き換えるBoxLib.put、`Box memory`で受け取るputCopy、それを呼ぶShelf |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/v2/src/Percent.sol](code/v2/src/Percent.sol) | Percent.partの本体だけを切り上げに変えたバージョン（Fee.solはdemoのものをそのまま使う） |
| [code/errors/](code/errors/) | libraryに入れてみたもの。lib_statevar・lib_statevar_public・lib_immutable（9957）、lib_ctor（7634）、lib_payable・lib_payable_int（7708）、lib_receive（4549）、lib_fallback（5982）、lib_inherit（9469）、lib_inherited（2571）、lib_new（1130）、lib_nobody（9231）、lib_virtual（7801）、lib_noname（7576）、lib_call_internal_from_outside（9582）。通るもの：lib_constant、lib_ok_types、lib_msgvalue、lib_this、lib_balance、lib_fnvalue、lib_selfdestruct（警告5159） |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | この講義で作ったファイル。InterestMath（interestFor、SECONDS_PER_YEAR）、PositionLib（credit、debit） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第116講のバージョン。Ledgerの`_credit`・`_debit`とMarketの`interestFor`がライブラリを呼ぶ |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol)、[code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol)、[code/market/src/MockToken.sol](code/market/src/MockToken.sol) | インターフェース、型、テスト用のトークン |
| [code/market/test/Library.t.sol](code/market/test/Library.t.sol) | この講義で加えたテスト。ライブラリの計算がMarketと同じ答えか、PositionLibがMarketのストレージを書き換えるか |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト |

### 実行結果

libraryに入れてみたもの（ソース一つに一種類ずつ、`forge build --force`）。

| 入れてみたもの | エラー | 原文 |
|---|---|---|
| 状態変数（public、immutableも） | 9957 | Library cannot have non-constant state variables |
| コンストラクタ | 7634 | Constructor cannot be defined in libraries. |
| payable関数（public、internal） | 7708 | Library functions cannot be payable. |
| receive | 4549 | Libraries cannot have receive ether functions. |
| fallback | 5982 | Libraries cannot have fallback functions. |
| `library L is B` | 9469 | Library is not allowed to inherit. |
| `contract C is L` | 2571 | Libraries cannot be inherited from. |
| `new L()` | 1130 | Invalid use of a library name. |
| 本体のない関数 | 9231 | Library functions must be implemented if declared. |
| virtual関数 | 7801 | Library functions cannot be "virtual". |

constantの状態変数、struct・enum・event・error・modifier、internal関数の中の`msg.value`・`address(this)`・`address(this).balance`はビルドできる。internal関数の中の`selfdestruct`は警告5159が出るだけで、ビルドできる。

同じ計算をライブラリで、コントラクトの中のinternal関数で、親で書いたバージョンのサイズ（`forge build --sizes`、余白の欄は省略）。PercentはABIが空なので表に出ない。

```
| Contract   | Runtime Size (B) | Initcode Size (B) |
| FeeInherit | 540              | 568               |
| FeeInline  | 540              | 568               |
| FeeLib     | 540              | 568               |
| FeeMany    | 540              | 568               |
```

成果物のdeployedBytecodeから最後の53バイト（メタデータ51 + 長さ2）を外してsha256を比べると、四つが同じである（先頭8桁）。

```
FeeLib: 540バイト、末尾2バイト 0x0033 = 51、メタデータを除いた487バイトのsha256 b3116b88、linkReferences {}
FeeInline: 540バイト、末尾2バイト 0x0033 = 51、メタデータを除いた487バイトのsha256 b3116b88、linkReferences {}
FeeInherit: 540バイト、末尾2バイト 0x0033 = 51、メタデータを除いた487バイトのsha256 b3116b88、linkReferences {}
FeeMany: 540バイト、末尾2バイト 0x0033 = 51、メタデータを除いた487バイトのsha256 b3116b88、linkReferences {}
Percent: 85バイト、末尾2バイト 0x0033 = 51、メタデータを除いた32バイトのsha256 53b5c08f、linkReferences {}
PercentMany: 85バイト、末尾2バイト 0x0033 = 51、メタデータを除いた32バイトのsha256 53b5c08f、linkReferences {}
```

Percent自身の成果物85バイトには、`part`関数のコードがない（`forge inspect`、`cast disassemble`、メタデータの途中は省略）。

```
$ forge inspect --offline Percent deployedBytecode
0x730000000000000000000000000000000000000000301460806040525f5ffdfea2646970667358221220…0033
$ cast disassemble 0x730000000000000000000000000000000000000000301460806040525f5ffdfe
00000000: PUSH20 0x0000000000000000000000000000000000000000
00000015: ADDRESS
00000016: EQ
00000017: PUSH1 0x80
00000019: PUSH1 0x40
0000001b: MSTORE
0000001c: PUSH0
0000001d: PUSH0
0000001e: REVERT
0000001f: INVALID
$ forge inspect --offline Percent methodIdentifiers
（空の表）
```

FeeLibの外の関数は`fee`一つで、ライブラリ関数`part`にはセレクタがない。名前なしで`part(a, 3)`と呼ぶと`Error (7576): Undeclared identifier.`、`Percent.part.selector`は`Error (9582)`である。内部関数型の変数に`Percent.part`を入れるのはビルドできる。

```
$ forge inspect --offline FeeLib methodIdentifiers
| Method       | Identifier |
| fee(uint256) | 39b37ab0   |
```

アカウント1番がWhoに`hello()`を送ると、ライブラリ関数の中の`msg.sender`はアカウント1番、`address(this)`はWhoで、別に開かれた呼び出しの行はない（`cast run`、トランザクションハッシュは省略）。

```
$ cast run 0xcc7f0e7a…c9dc4 --rpc-url $R
Traces:
  [1785] 0x5FbDB2315678afecb367f032d93F642f64180aa3::hello()
    ├─ emit Seen(sender: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, self: 0x5FbDB2315678afecb367f032d93F642f64180aa3)
    └─ ← [Stop]

Transaction successfully executed.
Gas used: 22849
```

アカウント1番がShelfに`put(70)`を送ると、BoxLibが`storage`の引数で受け取った欄が、Shelfのストレージで変わる（`cast call`、`cast index`、`cast storage`、スロット番号は省略）。

```
$ cast call $SHELF "boxes(address)(uint256,uint64)" $A1 --rpc-url $R
70
1792413984 [1.792e9]
$ cast index address $A1 0
0x14e04a66bf74771820a7400ff6cf065175b3d7eb25805a5bd1633b161af5d101
$ cast storage $SHELF 0x14e04a66…af5d101 --rpc-url $R
0x0000000000000000000000000000000000000000000000000000000000000046
$ cast storage $SHELF 0x14e04a66…af5d102 --rpc-url $R
0x000000000000000000000000000000000000000000000000000000006ad61120
```

`Box memory`で受け取る`putCopy(5)`はコピーを書き換えるので、あとで照会しても70のままである。

Marketの第116講のバージョン（`forge test`、サイズの比較）。

```
$ forge test --offline
Ran 13 test suites: 48 tests passed, 0 failed, 0 skipped (48 total tests)
```

| 項目 | 第115講のバージョン | 第116講のバージョン |
|---|---|---|
| ランタイム / 作成のコード | 7,233 / 7,811バイト | 7,298 / 7,876バイト |
| MarketのlinkReferences | 空 | 空 |
| デプロイするもの | Market一つ | Market一つ |
| セレクタ、スロット番号 | 19個、0〜5 | そのまま |
| テスト | 46個 | 48個 |

InterestMath・PositionLibの成果物も、それぞれ85バイトで関数のコードがない。

Percentの本体だけを切り上げに変えたv2では、Fee.solを変えていないのにFeeLibが540 → 603バイトになり、1,010の3%（30.3）が30から31になる。

```
$ forge build --offline --sizes
| FeeLib     | 603              | 631               |
$ cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "fee(uint256)(uint256)" 1010 --rpc-url $R
30
$ cast call 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 "fee(uint256)(uint256)" 1010 --rpc-url $R
31
```

ライブラリの表。

| ライブラリ / ファイル / 可視性 | 関数 / 呼ぶ場所 | 書き換えるストレージ / デプロイ |
|---|---|---|
| InterestMath / MarketMath.sol / internal | interestFor、SECONDS_PER_YEAR（constant） / Market.interestFor、Market.SECONDS_PER_YEAR | なし / Marketに合わさる |
| PositionLib / MarketMath.sol / internal | credit、debit / Ledgerの`_credit`、`_debit` | 渡されたPosition（positionsのスロット3の中のdeposited・lastUpdate） / Marketに合わさる |

### 試すときの注意

- internal関数だけのライブラリは、別にはデプロイしない。呼んだ関数のコードが呼ぶ側のコントラクトのランタイムコードに入り、成果物の`linkReferences`は空である。
- ライブラリ関数は、`Percent.part(a, 3)`のようにライブラリの名前をつけて呼ぶ。
- ライブラリ関数の中の`msg.sender`は最初に呼んだアカウント、`address(this)`は呼ぶ側のコントラクトである。
- ライブラリが書き換えるストレージは、呼ぶ側が`storage`の引数で渡す。`memory`で受け取ると、コピーを書き換える。
- メタデータにはソースをハッシュした値が入るので、バージョンごとに違う。コードが同じかを比べるときは、ランタイムコードの最後の53バイト（最後の2バイトが長さ0x0033 = 51）を外して比べる。
- 他人のライブラリでも、internal関数を呼べばそのコードが自分のデプロイするものに入る。ライブラリのバージョンを上げると、自分のデプロイするものが変わる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやライブラリのバージョンが変わると、変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| メタデータ | ランタイムコードの最後の2バイト0x0033 = 51、最後の53バイト（CBORのメタデータ51 + 長さ2） | 2026-10-19 |
| Feeの四つのバージョンのサイズ | FeeLib・FeeInline・FeeInherit・FeeManyのruntime 540 / initcode 568、メタデータを外した487バイトのsha256 b3116b88…は四つとも同じ | 2026-10-19 |
| Percentの成果物 | Percent・PercentMany・InterestMath・PositionLibのruntime 85バイト、メタデータを外した32バイトは同じ（sha256 53b5c08f…）、methodIdentifiersは空の表 | 2026-10-19 |
| 本体を変えたPercentのバージョン | FeeLib 603 / 631（Fee.solはそのまま）、`fee(1010)` 30 → 31 | 2026-10-19 |
| anvilのデモのガス | Who hello 22,849（トレース[1785]）、Shelf put(70) 66,190、putCopy(5) 26,331 | 2026-10-19 |
| Marketのサイズ | 第115講のバージョンのruntime 7,233 / initcode 7,811、第116講のバージョン7,298 / 7,876、linkReferences {} | 2026-10-19 |
| Marketのガス（第115講のバージョン / 第116講のバージョン） | デプロイ1,619,356 / 1,633,390、interestForの見積もり23,445 / 23,497、addAsset 75 93,730 / 93,730、deposit 100 130,376 / 130,369、withdraw 30 59,692 / 59,697、setStatus 1 45,732 / 45,732、setStatus 0 23,820 / 23,820、失敗deposit 0 26,869 / 26,869 | 2026-10-19 |
| Marketのガスの実測の条件 | バージョンごとに新しいanvil、`anvil_setBlockTimestampInterval 1`、アカウント0番がMockToken `0x5FbD…0aa3` → Market `0xe7f1…0512`をデプロイ、二回走らせて同じ値 | 2026-10-19 |
| テスト | 第115講のバージョン46個、第116講のバージョン48個が通る（LibraryTest 2個） | 2026-10-19 |
| OpenZeppelin Contracts | v5.4.0 `utils/Strings.sol`（library Strings）、`utils/math/Math.sol`（library Math）、関数はすべてinternal | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| public・externalのライブラリ関数、リンク、delegatecall | [第117講](../../part6/lecture117/) |
| ライブラリの成果物の先頭のバイト（自分のアドレスとの比較） | [第117講](../../part6/lecture117/) |
| ライブラリ関数を型につけて使う（`using for`） | [第118講](../../part6/lecture118/) |
| グローバル関数の総覧 | [第126講](../../part7/lecture126/) |
| ライブラリをどのパスとバージョンから取り込むか | [第129講](../../part8/lecture129/) |
| スロット番号の規則の全体 | [第135講](../../part8/lecture135/) |
| 同じことをするコードのサイズとガスの選び方 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 標準の実装のライブラリ（OpenZeppelin）の選び方 | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| internalのライブラリ関数の中のselfdestructが、呼ぶ側のコントラクトで動くということ | [第177講](../../part11/lecture177/) |
| 他人のライブラリまで読む精読の手順 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
