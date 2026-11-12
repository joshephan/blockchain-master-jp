# 第69講 配列のスライス

第4部 言語の詳細 ① ファイルと型・第14章 参照型

[← 第68講](../../part4/lecture68/) | [第4部 目次](../) | [第70講 →](../../part4/lecture70/)

## この講義の問い

すでに入ってきている入力のバイトの一区間だけを使いたいとき、なぜ移し替えなくてよく、その文法はなぜcalldataでしか使えないのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクト（`demo/`）から、Counterのファイルを消して始める。文字列のスライスはdemoをコピーした別のプロジェクト`str/`で、コンパイルが拒否される例はdemoをコピーした別のプロジェクト`bad/`で見る。テストにはforge-stdが必要である（`lib/forge-std`）。デプロイはローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を使って行い、ビルドはすべて`--offline`である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/demo/src/Slicer.sol](code/demo/src/Slicer.sol) | 先頭4バイトを外す三つの版（繰り返し文によるコピー`restLoop`、スライス`restSlice`、スライスをmemoryに入れる`restCopy`）、三つの区間（`parts`）、セレクターの取り出し（`selectorOf`）、配列のスライスの合計（`sumTail`） |
| [code/demo/src/OnlyCopy.sol](code/demo/src/OnlyCopy.sol) | `restCopy`だけを置いたコントラクト（アセンブリのCALLDATACOPYの確認用） |
| [code/demo/src/OnlySlice.sol](code/demo/src/OnlySlice.sol) | `restSlice`だけを置いたコントラクト |
| [code/demo/test/Gas.t.sol](code/demo/test/Gas.t.sol) | 100バイト・200バイトの入力で三つの版を呼ぶ、ガスの比較のテスト |
| [code/str/src/StrSlice.sol](code/str/src/StrSlice.sol) | `string calldata`の先頭3バイトのスライス |
| [code/str/test/StrSlice.t.sol](code/str/test/StrSlice.t.sol) | `"あい"`の先頭3バイトを出力するテスト |
| [code/bad/src/](code/bad/src/) | memory・storage配列のスライス、スライス・calldataパラメーターへの書き込みの例 |

`code/bad/src/`のファイルとエラー：

| ファイル | 行 | エラー |
|---|---|---|
| BadMem.sol | `return data[4:];`（bytes memory） | Error (1227)、Error (6359) |
| BadStore.sol | `return list[1:].length;`（storage配列） | Error (1227)、Error (9582) |
| BadWrite.sol | スライス`rest`に`rest[0] = 0x01;` | Error (6182) |
| BadParam.sol | `bytes calldata`パラメーターに`data[0] = 0x01;` | Error (6182) |
| BadParam2.sol | `uint256[] calldata`パラメーターに`x[0] = 1;` | Error (6182) |

### 実行結果

`forge test --offline --match-contract GasTest --gas-report`（Slicerの行のみ）：

```
| Function Name                  | Min             | Avg   | Median | Max   | # Calls |
| restCopy                       |            1261 |  1273 |   1273 |  1285 |       2 |
| restLoop                       |           36848 | 55410 |  55410 | 73972 |       2 |
| restSlice                      |            1018 |  1018 |   1018 |  1018 |       2 |
```

同じテストを`-vvvv`で実行したトレース（Slicerの呼び出しの行のみ、引数は省略）。最初の三つが100バイト、後ろの三つが200バイトである：

```
    ├─ [36848] Slicer::restLoop(0x010203040506...)
    ├─ [1018] Slicer::restSlice(0x010203040506...)
    ├─ [1261] Slicer::restCopy(0x010203040506...)
    ├─ [73972] Slicer::restLoop(0x010203040506...)
    ├─ [1018] Slicer::restSlice(0x010203040506...)
    ├─ [1285] Slicer::restCopy(0x010203040506...)
```

アセンブリでのCALLDATACOPYの行数（`forge inspect ... assembly | grep -ci calldatacopy`）。スライスをmemoryに入れるときだけコピーが生じる：

```
OnlyCopy   1
OnlySlice  0
```

anvilにSlicerをデプロイし（`0x5FbDB2315678afecb367f032d93F642f64180aa3`）、`cast call`で呼んだ結果。`$D`は0x01から1ずつ増える100バイトである：

```
$ cast call <Slicer> "restLoop(bytes)(uint256,bytes1)" $D
96
0x05
$ cast call <Slicer> "restSlice(bytes)(uint256,bytes1)" $D
96
0x05
$ cast call <Slicer> "parts(bytes)(bytes,bytes,bytes)" 0x0102030405060708
0x01020304
0x03040506
0x05060708
$ cast call <Slicer> "sumTail(uint256[])(uint256)" "[100,1,2,3]"
6
$ cast calldata "transfer(address,uint256)" 0x0000000000000000000000000000000000000b0b 30
0xa9059cbb0000000000000000000000000000000000000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000001e
$ cast call <Slicer> "selectorOf(bytes)(bytes4)" 0xa9059cbb0000000000000000000000000000000000000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000001e
0xa9059cbb
$ cast sig "transfer(address,uint256)"
0xa9059cbb
```

