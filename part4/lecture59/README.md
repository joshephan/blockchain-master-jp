# 第59講 リテラル ②：文字列・Unicode・アドレス

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第58講](../../part4/lecture58/) | [第4部 目次](../) | [第60講 →](../../part4/lecture60/)

## この講義の問い

引用符の中に書いた文字は、この機械で何になり、0xのあとの40桁のアドレスリテラルについて、コンパイラは何をチェックするのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める。テストにはforge-stdが必要である（`lib/forge-std`）。エラーを見せるファイルはsrcの外の`bad/`に置き、`forge build bad/<ファイル>.sol`で一つずつビルドする。anvilを立ち上げ、既定のアカウント0番（公開されたテスト用の鍵）でデプロイする。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/Lit.sol](code/src/Lit.sol) | 2種類の引用符と連結、UTF-8のバイト長、string・bytes・bytes32、hexリテラル、32バイトへの切り詰め、`bytes32 name` |
| [code/src/Label.sol](code/src/Label.sol) | `string label`を保存する`setLabel` |
| [code/src/Esc.sol](code/src/Esc.sol) | 接頭辞のない引用符の中のエスケープ（`\n`、`\t`、`\x41`、`\"`、`\uC548`） |
| [code/test/Lit.t.sol](code/test/Lit.t.sol) | 上の関数の結果の出力 |
| `code/bad/*.sol` | 文字列・hex・アドレスリテラルのルールを一つずつ確かめるファイル22個（下の表） |

`bad/`のファイルは、それぞれコントラクト一つに行一つである。

| ファイル | 行 | 結果 |
|---|---|---|
| [Korean.sol](code/bad/Korean.sol) | `string public s = "あいうえ";` | Error (8936): Invalid character in string. If you are trying to use Unicode characters, use a unicode"..." string literal. |
| [Accent.sol](code/bad/Accent.sol) / [Emoji.sol](code/bad/Emoji.sol) / [RawTab.sol](code/bad/RawTab.sol) | "café" / "hi 🙂" / タブ文字をそのまま打った"a b" | 同じError (8936) |
| [Fit32.sol](code/bad/Fit32.sol) | `bytes32 public x = "abcdefghijklmnopqrstuvwxyz012345";` | ビルド成功 |
| [TooLong.sol](code/bad/TooLong.sol) | 上の文字列の最後に6 | Error (7407): … Literal is larger than the type. |
| [Ko10.sol](code/bad/Ko10.sol) / [Ko11.sol](code/bad/Ko11.sol) | `unicode"あいうえおかきくけこ"` / 最後にさ | ビルド成功 / Error (7407)、リテラルがhex"e38182…e38195"と表示される |
| [HexOdd.sol](code/bad/HexOdd.sol) / [HexNot.sol](code/bad/HexNot.sol) | `hex"0ff"` / `hex"zz"` | Error (8936): Expected even number of hex-nibbles. |
| [AddrOk.sol](code/bad/AddrOk.sol) | `address public a = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf;` | ビルド成功 |
| [AddrBad.sol](code/bad/AddrBad.sol) / [AddrLower.sol](code/bad/AddrLower.sol) | 最後がBDF / すべて小文字 | Error (9429): … invalid checksum. Correct checksummed address: "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf". … |
| [Addr39.sol](code/bad/Addr39.sol) / [Addr41.sol](code/bad/Addr41.sol) | 最後のfを抜く / 最後に0をつける | Error (9429): This looks like an address but is not exactly 40 hex digits. It is 39 (41) hex digits. … |
| [Addr38.sol](code/bad/Addr38.sol) / [Addr42.sol](code/bad/Addr42.sol) | `uint256`の変数に38桁 / 42桁 | ビルド成功 |
| [Uint40.sol](code/bad/Uint40.sol) | `uint256 public a = 0x7e5f…bdf;`（40桁の小文字） | Error (9429) invalid checksum、続いてError (7407) addressをuint256に変えられない |
| [Prepend.sol](code/bad/Prepend.sol) | `uint256 public n = 0x007e5f…bdf;` | ビルド成功 |
| [Typo.sol](code/bad/Typo.sol) | 最後のfをcに | Error (9429): … Correct checksummed address: "0x7e5F4552091A69125d5Dfcb7b8c2659029395BdC". |
| [TypoFixed.sol](code/bad/TypoFixed.sol) | 提案されたアドレスそのまま | ビルド成功 |
| [Fake.sol](code/bad/Fake.sol) | `address public asset = 0x7E5FF5f9BB8139561f73Aa22f3840Ec7aC395Bdf;` | ビルド成功 |

forgeの出力には、Error (9429)の行の下に同じ内容の`SyntaxError:`の行がもう一度表示される。

### 実行結果

`forge test -vv`：

