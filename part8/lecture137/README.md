# 第137講 メモリの配置

第8部 コンパイラと内部構造・第33章 保存配置の内部

[← 第136講](../../part8/lecture136/) | [第8部 目次](../) | [第138講 →](../../part8/lecture138/)

## この講義の問い

Solidityはメモリに値をどんな形で置き、その場所はいつできていつまで残り、なぜストレージと形が違うのか。

## 実習資料

### 準備

0x40の欄（フリーメモリポインタ）を読んでメモリの配置を見るデモのプロジェクト（`demo`）と、通しプロジェクトMarketの第137講のバージョン（第136講のバージョンとコードが同じで、バージョンを説明するコメントを1行だけ足したバージョン）を使う。solc 0.8.30、Foundry 1.8.3で、forge-stdが必要である（`lib/forge-std`）。どちらのプロジェクトもoptimizerを切り、evm_versionはosakaである。Marketのメモリは、ローカルのanvil（`--steps-tracing`）にアカウント0番でMockTokenとMarketをデプロイし、`debug_traceTransaction`でメモリの記録をオンにして（enableMemory）、Marketが動く深さ1の値を見る。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモのプロジェクトの設定 |
| [code/demo/src/Mem137.sol](code/demo/src/Mem137.sol) | `fp()`で0x40の欄を読む関数の集まり: sizes、nested、front、neverFreed、afterEmit、expand。アセンブリは0x40の欄と決めたアドレスを読むだけである |
| [code/demo/test/Mem137.t.sol](code/demo/test/Mem137.t.sol) | 上の関数の結果を出すテスト |
| [code/demo/test/Mem137x.t.sol](code/demo/test/Mem137x.t.sol) | Mem137x: メモリの`uint8[10]`のサイズ、長さ100の`uint8[]`・`bytes`、長さだけを決めた`uint[][]`の内側の欄 |
| [code/market/](code/market/) | Market 第137講のバージョン（foundry.toml、src、test）。テスト58個 |

### 実行結果

Marketの作成のコードとランタイムコードの最初の命令。

```
$ forge inspect src/Market.sol:Market bytecode | cut -c1-24
0x60e060405234801561000f
$ forge inspect src/Market.sol:Market deployedBytecode | cut -c1-24
0x608060405234801561000f
```

作成のコードは`PUSH1 0xe0 PUSH1 0x40 MSTORE`、ランタイムは`PUSH1 0x80 PUSH1 0x40 MSTORE`で始まる。`forge inspect src/Market.sol:Market assembly`を見ると、コンストラクタはimmutable三つ（admin 0x80、collateralRatio 0xa0、interestRate 0xc0）をランタイムコードに入れる前に、しばらくメモリに置く。

```
  mstore(0x40, 0xe0)
  …
tag_11:
  mload(0x80)
  mload(0xa0)
  mload(0xc0)
  codecopy(0x00, dataOffset(sub_0), dataSize(sub_0))
  0x00
  assignImmutable("0x97798a7c…")
  0x00
  assignImmutable("0xbd868131…")
  0x00
  assignImmutable("0x6ca54da2…")
  return(0x00, dataSize(sub_0))
sub_0: assembly {
      mstore(0x40, 0x80)
```

デモのプロジェクトで`forge test --match-path test/Mem137.t.sol --match-test test_sizes -vv`（値を一つ作る前とあとの0x40の欄の差）。

```
  start 128
  uint8[4] 128
  uint8[] new(4) 160
  bytes1[] new(4) 160
  bytes new(4) 64
  string abc 64
  struct S 128
```

`struct S { uint a; uint b; uint8 c; uint8 d; }`である。同じ宣言がストレージでは、`forge inspect src/Mem137.sol:Mem137 storageLayout`で見るとSが96バイト（スロット三つ）、`uint8[4]`が32バイト（スロット一つ）である。Mem137xでは、メモリの`uint8[10]`が320バイト、長さ100で作った`uint8[]`が3,232バイト、`bytes`が160バイトである。

