# 第73講 暗黙的・明示的な変換の規則

第4部 言語の詳細 ① ファイルと型・第16章 変換と演算子

[← 第72講](../../part4/lecture72/) | [第4部 目次](../) | [第74講 →](../../part4/lecture74/)

## この講義の問い

型の違う値を移すとき、コンパイラは何を見てそのまま通したり止めたりするのか。手で変えろと書くと、その値はどうなるのか。

## 実習資料

### 準備

第71講・第72講のFoundryプロジェクト（`demo/`、forge-stdを含む、solc 0.8.30）から始める。ビルドされるコードは`demo/src`に、ビルドエラーを見るコードは別のプロジェクト`bad/src`にファイルを一つずつ置き、`forge build --offline src/<名前>.sol`でビルドする。デプロイと呼び出しはローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を使って行い、資産の場所の`0x000000000000000000000000000000000000aaaa`はテスト用のアドレスである。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/demo/src/Types.sol](code/demo/src/Types.sol)、[code/demo/src/Market.sol](code/demo/src/Market.sol) | 第72講の通しのプロジェクトのMarketそのまま。縮める変換は`uint64(block.timestamp)`の一行 |
| [code/demo/src/Packed.sol](code/demo/src/Packed.sol) | 金額の欄をuint128に縮めたテスト用の版MarketPacked。`uint128(amount)`で切り詰められたまま保存される |
| [code/demo/src/PackedSafe.sol](code/demo/src/PackedSafe.sol) | 縮める前に`type(uint128).max`で範囲を確かめる版 |
| [code/demo/src/Conv.sol](code/demo/src/Conv.sol) | 縮める、符号だけを変える、サイズと符号を変える順番、bytes4・アドレス・enum・bytes32・ユーザー定義の値型の変換 |
| [code/demo/src/Narrow.sol](code/demo/src/Narrow.sol) | `uint8(x)`の一行だけが入ったコントラクト（アセンブリの確認用） |
| [code/bad/foundry.toml](code/bad/foundry.toml) | demoと同じ設定 |
| [code/bad/src/](code/bad/src/) | 表記なしの代入の組、表記なしのMarket・Packed、リテラル・演算・2回変える変換の例 |

`code/bad/src/`の代入の組（ファイルごとに`function f(A a) external pure returns (B b) { b = a; }`）：

| 入れる値 → 受け取る欄 | ファイル | ビルド |
|---|---|---|
| uint8 → uint256 / int8 → int256 | U8toU256.sol、I8toI256.sol | できる |
| uint256 → uint8 / bytes4 → bytes1 | U256toU8.sol、B4toB1.sol | できない（7407） |
| uint8 → int16 / int8 → uint256 | U8toI16.sol、I8toU256.sol | できない（7407） |
| bytes1 → bytes4 / address payable → address | B1toB4.sol、PayToAddr.sol | できる |
| uint160 → address / bytes4 ↔ uint32 | U160toAddr.sol、B4toU32.sol、U32toB4.sol | できない（7407） |
| bool ↔ uint8 | BoolToU8.sol、U8toBool.sol | できない（7407） |

そのほかの`code/bad/src/`のファイル：

| ファイル | 行 | エラー |
|---|---|---|
| Market.sol（+ Types.sol） | Marketで`uint64(block.timestamp)`を`block.timestamp`に | Error (7407) |
| PackedNoCast.sol | Packedで`uint128(amount)`を`amount`に | Error (7366) |
| VarToU8.sol | `uint256 x = 5; uint8 y = x;` | Error (9574) |
| MixType.sol | `uint8 c = a + b;`（bはuint16） | Error (9574) |
| MixSign.sol | `return a + b;`（uint8 + int8） | Error (2271) |
| Lit300.sol | `uint8 y = 300;` | Error (9574) |
| LitCast.sol | `return uint8(300);` | Error (9640) |
| TwoAtOnce.sol | `uint256(x)`（xはint8） | Error (9640) |
| B4fromU64.sol | `bytes4(x)`（xはuint64） | Error (9640) |
| AddrFromU256.sol | `address(x)`（xはuint256） | Error (9640) |
| Amount18Call.sol | `Amount18(x)` | Error (9640) |
| BoolFromU8.sol、U8fromBool.sol | `bool(x)`、`uint8(x)` | ビルドできない |

### 実行結果

`bad/`の代表的なエラー（位置の行は一部省略）：

