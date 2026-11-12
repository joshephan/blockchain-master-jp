# 第86講 代入と分割代入

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第85講](../../part5/lecture85/) | [第5部 目次](../) | [第87講 →](../../part5/lecture87/)

## この講義の問い

複数の値を一度に受け取って入れる文は何を計算し、ストレージの欄に何を残すのか。

## 実習資料

### 準備

空のFoundryプロジェクト二つから始める。`demo`はビルドが通るバージョン、`errors`はビルドエラーを見るバージョンである。どちらもfoundry.tomlで`solc = "0.8.30"`に固定し、forge-stdを`lib/forge-std`に置く。コントラクトはローカルのanvilに既定のアカウント0番（デプロイ・管理者）でデプロイし、Marketの預け入れ・引き出しは既定のアカウント1番（アリス）で送る。預けたことのないユーザーとして、既定のアカウント2番（ボブ）のアドレスを使う（すべてanvilの公開されたテスト用の鍵）。`errors`のファイルは一つずつ`forge build --offline --force src/<ファイル>`でビルドする（`Market.sol`は`Getter2.sol`のimport用のコピー）。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Three.sol](code/demo/src/Three.sol) | 値を三つ返しながらイベントを残すSource、三つとも受け取る`takeAll`と一つだけ受け取る`takeOne`のReader |
| [code/demo/src/Side.sol](code/demo/src/Side.sol) | `slots[left()] = right()`で、左の欄と右の値の計算の順番を記録 |
| [code/demo/src/Blank.sol](code/demo/src/Blank.sol) | 空けた位置にも記録を残す`(a, , ) = (mark(1), mark(2), mark(3))` |
| [code/demo/src/PureThree.sol](code/demo/src/PureThree.sol) | 状態を変えない内部関数で、三つとも受け取る・一つだけ受け取る。オプティマイザの比較用 |
| [code/demo/src/Swap.sol](code/demo/src/Swap.sol) | 値型の入れ替え`(x, y) = (y, x)`、タプルリテラル、ストレージ配列の入れ替えSwapArr（警告7238） |
| [code/demo/src/Zero.sol](code/demo/src/Zero.sol) | `a = 0`と`delete b` |
| [code/demo/src/Getter.sol](code/demo/src/Getter.sol) | Marketのpositionsのゲッターから、預けた量だけを`(Amount d, , , )`で受け取る |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket、第85講までのバージョン。この講義で変えた行はない |
| [code/demo/src/MarketDel.sol](code/demo/src/MarketDel.sol) | デモ用。全部引き出すとPositionをdeleteする`withdrawAndClear`。プロジェクトのバージョンには入れない |
| [code/demo/src/MockToken.sol](code/demo/src/MockToken.sol) | デモ用の最小限のトークン（権限チェックなし） |
| [code/demo/test/Three.t.sol](code/demo/test/Three.t.sol) | takeAll 24、takeOne 7の確認とトレース |
| [code/demo/test/Side.t.sol](code/demo/test/Side.t.sol) | Sideの`run()`のあとの記録の出力 |
| [code/demo/test/Blank.t.sol](code/demo/test/Blank.t.sol) | Blankの`run()`のあとの記録の出力 |
| [code/demo/test/PureThree.t.sol](code/demo/test/PureThree.t.sol) | `takeAll(100)`、`takeOne(100)`の呼び出しのガスの比較 |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/Mix.sol](code/errors/src/Mix.sol) | 既存の名前のあとに宣言を混ぜる`(a, uint256 b)`、Error 2314 |
| [code/errors/src/Mix2.sol](code/errors/src/Mix2.sol) | 宣言のあとに既存の名前を混ぜる`(uint256 a, b)`、Error 2314 |
| [code/errors/src/Count.sol](code/errors/src/Count.sol) | 三つの値を二つの名前で、Error 7364 |
| [code/errors/src/Count2.sol](code/errors/src/Count2.sol) | 三つの値を`(a, )`で、Error 7407 |
| [code/errors/src/Getter2.sol](code/errors/src/Getter2.sol) | ゲッターのAmountの欄をuint256で受け取る、Error 7407 |
| [code/errors/src/TupleVar.sol](code/errors/src/TupleVar.sol) | タプルを変数一つに、Error 7364 |
| [code/errors/src/TupleType.sol](code/errors/src/TupleType.sol) | タプル型を書いた宣言、Error 2314 |
| [code/errors/src/MapAssign.sol](code/errors/src/MapAssign.sol) | マッピングを含む構造体の代入、Error 9214 |

### 実行結果

