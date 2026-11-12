# 第67講 memoryの配列、new、配列リテラル

第4部 言語の詳細 ① ファイルと型・第14章 参照型

[← 第66講](../../part4/lecture66/) | [第4部 目次](../) | [第68講 →](../../part4/lecture68/)

## この講義の問い

関数の中で一時的に使う配列は、なぜ作るときに長さを決めなければならず、角かっこで書いたリストはどんな型になるのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクト（`demo/`）から、Counterのファイルを消して始める。コンパイルが拒否される例は別のプロジェクト`bad/`に置き、ファイルごとに`forge build --offline src/<ファイル>.sol`でビルドする（foundry.tomlは同じ）。テストにはforge-stdが必要である（`lib/forge-std`）。デプロイは、ローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を使って行う。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/demo/src/MemArr.sol](code/demo/src/MemArr.sol) | `new`で長さnの配列を作る、フリーメモリポインター（0x40）の前後の値、二つの配列の位置、memoryの別名、偶数だけを選んで入れる（`evens`）、配列リテラル |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しのプロジェクトのMarketの草案。資産リストごとの残高をmemory配列に入れて返す`reserves()`と、テスト用のトークン |
| [code/demo/test/MemArr.t.sol](code/demo/test/MemArr.t.sol) | 上の関数を呼び、値をログに出すテスト |
| [code/bad/foundry.toml](code/bad/foundry.toml) | demoと同じ設定 |
| [code/bad/src/](code/bad/src/) | memory配列のpush・lengthへの代入、配列リテラルの型の例11個 |

`code/bad/src/`のファイルと結果：

| ファイル | 行 | 結果 |
|---|---|---|
| Push.sol | 長さなしで宣言したmemory配列に`r.push(xs[i])` | Error (4994) |
| Len.sol | `r.length = 5;` | Error (7567) |
| Lit1.sol | `uint256[3] memory a = [1, 2, 3];` | Error (9574) |
| Lit2.sol | `uint256[] memory b = [uint256(1), 2, 3];` | Error (9574) |
| Lit3.sol | `int8[2] memory c = [1, -1];` | Error (6378) |
| Lit4.sol | `int8[2] memory c = [int8(1), -1];` | ビルド成功 |
| Lit5.sol | `uint8[2] memory c = [1, 300];` | Error (9574)、`uint16[2]` |
| Lit6.sol | `uint8[2] memory c = [300, 1];` | Error (9574)、`uint16[2]` |
| Lit7.sol | `uint8[2] memory c = [-1, 1];` | Error (9574)、`int8[2]` |
| Lit8.sol | `int256[3] memory a = [int256(1), 2, -3];` | ビルド成功 |
| Lit9.sol | `int8[2] memory c = [-1, 1];` | ビルド成功 |

### 実行結果

`forge test --offline -vv`：

```
[PASS] test_alias() (gas: 6126)
[PASS] test_evens() (gas: 28483)
Logs:
  3
  8
  12
  40
[PASS] test_freePtr() (gas: 16065)
Logs:
  0x0000000000000000000000000000000000000000000000000000000000000080
  0x0000000000000000000000000000000000000000000000000000000000000100
  128
[PASS] test_make() (gas: 28410)
Logs:
  5
  0
  0
  0
  0
  0
[PASS] test_market() (gas: 349117)
Logs:
  100
  2500
  7
[PASS] test_twoArrays() (gas: 15816)
Logs:
  128
  256
  352
```

`forge inspect --offline Market storageLayout`：

```
| assets | contract IERC20[] | 0 | 0 | 32 | src/Market.sol:Market |
```

anvilにMemArrをデプロイし（`0x5FbDB2315678afecb367f032d93F642f64180aa3`）、`cast call`で呼んだ結果：

```
$ cast call <MemArr> "make(uint256)(uint256[])" 5
[0, 0, 0, 0, 0]
$ cast call <MemArr> "make(uint256)(uint256[])" 0
[]
$ cast call <MemArr> "freePtr(uint256)(uint256,uint256)" 3
128
256
$ cast call <MemArr> "freePtr(uint256)(uint256,uint256)" 10
128
480
$ cast call <MemArr> "twoArrays()(uint256,uint256,uint256)"
128
256
352
$ cast call <MemArr> "alias7()(uint256)"
7
$ cast call <MemArr> "evens(uint256[])(uint256[])" "[3,8,5,12,7,40]"
[8, 12, 40]
$ cast call <MemArr> "literal()(uint8[3])"
[1, 2, 3]
$ cast call <MemArr> "literalFixed()(uint256[3])"
[1, 2, 3]
```

