# 第118講 using forと演算子の付け方

第6部 言語の詳細 ③ コントラクト・第26章 ライブラリとusing for

[← 第117講](../../part6/lecture117/) | [第6部 目次](../) | [第119講 →](../../part7/lecture119/)

## この講義の問い

`using L for T`の一行は`a.f(b)`を何に変え、どこまで通じ、ユーザー定義値型につけた演算子は何を呼ぶのか。

## 実習資料

### 準備

第117講の終わりのMarketのプロジェクトから始め、Ledgerに`using PositionLib for Position;`を書き、MarketTypes.solで`Amount`に演算子`+`・`-`をつける（`global`）。`using for`と演算子のデモは別に作ったデモ用のプロジェクト（`demo`）で行い、同じソースをoptimizerを入れた設定（`demo_opt`）とvia-IRの設定（`demo_ir`）でもビルドしてサイズを比べる。エラー・通る例は、`errors/`の下のフォルダごとに別々にビルドする。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて（比較用のバージョンを除く）、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Attach.sol](code/demo/src/Attach.sol) | 名前を書いて呼ぶFeeDirect、`using Percent for uint256;`でつけて呼ぶFeeAttach、`using BoxLib for Box;`のShelfAttach |
| [code/demo/src/Money.sol](code/demo/src/Money.sol) | `Money`に`+`・`-`・`<`をつけたバージョン、本体をuncheckedで書いた`LooseMoney`の`-`、それを呼ぶTill |
| [code/demo/src/Percent.sol](code/demo/src/Percent.sol)、[code/demo/src/Shelf.sol](code/demo/src/Shelf.sol) | 第116講のデモのソース |
| [code/demo/foundry.toml](code/demo/foundry.toml) | 既定の設定 |
| [code/demo_opt/foundry.toml](code/demo_opt/foundry.toml)、[code/demo_ir/foundry.toml](code/demo_ir/foundry.toml) | 同じソースをビルドする比較用の設定（optimizer runs 200、via_ir） |
| [code/errors/](code/errors/) | `using for`の範囲：attach_inherit・attach_none・attach_file_import・attach_pick（9582）、attach_global_foreign（8841）、attach_global_in_contract（3367）、attach_global_otherfile（4117）、attach_storage（4994）、通るもの attach_ok・attach_firstarg・attach_global_ok・attach_free・attach_star・attach_public。ドットのあとの名前：xfer_lib_on_address（通る）、xfer_none（9862）、xfer_lib_on_payable（6675）。演算子：op_view・op_lib・op_lib_public（7775）、op_noglobal（3320）、op_uint（5332）、op_uint_nonglobal（globalなしでuint256につけたバージョン）、op_shift（4403）、op_mixed_params（1884）、op_cmp_wrongret（7743）、op_cmp（2271）、op_compound（7366）、op_mix（5653）、通るもの op_ok・op_unary・op_unchecked_body・op_scaled・op_scaled_nodiv |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | `addAmount`・`subAmount`と`using {addAmount as +, subAmount as -} for Amount global;` |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | PositionLibの本体がAmountの`+`・`-`を使う |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第118講のバージョン（第6部の終わりのバージョン）。Ledgerに`using PositionLib for Position;`、`positions[asset][user].credit(amount)` |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol)、[code/market/src/MockToken.sol](code/market/src/MockToken.sol) | インターフェースとテスト用のトークン |
| [code/market/test/Library.t.sol](code/market/test/Library.t.sol) | `test_amountOperators`を追加（5+3、5-3、2-3はPanic 0x11） |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト |

### 実行結果

名前を書いて呼んだバージョンと、つけて呼んだバージョンは同じ答えになる（`cast call`）。

```
$ cast call $FD "fee(uint256)(uint256)" 1000 --rpc-url $R
30
$ cast call $FA "fee(uint256)(uint256)" 1000 --rpc-url $R
30
```

uint8の値につけてもuint256の最初の引数として入り（`errors/attach_firstarg`は通る）、ShelfAttachの`boxes[msg.sender].put(amount)`はstorageの値につき、アカウント1番の`put(70)`のあと`boxes(アカウント1番)`は70である。memoryのBoxにつけると止まる。

