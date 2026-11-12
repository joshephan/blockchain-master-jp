# 第51講 整数型と範囲

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第50講](../../part4/lecture50/) | [第4部 目次](../) | [第52講 →](../../part4/lecture52/)

## この講義の問い

整数型のサイズを選ぶと、この機械では何が一緒に決まり、範囲を超えると何が起きるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める（`code/main`）。テストにはforge-stdが必要である（`lib/forge-std`）。定数の計算があふれる`Lit`は、ほかのコントラクトのビルドを止めないように別のプロジェクト（`code/lit`）でビルドし、同じanvilにデプロイする。anvilの既定のアカウント0番（公開されたテスト用の鍵）でデプロイして呼び出す。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/main/foundry.toml](code/main/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/main/src/Wrap.sol](code/main/src/Wrap.sol) | チェックする足し算・引き算・掛け算と`unchecked`版、int8の足し算 |
| [code/main/src/Counters.sol](code/main/src/Counters.sol) | 同じカウンターを`uint256`と`uint8`で作った`Counter256`、`Counter8` |
| [code/main/src/Packs.sol](code/main/src/Packs.sol) | uint8が四つの`FourSmall`、あいだにuint256を挟んだ`BigInMiddle` |
| [code/main/src/Fee.sol](code/main/src/Fee.sol) | uint8の`percent`をそのまま受け取る`Fee`、100以下だけを受け取る`FeeChecked` |
| [code/main/test/Range.t.sol](code/main/test/Range.t.sol) | 型ごとの`type(T).min`・`type(T).max`の出力 |
| [code/main/test/Wrap.t.sol](code/main/test/Wrap.t.sol) | 範囲を超える計算のチェック版と`unchecked`版の比較 |
| [code/main/test/Fee.t.sol](code/main/test/Fee.t.sol) | percentに101を入れる二つのテスト |
| [code/lit/foundry.toml](code/lit/foundry.toml) | 別プロジェクトの設定（mainと同じ） |
| [code/lit/src/Lit.sol](code/lit/src/Lit.sol) | `type(uint256).max + 1`を返す関数 |

### 実行結果

`forge test -vv`：

```
[PASS] test_Percent101() (gas: 54282)
Logs:
  percent 101

[FAIL: percent > 100] test_Percent101Checked() (gas: 25990)

[PASS] test_MinMax() (gas: 38109)
Logs:
  uint8   min 0
  uint8   max 255
  uint16  max 65535
  uint32  max 4294967295
  uint64  max 18446744073709551615
  uint128 max 340282366920938463463374607431768211455
  uint256 max 115792089237316195423570985008687907853269984665640564039457584007913129639935
  int8    min -128
  int8    max 127
  int256  min -57896044618658097711785492504343953926634992332820282019728792003956564819968
  int256  max 57896044618658097711785492504343953926634992332820282019728792003956564819967

[FAIL: panic: arithmetic underflow or overflow (0x11)] test_Int8MaxPlusOne() (gas: 6410)
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_MaxPlusOne() (gas: 6316)
[PASS] test_MaxPlusOneUnchecked() (gas: 9525)
Logs:
  0
[PASS] test_TwoTimesHalf() (gas: 9674)
Logs:
  0
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_TwoTimesHalfChecked() (gas: 6525)
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_ZeroMinusOne() (gas: 6352)
[PASS] test_ZeroMinusOneUnchecked() (gas: 9736)
Logs:
  115792089237316195423570985008687907853269984665640564039457584007913129639935
```

anvilにデプロイした二つのカウンターの`increment()`を3回ずつ呼んだgasUsed。二つのカウンターとも、0番の欄の値が3になる。

| コントラクト | 1回目 | 2回目 | 3回目 |
|---|---|---|---|
| Counter256 | 43517 | 26417 | 26417 |
| Counter8 | 43713 | 26613 | 26613 |

`cast disassemble`で数えたランタイムの命令数：

| コントラクト | AND | NOT | EXP | SLOAD |
|---|---|---|---|---|
| Counter256 | 0 | 0 | 0 | 2 |
| Counter8 | 5 | 1 | 3 | 3 |

`Lit.f()`を`cast call`で呼んだ結果：

```
Error: server returned an error response: error code 3: execution reverted: panic: arithmetic underflow or overflow (0x11), data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000011"
```

欄の配置（`forge inspect FourSmall storageLayout`、`BigInMiddle storageLayout`）：

