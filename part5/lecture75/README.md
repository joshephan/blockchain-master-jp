# 第75講 イーサの単位と時間の単位

第5部 言語の詳細 ② グローバル変数と制御構造・第17章 単位とグローバル変数

[← 第74講](../../part4/lecture74/) | [第5部 目次](../) | [第76講 →](../../part5/lecture76/)

## この講義の問い

`1 ether`、`1 days`と書くと、コンパイラは何をして、何をしないのか。

## 実習資料

### 準備

空のFoundryプロジェクト二つから始める。`demo`はビルドが通るバージョン、`errors`はビルドエラーを見るバージョンである。どちらもfoundry.tomlで`solc = "0.8.30"`に固定し、forge-stdを`lib/forge-std`に置く。コントラクトはローカルのanvilに既定のアカウント0番（anvilの公開されたテスト用の鍵）で`forge create`し、`cast call`で読む。`errors`のファイルは互いに独立したエラーの例なので、`forge build --offline --force src/<ファイル>`で一つずつビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Units.sol](code/demo/src/Units.sol) | イーサの単位三つ、時間の単位五つ、`2.5 ether`・`0.5 days`、uint64の欄の`1 ether`、`1 days + 1 ether`、`x * 1 days` |
| [code/demo/src/Usdc.sol](code/demo/src/Usdc.sol) | 6桁の金額の欄に`100 ether`を足すUsdcVault、`Amount6.wrap(100 ether)` |
| [code/demo/src/Lock.sol](code/demo/src/Lock.sol) | `3 days`を返す関数一つ。バイトコードの確認用 |
| [code/demo/src/LockTypo.sol](code/demo/src/LockTypo.sol) | ロック期間を`7 ether`と書き間違えた行。警告なしでビルドされる |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket（第72講のバージョン）に`SECONDS_PER_YEAR = 365 days`と利息の下書き`interestFor`、比較用の`interestPerSecondFirst`を足したバージョン |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/HalfWei.sol](code/errors/src/HalfWei.sol) | `0.5 wei`、Error 2326 |
| [code/errors/src/Uint64Big.sol](code/errors/src/Uint64Big.sol) | uint64の欄に`20 ether`、Error 7407 |
| [code/errors/src/VarDays.sol](code/errors/src/VarDays.sol) | 変数につけた`x days`、Error 2314 |
| [code/errors/src/VarEther.sol](code/errors/src/VarEther.sol) | 変数につけた`amount ether`、Error 2314 |
| [code/errors/src/Finney.sol](code/errors/src/Finney.sol) | なくなった単位`finney`、Error 2314 |
| [code/errors/src/Szabo.sol](code/errors/src/Szabo.sol) | なくなった単位`szabo`、Error 2314 |
| [code/errors/src/Years.sol](code/errors/src/Years.sol) | なくなった単位`years`、Error 4820 |

### 実行結果

6桁の金額の欄に`100 ether`を足したあと`usdcBalance()`を読み、`cast to-unit`で二通りの桁数で読んだ結果。ビルドの警告はない。

```
$ cast call $VAULT "usdcBalance()(uint256)"
100000000000000000000 [1e20]
$ cast to-unit 100000000000000000000 6
100000000000000
$ cast to-unit 100000000000000000000 ether
100
```

Unitsの定数を`cast call`で読んだ値。

| 定数 | 値 |
|---|---|
| `1 wei`、`1 gwei`、`1 ether` | 1, 1000000000, 1000000000000000000 |
| `2.5 ether` | 2500000000000000000 |
| `1 seconds`、`1 minutes`、`1 hours` | 1, 60, 3600 |
| `1 days`、`1 weeks`、`0.5 days` | 86400, 604800, 43200 |
| uint64の欄の`1 ether` | 1000000000000000000 |
| `1 days + 1 ether` | 1000000000000086400 |
| `lockFor(3)`（`x * 1 days`） | 259200 |

uint64の欄に`20 ether`を入れたときのビルドエラー。エラーの中の型に単位の名前はない。

