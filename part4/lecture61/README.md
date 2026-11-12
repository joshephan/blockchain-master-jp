# 第61講 関数型

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第60講](../../part4/lecture60/) | [第4部 目次](../) | [第62講 →](../../part4/lecture62/)

## この講義の問い

関数を値として渡せるなら、その値には実際に何が入っていて、その値を呼ぶと何が決まるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める（`code/main`）。テストにはforge-stdが必要である（`lib/forge-std`）。コンパイルエラーを見せるファイルは、別のプロジェクト（`code/bad`）に置く。anvilは使わず、すべて`forge test`の中でデプロイする。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/main/foundry.toml](code/main/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/main/src/FnTypes.sol](code/main/src/FnTypes.sol) | 内部・外部の関数型の変数、`this.double`、`.address`・`.selector`、空の関数値を呼ぶ |
| [code/main/src/Saver.sol](code/main/src/Saver.sol) | 外部の関数値を状態変数`cb`に保存する`Saver`、保存する関数を持つ`Target` |
| [code/main/src/Runner.sol](code/main/src/Runner.sol) | 関数型の引数`cb`を受け取って呼ぶ`Runner`、渡す関数を持つ`Alice`、`Bob` |
| [code/main/test/FnTypes.t.sol](code/main/test/FnTypes.t.sol) | 内部・外部の呼び出し、アドレスとセレクター、空の関数値、RunnerにAlice・Bobの関数を渡す |
| [code/main/test/Saver.t.sol](code/main/test/Saver.t.sol) | Target.checkを保存したあと0番の欄を読む |
| [code/bad/foundry.toml](code/bad/foundry.toml) | mainと同じ設定 |
| [code/bad/src/Bad.sol](code/bad/src/Bad.sol) | external関数の引数に内部の関数型（コンパイルエラー） |
| [code/bad/src/Bad2.sol](code/bad/src/Bad2.sol) | internal関数に`this.triple.selector`（コンパイルエラー） |

### 実行結果

関数型の欄のサイズ（`forge inspect FnTypes storageLayout`、`Saver storageLayout`）。内部の関数値は8バイト、外部の関数値は24バイトである。

```
| inner | function (uint256) pure returns (uint256)  | 0 | 0 | 8  | src/FnTypes.sol:FnTypes |
| outer | function (uint256) external returns (bool) | 0 | 8 | 24 | src/FnTypes.sol:FnTypes |

| cb | function (uint256) external returns (bool) | 0 | 0 | 24 | src/Saver.sol:Saver |
```

ABIでは、外部の関数型は`function`型として書かれる（`forge inspect FnTypes abi`、`--json`のouterの項目、`Runner abi --json`のcbの引数）：

```
| function | double(uint256) pure returns (uint256)                            | 0xeee97206 |
| function | outer() view returns (function (uint256) external returns (bool)) | 0x87c3dbb6 |

"outputs": [{ "name": "", "type": "function", "internalType": "function (uint256) external returns (bool)" }]

{ "name": "cb", "type": "function", "internalType": "function (uint256) external" }
```

`forge test`：

```
[PASS] test_save() (gas: 58784)
[FAIL: panic: called an invalid internal function (0x51)] test_emptyInner() (gas: 7988)
[FAIL: EvmError: Revert] test_emptyOuter() (gas: 29700)
[PASS] test_external() (gas: 10430)
[PASS] test_internal() (gas: 7105)
[PASS] test_parts() (gas: 17633)
[PASS] test_runAlice() (gas: 84511)
[PASS] test_runBob() (gas: 86818)
```

test_emptyInnerとtest_emptyOuterは、失敗する様子を見せるためのテストである。

内部の関数値で呼ぶとトレースに呼び出しの行ができず、`this.double`で呼ぶと外部呼び出しの行ができる（`forge test -vvvv --match-test test_internal`、`test_external`）：

```
  [7105] FnTypesTest::test_internal()
    ├─ [1404] FnTypes::useInternal(5) [staticcall]
    │   └─ ← [Return] 25
    └─ ← [Stop]

  [10430] FnTypesTest::test_external()
    ├─ [4684] FnTypes::useExternal(5) [staticcall]
    │   ├─ [907] FnTypes::double(5) [staticcall]
    │   │   └─ ← [Return] 10
    │   └─ ← [Return] 10
    └─ ← [Stop]
```

外部の関数値の`.address`と`.selector`（`--match-test test_parts`）。三つの行は、g.address、g.selector、FnTypesのアドレスである。

```
Logs:
  0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
  0xeee97206
  0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f

$ cast sig "double(uint256)"
0xeee97206
```

Target.checkをSaverに保存した結果（`--match-test test_save`）。欄には、アドレス20バイトとセレクター4バイトが続けてつながっている。

```
    ├─ [44351] Saver::save(0x2e234dae75c793f67a35089c9d99245e1c58470b5f72f450)
Logs:
  0x2e234DAe75C793f67A35089C9d99245E1C58470b
  0x00000000000000002e234dae75c793f67a35089c9d99245e1c58470b5f72f450

$ cast sig "check(uint256)"
0x5f72f450
```

