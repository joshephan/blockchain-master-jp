# 第68講 bytesとstring

第4部 言語の詳細 ① ファイルと型・第14章 参照型

[← 第67講](../../part4/lecture67/) | [第4部 目次](../) | [第69講 →](../../part4/lecture69/)

## この講義の問い

名前が一文字違いの`bytes32`と`bytes`はなぜ別の系統で、`string`はなぜ自分の長ささえ教えてくれないのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクトから、Counterのファイルを消して始める。コンパイルが拒否される例はsrcの外の`bad/`に置き、ファイル名をつけてビルドする（`forge build --offline bad/<ファイル>.sol`）。テストにはforge-stdが必要である（`lib/forge-std`）。デプロイは、ローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を使って行う。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/Text.sol](code/src/Text.sol) | `bytes`と`bytes1[]`の比較（Pack、PackN）、短い・長いstringの状態変数（ShortName、LongName）、storageの`bytes`へのpush（Tags）、名前と名前のハッシュを一緒に保存するMarket |
| [code/src/MarketIdOnly.sol](code/src/MarketIdOnly.sol) | 名前は保存せず、ハッシュだけを保存するMarketの版 |
| [code/src/Edge.sol](code/src/Edge.sol) | 31バイトと32バイトのstringの欄の形の比較 |
| [code/test/Text.t.sol](code/test/Text.t.sol) | 日本語の文字列のバイト長、ハッシュで同じかどうかの比較、`string.concat`・`bytes.concat`、bytesのメンバー |

`code/bad/`のファイルとエラー：

| ファイル | 行 | エラー |
|---|---|---|
| [StringLength.sol](code/bad/StringLength.sol) | `return s.length;`（string） | Error (9582) |
| [StringIndex.sol](code/bad/StringIndex.sol) | `return s[0];`（string） | Error (9961) |
| [StringPush.sol](code/bad/StringPush.sol) | `s.push(0x41);`（storageのstring） | Error (9582) |
| [StringEqual.sol](code/bad/StringEqual.sol) | `return a == b;`（string） | Error (2271) |
| [StringPlus.sol](code/bad/StringPlus.sol) | `return a + b;`（string） | Error (2271) |
| [MemoryPush.sol](code/bad/MemoryPush.sol) | `b.push(0x03);`（memoryのbytes） | Error (4994) |

### 実行結果

`forge test --offline -vv`：

```
Ran 4 tests for test/Text.t.sol:TextTest
[PASS] test_BytesMembers() (gas: 9793)
Logs:
  4
  0x03
  0x0102ff04

[PASS] test_Concat() (gas: 10211)
Logs:
  Lending Pool
  0x01020304
  4

[PASS] test_Equal() (gas: 6683)
Logs:
  true
  false

[PASS] test_KoreanLength() (gas: 9666)
Logs:
  6
  0xe38182e38184
  0xe3

Suite result: ok. 4 passed; 0 failed; 0 skipped
```

`bad/`のビルド：

```
$ forge build --offline bad/StringLength.sol
Error (9582): Member "length" not found or not visible after argument-dependent lookup in string memory.
$ forge build --offline bad/StringIndex.sol
Error (9961): Index access for string is not possible.
$ forge build --offline bad/StringPush.sol
Error (9582): Member "push" not found or not visible after argument-dependent lookup in string storage ref.
$ forge build --offline bad/StringEqual.sol
Error (2271): Built-in binary operator == cannot be applied to types string memory and string memory.
$ forge build --offline bad/StringPlus.sol
Error (2271): Built-in binary operator + cannot be applied to types string memory and string memory.
$ forge build --offline bad/MemoryPush.sol
Error (4994): Member "push" is not available in bytes memory outside of storage.
```

ほかの言語での同じ文字列の長さ（Python、Node.js）：

```
$ python -c 'print(len("あい"))'
2
$ node -e 'console.log("あい".length)'
2
$ python -c 's="\U0001F642"; print(len(s), len(s.encode()))'
1 4
$ node -e 'console.log("\u{1F642}".length)'
2
$ python -c 'e="é"; print(len(e), len(e.encode()))'
2 3
```

`cast calldata`で4バイトを`bytes`と`bytes1[]`としてエンコードすると、先頭の0xを除いて100バイトと196バイトである。0x01を32個にして同じ二行を作ると、100バイトと1,092バイトである：

```
$ cast calldata "f(bytes)" 0x01020304
0xd45754f8000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000040102030400000000000000000000000000000000000000000000000000000000
$ cast calldata "f(bytes1[])" "[0x01,0x02,0x03,0x04]"
0x2d885a1b000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000040100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000
```

PackNをanvilにデプロイし、メモリでnバイトを作ったgasUsed。n = 1000で、`makeBytes`は159213、`makeArray`は180966である。

Tagsに0x41、0x42、0x43を`add`した結果。gasUsedは44401、27301、27301で、`count()`は3である。三つのバイトと長さ × 2（06）が、0番の欄一つに入っている：

```
$ cast storage <Tags> 0
0x4142430000000000000000000000000000000000000000000000000000000006
```

ShortName（"abc"）とLongNameの欄。30バイトの名前は0番の欄の中に末尾のバイト3c（30 × 2）と一緒に入り、43バイトの名前は1番の欄に57（43 × 2 + 1）だけが残って、内容はkeccak256(1)番の欄から続く：

