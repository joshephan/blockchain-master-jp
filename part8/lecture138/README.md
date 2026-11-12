# 第138講 calldataのレイアウトと変数のクリーンアップ

第8部 コンパイラと内部構造・第33章 保存配置の内部

[← 第137講](../../part8/lecture137/) | [第8部 目次](../) | [第139講 →](../../part8/lecture139/)

## この講義の問い

外部関数の引数はcalldataにどんな形で入ってきて、Solidityはそれをどう読んで確かめ、32バイトより小さい型の余るビットは誰がいつ消すのか。

## 実習資料

### 準備

calldataの欄を手で作って送ってみるデモのコントラクトC138（`demo`）と、通しプロジェクトMarketの第138講のバージョン（第137講のバージョンとコードが同じで、`test/Calldata.t.sol`を足したバージョン）を使う。solc 0.8.30、Foundry 1.8.3で、forge-stdが必要である（`lib/forge-std`）。どちらのプロジェクトもoptimizerを切り、evm_versionはosakaである。C138とMarketは同じローカルのanvilにアカウント0番でデプロイし、`cast calldata`で作った入力をバイト単位で直して`cast call`・`cast send`で送る。例に使ったアカウント1番は、anvilの既定のアカウントである。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモのプロジェクトの設定 |
| [code/demo/src/C138.sol](code/demo/src/C138.sol) | take(uint8, bool, address, int8)、dyn(uint[], bytes)と`.offset`、color(enum)、size（`msg.data.length`）、dirtyU8・dirtyBool・dirtyI8・dirtyEnum・dirtyKey（アセンブリで上位ビットを残した値） |
| [code/demo/test/Bool138.t.sol](code/demo/test/Bool138.t.sol) | ブロックの中の`eq(b, 1)`と`and(0x1ff, 0xff)`の値を出すテスト |
| [code/market/test/Calldata.t.sol](code/market/test/Calldata.t.sol) | この講義で足したテスト二つ: うしろに4バイトをつけたdepositの成功、間違ったcalldata三つはリバートデータ0バイトで失敗 |
| [code/market/](code/market/) | Market 第138講のバージョン（foundry.toml、src、test）。テスト60個 |

### 実行結果

`cast calldata "take(uint8,bool,address,int8)" 255 true <アカウント1番> -1`（セレクタの4バイトと32バイトの欄四つに区切って書いた、132バイト）。

```
0x8e1b6478
  00000000000000000000000000000000000000000000000000000000000000ff
  0000000000000000000000000000000000000000000000000000000000000001
  00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
  ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
```

`cast calldata "dyn(uint256[],bytes)" "[1,2,3]" 0xabcdef`（左はセレクタを含めたバイトの番号、260バイト）。

```
0x000  6fbe1916
0x004  0000000000000000000000000000000000000000000000000000000000000040
0x024  00000000000000000000000000000000000000000000000000000000000000c0
0x044  0000000000000000000000000000000000000000000000000000000000000003
0x064  0000000000000000000000000000000000000000000000000000000000000001
0x084  0000000000000000000000000000000000000000000000000000000000000002
0x0a4  0000000000000000000000000000000000000000000000000000000000000003
0x0c4  0000000000000000000000000000000000000000000000000000000000000003
0x0e4  abcdef0000000000000000000000000000000000000000000000000000000000
```

同じ入力を`cast call`で送った答え（xs.offset、xsの長さ、bs.offset、bsの長さ、合計）。

```
100
3
228
3
6
```

xs.offset 100（0x64） = セレクタ4 + 頭の値0x40 + 長さの欄32、bs.offset 228（0xe4） = 4 + 0xc0 + 32である。

C138に手で直したcalldataを送った結果。

