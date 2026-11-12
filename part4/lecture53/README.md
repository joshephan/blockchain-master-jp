# 第53講 固定小数点の現状

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第52講](../../part4/lecture52/) | [第4部 目次](../) | [第54講 →](../../part4/lecture54/)

## この講義の問い

使える小数の型がない言語で、1.5イーサはどう保存され、その方式はどこで黙って間違えるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める。テストにはforge-stdが必要である（`lib/forge-std`）。anvilを立ち上げ、既定のアカウント0番（公開されたテスト用の鍵）でデプロイして呼び出す。ビルドが失敗する`FixedAssign.sol`は`bad/`に置いた。エラーを見るときだけ`src/`に移してビルドし、また外す。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/FixedDecl.sol](code/src/FixedDecl.sol) | `ufixed128x18`の状態変数の宣言だけがあるコントラクト（ビルド通過） |
| [code/bad/FixedAssign.sol](code/bad/FixedAssign.sol) | 同じ変数に`1.5`を代入するコントラクト（コンパイルエラー） |
| [code/src/Deposit.sol](code/src/Deposit.sol) | 受け取ったイーサをweiの整数で保存する`put()` |
| [code/src/SimpleToken.sol](code/src/SimpleToken.sol) | コンストラクターで`decimals`と最初の残高を決める最小のトークン |
| [code/src/Mix.sol](code/src/Mix.sol) | 桁数の違う金額の足し算、倍率18の値の掛け算3種類 |
| [code/test/Mix.t.sol](code/test/Mix.t.sol) | Mixの関数の結果の出力 |

### 実行結果

宣言はビルドを通過し、16バイトの場所を受け取る（`forge inspect FixedDecl storageLayout`）：

```
| x    | ufixed128x18 | 0    | 0      | 16    | src/FixedDecl.sol:FixedDecl |
```

値を代入すると、コンパイラはまだ実装されていないと言って止まる（`forge build`）：

```
Error (1834): Not yet implemented - FixedPointType.
 --> src/FixedAssign.sol:4:1:
  |
4 | contract FixedAssign {
  | ^ (Relevant source part starts here and spans across multiple lines).
```

同じ方式で、一つのファイルに一行ずつ入れてビルドした結果：

| 入れた行 | 結果 |
|---|---|
| `ufixed128x18 x = 1.5;` | Error (1834): Not yet implemented - FixedPointType. |
| 関数の中の`ufixed128x18 y = 1.5;` | Warning (2072): Unused local variable. / Error (1834): Not yet implemented - FixedPointType. |
| `function get() external view returns (ufixed128x18) { return x; }` | Error (1834): Fixed point types not implemented. |
| `function f(uint256 a) external { x = a; }` | Error (7407): Type uint256 is not implicitly convertible to expected type ufixed128x18. |
| `ufixed8x81 a;` | Error (7920): Identifier not found or not unique. |
| `ufixed a; fixed b; ufixed256x80 c; fixed8x0 d;` | ビルド通過。ufixed128x18 16バイト、fixed128x18 16バイト（同じ0番の欄のoffset 16）、ufixed256x80 32バイト、fixed8x0 1バイト |

1.5イーサを送ると、保存されるのはweiの整数である：

```
$ cast to-wei 1.5
1500000000000000000
$ cast send $D "put()" --value 1.5ether --rpc-url $R --private-key <アカウント0>
gasUsed              43273
status               1 (success)
$ cast storage $D 0 --rpc-url $R
0x00000000000000000000000000000000000000000000000014d1120d7b160000
$ cast to-dec 0x00000000000000000000000000000000000000000000000014d1120d7b160000
1500000000000000000
$ cast to-unit 1500000000000000000 ether
1.500000000000000000
```

SimpleTokenを桁数6（`--constructor-args 6 1500000`）と18（`--constructor-args 18 1500000000000000000`）でデプロイし、同じ1.5個を読んだ結果：

