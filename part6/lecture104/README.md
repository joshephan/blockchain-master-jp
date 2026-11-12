# 第104講 modifierの誤用と代わりの手

第6部 言語の詳細 ③ コントラクト・第22章 modifier

[← 第103講](../../part6/lecture103/) | [第6部 目次](../) | [第105講 →](../../part6/lecture105/)

## この講義の問い

宣言の行のmodifierの名前だけを信じるとどこで間違え、検査をmodifier・本体・内部関数のどこに置くかは何で決めるのか。

## 実習資料

### 準備

通しプロジェクトのMarketのこの講義のバージョン（`market`）は、第103講のバージョンから`onlyAdmin`・`notFrozen`の検査の中身を内部関数`_checkAdmin`・`_checkNotFrozen`に移してmodifierがその関数を呼ぶようにし、`deposit`一か所にだけついていた`onlyListed`を本体の最初の行の`require`に戻したバージョンである。modifierに`virtual`はつけない。テストとIMarketは第103講のままである（リバートの理由が同じなので、そのまま通る）。`inline`と`quiet`は比較・デモ用のバージョンで、プロジェクトのバージョンではない。`demo`は`forge init`で作った空のプロジェクトから始めた。どれもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | この講義のバージョンのMarket。`_checkAdmin`・`_checkNotFrozen`、`deposit`の本体の最初の行での上場の確認 |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | 第103講のインターフェースのまま |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Status.t.sol](code/market/test/Status.t.sol) | 第103講の状態のテストのまま |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol)、[Getters.t.sol](code/market/test/Getters.t.sol)、[Receive.t.sol](code/market/test/Receive.t.sol)、[WithdrawAll.t.sol](code/market/test/WithdrawAll.t.sol)、[Selectors.t.sol](code/market/test/Selectors.t.sol) | 前の講義で加えたテスト |
| [code/inline/src/Market.sol](code/inline/src/Market.sol) | 比較用のバージョン：modifierの本体に`require`をそのまま置いたバージョン（サイズの比較用、残りのファイルは`market`と同じ） |
| [code/quiet/src/Market.sol](code/quiet/src/Market.sol) | デモ用のバージョン：第103講のバージョンから`notFrozen`をリバートせずに`_;`を飛ばすように変えたバージョン |
| [code/quiet/src/MockToken.sol](code/quiet/src/MockToken.sol) | テスト用のトークン |
| [code/quiet/test/Quiet.t.sol](code/quiet/test/Quiet.t.sol) | 凍結した市場で`withdraw`がリバートせずに何もしないことを見せるテスト |
| [code/demo/src/Mod.sol](code/demo/src/Mod.sol) | virtualのmodifierを子が変えるBase・Child、状態を変えるmodifierの順番（Once）、`_;`を飛ばすmodifier（Count） |
| [code/demo/test/Mod.t.sol](code/demo/test/Mod.t.sol) | `test_child`、`test_once`、`test_maybe` |
| [code/bad/novirtual/src/X.sol](code/bad/novirtual/src/X.sol) | Baseのmodifierから`virtual`を抜いたバージョン（Error 4334） |
| [code/bad/nooverride/src/X.sol](code/bad/nooverride/src/X.sol) | Childのmodifierから`override`を抜いたバージョン（Error 9456） |

`inline`、`quiet`、`demo`、`bad/*`には、それぞれ同じ設定のfoundry.tomlがある。

### 実行結果

`demo`で`forge test --offline --match-test test_child -vvvv`。0xBEEFが呼んだ`setX`は、Baseでは止まり、modifierを`_;`だけ残すようにオーバーライドしたChildでは通る。

```
[PASS] test_child() (gas: 78073)
    ├─ [0] VM::prank(0x000000000000000000000000000000000000bEEF)
    ├─ [24055] Base::setX(1)
    │   └─ ← [Revert] not owner
    ├─ [0] VM::prank(0x000000000000000000000000000000000000bEEF)
    ├─ [43719] Child::setX(1)
    │   └─ ← [Stop]
    ├─ [2403] Child::x() [staticcall]
    │   └─ ← [Return] 1
```

`virtual`と`override`は対で書く必要がある（`bad/novirtual`、`bad/nooverride`）。

```
Error (4334): Trying to override non-virtual modifier. Did you forget to add "virtual"?
 --> src/X.sol:8:5:
  |
8 |     modifier onlyOwner() {
```

```
Error (9456): Overriding modifier is missing "override" specifier.
  --> src/X.sol:19:5:
   |
19 |     modifier onlyOwner() {
```

`test_once -vvvv`。状態を変える`bump`と、その状態を見る`first`は、順番を入れ替えるだけで結果が変わる。

```
    ├─ [43944] Once::bumpThenFirst()
    │   └─ ← [Revert] not first
    ├─ [43638] Once::firstThenBump()
    │   └─ ← [Stop]
    ├─ [2402] Once::calls() [staticcall]
    │   └─ ← [Return] 1
    ├─ [23612] Once::firstThenBump()
    │   └─ ← [Revert] not first
```

`_;`を飛ばす`onlyIf`をつけたCount。ビルドの警告と、ローカルのanvilにデプロイしたあとの`cast call`・`cast send`の結果。`maybe(false)`はリバートせずに0を返し、status 1で終わるが、`count`はそのままである。

```
Warning (6321): Unnamed return variable can remain unassigned. Add an explicit return with value to all non-reverting code paths or name the variable.
  --> src/Mod.sol:49:56:
```

```
0
7
gasUsed              21808
logs                 []
status               1 (success)
0
```

`quiet`で`forge test --offline --match-contract QuietTest -vvvv`。凍結した市場の`withdraw(…, 40)`は成功で終わるが、トークンは来ず、預け入れの合計もそのままである。

