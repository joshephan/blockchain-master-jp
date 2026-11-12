# 第185講 0.5・0.6・0.7の変更履歴

第11部 推奨事項：敵対的環境とバージョン履歴・第49章 既知のバグとバージョン移行

[← 第184講](../../part11/lecture184/) | [第11部 目次](../) | [第186講 →](../../part11/lecture186/)

## この講義の問い

何年も前のSolidityのコードを今のコンパイラに入れると、何が起きるのか。コンパイルが通れば意味も同じなのか。すでに古いバージョンでデプロイされたコントラクトはどうなるのか。

## 実習資料

### 準備

solc 0.8.30の実行ファイル一つとPythonで古い形のファイルをコンパイルしてエラーを集め、Foundryプロジェクト二つをビルドする。`old185/`の十九のファイルは、古いバージョンで通っていた形を一つずつ入れたファイルで、今のコンパイラで止まることを見せるためにわざと置いたものである（ファイルの冒頭は`pragma solidity >=0.4.24;`）。`bugs`はバージョンによって答えが変わった式を入れた小さなFoundryプロジェクトで、forge-stdが必要である。`market`は通しプロジェクトMarketの第46章の終わりのバージョンで、この講義では直さない。古いコンパイラは新たに回さなかった。anvilと外部への接続は使わない。

`tools/errs185.py`、`tools/errs185_full.py`は、solcの実行ファイル名を`solc-0.8.30`と書いてある。自分の環境のsolc 0.8.30のパスに変えて使う。

### コード

| ファイル | 内容 |
|---|---|
| [code/old185/](code/old185/) | 古い形を一ファイルずつ十九：0.5の形八つ（`v05_*`）、0.6の形四つ（`v06_*`）、0.7の形四つ（`v07_*`）、0.8の形三つ（`v08_*`） |
| [code/extra185/v07_usingfor.sol](code/extra185/v07_usingfor.sol) | 親にだけ`using L for uint;`を書き、子で`x.add(1)`を呼ぶ0.7の形 |
| [code/interop/NewContract.sol](code/interop/NewContract.sol) | 050のドキュメントのInteroperabilityの節のインターフェースOldContractとNewContractの例そのまま |
| [code/tools/errs185.py](code/tools/errs185.py) | フォルダの`.sol`ごとにsolcのStandard JSONでコンパイルし、エラーの種類・番号・メッセージ（110文字まで）を出す |
| [code/tools/errs185_full.py](code/tools/errs185_full.py) | 同じツールからメッセージの切り詰めだけを除いたバージョン |
| [code/bugs/foundry.toml](code/bugs/foundry.toml) | solc 0.8.30、optimizerオン、via-IRオン、evm osaka |
| [code/bugs/src/Silent185.sol](code/bugs/src/Silent185.sol) | 符号付きの右シフト、べき乗の結果の型、リテラルのシフトの型の三か所 |
| [code/bugs/test/Silent185.t.sol](code/bugs/test/Silent185.t.sol) | Silent185Testの三つ：-5 >> 1 = -3、uint8の2 ** 8はPanic 0x11、1 << uint8 8 = 256 |
| [code/market/](code/market/) | Market第46章の終わりのバージョン（foundry.toml、src、testそのまま） |

### 実行結果

`python -I -X utf8 tools/errs185.py old185`。0.8.30でエラー十八、警告一つ（`v07_ctorvis`）である。

