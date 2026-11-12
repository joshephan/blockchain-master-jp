# 第60講 列挙型とユーザー定義の値型

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第59講](../../part4/lecture59/) | [第4部 目次](../) | [第61講 →](../../part4/lecture61/)

## この講義の問い

型に新しく名前を作るということは、この機械で何を変え、何をそのままにするのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める（`code/main`）。anvilを立ち上げ、既定のアカウント0番（公開されたテスト用の鍵）でデプロイして呼び出す。ビルドが失敗する例は、ほかのビルドを止めないようにプロジェクトを分けた：金額の型を混ぜる（`code/mix`）、列挙型の名前256個と257個（`code/big`）、ユーザー定義の値型に直接`+`（`code/err`）。四つのプロジェクトとも、solc 0.8.30、optimizerはオフの既定値である。サイズの比較だけは、optimizerをオンにした（200 runs）結果もあわせて見る。

### コード

| ファイル | 内容 |
|---|---|
| [code/main/foundry.toml](code/main/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/main/src/StateBox.sol](code/main/src/StateBox.sol) | `type(State).min`・`max`、数値からの変換、アセンブリで欄に範囲外の値を書く・読む |
| [code/main/src/PlainBox.sol](code/main/src/PlainBox.sol) | uint256の`price`の欄 |
| [code/main/src/PriceBox.sol](code/main/src/PriceBox.sol) | 同じ欄を`type Price is uint256`で書いた版 |
| [code/main/src/PriceOperator.sol](code/main/src/PriceOperator.sol) | `using {add as +} for Price global`で演算子を定義した版 |
| [code/main/src/MarketDraft.sol](code/main/src/MarketDraft.sol) | レンディングプロトコルの草案：`MarketStatus`列挙型と`Amount`、`Rate`、`Ratio`型 |
| [code/mix/foundry.toml](code/mix/foundry.toml) | mainと同じ設定 |
| [code/mix/src/MixPlain.sol](code/mix/src/MixPlain.sol) | 桁数の違う二つの金額をuint256で足す（ビルド通過） |
| [code/mix/src/MixTyped.sol](code/mix/src/MixTyped.sol) | 同じ足し算を`Amount18`、`Amount6`で（コンパイルエラー） |
| [code/mix/src/MixAssign.sol](code/mix/src/MixAssign.sol) | `Amount6`を`Amount18`の変数に代入（コンパイルエラー） |
| [code/mix/src/MixBypass.sol](code/mix/src/MixBypass.sol) | `wrap`・`unwrap`で型チェックを迂回する版 |
| [code/big/foundry.toml](code/big/foundry.toml) | mainと同じ設定 |
| [code/big/src/E256.sol](code/big/src/E256.sol) | 名前が256個の列挙型 |
| [code/big/src/E257.sol](code/big/src/E257.sol) | 名前が257個の列挙型（コンパイルエラー） |
| [code/err/foundry.toml](code/err/foundry.toml) | mainと同じ設定 |
| [code/err/src/PriceOps.sol](code/err/src/PriceOps.sol) | `Price`にuint256とPriceを`+`（コンパイルエラー） |

### 実行結果

StateBoxをデプロイし、範囲の内外の値を入れた結果。数値を変換して入れる経路はPanic 0x21で止められるが、アセンブリで欄に7を直接書くと、それ以降この欄を列挙型として読む関数はすべて巻き戻る。

```
$ forge inspect StateBox storageLayout
| state | enum StateBox.State | 0    | 0      | 1     | src/StateBox.sol:StateBox |
$ cast call $S "bounds()(uint8,uint8)"
0
3
$ cast call $S "setRaw(uint256)" 7
Error: execution reverted: panic: failed to convert value into enum type (0x21)
$ cast send $S "setRaw(uint256)" 2
gasUsed              43861
$ cast call $S "state()(uint8)"
2
$ cast send $S "poke(uint256)" 7
gasUsed              26611
$ cast storage $S 0
0x0000000000000000000000000000000000000000000000000000000000000007
$ cast call $S "rawSlot()(uint256)"
7
$ cast call $S "state()"
Error: execution reverted: panic: failed to convert value into enum type (0x21)
$ cast call $S "asNumber()"
Error: execution reverted: panic: failed to convert value into enum type (0x21)
$ cast call $S "isInactive()(bool)"
Error: execution reverted: panic: failed to convert value into enum type (0x21)
$ cast send $S "setRaw(uint256)" 1
gasUsed              26761
$ cast call $S "state()(uint8)"
1
```

