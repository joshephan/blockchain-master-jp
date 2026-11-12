# 第74講 LValueの演算、delete、三項演算子の型の決まり方

第4部 言語の詳細 ① ファイルと型・第16章 変換と演算子

[← 第73講](../../part4/lecture73/) | [第4部 目次](../) | [第75講 →](../../part5/lecture75/)

## この講義の問い

値を書き戻す欄が必要な演算は、その欄に正確に何をするのか。二つの枝のどちらかを選ぶ式の型は、誰が決めるのか。

## 実習資料

### 準備

ビルドされる版はFoundryプロジェクト`demo/`に、エラーを見る版は別のプロジェクト`bad/`に置く。どちらにもforge-stdを入れ、foundry.tomlに`solc = "0.8.30"`を置く。エラーの版は一つずつ`forge build --offline --force src/<ファイル>`でビルドする。デプロイはローカルのanvilで既定のアカウント0番（管理者）、アリスの呼び出しは既定のアカウント1番で行う（公開されたテスト用の鍵）。Marketは、anvilを新しく立ち上げて別にデプロイした。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/demo/src/Ops.sol](code/demo/src/Ops.sol) | 後置・前置のインクリメント、uint8の255での`++`、シフト代入`<<=`、`arr[i++] += 1` |
| [code/demo/src/Ledger.sol](code/demo/src/Ledger.sol) | LedgerTotal。マッピングの項目一つをdeleteし、合計も一緒に直す`clear`（実習用、権限チェックなし） |
| [code/demo/src/Wipe.sol](code/demo/src/Wipe.sol) | 型ごとに状態変数を埋めて（`fill`）すべてdeleteする（`wipe`）、`u = 0`と`delete u`の比較 |
| [code/demo/src/MemDelete.sol](code/demo/src/MemDelete.sol) | memory配列の別名で片方だけをdelete |
| [code/demo/src/MapStruct.sol](code/demo/src/MapStruct.sol) | マッピングのフィールドを含む構造体をdelete |
| [code/demo/src/Tern.sol](code/demo/src/Tern.sol) | 三項式の結果の型：リテラルの枝、符号の違う枝、サイズの違う枝 |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 第72講のMarketに、実習用の`delistAsset`（管理者だけ、`delete assetConfig[asset]`）を加えた版 |
| [code/bad/foundry.toml](code/bad/foundry.toml) | demoと同じ設定 |
| [code/bad/src/](code/bad/src/) | 代入の左が欄でない式、ユーザー定義の値型の`+=`、deleteが止められる場所、三項式の型の例13個 |

`code/bad/src/`のファイルと結果：

| ファイル | 行 | 結果 |
|---|---|---|
| PlusLhs.sol | `totalDeposits + 1 = 5;` | Error (4247) |
| CallPlusEq.sol | `getTotal() += 1;` | Error (4247) |
| CallLhs.sol | `getTotal() = 1;` | Error (4247) |
| SumLhs.sol | `a + b = 1;` | Error (4247) |
| LitLhs.sol | `1 = x;` | Error (4247)、Error (7407) |
| AmountPlusEq.sol | `totalDeposits += Amount.wrap(amount);` | Error (7366) |
| DelLocal.sol | storageのローカル名で`delete y;` | Error (9767) |
| DelMap.sol | `delete deposits;`（マッピング全体） | Error (9767) |
| TernType.sol | `uint8 r = c ? a : b;`（bはuint16） | Error (9574) |
| MixBranch.sol | `return c ? a : b;`（uint256とint256） | Error (1080) |
| FracOk.sol | `return 1.5 + 1.5;` | ビルド成功 |
| Frac.sol | `return 1.5 + (true ? 1.5 : 2.5);` | Error (2271)、Error (6359) |
| TernLhs.sol | `(c ? a : b) = 1;` | Error (2212)、Error (4247) |

### 実行結果

`bad/`のビルド（位置の行は一部省略）：