```
v05_constant           ParserError(2314) Expected '{' but got 'constant'
v05_ctor               SyntaxError(5796) Functions are not allowed to have the same name as the contract. If you intend this to be a constructor, use "
v05_keccak2            TypeError(4323) Wrong argument count for function call: 2 arguments given but expected 1. This function requires a single byte
v05_sha3               TypeError(3557) "sha3" has been deprecated in favour of "keccak256".
v05_throw              SyntaxError(4538) "throw" is deprecated in favour of "revert()", "require()" and "assert()".
v05_var                ParserError(6933) Expected primary expression.
v05_vis                SyntaxError(4937) No visibility specified. Did you intend to add "public"?
v05_years              TypeError(4820) Using "years" as a unit denomination is deprecated.
v06_fallback           ParserError(2915) Expected a state variable declaration. If you intended this as a fallback function or a function to handle pla
v06_length             TypeError(7567) Member "length" is read-only and cannot be used to resize arrays.
v06_override           TypeError(9456) Overriding function is missing "override" specifier.
v06_override           TypeError(4334) Trying to override non-virtual function. Did you forget to add "virtual"?
v06_shadow             DeclarationError(9097) Identifier already declared.
v07_ctorvis            Warning(2462) Visibility for constructor is ignored. If you want the contract to be non-deployable, making it "abstract" is 
v07_finney             ParserError(2314) Expected ';' but got identifier
v07_now                TypeError(7359) "now" has been deprecated. Use "block.timestamp" instead.
v07_value              TypeError(1621) Using ".value(...)" is deprecated. Use "{value: ...}" instead.
v08_byte               ParserError(9182) Function, variable, struct or modifier declaration expected.
v08_sendertransfer     TypeError(9862) "send" and "transfer" are only available for objects of type "address payable", not "address".
v08_uintm1             TypeError(9640) Explicit type conversion not allowed from "int_const -1" to "uint256".
```

`python -I -X utf8 tools/errs185_full.py extra185`。0.7から、using forは書いたコントラクトにだけかかる。

```
v07_usingfor           TypeError(9582) Member "add" not found or not visible after argument-dependent lookup in uint256.
```

`v07_ctorvis.sol`を`solc --bin`でビルドすると、警告2462のあとにバイトコードが出る。`interop/NewContract.sol`を`solc --abi`でビルドすると、エラーなしで終了コード0である（OldContractのABIの行は省略）。

```
$ solc --abi NewContract.sol
======= NewContract.sol:NewContract =======
Contract JSON ABI
[{"inputs":[{"internalType":"contract OldContract","name":"a","type":"address"}],"name":"doSomething","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]
```

`bugs`で`forge test --offline --match-contract Silent185Test -vv`：

```
Ran 3 tests for test/Silent185.t.sol:Silent185Test
[PASS] test_powTypeIsBase() (gas: 17413)
Logs:
  uint8 2 ** 7 128

[PASS] test_shiftLiteralIsUint256() (gas: 11969)
Logs:
  1 << uint8 8 256

[PASS] test_shiftSignedRoundsDown() (gas: 14382)
Logs:
  -5 >> 1
  -3

Suite result: ok. 3 passed; 0 failed; 0 skipped
```

`forge test --offline --match-test test_powTypeIsBase -vvvv`（console.logの行は省略）。戻り値の型はuint256だが、計算はuint8なので2 ** 8で差し戻す。

```
  [17413] Silent185Test::test_powTypeIsBase()
    ├─ [399] Silent185::powBase(2, 7) [staticcall]
    │   └─ ← [Return] 128
    ├─ [0] VM::expectRevert(panic: arithmetic underflow or overflow (0x11))
    │   └─ ← [Return]
    ├─ [395] Silent185::powBase(2, 8) [staticcall]
    │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
    └─ ← [Return]
```

同じ式のバージョンごとの答え。右の欄はドキュメントのルールどおりに計算した値で、古いコンパイラで回した値ではない。

| 式 | 0.8.30で回した値 | 古いバージョンのルール（ドキュメント） |
|---|---|---|
| `-5 >> 1` | -3 | 0.5より前：0の方向に切り捨て、-2 |
| uint8 `2 ** 8` | Panic 0x11で差し戻し | 0.6より前：底と指数の両方が入る型（uint256）、256 |
| uint8 `2 ** 7` | 128 | 0.6より前も128 |
| `1 << n`（uint8 n = 8） | 256 | 0.7より前：nの型（uint8）で計算、0 |

`forge build --offline --force`のコンパイラの警告は、べき乗の一行だけである。シフトの二行には警告がない（同じビルドのforge lintの警告の行は省略）。

```
Compiler run successful with warnings:
Warning (3149): The result type of the exponentiation operation is equal to the type of the first operand (uint8) ignoring the (larger) type of the second operand (uint256) which might be unexpected. Silence this warning by either converting the first or the second operand to the type of the other
  --> src/Silent185.sol:13:16:
   |
13 |         return b ** e;
   |                ^^^^^^
```

`market`でpragmaとシフト・べき乗の場所を探し、ビルドした結果：