```
$ forge build --offline src/Market.sol
Error (7407): Type uint256 is not implicitly convertible to expected type uint64.
  --> src/Market.sol:40:24:
   |
40 |         p.lastUpdate = block.timestamp;
   |                        ^^^^^^^^^^^^^^^
$ forge build --offline src/PackedNoCast.sol
Error (7366): Operator += not compatible with types uint128 and uint256.
  --> src/PackedNoCast.sol:16:9:
   |
16 |         p.deposited += amount;
   |         ^^^^^^^^^^^^^^^^^^^^^
$ forge build --offline src/VarToU8.sol
Error (9574): Type uint256 is not implicitly convertible to expected type uint8.
$ forge build --offline src/MixType.sol
Error (9574): Type uint16 is not implicitly convertible to expected type uint8.
$ forge build --offline src/MixSign.sol
Error (2271): Built-in binary operator + cannot be applied to types uint8 and int8.
$ forge build --offline src/Lit300.sol
Error (9574): Type int_const 300 is not implicitly convertible to expected type uint8. Literal is too large to fit in uint8.
$ forge build --offline src/LitCast.sol
Error (9640): Explicit type conversion not allowed from "int_const 300" to "uint8".
$ forge build --offline src/TwoAtOnce.sol
Error (9640): Explicit type conversion not allowed from "int8" to "uint256".
$ forge build --offline src/B4fromU64.sol
Error (9640): Explicit type conversion not allowed from "uint64" to "bytes4".
$ forge build --offline src/AddrFromU256.sol
Error (9640): Explicit type conversion not allowed from "uint256" to "address".
$ forge build --offline src/Amount18Call.sol
Error (9640): Explicit type conversion not allowed from "uint256" to "Amount18".
```

代入の組のエラーの文言は、`Type uint8 is not implicitly convertible to expected type int16.`の形である。`demo/`の`forge build --offline`は`Compiler run successful!`である。

MarketPackedに2の128乗 + 5（`0x100000000000000000000000000000005`）を預けた結果。トランザクションは成功し（gasUsed 66834、ログ0個）、欄には5だけが残る：

```
$ cast send <MarketPacked> "deposit(address,uint256)" 0x000000000000000000000000000000000000aaaa 340282366920938463463374607431768211461 --private-key <アカウント0のキー> --json
(抜粋) "status": "0x1", "logs": []
$ cast index address 0x000000000000000000000000000000000000aaaa 0
0x839613f731613c3a2f728362760f939c8004b5d9066154aab51d6dadf74733f3
$ cast index address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 0x839613f731613c3a2f728362760f939c8004b5d9066154aab51d6dadf74733f3
0x59f61559c53be69edbefde122c519fc18499a035f84520c988c41a2761ef120f
$ cast storage <MarketPacked> 0x59f61559c53be69edbefde122c519fc18499a035f84520c988c41a2761ef120f
0x0000000000000000000000000000000000000000000000000000000000000005
```

`positions(...)`で読んでも`5, 0, 1792393278, false`である。変換の箇所をアセンブリで見ると、0xffとのANDで下位8ビットだけを残し、Panicのセレクターはない：

```
$ forge inspect --offline Narrow assembly > narrow.asm
(抜粋)
    tag_17:
      0x00
      0xff
      dup3
      and
$ grep -c "0x4e487b71" narrow.asm
0
```

MarketPackedSafeは、同じ値を入れると巻き戻り、500は成功する（gasUsed 66866）：

```
$ cast send <MarketPackedSafe> "deposit(address,uint256)" 0x000000000000000000000000000000000000aaaa 340282366920938463463374607431768211461 ...
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: amount too large, ...
```

Convを`cast call`で呼んだ結果：

```
$ cast call <Conv> "narrow(uint256)(uint8)" 300
44
$ cast to-base 300 bin
0b100101100
$ cast to-base 44 bin
0b101100
$ cast call <Conv> "signOnly8(int8)(uint8)" -- -1
255
$ cast call <Conv> "signOnly256(int256)(uint256)" -- -1
115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]
$ cast call <Conv> "toStatus(uint8)(uint8)" 2
2
$ cast call <Conv> "toStatus(uint8)(uint8)" 7
Error: execution reverted: panic: failed to convert value into enum type (0x21)
$ cast call <Conv> "toBytes32(bytes)(bytes32)" 0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728
0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20
$ cast call <Conv> "toBytes32(bytes)(bytes32)" 0x616263
0x6162630000000000000000000000000000000000000000000000000000000000
```

そのほか、`sizeFirst(-1)`は255、`signFirst(-1)`はuint256の最大値、`toBytes4(0x12345678)`は`0x12345678`、`mixed(200, 1000)`は1200、`literal()`は5、`hashToAddr(keccak256("hello"))`は`0x3472287B56D9517B9C948127319A09a7A36dEaC8`、`wrap18(1000)`は1000、`asToken(0x...aaaa)`は`0x...aaaa`である。

