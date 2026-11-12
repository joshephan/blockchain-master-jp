# 第57講 固定サイズのバイト配列

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第56講](../../part4/lecture56/) | [第4部 目次](../) | [第58講 →](../../part4/lecture58/)

## この講義の問い

意味の決まっていないバイトの塊を、サイズだけ決めて入れる型は、この機械でどう入り、数値とどこで逆に動くのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める。テストにはforge-stdが必要である（`lib/forge-std`）。コンパイルエラーを見るファイルはsrcの外の`bad/`に置き、`forge build bad/<ファイル>.sol`で一つずつビルドする。anvilを立ち上げ、既定のアカウント0番（公開されたテスト用の鍵）でデプロイする。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/Slots.sol](code/src/Slots.sol) | bytes32が一つ（`OneWord`）、bytes4が四つ（`FourTags`）、同じ文字をbytes32とuint256で（`TextAndNumber`） |
| [code/src/Market.sol](code/src/Market.sol) | 名前のkeccak256を`bytes32 marketId`として保存するMarket |
| [code/test/Bytes.t.sol](code/test/Bytes.t.sol) | ハッシュ・文字・数値を入れたbytes32、セレクター、長さとインデックス、コピー、サイズの変換、ビット演算 |
| [code/bad/Bytes33.sol](code/bad/Bytes33.sol) | `bytes33`（コンパイルエラー） |
| [code/bad/HashToUint.sol](code/bad/HashToUint.sol) | ハッシュをuint256の変数に直接代入（コンパイルエラー） |
| [code/bad/IndexWrite.sol](code/bad/IndexWrite.sol) | `b[0] = 0x01`（コンパイルエラー） |
| [code/bad/AddBytes.sol](code/bad/AddBytes.sol) | bytes4どうしの`+`（コンパイルエラー） |
| [code/bad/LocalBytes.sol](code/bad/LocalBytes.sol) | ローカル変数の`bytes`に保存場所がない（コンパイルエラー） |

### 実行結果

`forge test -vv`：

```
Ran 6 tests for test/Bytes.t.sol:BytesTest
[PASS] test_Bits() (gas: 18544)
Logs:
  0x1200
  0xfff0
  0xedf0
  0xed0f
  0x2f00
  0x012f

[PASS] test_Copy() (gas: 6337)
Logs:
  0x11223344
  0x55667788

[PASS] test_LengthIndex() (gas: 13309)
Logs:
  h.length 32
  s.length 4
  0x9c
  0x78

[PASS] test_Selector() (gas: 3325)
Logs:
  0xa9059cbb

[PASS] test_Shrink() (gas: 12421)
Logs:
  0x1234
  22136
  0x12340000
  4660

[PASS] test_Three() (gas: 9356)
Logs:
  0x9c0257114eb9399a2985f8e75dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501
  0x616c6963652d7365637265740000000000000000000000000000000000000000
  0x00000000000000000000000000000000000000000000000000000000000003e8

Suite result: ok. 6 passed; 0 failed; 0 skipped
```

`bad/`の五つのファイルを一つずつビルドした結果：

```
bad/Bytes33.sol     Error (7920): Identifier not found or not unique.
bad/HashToUint.sol  Error (9574): Type bytes32 is not implicitly convertible to expected type uint256.
bad/IndexWrite.sol  Error (4360): Single bytes in fixed bytes arrays cannot be modified.
bad/AddBytes.sol    Error (2271): Built-in binary operator + cannot be applied to types bytes4 and bytes4.
bad/LocalBytes.sol  Error (6651): Data location must be "storage", "memory" or "calldata" for variable, but none was given.
```

欄の配置（`forge inspect <コントラクト> storageLayout`）：

```
| id   | bytes32 | 0 | 0 | 32 | src/Slots.sol:OneWord |

| a | bytes4 | 0 | 0  | 4 | src/Slots.sol:FourTags |
| b | bytes4 | 0 | 4  | 4 | src/Slots.sol:FourTags |
| c | bytes4 | 0 | 8  | 4 | src/Slots.sol:FourTags |
| d | bytes4 | 0 | 12 | 4 | src/Slots.sol:FourTags |

| s | bytes32 | 0 | 0 | 32 | src/Slots.sol:TextAndNumber |
| n | uint256 | 1 | 0 | 32 | src/Slots.sol:TextAndNumber |

| marketId | bytes32 | 0 | 0 | 32 | src/Market.sol:Market |
| paused   | bool    | 1 | 0 | 1  | src/Market.sol:Market |
```

