# 第113講 superと呼び出しの順番

第6部 言語の詳細 ③ コントラクト・第25章 継承

[← 第112講](../../part6/lecture112/) | [第6部 目次](../) | [第114講 →](../../part6/lecture114/)

## この講義の問い

`super`は正確に誰を呼び、`super`をどこに書くか・書き落とすかが、複数の親のコードが動く順番をどう変えるのか。

## 実習資料

### 準備

第112講の終わりのMarketのプロジェクトから始め、預け入れの検査を`_checkDeposit`の連鎖に変える。MarketBaseに空の本体の`virtual`を置き、AssetRegistryとLedgerが`super._checkDeposit`のあとに自分の検査を加え、Marketが`override(AssetRegistry, Ledger)`でsuperを呼ぶ。depositはLedgerに移す。`super`のデモは、別に作ったデモ用のプロジェクト（`demo`）の`Super.sol`と、そのログを出力するテストで行う。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Super.sol](code/demo/src/Super.sol) | 自分の名前をつけて`super.who()`を呼ぶBase・A・Bと、C（`is A, B`）、D（`is B, A`）、OnlyB、親の名前を直接呼ぶE、`super`を後ろに書いたA2とF、`super`を呼ばないB3とG、`super.f()`を呼ぶOverHeavySuper |
| [code/demo/src/Body.sol](code/demo/src/Body.sol) | 第110講のLight・Heavy・OverLight・OverHeavy |
| [code/demo/test/Super.t.sol](code/demo/test/Super.t.sol) | 六つのコントラクトの`who()`を`console.log`で出力するSuperTest |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/errors/super_unimpl/src/X.sol](code/errors/super_unimpl/src/X.sol) | 本体のない親の関数を`super`で呼ぶバージョン、Error 9582 |
| [code/errors/two_ovBA/src/X.sol](code/errors/two_ovBA/src/X.sol) | 二つの親の同じ関数を`override(B, A)`で書き直したバージョン、ビルドは通る |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第113講のバージョン。`_checkDeposit`の四つの本体、Ledgerに移したdeposit、`contract Market is AssetRegistry, Ledger` |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol)、[code/market/src/MockToken.sol](code/market/src/MockToken.sol) | インターフェースとテスト用のトークン |
| [code/market/test/Inherit.t.sol](code/market/test/Inherit.t.sol) | `test_depositCheckOrder`を追加。第109講のバージョンと同じエラーが同じ順番で出るか |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト |

### 実行結果

SuperTestのログと線形化の順番（`forge test -vv`、`forge build --ast`の`linearizedBaseContracts`を名前に置き換えて出力）。ログの順番が線形化の順番と同じである。

```
$ forge test --offline --match-contract SuperTest -vv
[PASS] test_who() (gas: 56348)
Logs:
  C B A Base
  D A B Base
  B Base

$ forge build --offline --force --ast
C ['C', 'B', 'A', 'Base']
D ['D', 'A', 'B', 'Base']
OnlyB ['OnlyB', 'B', 'Base']
```

Bのソースはそのままなのに、Bの中の`super`は、CではAへ、OnlyBではBaseへ行く。

| デプロイしたコントラクト | 線形化の順番 | Bの中の`super` |
|---|---|---|
| C | C、B、A、Base | A |
| OnlyB | OnlyB、B、Base | Base |

親の名前を直接呼ぶE、`super`を後ろに書いたA2を継承したF、`super`を呼ばないB3を継承したGのログと線形化の順番。

```
E [A Base] [B A Base]          E ['E', 'B', 'A', 'Base']
F B Base A2                    F ['F', 'B', 'A2', 'Base']
G B3                           G ['G', 'B3', 'A', 'Base']
```

EではAのコードが二回動き、`A.who()`の中の`super`はEの順番どおりBaseへ行く。Gはビルドの警告がなく、AとBaseの本体は動かない。

`super`で覆われた親の本体を呼ぶと、その本体がデプロイされるものにまた入ってくる（`forge build --sizes`）。

