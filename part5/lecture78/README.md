# 第78講 ABIのエンコード・デコードの関数

第5部 言語の詳細 ② グローバル変数と制御構造・第17章 単位とグローバル変数

[← 第77講](../../part5/lecture77/) | [第5部 目次](../) | [第79講 →](../../part5/lecture79/)

## この講義の問い

値をバイトにする関数五つと、ほどく関数一つは、それぞれ何を書き、何を確かめるのか。

## 実習資料

### 準備

空のFoundryプロジェクト二つから始める。`demo`はビルドが通るバージョン、`errors`はビルドエラーを見るバージョンである。どちらもfoundry.tomlで`solc = "0.8.30"`に固定し、テストにはforge-std（`lib/forge-std`）が必要である。Enc、Dec、Marketはローカルのanvilに既定のアカウント0番（anvilの公開されたテスト用の鍵）で`forge create`し、アリスは既定のアカウント1番である。`errors`のファイルは`forge build --offline --force src/<ファイル>`で一つずつビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Enc.sol](code/demo/src/Enc.sol) | エンコード関数五つを同じ引数で呼ぶ`five`、シグネチャの打ち間違い`typo`、文字列の引数`wrongArg`、encodePackedのサイズと衝突の例 |
| [code/demo/src/Dec.sol](code/demo/src/Dec.sol) | `abi.decode`で同じバイトをいくつかの型で読む関数、`msg.data[4:]`をほどく`take` |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket（第72講のバージョン）のIERC20に`transferFrom`の宣言を足し、送るバイトを返すデモ用の`pullCalldata`をつけたバージョン |
| [code/demo/test/PullBytes.t.sol](code/demo/test/PullBytes.t.sol) | 受け取ったcalldataを記録しておくテスト用トークンで、型つきの呼び出しが送ったバイトと`abi.encodeCall`の結果を比べる |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/CallWrong.sol](code/errors/src/CallWrong.sol) | `abi.encodeCall`に文字列の引数、Error 5407 |
| [code/errors/src/CallCount.sol](code/errors/src/CallCount.sol) | `abi.encodeCall`の引数が一つ足りない、Error 7515 |
| [code/errors/src/PackStruct.sol](code/errors/src/PackStruct.sol) | 構造体を`abi.encodePacked`、Error 9578 |
| [code/errors/src/PackNested.sol](code/errors/src/PackNested.sol) | 入れ子の配列を`abi.encodePacked`、Error 9578 |

### 実行結果

`abi.encode`は値一つを32バイトの欄一つにし、文字列はオフセット・長さ・中身の三つの欄にする（`u8()`、`str()`）。

```
$ cast call $ENC "str()(bytes)"
0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000036162630000000000000000000000000000000000000000000000000000000000
$ cast abi-encode "f(bytes3)" 0x616263
0x6162630000000000000000000000000000000000000000000000000000000000
$ cast abi-encode "f(uint24)" 0x616263
0x0000000000000000000000000000000000000000000000000000000000616263
```

`five(100)`: 上から`abi.encode`、`abi.encodePacked`、`abi.encodeWithSelector`、`abi.encodeWithSignature`、`abi.encodeCall`。下の三つは同じバイトである。

```
$ cast call $ENC "five(uint256)(bytes,bytes,bytes,bytes,bytes)" 100
0x000000000000000000000000000000000000000000000000000000000000beef0000000000000000000000000000000000000000000000000000000000000064
0x000000000000000000000000000000000000beef0000000000000000000000000000000000000000000000000000000000000064
0xa9059cbb000000000000000000000000000000000000000000000000000000000000beef0000000000000000000000000000000000000000000000000000000000000064
0xa9059cbb000000000000000000000000000000000000000000000000000000000000beef0000000000000000000000000000000000000000000000000000000000000064
0xa9059cbb000000000000000000000000000000000000000000000000000000000000beef0000000000000000000000000000000000000000000000000000000000000064
```

シグネチャの文字列に`uint`を使ったり空白を入れたりした`typo(100)`。セレクタがそれぞれ0x6cb927d8、0x9d61d234に変わる（`cast keccak`の先頭4バイトと同じ）。

```
0x6cb927d8000000000000000000000000000000000000000000000000000000000000beef0000000000000000000000000000000000000000000000000000000000000064
0x9d61d234000000000000000000000000000000000000000000000000000000000000beef0000000000000000000000000000000000000000000000000000000000000064
```

`abi.encodeCall`のビルドエラー。

```
Error (5407): Cannot implicitly convert component at position 1 from "literal_string "1"" to "uint256".
Error (7515): Expected a tuple with 2 components instead of a single non-tuple parameter.
```

