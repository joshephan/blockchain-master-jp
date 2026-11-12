# 第132講 ソースマッピング

第8部 コンパイラと内部構造・第31章 出力の分析

[← 第131講](../../part8/lecture131/) | [第8部 目次](../) | [第133講 →](../../part8/lecture133/)

## この講義の問い

リバートした命令のバイトの位置（pc）から、ソースの何行目かをどうやって探し、その答えが正しいためには何が同じでなければならず、いつ間違うのか。

## 実習資料

### 準備

通しプロジェクトMarketの第132講のバージョン（第131講のバージョンとコードが同じで、`src/Market.sol`にバージョンを説明するコメントを1行だけ足したバージョン）から始める。solc 0.8.30、Foundry 1.8.3を使い、テストにはforge-stdが必要である（`lib/forge-std`）。失敗の画面を出す`Fail.t.sol`はプロジェクトに入れず、コピーの`test/`にだけ置く。チェーン側の確認は、`anvil --steps-tracing`で立ち上げたローカルのノードで行う（このオプションがあってはじめて、`debug_traceTransaction`がステップごとの記録を返す）。アカウントはanvilの既定のアカウント0番である。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30、optimizerは切る、evm_version osaka、remappingsを固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | Market 第132講のバージョン。バージョンを説明するコメント1行のために、deposit 0のリバートが142行目、withdraw 0が147行目 |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | インターフェース、エラー・イベントの宣言 |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | ライブラリ。`PositionLib.debit`の38行目が`InsufficientDeposit`のリバートの位置 |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | ユーザー定義の値型と構造体 |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/](code/market/test/) | プロジェクトのテスト14ファイル、テスト55個 |
| [code/fail/test/Fail.t.sol](code/fail/test/Fail.t.sol) | `vm.expectRevert`なしでわざと失敗するテスト二つ（deposit 0、withdraw 150）。`code/market/test/`にコピーして回す |
| [code/demo/Store.sol](code/demo/Store.sol) | ソースマップをはじめて読んでみる14行のコントラクト（`v = 7`、get、set） |
| [code/tools/evm31.py](code/tools/evm31.py) | Pythonの標準ライブラリだけを使う補助ツール。`instructions`（先頭から命令を分ける）、`decompress`（ソースマップの圧縮を解く）、`line_col`（バイトの位置を行・桁に） |

### 実行結果

`Fail.t.sol`を入れて`forge test -vvvvv`（optimizerは切る）。出力の一部である。

```
[FAIL: ZeroAmount()] test_depositZero() (gas: 127779)
Backtrace:
  at Market.deposit (src/Market.sol:142:33)
  at FailTest.test_depositZero
[FAIL: InsufficientDeposit(0, 150)] test_withdrawOver() (gas: 128164)
Backtrace:
  at Market.withdraw (src/MarketMath.sol:38:35)
  at FailTest.test_withdrawOver
```

anvilにMockTokenとMarketをデプロイし、addAsset 75、deposit 100のあとに`cast send --gas-limit 300000`でdeposit(token, 0)を送った結果と、`cast rpc debug_traceTransaction`の最後の3ステップ。

```
blockNumber          5
gasUsed              26869
status               0 (failed)
revertReason         * , data: "0x1f2a2005"

failed True gas 26869 returnValue 0x1f2a2005 structLogs 300
{"pc": 4701, "op": "SUB", "gas": 273137, "gasCost": 3, "depth": 1}
{"pc": 4702, "op": "SWAP1", "gas": 273134, "gasCost": 3, "depth": 1}
{"pc": 4703, "op": "REVERT", "gas": 273131, "gasCost": 0, "depth": 1}
```

`cast sig "ZeroAmount()"`は0x1f2a2005である。手もとに残るのはpc 4703とリバートデータの4バイトだけで、行番号はない。

Storeのソースマップ（`solc --combined-json srcmap-runtime,bin-runtime,generated-sources-runtime Store.sol`）の先頭部分。全体は891文字、項目230個で、コードの部分の命令は231個である（最後のINVALIDには項目がない）。

