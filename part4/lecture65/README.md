# 第65講 固定サイズの配列

第4部 言語の詳細 ① ファイルと型・第14章 参照型

[← 第64講](../../part4/lecture64/) | [第4部 目次](../) | [第66講 →](../../part4/lecture66/)

## この講義の問い

長さが型に書かれた配列は、この機械でどう場所を占め、長さを前もって知っているということは何を可能にするのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクトから、Counterのファイルを消して始める。コンパイルが拒否される例はsrcの外の`bad/`に置き、パスを指定して別々にビルドする（`forge build --offline bad/VarLength.sol`）。デプロイと呼び出しは、ローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を使って行う。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/Slots.sol](code/src/Slots.sol) | `uint256[10]`の状態配列と後ろの変数`tail`、欄の書き込み・読み取り・長さ・delete |
| [code/src/Small.sol](code/src/Small.sol) | `uint8[10]`の状態配列（一つの欄にすべて入る） |
| [code/src/Grid.sol](code/src/Grid.sol) | 2次元の固定配列`uint256[2][3]` |
| [code/src/Alias.sol](code/src/Alias.sol) | memoryの固定配列どうしの代入（別名）と、状態変数どうしの代入（コピー） |
| [code/src/SumGas.sol](code/src/SumGas.sol) | 長さ10・100・1000の配列の合計（Sum10、Sum100、Sum1000） |
| [code/src/AssetList.sol](code/src/AssetList.sol) | レンディングプロトコルの資産リストを`address[8]`で持つ版と、登録数の数え上げ |

`code/bad/`のファイルとエラー：

| ファイル | 行 | エラー |
|---|---|---|
| [VarLength.sol](code/bad/VarLength.sol) | `uint256[n] public slots;`（nは状態変数） | Error (5462) |
| [NoLocation.sol](code/bad/NoLocation.sol) | 関数の中の`uint256[3] a;` | Error (6651) |
| [PushFixed.sol](code/bad/PushFixed.sol) | `slots.push(1);` | Error (9582) |
| [SetLength.sol](code/bad/SetLength.sol) | `slots.length = 20;` | Error (7567) |

### 実行結果

`forge inspect --offline <コントラクト> storageLayout`（見出しの行は省略）。固定配列は長さの分だけ欄を占め、後ろの変数はその次の欄に来る：

```
| slots | uint256[10] | 0    | 0      | 320   | src/Slots.sol:Slots |
| tail  | uint256     | 10   | 0      | 32    | src/Slots.sol:Slots |
| small | uint8[10] | 0    | 0      | 32    | src/Small.sol:Small |
| tail  | uint256   | 1    | 0      | 32    | src/Small.sol:Small |
| a    | uint256[2][3] | 0    | 0      | 192   | src/Grid.sol:Grid |
| x    | uint256[3] | 0    | 0      | 96    | src/Alias.sol:Alias |
| y    | uint256[3] | 3    | 0      | 96    | src/Alias.sol:Alias |
| assets | address[8]                  | 0    | 0      | 256   | src/AssetList.sol:AssetList |
| status | enum AssetList.MarketStatus | 8    | 0      | 1     | src/AssetList.sol:AssetList |
```

`bad/`のビルド：

```
$ forge build --offline bad/VarLength.sol
Error: Compiler run failed:
Error (5462): Invalid array length, expected integer literal or constant expression.
 --> bad/VarLength.sol:6:13:
$ forge build --offline bad/NoLocation.sol
Error (6651): Data location must be "storage", "memory" or "calldata" for variable, but none was given.
 --> bad/NoLocation.sol:6:9:
$ forge build --offline bad/PushFixed.sol
Error (9582): Member "push" not found or not visible after argument-dependent lookup in uint256[10] storage ref.
 --> bad/PushFixed.sol:8:9:
$ forge build --offline bad/SetLength.sol
Error (7567): Member "length" is read-only and cannot be used to resize arrays.
 --> bad/SetLength.sol:8:9:
```

Slots。`set(3, 42)`のgasUsedは44080、`set(2, 0)`は24168。3番の欄だけが`0x...2a`で、2・5・10番の欄は0である。範囲外の読み取りと書き込みは、Panic 0x32で巻き戻る：

```
$ cast call <Slots> "get(uint256)(uint256)" 10
Error: execution reverted: panic: array out-of-bounds access (0x32)
  data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000032"
$ cast send <Slots> "set(uint256,uint256)" 10 1
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: panic: array out-of-bounds access (0x32), data: "0x4e487b71...0032": Panic(50)
```

`clearOne(3)`はgasUsed 21907で3番の欄を0に戻し、0・4・9番の欄を埋めたあと`clearAll()`（gasUsed 41851）を呼ぶと、すべての欄が0になる。どちらの場合も`len()`は10のままである。