Panic 0x21の巻き戻しデータは`0x4e487b710000000000000000000000000000000000000000000000000000000000000021`である。

名前256個は1バイトに入り（`forge inspect E256 storageLayout`）、257個はコンパイルされない：

```
| e    | enum E256.E | 0    | 0      | 1     | src/E256.sol:E256 |

Error (1611): Enum with more than 256 members is not allowed.
 --> src/E257.sol:5:5:
```

ユーザー定義の値型には演算子がない（`code/err`で`forge build`）：

```
Error (2271): Built-in binary operator + cannot be applied to types Price and uint256. No matching user-defined operator found.
 --> src/PriceOps.sol:8:16:
  |
8 |         return p + x;
  |                ^^^^^

Error (2271): Built-in binary operator + cannot be applied to types Price and Price. No matching user-defined operator found.
  --> src/PriceOps.sol:12:16:
   |
12 |         return a + b;
   |                ^^^^^
```

`code/mix`で一つずつビルドした結果。uint256の版は通過し、型を分けた版は足し算と代入が止められる。

```
$ forge build src/MixPlain.sol
Compiler run successful!
$ forge build src/MixTyped.sol
Error (2271): Built-in binary operator + cannot be applied to types Amount18 and Amount6. No matching user-defined operator found.
  --> src/MixTyped.sol:11:16:
$ forge build src/MixAssign.sol
Error (9574): Type Amount6 is not implicitly convertible to expected type Amount18.
 --> src/MixAssign.sol:9:9:
```

`wrap`・`unwrap`で包むと、チェックを通り抜ける。ABIにはuint256だけが残る。

```
$ cast call $M "total(uint256,uint256)(uint256)" 1000000000000000000 1000000
1000000000001000000 [1e18]
$ cast call $M "anything()(uint256)"
123
$ forge inspect MixBypass methodIdentifiers
| anything()             | 5c686a08   |
| total(uint256,uint256) | 9d515c26   |
```

PlainBoxとPriceBoxの比較。欄、保存のガス、`get()`のガスが同じで、optimizerをオンにするとランタイムのサイズも同じになる。

```
$ forge build --sizes
| PlainBox  | 369              | 397               | 24,207             | 48,755              |
| PriceBox  | 451              | 479               | 24,125             | 48,673              |
$ forge build --sizes --optimize --optimizer-runs 200
| PlainBox  | 183              | 209               | 24,393             | 48,943              |
| PriceBox  | 183              | 209               | 24,393             | 48,943              |
$ forge inspect PriceBox storageLayout
| price | Price | 0    | 0      | 32    | src/PriceBox.sol:PriceBox |
$ forge inspect PlainBox storageLayout
| price | uint256 | 0    | 0      | 32    | src/PlainBox.sol:PlainBox |
```

| 呼び出し | PlainBox | PriceBox |
|---|---|---|
| `set(123)`のgasUsed | 43696 | 43696 |
| `set(456)`のgasUsed | 26608 | 26608 |
| 0番の欄 | `0x...01c8` | `0x...01c8` |
| `cast estimate get()` | 23495 | 23495 |
| `cast estimate price()` | 23510 | 23636 |

optimizerをオンにして`forge inspect --optimize true <コントラクト> deployedBytecode`で見た二つの出力は、メタデータ（`a264`で始まる末尾）の手前まで同じである。ABIのpriceの項目は、outputsのtypeが`uint256`、internalTypeが`Price`である。`PriceOperator.sol`は0.8.30でビルドされる。

