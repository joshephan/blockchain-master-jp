# 第121講 アセンブリの慣例とメモリの安全性

第7部 アセンブリとYul・第27章 インラインアセンブリ

[← 第120講](../../part7/lecture120/) | [第7部 目次](../) | [第122講 →](../../part7/lecture122/)

## この講義の問い

メモリは誰がどんなやり方で分け合って使っていて、アセンブリブロックはそのやり方をどう壊しうるのか。そして`memory-safe`の表示はコンパイラに何を知らせるのか。

## 実習資料

### 準備

Foundryのプロジェクトを三つ使う。`demo`は`forge init`で作ったプロジェクトに`Mem121.sol`・`Sig121.sol`を入れたもの、`deep`はvia-IRのビルド（`via_ir = true`、`optimizer = false`）をオンにした`Deep.sol`一つだけのプロジェクト、`market`は通しプロジェクトMarketの第121講のバージョンである。どれもsolc 0.8.30で、`demo`と`market`にはforge-std（`lib/forge-std`）が必要である。関数の呼び出しは、ローカルのanvilで新しく立ち上げたチェーンにアカウント0番がデプロイしてから`cast call`で行った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Mem121.sol](code/demo/src/Mem121.sol) | メモリの先頭の四つの欄の読み取り、マッピングを読んだあとのscratchの欄、0x40を動かさないブロックと動かすブロック、ゼロの欄、短い型に入れた300 |
| [code/demo/src/Sig121.sol](code/demo/src/Sig121.sol) | 署名のvの行を`byte(0, …)`で読むバージョンと抜いたバージョン |
| [code/deep/foundry.toml](code/deep/foundry.toml) | `via_ir = true`、`optimizer = false` |
| [code/deep/src/Deep.sol](code/deep/src/Deep.sol) | ローカル変数22個がループのあいだずっと生きている`deep`。ブロックは規則どおり0x40のうしろに書くバージョン |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第121講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第121講のバージョン。src内のアセンブリブロック0個 |
| [code/market/test/](code/market/test/) | Marketのテスト51個 |

`Deep.sol`は29行目のブロック1行だけを変えて、六つのバージョンをビルドした。

| バージョン | 29行目 |
|---|---|
| 表示なし、メモリに触らない | `assembly { let z := 1 }` |
| 表示なし、0x80に書く | `assembly { mstore(0x80, 5) }` |
| 表示あり、メモリに触らない | `assembly ("memory-safe") { let z := 1 }` |
| 表示あり、0x40のうしろに書く | `assembly ("memory-safe") { let p := mload(0x40) mstore(p, 5) }` |
| 表示あり、0x80に書く | `assembly ("memory-safe") { mstore(0x80, 5) }` |
| 表示あり、0x100に書く | `assembly ("memory-safe") { mstore(0x100, 5) }` |

`memory-safe`の表示の形は、関数本体に下のブロックを入れて`forge build`で確かめた。

| ブロック | 結果 |
|---|---|
| `/// @solidity memory-safe-assembly`のコメントのあとに`assembly { r := mload(0x40) }` | 通る |
| `assembly ("memorysafe") { r := mload(0x40) }` | Warning (4430) |
| `assembly { r := memoryguard(0x80) }` | Error (4619) `Function "memoryguard" not found.`、8678 |
| `assembly ("memory-safe") { mstore(0x40, 0) mstore(0x60, 7) r := 1 }` | 通る、警告なし |

### 実行結果

`Mem121`の関数（`cast call`の出力）。`afterMapping`にはアカウント1番のアドレスを入れた。

```
firstWords()     0 / 0 / 128 / 0
afterMapping()   0 / 642829559307850963015472508762062935916233390536 [6.428e47] / 1
noBump()         32 / 128 / 128
withBump()       4660 / 128 / 160
zeroSlot()       96 / 0
dirtyZeroSlot()  5
dirty()          44 / 300 / true
```

`afterMapping`の0x00の欄はマッピングのキーに使ったアカウント1番のアドレス、0x20の欄はマッピングのスロット番号1である。`noBump`は0x40を動かさないので、自分が書いた0x1234（4660）が`abi.encode`に上書きされて32になり、`withBump`は0x40を0x20だけ動かすので4660が残った。