anvilにデプロイして欄を読んだ結果。bytes4の四つは一つの欄の右から埋まり、同じ文字"abc"が、bytes32では左に、uint256では右に寄る。

```
$ cast send $O "set(bytes32)" $(cast keccak alice)
gasUsed              44078
$ cast storage $O 0
0x9c0257114eb9399a2985f8e75dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501

$ cast send $F "set()"
gasUsed              44388
$ cast storage $F 0
0x0000000000000000000000000000000044444444333333332222222211111111
$ cast call $F "c()"
0x3333333300000000000000000000000000000000000000000000000000000000

$ cast storage $T 0
0x6162630000000000000000000000000000000000000000000000000000000000
$ cast storage $T 1
0x0000000000000000000000000000000000000000000000000000000000616263

$ cast storage $M 0          # Marketを"ETH"でデプロイ
0xaaaebeba3810b1e6b70781f14b2d72c1cb89c0b2b320c43bb67ff79f562f5ff4
$ cast keccak "ETH"
0xaaaebeba3810b1e6b70781f14b2d72c1cb89c0b2b320c43bb67ff79f562f5ff4
```

同じ32バイトを、どう読むかによって値が変わる：

```
$ cast parse-bytes32-string 0x616c6963652d7365637265740000000000000000000000000000000000000000
alice-secret
$ cast to-dec 0x616c6963652d7365637265740000000000000000000000000000000000000000
44065893158629277056013394397909591327729243779337382038371802066394867040256
$ cast to-hex 22136
0x5678
$ cast to-hex 4660
0x1234
$ cast sig "transfer(address,uint256)"
0xa9059cbb
```

### 試すときの注意

- `bytesN`は1から32までしかない。`bytes33`は存在しない型である。
- バイト配列は左寄せ、整数は右寄せである。サイズを縮めると、bytesは右を、整数は左を捨てる（`bytes2(bytes4(0x12345678))`は0x1234、`uint16(uint32(0x12345678))`は0x5678）。
- 固定サイズのバイト配列は値型である。代入するとコピーされ、`b[i]`で読むことはできても、1バイトだけを直すことはできない。算術演算もなく、ビット演算だけがある。
- ハッシュを数値として使うには、`uint256(...)`で明示的に変える。
- `cast call ... "c()"`が返す値はABIエンコードなので、bytes4が左に寄って出る。欄の中では、cはoffset 8の場所（右から3番目の4バイト）にある。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のFixed-size byte arrays、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| 初めて書くsetのgasUsed | OneWord（bytes32が一つ）44,078 / FourTags（bytes4が四つ）44,388 | 2026-10-19 |
| テストのガス | test_Three 9,356 / test_Selector 3,325 / test_Copy 6,337 / test_LengthIndex 13,309 / test_Shrink 12,421 / test_Bits 18,544 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 16進リテラルをbytesNに入れるルール（桁数が合っている必要がある） | [第58講](../../part4/lecture58/) |
| 文字列リテラルをbytes32に入れる、32バイトを超える文字 | [第59講](../../part4/lecture59/) |
| データの場所（storage、memory、calldata） | [第62講](../../part4/lecture62/)、[第63講](../../part4/lecture63/)、[第64講](../../part4/lecture64/) |
| 固定サイズの配列（`uint[3]`のようなもの）とbytesNの違い | [第65講](../../part4/lecture65/) |
| bytesとstring | [第68講](../../part4/lecture68/) |
| bytesNと整数、違うサイズのあいだの明示的な変換のルール全体 | [第73講](../../part4/lecture73/) |
| ABIエンコード・デコードの関数 | [第78講](../../part5/lecture78/) |
| ストレージの欄の配置のルール（offset 0が右端、まとめて入れる条件） | [第135講](../../part8/lecture135/) |
| ABIエンコードのルールとセレクターの計算 | [第141講](../../part8/lecture141/) |
| 欄の配置でガスを減らす | [第143講](../../part9/lecture143/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