`cast send <MemArr> "make(uint256)" <n> --json`のgasUsedは、10：24911、100：49293、1000：300089、10000：3504018である。

`bad/`で`forge build --offline src/<ファイル>.sol`：

```
$ forge build --offline src/Push.sol
Error (4994): Member "push" is not available in uint256[] memory outside of storage.
$ forge build --offline src/Len.sol
Error (7567): Member "length" is read-only and cannot be used to resize arrays.
$ forge build --offline src/Lit1.sol
Error (9574): Type uint8[3] memory is not implicitly convertible to expected type uint256[3] memory.
$ forge build --offline src/Lit2.sol
Error (9574): Type uint256[3] memory is not implicitly convertible to expected type uint256[] memory.
$ forge build --offline src/Lit3.sol
Error (6378): Unable to deduce common type for array elements.
$ forge build --offline src/Lit4.sol
Compiler run successful!
$ forge build --offline src/Lit5.sol
Error (9574): Type uint16[2] memory is not implicitly convertible to expected type uint8[2] memory.
$ forge build --offline src/Lit6.sol
Error (9574): Type uint16[2] memory is not implicitly convertible to expected type uint8[2] memory.
$ forge build --offline src/Lit7.sol
Error (9574): Type int8[2] memory is not implicitly convertible to expected type uint8[2] memory.
$ forge build --offline src/Lit8.sol
Compiler run successful!
$ forge build --offline src/Lit9.sol
Compiler run successful!
```

### 試すときの注意

- 公式ドキュメントは、配列リテラルの要素の型はリストの最初の式の型を基準に決まると書いている。solc 0.8.30の実際の出力は違う。`[1, 300]`と`[300, 1]`はどちらも`uint16[2]`、`[-1, 1]`は`int8[2]`で、`[1, -1]`だけがエラー6378である（同じ二つの値でも、順番によって分かれる）。
- フリーメモリポインター（0x40）の最初の値は0x80（128）である。長さ3の配列を作ると、長さの欄一つと要素の欄三つ、32バイト四つ分だけ増えて0x100（256）になる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、数字とエラーの文言が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Types、Reference TypesのAllocating Memory Arrays・Array Literals・Array Membersの節、v0.8.36（memory配列はサイズを変えられない・`.push`なし、新しい配列の要素は既定値、リテラルは常に固定サイズのmemory配列、`[1, 2, 3]`は`uint8[3] memory`、`[1, -1]`は不可、固定サイズのmemory配列を動的なmemory配列に代入できない） | 2026-10-19 |
| ドキュメントと実際の出力が違う箇所 | ドキュメント：要素の型はリストの最初の式の型が基準。solc 0.8.30の実際：`[1, 300]`と`[300, 1]`はどちらも`uint16[2]`、`[-1, 1]`は`int8[2]`、`[1, -1]`だけがエラー6378 | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| フリーメモリポインターの最初の値 | 0x80（128） | 2026-10-19 |
| make(n)のgasUsed | 10：24,911 / 100：49,293 / 1,000：300,089 / 10,000：3,504,018（トランザクションの基本21,000と戻り値のエンコードを含む） | 2026-10-19 |
| テストのガス | test_make 28,410 / test_freePtr 16,065 / test_twoArrays 15,816 / test_alias 6,126 / test_evens 28,483 / test_market 349,117 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `new`でコントラクトをデプロイする | [第84講](../../part5/lecture84/) |
| アセンブリの文法と`mload` | [第119講](../../part7/lecture119/) |
| 多めに確保して長さの欄を縮めるアセンブリの形 | [第119講](../../part7/lecture119/)、[第120講](../../part7/lecture120/)、[第121講](../../part7/lecture121/) |
| メモリの配置のルール全体（予約区間、0x40の管理） | [第137講](../../part8/lecture137/) |
| メモリ拡張のガスの公式 | [第137講](../../part8/lecture137/)、[第143講](../../part9/lecture143/) |
| 型変換のルール全般 | [第73講](../../part4/lecture73/) |
| `bytes`・`string`と文字列リテラル | [第68講](../../part4/lecture68/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