入力が短いとき。3バイトに`[4:]`はデータなしで巻き戻り、4バイトはスライスが空のまま`rest[0]`でPanic 0x32、繰り返し文の版は長さの計算でPanic 0x11である。5バイトは長さ1である：

```
$ cast call <Slicer> "restSlice(bytes)(uint256,bytes1)" 0x010203
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call <Slicer> "restSlice(bytes)(uint256,bytes1)" 0x01020304
Error: execution reverted: panic: array out-of-bounds access (0x32)
$ cast call <Slicer> "restLoop(bytes)(uint256,bytes1)" 0x010203
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call <Slicer> "restSlice(bytes)(uint256,bytes1)" 0x0102030405
1
0x05
```

`str/`で`forge test --offline -vv --match-test test_head`。stringのスライスはバイト単位なので、日本語の1文字（3バイト）が出る：

```
[PASS] test_head() (gas: 12588)
Logs:
  あ
  0xe38182
```

`bad/`で`forge build --offline src/<ファイル>.sol`（位置の行は省略）：

```
$ forge build --offline src/BadMem.sol
Error (1227): Index range access is only supported for dynamic calldata arrays.
Error (6359): Return argument type bytes memory slice is not implicitly convertible to expected type (type of first return variable) bytes memory.
$ forge build --offline src/BadStore.sol
Error (1227): Index range access is only supported for dynamic calldata arrays.
Error (9582): Member "length" not found or not visible after argument-dependent lookup in uint256[] storage ref slice.
$ forge build --offline src/BadWrite.sol
Error (6182): Calldata arrays are read-only.
 --> src/BadWrite.sol:7:9:
  |
7 |         rest[0] = 0x01;
  |         ^^^^^^^
$ forge build --offline src/BadParam.sol
Error (6182): Calldata arrays are read-only.
 --> src/BadParam.sol:6:9:
  |
6 |         data[0] = 0x01;
  |         ^^^^^^^
```

### 試すときの注意

- スライスが使えるのは、calldataの動的配列だけである。memory・storage配列に`[a:b]`を使うとError (1227)になる。
- スライスは元を指しているので、直せない。直すには`bytes memory rest = data[4:];`のようにmemoryにコピーする。このときCALLDATACOPYが生じ、長さの分だけガスが増える。
- anvilで`cast send`により送ったトランザクションのgasUsedは、calldataの下限価格（EIP-7623）にかかって、restSliceとrestCopyが同じ値で出る。関数の中の実行ガスを比べるには、`--gas-report`やトレースを見る。

## 時効性のあるデータ

基準日時点の値。ハードフォークとツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Types、Reference TypesのArray Slicesの節、v0.8.36（x[start:end]、省略時は0と長さ、start > endまたはend > lengthなら例外、スライスには型の名前がなく元の型の配列に暗黙的に変換、"only implemented for calldata arrays"、Proxyの例の`bytes4(payload[:4])`） | 2026-10-19 |
| calldata配列のスライスの導入 | 0.6.0（2019-12-17）"Introduce syntax for array slices and implement them for dynamic calldata arrays." | 2026-10-19 |
| calldataのスライス → memory・storage配列への変換 | 0.7.6 | 2026-10-19 |
| bytes・bytesのスライス → bytes1〜bytes32への変換 | 0.8.5 | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 関数の実行ガス（--gas-report） | restLoop 36,848（100バイト） / 73,972（200バイト）、restSlice 1,018 / 1,018、restCopy 1,261 / 1,285 | 2026-10-19 |
| トランザクションのgasUsed（anvil、参考） | 100バイト：restLoop 59,904、restSlice 26,140、restCopy 26,140 / 200バイト：restLoop 98,612、restSlice 30,100、restCopy 30,100 | 2026-10-19 |
| トランザクションのgasUsedの解説 | スライス・コピーの版はcalldataの下限価格（EIP-7623：21,000 + トークンあたり10、トークン = 0のバイト1 + 0でないバイト4）にかかる。200バイトの版のcalldataは0でないバイト206、0のバイト86 → 910トークン → 30,100で一致。標準価格（0でないバイト16、0のバイト4、EIP-2028）より下限価格が大きいので、二つの版が同じ値 | 2026-10-19 |
| テストのアドレス | anvilにデプロイしたSlicer `0x5FbDB2315678afecb367f032d93F642f64180aa3`、デプロイのアカウントはanvilの既定のアカウント0 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（公開されたテスト用の鍵） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| スライスした引数をアドレス・数値にほどく（abi.decode） | [第78講](../../part5/lecture78/) |
| ABIエンコードのルール（オフセット、長さ、32バイトへの埋め合わせ） | [第141講](../../part8/lecture141/) |
| calldataの配置とスライスの内部表現（オフセット・長さの二つの値） | [第138講](../../part8/lecture138/) |
| セレクターで呼び出しを渡すプロキシ | [第77講](../../part5/lecture77/)、[第101講](../../part6/lecture101/) |
| 短い入力と巻き戻しの処理 | [第90講](../../part5/lecture90/) |
| 繰り返し文のコストの最適化 | [第143講](../../part9/lecture143/) |
| 入力をそのまま信じるコードの判断 | [第170講](../../part11/lecture170/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