MarketDraftの欄の配置（`forge inspect MarketDraft storageLayout`）：

```
| status          | enum MarketDraft.MarketStatus | 0    | 0      | 1     | src/MarketDraft.sol:MarketDraft |
| collateralRatio | Ratio                         | 0    | 1      | 1     | src/MarketDraft.sol:MarketDraft |
| interestRate    | Rate                          | 1    | 0      | 32    | src/MarketDraft.sol:MarketDraft |
| totalDeposits   | Amount                        | 2    | 0      | 32    | src/MarketDraft.sol:MarketDraft |
```

### 試すときの注意

- 列挙型の値は、数値から変換するときにだけ範囲がチェックされる。欄に範囲外の値が入ると、その欄を列挙型として読むすべての関数がPanic 0x21で止まる。
- 列挙型の名前は256個までである。257個ならエラー1611になる。
- ユーザー定義の値型は、コンパイラだけが知っている名前である。欄、ABIの型、ガスは元の型と同じである。演算子は`using {f as +} for T global`で自分で定義して初めてできる。
- `wrap`・`unwrap`を使うと、型チェックをそのまま通り抜ける。包む行をどこに置くかが、型を分けた効果を決める。
- `E257.sol`があるフォルダで`forge build`をすると、ビルド全体が止まる。E256だけを見るには、ファイルを指定してビルドする。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のEnums、User-defined Value Types / Contractsの節のUsing For、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値）。サイズの比較だけoptimizerオン（200 runs）もあわせて | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| type(E).min・max、ユーザー定義の値型の導入 | 0.8.8（ドキュメントのEnums・User-defined Value Typesの例が`pragma solidity ^0.8.8;`、ドキュメント本文に導入バージョンの文はない） | 2026-10-19 |
| ユーザー定義の値型の演算子定義（`using {f as +} for T global`） | 0.8.19（ドキュメントのUsing Forの演算子の例が`pragma solidity ^0.8.19;`、本文に導入バージョンの文はない）。0.8.30でビルドを確認 | 2026-10-19 |
| 列挙型の名前の個数の上限 | 256個（257個ならError 1611） | 2026-10-19 |
| StateBoxの欄 | stateは0番の欄の1バイト | 2026-10-19 |
| poke(7)のgasUsed | 26,611（先にsetRaw(2)で0でない欄） | 2026-10-19 |
| PlainBox・PriceBoxのgasUsed | set(123) 43,696 / set(456) 26,608（両方同じ） | 2026-10-19 |
| ガス見積もり | get() 23,495（両方） / price() 23,510対23,636 | 2026-10-19 |
| デプロイのサイズ | optimizerオフ：PlainBox 369 / PriceBox 451 / MixBypass 594 / StateBox 1,044。optimizerオン：PlainBox 183 / PriceBox 183 / StateBox 528 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 列挙型で組む状態マシンの設計 | [第152講](../../part9/lecture152/) |
| インラインアセンブリの文法とsstore・sload | [第119講](../../part7/lecture119/)〜[第125講](../../part7/lecture125/) |
| ユーザー定義の値型に演算子をつける（`using {f as +} for T global`） | [第118講](../../part6/lecture118/) |
| 型のあいだの変換のルール全体 | [第73講](../../part4/lecture73/)、[第74講](../../part4/lecture74/) |
| 構造体・列挙型・ユーザー定義の値型を一緒に使う設計 | [第70講](../../part4/lecture70/) |
| ABIエンコードのルール（列挙型はuint8、ユーザー定義の値型は元の型） | [第141講](../../part8/lecture141/) |
| 単位・倍率を扱う計算の技法 | [第75講](../../part5/lecture75/)、[第194講](../../part13/lecture194/)、[第195講](../../part13/lecture195/)、[第196講](../../part13/lecture196/) |
| ストレージの欄の配置のルール | [第135講](../../part8/lecture135/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