```
Error (4994): Member "put" is not available in struct Box memory outside of storage.
```

つけて呼んだバージョンのサイズ（`forge build --sizes`、ランタイムのバイト）。

| 設定 | FeeDirect | FeeAttach |
|---|---|---|
| 既定（optimizerは切る） | 540 | 549 |
| optimizerを入れる（runs 200） | 257 | 257、メタデータを除けばバイトは同じ |
| via-IR | 546 | 546 |

既定の設定での差は、引数の位置を入れ替える数バイトと、後ろにずれたジャンプ先のアドレスである（最後の53バイトを除いたランタイムコードの`cast disassemble`の比較）。

```
$ diff FeeDirect.asm FeeAttach.asm
67,68c67
< PUSH2 0x0069
< DUP3
---
> PUSH2 0x0072
70c69,75
< PUSH2 0x0070
---
> DUP4
> PUSH2 0x0079
> SWAP1
> SWAP2
> SWAP1
> PUSH4 0xffffffff
> AND
```

FeeAttachの`linkReferences`は`{}`である。publicのライブラリ関数につけたバージョン（`errors/attach_public`）は`{"src/X.sol": {"PercentPub": [{"start": 97, "length": 20}]}}`で、呼ぶたびにdelegatecallである。

`using for`が通じる範囲。

```
abstract contract P { using Percent for uint256; }  contract C is P { ... a.part(3) ... }
Error (9582): Member "part" not found or not visible after argument-dependent lookup in uint256.

// A.solにファイルレベルのusing、B.solでimport "./A.sol"のあとにa.part(3)
Error (9582): Member "part" not found or not visible after argument-dependent lookup in uint256.

contract C { using {Percent.part} for uint256; ... a.half() ... }
Error (9582): Member "half" not found or not visible after argument-dependent lookup in uint256.
```

| `global`を書いた場所 | 結果 |
|---|---|
| `using Percent for uint256 global;` | Error (8841): Can only use "global" with user-defined types. |
| コントラクトの中の`using L for Amount global;` | Error (3367): "global" can only be used at file level. |
| Amountを取り込んだ別のファイル | Error (4117): Can only use "global" with types defined in the same source unit at file level. |
| Amountを宣言したファイル、ファイルレベル | 通る。Amountだけを取り込んだ別のファイルでも、つけた関数を使える |

自由関数をつける`using {part} for uint256;`と`using Percent for *;`もビルドできる。

ドットのあとの名前。`using Pay for address;`でつけた`a.transfer(to, 5)`はビルドでき、usingなしで`address`に`a.transfer(5)`を書くと`Error (9862): "send" and "transfer" are only available for objects of type "address payable", not "address".`、同じ名前を`address payable`につけると`Error (6675): Member "transfer" not unique after argument-dependent lookup in address payable.`である。

| 書かれた行 | 呼ばれるコード |
|---|---|
| `a.transfer(to, 5)`（`using Pay for address`） | ライブラリPayのtransfer |
| `to.transfer(1 ether)`（`address payable`） | イーサを送る組み込みのメンバー |
| `IERC20(asset).transfer(msg.sender, amount)` | トークンのコントラクトのtransfer |

`Money`につけた演算子（`cast call`）。同じ`-`でも、つけておいた関数の本体どおりに計算する。

```
$ cast call $T "minus(uint256,uint256)(uint256)" 5 3 --rpc-url $R
2
$ cast call $T "minus(uint256,uint256)(uint256)" 2 3 --rpc-url $R
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call $T "looseMinus(uint256,uint256)(uint256)" 2 3 --rpc-url $R
115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]
$ cast call $T "less(uint256,uint256)(bool)" 2 3 --rpc-url $R
true
```

ABIには元の型で載る（`forge inspect Till methodIdentifiers`）。

```
| less(uint256,uint256)       | 2d738965 |
| looseMinus(uint256,uint256) | 864034e2 |
| minus(uint256,uint256)      | f4f3bdc1 |
| minusRaw(uint256,uint256)   | 3b6c6a26 |
```