| 送ったもの | 結果 |
|---|---|
| takeのcalldataのうしろに`deadbeef00`の5バイト | つけない答えとバイトまで同じ |
| `size()` / `size()`のうしろに3バイト | 4 / 7 |
| takeのcalldataから最後の1バイトを抜く（131バイト） | リバート、データ`0x` |
| uint8の欄に`0x…01ff` | リバート、データ`0x` |
| boolの欄に`0x…02` | リバート、データ`0x` |
| addressの欄の先頭のバイトを`01` | リバート、データ`0x` |
| int8の欄に`0x…00ff`（符号を上に埋めない） | リバート、データ`0x` |
| `color(2)` / `color(3)`（`enum Color { Red, Green, Blue }`） | `…02` / リバート、データ`0x` |
| dynの2番目の頭を0xc0から0x40に（同じ尾を指す二つの頭） | 通る: xo 0x64、xl 3、bo 0x64、bl 3、sum 6 |
| dynの最初の頭を0x1000に（260バイトの外） | リバート、データ`0x` |

アセンブリで上位ビットを残した値を`cast call`で呼んだ結果。

```
dirtyU8()(uint8,bool,uint256,uint256) -> 255 | true | 255 | 511
dirtyBool()(bool,bool,bool,uint256) -> true | true | true | 2
dirtyI8()(int8,int256) -> -1 | -1
dirtyEnum()(uint8) -> "0x4e487b710000000000000000000000000000000000000000000000000000000000000021"
dirtyKey 7 | 7
```

dirtyU8は、ブロックで`x := 0x1ff`を入れ、Solidityの行で`x == 0xff`、`uint256(x)`、戻り値、ブロックで読み直した値を返す。dirtyKeyは、`k := 0x101`で`m[k] = 7`を書いてから、`m[1]`と`m[k]`を読む。デモのプロジェクトの`forge test --match-path test/Bool138.t.sol -vv`のログは、`eq(b, 1)`が0、`and(0x1ff, 0xff)`が255である。

Marketのデプロイのトランザクションの入力（`cast tx <デプロイのトランザクション> input`、作成のコードの部分を縮め、末尾の96バイトを32バイトずつ区切った）。

```
0x6080…（作成のコード7,931バイト）
  000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
  00000000000000000000000000000000000000000000000000b1a2bc2ec50000
  0000000000000000000000000000000000000000000000000000000000000050
```

作成のコードの先頭の命令（`cast disassemble`）。

```
00000000: PUSH1 0xe0
00000002: PUSH1 0x40
00000004: MSTORE
…
00000011: PUSH1 0x40
00000013: MLOAD
00000014: PUSH2 0x1efb
00000017: CODESIZE
00000018: SUB
00000019: DUP1
0000001a: PUSH2 0x1efb
0000001d: DUP4
0000001e: CODECOPY
```

0x1efb = 7,931が引数の開始位置で、長さはCODESIZEから引く。

同じanvilのMarketに、addAsset 75のあと手で作ったcalldata四つを送った結果（失敗する三つは`--gas-limit 300000`）。

| 送ったもの | バイト | status | gasUsed |
|---|---|---|---|
| deposit(トークン, 100) + `cafebabe` | 68 + 4 | 1、残高100 | 130,542 |
| depositの最後の1バイトを抜く | 67 | 0 | 22,390 |
| depositのアドレスの欄の先頭のバイトを`ff` | 68 | 0 | 22,460 |
| setStatus(3) | 36 | 0 | 21,533 |

`forge test --match-path test/Calldata.t.sol`と、Market 第138講のバージョンのビルド・テスト。

```
[PASS] test_badInputsRevertEmpty() (gas: 92611)
[PASS] test_extraBytesIgnored() (gas: 143109)

$ forge build --offline --force --sizes
| Market      | 7,353            | 7,931             | 17,223             | 41,221              |
$ forge test --offline
Ran 18 test suites …: 60 tests passed, 0 failed, 0 skipped (60 total tests)
$ FOUNDRY_PROFILE=ir forge test --offline
Ran 18 test suites …: 60 tests passed, 0 failed, 0 skipped (60 total tests)
```

Marketの関数のcalldataのバイトは、4 + 32 × 引数の数である: addAsset 68（Ratioはuint8だが欄は32バイト）、setStatus 36、deposit・withdraw 68、withdrawAll 36、assetCount 4、collateralCount 36、elapsedOf 68、interestFor 100。

### 試すときの注意

