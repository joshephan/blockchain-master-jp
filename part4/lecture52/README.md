# 第52講 整数の演算とシフト

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第51講](../../part4/lecture51/) | [第4部 目次](../) | [第53講 →](../../part4/lecture53/)

## この講義の問い

同じ式を順番だけ変えて書いたのに、なぜ違う答えが出て、シフトは掛け算と何が違うのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める（`code/main`）。ローカルチェーンは使わず、すべて`forge test`で実行する。テストにはforge-stdが必要である（`lib/forge-std`）。数値どうしで書いたシフトがコンパイルされないことは、別に作ったプロジェクト（`code/literal`）で確かめる。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/main/foundry.toml](code/main/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/main/src/Fee.sol](code/main/src/Fee.sol) | 0.3%の手数料を、掛け算を先に（`mulFirst`）、割り算を先に（`divFirst`）計算 |
| [code/main/src/Small.sol](code/main/src/Small.sol) | uint8で4分の3を二つの順番で計算 |
| [code/main/src/IntOps.sol](code/main/src/IntOps.sol) | 割り算、余り、符号付きの割り算、int8の符号反転、べき乗 |
| [code/main/src/DivUnchecked.sol](code/main/src/DivUnchecked.sol) | `unchecked`の中のゼロ除算 |
| [code/main/src/Shift.sol](code/main/src/Shift.sol) | uint8の掛ける2と`<< 1`、int256の割る2と`>> 1`、大きなシフト |
| [code/main/src/Double.sol](code/main/src/Double.sol) | 2倍を`* 2`、`<< 1`、`unchecked { * 2 }`で作った三つのコントラクト |
| [code/main/test/Fee.t.sol](code/main/test/Fee.t.sol) | 二つの順番の結果表、大きな金額、uint8版 |
| [code/main/test/IntOps.t.sol](code/main/test/IntOps.t.sol) | ゼロ除算、符号付きの割り算・余り、int8の最小値、べき乗 |
| [code/main/test/DivUnchecked.t.sol](code/main/test/DivUnchecked.t.sol) | `unchecked`でもゼロ除算のチェックが外れないことの確認 |
| [code/main/test/Shift.t.sol](code/main/test/Shift.t.sol) | シフトと掛け算・割り算の比較 |
| [code/main/test/ShiftGas.t.sol](code/main/test/ShiftGas.t.sol) | 2倍にする三つの関数のガスの比較 |
| [code/literal/foundry.toml](code/literal/foundry.toml) | 別プロジェクトの設定（mainと同じ） |
| [code/literal/src/Literal.sol](code/literal/src/Literal.sol) | `return 1 << 256;`（コンパイルエラー） |

### 実行結果

`forge test --match-contract FeeTest -vv`。表の三つの数字は、金額、掛け算が先の結果、割り算が先の結果である。

```
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_BigMulFirst() (gas: 19214)
Logs:
  amount 1000000000000000000000000000000000000000000000000000000000000000000000000000
  divFirst 997000000000000000000000000000000000000000000000000000000000000000000000000

[PASS] test_SmallDivFirst() (gas: 16523)
Logs:
  divFirst(200) 150
  divFirst(201) 150

[FAIL: panic: arithmetic underflow or overflow (0x11)] test_SmallMulFirst() (gas: 12465)
Logs:
  mulFirst(80) 60

[PASS] test_Table() (gas: 96928)
Logs:
  999 996 0
  1000 997 997
  1500 1495 997
  1999 1993 997
  2000 1994 1994
  12345 12307 11964
```

`forge test --match-contract IntOpsTest -vv`：

```
[FAIL: panic: division or modulo by zero (0x12)] test_DivByZero() (gas: 26637)
Logs:
  10 / 3 = 3
  10 % 3 = 1

[FAIL: panic: arithmetic underflow or overflow (0x11)] test_Int8MinDivMinusOne() (gas: 16707)
Logs:
  -127 / -1 = 127

[FAIL: panic: division or modulo by zero (0x12)] test_ModByZero() (gas: 6522)
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_NegInt8Min() (gas: 15680)
Logs:
  -(-127) = 127

[FAIL: panic: arithmetic underflow or overflow (0x11)] test_Pow() (gas: 26919)
Logs:
  0 ** 0 = 1
  2 ** 255 = 57896044618658097711785492504343953926634992332820282019728792003956564819968

[FAIL: panic: arithmetic underflow or overflow (0x11)] test_PowTen() (gas: 18128)
Logs:
  10 ** 77 = 100000000000000000000000000000000000000000000000000000000000000000000000000000

[PASS] test_Signed() (gas: 50663)
Logs:
  -7 / 2 = -3
  -7 % 3 = -1
  7 % -3 = 1
  7 / -2 = -3
  -3 % 2 = -1
```

`unchecked`の中でも、ゼロ除算は巻き戻る（`forge test --match-contract DivUncheckedTest -vv`）：

```
[FAIL: panic: division or modulo by zero (0x12)] test_UncheckedDivByZero() (gas: 4819)
```

同じ計算をPythonとJavaScriptで行うと、丸めの方向が違う。