Small。`set(0, 1)`のgasUsedは44151、`set(9, 9)`は27113。10個の要素が0番の欄一つに入っていて、1番の欄（`tail`）は0である：

```
$ cast storage <Small> 0
0x0000000000000000000000000000000000000000000009000000000000000001
```

Grid。`outer()`は3、`inner()`は2である。`put(2, 1, 5)`（gasUsed 44401）のあと、`at(2, 1)`は5、`at(1, 2)`はPanic 0x32で巻き戻り、`cast storage <Grid> 5`が5である。`a[i][j]`は、0番のスロットから`i × 2 + j`番目の欄である。

Alias。`memoryAlias()`は`7, 7`（memoryどうしは同じ配列）で、`stateCopy()`のあと`x[0]`は1、`y[0]`は9である（状態変数どうしはコピー）。

`sum()`のgasUsed。同じ送信を2回しても値は同じである：

```
Sum10    45196   (2回目 45196)
Sum100   259126  (2回目 259126)
Sum1000  2398426
```

AssetList。空のときの`listedCount()`のgasUsedは39494、八つの欄をすべて埋めたあとは41038で、`listedCount()`は8である。7番の欄は最後の資産のアドレス、8番の欄（`status`）は0である。

`forge inspect --offline Sum10 gasEstimates`、`AssetList gasEstimates`：

```
  "external": { "sum()": "infinite", "v(uint256)": "infinite" }
  "external": { "assets(uint256)": "2794", "listedCount()": "infinite", "setAsset(uint256,address)": "24935", "status()": "2532" }
```

### 試すときの注意

- 状態変数の名前を`after`にすると、`Error (2314): Expected identifier but got reserved keyword 'after'`でビルドが止まる。そのため、後ろの変数の名前を`tail`にした。
- public getterの`slots(uint256)`に範囲外の番号10を入れると、Panicのデータなしで`execution reverted, data: "0x"`として巻き戻る。Panic 0x32を見るには、自分で書いた`get`を使う。
- 新しいanvilでアカウント0がSlots、Small、Grid、Alias、Sum10、Sum100、AssetList、Sum1000の順にデプロイすると、アドレスは`0x5FbDB2315678afecb367f032d93F642f64180aa3`、`0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、`0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、`0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、`0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、`0x5FC8d32690cc91D4c39d9d3abcBD16989F875707`、`0x0165878A594ca255338adfa4d48449f69242Eb8F`、`0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB`である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のArrays、v0.8.36（"The notation is reversed compared to some other languages."、"access is in the opposite direction of the declaration"） | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| 固定サイズの配列の保存サイズ | uint256[10] 320バイト・後ろの変数はスロット10 / uint8[10] 32バイト・後ろの変数はスロット1 / uint256[2][3] 192バイト / address[8] 256バイト・後ろの変数はスロット8 | 2026-10-19 |
| Slotsのset(2, 0)のgasUsed | 24,168（最初のset(3, 42)は44,080） | 2026-10-19 |
| SmallのsetのgasUsed | set(0, 1) 44,151 / set(9, 9) 27,113 | 2026-10-19 |
| deleteのgasUsed | clearOne(3) 21,907 / clearAll() 41,851 | 2026-10-19 |
| sum()のgasUsed | 長さ10：45,196 / 100：259,126 / 1000：2,398,426（2回目の送信も同じ値） | 2026-10-19 |
| AssetListのlistedCount()のgasUsed | 空のとき39,494 / 八つの欄を埋めて41,038 | 2026-10-19 |
| 第37講のdelegateのガス | チェーン1 / 5 / 20人：55,434 / 66,022 / 105,727（gasleft()の差、基本コストは含まない） | 2026-10-19 |
| SLOADの価格 | コールドアクセス2,100 / ウォームアクセス100 | ベルリン（2021.04）以降 |
| gasEstimates | Sum10の`sum()`："infinite"、AssetListの`listedCount()`："infinite" | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 長さを変えられる配列、push・pop | [第66講](../../part4/lecture66/) |
| メモリ配列の作成と配列リテラルの文法 | [第67講](../../part4/lecture67/) |
| 0と空の欄を見分ける印の設計 | [第71講](../../part4/lecture71/)、[第72講](../../part4/lecture72/)、[第79講](../../part5/lecture79/) |
| deleteのルール全般 | [第74講](../../part4/lecture74/) |
| 繰り返し文の文法 | [第81講](../../part5/lecture81/) |
| ストレージの欄の配置のルール全体 | [第135講](../../part8/lecture135/) |
| 最大ガスを根拠にした最適化の判断 | [第143講](../../part9/lecture143/) |
| 長さを他人が決める配列のガスの問題 | [第66講](../../part4/lecture66/)、[第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
