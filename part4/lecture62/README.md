# 第62講 データの場所の概念

第4部 言語の詳細 ① ファイルと型・第14章 参照型

[← 第61講](../../part4/lecture61/) | [第4部 目次](../) | [第63講 →](../../part4/lecture63/)

## この講義の問い

値型の12講のあいだ一度も書かなかった単語を、配列や文字列ではなぜ必ず書かなければならず、その単語一つが何を決めるのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクトから、Counterのファイルを消して始める。すべてのファイルのいちばん上は、`// SPDX-License-Identifier: GPL-3.0`と`pragma solidity 0.8.30;`の二行である。コンパイルできない例はsrcの外の`bad/`に、ライブラリの例は`lib2/`に置き、ファイルのパスを指定して別々にビルドする（`forge build --offline bad/NoLoc.sol`）。テストにはforge-stdが必要である（`lib/forge-std`）。デプロイと呼び出しは、ローカルのanvilで既定のアカウント0・1・2（公開されたテスト用の鍵）を使って行う。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Places.sol](code/src/Places.sol) | 状態配列`kept`（storage）とローカル配列`temp`（memory）を1回ずつ増やす`bump()`、storageパラメーターを受け取るinternal関数 |
| [code/src/Ext.sol](code/src/Ext.sol) | 同じ合計を、calldata・memoryのパラメーター、external・publicの関数で受け取る三つの版 |
| [code/src/Lending.sol](code/src/Lending.sol) | レンディングプロトコルの骨組み。資産リスト`assets`はstorage、入力リストはcalldata |
| [code/lib2/ArrLib.sol](code/lib2/ArrLib.sol) | storage配列をパラメーターとして受け取るライブラリ関数 |
| [code/test/Places.t.sol](code/test/Places.t.sol) | `bump()`を2回呼び、storageの値が2、memoryの値が1かを確認 |
| [code/bad/](code/bad/) | データの場所を抜かしたり間違えたりして、コンパイルが拒否される例11個 |

`code/bad/`のファイルとエラー：

| ファイル | 行 | エラー |
|---|---|---|
| NoLoc.sol | `function g(uint[] x) public {}` | Error (6651) parameter |
| RetNoLoc.sol | `function f() public pure returns (uint[]) {}` | Error (6651) return parameter |
| LocalNoLoc.sol | 関数の中の`uint[] a;` | Error (6651) variable |
| BytesLocal.sol | 関数の中の`bytes b = "abc";` | Error (6651) variable |
| ValueLoc.sol | `function f(uint memory x) public {}` | Error (6651) 値型に場所 |
| StateLoc.sol、StateLoc2.sol | 状態変数`uint[] memory xs;`、`uint[] storage xs;` | Error (2314) |
| StorageParam.sol | `function f(uint[] storage x) public {}` | Error (6651) "storage" was given |
| CtorCd.sol | `constructor(bytes32[] calldata names) {}` | Error (6651) コンストラクターのパラメーター |
| CalldataWrite.sol | `function f(uint[] calldata x) external { x[0] = 1; }` | Error (6182) |
| TransArr.sol | 状態変数`uint[] transient xs;` | Error (1834) |

### 実行結果

`bad/`を一つずつビルドしたエラーの原文（代表）：

```
$ forge build --offline bad/NoLoc.sol
Error (6651): Data location must be "memory" or "calldata" for parameter in function, but none was given.
$ forge build --offline bad/RetNoLoc.sol
Error (6651): Data location must be "memory" or "calldata" for return parameter in function, but none was given.
$ forge build --offline bad/BytesLocal.sol
Error (6651): Data location must be "storage", "memory" or "calldata" for variable, but none was given.
$ forge build --offline bad/ValueLoc.sol
Error (6651): Data location can only be specified for array, struct or mapping types, but "memory" was given.
$ forge build --offline bad/StateLoc.sol
Error (2314): Expected identifier but got 'memory'
$ forge build --offline bad/StorageParam.sol
Error (6651): Data location must be "memory" or "calldata" for parameter in function, but "storage" was given.
$ forge build --offline bad/CtorCd.sol
Error (6651): Data location must be "storage" or "memory" for constructor parameter, but "calldata" was given.
$ forge build --offline bad/CalldataWrite.sol
Error (6182): Calldata arrays are read-only.
$ forge build --offline bad/TransArr.sol
Error (1834): Transient data location is only supported for value types.
```

`forge build --offline lib2/ArrLib.sol`は`Compiler run successful!`で終わる。

