# 第136講 transient storage

第8部 コンパイラと内部構造・第33章 保存配置の内部

[← 第135講](../../part8/lecture135/) | [第8部 目次](../) | [第137講 →](../../part8/lecture137/)

## この講義の問い

transientの変数はどこに置かれ、いつ0に戻り、ストレージ・メモリと何が同じで何が違うのか。Marketに使う場所はあるのか。

## 実習資料

### 準備

transientの変数を使う小さなコントラクトを集めたデモのプロジェクト（`demo`）と、通しプロジェクトMarketの第136講のバージョン（第135講のバージョンとコードが同じで、バージョンを説明するコメントを1行だけ足したバージョン）を使う。solc 0.8.30、Foundry 1.8.3で、forge-stdが必要である（`lib/forge-std`）。デモのプロジェクトはoptimizerを切り、evm_versionはosakaである。コントラクトごとにローカルのanvilにアカウント0番で新しくデプロイしてトランザクションを送り、命令ごとのガスは`anvil --steps-tracing`の`debug_traceTransaction`から読む。エラーの原文は、`code/solc/`のファイルを`solc --bin`で一つずつビルドして見る。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモのプロジェクトの設定 |
| [code/demo/src/T136.sol](code/demo/src/T136.sol) | ドキュメントの例MulServiceとBatch、Life（トランザクションごとの値）、Same（同じ0番の二つの欄）、Rev（リバート）、Other・Share・TLib・TWriter（自分への呼び出し、別のコントラクト、delegatecall）、Static（staticcall）、FlagS・FlagT（ストレージ / transientでの作業中の印）、Leave（消さない印）、Asm136 |
| [code/demo/src/Slot136.sol](code/demo/src/Slot136.sol) | transientの変数の`.slot`・`.offset`と、`tload`・`sload`・`tstore` |
| [code/demo/test/Slot136.t.sol](code/demo/test/Slot136.t.sol) | Slot136.runの結果を出すテスト |
| [code/solc/](code/solc/) | 1行だけのファイル14個。Arr・Map・Str・Init・Const・Immut・Local・Param・Name・ViewW・PureRはエラーを出すファイル、Ok・Asmは`--evm-version shanghai`での比較用、Pubは`public transient`のゲッター |
| [code/market/](code/market/) | Market 第136講のバージョン（foundry.toml、src、test）。テスト58個 |

### 実行結果

コントラクトごとに新しくデプロイして送ったトランザクションの結果（かっこの中はgasUsed）。

| 送ったもの | 結果 |
|---|---|
| Life bump トランザクション1 | Seen(1, 1)（45,671） |
| Life bump トランザクション2 | Seen(2, 1)（28,571） |
| Life bumpTwice トランザクション一つ | Seen(3, 1)、Seen(4, 2)（32,109） |
| そのあとの`cast call readT()` | 0 |
| Batch.run: setMultiplier(42) → multiply(1) → multiply(2)を一つのトランザクションで | Got(42, 84)（30,747） |
| setMultiplier(42)のトランザクションのあとの`cast call`でmultiply(1)・multiply(2) | 0、0 |
| Same.both | sv 11、tv 22。トランザクションのあとの`cast storage <Same> 0`は`0x…0b` |
| Rev.run(true): 内側の呼び出しがリバート | R(t 1, s 1, ok false) |
| Rev.run(false) | R(t 2, s 2, ok true) |
| Share.run: `t = 5`のあとに自分への呼び出し | 自分への呼び出しが読んだt 5、Otherが読んだ`tload(0)` 0、自分への呼び出しの中の0x40の欄0x80 |
| Share.viaLib | 内部ライブラリの`tstore(0, 9)`のあと9、TWriter.put(10)のdelegatecallのあと10、TWriter.put(11)のふつうのcallのあと10（TWriter自身の欄は11） |
| Static.tryStatic | staticcallで書き込みfalse、読み取りtrue |

デモのプロジェクトで`forge test --match-path test/Slot136.t.sol -vv`。

```
[PASS] test_slot() (gas: 67865)
Logs:
  b.slot 0 b.offset 0
  i.slot 0 i.offset 16
  0x999999999999999999999999999999990000000000000000000000000000bbbb
  sload(b.slot) 7
  0x00000000000000000000000000000000
```

`sload(b.slot)`はストレージ0番のs0（7）で、`tstore(b.slot, 0x1234)`が同じ欄のiまで上書きするので、最後の行が0である。

`code/solc/`のファイルを`solc --bin`でビルドしたエラーの原文。