演算子を決める条件（`forge build --force`）。

| 破ったこと | エラー |
|---|---|
| view関数、ライブラリ関数（internal・public） | Error (7775): Only pure free functions can be used to define operators. |
| globalなしで書く | Error (3320): Operators can only be defined in a global 'using for' directive. |
| uint256につける | Error (5332): Operators can only be implemented for user-defined value types. |
| `<<` | Error (4403): Not a user-definable operator: <<. Only the following operators can be user-defined: \|, &, ^, ~, +, -, *, /, %, ==, !=, <, >, <=, >= |
| 引数が`(Amount, uint256)` | Error (1884): Wrong parameters in operator definition. … two parameters of type Amount … |
| `<`がAmountを返す | Error (7743): Wrong return parameters in operator definition. … exactly one value of type bool … |

単項の`-`、本体をuncheckedで書いた`-`、倍率のある型の`*`（割り算を本体に直接書いたバージョンと抜いたバージョンの両方）はビルドできる。つけた記号だけが使える。

```
using {lt as <} for Amount global;  ...  return a > b;
Error (2271): Built-in binary operator > cannot be applied to types Amount and Amount. No matching user-defined operator found.

using {add as +} for Amount global;  ...  total += a;
Error (7366): Operator += not compatible with types Amount and Amount.

using {add as +} for Amount18 global;  ...  return a + b;   // bはAmount6
Error (5653): The type of the second operand of this user-defined binary operator + does not match the type of the first operand, which is Amount18.
```

Marketの第118講のバージョンで一か所ずつ変えた変形。

```
// Marketにpositions[asset][msg.sender].credit(0)を使う関数を加える
Error (9582): Member "credit" not found or not visible after argument-dependent lookup in struct Position storage ref.

// MarketTypes.solからglobalを抜く
Error (3320): Operators can only be defined in a global 'using for' directive.
Error (2271): Built-in binary operator + cannot be applied to types Amount and Amount. No matching user-defined operator found.

// _creditの合計の行をtotalDeposits[asset] += Amount.wrap(amount);に縮める
Error (7366): Operator += not compatible with types Amount and Amount.
```

| 項目 | 第117講のバージョン | 第118講のバージョン |
|---|---|---|
| Marketのruntime / initcode | 7,298 / 7,876 | 7,353 / 7,931 |
| デプロイのgasUsed | 1,633,390 | 1,645,279 |
| deposit 100 / withdraw 30 | 130,369 / 59,697 | 130,478 / 59,911 |
| addAsset 75 / setStatus 1 / setStatus 0 / 失敗deposit 0 | 93,730 / 45,732 / 23,820 / 26,869 | 同じ |
| `forge test --offline` | 48個 | 49個（test_amountOperators） |

`using`だけをつけて演算子はつけないバージョンはruntime 7,316で、optimizerを入れると第117講のバージョンとメタデータを除いてバイトが同じである（3,734）。セレクタ19個、topic0四つ、エラーのセレクタ十二個、スロット0〜5はそのままで、`linkReferences`は`{}`である。

| ライブラリ | 可視性 | リンクのアドレス | つけた型（using） |
|---|---|---|---|
| InterestMath | internal | なし | なし |
| PositionLib | internal | なし | Position（Ledgerの中でだけ） |

Amountの演算子`+`・`-`は、MarketTypes.solの自由関数`addAmount`・`subAmount`（global）で、ライブラリ関数ではない。

### 試すときの注意