```
61:183:0:-:0;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;187:55;;;;;;;;;;;;;:::i;:::-;;:::i;:::-;;109:72;;;:::i;…
```

圧縮を解いて、pcから行まで読んだStoreの表。

| pc | 命令の番号 | 項目 | 指す場所 |
|---|---|---|---|
| 160 SSTORE | 105 | `230:5:0:-:0` | Store.sol 12行目`v = x` |
| 87 JUMP | 54 | `187:55:0:i:0` | 11行目のset関数全体、入る |
| 163 JUMP | 108 | `187:55:0:o:0` | 11行目のset関数全体、出る |
| 14 REVERT | 10 | `61:183:0:-:0` | 4行目のコントラクト全体（イーサを一緒に送った呼び出し） |
| 66 REVERT | 40 | `61:183:0:-:0` | 4行目のコントラクト全体（一致するセレクタなし） |
| 180 REVERT | 125 | `187:12:1:-:0` | コンパイラが作った#utility.yulの8行目`revert(0, 0)` |

`solc --asm Store.sol`のソースの注釈も、同じ範囲を開始:終了で書く。

```
        /* "Store.sol":230:235  v = x */
      dup2
      swap1
      sstore
```

Marketの成果物（`out/Market.sol/Market.json`のdeployedBytecode.sourceMap）とbuild-infoの`source_id_to_path`で、pcを手で行まで探した結果（`evm31.py`の三つの関数）。

```
>>> code = runtime[:7300]   # 末尾2バイト0x0033 = 51、末尾の53バイトを除く
>>> ci = instructions(code); len(ci) -> 3933
>>> D = decompress(sourceMap); len(D) -> 3932
pc 4703 -> 命令2233番 (op 0xfd) -> 項目 10734:12:21:-:0
        -> source_id_to_path["21"] = src/Market.sol -> 142行 33桁 -> 'ZeroAmount()'
```

同じ方法で、withdraw(token, 0)はpc 3177 → 命令1653番 → `10960:12:21:-:1` → 147行33桁（m 1はnotFrozen modifierの`_`の中）、withdraw(token, 150)はpc 4872 → 命令2334番 → `2339:41:22:-:0` → `src/MarketMath.sol` 38行35桁である。

同じソースをoptimizerを入れて（runs 200）ビルドし、同じ三つのトランザクションを送った比較。

| 送ったもの | optimizerを切る | optimizerを入れる |
|---|---|---|
| deposit(token, 0) | pc 4703 → 142行目`ZeroAmount()` | pc 2879 → 142行目`ZeroAmount()` |
| withdraw(token, 0) | pc 3177 → 147行目`ZeroAmount()` | pc 2120 → 147行目`ZeroAmount()` |
| withdraw(token, 150) | pc 4872 → MarketMath.sol 38行目`InsufficientDeposit` | pc 1328 → Market.sol 60行目`NotActive(status)` |

入れたビルドのwithdraw 150のリバートデータは0x25c3f46e（`InsufficientDeposit`、68バイト）なのに、ソースマップは60行目を指す。`forge test --optimize --optimizer-runs 200 -vvvvv`も同じである。

```
[FAIL: ZeroAmount()] test_depositZero() (gas: 123849)
  at Market.deposit (src/Market.sol:142:33)
[FAIL: InsufficientDeposit(0, 150)] test_withdrawOver() (gas: 124109)
  at Market.withdraw (src/Market.sol:60:51)
```

Market 第132講のバージョンのビルドとテスト（`forge build --sizes`、`forge test`）。

```
| Market      | 7,353            | 7,931             | 17,223             | 41,221              |
Ran 16 test suites …: 55 tests passed, 0 failed, 0 skipped (55 total tests)
```

### 試すときの注意