`test_nested`（`uint[][]`の中に長さ1・2の配列、32バイトの欄を縮めて先頭の八つの欄だけ）。

```
  x at 128
  128  0x…0002
  160  0x…00e0
  192  0x…0120
  224  0x…0001
  256  0x…00a0
  288  0x…0002
  320  0x…00b0
  352  0x…00b1
```

0xa0・0xc0の欄には、内側の配列の開始アドレス（0xe0、0x120）が入っている。内側の配列を作る前は、二つの欄とも0x60（ゼロの欄）を指す（`test_inner`: `x[0] slot 96`、`x[1] slot 96`）。

`test_neverFreed`（長さ10の`uint[]`を`new`で作る内部関数を3回呼びながら0x40の欄を読む）。

```
  128 480
  832 1184
```

`test_afterEmit`（イベントのデータ96バイトを出したあとのポインタと、そのうしろの二つの欄）。

```
  fp before/after emit 128 128
  0x0000000000000000000000000000000000000000000000000000000000000007
  0x0000000000000000000000000000000000000000000000000000000000000008
```

`test_expand`（関数の中のgasleftの差）と、メモリを広げるガスの式（欄の数がaのとき3 × a + a² ÷ 512、最初の四つの欄の値を引いた差）。

| n（バイト） | 測ったガス | 前の行との比 | 広げるガス（式） |
|---|---|---|---|
| 32 | 263 | | 6 |
| 1,024 | 451 | | 101 |
| 32,768 | 8,469 | | 5,143 |
| 65,536 | 20,777 | 2.45倍 | 14,379 |
| 131,072 | 57,681 | 2.78倍 | 45,139 |
| 262,144 | 180,641 | 3.13倍 | 155,811 |

Marketをanvilにデプロイし、順に送ったトランザクションの深さ1のメモリ。

| トランザクション | Marketのメモリの最大 | 0x40の欄 | メモリを使う命令（アドレス、長さ） |
|---|---|---|---|
| addAsset 75 | 224バイト | 0x80 → 0xc0 | `LOG2(0xc0, 0x20)` |
| deposit 100 | 256バイト | 0x80 → 0xa0 | `CALL`の入力`(0x80, 0x64)`・戻り`(0x80, 0x20)`、`LOG3(0xa0, 0x20)` |
| withdraw 30 | 224バイト | 0x80 → 0xa0 | `CALL`の入力`(0x80, 0x44)`・戻り`(0x80, 0x20)`、`LOG3(0xa0, 0x20)` |
| setStatus 1 / 0 | 192バイト | 0x80 | `LOG1(0x80, 0x40)` |
| deposit 0（失敗） | 160バイト | 0x80 | `REVERT(0x80, 0x4)`、リバートデータ`0x1f2a2005` |
| withdraw 999（失敗） | 224バイト | 0x80 | `REVERT(0x80, 0x44)`、リバートデータ`0x25c3f46e…` |

deposit 100が終わったあとのメモリ。

| アドレス | 値 | 意味 |
|---|---|---|
| 0x00 | `…5fbdb2315678afecb367f032d93f642f64180aa3` | トークンのアドレス（ハッシュの材料） |
| 0x20 | 4 | totalDepositsのスロット番号（ハッシュの材料） |
| 0x40 | 0xa0 | フリーメモリポインタ |
| 0x60 | 0 | ゼロの欄 |
| 0x80 | 1 | transferFromの戻り値true |
| 0xa0 | 0x64 | Depositedイベントのデータamount 100、ポインタは動かさない |
| 0xc0 | `bb3f0512 000…` | transferFromの入力の残りの部分（Marketのアドレスの末尾4バイト） |
| 0xe0 | `00000064 000…` | transferFromの入力の残りの部分（amountの末尾4バイト） |

Market 第137講のバージョンのビルドとテスト。