```
$ forge build --offline --force src/PlusLhs.sol
Error (4247): Expression has to be an lvalue.
 --> src/PlusLhs.sol:8:9:
  |
8 |         totalDeposits + 1 = 5;
  |         ^^^^^^^^^^^^^^^^^
$ forge build --offline --force src/CallPlusEq.sol
Error (4247): Expression has to be an lvalue.
  --> src/CallPlusEq.sol:12:9:
   |
12 |         getTotal() += 1;
   |         ^^^^^^^^^^
$ forge build --offline --force src/LitLhs.sol
Error (4247): Expression has to be an lvalue.
Error (7407): Type uint256 is not implicitly convertible to expected type int_const 1.
$ forge build --offline --force src/AmountPlusEq.sol
Error (7366): Operator += not compatible with types Amount and Amount.
$ forge build --offline --force src/DelLocal.sol
Error (9767): Built-in unary operator delete cannot be applied to type uint256[] storage pointer.
$ forge build --offline --force src/DelMap.sol
Error (9767): Built-in unary operator delete cannot be applied to type mapping(address => uint256).
$ forge build --offline --force src/TernType.sol
Error (9574): Type uint16 is not implicitly convertible to expected type uint8.
$ forge build --offline --force src/MixBranch.sol
Error (1080): True expression's type uint256 does not match false expression's type int256.
$ forge build --offline --force src/FracOk.sol
Compiler run successful!
$ forge build --offline --force src/Frac.sol
Error (2271): Built-in binary operator + cannot be applied to types rational_const 3 / 2 and ufixed8x1. Fractional literals not supported.
Error (6359): Return argument type rational_const 3 / 2 is not implicitly convertible to expected type (type of first return variable) uint256.
$ forge build --offline --force src/TernLhs.sol
Error (2212): Conditional expression as left value is not supported yet.
Error (4247): Expression has to be an lvalue.
```

Ops。後置の`x++`は前の値を、前置の`++x`は変わった値を返す。`small`が255のときの`bump()`は巻き戻り、`bits`が128のときの`shift()`は成功して0になる：

```
$ cast call <Ops> "post(uint256)(uint256,uint256)" 5
5
6
$ cast call <Ops> "pre(uint256)(uint256,uint256)" 5
6
6
$ cast send <Ops> "bump()" --private-key <アカウント0のキー>
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: panic: arithmetic underflow or overflow (0x11), ...
$ cast call <Ops> "bits()(uint8)"
0
$ cast storage <Ops> 0
0x00000000000000000000000000000000000000000000000000000000000000ff
```

`touch()`（`arr[i++] += 1`）を2回呼ぶと、iは1、2と1回ずつだけ増え、arr[0]とarr[1]が順に1になる。

Wipe。`fill()`（gasUsed 333594）のあとと`wipe()`（gasUsed 73992）のあとの欄：

| 欄 | 変数 | fillのあと | wipeのあと |
|---|---|---|---|
| 0 | `uint256 u` | `...0007` | `...0000` |
| 1 | `bool b`、`address a` | `...f39fd6e5...b9226601` | `...0000` |
| 2 | `bytes32 h` | `0x7521d1ca...a1127a83` | `...0000` |
| 3 | 列挙型`s` | `...0002`（Frozen） | `...0000`（Active） |
| 4〜6 | `uint256[3] fixedArr` | 1、2、3 | 0、0、0 |
| 7 | `uint256[] dyn`の長さ | `...0002` | `...0000` |
| keccak256(7)、+1 | dynの要素 | `...000a`、`...0014` | `...0000`、`...0000` |
| 8 | `bytes bs`（hex"0102"） | `0x0102...0004` | `...0000` |
| 9 | `string str`（"abc"） | `0x616263...0006` | `...0000` |
| 10、11 | 構造体`Pair pair`（5、true） | `...0005`、`...0001` | `...0000`、`...0000` |

dynの要素の欄は、`cast keccak $(cast to-uint256 7)` = `0xa66cc928b5edb82af9bd49922954155ab7b0942694bea4ce44661d9a8736c688`からである。固定サイズの配列は、deleteのあとも長さ3のままで、要素だけが0になる。

uが7のときの`u = v`と`delete u`の比較：