```
$ cast storage <ShortName> 0
0x6162630000000000000000000000000000000000000000000000000000000006
$ cast storage <LongName> 0
0x4c656e64696e6720506f6f6c20666f722057726170706564204574686572003c
$ cast storage <LongName> 1
0x0000000000000000000000000000000000000000000000000000000000000057
$ cast keccak $(cast to-uint256 1)
0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6
$ cast storage <LongName> 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6
0x4c656e64696e6720506f6f6c20666f7220577261707065642045746865722061
$ cast storage <LongName> 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf7
0x6e642055534420436f696e000000000000000000000000000000000000000000
```

Marketの`forge inspect --offline Market storageLayout`と、"ETH"でデプロイしたあとの欄：

```
| Name       | Type    | Slot | Offset | Bytes | Contract            |
| marketId   | bytes32 | 0    | 0      | 32    | src/Text.sol:Market |
| marketName | string  | 1    | 0      | 32    | src/Text.sol:Market |
$ cast storage <Market> 0
0xaaaebeba3810b1e6b70781f14b2d72c1cb89c0b2b320c43bb67ff79f562f5ff4
$ cast storage <Market> 1
0x4554480000000000000000000000000000000000000000000000000000000006
```

デプロイのgasUsed（`cast receipt <デプロイのハッシュ> gasUsed`）：

```
247514        (Market, "ETH")
292522        (Market, "Lending Pool for Wrapped Ether and USD Coin")
120866        (MarketIdOnly, "ETH")
121494        (MarketIdOnly, "Lending Pool for Wrapped Ether and USD Coin")
```

Edgeの31バイト（0番の欄）と32バイト（1番の欄）：

```
$ cast storage <Edge> 0
0x6162636465666768696a6b6c6d6e6f707172737475767778797a30313233343e
$ cast storage <Edge> 1
0x0000000000000000000000000000000000000000000000000000000000000041
```

### 試すときの注意

- storageの`string`と`bytes`の欄の形：31バイト以下は内容を欄の左から書き、いちばん最後のバイトに長さ × 2（最後のビットは0）を置く。32バイト以上はその欄に長さ × 2 + 1（最後のビットは1）だけを置き、内容はkeccak256（欄の番号）番の欄から32バイトずつ順に置かれる。
- `string`には、`length`、インデックス、`push`、`==`、`+`がない。長さとバイトは`bytes(s)`に変えて見て、同じかどうかは`keccak256(bytes(a)) == keccak256(bytes(b))`で比べる。連結は`string.concat`である。
- `"あい"`はUTF-8で6バイトである。Solidityが数える長さは、文字数ではなくバイト数である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、数字とエラーの文言が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のBytes and string as Arrays、The functions bytes.concat and string.concat、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| `bytes.concat`の導入 | 0.8.4（2021-04-21） | 2026-10-19 |
| `string.concat` | 0.8.12（2022-02-16）から、stringを受け取ってstring memoryを返す。それ以前の版ではbytes.concatのコピーとして誤って入っていたとChangelogに書かれている。ドキュメントの例のpragmaは`^0.8.12` | 2026-10-19 |
| cast calldataの長さ | 4バイト：f(bytes) 100 / f(bytes1[]) 196、32バイト：100 / 1,092 | 2026-10-19 |
| メモリで作るgasUsed（n = 4、32、100、1,000） | bytes 22,561 / 26,397 / 35,731 / 159,213、bytes1[] 22,606 / 27,004 / 37,699 / 180,966 | 2026-10-19 |
| TagsのaddのgasUsed | 最初のpush 44,401 / 2回目・3回目27,301 | 2026-10-19 |
| MarketのデプロイのgasUsed | ETH 247,514 / 43バイトの名前292,522、MarketIdOnly ETH 120,866 / 43バイトの名前121,494 | 2026-10-19 |
| テストのガス | test_BytesMembers 9,793 / test_Concat 10,211 / test_Equal 6,683 / test_KoreanLength 9,666 | 2026-10-19 |
| 第59講のLabelのsetLabelのgasUsed | 17バイト44,835 / 41バイト89,637 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| calldata配列のスライス（`data[4:]`、string calldataを含む） | [第69講](../../part4/lecture69/) |
| bytesとstringのあいだ、bytesNとbytesのあいだの明示的な変換のルール全体 | [第73講](../../part4/lecture73/) |
| ABIエンコードの関数（abi.encode、abi.encodePacked）とbytesの引数 | [第78講](../../part5/lecture78/) |
| ハッシュ関数の性質（違う内容が同じハッシュを出す可能性） | [第79講](../../part5/lecture79/) |
| 文字列処理のライブラリと、文字列を扱う関数の集まり | [第106講](../../part6/lecture106/) |
| 長いstring・bytesの欄の配置のルール（長さ × 2 + 1、keccak256の欄の番号） | [第135講](../../part8/lecture135/) |
| ABIエンコードのルール（開始位置・長さの欄、32バイトへの埋め合わせ） | [第141講](../../part8/lecture141/) |
| チェーンの外で名前・文章を見せる側のUTF-8の処理 | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