| ソース | solc 0.8.30 |
|---|---|
| `uint transient x = 1;` | Error: Initialization of transient storage state variables is not supported. |
| `mapping(uint => uint) transient m;`・`uint[] transient a;`・`S transient s;` | Error: Transient data location is only supported for value types. |
| `uint constant transient x = 1;`・`uint immutable transient x;` | Error: Transient cannot be used as data location for constant or immutable variables. |
| 関数の中の`uint transient y;` | Error: Expected ';' but got identifier |
| 引数`uint transient y` | Error: Expected ',' but got identifier |
| `uint x; uint transient x;` | Error: Identifier already declared. |
| view関数での書き込み | Error: Function cannot be declared as view because this expression (potentially) modifies the state. |
| pure関数での読み取り | Error: Function declared as pure, but this expression (potentially) reads from the environment or state and thus requires "view". |

`uint public transient x;`はビルドでき、ABIに`x()`のviewゲッターができる。古いEVMのバージョンでビルドすると次のとおり。

```
$ solc --evm-version shanghai --bin Ok.sol
Error: Transient storage is not supported by EVM versions older than cancun.
$ solc --evm-version shanghai --bin Asm.sol
Error: The "tstore" instruction is only available for Cancun-compatible VMs (you are currently compiling for "shanghai").
```

同じMulServiceのバイトコードを`anvil --hardfork shanghai`と`--hardfork cancun`にデプロイし、setMultiplier(42)を`--gas-limit 100000`で送った結果。

| anvil `--hardfork` | MulServiceのデプロイ | setMultiplier(42) |
|---|---|---|
| shanghai | 153,123 成功 | 失敗、100,000を使い切る、最後の命令はTSTORE（pc 137） |
| cancun | 153,123 成功 | 成功、21,696 |

作業中の印をストレージ（FlagS）とtransient（FlagT）に置いた二つのバージョンのworkのトレース。行ごとにデプロイのガス、workの回数、status、gasUsed、保存の命令とgasCostの順である。

```
FlagS deploy 139127 work 1 1 52881 [('SLOAD', 2100), ('SLOAD', 100), ('SSTORE', 20000), ('SLOAD', 2100), ('SSTORE', 20000), ('SLOAD', 100), ('SSTORE', 100)]
FlagS deploy 139127 work 2 1 39201 [('SLOAD', 2100), ('SLOAD', 100), ('SSTORE', 20000), ('SLOAD', 2100), ('SSTORE', 2900), ('SLOAD', 100), ('SSTORE', 100)]
FlagT deploy 138923 work 1 1 44200 [('TLOAD', 100), ('TLOAD', 100), ('TSTORE', 100), ('SLOAD', 2100), ('SSTORE', 20000), ('TLOAD', 100), ('TSTORE', 100)]
FlagT deploy 138923 work 2 1 27100 [('TLOAD', 100), ('TLOAD', 100), ('TSTORE', 100), ('SLOAD', 2100), ('SSTORE', 2900), ('TLOAD', 100), ('TSTORE', 100)]
```

FlagSのgasUsedは、最初の値に戻した印の欄の払い戻しを差し引いた値である。印を消さないLeaveは、workのトランザクション2回は成功し（43,936 / 26,836）、一つのトランザクションで2回呼ぶtwiceは失敗する（28,255、`cast call`で見ると`execution reverted: busy`）。

アセンブリの`tstore`があるファイルをsolcで直接ビルドすると警告が出て、forgeは既定の設定でこの警告を隠す。

```
$ solc --bin Asm.sol
Warning: Transient storage as defined by EIP-1153 can break the composability of smart contracts: Since transient storage is cleared only at the end of the transaction and not at the end of the outermost call frame to the contract within a transaction, your contract may unintentionally misbehave when invoked multiple times in a complex transaction. To avoid this, be sure to clear all transient storage at the end of any call to your contract. …
$ forge config
ignored_error_codes = [
    "license",
    "code-size",
    "init-code-size",
    "transient-storage",
    …
```

Market 第136講のバージョンのtransientの配置と、トランザクションごとの保存の命令。

```
$ solc --transient-storage-layout … src/Market.sol
======= src/Market.sol:Market =======
Contract Transient Storage Layout:
{"storage":[]}
```

| トランザクション | SSTORE | 2回書いた欄 | TLOAD・TSTORE |
|---|---|---|---|
| addAsset 75 | 4 | assetConfigの欄: 0 → 75 → 0x14b | 0 |
| deposit 100 | 5 | なし | 0 |
| withdraw 30 | 5 | なし | 0 |
| withdrawAll | 5 | なし | 0 |
| setStatus 1・setStatus 0 | 1・1 | なし | 0 |

