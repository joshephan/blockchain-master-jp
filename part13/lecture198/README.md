# 第198講 清算のインセンティブとボットの競争

第13部 DeFi・第53章 レンディングと清算

[← 第197講](../../part13/lecture197/) | [第13部 目次](../) | [第199講 →](../../part13/lecture199/)

## この講義の問い

担保の値が借金に近づいたポジションは、誰が片づけるのか。その人はなぜ自分のお金を出して他人の借金を返すのか。同じポジションを何人も狙うと、誰が持っていくのか。損が出る清算は誰がするのか。

## 実習資料

### 準備

通しプロジェクトMarketの清算のバージョン（借りるバージョンにliquidateと清算の定数三つを足したバージョン）から始める。デモ用に、受け取った担保をプールに売るときの損益を測るテスト`Econ198.t.sol`と、そのテストが使うおもちゃのプールのコピー（`test/amm/`）を足した。forge-std（1.17.0）とOpenZeppelin Contracts 5.4.0が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。同じブロックでの清算の競争は、ローカルのanvil一つで、anvilの既定のテスト用アカウントだけで回した。清算の定数の値は講義用の設計値で、実在するプロトコルの値ではない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | ビルド設定（OpenZeppelinのremappingを1行追加） |
| [code/src/Market.sol](code/src/Market.sol) | 清算の定数（LIQUIDATION_GAP 5、LIQUIDATION_BONUS 5、CLOSE_FACTOR 50）、liquidate、liquidationLimitを足したMarket |
| [code/src/](code/src/) | IMarket、MarketMath、MarketTypes、テスト用のMockToken |
| [code/test/Liquidate.t.sol](code/test/Liquidate.t.sol) | 清算のテスト七つ（余裕の区間、半分の返済、規則、凍結した市場、利息で超える清算ライン、遅れた清算、借金が担保より大きいとき） |
| [code/test/Econ198.t.sol](code/test/Econ198.t.sol) | 受け取ったCOLを深さの違うプールに売るときに残る値（デモ用、基準のバージョンにはない） |
| [code/test/amm/](code/test/amm/) | Econ198が使うToyAmm・ToyErc20のコピー |
| [code/test/](code/test/) | そのほかの基準のバージョンのテスト |

### 実行結果

aliceはCOL 1000を担保（担保率75）にしてUSD 700を借りた。清算ラインは担保の値 × (担保率 + 5)%である。価格0.9では、借りられる上限675 < 借金700 < 清算ライン720なので、それ以上借りることも清算されることもない（`test_gapBand`：borrow 1 → `InsufficientCollateral(675e18, 701e18)`、liquidate → `NotLiquidatable(720e18, 700e18)`）。

`forge test --offline --match-contract LiquidateTest -vv`（七つ通過）：

```
[PASS] test_closeFactorAndCollateralOnly() (gas: 412210)
[PASS] test_gapBand() (gas: 417792)
[PASS] test_interestCrossesLine() (gas: 3634608)
[PASS] test_liquidateHalf() (gas: 682307)
[PASS] test_liquidateWhenFrozen() (gas: 413178)
[PASS] test_secondLiquidatorReverts() (gas: 469872)
[PASS] test_underwaterSeizeTooLarge() (gas: 277781)
Suite result: ok. 7 passed; 0 failed; 0 skipped
```

価格0.85でcarolが350を返した結果（`test_liquidateHalf`）。受け取るCOL = 350 × 1.05 / 0.85 = 432.35（367.5相当）である。carolはwithdrawAllでCOL 432.35を引き出し、carolのUSDは1000 → 650になる。

| 値 | 清算の前 | 清算のあと |
|---|---|---|
| 清算ライン | 850 × 80% = 680 | 567.65 × 0.85 × 80% = 386 |
| aliceの借金 | 700 | 350 |
| aliceのCOL | 1000 | 567.647058823529411765 |
| carolのCOL（帳簿） | 0 | 432.352941176470588235 |

清算の規則：

| 場合 | 結果 |
|---|---|
| 0.85で351を返す | `AboveCloseFactor(350e6, 351e6)` |
| USDを担保として受け取ろうとする | `NotCollateral(USD)` |
| 凍結した市場（Frozen）で350を返す | 成功、aliceの借金350 |
| 価格0.3で350を返す（受け取るCOL 1225 > 預けた1000） | `SeizeExceedsCollateral(1000e18, 1225e18)` |

価格はそのままで、利息で清算ラインを超える場合（`test_interestCrossesLine`、年5%の市場、借りた比率70% → 年4.375%）：

| とき | aliceの借金 | 清算ライン | 結果 |
|---|---|---|---|
| 価格を0.9に変えて30分後 | 700.001749 | 720 | `NotLiquidatable(720e18, 700001749e12)` |
| 借りたときから1年 | 730.625 | 720 | 清算成功 |

受け取ったCOL 432.35を、COL/USDの定積のプール（手数料0.3%、USD側 = COL × 0.85）に一度に売った結果（`Econ198Test`、デモ）。プールが浅いと、ボーナス17.5が価格への影響に食われる。