`Sig121`（署名のバイト 0x11 × 32、0x22 × 32、0x1b）。

```
vByte(bytes)  27
vRaw(bytes)   0
              12212446911748192486079752325135052781399568695204278238536542063334587891712 [1.221e76]
```

`Deep`の六つのバージョン（正しい答えはdeep(3) 2618、deep(0) 253）。

| アセンブリブロック | ビルド | deep(3) / deep(0) |
|---|---|---|
| 表示なし、`let z := 1` | 通る | 2618 / 253 |
| 表示なし、`mstore(0x80, 5)` | 失敗 | なし |
| 表示あり、`let z := 1` | 通る | 2618 / 253 |
| 表示あり、`let p := mload(0x40) mstore(p, 5)` | 通る | 2618 / 253 |
| 表示あり、`mstore(0x80, 5)` | 通る、警告なし | 2618 / 256 |
| 表示あり、`mstore(0x100, 5)` | 通る、警告なし | 2578 / 251 |

ビルドした五つのバージョンはすべて、ランタイムコードが`0x610380604052`で始まる。0x40の欄の最初の値が0x80ではなく0x380である。失敗したバージョンのエラー。

```
Error: Compiler run failed:
Error: Cannot swap Variable var_x with Variable var_b17: too deep in the stack by 1 slots in [ var_x var_b2 var_x var_b0 var_x var_x var_x var_x var_b16 var_b15 var_b14 var_b13 var_b12 var_b11 var_b10 var_b9 var_b8 var_b7 var_b6 var_b5 var_b4 var_b3 var_b1 RET var_b17 ]
No memoryguard was present. Consider using memory-safe assembly only and annotating it via 'assembly ("memory-safe") { ... }'.
```

Market 第121講のバージョンは、`forge build --sizes`でruntime 7,353 / initcode 7,931バイト、`forge test`は51個がすべて通り、`grep -n assembly src/*.sol`は0行である。

### 試すときの注意

- `bytes memory empty;`のように値を与えていないmemory変数は0x60（ゼロの欄）を指す。ブロックで0x60に値を書くと、空のbytesの長さが5になる（`dirtyZeroSlot`）。
- `uint8`の変数にブロックで300を入れると、Solidityで読むときは44で、ブロックで読み直すと300が残っている。上位ビットは、メモリに書く直前か比較の直前にだけ消される。
- `memory-safe`の表示はコンパイラがチェックしない。規則を破ったブロックにつけても警告は出ない。
- コメントの形`/// @solidity memory-safe-assembly`は0.8.30では警告なしで通るが、0.8.31から非推奨の警告がつく。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| ツール | solc 0.8.30（optimizerは切る、既定のcodegen）、Foundry 1.8.3（forge・cast・anvil） | 2026-10-19 |
| Deepのビルド設定 | `via_ir = true`、`optimizer = false` | 2026-10-19 |
| `memory-safe`の表示の導入 | 0.8.13（2022-03-16） | 2026-10-19 |
| コメントの形`/// @solidity memory-safe-assembly` | 非推奨の警告は0.8.31（2025-12-03）から。0.8.30のビルドではFoundryの無視リストを空にしても警告なし。ドキュメント: "deprecated and scheduled for removal" | 2026-10-19 |
| アカウント0番・1番 | anvilの既定のアカウント（公開されたテスト用の鍵）、`--unlocked --from` | 2026-10-19 |
| Market 第121講のバージョン | runtime 7,353 / initcode 7,931バイト、テスト51個が通る、`grep -n assembly src/*.sol` 0行 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 呼び出しの入力・出力をメモリに置くこと | [第122講](../../part7/lecture122/) |
| メモリの配置の規則の全体（配列・構造体・bytesの形） | [第137講](../../part8/lecture137/) |
| via-IRとoptimizerの設定 | [第128講](../../part8/lecture128/)、[第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| メモリを節約してガスを減らす判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 監査でブロックのメモリの使い方を確かめる | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