- calldataは、小さな型でも引数ごとに32バイトの欄に入ってくる（ストレージのようにまとめない）。長さがわからない引数は、頭の欄に開始位置だけを書き、中身は尾につく。頭の値は、セレクタのうしろの最初のバイト（0x004）から数える。
- ABIデコーダ（ABIコーダv2、0.8の既定）は、引数を読みながら、範囲外の値、足りないcalldata、calldataの外を指す頭を、リバートデータ0バイトでリバートする。0x1ffを0xffに切り詰めてはくれない。
- うしろに残るバイトと、同じ尾を指す二つの頭は確かめない。バイトが違う二つのcalldataが同じ呼び出しになりうるので、msg.data全体のハッシュで呼び出しを区別してはいけない。
- アセンブリで入れた値の上位ビットは、コンパイラがその値を使う演算（比較、型変換、メモリへの書き込み、ハッシュ）の前に消す。ブロックの中で読み直すと消す前の値が出て、`JUMPI`の条件に使うboolは消さない。ブロックの中で使う値は、`and(x, 0xff)`のように自分でクリーンアップする。
- ドキュメントのクリーンアップの表の符号つき・符号なしの整数の行は"currently … may throw an exception in the future"と書かれていて、バージョンごとに変わりうる。
- コンストラクタの引数は、デプロイのトランザクションの入力の作成のコードのうしろに、ABIの形でつく。Marketのadminがアカウント0番だという事実はソースになく、その末尾の96バイトにある。
- うしろにつけた4バイトの分だけ、calldataのガスが増える（0でないバイト16、0のバイト4。deposit 100が130,478から130,542に）。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンやソースのコメントが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ・通しプロジェクトともevm_version osaka、optimizerは切る | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| ABIコーダ | v2が0.8の既定。範囲外の値・足りないcalldata・範囲外のオフセットはリバート（データ0バイト）、うしろに残るバイトと同じ尾を指す二つの頭は通る | 2026-10-20 |
| ドキュメントのクリーンアップの表 | "currently … may throw an exception in the future"の行は、バージョンごとに変わりうる | 2026-10-20 |
| コンストラクタの引数の読み取り | solc 0.8.30の既定の経路のMarketの作成のコード`0x14: PUSH2 0x1efb CODESIZE SUB DUP1 PUSH2 0x1efb DUP4 CODECOPY`（開始位置は固定、長さをCODESIZEから引く） | 2026-10-20 |
| calldataのガス | 0でないバイト16、0のバイト4（EIP-2028）。deposit 100 + `cafebabe` 130,542 / つけないdeposit 100 130,478 | 2026-10-20 |
| デモの実測 | C138の次にデプロイしたMarket 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0、失敗する三つのgasUsed 22,390 / 22,460 / 21,533、デプロイのトランザクションの入力8,027バイト | 2026-10-20 |
| 通しプロジェクトのガス | 第138講のバージョン、新しいanvil、ブロック間隔1秒: デプロイ1,645,279、addAsset 75 93,730、deposit 100 130,478、withdraw 30 59,911、setStatus 1 45,732、setStatus 0 23,820、失敗するdeposit 0 26,869 | 2026-10-20 |
| セレクタ | take 0x8e1b6478、dyn 0x6fbe1916、size 0x949d225d、color 0x98ed54cf、deposit 0x47e7ef24、setStatus 0x2e49d78b | 2026-10-20 |
| 行番号 | 第138講のバージョンのdeposit 0のリバートはsrc/Market.sol 148:33。バージョンを説明するコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`、アカウント1番`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`（anvilの既定のアカウント） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ABIエンコードの規則の全体（頭・尾のオフセットの計算、標準の形、`abi.encode`・`encodePacked`） | [第141講](../../part8/lecture141/) |
| メタデータとコンストラクタの引数の検証 | [第142講](../../part8/lecture142/) |
| 余るバイトをつけて送る側と、署名されたcalldata | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/)、[第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| 標準の形でないcalldataを受け取るコードの監査 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| ほかの人がデプロイしたコードのcalldataを読む | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| バージョンごとに変わるクリーンアップの動作 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