```
[PASS] test_cut() (gas: 13738)
Logs:
  0x4c656e64696e6720506f6f6c20666f7220577261707065642045746865722061
  Lending Pool for Wrapped Ether a
[PASS] test_esc() (gas: 16612)
Logs:
  0x6c696e65310a6c696e65320941227122
  0xec9588
  len 3
[PASS] test_hex() (gas: 13603)
Logs:
  0x00ff
  len 2
[PASS] test_lengths() (gas: 16853)
Logs:
  abcd 4
  ko4 12
  emoji 4
[PASS] test_quotes() (gas: 17207)
Logs:
  same true
  joined true
  len abc 3
[PASS] test_three() (gas: 17694)
Logs:
  abc
  0x616263
  0x6162630000000000000000000000000000000000000000000000000000000000
```

Litをanvilにデプロイし、`bytes32 name`の欄を読んだ結果。32バイトを超える名前は切り詰められ、日本語はUTF-8のバイトで入って、文字の途中で切れる。

```
$ cast storage <Lit> 0
0x4c656e64696e6720506f6f6c0000000000000000000000000000000000000000
$ cast storage <Lit> 0 | cast to-ascii
Lending Pool
$ cast send <Lit> "setName(string)" "Lending Pool for Wrapped Ether and USD Coin"
status               1 (success)
$ cast storage <Lit> 0 | cast to-ascii
Lending Pool for Wrapped Ether a
$ cast send <Lit> "setName(string)" "貸出 枠 イーサ ドル 通貨 担保"
status               1 (success)
$ cast storage <Lit> 0
0xe8b2b8e587ba20e69ea020e382a4e383bce382b520e38389e383ab20e9809ae8
```

Labelは名前ごとに新しくデプロイし、`cast send <アドレス> "setLabel(string)" "<名前>"`のgasUsedを読んだ（値は下の時効性のあるデータ）。31バイトまでは欄一つ、超えると欄がさらに要る。

`Fake.sol`のアドレスは、`0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf`の先頭4文字（7e5f）と末尾4文字（5bdf）を残し、真ん中の32桁を16進数で埋めたあと、`cast to-check-sum-address`でチェックサムをかぶせて大文字・小文字まで同じになったものである。チェックサムが合っているので、ビルドは通過する。秘密鍵を知らないアドレスなので、ビルドまでにとどめて送金はしない。

### 試すときの注意

- 接頭辞のない文字列リテラルには、ASCIIしか入らない。日本語、アクセント付きの文字、絵文字、タブ文字をそのまま打つとエラー8936になる。`unicode"..."`を使うか、エスケープ（`\uC548`）で書く。
- 文字列の長さは文字数ではなく、UTF-8のバイト数である。ひらがな・漢字の1文字は3バイト、絵文字は4バイトである。bytes32には日本語10文字（30バイト）まで入る。
- `hex"..."`は偶数桁の16進しか受け付けない。
- 40桁の16進リテラルはアドレスとして読まれ、EIP-55のチェックサムがチェックされる。すべて小文字でもエラーで、uint256の変数に入れても同じである。数値として使うには先頭に`00`をつける。39・41桁は"not exactly 40 hex digits"エラー、38・42桁は数値としてビルドされる。
- チェックサムが捕まえるのは打ち間違いだけで、本物のアドレスかどうかは確かめない。先頭と末尾の4文字が同じ偽のアドレスも、チェックサムが合っていれば通過する。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると、エラーの文言とガスが違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のString Literals and Types、Unicode Literals、Hexadecimal Literals、Address Literals、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| アドレスリテラルの桁数のルール | 0xのあと39・41桁："not exactly 40 hex digits"エラー / 40桁でチェックサムが違う（すべて小文字を含む）："invalid checksum"エラー、uint256の変数に入れても同じ / 38・42桁：数値リテラルとしてビルド / 先頭に00をつけると数値としてビルド | 2026-10-19 |
| エラーの原文 | 日本語など：Error (8936) Invalid character in string… / 33バイト：Error (7407) …Literal is larger than the type. / チェックサム：Error (9429) This looks like an address but has an invalid checksum… / hexの奇数桁：Error (8936) Expected even number of hex-nibbles. | 2026-10-19 |
| setLabelのgasUsed | Lending Pool WETH（17バイト）44,835 / 貸出 枠 イーサ ドル 通貨 担保（41バイト）89,637 | 2026-10-19 |
| そのほかに測ったsetLabelのgasUsed | Lending Pool（12バイト）44,775 / 貸出 枠（10バイト）44,751 / Lending Pool for Wrapped Ether and USD Coin（43バイト）89,661 | 2026-10-19 |
| EIP-55 | 2016年、大文字・小文字のチェックサム | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| string・bytes型そのもの、文字列を扱う関数（string.concat、bytes.concat、比較） | [第68講](../../part4/lecture68/) |
| stringがストレージの欄を分けて使うルール（31バイト以下と超過） | [第68講](../../part4/lecture68/)、[第135講](../../part8/lecture135/) |
| bytesとbytesNNのあいだの変換のルール全体 | [第73講](../../part4/lecture73/)、[第74講](../../part4/lecture74/) |
| ABIエンコードでstring・bytesが載る形 | [第141講](../../part8/lecture141/) |
| チェーンのデータのバイトを文字にほどいて読む | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| アドレスを受け取るときに確かめる実務、アドレス汚染への対応 | [第176講](../../part11/lecture176/)、[第178講](../../part11/lecture178/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
