# 第133講 IRコード生成とレガシーの違い

第8部 コンパイラと内部構造・第32章 IRベースのコード生成

[← 第132講](../../part8/lecture132/) | [第8部 目次](../) | [第134講 →](../../part8/lecture134/)

## この講義の問い

solcの二つのコード生成の経路（既定の経路とvia-IR）は、それぞれ何を通ってバイトコードを作り、同じソースから何が同じで何が変わるのか。

## 実習資料

### 準備

通しプロジェクトMarketの第133講のバージョン（第132講のバージョンとコードが同じで、バージョンを説明するコメントを1行だけ足したバージョン）と、ドキュメントIR-based Codegen Changesの例を名前だけ変えて集めたデモのプロジェクト（`demo`）の二つを使う。solc 0.8.30、Foundry 1.8.3で、どちらのプロジェクトもforge-stdが必要である（`lib/forge-std`）。Store・Deepはsolcを直接呼んでビルドする。ノードは立ち上げない。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | optimizerは切る、`via_ir = false`（デプロイ物は既定の経路） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | Market 第133講のバージョン。バージョンを説明するコメント1行のために、下の行番号が第132講のバージョンより1ずつ大きい |
| [code/market/src/](code/market/src/) | IMarket・MarketMath・MarketTypes・MockToken（第132講のバージョンと同じ） |
| [code/market/test/](code/market/test/) | プロジェクトのテスト14ファイル、テスト55個 |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモのプロジェクトの設定（optimizerは切る、evm_version osaka） |
| [code/demo/src/Diff133.sol](code/demo/src/Diff133.sol) | ドキュメントの例七つ: A・B（継承の初期値）、Del（structのdelete）、Twice・Active（`_;`が2回）、Order（計算の順番、addmod・mulmod）、Clean（上位ビット）、Big（フリーメモリポインタの上限） |
| [code/demo/test/Diff133.t.sol](code/demo/test/Diff133.t.sol) | 例の値を`console.log`で出す`test_show` |
| [code/solc/Store.sol](code/solc/Store.sol) | `v = 7`、get、setだけの14行のコントラクト |
| [code/solc/Deep.sol](code/solc/Deep.sol) | ローカル変数22個のために、既定の経路でStack too deepが出る関数 |
| [code/tools/count_effects.py](code/tools/count_effects.py) | 1行に状態を変えうる式がいくつあるかを数えるPythonのスクリプト |

### 実行結果

`solc --ir`で取り出したYul（見出しの`IR:`を除いた337行）をアセンブルしたサイズと、二つの経路の`--bin`のサイズ。

```
$ solc --strict-assembly --bin store_ir_only.yul
805バイト
$ solc --via-ir --bin Store.sol
805バイト
$ solc --bin Store.sol
401バイト
```

アセンブルした805バイトは`--via-ir --bin`とバイトまで同じで、既定の経路の401バイトとは違う。デプロイのコードの前の部分とランタイムは、既定の経路が32 + 369、via-IRが145 + 660である。

同じ`v = x`の1行を、既定の経路の`--asm`と`--ir`で見た姿。

```
$ solc --asm Store.sol
        /* "Store.sol":230:235  v = x */
      dup2
      swap1
      sstore
```

```
$ solc --ir Store.sol
            function fun_set_22(var_x_14) {
                /// @src 0:234:235  "x"
                let _1 := var_x_14
                let expr_18 := _1
                /// @src 0:230:235  "v = x"
                update_storage_value_offset_0_t_uint256_to_t_uint256(0x00, expr_18)
```

四つの設定のランタイムのサイズ（Marketはfoundry.tomlの`via_ir`・`optimizer`の2行だけを変えて`forge build --sizes`）。

| ランタイム（バイト） | Store | Market |
|---|---|---|
| 既定の経路、optimizerを切る | 369 | 7,353 |
| 既定の経路、optimizerを入れる | 183 | 3,755 |
| via-IR、optimizerを切る | 660 | 7,615 |
| via-IR、optimizerを入れる | 186 | 3,260 |

Deep.solを二つの経路でビルド。