```
$ cast call <6桁の版> "decimals()(uint8)"
6
$ cast call <6桁の版> "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
1500000 [1.5e6]
$ cast call <18桁の版> "decimals()(uint8)"
18
$ cast call <18桁の版> "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
1500000000000000000 [1.5e18]
```

`forge inspect SimpleToken abi`：

```
| function    | balanceOf(address) view returns (uint256) | 0x70a08231 |
| function    | decimals() view returns (uint8)           | 0x313ce567 |
| constructor | constructor(uint8,uint256) nonpayable     |            |
```

Mixの呼び出し結果。18桁の1個と6桁の1個をそのまま足すと数字が混ざり、倍率18の値どうしを掛けると倍率が36になる。

```
$ cast call $M "total(uint256,uint256)(uint256)" 1000000000000000000 1000000
1000000000001000000 [1e18]
$ cast to-unit 1000000000001000000 ether
1.000000000001000000
$ cast call $M "mulRaw(uint256,uint256)(uint256)" 1500000000000000000 1500000000000000000
2250000000000000000000000000000000000 [2.25e36]
$ cast call $M "mulThenDiv(uint256,uint256)(uint256)" 1500000000000000000 1500000000000000000
2250000000000000000 [2.25e18]
$ cast call $M "divThenMul(uint256,uint256)(uint256)" 1500000000000000000 1500000000000000000
1500000000000000000 [1.5e18]
$ cast call $M "mulThenDiv(uint256,uint256)(uint256)" 999 50000000000000000
49
```

`forge test -vv`：

```
[PASS] test_show() (gas: 51417)
Logs:
  total      1000000000001000000
  mulRaw     2250000000000000000000000000000000000
  mulThenDiv 2250000000000000000
  divThenMul 1500000000000000000
  interest   49
```

### 試すときの注意

- `fixed`・`ufixed`でできるのは、宣言と欄の配置までである。代入、戻り値、整数からの変換はすべてコンパイルエラーになる。小数は、整数に倍率を掛けて表す。
- 金額には桁数の情報がついてこない。桁数の違うトークンの金額を足すと、コンパイラも実行も止めずに間違った値が出る。
- 倍率18の値どうしを掛けたら、1e18で割って倍率を戻す。先に割ると小数部分が捨てられる（1.5 × 1.5が1.5になる）。
- 小さな値の掛け算のあとの割り算では切り捨てが起きる。999 weiに5%を掛けると、49.95ではなく49になる。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると出力が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のFixed Point Numbers、v0.8.36（「宣言はできるが代入できない」） | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| Node.jsの`0.1 + 0.2` | 0.30000000000000004 | 2026-10-19 |
| ufixed128x18のサイズ | 16バイト、0番の欄のoffset 0 | 2026-10-19 |
| 固定小数点の代入・戻り値のエラー | Error (1834) "Not yet implemented - FixedPointType." / "Fixed point types not implemented." | 2026-10-19 |
| トークンの桁数の例 | 多くのトークンは18桁、USDCは6桁 | 2026-10-19 |
| Depositのput()のgasUsed | 43,273（1.5イーサ） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 小数リテラル（`1.5`、`0.05e18`）がコンパイル時に計算されるルール | [第58講](../../part4/lecture58/) |
| 倍率を型の名前としてつける文法（ユーザー定義の値型） | [第60講](../../part4/lecture60/) |
| サイズの違う整数のあいだの変換のルール | [第73講](../../part4/lecture73/) |
| 金額の単位の表記（`ether`、`gwei`、時間の単位） | [第75講](../../part5/lecture75/) |
| 掛けてから割る計算を、あふれなしで、切り捨ての方向を決めて行う技法（mulDiv、切り上げ・切り捨て） | [第194講](../../part13/lecture194/)〜[第199講](../../part13/lecture199/) |
| トークン標準（ERC-20）とdecimals()の規格 | [第155講](../../part10/lecture155/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