同じ`run`にAliceの`onDone`とBobの`ping`を渡したトレース。runのコードはそのままなのに、実際に呼ばれたコードが違う（`onDone(uint256)`は`0x65b00ad8`、`ping(uint256)`は`0x773acdef`）。

```
0xA11CEのアカウント: r.run(5, a.onDone)
    ├─ [70478] Runner::run(5, 0xf62849f9a0b5bf2913b396098f7c7019b51a820a65b00ad8)
    │   ├─ [22492] Alice::onDone(10)
    │   │   └─ ← [Stop]
    │   └─ ← [Stop]

0xB0Bのアカウント: r.run(5, b.ping)
    ├─ [70551] Runner::run(5, 0x5991a2df15a8f6a256d3ec51e99254cd3fb576a9773acdef)
    │   ├─ [22565] Bob::ping(10)
    │   │   └─ ← [Stop]
    │   └─ ← [Stop]
```

test_runBobのトレースの`Bob::lastCaller()`の戻り値は`Runner: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]`である。Bobを呼んだのは0xB0Bのアカウントではなく、Runnerである。

何も入れていない関数値を呼んだ結果（`--match-test test_empty`）：

```
[FAIL: panic: called an invalid internal function (0x51)] test_emptyInner() (gas: 7988)
    ├─ [2649] FnTypes::callEmptyInner(1) [staticcall]
    │   └─ ← [Revert] panic: called an invalid internal function (0x51)

[FAIL: EvmError: Revert] test_emptyOuter() (gas: 29700)
    ├─ [24300] FnTypes::callEmptyOuter(1)
    │   ├─ [0] 0x0000000000000000000000000000000000000000::00000000(0000…0001)
    │   │   └─ ← [Stop]
    │   └─ ← [Revert] call to non-contract address 0x0000000000000000000000000000000000000000
```

`code/bad`でビルドした結果：

```
$ forge build src/Bad.sol
Error (4103): Internal type is not allowed for public or external functions.
 --> src/Bad.sol:5:29:
  |
5 |     function use(uint256 x, function (uint256) internal pure returns (uint256) f)
  |                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

$ forge build src/Bad2.sol
Error (9582): Member "triple" not found or not visible after argument-dependent lookup in contract Bad2.
  --> src/Bad2.sol:10:16:
   |
10 |         return this.triple.selector;
   |                ^^^^^^^^^^^
```

### 試すときの注意

- 関数型の既定はinternalである。内部の関数値は同じコントラクトの中のジャンプ位置なので8バイトで、外部の関数に引数として渡せない（エラー4103）。
- `this.f`で外部の形を作れるのは、public・external関数だけである。internal関数には`this.triple.selector`を使えない。
- 外部の関数値は、アドレス20バイトとセレクター4バイトで、合わせて24バイトである。ABIではbytes24と同じエンコードである。
- 関数型の値を引数として受け取ると、何が呼ばれるかは値を渡した側が決める。受け取る側のコードだけを見ても、どのコントラクトのどの関数が動くかはわからない。
- 空の内部の関数値を呼ぶとPanic 0x51、空の外部の関数値はアドレス0に呼び出しをして、返ってきた値がないので巻き戻る。
- 関数名に`apply`は使えない。予約語なので`Error (2314): Expected identifier but got reserved keyword 'apply'`になる。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると、数字とテストのアドレスが違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Types、Value TypesのFunction Typesの節、v0.8.36（internalが既定値、`this.f`で外部の形、`.address`・`.selector`、外部の関数型 = アドレス + セレクター） | 2026-10-19 |
| ABIのfunctionのエンコード | アドレス20バイト + セレクター4バイト、bytes24と同じエンコード | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast） | 1.8.3 | 2026-10-19 |
| 関数型の保存サイズ | 内部8バイト、外部24バイト（FnTypesのinner・outerが0番の欄のoffset 0・8） | 2026-10-19 |
| テストのガス | test_internal 7,105 / test_external 10,430 / test_save 58,784 / test_runAlice 84,511 / test_runBob 86,818 | 2026-10-19 |
| テストのアドレス | FnTypes・Saver `0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f`、Runner・Target `0x2e234DAe75C793f67A35089C9d99245E1C58470b`、Alice `0xF62849F9A0B5Bf2913b396098F7c7019b51A820a`、Bob `0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 内部呼び出しと外部呼び出しの違い全般 | [第82講](../../part5/lecture82/) |
| 渡された関数・アドレスを呼ぶときの判断 | [第83講](../../part5/lecture83/)、[第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/) |
| ライブラリの内部関数と関数型 | [第116講](../../part6/lecture116/) |
| 関数セレクターの計算とABIエンコードの詳細 | [第77講](../../part5/lecture77/)、[第92講](../../part6/lecture92/)、[第101講](../../part6/lecture101/) |
| 保存レイアウトで関数型の欄を読む | [第141講](../../part8/lecture141/) |
| ストレージの欄の配置のルール（スロット番号、まとめる順番） | [第135講](../../part8/lecture135/) |
| 参照型（配列、マッピング、構造体の詳細）、データの場所 | [第62講](../../part4/lecture62/)〜[第72講](../../part4/lecture72/) |
| レンディングプロトコルの権限チェックのコード | 第14・15章以降 |

出典と参考資料は[reference.md](reference.md)にまとめた。