- `using L for T`と書くと、`a.f(b)`は`L.f(a, b)`である。ドットの前の値が最初の引数として入る。storageを受け取る関数は、storageの値にだけつく。
- `using for`は、書いたコントラクトかファイルの中でだけ通じる。継承してもimportしてもついてこない。ユーザー定義値型を宣言したファイルのファイルレベルに`global`を書くと、その型を使うところならどこでも通じる。
- ドットのあとの関数の名前がその型にもともとあるものかつけたものかは、その行だけを見てもわからない。ファイルとコントラクトの`using`の行を探す。
- 演算子は、ユーザー定義値型に、pureの自由関数で、`global`でだけつける。`+`をつけても`+=`はついてこず、`<`をつけても`>`はついてこない。
- 演算子は、つけた関数の本体どおりに計算する。本体をuncheckedで書くと、あふれてもリバートしない。倍率のある型の掛け算は、割り算を本体に直接書く必要がある。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやコンパイルの設定が変わると、数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン。比較用のバージョン：optimizerを入れる（runs 200）、via-IR | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| `using for`の継承の規則 | 0.7.0（2020-07-28）から、書いたコントラクトにだけ適用、継承したコントラクトにはついていかない | 2026-10-19 |
| ファイルレベルの`using`・`global` | 0.8.13（2022-03-16）から | 2026-10-19 |
| 演算子の定義 | 0.8.19（2023-02-22）から。同じバージョンで、externalのライブラリ関数も`using for`に許可 | 2026-10-19 |
| Feeの二つのバージョンのサイズ（runtime / initcode） | 既定 FeeDirect 540 / 568、FeeAttach 549 / 577 ・ optimizer どちらも257 / 285（最後の53バイトを除いたsha256 f345b86c…が同じ） ・ via-IR どちらも546 / 589 ・ Shelf 1,035 / ShelfAttach 1,044、optimizer 527 / 527、via-IR 1,399 / 1,399 ・ Till 937 | 2026-10-19 |
| Feeの二つのバージョンのガス | `cast estimate fee(1000)` FeeDirect 22,260、FeeAttach 22,275 | 2026-10-19 |
| Tillのガス | `cast estimate` minus(5, 3) 22,509、minusRaw(5, 3) 22,418 | 2026-10-19 |
| ShelfAttach | アカウント1番の`put(70)`のgasUsed 66,205、`boxes(アカウント1番)` 70 | 2026-10-19 |
| Marketのサイズ | 第117講のバージョン7,298 / 7,876、第118講のバージョン7,353 / 7,931、usingだけをつけたバージョン7,316 / 7,894 ・ optimizerを入れる：第117講のバージョン・usingだけをつけたバージョン3,734（最後の53バイトを除いたsha256 b2787710…が同じ）、第118講のバージョン3,755 | 2026-10-19 |
| Marketのガス（第117講のバージョン → 第118講のバージョン） | デプロイ1,633,390 → 1,645,279、addAsset 75 93,730 → 93,730、deposit 100 130,369 → 130,478、withdraw 30 59,697 → 59,911、setStatus 1 45,732 → 45,732、setStatus 0 23,820 → 23,820、失敗deposit 0 26,869 → 26,869。usingだけをつけたバージョン：デプロイ1,637,242、deposit 100 130,384、withdraw 30 59,712 | 2026-10-19 |
| Marketのガスの実測の条件 | バージョンごとに新しいanvil、`anvil_setBlockTimestampInterval 1`、アカウント0番がMockTokenの次にMarketをデプロイ、コンストラクタの引数はアカウント0番・5e16・80。第118講のバージョンは二回走らせて同じ値 | 2026-10-19 |
| テスト | 第117講のバージョン48個、第118講のバージョン49個が通る（LibraryTest 3個） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| importのパスの解決と`using`の範囲 | [第129講](../../part8/lecture129/) |
| ABIにユーザー定義値型が元の型で載る規則 | [第141講](../../part8/lecture141/) |
| optimizer・via-IRの設定とバイトの違い | [第133講](../../part8/lecture133/)、[第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| `using for`の規則のバージョンごとの変化 | [第185講](../../part11/lecture185/) |
| 検査付きの算術とuncheckedの本体 | [第186講](../../part11/lecture186/) |
| グローバル関数・演算子の総覧 | [第126講](../../part7/lecture126/) |
| 標準の実装が使う`using`の形（SafeERC20など） | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| 倍率のある値の掛け算・割り算 | [第194講](../../part13/lecture194/)、[第195講](../../part13/lecture195/)、[第196講](../../part13/lecture196/) |
| 精読の手順での`using`の行の確認 | [第188講](../../part12/lecture188/) |
| Yulとインラインアセンブリ | [第119講](../../part7/lecture119/)〜[第125講](../../part7/lecture125/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