```
$ python -c "print(-7 // 2, -7 % 3, 7 % -3, -7 >> 1)"
-4 2 -2 -4
$ node -e "console.log(-7 % 3, Math.trunc(-7/2), Math.floor(-7/2))"
-1 -3 -4
```

`forge test --match-contract ShiftTest -vv`：

```
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_MulUint8() (gas: 6112)
[PASS] test_ShlFar() (gas: 29905)
Logs:
  1 << 255 = 57896044618658097711785492504343953926634992332820282019728792003956564819968
  1 << 256 = 0
  1 << 1000 = 0

[PASS] test_ShlUint8() (gas: 9789)
Logs:
  200 << 1 = 144

[PASS] test_SignedShr() (gas: 57824)
Logs:
  -7 / 2  = -3
  -7 >> 1 = -4
  -8 / 2  = -4
  -8 >> 1 = -4
  7 / 2   = 3
  7 >> 1  = 3

[PASS] test_SmallValues() (gas: 19576)
Logs:
  100 * 2  = 200
  100 << 1 = 200
```

数値どうしで書いたシフトは、コンパイルの段階で止められる（`code/literal`で`forge build`）：

```
Error (6359): Return argument type int_const 1157...(70 digits omitted)...9936 is not implicitly convertible to expected type (type of first return variable) uint256. Literal is too large to fit in uint256.
 --> src/Literal.sol:6:16:
  |
6 |         return 1 << 256;
  |                ^^^^^^^^
```

2倍にする三つの関数の呼び出しのガス（`forge test --match-contract DoubleGasTest --gas-report`、optimizerはオフ）。三つとも関数名とセレクターが同じ、関数一つだけのコントラクトなので、関数を探すコストは同じである。

| コントラクト | doubleの呼び出しのガス |
|---|---|
| DoubleMul（`x * 2`） | 819 |
| DoubleShl（`x << 1`） | 580 |
| DoubleUnchecked（`unchecked { x * 2 }`） | 579 |

### 試すときの注意

- 割り算は0の方向に切り捨てる。そのため掛け算を先にしたほうが精度を失いにくいが、掛け算が先の版は`type(uint256).max / 997`を超える金額でPanic 0x11で巻き戻る。
- ゼロ除算とゼロでの余りはPanic 0x12である。このチェックは`unchecked`で外せない。
- 符号付きの割り算で唯一のあふれは`type(int).min / -1`である。余りの符号は左のオペランドに従う。Pythonとは結果が違う。
- シフトにはあふれチェックがない。結果は左のオペランドの型で切り詰められる（uint8の`200 << 1`は144）。符号付きの`>>`は負の無限大の方向に丸めるので、`-7 >> 1`は-4、`-7 / 2`は-3である。
- `<< 1`が`* 2`より安い理由は、あふれチェックがないからである。`unchecked { x * 2 }`もほぼ同じ値（579）になる。optimizerをオンにすると、差は約105に縮まる。
- `0 ** 0`は1である。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のIntegers（Shifts、Division、Modulo、Exponentiation）、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge）のバージョン | 1.8.3 | 2026-10-19 |
| 2倍にする関数の呼び出しのガス | DoubleMul 819 / DoubleShl 580 / DoubleUnchecked 579（optimizerはオフ） | 2026-10-19 |
| 2倍にする関数の呼び出しのガス、optimizerオン（参考） | DoubleMul 345 / DoubleShl 239 / DoubleUnchecked 241、差は約105に縮まる | 2026-10-19 |
| デプロイのサイズ（ランタイム） | DoubleMul 416 / DoubleShl 275 / DoubleUnchecked 274 / Fee 617 / Small 611 / IntOps 2,058 / Shift 1,149バイト | 2026-10-19 |
| 手数料の掛け算が先の版が巻き戻る金額 | type(uint256).max / 997超（約1.16 × 10^74 wei） | 2026-10-19 |
| ドキュメントの文 | シフトのあふれチェックはなし、結果は左のオペランドの型で切り詰め、`>>`は負の無限大の方向に丸め / 割り算は0の方向に丸め、ゼロ除算のチェックはuncheckedで外せない、type(int).min / -1が唯一の割り算のあふれ / 余りは左のオペランドの符号 / 0**0 = 1 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 固定小数点、倍率を決めた整数で小数を扱う | [第53講](../../part4/lecture53/) |
| 数値どうしで書いた式のコンパイル時の計算のルール | [第58講](../../part4/lecture58/) |
| サイズの違う整数どうしの変換のルール | [第73講](../../part4/lecture73/)、[第74講](../../part4/lecture74/) |
| 演算子の優先順位 | [第126講](../../part7/lecture126/) |
| あふれチェックのルールの詳細と、uncheckedを使ってよい場所 | [第88講](../../part5/lecture88/)、[第89講](../../part5/lecture89/) |
| ビット演算とシフトを使う場面 | [第123講](../../part7/lecture123/)、[第127講](../../part7/lecture127/) |
| ガスを節約する算術の判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 大きな数の掛け算のあとの割り算を安全に行うライブラリ関数、利息の計算式 | [第194講](../../part13/lecture194/)〜[第199講](../../part13/lecture199/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