| uが7のときに送ったもの | 欄に残った値 | gasUsed |
|---|---|---|
| `setU(9)`（`u = v`） | 9 | 26,686 |
| `wipeU()`（`delete u`） | 0 | 21,460 |
| `setU(0)`（`u = v`） | 0 | 21,874 |

MemDelete。memory配列`a`を`b`も一緒に指しているとき、`delete a`は`a`に新しい空の配列を入れるだけなので、`b`はそのままである：

```
$ cast call <MemDelete> "f()(uint256,uint256,uint256)"
0
2
7
```

LedgerTotal。アリスが1イーサを預けたあと`clear(<アリス>)`（gasUsed 25802）を呼ぶと、アリスの欄が0になる：

```
$ cast storage <LedgerTotal> $(cast index address <アリス> 0)
0x0000000000000000000000000000000000000000000000000de0b6b3a7640000
$ cast send <LedgerTotal> "clear(address)" <アリス> --private-key <アカウント0のキー>
$ cast storage <LedgerTotal> $(cast index address <アリス> 0)
0x0000000000000000000000000000000000000000000000000000000000000000
```

MapStruct。`fill(0x...aa, 500)`（gasUsed 66300）のあとに`wipe()`（gasUsed 21450）を呼ぶと、totalだけが0になり、マッピングの項目は残る：

| 欄 | fill(0x...aa, 500)のあと | wipeのあと |
|---|---|---|
| 0（total） | `...01f4` | `...0000` |
| 1（byAssetの宣言の欄） | `...0000` | `...0000` |
| `cast index address 0x...aa 1`（byAssetの項目） | `...01f4` | `...01f4` |

`cast index address 0x00000000000000000000000000000000000000aa 1`は`0x858c5a7702dbcc7e542bf7cd777756ad7a1cf5ac44f955cea0b7008d7156d4a8`である。

Market。管理者が資産AAAAを比率75で追加し（gasUsed 91663）、アリスが500を預けたあと（gasUsed 91448）、`delistAsset(AAAA)`（gasUsed 24613）を呼んだ結果。資産の設定だけが消え、ユーザーの欄、合計、リストは残る：

| 読んだもの（AAAA、アリス） | delistAssetの前 | delistAssetのあと |
|---|---|---|
| `assetConfig(AAAA)` | 75、true | 0、false |
| `positions(AAAA, アリス)` | 500、0、時刻、false | 500、0、時刻、false |
| `totalDeposits(AAAA)` | 500 | 500 |
| `assetCount()` | 1 | 1 |

同じ資産をもう一度`addAsset`すると、gasUsed 74563で成功する。アリスのPositionの欄：

```
$ cast index address <アリス> $(cast index address 0x000000000000000000000000000000000000AAAA 4)
0x38bb39d3455c9ab9596b6ddbdd0e9f6d06a6d98609d16fa00df0a9d840121780
$ cast storage <Market> 0x38bb39d3455c9ab9596b6ddbdd0e9f6d06a6d98609d16fa00df0a9d840121780
0x00000000000000000000000000000000000000000000000000000000000001f4
```

`assetConfig`の項目の欄（`cast index address AAAA 3` = `0xff04a2f18f82db7935babf1bcde07e62bb1da970a6be525e37ecc16f3fe97988`）はdeleteのあと0で、`totalDeposits`の項目の欄（`cast index address AAAA 5` = `0xee6b9c9ae8956039f0ca8ff6a58cb4f46142be0e97ada49c266e83ef83adf4d5`）は`0x1f4`のままである。

Tern。リテラルの枝の`255 + (c ? 1 : 0)`はいちばん小さな型（uint8）で計算され、cがtrueなら巻き戻る：

```
$ cast call <Tern> "lit(bool)(uint256)" true
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call <Tern> "lit(bool)(uint256)" false
255
```

