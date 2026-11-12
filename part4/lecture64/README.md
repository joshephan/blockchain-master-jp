# 第64講 データの場所とガスのコスト

第4部 言語の詳細 ① ファイルと型・第14章 参照型

[← 第63講](../../part4/lecture63/) | [第4部 目次](../) | [第65講 →](../../part4/lecture65/)

## この講義の問い

第62講・第63講で見た場所とコピーの違いは、ガスにしてどれだけの違いで、その違いはどこでつくのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクトから、Counterのファイルを消して始める。テストにはforge-stdが必要である（`lib/forge-std`）。デプロイと呼び出しはローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を使って行い、ガスは`cast send ... --json`の`gasUsed`で測る。要素1,000個以上の配列は、calldataがWindowsのコマンドラインの長さの上限を超えるので、anvilのロック解除された0番のアカウントで`eth_sendTransaction`を送る短いスクリプトで送った（セレクター`0x0194db8e`のあとにABIエンコードした配列をつける）。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/Sum.sol](code/src/Sum.sol) | 同じ合計を、memoryパラメーター（SumMemory）とcalldataパラメーター（SumCalldata）で受け取る二つの版 |
| [code/src/Holder.sol](code/src/Holder.sol) | storage配列をmemoryに丸ごとコピーして読む（readCopy）、storageの名前で読む（readRef）、同じ欄を1回・3回読む |
| [code/src/MemGrow.sol](code/src/MemGrow.sol) | 長さnのmemory配列を作るだけの関数（メモリ拡張のコストの測定） |
| [code/src/Store.sol](code/src/Store.sol) | memoryの中だけで埋める（build）、埋めたあとstorageに代入する（put） |
| [code/src/Batch.sol](code/src/Batch.sol) | 金額のリストを足す`addAll`。最初に`memory`でスナップショットを撮り、そのあと`calldata`に変えた最終版 |
| [code/test/Batch.t.sol](code/test/Batch.t.sol) | 要素10個・100個でaddAllを呼ぶテスト |
| [code/err/CdWrite.sol](code/err/CdWrite.sol) | calldata配列に書く行。ビルドが拒否される（srcに入れて確かめたあと削除） |

### 実行結果

CdWriteをsrcに入れて`forge build --offline`：

```
Error: Compiler run failed:
Error (6182): Calldata arrays are read-only.
 --> src/CdWrite.sol:6:9:
  |
6 |         xs[0] = 1;
  |         ^^^^^
```

SumMemory（mem）とSumCalldata（cd）に長さnの配列を送った結果。二つの版のcalldataのバイト数は同じで、gasUsedだけが違う。floorはEIP-7623の下限（21,000 + 10 × トークン数、トークン = 0のバイトは1、0でないバイトは4）である：

```
mem n=10 bytes=388 tokens=436 floor=25360 gasUsed=29077 status=0x1
cd  n=10 bytes=388 tokens=436 floor=25360 gasUsed=26470 status=0x1
mem n=100 bytes=3268 tokens=3586 floor=56860 gasUsed=89128 status=0x1
cd  n=100 bytes=3268 tokens=3586 floor=56860 gasUsed=66520 status=0x1
mem n=1000 bytes=32068 tokens=37315 floor=394150 gasUsed=700299 status=0x1
cd  n=1000 bytes=32068 tokens=37315 floor=394150 gasUsed=475936 status=0x1
mem n=2000 bytes=64068 tokens=75303 floor=774030 gasUsed=1385134 status=0x1
cd  n=2000 bytes=64068 tokens=75303 floor=774030 gasUsed=932888 status=0x1
mem n=3000 bytes=96068 tokens=113291 floor=1153910 gasUsed=2073875 status=0x1
cd  n=3000 bytes=96068 tokens=113291 floor=1153910 gasUsed=1389840 status=0x1
```

すべての測定でgasUsedが下限より大きく、下限は結果を変えなかった。

Holderの測定。`fill`は累積なので、長さを10、100、1,000と増やしながら測った。readRefは長さに関係なく同じで、readCopyは長さの分だけ増える：

```
fill10            292302
readCopy len10:   45763
readRef  len10:   26108
fill90            2068102
readCopy len100:  239554
readRef  len100:  26108
readCopy len1000: 2179209
readRef  len1000: 26108
once:   23497
thrice: 24132
```

anvilを`--steps-tracing`で立ち上げ、`debug_traceTransaction`で見た実行トレースでは、`readRef(3)`はSLOAD 2100が2回、KECCAK256 36、calldata 36バイトで、`readOnce()`はSLOAD 2100が1回、calldata 4バイトだった。`cast call`で読むと、`readThrice()`は21、`readCopy(3)`と`readRef(3)`はどちらも4である。

MemGrowの`make(n)`のgasUsed（`--gas-limit 16000000`）。長さが2倍になるとき、ガスは2倍より速く増える：