```
$ solc --bin-runtime Deep.sol
Error: Stack too deep. Try compiling with `--via-ir` (cli) or the equivalent `viaIR: true` (standard JSON) while enabling the optimizer. Otherwise, try removing local variables.
  --> Deep.sol:20:23:
   |
20 |         uint256 b13 = x + 14;
   |                       ^
$ solc --via-ir --bin-runtime Deep.sol      # 終了コード0、ランタイム2,465バイト
$ solc --via-ir --ir-optimized Deep.sol
        mstore(64, memoryguard(0x80))       # デプロイのコード
            mstore(64, memoryguard(0x0380)) # ランタイム
```

デモのプロジェクトで`forge test --match-path test/Diff133.t.sol -vv`と、同じコマンドに`--via-ir`をつけた結果（上が既定の経路、下がvia-IR）。

```
-- legacy
  B.y 0
  0x0000000000000000000000000000abcd00000000000000020000000000000001
  0x0000000000000000000000000000abcd00000000000000000000000000000000
  Twice.f(0) 1
  Active.foo() 1
  preincr_u8(1) 3
  g(1, 2) 10
  addmod 0
  mulmod 2
  0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
  0x00000000000000000000000000000000000000000000000000000000000000fe
  Big ok false 1000667
  0x
-- via-IR
  B.y 42
  0x0000000000000000000000000000abcd00000000000000020000000000000001
  0x0000000000000000000000000000000000000000000000000000000000000000
  Twice.f(0) 0
  Active.foo() 0
  preincr_u8(1) 4
  g(1, 2) 10
  addmod 4
  mulmod 0
  0x00000000000000000000000000000000000000000000000000000000000000fe
  0x00000000000000000000000000000000000000000000000000000000000000fe
  Big ok false 23591
  0x4e487b710000000000000000000000000000000000000000000000000000000000000041
```

2行目・3行目はDelの`fill()`のあとと`delete`のあとのスロットの値、最後から4行目・3行目はCleanのr1・r2、最後の2行はBigをガス1,000,000で呼んだ結果（使ったガス、リバートデータ）である。addmod・mulmodの引数は、既定の経路が右から`(5, 4, 3)`、via-IRが左から`(4, 5, 5)`の順に計算される。

Market 第133講のバージョンで、`forge inspect src/Market.sol:Market ir`（3,072行）のmodifierの関数。

```
            function modifier_notFrozen_609(var_asset_604, var_amount_606) {
                fun__checkNotFrozen_352()
                /// @src 1:6546:6547  "_"
                fun_withdraw_651_inner(var_asset_604, var_amount_606)
            }
            …
            function fun_withdraw_651(var_asset_604, var_amount_606) {
                modifier_notFrozen_609(var_asset_604, var_amount_606)
            }
```

`python count_effects.py src/Market.sol`。

```
状態を変える関数: _credit, _debit, addAsset, deposit, setStatus, withdraw, withdrawAll
 42 [1] admin = admin_;
 69 [1] status = s;
 …
170 [1] totalDeposits[asset] = totalDeposits[asset] - Amount.wrap(amount);
191 [1] interestRate = interestRate_;
213 [2] for (uint256 i = 0; i < assets.length; i++) {
215 [1] count++;
2個以上の行: 1
```

213行目の`uint256 i = 0`と`i++`はセミコロンで分かれた別の式なので、二つの経路の計算の順番の違いに引っかからない。Market 第133講のバージョンのビルドとテスト。

```
$ forge build --offline --force --sizes
| Market      | 7,353            | 7,931             | 17,223             | 41,221              |
$ forge test --offline
Ran 16 test suites …: 55 tests passed, 0 failed, 0 skipped (55 total tests)
```

### 試すときの注意

