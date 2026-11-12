# 第89講 uncheckedブロック

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第88講](../../part5/lecture88/) | [第5部 目次](../) | [第90講 →](../../part5/lecture90/)

## この講義の問い

あふれの検査を切るブロックは正確に何を切り、切る行を書く人は何を引き受けるのか。

## 実習資料

### 準備

空のFoundryプロジェクト（`forge init`が作るCounterの例のファイルは消す）で、foundry.tomlに`solc = "0.8.30"`を固定し、forge-stdを`lib/forge-std`に置く。WrapとCounter8はローカルのanvilに既定のアカウント0番（anvilの公開されたテスト用の鍵）で`forge create`し、`cast`で呼ぶ。残りは`forge test`で動かす。`bad/`の二つのファイルはエラーのバージョンなので、`forge build bad/<ファイル> --offline`で別にビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Wrap.sol](code/src/Wrap.sol) | `addChecked`・`addUnchecked`、uncheckedの中の割り算・剰余、中で呼んだinternal関数`callInside` |
| [code/src/Sub.sol](code/src/Sub.sol) | すぐ上の条件でふるいにかけた引き算`gapChecked`・`gapUnchecked`（根拠のコメントつき） |
| [code/src/Loop.sol](code/src/Loop.sol) | ループの増加の3バージョン`sumPlain`（`++i`）、`sumWrapped`（`unchecked { ++i; }`）、`sumPlusEq`（`i += 1`） |
| [code/src/Counter8.sol](code/src/Counter8.sol) | カウンタをuint8に変えた`countPlain`・`countWrapped` |
| [code/src/Market.sol](code/src/Market.sol) | 第88講までの通しプロジェクトのMarket。uncheckedはない |
| [code/src/MockToken.sol](code/src/MockToken.sol) | 第83講のテスト用のトークン（`mint`、`approve`、`transfer`、`transferFrom`） |
| [code/test/Gas.t.sol](code/test/Gas.t.sol) | ループの3バージョン（n=100、1000）と引き算の2バージョンのガスの比較 |
| [code/test/Market.t.sol](code/test/Market.t.sol) | デモ用の`WithdrawDemo`（`_debit`の引き算をuncheckedで囲んだ`withdrawWrapped`、Marketには入れない）とMarketTest（`test_withdrawChecked`、`test_withdrawWrapped`、`test_elapsedBackward`） |
| [code/test/Ops.t.sol](code/test/Ops.t.sol) | uncheckedの中の演算ごとに、一周する値を`console.log`で出力 |
| [code/bad/Nested.sol](code/bad/Nested.sol) | uncheckedブロックの入れ子、Error 1941 |
| [code/bad/Body.sol](code/bad/Body.sol) | 関数の本体の位置にunchecked、Error 5296 |

### 実行結果

Wrapを`cast call`で呼んだ結果。uncheckedの中の足し算は一周し、ゼロ除算と中で呼んだ関数の足し算はそのまま検査される。

```
$ cast call $W "addChecked(uint8,uint8)(uint8)" 255 1
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call $W "addUnchecked(uint8,uint8)(uint8)" 255 1
0
$ cast call $W "addUnchecked(uint8,uint8)(uint8)" 200 100
44
$ cast call $W "divUnchecked(uint256,uint256)(uint256)" 10 0
Error: execution reverted: panic: division or modulo by zero (0x12)
$ cast call $W "modUnchecked(uint256,uint256)(uint256)" 10 0
Error: execution reverted: panic: division or modulo by zero (0x12)
$ cast call $W "callInside(uint8,uint8)(uint8)" 255 1
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
```

`bad/`のビルドエラー。

```
Error (1941): "unchecked" blocks cannot be nested.
Error (5296): "unchecked" blocks can only be used inside regular blocks.
```

`forge test --match-contract GasTest --gas-report --offline`の関数の実行ガス（抜粋）。引き算1行の検査を切ると157ガス減る。0.8.30では`for`の`++i`にもともと検査がつかないので、`sumPlain`と`sumWrapped`はほとんど同じで、`i += 1`のバージョンだけが大きく高い。

```
| gapChecked               |             960 | 960 |    960 | 960 |       1 |
| gapUnchecked             |             803 | 803 |    803 | 803 |       1 |
| Function Name              | Min             | Avg    | Median | Max    | # Calls |
| sumPlain                   |           24994 | 134794 | 134794 | 244594 |       2 |
| sumPlusEq                  |           42938 | 233288 | 233288 | 423638 |       2 |
| sumWrapped                 |           25016 | 134816 | 134816 | 244616 |       2 |
```

uint8のカウンタのCounter8。200までは二つのバージョンとも200を返す。300を渡すと、検査のあるバージョンは255でPanicになって止まり、uncheckedのバージョンは`i`が255から0に戻って終わらないループになり、ガスを使い切る。

```
$ cast call $C8 "countPlain(uint256)(uint256)" 300
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
$ cast call $C8 "countWrapped(uint256)(uint256)" 300
Error: server returned an error response: error code -32003: EVM error OutOfGas
```

