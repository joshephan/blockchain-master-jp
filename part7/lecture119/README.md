# 第119講 Yulの文法の基礎

第7部 アセンブリとYul・第27章 インラインアセンブリ

[← 第118講](../../part6/lecture118/) | [第7部 目次](../) | [第120講 →](../../part7/lecture120/)

## この講義の問い

`assembly { }`の中に書くYulには何があって何がなく、そこに書いた行は機械の命令とどうつながるのか。

## 実習資料

### 準備

Foundryのプロジェクトを二つ使う。`demo`は`Yul119.sol`一つだけを置いたプロジェクトで、`market`は通しプロジェクトMarketの第119講のバージョンである。どちらもsolc 0.8.30、optimizerは切った既定値で、テストにはforge-std（`lib/forge-std`）が必要である。関数の呼び出しは、ローカルのanvilに`Yul119`をデプロイしてから`cast call`で行った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Yul119.sol](code/demo/src/Yul119.sol) | リテラル、オーバーフロー・ゼロ除算、`lt`/`slt`の比較、制御文すべて（`all`）、同じ足し算三つ（Solidity・`unchecked`・アセンブリ） |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第119講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第119講のバージョン。第118講のバージョンとコードが同じで、バージョンを説明するコメントを1行だけ足した。アセンブリブロック0個 |
| [code/market/test/](code/market/test/) | Marketのテスト49個 |

コンパイルエラーの事例は、関数本体の`assembly { }`の中に下の行を入れて`forge build`で確かめた。

| 事例 | 行 | 結果 |
|---|---|---|
| 演算子 | `let x := 1` / `r := x + 1` | Error (1856) `Literal or identifier expected.` |
| else | `if lt(x, 2) { r := 1 } else { r := 2 }` | Error (6913) |
| 関数の中から外の`let` | `let a := 7` / `function g() -> v { v := a }` | Error (8198) |
| 同じ名前の再宣言 | `let x := 1` / `{ let x := 2 }` | Error (1395) |
| 値を捨てていない行 | `add(1, 2)` | Error (3083) |
| スタック・ジャンプの命令 | `r := dup1(1)` / `jump(0)` / `swap1()` | Error (4619)、dup1は8678も |
| Solidityの関数の呼び出し | internalの`g()`を`r := g()` | Error (4619)、8678 |
| 長い文字列 | 33文字の文字列 | Error (3069) `String literal too long (33 > 32)` |
| 外側のbreak・leave | `break` / `leave` | Error (2592) / (8149) |
| 同じcase二つ | `case 1`を2回 | Error (6792) |
| defaultだけのswitch | `default`だけ | 通る、Warning (9592) |
| 宣言のない代入 | `y := 1` | Error (4634)、8198 |
| 型の表記 | `let x:u256 := 1` / `let x:bool := true` | Error (5473) `Types are not supported in untyped Yul.` |
| ブロックの位置 | コントラクトの中で関数の外 / ファイルのいちばん外 | Error (9182) / (7858) |
| 値を使わない変数 | `let x := mload(0x40)` | 通る（Warning 5667） |
| 文法すべて | `all()`と同じ文法 | 通る |

### 実行結果

`cast call`で呼んだ`Yul119`の関数（出力の値を関数名の横にまとめた。maxは`cast max-uint`）。

```
literals()          255
                    0x6162630000000000000000000000000000000000000000000000000000000000
                    1
stringAsNumber()    44048180597813453602326562734351324025098966208897425494240603688123167145984 [4.404e76]
compare()           0
                    1
wrapAdd()           0
wrapSub()           115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]
all()               27
divZero(7, 0)       0
addUnchecked(max, 1) 0
addAsm(max, 1)      0
```

Solidityで書いたほうはリバートする。`addSol(max, 1)`。

```
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
```

`divZeroSol(7, 0)`と`divZeroUnchecked(7, 0)`はどちらも次のとおり。

```
Error: execution reverted: panic: division or modulo by zero (0x12)
```

`forge inspect src/Yul119.sol:Yul119 ir`（658行）での同じ足し算の二つの関数。Solidityの`a + b`はチェックの関数を通り、ブロックの`add`はそのまま入る。

```
            function checked_add_t_uint256(x, y) -> sum {
...
                let expr_100 := checked_add_t_uint256(expr_98, expr_99)
...
            function fun_addAsm_129(var_a_120, var_b_122) -> var_r_125 {
...
                    var_r_125 := add(var_a_120, var_b_122)
```

Market 第119講のバージョンで`grep -n assembly src/*.sol`は1行も出ず、`forge build --sizes`と`forge test`は次のとおりである。

```
| Market     | 7,353            | 7,931             | 17,223             | 41,221              |

Ran 13 test suites in 9.27ms (11.07ms CPU time): 49 tests passed, 0 failed, 0 skipped (49 total tests)
```

### 試すときの注意

- `stringAsNumber()`が返した数を`cast to-hex`で変えると、`0x616263`のうしろに0が詰まった32バイトが出る。文字列リテラルは右側に0を詰める。
- 同じビットの`not(0)`を`lt`で1と比べると0、`slt`で比べると1である。符号をどう見るかは命令が決める。
- `unchecked`の中でも0で割るとPanic 0x12である。ブロックの中の`div`だけが0を返す。
- Yulの関数の中からは外の`let`変数が見えない（8198）。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| Yul119のサイズ（runtime / initcode） | 1,536 / 1,564 | 2026-10-19 |
| Yul119のIR | `forge inspect --offline src/Yul119.sol:Yul119 ir` 658行 | 2026-10-19 |
| Market 第119講のバージョン | runtime 7,353 / creation 7,931（第118講のバージョンと同じ）、linkReferences `{}`、テスト49個が通る、`grep -n assembly src/*.sol` 0行 | 2026-10-19 |
| デプロイのアドレス | anvilのYul119 `0x5FbDB2315678afecb367f032d93F642f64180aa3` / アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（公開されたテスト用の鍵） | 2026-10-19 |
| `leave`が入ったバージョン | 0.6.0（2019-12-17） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 外の変数の名前をブロックで使う規則（`.slot`・`.offset`・`.length`） | [第120講](../../part7/lecture120/) |
| メモリの先頭の欄とフリーメモリポインタ、`memory-safe` | [第121講](../../part7/lecture121/) |
| `call`・`create`をブロックで呼ぶ形 | [第122講](../../part7/lecture122/) |
| アセンブリでガスを減らす場合と測り方 | [第123講](../../part7/lecture123/) |
| Yulでコントラクト全体を書くオブジェクトの構造 | [第124講](../../part7/lecture124/)、[第125講](../../part7/lecture125/) |
| 組み込み関数の全一覧 | [第126講](../../part7/lecture126/) |
| 文法規格の読み方 | [第127講](../../part7/lecture127/) |
| IRと最適化のステップ | [第124講](../../part7/lecture124/)、[第133講](../../part8/lecture133/) |
| 監査でブロックを読む手順 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