- `solc --ir`は、`--via-ir`なしでもYulを出す。そのYulはvia-IRの経路がアセンブルするコードで、既定の経路のビルドはこのYulを通らない。
- 既定の経路の成果物のgenerated-sourcesには`#utility.yul`（Storeで1,375文字）があり、via-IRにはない。そのため、ソースマップのファイル番号も既定の経路が0・1、via-IRが-1・0と違う。
- optimizerを切ったvia-IRが、四つの設定のうちでいちばん大きい。via-IRは、optimizerと一緒に入れてはじめて小さくなる。
- Marketで`via_ir`の1か所を変えるだけでも、末尾のメタデータハッシュではなくコードから変わる（runtime 7,353 → 7,615バイト、デプロイのコード7,931 → 8,209バイト）。
- Marketのsrcで、ドキュメントが挙げた違いに引っかかる行は見つからなかった: 状態変数の初期値0か所、`delete`・`addmod`・`mulmod`・`assembly` 0か所、modifier三つはどれも`_;`が1回、大きなメモリ配列・関数ポインタなし。`grep -n "delete\|addmod\|mulmod\|assembly\|_;" src/*.sol`と`count_effects.py`で確かめる。
- IRの関数名のうしろの数字（`_609`など）は、そのビルドのASTのidなので、ビルドごとに違うことがある。

## 時効性のあるデータ

基準日時点の値。コンパイラのバージョンや設定が変わると数字が変わる。

| 項目 | 値 | 基準日 |
|---|---|---|
| via-IRの既定値 | solc 0.8.30ではfalse（Standard JSONの`viaIR`の欄の注釈"This is false by default."、オプションなしの`solc --bin`が既定の経路） | 2026-10-20 |
| solc | 0.8.30+commit.73712a01（直接呼ぶときのevm_versionの既定値はprague、Store・Deepはこの値） | 2026-10-20 |
| Foundry（forge） | 1.8.3、forgeのビルドのevm_versionはosaka（foundry.tomlに書く） | 2026-10-20 |
| Storeの二つの経路 | creation 401 / runtime 369（既定の経路）、805 / 660（via-IR）。`--asm` 329行・tag 29 / 521行・tag 78。generated-sourcesの#utility.yul 1,375文字 / なし | 2026-10-20 |
| ランタイムのサイズ四つ（既定で切る / 既定で入れる / via-IRで切る / via-IRで入れる、runs 200） | Store 369 / 183 / 660 / 186、Market 7,353 / 3,755 / 7,615 / 3,260、Marketのinitcode 7,931 / 4,013 / 8,209 / 3,473 | 2026-10-20 |
| ビルドの時間（Marketのプロジェクト全体、`forge build --force`のsolcの時間） | via-IR（optimizerを切る）が既定の経路（optimizerを切る）の3.5倍前後。同じコンピュータで1.17s / 2.88s / 4.14s / 7.35s（既定で切る / 既定で入れる / via-IRで切る / via-IRで入れる）と測ったことがあり、ほかの作業と重なると数倍遅くなる | 2026-10-20 |
| Deep.sol | 既定の経路は終了コード1でStack too deep（Deep.sol:20:23） / via-IR（optimizerを切る）は終了コード0、runtime 2,465、`--ir-optimized`でmemoryguard(0x80)・(0x0380) | 2026-10-20 |
| ドキュメントの例の二つの経路の値 | B.y 0 / 42、Twice.f(0) 1 / 0、Active.foo() 1 / 0、preincr_u8(1) 3 / 4、g(1, 2) 10 / 10、addmod 0 / 4、mulmod 2 / 0、Bigをガス1,000,000で: 1,000,667・リバート0バイト / 23,591・Panic 0x41 | 2026-10-20 |
| MarketのIR | `forge inspect src/Market.sol:Market ir` 3,072行、関数271個、modifierの関数五つ | 2026-10-20 |
| Market 第133講のバージョン | runtime 7,353 / creation 7,931バイト、テスト55個、linkReferences {}、srcに`assembly`なし、count_effectsは13行・二つ以上が1行（213行目） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Marketをvia-IRに変えてみる手順と判断 | [第134講](../../part8/lecture134/) |
| structのメンバーがスロットの中で位置を分け合う規則 | [第135講](../../part8/lecture135/) |
| メモリの配置とフリーメモリポインタ | [第137講](../../part8/lecture137/) |
| via-IRの最適化のステップの名前と順序 | [第139講](../../part8/lecture139/)、[第140講](../../part8/lecture140/) |
| メタデータのsettingsの欄の一つひとつ（viaIR） | [第142講](../../part8/lecture142/) |
| 経路とoptimizerをガスで選ぶ判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| コンストラクタの代わりに初期化関数を使う構造 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 計算の順番に頼る行を探すツール | [第183講](../../part11/lecture183/) |
| バージョンごとに変わるコンパイラの動作 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
