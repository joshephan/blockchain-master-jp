# 第88講 checkedな算術の既定の動作

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第87講](../../part5/lecture87/) | [第5部 目次](../) | [第89講 →](../../part5/lecture89/)

## この講義の問い

0.8から算術があふれると何が起き、その検査はどの演算につき、どの演算にはつかないのか。

## 実習資料

### 準備

`demo`と`errors`は、空のFoundryプロジェクトでfoundry.tomlに`solc = "0.8.30"`を固定し、forge-stdを`lib/forge-std`に置く。`old`と`old2`はforge-stdなし（`libs = []`）で、同じソースをsolc 0.7.6と0.8.30で別々にビルドして比べる（`forge build --offline --use 0.7.6 --out out076`、`--use 0.8.30 --out out0830`）。0.7.6のビルドには、そのバージョンのsolcがインストールされている必要がある。コントラクトはローカルのanvilに既定のアカウント0番（anvilの公開されたテスト用の鍵）でデプロイする。`old`はビルド成果物の`bytecode.object`を`cast send --create`でデプロイする。`errors`のファイルは`forge build --offline --force src/<ファイル>`で一つずつビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Ops.sol](code/demo/src/Ops.sol) | 演算ごとに関数を一つずつ置いたデモ用のコントラクト。検査がつく演算とつかない演算、`bump`・`addTo` |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 第87講までの通しプロジェクトのMarket。withdrawの引き算`_debit` |
| [code/demo/src/Token.sol](code/demo/src/Token.sol) | デモ用の最小限のトークン（`approve`、`transfer`、`transferFrom`） |
| [code/demo/src/BorrowDraft.sol](code/demo/src/BorrowDraft.sol) | 担保比率を見ない借り入れの下書き。デモ用で、Marketには入れない |
| [code/demo/test/Market.t.sol](code/demo/test/Market.t.sol) | 預け入れより多く引き出すwithdraw、全部引き出すwithdraw、担保比率を超えるborrowのテスト |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/Lit256.sol](code/errors/src/Lit256.sol) | `uint8 x = 256`、Error 7407 |
| [code/errors/src/LitSum.sol](code/errors/src/LitSum.sol) | `uint8 y = 255 + 1`、Error 7407 |
| [code/errors/src/LitBack.sol](code/errors/src/LitBack.sol) | `uint8 z = 255 + 1 - 1`、ビルドが通る |
| [code/errors/src/LitCast.sol](code/errors/src/LitCast.sol) | `uint8(256)`、Error 9640 |
| [code/errors/src/ShiftLit.sol](code/errors/src/ShiftLit.sol) | `200 << 1`、Error 7407 |
| [code/old/foundry.toml](code/old/foundry.toml) | forge-stdなし |
| [code/old/src/Old.sol](code/old/src/Old.sol) | `pragma solidity >=0.7.6 <0.9.0;`の`add8`、`sub`。二つのコンパイラの比較用 |
| [code/old2/foundry.toml](code/old2/foundry.toml) | forge-stdなし |
| [code/old2/src/Old2.sol](code/old2/src/Old2.sol) | 0.7.6でゼロ除算とint8の端を見る`div`、`divI8` |
| [code/old2/src/LitSum7.sol](code/old2/src/LitSum7.sol) | 0.7.6でもリテラルの`255 + 1`がビルドエラーになるかの確認 |

### 実行結果

Opsを`cast call`で呼んだ結果。算術演算はあふれるとPanic 0x11、0で割ると0x12でリバートする。

```
$ cast call $O "add8(uint8,uint8)(uint8)" 254 1
255
$ cast call $O "add8(uint8,uint8)(uint8)" 255 1
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call $O "div(uint256,uint256)(uint256)" 10 0
Error: execution reverted: panic: division or modulo by zero (0x12)
$ cast call $O "pow8(uint8,uint8)(uint8)" 2 8
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call $O "divI8(int8,int8)(int8)" -- -128 -1
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call $O "negI8(int8)(int8)" -- -128
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
```

`sub8(0,1)`、`mul8(16,16)`、countが255のときの`addTo(1)`もPanic 0x11である。リバートデータは`Panic(uint256)`のセレクタと番号である。

```
data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000011"
$ cast sig "Panic(uint256)"
0x4e487b71
```

検査がつかない演算は、リバートせずに切り捨てられる。

| 呼び出し | 結果 |
|---|---|
| `cast8(256)`、`cast8(300)` | 0, 44 |
| `shl8(200, 1)` | 144 |
| `not8(0)`、`or8(240, 15)` | 255, 255 |
| `twoSteps(-1)`、`twoSteps(-200)`、`twoSteps(300)` | 255, 56, 44 |

リテラルだけの式は、ビルドで引っかかる（`errors`）。

```
Error (7407): Type int_const 256 is not implicitly convertible to expected type uint8. Literal is too large to fit in uint8.
 --> src/LitSum.sol:5:22:
  |
5 |     uint8 public y = 255 + 1;
  |                      ^^^^^^^
Error (9640): Explicit type conversion not allowed from "int_const 256" to "uint8".
 --> src/LitCast.sol:5:22:
Error (7407): Type int_const 400 is not implicitly convertible to expected type uint8. Literal is too large to fit in uint8.
 --> src/ShiftLit.sol:5:22:
```

`LitBack.sol`（`255 + 1 - 1`）は`Compiler run successful!`でビルドされる。

同じソースのOldを0.7.6と0.8.30でビルドし、同じanvilに載せた結果（`$O7`は0.7.6のバージョン、`$O8`は0.8.30のバージョン）。バイトコードの末尾のコンパイラの印は`...64736f6c63430007060033`と`...64736f6c634300081e0033`である。