`packedSizes()`と`collide()`。encodePackedはアドレスを20バイト、文字列を中身だけでつなぐが、配列の要素は32バイトずつ埋める。`"a"+"bc"`と`"ab"+"c"`は、encodePackedでは同じバイト、encodeでは違うバイトになる。

```
$ cast call $ENC "packedSizes()(bytes,bytes,bytes)"
0x000000000000000000000000000000000000beef
0x616263
0x00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002
$ cast call $ENC "collide()(bytes,bytes,bytes,bytes)"
0x616263
0x616263
0x000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000026263000000000000000000000000000000000000000000000000000000000000
0x000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000002616200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016300000000000000000000000000000000000000000000000000000000000000
```

構造体をencodePackedに入れると、ビルドエラーになる。

```
Error (9578): Type not supported in packed mode.
```

`abi.decode`がリバートする四つ：バイトが足りない`pair`、上位12バイトが`ff`のアドレス、2のbool、文字列として読めないバイト。どれもリバートデータなしでリバートする。

```
$ cast call $DEC "pair(bytes)(uint256,address)" 0x0000000000000000000000000000000000000000000000000000000000000064
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call $DEC "asAddress(bytes)(address)" 0xffffffffffffffffffffffff000000000000000000000000000000000000beef
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call $DEC "asBool(bytes)(bool)" 0x0000000000000000000000000000000000000000000000000000000000000002
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

順番を入れ替えてほどく`pairSwapped`はリバートせず、`0x0000000000000000000000000000000000000064`、`48879`を返す。`"abc"`をエンコードした96バイトを`asString`でほどくと`"abc"`になる。

Marketの`pullCalldata(500)`をアリスで呼んだ結果と`cast calldata`。同じ100バイトである。

```
$ cast call $MARKET "pullCalldata(uint256)(bytes)" 500 --from $ALICE
0x23b872dd00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8000000000000000000000000dc64a140aa3e981100a9beca4e685f962f0cf6c900000000000000000000000000000000000000000000000000000000000001f4
$ cast calldata "transferFrom(address,address,uint256)" $ALICE $MARKET 500
0x23b872dd00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8000000000000000000000000dc64a140aa3e981100a9beca4e685f962f0cf6c900000000000000000000000000000000000000000000000000000000000001f4
```

`forge test`の`test_sameBytes`は通る。テスト用トークンが受け取った`msg.data`と`abi.encodeCall`の結果が同じで、長さは100バイトである。

### 試すときの注意

- `abi.encodeWithSignature`は文字列をそのままハッシュする。`uint`や空白が混ざるとセレクタが変わるが、ビルドは通る。一方`cast sig "transfer(address,uint)"`は`uint`を`uint256`に直して計算し0xa9059cbbを返すので、二つを比べるときは注意する。
- 型を確かめてくれるのは`abi.encodeCall`だけである。`abi.encodeWithSelector(IERC20.transfer.selector, TO, "1")`のように型が違う引数でもビルドが通り、別のバイトが出てくる。
- encodePackedで可変長の値を二つ以上つなぐと、違う入力が同じバイトになることがある。固定サイズの値だけをつなぐか、encodeを使う。
- `cast calldata`の結果に出るMarketのアドレスは、デプロイの順番で決まる。新しいanvilでEnc、Dec、Marketの順にデプロイすると同じアドレスになる（Decは`pairSwapped`を足すためにさらに2回デプロイした）。
- このバージョンの`pullCalldata`は、バイトを見せるだけのデモ用である。トークンを実際には動かさない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| `abi.encodeCall`の導入 | solc 0.8.11 | 2026-10-19 |
| ABI coder v2の既定値 | solc 0.8.0から既定（それ以前は`pragma abicoder v2`） | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| test_sameBytesのガス | 587,404 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| encodePacked・encodeのバイトをkeccak256に入れるハッシュの材料、同じバイトが同じハッシュになること | [第79講](../../part5/lecture79/) |
| 作ったバイトを低水準の呼び出し（`call`）で送り、戻り値を受け取ること | [第83講](../../part5/lecture83/)、[第122講](../../part7/lecture122/) |
| 失敗データをほどくこと（リバート理由のバイト） | [第91講](../../part5/lecture91/) |
| セレクタの計算の詳細とセレクタの衝突 | [第101講](../../part6/lecture101/) |
| カスタムエラーのエンコード | [第108講](../../part6/lecture108/) |
| ABIエンコードの規則全体（入れ子の動的型、オフセットの計算、タプル） | [第141講](../../part8/lecture141/) |
| msg.dataをそのまま渡すプロキシとセレクタのルーティング | [第160講](../../part10/lecture160/)、[第163講](../../part10/lecture163/) |
| transferFromの戻り値の確認と、標準を守らないトークン | [第171講](../../part11/lecture171/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
