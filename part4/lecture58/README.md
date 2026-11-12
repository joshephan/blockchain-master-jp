# 第58講 リテラル ①：有理数・整数・16進

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第57講](../../part4/lecture57/) | [第4部 目次](../) | [第59講 →](../../part4/lecture59/)

## この講義の問い

コードにそのまま書き込んだ数値は、いつ型が決まり、コンパイル時に計算される式は実行時と何が違うのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める。テストにはforge-stdが必要である（`lib/forge-std`）。コンパイルエラーを見せるファイルは`bad/`に別に置き、`forge build bad/<ファイル>`で一つずつビルドする。実行はすべて`forge test`の中で行うので、anvilは立ち上げない。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/SameOne.sol](code/src/SameOne.sol) | 同じリテラル1を、uint8、uint256、int8、bytes1の欄に入れたコントラクト |
| [code/src/Notation.sol](code/src/Notation.sol) | 指数表記、アンダースコア、負の数、シフト、16進、小数の掛け算など、リテラルの表記9種類 |
| [code/src/AddHundred.sol](code/src/AddHundred.sol) | uint8の変数にリテラル100を足す版と、先にuint256に広げる版 |
| [code/src/Rational.sol](code/src/Rational.sol) | リテラルどうしの大きな計算、`0.5 * 4`、変数を2で割る |
| [code/src/Both.sol](code/src/Both.sol) | リテラルどうしの`200 + 100` |
| [code/src/Half.sol](code/src/Half.sol) | `0.25 * 1000`を返す関数（バイトコードの確認用） |
| [code/test/Literal.t.sol](code/test/Literal.t.sol) | AddHundredとRationalの結果 |
| [code/test/Both.t.sol](code/test/Both.t.sol) | `literalsOnly()`の結果 |
| [code/test/Notation.t.sol](code/test/Notation.t.sol) | Notationの九つの値とSameOneの五つの値 |
| [code/bad/Bad256.sol](code/bad/Bad256.sol) | `uint8 x = 256`（コンパイルエラー） |
| [code/bad/BadBytes1.sol](code/bad/BadBytes1.sol) | `bytes1 d = 1`（コンパイルエラー） |
| [code/bad/BadDiv.sol](code/bad/BadDiv.sol) | `uint x = 5 / 2`（コンパイルエラー） |
| [code/bad/BadFixed.sol](code/bad/BadFixed.sol) | `ufixed8x1 x = 5 / 2`（コンパイルエラー） |
| [code/bad/BadShift.sol](code/bad/BadShift.sol) | `uint256 x = 1 << 256`（コンパイルエラー） |
| [code/bad/BadBytes.sol](code/bad/BadBytes.sol) | `bytes2 y = 0x12`（コンパイルエラー） |
| [code/bad/BadAddr.sol](code/bad/BadAddr.sol) | チェックサムのない40桁の16進をuint160に（コンパイルエラー） |

### 実行結果

同じ1が、型ごとに違うサイズで保存される（`forge inspect SameOne storageLayout`）：

```
| a    | uint8   | 0    | 0      | 1     | src/SameOne.sol:SameOne |
| b    | uint256 | 1    | 0      | 32    | src/SameOne.sol:SameOne |
| c    | int8    | 2    | 0      | 1     | src/SameOne.sol:SameOne |
| d    | bytes1  | 2    | 1      | 1     | src/SameOne.sol:SameOne |
| max8 | uint8   | 2    | 2      | 1     | src/SameOne.sol:SameOne |
```

`bad/`のファイルを一つずつビルドした結果：

```
bad/Bad256.sol
Error (7407): Type int_const 256 is not implicitly convertible to expected type uint8. Literal is too large to fit in uint8.

bad/BadBytes1.sol
Error (7407): Type int_const 1 is not implicitly convertible to expected type bytes1.

bad/BadDiv.sol
Error (4486): Type rational_const 5 / 2 is not implicitly convertible to expected type uint256. Try converting to type ufixed8x1 or use an explicit conversion.

bad/BadFixed.sol
Error (1834): Not yet implemented - FixedPointType.

bad/BadShift.sol
Error (7407): Type int_const 1157...(70 digits omitted)...9936 is not implicitly convertible to expected type uint256. Literal is too large to fit in uint256.

bad/BadBytes.sol
Error (7407): Type int_const 18 is not implicitly convertible to expected type bytes2.

bad/BadAddr.sol
Error (9429): This looks like an address but has an invalid checksum. Correct checksummed address: "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf". If this is not used as an address, please prepend '00'. For more information please see https://docs.soliditylang.org/en/develop/types.html#address-literals
Error (7407): Type address is not implicitly convertible to expected type uint160.
```

