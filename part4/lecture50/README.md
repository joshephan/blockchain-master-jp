# 第50講 boolと論理演算

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第49講](../../part4/lecture49/) | [第4部 目次](../) | [第51講 →](../../part4/lecture51/)

## この講義の問い

値が二つしかない型一つが、この機械では何バイトを占め、`&&`と`||`の順番は何を決めるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める。コンパイルエラーを見せるファイルは`bad/`に別に置く（srcに置くとほかのビルドも一緒に止まる）。anvilを立ち上げ、既定のアカウント0番（公開されたテスト用の鍵）でデプロイして呼び出す。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/bad/IfInt.sol](code/bad/IfInt.sol) | `if (count)`のように整数を条件に使ったコード（コンパイルエラー） |
| [code/bad/IfOne.sol](code/bad/IfOne.sol) | `if (1)`（コンパイルエラー） |
| [code/bad/BoolInt.sol](code/bad/BoolInt.sol) | `bool public b = 1;`（コンパイルエラー） |
| [code/src/Flags.sol](code/src/Flags.sol) | boolが一つの`OneFlag`、boolが二つで一つの欄を分け合う`TwoFlags` |
| [code/src/ShortCircuit.sol](code/src/ShortCircuit.sol) | 右側に状態を変える`mark()`を置いた`\|\|`、`&&`、順番を入れ替えた`\|\|` |
| [code/src/OrderGas.sol](code/src/OrderGas.sol) | 同じ条件を、安い比較を先に（`cheapFirst`）、ストレージの読み取りを先に（`storageFirst`）書いた二つの関数 |
| [code/src/LendingDraft.sol](code/src/LendingDraft.sol) | レンディングプロトコルの草案の`paused`の欄と`!paused && amount > 0`のチェック |

### 実行結果

整数をboolの場所に使うと、コンパイラが止める（`forge build bad/IfInt.sol`、`bad/IfOne.sol`、`bad/BoolInt.sol`）：

```
Error (7407): Type uint256 is not implicitly convertible to expected type bool.
 --> bad/IfInt.sol:8:13:
  |
8 |         if (count) {
  |             ^^^^^

Error (7407): Type int_const 1 is not implicitly convertible to expected type bool.
 --> bad/IfOne.sol:6:13:
  |
6 |         if (1) {
  |             ^

Error (7407): Type int_const 1 is not implicitly convertible to expected type bool.
 --> bad/BoolInt.sol:5:21:
  |
5 |     bool public b = 1;
  |                     ^
```

boolの欄の配置（`forge inspect OneFlag storageLayout`、`TwoFlags storageLayout`）：

```
| paused | bool | 0    | 0      | 1     | src/Flags.sol:OneFlag |

| paused | bool | 0    | 0      | 1     | src/Flags.sol:TwoFlags |
| frozen | bool | 0    | 1      | 1     | src/Flags.sol:TwoFlags |
```

OneFlagの`pause()`を2回呼び、TwoFlagsの`pause()`と`freeze()`を順に呼んだ結果。同じ欄の2番目のバイトに1が入る。

```
$ cast send $A "pause()" --private-key <アカウント0>
gasUsed              43372
$ cast storage $A 0
0x0000000000000000000000000000000000000000000000000000000000000001
$ cast send $A "pause()" --private-key <アカウント0>
gasUsed              23472

$ cast send $B "pause()" --private-key <アカウント0>
gasUsed              43416
$ cast send $B "freeze()" --private-key <アカウント0>
gasUsed              26345
$ cast storage $B 0
0x0000000000000000000000000000000000000000000000000000000000000101
```

ShortCircuitで、`flag`の値によって右側の`mark()`が実行されるかを`count`で確かめた結果：

| 呼び出し | flag | gasUsed | 呼び出し後のcount |
|---|---|---|---|
| `orCheck()` | false | 45979 | 1 |
| `orCheck()` | true | 23629 | 1（スキップ） |
| `andCheck()` | true | 28806 | 2 |
| `orSwapped()` | true | 26708 | 3 |
| `andCheck()` | false | 23556 | 3（スキップ） |

OrderGasは、二つの関数の結果が同じである（0はtrue、500はfalse、5000はtrue）。`cast send`で測ったgasUsed：

| 引数 | cheapFirst | storageFirst |
|---|---|---|
| 0 | 21835 | 23901 |
| 500 | 23969 | 23925 |
| 5000 | 23969 | 23915 |

LendingDraftの欄の配置（`forge inspect LendingDraft storageLayout`）：

```
| paused | bool | 0    | 0      | 1     | src/LendingDraft.sol:LendingDraft |
```

### 試すときの注意

- Solidityは整数をboolに暗黙的に変換しない。`if (count)`、`if (1)`、`bool b = 1`はすべてエラー7407で止まる。
- boolは1バイトである。二つを続けて宣言すると同じ欄のoffset 0と1に入り、2回目の書き込みはすでに0でない欄を直す値なので安い（43416対26345）。
- `||`と`&&`は、左側だけで答えが出ると右側を実行しない。右側の関数が状態を変えるなら、順番によって状態が変わる。
- 安い条件を左に置くと、左で終わる場合だけガスが減る（引数0のとき21835）。左で終わらなければ、かえって少し高くなることがある。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のBooleans、v0.8.36（演算子五つ、`\|\|`・`&&`の短絡評価の文） | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| boolの保存サイズ | 1バイト、一つなら0番の欄のoffset 0 / 二つなら同じ欄のoffset 0・1 | 2026-10-19 |
| OneFlagのpause()のgasUsed | 最初の書き込み43,372 / 同じ値をもう一度23,472 | 2026-10-19 |
| TwoFlagsのgasUsed | pause() 43,416 / freeze() 26,345 | 2026-10-19 |
| 第47講の最初のvisit()のgasUsed | 65,727（欄二つの最初の書き込み） | 2026-10-19 |
| ShortCircuitのgasUsed | orCheck()実行45,979 / スキップ23,629、andCheck()実行28,806 / スキップ23,556、orSwapped() 26,708 | 2026-10-19 |
| OrderGasのgasUsed | cheapFirst 0・500・5000：21,835 / 23,969 / 23,969、storageFirst：23,901 / 23,925 / 23,915 | 2026-10-19 |
| SSTORE・SLOADの価格 | 0の欄に新しい値20,000 / 0でない値を別の値へ2,900 / コールドな欄は+2,100 | ベルリン（2021.04）以降 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 明示的な変換のルール全般（整数とboolのあいだを含む） | [第73講](../../part4/lecture73/) |
| 条件文・繰り返し文の文法 | [第81講](../../part5/lecture81/) |
| 演算子の優先順位 | [第126講](../../part7/lecture126/) |
| ストレージの欄の配置のルール全体 | [第135講](../../part8/lecture135/) |
| 欄の配置と条件の順番でガスを減らす | [第143講](../../part9/lecture143/) |
| 外部呼び出しを条件の中に置くときの判断 | [第83講](../../part5/lecture83/)、[第170講](../../part11/lecture170/) |
| 参照型（配列、マッピング、構造体の詳細） | [第62講](../../part4/lecture62/)〜[第72講](../../part4/lecture72/) |
| レンディングプロトコルの残りの欄の型 | [第51講](../../part4/lecture51/)〜[第61講](../../part4/lecture61/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