MarketとPackedで縮める変換を探した結果：

```
$ grep -nE "uint(8|16|32|64|128)\(" src/Market.sol
40:        p.lastUpdate = uint64(block.timestamp);
$ grep -nE "uint(8|16|32|64|128)\(" src/Packed.sol
16:        p.deposited += uint128(amount);
17:        p.lastUpdate = uint64(block.timestamp);
```

### 試すときの注意

- 縮める明示的な変換は、あふれても巻き戻らず、上位のビットを捨てる。値が範囲内かを先に確かめる行（`require(amount <= type(uint128).max, ...)`）を置く。OpenZeppelinのSafeCast（`toUint128`など）は、同じ確認をまとめたライブラリである。
- 符号・サイズ・系統のうち二つ以上を一度に変える変換は止められる。`uint256(uint8(x))`と`uint256(int256(x))`のように2段階で書くと、順番によって結果が違う（-1で255とuint256の最大値）。
- 負の引数は、`cast call <アドレス> "signOnly8(int8)(uint8)" --rpc-url <RPC_URL> -- -1`のように、オプションを先に置いて`--`のあとに書く。オプションを後ろに置くと、`--`のあとのオプションが引数として読まれる。
- 新しいanvilでMarketPacked、MarketPackedSafe、Convの順にデプロイすると、アドレスは`0x5FbDB2315678afecb367f032d93F642f64180aa3`、`0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、`0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、数字とエラーの文言が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | TypesのConversions between Elementary Types、Conversions between Literals and Elementary Types、v0.8.36（この講義の説明はsolc 0.8.30の実際の出力が基準） | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 符号・サイズ・系統のうち一つだけを変えるルール | 0.8.0（2020-12-16）"Explicit conversions between two types are disallowed if it changes more than one of sign, width or kind at the same time." 同じ版に"Explicit conversions from literals to integer type is as strict as implicit conversions." | 2026-10-19 |
| uintN → intMの暗黙的な変換の禁止 | 0.8.1（2021-01-27）"Disallow implicit conversion from ``uintN`` to ``intM`` when ``M > N``, and by extension, explicit conversion between the same types is also disallowed." | 2026-10-19 |
| bytes → bytes1〜bytes32への変換 | 0.8.5（2021-06-10）"Allowing conversion from ``bytes`` and ``bytes`` slices to ``bytes1``/.../``bytes32``." | 2026-10-19 |
| OpenZeppelinのSafeCast | Contracts v5.4.0の`utils/math/SafeCast.sol`（ファイルの頭に"last updated v5.1.0"）、`toUint128`は超えると`SafeCastOverflowedUintDowncast(128, value)`で巻き戻す | 2026-10-19 |
| gasUsed | MarketPackedのdeposit（2の128乗 + 5）66,834 / MarketPackedSafeのdeposit(500) 66,866 | 2026-10-19 |
| anvilのブロックの時刻 | 1792393278 | 2026-10-19 |
| テストのアドレス | MarketPacked `0x5FbDB2315678afecb367f032d93F642f64180aa3`、MarketPackedSafe `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Conv `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、デプロイ・呼び出しのアカウントはanvilの既定のアカウント0 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（公開されたテスト用の鍵）、資産の場所`0x000000000000000000000000000000000000aaaa`（テスト用のアドレス） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 複合代入（`+=`）が欄にすること、`delete`、三項演算子の結果の型 | [第74講](../../part4/lecture74/) |
| エラーに名前をつけて投げる文法（ユーザー定義のエラー） | [第90講](../../part5/lecture90/) |
| 切り詰めを狙う攻撃の形、監査で縮める行を見る方法 | [第88講](../../part5/lecture88/)、[第89講](../../part5/lecture89/)、[第90講](../../part5/lecture90/)、[第188講](../../part12/lecture188/) |
| ハッシュからアドレスを取り出す形が使われる場所（コントラクトのアドレスの計算） | [第94講](../../part6/lecture94/) |
| 関数のオーバーロードで、引数の型によって関数を選ぶルール | [第100講](../../part6/lecture100/) |
| エンコード・デコードの境界で符号とサイズが変わる場所 | [第141講](../../part8/lecture141/) |
| 欄を縮めてガスを節約する設計（金額の欄をuint128に） | [第143講](../../part9/lecture143/) |
| 単位の違う金額を混ぜる事故と点検 | [第194講](../../part13/lecture194/)、[第195講](../../part13/lecture195/)、[第196講](../../part13/lecture196/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