```
$ forge build --offline --force --sizes
| Market      | 7,353            | 7,931             | 17,223             | 41,221              |
$ forge test --offline
Ran 17 test suites …: 58 tests passed, 0 failed, 0 skipped (58 total tests)
```

### 試すときの注意

- メモリの先頭の四つの欄は、ハッシュ用のscratchの二つの欄（0x00〜0x3f）、フリーメモリポインタ（0x40）、ゼロの欄（0x60）で、Solidityの値は0x80から置かれる。コンストラクタは、immutableの値を入れておく場所のために、0x80ではないところ（Marketは0xe0）から始まることがある。
- メモリの配列の要素は、小さな型でも32バイトずつ占める（`bytes1[]`も同じ）。`bytes`と`string`だけが中身を詰めて入れる。
- 確保したメモリは、その外部呼び出しが終わるまで返さない。内部関数が終わっても、0x40の欄はそのままである。
- メモリを広げるガスには、サイズの2乗に比例する項があるので、サイズより速く増える。
- フリーメモリポインタのうしろのメモリが0だと信じてはいけない。コンパイラがイベントのデータや呼び出しの入力を一時的に書いて、ポインタを動かさなかった場所かもしれない（afterEmit、deposit 100の終わりのメモリ）。
- アセンブリブロックでメモリのアドレスを数字で埋め込まず、0x40の欄を読んで使う。via-IRのビルドでは、コンパイラが変数を移しておいた欄のために、開始アドレスが0x80でないことがある。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンやソースのコメントが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30（forgeが呼ぶ、evm_version osaka、optimizerは切る） | 2026-10-20 |
| Foundry（forge・anvil） | 1.8.3 | 2026-10-20 |
| メモリを広げるガスの式 | 欄（32バイト）の数がaのとき3 × a + a² ÷ 512（切り捨て）、広がった分の差 | 2026-10-20 |
| Mem137の値 | start 128、uint8[4] 128、uint8[]・bytes1[] new(4) 160、bytes new(4) 64、string "abc" 64、S 128 / neverFreed 128・480・832・1184 / afterEmit 128・128、7・8 / Mem137x uint8[10] 320、長さ100の`uint8[]` 3,232・`bytes` 160、長さだけを決めた内側の欄96・96 | 2026-10-20 |
| expand(n)のガス | 32 263、1,024 451、32,768 8,469、65,536 20,777、131,072 57,681、262,144 180,641（関数の中のgasleftの差、optimizerは切る） | 2026-10-20 |
| storageLayout | Mem137のstored(S)はスロット0で96バイト、storedArr(uint8[4])はスロット3で32バイト / Mem137xのstoredM(uint8[10])はスロット0で32バイト | 2026-10-20 |
| Marketの最初の命令 | 作成のコード`0x60e0604052`、ランタイム`0x6080604052`、immutable三つは0x80（admin）・0xa0（collateralRatio）・0xc0（interestRate） | 2026-10-20 |
| Marketのメモリ | 深さ1のメモリの最大: addAsset 75 224、deposit 100 256（深さ2のMockTokenは160）、withdraw 30 224（深さ2は160）、setStatus 1・0 192、deposit 0 160、withdraw 999 224。gasUsed 93,730 / 130,478 / 59,911 / 45,732 / 23,820 / 26,869 / 27,195 | 2026-10-20 |
| Market 第137講のバージョン | runtime 7,353 / creation 7,931、テスト58個、srcに`assembly`なし、deposit 0のリバートはsrc/Market.solの147行目 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| calldataの配置と変数のクリーンアップ | [第138講](../../part8/lecture138/) |
| ABIエンコードがメモリに置く形 | [第141講](../../part8/lecture141/) |
| メモリを節約してガスを減らす判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| via-IRが変数をメモリに移す場所とoptimizer | [第139講](../../part8/lecture139/)、[第140講](../../part8/lecture140/)、[第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 監査でアセンブリブロックのメモリの使い方を確かめる | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