トランザクションの終わりに最初の値に戻った欄がないので、Marketにはtransientに移す値がない。ビルドとテスト。

```
$ forge build --offline --force --sizes
| Market      | 7,353            | 7,931             | 17,223             | 41,221              |
$ forge test --offline
Ran 17 test suites …: 58 tests passed, 0 failed, 0 skipped (58 total tests)
```

### 試すときの注意

- transientの値は、トランザクションが終わってはじめて0になる。同じトランザクションの中では、自分のアドレスを呼び直して新しいコールコンテキストが開いても値が残る（メモリは0x80から新しく始まる）。
- transientのスロット番号は、ストレージとは別に数える。同じ0番が別々の欄で、一つの欄にまとめるやり方はストレージと同じである。
- 呼び出しがリバートすると、その呼び出しで書いたtransientの値も一緒に元に戻る。view・pureのチェックとstaticcallでの書き込みの禁止もストレージと同じで、delegatecallでは呼んだ側の欄を使う。
- transientの変数はsolc 0.8.28から（値型だけ）、アセンブリの`tstore`・`tload`は0.8.24から使える。evm_versionがcancunより古いとビルドできず、すでにデプロイしたコードも、cancunより前の規則のチェーンではTSTOREで失敗する。
- forge 1.8.3は`ignored_error_codes`の既定値に"transient-storage"があり、警告2394を見せない。警告を見るには、solcで直接ビルドするかこの設定を変える。
- transientに書いた値は、関数が終わる前に消す。消さないと、同じトランザクションの次の呼び出しがその値を見る（Leave.twice）。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンやチェーンの規則が変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。evm_versionの既定値はprague、`--evm-version shanghai`ではtransientの変数・アセンブリの`tstore`のどちらもエラー | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3。evm_versionの既定はosaka、`ignored_error_codes`の既定値に"transient-storage"（警告2394を見せない）、anvil `--hardfork shanghai`・`cancun` | 2026-10-20 |
| transientに対応したバージョン | `transient`の状態変数（値型）は0.8.28から、アセンブリの`tstore`・`tload`は0.8.24から。参照型・ローカル変数・引数は、ドキュメントv0.8.36の時点で未対応 | 2026-10-20 |
| EIP-1153とCancun | EIP-1153（TSTORE・TLOAD）、Cancun（Dencun）アップグレードのイーサリアムメインネット2024-03-13 | 2026-10-20 |
| ガスの値 | TLOAD・TSTORE 100。SSTORE 0 → 0でない値は20,000（+ はじめて読む欄の2,100）、元の値に戻す書き込みは100と払い戻し | 2026-10-20 |
| デモのガス | MulServiceのデプロイ153,123、Batch.run 30,747、setMultiplier(42) 21,696、Life bump 45,671 / 28,571、bumpTwice 32,109、Same.both 43,910、Rev.run(true) 47,407 / (false) 30,001、Share.run 29,451、FlagSのデプロイ139,127・work 52,881 / 39,201、FlagT 138,923・44,200 / 27,100、Leave.work 43,936 / 26,836、twice 28,255（失敗） | 2026-10-20 |
| shanghai / cancunのanvil | 同じMulServiceのデプロイ153,123はどちらも成功、setMultiplier(42) `--gas-limit 100000`: shanghaiは失敗（最後の命令はTSTORE pc 137）、cancunは成功21,696 | 2026-10-20 |
| Marketのトレース | 第136講のバージョン、addAsset 75 93,730（SSTORE 4、assetConfigの欄75 → 331）、deposit 100 130,478、withdraw 30 59,911、withdrawAll 47,968、setStatus 1 45,732、setStatus 0 23,820、TLOAD・TSTOREは0回 | 2026-10-20 |
| 行番号 | 第136講のバージョンのdeposit 0のリバートはsrc/Market.sol 146:33。バージョンを説明するコメントが変わると変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| メモリの配置 | [第137講](../../part8/lecture137/) |
| transientとストレージをガスで選ぶ判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| transientのロックの使い方（外部呼び出しの途中で同じコントラクトに入り直す呼び出しを防ぐ）と、ドキュメントTransient Storageの節のGenerosityの例 | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| 一つのトランザクションにいくつもの呼び出しをまとめる側から見たtransientの値 | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| delegatecallでほかの人のコードが自分のtransientを使う構造 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| チェーンの規則の変更とコンパイラのevm_version | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 警告を隠すツールの設定の確認 | [第182講](../../part11/lecture182/)、[第183講](../../part11/lecture183/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