```
0 21876
1000 29928
2000 41811
4000 77295
8000 195139
16000 618327
32000 2214690
```

Storeに要素100個：`build`は53243、`put`は2292379。そのあとの`s(99)`は100である。

`forge snapshot --offline`（memory版）：

```
BatchTest:test_AddAll10() (gas: 65909)
BatchTest:test_AddAll100() (gas: 177904)
```

Batchの`memory`を`calldata`に変えて`forge snapshot --offline --diff`：

```
↓ BatchTest::test_AddAll10() (gas: 65909 → 63299 | -2610 -3.960%)
↓ BatchTest::test_AddAll100() (gas: 177904 → 155293 | -22611 -12.710%)

--------------------------------------------------------------------------------
Total tests: 2, ↑ 0, ↓ 2, ━ 0
Overall gas change: -25221 (-10.344%)
```

anvilのアカウント0からアカウント1へ、データだけを載せて送ったトランザクションのgasUsed（calldataのバイトの下限の確認）：

```
データなし             21000
0x00のバイト100個      22000
0x01のバイト100個      25000
```

### 試すときの注意

- 新しいanvilでアカウント0が順にデプロイしたとき、アドレスはSumMemory `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、SumCalldata `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、Holder `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707`、MemGrow `0xE6E340D132b5f46d1e472DebcD681B2aBc16e57E`だった。前のデプロイの数によって変わる。
- 要素の多い配列を`cast send`の引数として渡すと、Windowsではコマンドラインの長さの上限に引っかかる。RPCで直接送る方法を使う。
- MemGrowの大きなnは既定のガスリミットを超えることがあるので、`--gas-limit`を与える。

## 時効性のあるデータ

基準日時点の値。ハードフォークとツールのバージョンが変わると、ガスの数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のReference Types / Data location、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3、anvilの既定のハードフォークの表記は`Bpo1` | 2026-10-19 |
| sumの二つの版のgasUsed（memory / calldata） | 10個29,077 / 26,470、100個89,128 / 66,520、1,000個700,299 / 475,936、2,000個1,385,134 / 932,888、3,000個2,073,875 / 1,389,840 | 2026-10-19 |
| sumの呼び出しのcalldataのサイズ | 10個388バイト、100個3,268バイト、1,000個32,068バイト | 2026-10-19 |
| readCopy / readRefのgasUsed | 長さ10で45,763 / 26,108、100で239,554 / 26,108、1,000で2,179,209 / 26,108 | 2026-10-19 |
| readOnce / readThriceのgasUsed | 23,497 / 24,132 | 2026-10-19 |
| MemGrowのmake(n)のgasUsed | 0 21,876 / 1,000 29,928 / 2,000 41,811 / 4,000 77,295 / 8,000 195,139 / 16,000 618,327 / 32,000 2,214,690 | 2026-10-19 |
| Storeのbuild / put（要素100個） | 53,243 / 2,292,379 | 2026-10-19 |
| forge snapshot | memory版65,909 / 177,904、calldata版63,299 / 155,293 | 2026-10-19 |
| MLOAD / MSTORE / CALLDATALOAD | それぞれ3ガス（MLOAD・MSTOREは + メモリ拡張のコスト） | 2026-10-19 |
| SLOAD | コールドアクセス2,100 / ウォームアクセス100ガス、ベルリン（2021.04）以降 | 2026-10-19 |
| SSTORE、0から0でない値へ | 20,000ガス（コールドな欄なら + 2,100） | 2026-10-19 |
| メモリ拡張のコスト | ワード数をaとすると3 × a + a² ÷ 512、広がった分の差を払う（32,000個：a ≈ 32,005、約210万） | 2026-10-19 |
| calldataのバイトの価格 | 0のバイト4、0でないバイト16ガス（EIP-2028、イスタンブール2019-12） | 2026-10-19 |
| データ中心のトランザクションのcalldataの下限 | 0のバイト10、0でないバイト40ガス相当の下限（EIP-7623、プラハ2025-05）。anvilでの実測：空のトランザクション21,000 / 0のバイト100個22,000 / 0x01のバイト100個25,000 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `new`でmemory配列を作ることと長さのルール | [第67講](../../part4/lecture67/) |
| calldataのスライスでコピーなしに一部だけを使う | [第69講](../../part4/lecture69/) |
| ABIエンコードのルール（配列がcalldataに載る形） | [第78講](../../part5/lecture78/) |
| ストレージ配列の欄の配置のルール | [第66講](../../part4/lecture66/)、[第135講](../../part8/lecture135/) |
| memoryの配置と広げるコストの正確な計算 | [第137講](../../part8/lecture137/) |
| ガスをどこまで減らすかの判断（欄をまとめる、キャッシュ、いつやめるか） | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 際限なく伸びる配列をなめる関数 | [第66講](../../part4/lecture66/)、[第150講](../../part9/lecture150/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