```
$ cast call $O7 "add8(uint8,uint8)(uint8)" 255 1
0
$ cast call $O7 "sub(uint256,uint256)(uint256)" 5 6
115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]
$ cast call $O8 "add8(uint8,uint8)(uint8)" 255 1
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call $O8 "sub(uint256,uint256)(uint256)" 5 6
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
```

0.7.6でビルドしたOld2。

```
$ cast call $O7b "div(uint256,uint256)(uint256)" 10 0
Error: server returned an error response: error code -32003: EVM error InvalidFEOpcode
$ cast call $O7b "divI8(int8,int8)(int8)" -- -128 -1
-128
```

countが254のOpsで`bump()`を1回送ると成功し（ログはbefore 254）、countが255になる。もう一度送ると、castが事前に実行してみて送らないので、`--gas-limit 100000`をつけて送る。

```
$ cast send $O "bump()" --gas-limit 100000 --private-key $PK0
blockNumber          3
effectiveGasPrice    771153123
gasUsed              24883
logs                 []
status               0 (failed)
```

送る前後で、アカウント0番のナンスは2から3に、残高は9999999245376077980776から9999999226187474821167 weiに減り（gasUsed × effectiveGasPrice）、`cast storage $O 0`は`0x...00ff`のままである。`cast run`で同じトランザクションをもう一度実行すると、トレースにだけemitが見える。

```
Traces:
  [3819] 0x5FbDB2315678afecb367f032d93F642f64180aa3::bump()
    ├─ emit Bumped(before: 255)
    └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
```

Marketのテスト（`forge test --offline -vvvv --match-test test_withdrawTooMuch`）。預け入れ100から150を引き出すと、`_debit`の引き算でPanic 0x11によってリバートする。

```
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_withdrawTooMuch() (gas: 32581)
  [32581] MarketTest::test_withdrawTooMuch()
    ├─ [24785] Market::withdraw(Token: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 150)
    │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
    └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
```

担保比率75で登録した資産に100を預けて1,000,000を借りても、範囲の検査には引っかからない（`-vv --match-test "test_withdrawAll|test_borrowPastRatio"`）。

```
[PASS] test_borrowPastRatio() (gas: 91722)
Logs:
  deposited 100
  borrowed  1000000
[PASS] test_withdrawAll() (gas: 55307)
Logs:
  totalDeposits 0
```

### 試すときの注意

- あふれの検査は算術演算（`+ - * **`、単項の`-`、`++ --`、複合代入、`/ %`）にだけつく。明示的な変換とシフトは切り捨てられ、ビット演算はあふれようがない。
- リテラルどうしの式は、範囲のない数として最後まで計算してから、最後の値だけを確かめる。`255 + 1 - 1`はビルドされ、リテラルの`uint8(256)`、`200 << 1`は止められる。
- 負の引数は`cast call --rpc-url <RPC_URL> <アドレス> "<シグネチャ>" -- <引数>`の順番で渡す。`--`の後ろに`--rpc-url`を置くと引数として読まれ、既定のポート8545に行ってしまう。
- 0.7.6のビルドでは、出力の最後に`Warning: unable to lint. Solar only supports Solidity versions >=0.8.0`の1行が追加で出る。
- `test_withdrawTooMuch`はトレースを見るためにわざと`vm.expectRevert`なしにしたテストなので、失敗で終わる。
- リバートしたトランザクションもブロックに入り、手数料とナンスは残る。消えるのは状態の変更とイベントのログだけである。
- BorrowDraftはデモ用である。あふれの検査は、担保比率のような業務の規則を守ってはくれない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）。二つのコンパイラの比較にだけ0.7.6 | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| あふれの検査の導入 | Solidity 0.8.0、2020年12月。算術は既定で検査し、`unchecked { ... }`で切る | 2026-10-19 |
| SafeMath | OpenZeppelin ContractsのSafeMath。5.0.0（2023-10-05）で削除、0.8.0のあふれの検査で代替 | 2026-10-19 |
| Panicの番号 | 0x11 算術のあふれ、0x12 ゼロ除算・剰余、セレクタ`0x4e487b71` | 2026-10-19 |
| 検査コードのガス | `increment()` Counter 43,539・26,439 / CounterUnchecked 43,338・26,238、差は201 | 2026-10-19 |
| リバートしたbump | gasUsed 24,883、effectiveGasPrice 771,153,123、残高の減少 19,188,603,159,609 wei。成功したbumpのgasUsed 27,953 | 2026-10-19 |
| テストのガス | test_withdrawTooMuch 32,581（withdraw 24,785）、test_withdrawAll 55,307、test_borrowPastRatio 91,722 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| uncheckedブロックで検査を切る方法と、使ってよい場所 | [第89講](../../part5/lecture89/) |
| Panicのコードの全体の表、require・revert・assertとリバートデータ | [第90講](../../part5/lecture90/) |
| 預け入れより多く引き出す要求を、理由を書いた検査で止めること | [第90講](../../part5/lecture90/) |
| 失敗を受け取って処理するtry/catch | [第91講](../../part5/lecture91/) |
| カスタムエラーの宣言とエンコード | [第108講](../../part6/lecture108/) |
| 検査のコストを減らす最適化とその判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 0.5・0.6・0.7の変更履歴と、0.8の検算つき算術の歴史 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 監査でpragmaとSafeMathの抜けた行を探す方法 | [第188講](../../part12/lecture188/) |
| 担保比率と清算の規則 | [第197講](../../part13/lecture197/)、[第198講](../../part13/lecture198/)、[第199講](../../part13/lecture199/) |
| 引き出しパターン | [第150講](../../part9/lecture150/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