| 関数 | 式 | 入れた値 | 結果 |
|---|---|---|---|
| `fixedLit` | `255 + (c ? uint256(1) : 0)` | c = true | 256 |
| `wrapped` | `c ? a : uint256(b)` | c = false、a = 5、b = -1 | 115792089237316195423570985008687907853269984665640564039457584007913129639935 |
| `mixedWidth` | `c ? a : b`（uint8、uint16、戻り値はuint16） | c = true、a = 200、b = 1000 | 200 |

### 試すときの注意

- `delete x`は、xにその型の初期値を代入する。欄が消えるわけではなく、マッピング全体には使えず、構造体の中のマッピングのフィールドの項目も消さない。
- `arr[i++] += 1`で、iは1回だけ増える。`a += e`を`a = a + e`にほどいて読み、左の式を2回計算すると考えると間違える。
- シフト代入（`<<=`）にはあふれチェックがない。128を左に1つずらすと、uint8では0になる。
- 新しいanvilでOps、LedgerTotal、Wipe、MemDelete、MapStruct、Ternの順にデプロイすると、アドレスは`0x5FbDB2315678afecb367f032d93F642f64180aa3`、`0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、`0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、`0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、`0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、`0x5FC8d32690cc91D4c39d9d3abcBD16989F875707`である。

## 時効性のあるデータ

基準日時点の値。ハードフォークとツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Types、Operatorsの節のTernary Operator・Compound and Increment/Decrement Operators・delete、v0.8.36。三項：結果は有理数型になれず、二つの枝をmobile typeに変えてから決める、例の`255 + (true ? 1 : 0)`はあふれで巻き戻る、`1.5 + 1.5`はできて`1.5 + (true ? 1.5 : 2.5)`はできない / 複合：`a += e`は`a = a + e`と同じ、`a++`は前の値、`++a`は変わった値 / delete："assigns the initial value for the type to a"、代入のように動作、storageのローカル名での`delete y`はできない例 | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| SSTOREの返金ルール | EIP-3529（ロンドン・アップグレード、2021年8月）：0でない欄を0に戻すと4,800の返金、トランザクションの返金の上限は使ったガスの5分の1 | 2026-10-19 |
| WipeのgasUsed | fill 333,594 / wipe 73,992 / uが7のときsetU(9) 26,686、wipeU 21,460、setU(0) 21,874（setU(7)は0から7へ、43,786） | 2026-10-19 |
| そのほかのgasUsed（参考） | MapStructのfill 66,300 / wipe 21,450、LedgerTotalのアリスのdeposit 65,911 / clear 25,802、MarketのaddAsset 91,663 / アリスのdeposit 91,448 / delistAsset 24,613 / addAssetをもう一度74,563 | 2026-10-19 |
| anvilのブロックの時刻（lastUpdateの値） | 1792393499など、anvilを立ち上げた時刻が基準 | 2026-10-19 |
| テストのアドレス | 1つ目のanvil：Ops `0x5FbDB2315678afecb367f032d93F642f64180aa3`、LedgerTotal `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Wipe `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、MemDelete `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、MapStruct `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、Tern `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707` / 2つ目のanvil：Market `0x5FbDB2315678afecb367f032d93F642f64180aa3` / アカウント0番`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（デプロイ・管理者）、1番アリス`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`（anvilの既定のアカウント、公開されたテスト用の鍵） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 一つの文の中の計算の順番（左の欄と右の値のどちらを先に計算するか） | [第85講](../../part5/lecture85/) |
| 複数を一度に受け取る代入（分割代入） | [第86講](../../part5/lecture86/) |
| deleteと宣言の範囲、代入のルールのまとめ | [第86講](../../part5/lecture86/)、[第87講](../../part5/lecture87/) |
| 演算子の優先順位と演算子の一覧 | [第126講](../../part7/lecture126/) |
| 0に戻す書き込みのガスの判断、保存の最適化の優先順位 | [第143講](../../part9/lecture143/) |
| 資産を外す状態遷移の設計 | [第152講](../../part9/lecture152/) |
| 監査でdeleteとマッピングを含む構造体、三項式の型を見つける方法 | [第188講](../../part12/lecture188/) |
| ユーザー定義の値型に演算子をつける | [第118講](../../part6/lecture118/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