Sideの`run()`のあとの記録。右の値が先に計算される（`forge test --offline --via-ir -vv`でビルドしたバージョンも2, 1）。

```
$ cast send $SD "run()" --private-key $PK0
status               1 (success)
$ cast call $SD "logged()(uint256[])"
[2, 1]
$ cast call $SD "slots(uint256)(uint256)" 0
42
```

受け取る形のビルドエラー。

```
Error (2314): Expected ',' but got identifier
  --> src/Mix.sol:11:21:
   |
11 |         (a, uint256 b) = f();
   |                     ^
Error (2314): Expected identifier but got ')'
Error (7364): Different number of components on the left hand side (2) than on the right hand side (3).
Error (7407): Type tuple(uint256,uint256,uint256) is not implicitly convertible to expected type tuple(uint256,).
  --> src/Count2.sol:10:17:
   |
10 |         (a, ) = f();
   |                 ^^^
Error (7407): Type tuple(Amount,Amount,uint64,bool) is not implicitly convertible to expected type tuple(uint256,,,).
 --> src/Getter2.sol:8:21:
  |
8 |         (d, , , ) = m.positions(asset, user);
  |                     ^^^^^^^^^^^^^^^^^^^^^^^^
Error (7364): Different number of components on the left hand side (1) than on the right hand side (2).
  --> src/TupleVar.sol:10:9:
   |
10 |         uint256 t = f();
   |         ^^^^^^^^^^^^^^^
Error (2314): Expected ';' but got identifier
  --> src/TupleType.sol:10:28:
   |
10 |         (uint256, uint256) t = f();
   |                            ^
```

上からMix、Mix2、Count、Count2、Getter2、TupleVar、TupleTypeのエラーである。

`forge test --offline -vvvv --match-contract ThreeTest`（Tracesの見出し行とテスト関数の行は省略）。二つのバージョンとも、threeの本体は最後まで動いて三つの値を返す。

```
[PASS] test_takeAll() (gas: 36788)
    ├─ [31363] Reader::takeAll()
    │   ├─ [4080] Source::three()
    │   │   ├─ emit Made(n: 7)
    │   │   ├─ emit Made(n: 8)
    │   │   ├─ emit Made(n: 9)
    │   │   └─ ← [Return] 7, 8, 9
    │   └─ ← [Return] 24
[PASS] test_takeOne() (gas: 36358)
    ├─ [30931] Reader::takeOne()
    │   ├─ [4080] Source::three()
    │   │   ├─ emit Made(n: 7)
    │   │   ├─ emit Made(n: 8)
    │   │   ├─ emit Made(n: 9)
    │   │   └─ ← [Return] 7, 8, 9
    │   └─ ← [Return] 7
```

anvilでの`cast send`のgasUsedは、takeAll 31363、takeOne 30931である。takeOneのトランザクションの`cast run`のトレース。threeの戻りデータは32バイトの欄三つである。

```
Traces:
  [9867] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::takeOne()
    ├─ [4080] 0x5FbDB2315678afecb367f032d93F642f64180aa3::three()
    │   ├─ emit Made(n: 7)
    │   ├─ emit Made(n: 8)
    │   ├─ emit Made(n: 9)
    │   └─ ← [Return] 0x000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000009
    └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000007
```

Blankの`run()`のあとの`logged()`は`[1, 2, 3]`である。空けた位置の式も計算される。

PureThreeを三つの設定で動かした`forge test --offline -vvvv --match-contract PureThreeTest`の呼び出しのガス（n = 100）。

| 設定 | takeAll | takeOne |
|---|---|---|
| optimizerは切る | 26,072 | 25,829 |
| `--optimize` | 12,827 | 12,736 |
| `--via-ir --optimize` | 8,123 | 8,075 |

入れ替え。値型は1行で入れ替わり、タプルリテラルは欄ごとに型を別々に決める。

```
$ cast send $SW "swap()" --private-key $PK0
status               1 (success)
$ cast call $SW "x()(uint256)"
2
$ cast call $SW "y()(uint256)"
1
$ cast call $SW "literals()(uint8,int8)"
1
-1
```

ストレージ配列の入れ替えは警告つきでビルドされ、先に書いたほうが次のコピーの材料になって、二つとも`[1]`になる（最初はp = [1]、q = [2, 3]）。

```
Warning (7238): This assignment performs two copies to storage. Since storage copies do not first copy to a temporary location, one of them might be overwritten before the second is executed and thus may have unexpected effects. It is safer to perform the copies separately or assign to storage pointers first.
$ cast send $SA "swap()" --private-key $PK0
status               1 (success)
$ cast call $SA "both()(uint256[],uint256[])"
[1]
[1]
```