```
[PASS] test_frozenWithdrawLooksFine() (gas: 93538)
    ├─ [43828] Market::setStatus(2)
    │   └─ ← [Stop]
    ├─ [24466] Market::withdraw(MockToken: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 40)
    │   └─ ← [Stop]
    ├─ [2801] MockToken::balanceOf(QuietTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   └─ ← [Return] 900
    ├─ [2950] Market::totalDeposits(MockToken: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]) [staticcall]
    │   └─ ← [Return] 100
```

同じバージョンに第103講のStatusTestを走らせると、リバートすべき二つのテストが失敗する。

```
[FAIL: next call did not revert as expected] test_addAssetOrder() (gas: 107593)
[PASS] test_depositNotListed() (gas: 38047)
[PASS] test_depositPaused() (gas: 140312)
[FAIL: next call did not revert as expected] test_frozenBlocksWithdrawAll() (gas: 80064)
[PASS] test_setStatusOnlyAdmin() (gas: 81036)
Suite result: FAILED. 3 passed; 2 failed; 0 skipped; finished in 1.67ms (2.58ms CPU time)
```

Marketの三つのバージョンの`forge build --offline --sizes`（Marketの行、ランタイム / デプロイのコード）。

| バージョン | ランタイム | デプロイのコード |
|---|---|---|
| 第103講のバージョン | 8,002 | 8,705 |
| `onlyListed`だけを本体に移したバージョン（`inline`） | 8,000 | 8,703 |
| この講義のバージョン（modifierが`_check`関数を呼ぶ） | 7,779 | 8,475 |

`market`で`forge test --offline`。

```
Ran 6 test suites in 40.33ms (11.41ms CPU time): 16 tests passed, 0 failed, 0 skipped (16 total tests)
```

### 試すときの注意

- 宣言の行だけを読んでも、modifierの本体が何をするかは見えない。継承するコントラクトがvirtualのmodifierをオーバーライドすると、検査が丸ごと消えることがある。
- 状態を変えるmodifierは、宣言の行の順番によって結果が変わる。
- `_;`を条件の中に置くと、検査が失敗してもリバートせずに成功で終わる。呼ぶ側はstatus 1だけを見て、処理が済んだと思う。
- 二か所以上につく検査は、内部関数に一度書いてmodifierがその関数を呼ぶようにすると、つけた関数ごとにコピーされるコードが減る（8,000 → 7,779バイト）。一つの関数にだけかかる検査は、本体の最初の行の`require`にしておく。
- 公式ドキュメントv0.8.36は、modifierのオーバーライドをdeprecatedと表示している。solc 0.8.30のビルドでは警告は出ない。

## 時効性のあるデータ

基準日時点の値。ツール・ライブラリのバージョンが変わると、サイズとガス、ドキュメントの文が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節 Function Modifiers（オーバーライドは`virtual`のときだけ、複数のmodifierは書いた順に評価、本体を実行しないことがあり、そのとき戻り値は既定値） | 2026-10-19 |
| modifierのオーバーライドの表示 | 0.6.0から、オーバーライドのときに`override`が必須 | 2026-10-19 |
| modifierのオーバーライドの今後 | 公式ドキュメント v0.8.36 Inheritanceの節 Modifier Overridingの見出し"(deprecated)"、"`virtual` modifiers are deprecated and scheduled for removal." solc 0.8.30のビルドは警告なし | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| OpenZeppelin Contracts | 5.4.0、`Ownable.sol`のonlyOwner・_checkOwner | 2026-10-19 |
| ランタイム・デプロイのコードのサイズ | Base 749 / Child 487（デプロイのトレース）、Marketの第103講のバージョン8,002 / 8,705、onlyListedだけを移したバージョン8,000 / 8,703、第104講のバージョン7,779 / 8,475 | 2026-10-19 |
| テストのgas | test_child 78,073（Base.setX 24,055、Child.setX 43,719）、test_once 125,158（bumpThenFirst 43,944、firstThenBump 43,638・23,612）、QuietTest 93,538（withdraw 24,466） | 2026-10-19 |
| gas report（StatusTestの最大値、第103講のバージョン / requireのバージョン / 第104講のバージョン） | addAsset 91,975 / 91,975 / 92,023、setStatus 43,828 / 43,828 / 43,852、withdraw 54,935 / 54,935 / 54,959、deposit 128,296 / 128,291 / 128,291 | 2026-10-19 |
| Countのmaybe | cast send maybe(false)のgasUsed 21,808、maybe(true) 44,138 | 2026-10-19 |
| ローカルのanvilのアドレス | Count `0x5FbDB2315678afecb367f032d93F642f64180aa3` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 継承の規則（`is`、関数のオーバーライド、多重継承、`super`） | [第110講](../../part6/lecture110/)、[第111講](../../part6/lecture111/)、[第112講](../../part6/lecture112/)、[第113講](../../part6/lecture113/) |
| カスタムエラーでリバートの理由を渡す | [第108講](../../part6/lecture108/)、[第109講](../../part6/lecture109/) |
| サイズとガスを減らす優先順位、ベンチマーク | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 関数・modifierの命名規則とコードの配置 | [第148講](../../part9/lecture148/)、[第149講](../../part9/lecture149/) |
| アクセス制限のパターンと権限の設計 | [第151講](../../part9/lecture151/)、[第176講](../../part11/lecture176/) |
| 市場の状態遷移の設計 | [第152講](../../part9/lecture152/) |
| ライブラリ（OpenZeppelin）のアクセス制御のコード | [第151講](../../part9/lecture151/) |
| リバートせずに通り過ぎる経路を見つける方法 | [第167講](../../part11/lecture167/) |
| 精読の手順と深刻度の判定 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