```
$ grep -rn "^pragma" src
src/IMarket.sol:2:pragma solidity 0.8.30;
src/Market.sol:2:pragma solidity 0.8.30;
src/MarketMath.sol:2:pragma solidity 0.8.30;
src/MarketTypes.sol:2:pragma solidity 0.8.30;
src/MockToken.sol:2:pragma solidity 0.8.30;
$ grep -nE ">>|<<|\*\*" src/*.sol | wc -l
0
$ forge build --offline --force
Compiling 65 files with Solc 0.8.30
Solc 0.8.30 finished in 17.93s
Compiler run successful!
```

バージョンごとのまとめ：

| バージョン | コンパイルが止まる変更 | 黙って変わった変更 |
|---|---|---|
| 0.5 | 名前が同じコンストラクタ、throw、var、sha3、可視性なし、years、constant関数、keccak256(a, b) | `-5 >> 1`の切り捨ての方向、外部呼び出しのガス、viewのSTATICCALL |
| 0.6 | 名前のないfallback、override・virtualなし、lengthへの代入、状態変数の隠蔽 | べき乗の結果の型 |
| 0.7 | now、`.value(...)()`、finney、継承したusing for（コンストラクタのpublicは警告） | リテラルのシフトの型 |

### 試すときの注意

- 古いコードは二つに分かれる。コンパイルが止まるか、コンパイルは通るのに答えが変わるかである。後者はビルドの警告もほとんどない（Silent185で警告はべき乗の3149一つ）。
- パーサの段階のエラーは、直す形を言わない（constant関数2314、var 6933、finney 2314）。こういう行はBreaking Changesのドキュメントで探す。パースのあとのチェックのエラー（SyntaxError・TypeError）は、たいてい直す形をメッセージに書く。
- `>=0.4.24`のような開いたpragmaは0.8.30も受け入れて、文法チェックまで進む。`^0.4.20`は0.5.0の手前で閉じるので、最初の行で拒否される（エラー5333）。
- 0.5の予約語のうち、overrideは0.6で、uncheckedは0.8でキーワードになった。
- すでにデプロイされた古いバージョンのコントラクトは直さず、今のバージョンのインターフェースで呼ぶ。ドキュメントは、もともと`constant`だった関数を`view`と書かない。0.5より前のconstantはコンパイラが守らせないのでストレージを書き換えられ、viewと書くとSTATICCALLで呼んで差し戻されることがある。
- 古いコードを受け取ったら、pragmaのバージョンとバイトコード末尾のsolcのバージョンを見て、そのバージョンから今までのBreaking Changesのドキュメントを開き、黙って変わった場所（シフト、べき乗、リテラルのシフト、外部呼び出し）を自分で探す。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。コンパイラのバージョンが変わると、エラー番号・メッセージが変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30+commit.73712a01.Windows.msvc。`bugs`・`market`ともにoptimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| Foundry（forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| Solidityのドキュメント・Changelog | リポジトリv0.8.36の写し、コミット8a079791（2026-07-09） | 2026-10-21 |
| バージョンの公開日 | 0.4.24 2018-05-16、0.4.25 2018-09-12、0.5.0 2018-11-13、0.6.0 2019-12-17、0.7.0 2020-07-28、0.7.6 2020-12-16、0.8.0 2020-12-16、0.8.30 2025-05-07 | 2026-10-21 |
| エラー番号 | 十九のファイルとusing forの一ファイルのエラー・警告の番号はsolc 0.8.30基準 | 2026-10-21 |
| テストのガス（bugs） | powTypeIsBase 17,413 / shiftLiteralIsUint256 11,969 / shiftSignedRoundsDown 14,382 | 2026-10-21 |
| Marketのビルド | 65 files、Solc 0.8.30 finished in 17.93s、警告なし（時間はマシンごとに違う） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 0.8.0の変更（オーバーフローチェック付きの算術、Panic、ABI coder v2の既定化、べき乗の結合） | [第186講](../../part11/lecture186/) |
| 0.8.xの中の変更とバージョンの引き上げ | [第186講](../../part11/lecture186/) |
| デプロイされた古いバージョンのコントラクトを読んで呼ぶ | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| 監査でのpragmaとバージョンの確認 | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/) |
| 0.4より前のバージョンの変更 | 付録（時効性のシート） |

出典と参考資料は[reference.md](reference.md)にまとめた。