```
| a    | uint8 | 0    | 0      | 1     | src/Packs.sol:FourSmall |
| b    | uint8 | 0    | 1      | 1     | src/Packs.sol:FourSmall |
| c    | uint8 | 0    | 2      | 1     | src/Packs.sol:FourSmall |
| d    | uint8 | 0    | 3      | 1     | src/Packs.sol:FourSmall |

| a    | uint8   | 0    | 0      | 1     | src/Packs.sol:BigInMiddle |
| b    | uint8   | 0    | 1      | 1     | src/Packs.sol:BigInMiddle |
| big  | uint256 | 1    | 0      | 32    | src/Packs.sol:BigInMiddle |
| c    | uint8   | 2    | 0      | 1     | src/Packs.sol:BigInMiddle |
| d    | uint8   | 2    | 1      | 1     | src/Packs.sol:BigInMiddle |
```

### 試すときの注意

- 0.8.0から、算術は既定でチェックされる。範囲を超えると一周せず、Panic 0x11（巻き戻しデータのセレクター`0x4e487b71`）で巻き戻る。一周するのは`unchecked`の中だけである。
- `uint8`は`uint256`より安くない。単独のカウンターでは、1バイトを選んで直す命令が余分に入るので、呼び出しごとに196ガス高い。小さな型が得になるのは、一つの欄に複数をまとめるときである。
- 小さな型のあいだにuint256を挟むと、欄が一つから三つに増える。
- 型の範囲内だからといって、業務の範囲内とは限らない。uint8の`percent`に101がそのまま入るので、範囲は`require`で別に止める。
- リテラルどうしの計算は、実行前にコンパイラが拒否する（`uint8 x = 255 + 1;`はエラー9574）。そのため、定数があふれる例（`Lit`）は`type(uint256).max + 1`を関数の中で返している。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のIntegers、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| 算術チェックの既定化 | 0.8.0（2020-12-16）、"All arithmetic is checked by default" | 2026-10-19 |
| 整数の`type(T).min`・`type(T).max`の導入 | 0.6.8（2020-05-14） | 2026-10-19 |
| incrementのgasUsed | Counter256 43,517 / 26,417、Counter8 43,713 / 26,613（呼び出しごとに+196） | 2026-10-19 |
| 逆アセンブルの命令数 | Counter256 AND 0・NOT 0・EXP 0・SLOAD 2 / Counter8 AND 5・NOT 1・EXP 3・SLOAD 3 | 2026-10-19 |
| チェックのコードのガス | Counter 43,539・26,439 / CounterUnchecked 43,338・26,238（第35講の測定） | 2026-10-19 |
| 欄の数 | FourSmall 1欄 / BigInMiddle 3欄 | 2026-10-19 |
| 欄を一つ余分に初めて書き込む | 約2万ガス（第49講のOrderの二つの版の差21,851） | 2026-10-19 |
| テストのガス | test_MinMax 38,109 / test_Percent101 54,282 / test_Percent101Checked 25,990 | 2026-10-19 |
| デプロイのサイズ（ランタイム） | Counter256 303 / Counter8 371 / Fee 354 / FeeChecked 545 / Wrap 1,088バイト | 2026-10-19 |
| Panicコード | 0x11 = 算術のあふれ、巻き戻しデータのセレクター0x4e487b71 | 2026-10-19 |
| BEC事件 | 2018年4月（2018-04-22の攻撃）、BeautyChain（BEC）のbatchTransferの掛け算のあふれ、足し算・引き算だけSafeMath | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 符号付き整数の端で起きること（`-type(int8).min`、`int8(-128) / -1`） | [第52講](../../part4/lecture52/) |
| 割り算・余り・シフト・べき乗のあふれと切り捨て | [第52講](../../part4/lecture52/) |
| 小数と倍率（利率・担保比率を整数で書く方法） | [第53講](../../part4/lecture53/) |
| リテラルの計算のルール（`255 + 1`がコンパイルの段階で拒否される理由） | [第58講](../../part4/lecture58/) |
| 暗黙的・明示的な変換のルール（サイズの違う整数を混ぜる、縮める変換） | [第73講](../../part4/lecture73/) |
| あふれチェックのルールの詳細と、uncheckedを使ってよい場所 | [第88講](../../part5/lecture88/)、[第89講](../../part5/lecture89/) |
| requireとPanicコードの一覧、巻き戻しデータの受け取り | [第90講](../../part5/lecture90/)、[第91講](../../part5/lecture91/) |
| ストレージの欄の配置のルール全体 | [第135講](../../part8/lecture135/) |
| 欄の配置と型のサイズでガスを減らす | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 過去のあふれ事故の検証 | [第186講](../../part11/lecture186/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