| プールのCOL | 受け取ったUSD | 返した350との差 |
|---|---|---|
| 1,000,000 | 366.239630 | +16.239630 |
| 100,000 | 364.824900 | +14.824900 |
| 20,000 | 358.667219 | +8.667219 |
| 5,000 | 337.317004 | −12.682996 |
| 2,000 | 301.430750 | −48.569250 |

ローカルのanvilで自動マイニングを切り、carol（チップ1 gwei、最大手数料20 gwei、先に送る）とdave（チップ3 gwei、最大30 gwei、あとに送る）の清算を送ってから、ブロックを一つ作った結果：

```
carol tx 0xe6712fb1c82ca3c89d2ddf120b4b5bedc9b4ef38b635f41c0a2209d79bc27a92
  block 25 index 1 status 0 gasUsed 109308 effectiveGasPrice 1042490719
dave tx 0xff5a3822dc24b71931aa1699bd03cb97361c79995c399bb921c5712dc3afdec2
  block 25 index 0 status 1 gasUsed 258266 effectiveGasPrice 3042490719
debtOf(alice): 350000000 [3.5e8]
depositOf(COL, dave): 432352941176470588235 [4.323e20]
depositOf(COL, carol): 0
USD carol 1000000000 [1e9] dave 650000000 [6.5e8]
```

| 実行 | carol（先に送る） | dave（あとに送る） |
|---|---|---|
| 最大20 / 30 gwei | index 1、status 0 | index 0、status 1 |
| 最大20 / 20 gwei | index 0、status 1 | index 1、status 0 |

遅れた側の呼び出しをもう一度すると`NotLiquidatable`でリバートする。0xd8edc336 = `NotLiquidatable(uint256,uint256)`、0x14ecd37ae264c80000 = 386e18（清算ライン）、0x12f939c99edab80000 = 350e18（借金）である。遅れた側は帳簿の変化なしに手数料（gasUsed 109,308）だけを払う。

```
error code 3: execution reverted: custom error 0xd8edc336: ...14ecd37ae264c80000 ...12f939c99edab80000
```

今回のバージョンのMarket（CIスクリプト`ci ok`）：

| 項目 | 借りるバージョン | 清算のバージョン |
|---|---|---|
| テスト | 125 | 132 |
| ランタイム / 作成のコード（バイト） | 7,226 / 7,453 | 8,460 / 8,687 |
| セレクタ / イベント / エラー | 32 / 8 / 18 | 37 / 9 / 22 |
| IMarketのインターフェースID | 0x93a1e693 | 0x340612db |

### 試すときの注意

- テストは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガス記録の照合を切って実行する。`snapshots/`は添付していない。
- liquidateは、利息の積み上げ → 確認三つ → 受け取る担保 → 借金を減らす → 担保の欄を移す → 最後にtransferFrom、の順である。受け取った担保はトークンで送らず帳簿の欄に移すので、外部呼び出しはtransferFrom一つだけである。
- 清算の定数三つは定数なので、管理者も変えられない。清算は市場の状態に関係なくでき、担保の値は借りるときと同じ30分平均の価格で数える。
- anvilの並べ方（最大手数料の大きい側が先、同じなら先に受け取った側が先）は、このバージョンのanvilで2回回してみた観察である。実際のチェーンのブロック内の順番は、ブロックを作る側が決める。
- 清算は誰かが呼ぶときにだけ起きる。ボーナス5%が、ガスと受け取った担保を売るときの価格への影響を上回ってはじめて呼ばれる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わるとサイズ、ガス、anvilの動作が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| 清算の定数 | LIQUIDATION_GAP 5（パーセントポイント）、LIQUIDATION_BONUS 5%、CLOSE_FACTOR 50%。講義用の設計値、実在するプロトコルの値ではない | 2026-10-21 |
| anvilのデモ | ブロック25、dave index 0 status 1 gasUsed 258,266 effectiveGasPrice 3,042,490,719 / carol index 1 status 0 gasUsed 109,308 effectiveGasPrice 1,042,490,719。最大手数料が同じ実行：carol index 0 / dave index 1 | 2026-10-21 |
| anvilの並べ方の観察 | このバージョンのanvilで2回実行してみたもの：最大手数料の大きい側が先、同じなら先に受け取った側が先。実際のチェーンでブロックを作る側の並べ方には一般化しない | 2026-10-21 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| Marketのサイズ | ランタイム8,460 / 作成8,687バイト、メタデータハッシュの先頭4バイト`d01cf890` | 2026-10-21 |
| ガス記録（snapshots/Market.json） | addAsset75 92,839・deposit100 136,902・withdraw30 66,393・failDeposit0 26,356・setStatus0 23,147・setStatus1 45,059 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 借金が担保より大きいアカウントと回収できない借金 | [第199講](../../part13/lecture199/) |
| 清算が集中するときのプールの価格 | [第199講](../../part13/lecture199/) |
| ブロックを作る側の順番の販売と、実際の清算の競争 | [第224講](../../part16/lecture224/)、[第225講](../../part16/lecture225/)、[第226講](../../part16/lecture226/)、[第227講](../../part16/lecture227/)、[第228講](../../part16/lecture228/) |
| オークション式の清算 | 付録 |
| 清算ボーナスの値を変えるガバナンス | [第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/)、[第215講](../../part14/lecture215/)、[第216講](../../part14/lecture216/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