Zeroの欄を`cast storage $Z <欄>`で開いた値（0は省略）。gasUsedは`zero()` 21,463、`wipe()` 21,437である。

| 欄 | 送る前 | `zero()`、`wipe()`のあと |
|---|---|---|
| 0 (a) | `...0007` | `...0000` |
| 1 (b) | `...0007` | `...0000` |
| 2（宣言なし） | `...0000` | `...0000` |

マッピングを含む構造体の代入のビルドエラー。

```
Error (9214): Types in storage containing (nested) mappings cannot be assigned to.
  --> src/MapAssign.sol:14:9:
   |
14 |         backup = acct;
   |         ^^^^^^
```

MarketとMarketDelにアリスが500を入れて500を引き出したあとの、positions[トークン][アリス]の三つの欄。baseは、`cast index address $TK 4`の結果をさらに`cast index address $AL`に入れて求めた欄（`0x549a5b00ba4a2e087e3956958c7a8d2101e0ea1e19816d2ed4d1ef6bcb8419c2`）である。`0x6ad5d688`は最後に引き出したブロックの時刻である。

| 欄 | Market（withdraw） | MarketDel（withdrawAndClear） | 預けたことのないボブ |
|---|---|---|---|
| base（deposited） | `...0000` | `...0000` | `...0000` |
| base + 1（borrowed） | `...0000` | `...0000` | `...0000` |
| base + 2（lastUpdate、useAsCollateral） | `...6ad5d688` | `...0000` | `...0000` |

ゲッターで読むと、全部引き出したアリスと預けたことのないボブは、lastUpdateだけが違う。

```
$ cast call $M "positions(address,address)(uint256,uint256,uint64,bool)" $TK $AL
0
0
1792398984 [1.792e9]
false
$ cast call $M "positions(address,address)(uint256,uint256,uint64,bool)" $TK $BOB
0
0
0
false
```

### 試すときの注意

- 空けた位置で受け取らなかった値でも、関数の本体は最後まで実行され、値をすべて返す。空けた位置もカンマで数を合わせる。
- 1行の中では、すべて宣言か、すべて既存の名前でなければならない。タプル型を書く文法はないので、受け取る行ですぐに分けて受け取る。
- ストレージ配列どうしの`(p, q) = (q, p)`は警告7238を出すだけでビルドされる。結果は入れ替わらない。
- `a = 0`と`delete b`は同じ書き込みである。マッピングを含む構造体は代入できず、`delete`してもマッピングの項目の欄は残る。
- このバージョンのMarketは、全部引き出したユーザーのPositionを消さずに0のままにする。0の欄と使っていない欄を、コードは区別しない。MarketDelは比較用である。
- ブロックの時刻の値はanvilを立ち上げた時刻に従うので、実行し直すと変わる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンや設定が変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン。比較用に`--optimize`、`--via-ir`、`--via-ir --optimize` | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 0に戻す書き込みの払い戻し | EIP-3529（Londonアップグレード、2021年8月）、0でない値を0に戻すと4,800を払い戻し、上限は使ったガスの5分の1 | 2026-10-19 |
| トレースのガス | test_takeAll 36,788 / test_takeOne 36,358、Reader::takeAll 31,363 / takeOne 30,931、Source::three 4,080（二つのバージョンで同じ） | 2026-10-19 |
| gasUsed | takeAll 31,363 / takeOne 30,931（cast runのトレースではtakeOne 9,867）、swap 31,247、zero 21,463 / wipe 21,437、deposit 124,593（二つのバージョンで同じ）、Market withdraw 42,408 / MarketDel withdrawAndClear 45,042 | 2026-10-19 |
| PureThreeの呼び出しのガス（n = 100） | optimizerは切る 26,072 / 25,829、`--optimize` 12,827 / 12,736、`--via-ir --optimize` 8,123 / 8,075（takeAll / takeOne） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 名前が見える範囲と宣言の位置、同じ名前の再宣言 | [第87講](../../part5/lecture87/) |
| 既定のコード生成とvia-IRの評価の順番の違い | [第133講](../../part8/lecture133/) |
| ストレージのスロットの配置と、ストレージどうしのコピーが欄を移す順番 | [第135講](../../part8/lecture135/) |
| 戻りデータのABIエンコードの規則 | [第141講](../../part8/lecture141/) |
| 0に戻す書き込みの払い戻しと保存コストの判断 | [第143講](../../part9/lecture143/) |
| ユーザーの状態を消すか残すかを決める設計 | [第152講](../../part9/lecture152/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