`forge test -vvvv`（ログとトレースの一部）：

```
[PASS] test_AddHundred155() (gas: 9521)
  255
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_AddHundred200() (gas: 5964)
  [5964] LiteralTest::test_AddHundred200()
    ├─ [595] AddHundred::addHundred(200) [staticcall]
    │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
[PASS] test_AddHundredWide200() (gas: 9465)
  300
[PASS] test_Rational() (gas: 26390)
  1
  2
  2
[PASS] test_LiteralsOnly() (gas: 7397)
  300
[PASS] test_Notation() (gas: 77474)
  1000000000000000000
  25
  1000000
  -1
  57896044618658097711785492504343953926634992332820282019728792003956564819968
  255
  255
  0x1234
  3000000000000000
[PASS] test_SameOne() (gas: 43649)
  1
  1
  -1
  0x01
  255
```

`0.25 * 1000`はコンパイル時に計算され、バイトコードに250がそのまま入る（`forge inspect Half deployedBytecode`を`cast disassemble`でほどく、一部）：

```
00000044: JUMPDEST
00000045: PUSH0
00000046: PUSH1 0xfa
00000048: SWAP1
00000049: POP
0000004a: SWAP1
0000004b: JUMP
$ cast to-dec 0xfa
250
```

### 試すときの注意

- リテラルどうしの計算は、コンパイラが範囲の制限なしに正確に行う。`(2**800 + 1) - 2**800`は1、`0.5 * 4`は2で、結果が整数で、代入する型に収まれば通過する。
- リテラルと変数が混ざると、変数の型で計算する。uint8の`a + 100`はuint8で計算され、aが200ならPanic 0x11で巻き戻る。結果をuint256の変数に入れても同じで、`uint256(a) + 100`のように先に広げる必要がある。
- 整数でない結果（`5 / 2`）は整数型に入れられない（エラー4486）。変数どうしの`a / 2`は切り捨てで2になる。
- 16進リテラルをbytesNに入れるには、桁数が正確に合っている必要がある。`bytes2`に`0x12`は入らない。
- 40桁の16進リテラルはアドレスとして読まれる。チェックサムが違うとエラー9429が出て、アドレスではない数値として使うなら先頭に`00`をつけるよう案内される。

## 時効性のあるデータ

基準日時点の値。コンパイラのバージョンが変わると、エラーコードと出力が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のRational and Integer Literals、Hexadecimal Literals、Address Literals、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast）のバージョン | 1.8.3 | 2026-10-19 |
| エラーコード | 7407（暗黙的な変換ができない）、4486（rational_const）、9429（アドレスのチェックサム） | 2026-10-19 |
| addHundred(200)の巻き戻し | panic 0x11、呼び出しのガス595 | 2026-10-19 |
| Half.half()のバイトコード | 0x46の位置に`PUSH1 0xfa` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 文字列リテラル、Unicodeリテラル、hex文字列リテラル | [第59講](../../part4/lecture59/) |
| アドレスリテラルのルール全体（チェックサム、39〜41桁） | [第59講](../../part4/lecture59/) |
| 暗黙的・明示的な変換のルール全体（リテラルと変数の共通の型） | [第73講](../../part4/lecture73/)、[第74講](../../part4/lecture74/) |
| イーサの単位と時間の単位（`1 ether`、`1 days`） | [第75講](../../part5/lecture75/) |
| 定数（`constant`、`immutable`）がコンパイル時の値になるルール | [第102講](../../part6/lecture102/) |
| あふれチェックとuncheckedを使う場所 | [第88講](../../part5/lecture88/)、[第89講](../../part5/lecture89/) |
| 配列リテラル、文字列リテラルの型の決まり方 | [第67講](../../part4/lecture67/) |
| 演算子の優先順位 | [第126講](../../part7/lecture126/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