同じ呼び出しを`cast send --gas-limit 1000000`で送ると、`countWrapped`はgasUsed 1000000、`countPlain`はgasUsed 117321で、どちらもstatus 0（failed）である。

Marketにはuncheckedがない（`grep -n "unchecked" src/Market.sol`の出力なし）。算術の行は次のとおりである（`grep -nE " [-+*/] " src/Market.sol`）。

```
68:        p.deposited = Amount.wrap(Amount.unwrap(p.deposited) + amount);
70:        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) + amount);
75:        p.deposited = Amount.wrap(Amount.unwrap(p.deposited) - amount);
77:        totalDeposits[asset] = Amount.wrap(Amount.unwrap(totalDeposits[asset]) - amount);
93:        return amount * Rate.unwrap(rate) * elapsed / SECONDS_PER_YEAR / 1e18;
99:        return block.timestamp - p.lastUpdate;
```

`forge test --match-contract MarketTest -vv --offline`。100を預けて101を引き出すと、MarketのwithdrawはPanic 0x11でリバートし（`test_withdrawChecked`）、引き算をuncheckedで囲んだデモ用のバージョンでは預け入れ額がuint256の最大値付近に一周する。時計を預け入れ時点より前に戻すと、`elapsedOf`の引き算がPanic 0x11で引っかかる（`test_elapsedBackward`）。

```
[PASS] test_elapsedBackward() (gas: 100792)
[PASS] test_withdrawChecked() (gas: 38843)
[PASS] test_withdrawWrapped() (gas: 53831)
Logs:
  deposited after withdraw 101: 115792089237316195423570985008687907853269984665640564039457584007913129639935
```

`forge test --match-contract OpsTest -vv --offline`でのuncheckedの中の値：`-(-128)`は-128、`200 * 2`は144、`200 ** 2`は64、`0 - 200`は56、`0--`は255（uint8・int8）。

### 試すときの注意

- uncheckedはブロックの代わりには使えず、入れ子にもできない。文法上ブロックの中に書かれた文にだけ適用され、中で呼んだ関数には引き継がれない。
- ゼロ除算と剰余の検査（Panic 0x12）は、uncheckedでも切れない。
- 0.8.22から、`for (uint256 i; i < n; ++i)`の増加はコンパイラが検査を省く。0.8.30で`unchecked { ++i; }`のバージョンとの差はnに関係なく22ガスで同じで、`i += 1`のバージョンは一周ごとに179ガス多くかかる。
- uncheckedを使う行には、なぜあふれないのかの根拠をコメント1行で書く。カウンタの型を小さくするような、根拠が崩れる変更が入ると、一周するループになる。
- `WithdrawDemo`は、ユーザーの金額を引く行をuncheckedで囲むと何が起きるかを見せるデモ用である。Marketには入れない。
- `cast call`の既定のガスの上限は、anvilのブロックガスリミット30,000,000である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| `for`ループの増加の検査の省略 | solc 0.8.22から。0.8.30で`++i`のバージョンと`unchecked { ++i; }`のバージョンのガスの差はnに関係なく22、`i += 1`のバージョンは一周ごとに179多い | 2026-10-19 |
| gas report（関数の実行ガス） | gapChecked 960、gapUnchecked 803 / sumPlain 24,994（n=100）・244,594（n=1000）、sumWrapped 25,016・244,616、sumPlusEq 42,938・423,638 | 2026-10-19 |
| forge snapshot（テスト全体のガス、参考） | test_gapChecked 6,839、test_gapUnchecked 6,747、test_loopPlain100 30,740、test_loopWrapped100 30,719、test_loopPlain1000 250,362、test_loopWrapped1000 250,363、test_loopPlusEq100 48,661、test_loopPlusEq1000 429,406 | 2026-10-19 |
| uint8のカウンタ n=300 | countWrapped `--gas-limit 1000000`: gasUsed 1,000,000、status 0 / countPlain: gasUsed 117,321、status 0 | 2026-10-19 |
| anvilのブロックガスリミット | 30,000,000（`cast call`の既定のガスの上限） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Panicのコードの表全体、理由を書いてリバートさせる文法 | [第90講](../../part5/lecture90/) |
| カスタムエラーとPanicのデータのエンコード | [第108講](../../part6/lecture108/) |
| アセンブリの算術と、アセンブリによる最適化 | [第123講](../../part7/lecture123/) |
| ストレージへのアクセスのコストと最適化の優先順位 | [第143講](../../part9/lecture143/) |
| 最適化がセキュリティを損なう場合 | [第144講](../../part9/lecture144/) |
| ガスのベンチマークと退行の防止 | [第145講](../../part9/lecture145/) |
| ガスに上限のないループと引き出しパターン | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |
| あふれない根拠を不変条件とファジングで試すこと | [第183講](../../part11/lecture183/) |
| コード精読のときにuncheckedの行を読む順番 | [第188講](../../part12/lecture188/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