| コントラクト | 書き直した本体 | ランタイムのサイズ |
|---|---|---|
| OverHeavy | `return 2;` | 175 B |
| OverHeavySuper | `return super.f() + 1;` | 663 B |

次の番に本体がなければ、呼ぶ相手がいない（`errors/super_unimpl`）。

```
Error (9582): Member "f" not found or not visible after argument-dependent lookup in type(contract super C).
 --> src/X.sol:4:75:
```

Marketの第113講のバージョンで`is`の行にMarketBaseを残すと、Marketのoverrideにまで MarketBaseを書けというエラーが出る。

```
contract Market is MarketBase, AssetRegistry, Ledger {

$ forge build --offline
Error (4327): Function needs to specify overridden contract "MarketBase".
   --> src/Market.sol:214:73:
```

`contract Market is AssetRegistry, Ledger`の線形化の順番はMarket、Ledger、AssetRegistry、MarketBaseで第112講のバージョンと同じで、スロットもそのままである。預け入れの検査は、whenActiveのあと本体の最初の行の`_checkDeposit`で、Market → Ledger → AssetRegistry → MarketBase（空の本体）へ下りていき、戻りながらAssetRegistryの上場の確認（NotListed）、Ledgerの金額の確認（ZeroAmount）の順に動く。

```
$ forge test --offline --match-test test_depositCheckOrder -vv
[PASS] test_depositCheckOrder() (gas: 235666)
```

一か所だけを変えたMarketの三つの変形（`forge build --sizes`、`forge test`、44個のうちの失敗）。

| 変えた場所 | ビルド | 失敗したテスト |
|---|---|---|
| Ledgerの`_checkDeposit`の`super`の行を消す | 通る、Warning 5667が一つ、runtime 7,059 B | 3個：`test_notListed`、`test_depositNotListed`、`test_depositCheckOrder` |
| Marketの`_checkDeposit`の本体を空にする | 通る、警告なし、runtime 6,988 B | 4個：`test_notListed`、`test_zeroAmount`、`test_depositNotListed`、`test_depositCheckOrder` |
| Ledgerの`super`を金額の確認のあとに | 通る、警告なし、runtime 7,229 B | 1個：`test_depositCheckOrder`（`ZeroAmount() != NotListed(...)`） |

superの行を消したバージョンの警告は使わない引数についてのものだけで、`super`を呼ばなかったという話はない。

```
$ forge build --offline --force
Compiler run successful with warnings:
Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
   --> src/Market.sol:131:28:
    |
131 |     function _checkDeposit(address asset, uint256 amount) internal view virtual override {
    |                            ^^^^^^^^^^^^^
```

| 書き落としたもの | ビルド |
|---|---|
| modifierの`_;` | Error (2883) `Modifier body does not contain '_'.` |
| 書き直した関数の`super`の呼び出し | 通る |

Marketを継承して`_checkDeposit`を空の本体で書き直そうとするバージョンは、Marketの`_checkDeposit`に`virtual`がないので止まる。

```
Error (4334): Trying to override non-virtual function. Did you forget to add "virtual"?
   --> src/Market.sol:214:5:
```

```
$ forge build --offline --force
Compiler run successful!
$ forge test --offline
Ran 12 test suites: 44 tests passed, 0 failed, 0 skipped (44 total tests)
```

| | 第112講のバージョン | 第113講のバージョン |
|---|---|---|
| runtime / creation | 7,173 / 7,740 B | 7,229 / 7,796 B |
| デプロイのgasUsed | 1,606,559 | 1,618,582 |
| deposit 100 | 130,240 | 130,376 |
| 失敗したdeposit 0 | 26,759 | 26,869 |
| addAsset 75、withdraw 30 | 93,769、59,692 | 93,769、59,692 |

継承の構造の表のvirtualの欄とsuperの順番。