- ソースマップの項目一つは命令一つである。pc（バイトの位置）をそのまま使わず、コードを先頭から命令に分けて何番目の命令かを数える（PUSHのうしろのデータのバイトがあるため）。
- ランタイムの末尾のメタデータには、ソースマップの項目がない。末尾2バイト（長さ）で末尾を先に切り落とす。
- ソースマップのs・lはバイトの位置である。`src/Market.sol`は日本語のコメントのために10,666文字、15,552バイトなので、10734を文字の位置として数えるとファイルの長さを超えてしまい、142行目にたどり着かない。
- ソース番号fは、そのビルド1回だけの番号である。forgeのビルド（39ファイルの入力）で`src/Market.sol`は21、srcの四つのファイルだけを入れたStandard JSONでは1である。番号はbuild-infoの`source_id_to_path`かsourcesの欄で探す。
- ソースマップは、メタデータのoutputの欄（abi、devdoc、userdoc）にもチェーンにもない。コメント1行だけが違う第131講のバージョンのソースマップを第132講のバージョンのソースに当てると、見当違いの行が出る。ビルドの成果物と、バイトまで同じソースを一緒に保管する。
- チェーンのコードは、immutableの六つの区間（PUSH32のうしろの32バイト）だけが成果物と違い、命令の数は同じなので、anvilで得たpcをビルドの成果物のソースマップにそのまま当てられる。
- 失敗するトランザクションは、`cast send`に`--gas-limit`を与えてはじめてブロックに入る（与えないとガスの見積もりで止まる）。
- optimizerを入れたビルドで、リバートデータのエラーとソースマップの行が合わなければ、optimizerを切ったビルドでもう一度回してみる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやソースのコメントが変わると数字が変わる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30+commit.73712a01（直接呼ぶとevm_versionの既定値はprague、Storeはこの値） | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3、forgeのビルドのevm_versionはosaka。anvilは`--steps-tracing`をつけてはじめて`debug_traceTransaction`のstructLogsが出る | 2026-10-20 |
| forgeのBacktraceの表記 | `at コントラクト.関数 (ファイル:行:桁)` | 2026-10-20 |
| forgeのbuild-info | `source_id_to_path` 39個、src/Market.sol 21・MarketMath.sol 22・MarketTypes.sol 23、#utility.yulの39番は一覧にない | 2026-10-20 |
| Storeのソースマップ | 891文字、項目230 / 命令231、ソース番号{0: 122, 1: 108}、移動の種類{-: 209, i: 12, o: 9}、#utility.yul 1,375文字 | 2026-10-20 |
| Marketのソースマップ（第132講のバージョン） | 15,762文字、項目3,932 / 命令3,933、ソース番号21: 2,266・39: 1,468・22: 164・23: 34、移動の種類{-: 3641, i: 193, o: 98}、modifierの深さ{0: 3292, 1: 365, 2: 275} | 2026-10-20 |
| pc → 行（optimizerを切る） | deposit 0 pc 4703 → 142:33 / withdraw 0 pc 3177 → 147:33 / withdraw 150 pc 4872 → MarketMath.sol 38:35 | 2026-10-20 |
| pc → 行（optimizerを入れる、runs 200） | ランタイム3,755バイト、deposit 0 pc 2879 → 142:33 / withdraw 0 pc 2120 → 147:33 / withdraw 150 pc 1328 → Market.sol 60:51 | 2026-10-20 |
| optimizerを切る / 入れる | Store 369 → 183バイト、項目230 → 98、-1の項目2 / Market 7,353 → 3,755バイト、項目3,932 → 2,316、互いに違う範囲1,098 → 603、-1の項目0 → 208 | 2026-10-20 |
| deposit 0のトランザクション（anvil） | gasUsed 26,869、ステップ300 | 2026-10-20 |
| Market 第132講のバージョン | runtime 7,353 / creation 7,931バイト、テスト55個、linkReferences {}、srcに`assembly`なし | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 二つのコード生成の経路でのソースマップ | [第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| オプティマイザがリバートのコードをまとめるステップ | [第139講](../../part8/lecture139/)、[第140講](../../part8/lecture140/) |
| メタデータの欄の一つひとつ | [第142講](../../part8/lecture142/) |
| ファジング・不変条件のツールが失敗の位置を見せるやり方 | [第183講](../../part11/lecture183/) |
| コンパイラのバグとバージョンの変更履歴 | [第184講](../../part11/lecture184/)、[第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 監査でデプロイ物とソースを確定する | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