`forge inspect --offline Places storageLayout`（区切り線は省略）。状態配列`kept`だけがあり、ローカル配列`temp`はない：

```
| Name | Type      | Slot | Offset | Bytes | Contract              |
| kept | uint256[] | 0    | 0      | 32    | src/Places.sol:Places |
```

`forge test --offline -vvvv`。1回目の呼び出しでも2回目の呼び出しでも、memoryの側は1である：

```
[PASS] test_twice() (gas: 103600)
Traces:
  [103600] PlacesTest::test_twice()
    ├─ [67294] Places::bump()
    │   └─ ← [Return] 1, 1
    ├─ [29776] Places::bump()
    │   └─ ← [Return] 2, 1
    └─ ← [Stop]
```

anvilにデプロイしたPlaces（`0x5FbDB2315678afecb367f032d93F642f64180aa3`）を、アカウント1とアカウント2が1回ずつ`cast send`で呼んだあと、`cast call`で読んだ値。誰が呼んでもstorage配列は一つなので3回目の問いで3が出て、memoryの側は毎回1である：

```
$ cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "bump()(uint256,uint256)"
3
1
$ cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "kept(uint256)(uint256)" 0
2
```

二つの`cast send`のgasUsedは67294、29776である。`cast storage <Places> 0`は配列の長さの欄なので1が出る。

Ext（`0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`）の`sumCalldata`、`sumMemory`、`sumPublic`に`"[1,2,3]"`を渡すと、三つとも6である。

`forge inspect --offline Lending storageLayout`（区切り線は省略）。`status`と`admin`が0番の欄を分け合う：

```
| Name   | Type                      | Slot | Offset | Bytes | Contract                |
| status | enum Lending.MarketStatus | 0    | 0      | 1     | src/Lending.sol:Lending |
| admin  | address                   | 0    | 1      | 20    | src/Lending.sol:Lending |
| assets | address[]                 | 1    | 0      | 32    | src/Lending.sol:Lending |
```

### 試すときの注意

- `bad/`のファイルはsrcの外に置く。srcの中にあると、全体の`forge build`も一緒に失敗する。
- Lendingをビルドすると、forgeのリントが`uninitialized-state`の警告（status、admin、assetsに値を書く場所がない）を出す。骨組みなので、そのままにしておく。
- `cast`コマンドには、anvilのアドレスを`--rpc-url`でつける。上のアドレスは、新しいanvilでアカウント0がPlaces、Extの順にデプロイしたときの値である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、数字とエラーの文言が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidityドキュメントのバージョン | v0.8.36、Typesの節のReference Types / Data location | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundryのバージョン | forge・cast・anvil 1.8.3 | 2026-10-19 |
| public関数のパラメーターでのcalldataの許可 | 0.6.9から。それ以前は、externalはcalldata、publicはmemory、internal・privateはmemoryまたはstorage | 2026-10-19 |
| データの場所の表示の義務化 | 0.5.0から。それ以前は、変数の種類によって既定の場所 | 2026-10-19 |
| transient状態変数 | 0.8.28から値型を全面サポート。参照型のtransientは未サポート（Error 1834） | 2026-10-19 |
| メモリ・ストレージのガス | MLOAD・MSTORE 3 + メモリ拡張 / SLOADコールド2,100、ウォーム100 / SSTORE 0から新しい値へ20,000 | ベルリン（2021.04）以降 |
| Places.bump()のgasUsed | 1回目の呼び出し67,294 / 2回目の呼び出し29,776 | 2026-10-19 |
| エラー番号 | 6651（場所なし・間違った場所・値型に場所）、2314（状態変数に場所の単語）、6182（calldata配列への書き込み）、1834（参照型のtransient） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 場所の組み合わせごとの代入のルール（コピーと別名） | [第63講](../../part4/lecture63/) |
| 場所ごとのガス測定の比較（memory・calldataの引数、storageのコピー） | [第64講](../../part4/lecture64/) |
| 動的配列の長さの欄と要素の欄の計算 | [第66講](../../part4/lecture66/) |
| memory配列の作成（new）とメモリ拡張 | [第67講](../../part4/lecture67/) |
| ライブラリのstorageパラメーター | [第116講](../../part6/lecture116/) |
| ストレージの配置のルール（小さな値をまとめる） | [第135講](../../part8/lecture135/) |
| transientストレージ | [第136講](../../part8/lecture136/) |
| メモリとcalldataの配置 | [第137講](../../part8/lecture137/)、[第138講](../../part8/lecture138/) |
| ユーザーごとの預けた量・借りた量（マッピング） | [第71講](../../part4/lecture71/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
