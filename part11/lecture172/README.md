# 第172講 MEV

第11部 推奨事項：敵対的環境とバージョン履歴・第45章 軸2・順序の操作

[← 第171講](../../part11/lecture171/) | [第11部 目次](../) | [第173講 →](../../part11/lecture173/)

## この講義の問い

自分が送った取引は、自分が書いた値のとおりに約定するのか。同じブロックの中で順番を決める側は、自分の取引の前後に何ができるのか。受け取る最小量を先に書いておくと何が変わるのか。Marketの順番はすでに安全なのか。

## 実習資料

### 準備

プロジェクトは二つある。`vulns`は積が一定の交換（x*y=k）を行う講義用のトイプール一つを置いた小さなプロジェクトで（本物のDEXではない）、`market`は通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）のsrcをそのまま置き、確認用テスト`test/Order45.t.sol`を足したものである。どちらもforge-stdが必要である（`lib/forge-std`）。anvilと外部への接続はない。前後に割り込む取引を再現するテストは載せず、受け取る最小量で防ぐ側のテストだけを載せる。

### コード

| ファイル | 内容 |
|---|---|
| [code/vulns/foundry.toml](code/vulns/foundry.toml) | solc 0.8.30、optimizerオン（200）・via-IRオン・evm osaka、fuzz runs 256・seed 0x2a |
| [code/vulns/src/Mev172.sol](code/vulns/src/Mev172.sol) | ToyPool(1000, 1000)。上限のない`swapAForB`、受け取る最小量をかける`swapAForBMin`、売り戻す`swapBForA` |
| [code/vulns/test/Mev172.t.sol](code/vulns/test/Mev172.t.sol) | 受け取る最小量のテスト二つ（割り込まれたあとは差し戻される、割り込みがなければ約定する）。割り込む取引の再現テストは除いた抜粋 |
| [code/market/test/Order45.t.sol](code/market/test/Order45.t.sol) | 同じ取引二つの順番を入れ替えてみるMarketの確認テスト四つ |
| [code/market/src/Market.sol](code/market/src/Market.sol) | setStatus、withdraw、elapsedOf（208〜210行、block.timestampを使用） |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/) | Marketのソースとテストすべて |

### 実行結果

割り込む取引がないとき、A 100で受け取るBは91である。前でA 500を入れると、同じ100で受け取るBが42に減る。受け取る最小量を91の99%の90にかけると、割り込まれたあとは`Slippage(42, 90)`で差し戻される（`forge test --offline --match-test test_minOutBlocksSandwich -vvvv`から選んだ行）：

```
[PASS] test_minOutBlocksSandwich() (gas: 81707)
    ├─ ToyPool::quoteAForB(100) [staticcall]
    │   └─ ← [Return] 91
    ├─ ToyPool::swapAForB(500)
    │   └─ ← [Return] 334
    ├─ ToyPool::quoteAForB(100) [staticcall]
    │   └─ ← [Return] 42
    ├─ ToyPool::swapAForBMin(100, 90)
    │   └─ ← [Revert] Slippage(42, 90)
```

割り込みがなければ、上限の範囲内でそのまま約定する（`--match-test test_minOutPassesWhenFair -vvvv`）：

```
[PASS] test_minOutPassesWhenFair() (gas: 44745)
    ├─ ToyPool::quoteAForB(100) [staticcall]
    │   └─ ← [Return] 91
    ├─ ToyPool::swapAForBMin(100, 90)
    │   └─ ← [Return] 91
```

Marketの順番の確認（`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract Order45Test -vvv`）：

```
[PASS] test_depositWithdrawOneToOne() (gas: 219780)
[PASS] test_elapsedReadsBlockTimestamp() (gas: 151799)
[PASS] test_freezeBeforeWithdrawBlocks() (gas: 208491)
[PASS] test_withdrawBeforeFreezePasses() (gas: 233010)
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

同じブロックで凍結が先に来ると、withdrawは`MarketFrozen`で差し戻される（`--match-test test_freezeBeforeWithdrawBlocks -vvvv`から選んだ行）。withdrawが先に来ると、帳簿が0になってから凍結される：

```
    ├─ Market::setStatus(2)
    │   ├─ emit StatusChanged(from: 0, to: 2)
    ├─ Market::withdraw(MockToken: [0x2e23…470b], 100)
    │   └─ ← [Revert] MarketFrozen()
```

### 試すときの注意

- 抜粋した`Mev172.t.sol`はテスト関数が二つだけなので、同じ環境でガスが81,707 → 81,591、44,745 → 44,687と少し違って出る。
- トイプールは手数料がなく、整数の割り算を使う。数字はこのプールの値である。
- Marketはblock.timestampを利息の経過時間（`elapsedOf`、208〜210行）にだけ使う。
- Marketのテストを回すときに二つの環境変数を渡すと、ガスの記録ファイル（`snapshots/`）と照合も書き換えもしない。
- テストの中のトイのアドレスは、デプロイの順番によって変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30。vulns・marketともにoptimizerオン（runs 200）・via-IRオン・evm osaka。vulnsは`[fuzz] runs=256 seed=0x2a` | 2026-10-21 |
| トイプールの値 | ToyPool(1000, 1000)、手数料なし、整数の割り算。quoteAForB(100) 91、前の取引A 500、minOut 90（91の99%） | 2026-10-21 |
| テストのガス（vulns） | minOutBlocksSandwich 81,707 / minOutPassesWhenFair 44,745 | 2026-10-21 |
| テストのガス（market） | depositWithdrawOneToOne 219,780 / elapsedReadsBlockTimestamp 151,799 / freezeBeforeWithdrawBlocks 208,491 / withdrawBeforeFreezePasses 233,010 | 2026-10-21 |
| トイのアドレス（テストの中） | ToyPool 0x5615dEB7…23b72f（fairの計算用）・0x2e234DAe…58470b（割り込んだ回）、Market 0x5615dEB7…23b72f、MockToken 0x2e234DAe…58470b。デプロイの順番によって変わる | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| その場の価格を揺らして担保を膨らませる攻撃 | [第173講](../../part11/lecture173/) |
| 元手なしで揺らすフラッシュローン | [第174講](../../part11/lecture174/) |
| オンチェーンの乱数 | [第175講](../../part11/lecture175/) |
| 承認の上書きのすきを減らす承認の設計（承認の範囲を狭めるウォレット側） | [第222講](../../part15/lecture222/)、[第223講](../../part15/lecture223/) |
| 実際のメンプールで順番を売り買いする仕組み | [第225講](../../part16/lecture225/)、[第226講](../../part16/lecture226/)、[第227講](../../part16/lecture227/) |
| スリッページの上限を使う交換の連携 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| Marketの順番の二つのバージョンと信頼の前提の監査 | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/) |
| ブロックの時刻を動かして得をするケース | [第175講](../../part11/lecture175/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