```
Error (7407): Type int_const 20000000000000000000 is not implicitly convertible to expected type uint64. Literal is too large to fit in uint64.
 --> src/Uint64Big.sol:5:23:
  |
5 |     uint64 public b = 20 ether;
  |                       ^^^^^^^^
```

`cast max-uint uint64`は18446744073709551615で、イーサとして読むと18.446744073709551615である。

`0.5 wei`と、変数につけた接尾辞のビルドエラー。

```
Error (2326): Type rational_const 1 / 2 is not implicitly convertible to expected type uint256. Try converting to type ufixed8x1 or use an explicit conversion.
Error (2314): Expected ';' but got 'days'
Error (2314): Expected ';' but got 'ether'
```

なくなった単位のビルドエラー。`finney`・`szabo`は知らない名前として扱われ、`years`は単位として使えないと出る。

```
Error (2314): Expected ';' but got identifier
 --> src/Finney.sol:5:35:
  |
5 |     uint256 public constant X = 1 finney;
  |                                   ^^^^^^
Error (4820): Using "years" as a unit denomination is deprecated.
 --> src/Years.sol:5:33:
  |
5 |     uint256 public constant X = 1 years;
  |                                 ^^^^^^^
```

Lockのデプロイコードを`cast disassemble`でほどいた結果から、PUSH3とMULを探したもの。掛け算はビルドのときに終わり、結果の259200（`cast to-dec 0x03f480`）だけが残る。全115行のうちMULはない。

```
00000046: PUSH3 0x03f480
```

Marketの利息の下書きの実行結果。金額1000個（6桁）、年5%（`50000000000000000`、倍率10の18乗）。

```
$ cast call $MARKET "interestFor(uint256,uint256,uint256)(uint256)" 1000000000 50000000000000000 31536000
50000000 [5e7]
$ cast call $MARKET "interestPerSecondFirst(uint256,uint256,uint256)(uint256)" 1000000000 50000000000000000 31536000
49999999 [4.999e7]
$ cast call $MARKET "interestFor(uint256,uint256,uint256)(uint256)" 1000000000 50000000000000000 2592000
4109589 [4.109e6]
$ cast call $MARKET "interestFor(uint256,uint256,uint256)(uint256)" 1000000000 50000000000000000 31622400
50136986 [5.013e7]
```

`SECONDS_PER_YEAR()`は31536000である。

### 試すときの注意

- 変数につけた`x days`、`amount ether`と`1 finney`、`1 szabo`は、単位のエラーではなく文法エラー（Error 2314）として出る。直した形は`x * 1 days`である。
- `1 days + 1 ether`、`lockPeriod = 7 ether`（`7 days`を書き間違えた行）、6桁の欄の`100 ether`、`Amount6.wrap(100 ether)`は、どれも警告なしでビルドされる。`ether`は18桁の資産の金額にだけ使う。
- Marketに足した`SECONDS_PER_YEAR`はconstantなので、ストレージの欄を使わない。`forge inspect --offline Market storageLayout`は第72講のバージョンと同じである（スロット0〜6）。デプロイコードには`PUSH4 0x01e13380`（31536000）が3回出てくる。
- 利息の下書きは1年を`365 days`とみなす。うるう年・うるう秒は考えない。
- disassembleの結果は、optimizerを切った既定の設定によるものである。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 単位の導入・削除 | `gwei`の追加 solc 0.6.11（2020-07-07）、`finney`・`szabo`の削除 0.7.0（2020-07-28）、`years`の削除 0.5.0 | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 6桁のトークンの例 | USDC `decimals()` 6（メインネット 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `block.timestamp`がどこから来て、誰が書くのか | [第76講](../../part5/lecture76/) |
| 実行中の算術のあふれの検査 | [第88講](../../part5/lecture88/) |
| `constant`がコンパイル時の値になる規則、`immutable` | [第102講](../../part6/lecture102/) |
| 単位・倍率を扱う計算の技法 | [第194講](../../part13/lecture194/)、[第195講](../../part13/lecture195/)、[第196講](../../part13/lecture196/) |
| 金利モデルと担保率 | [第197講](../../part13/lecture197/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