| コントラクト | 継承するコントラクト | virtualの欄 |
|---|---|---|
| MarketBase | なし | `_checkDeposit`（空の本体、`virtual`） |
| AssetRegistry | MarketBase | `_checkDeposit`（`virtual override`） |
| Ledger | MarketBase | `_checkDeposit`（`virtual override`） |
| Market | AssetRegistry、Ledger | `_checkDeposit`（`override(AssetRegistry, Ledger)`、`virtual`なし） |

### 試すときの注意

- `super`が呼ぶのは自分の親ではなく、最終的な線形化の順番で自分のすぐ次のコントラクトである。同じ親のコードでも、継承する側によって次の番が変わる。
- 親の名前を直接呼ぶと（`A.who()`）その本体一つへ行き、順番を飛ばす。同じコードが二回動くことがある。
- `super`を書き落としてもビルドは通る。抜けた番の検査は、失敗する場合を書いたテストでしか捕まらない。
- 一つの関数にmodifierと`super`の連鎖が一緒にあると、modifierが先に動き、本体で連鎖が動く。
- このバージョンは、modifierではなく`virtual`関数`_checkDeposit`を書き直す連鎖である。公式ドキュメントは、modifierのオーバーライドをdeprecatedと書いている。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンや実行環境が変わると、数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| modifierのオーバーライド | 公式ドキュメント v0.8.36 Modifier Overridingの節がdeprecatedと表示。solc 0.8.30のビルドは警告なし | 2026-10-19 |
| 線形化の順番のフィールド | `forge build --ast`の成果物`out/<ファイル>/<コントラクト>.json`の`ast`の中の`linearizedBaseContracts` | 2026-10-19 |
| Super.solのサイズ（runtimeのバイト） | Light 175、Heavy 637、OverLight 175、OverHeavy 175、Heavy2 637、OverHeavySuper 663、C 755、OnlyB 513 | 2026-10-19 |
| Marketの二つのバージョンのサイズ | 第112講のバージョンのruntime 7,173 / creation 7,740、第113講のバージョン7,229 / 7,796。第113講のバージョンの親の単体のサイズはAssetRegistry 1,085、Ledger 3,915、MarketBase 268（別にはデプロイしない） | 2026-10-19 |
| Marketの二つのバージョンのgasUsed（第112講のバージョン / 第113講のバージョン） | デプロイ1,606,559 / 1,618,582、addAsset 75 93,769 / 93,769、deposit 100 130,240 / 130,376、withdraw 30 59,692 / 59,692、setStatus 1 45,761 / 45,761、失敗deposit 0 26,759 / 26,869 | 2026-10-19 |
| ガスの実測の条件 | バージョンごとに新しいanvil、ブロックの間隔1秒（`cast rpc anvil_setBlockTimestampInterval 1`）、同じアドレス（MockToken `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Market `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`）、アカウント0番、Marketのコンストラクタの引数はアカウント0番・5e16・80、順番はデプロイ → addAsset 75 → deposit 100 → withdraw 30 → setStatus 1 → setStatus 0 → deposit 0（`--gas-limit 100000`、status 0） | 2026-10-19 |
| Marketの三つの変形 | Ledgerのsuperの行を消す：Warning 5667が一つ、runtime 7,059、41個が通り3個が失敗 / Marketの本体を空にする：警告なし、runtime 6,988、40個が通り4個が失敗 / Ledgerのsuperを金額の確認のあとに：警告なし、runtime 7,229、43個が通り1個が失敗 | 2026-10-19 |
| テスト | 第113講のバージョンは44個が通る（12のまとまり）、`test_depositCheckOrder`のgas 235,666 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 親のコンストラクタの順番 | [第114講](../../part6/lecture114/) |
| 本体のない親の関数と連鎖の終わり | [第115講](../../part6/lecture115/) |
| 標準の実装が使うフックの連鎖（`_update`など） | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| アクセス制御の設計での検査の位置 | [第151講](../../part9/lecture151/) |
| 検査が抜けた経路を狙う場合 | [第167講](../../part11/lecture167/)、[第176講](../../part11/lecture176/) |
| 失敗の経路を性質で検査する | [第183講](../../part11/lecture183/) |
| 線形化の順番で精読する | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
