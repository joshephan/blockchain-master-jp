# 第199講 連鎖清算と極限の状況

第13部 DeFi・第53章 レンディングと清算

[← 第198講](../../part13/lecture198/) | [第13部 目次](../) | [第200講 →](../../part13/lecture200/)

## この講義の問い

価格が一度に大きく下がると、清算は間に合うのか。担保を全部持っていっても借金が残ると、その借金は誰が負うのか。清算がほかの清算を呼ぶことは、どうして起きるのか。価格の出どころが止まると、Marketの何が止まるのか。

## 実習資料

### 準備

通しプロジェクトMarketのこの講義のバージョン（清算のバージョンに、借金全部までの清算と、残った借金の消去`writeOffBadDebt`を足したバージョン）から始める。デモ用に、連鎖清算のテスト`Cascade199.t.sol`、資産の数ごとのガスのテスト`Gas199.t.sol`、そのテストが使うおもちゃのプールのコピー（`test/amm/`）を足した。forge-std（1.17.0）とOpenZeppelin Contracts 5.4.0が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。anvilと外部への接続は使わない。価格1.0・0.5・0.3、プールの深さ、外での売却量はテストが決めた数字である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | ビルド設定（OpenZeppelinのremappingを1行追加） |
| [code/src/Market.sol](code/src/Market.sol) | 受け取る担保を預けた量まで減らすliquidate、`_repayFor`、`writeOffBadDebt`・`_writeOff`を足したMarket |
| [code/src/](code/src/) | IMarket、MarketMath、MarketTypes、テスト用のMockToken |
| [code/test/BadDebt.t.sol](code/test/BadDebt.t.sol) | 平均の遅れ、借金全部の清算、遅れた清算と残った借金、損失の分担、価格の出どころが止まるときのテスト五つ |
| [code/test/Liquidate.t.sol](code/test/Liquidate.t.sol) | 清算のテスト六つ |
| [code/test/TwapFeed.sol](code/test/TwapFeed.sol) | テスト用の価格の出どころ（`stop()`を追加） |
| [code/test/Cascade199.t.sol](code/test/Cascade199.t.sol) | 同じプールを価格の出どころに使い、受け取った担保もそのプールに売る連鎖清算（デモ用、基準のバージョンにはない） |
| [code/test/Gas199.t.sol](code/test/Gas199.t.sol) | 登録した資産の数ごとのborrow・liquidateのガス（デモ用、基準のバージョンにはない） |
| [code/test/amm/](code/test/amm/) | 連鎖清算のテストが使うToyAmm・ToyErc20のコピー |
| [code/test/](code/test/) | そのほかの基準のバージョンのテスト |

### 実行結果

`forge test --offline --match-contract "BadDebtTest|LiquidateTest" -vv`（11個通過）：

```
[PASS] test_feedStopped() (gas: 462142)
[PASS] test_lateLiquidationBadDebt() (gas: 587238)
[PASS] test_twapLagUnprofitable() (gas: 664087)
[PASS] test_underwaterFullLiquidation() (gas: 588040)
[PASS] test_writeOffSharesLoss() (gas: 688160)
Suite result: ok. 5 passed; 0 failed; 0 skipped
[PASS] test_closeFactorAndCollateralOnly() (gas: 421649)
[PASS] test_gapBand() (gas: 427158)
[PASS] test_interestCrossesLine() (gas: 3701262)
[PASS] test_liquidateHalf() (gas: 698335)
[PASS] test_liquidateWhenFrozen() (gas: 419794)
[PASS] test_secondLiquidatorReverts() (gas: 481192)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

価格が1.0から0.5に一度に下がるとき、30分平均は遅れてついていく（aliceのCOL 1000、借金700、利息0の市場）。

| 下がってから | 30分平均 | 清算ライン | 清算 |
|---|---|---|---|
| 0分 | 1.0 | 800 | `NotLiquidatable(800e18, 700e18)` |
| 10分 | 0.833 | 666.67 | できる |
| 30分 | 0.5 | 400 | できる |

10分目に350を返した側は、平均0.833で数えたCOL 441.000000000000000176を受け取るが、実際の値（0.5）は220.500000000000000088なので129.5の損である（`test_twapLagUnprofitable`）。

担保の値が借金より小さいアカウントは、受け取る担保を預けた量全部まで減らし、返す量もそれに合わせて減らす。このときは借金全部まで返せる（0.3で701 → `AboveCloseFactor(700e6, 701e6)`）。払ったUSD = 担保の値 / 1.05（切り上げ）である。

| 価格 | 担保の値 | carolが払ったUSD | carolが受け取ったCOL | 残った借金 |
|---|---|---|---|---|
| 0.3 | 300 | 285.714286 | 1000 | 414.285714 |
| 0.5（30分後） | 500 | 476.190477 | 1000 | 223.809523 |

残った借金の消去（価格0.3）：

| とき | 結果 |
|---|---|
| 清算の前にwriteOffBadDebt | `HasCollateral(300e18)` |
| 清算のあとにdaveがwriteOffBadDebt | `BadDebtWrittenOff(USD, alice, 414.285714)` |
| bobの持ち分（depositOf） | 1000 → 585.714286 |
| MarketのUSD残高 | 585.714286 |
| bobのwithdrawAllのあとのMarketのUSD | 0 |

0.5の場合は223.809523を消し、bobの持ち分776.190477がMarketの残高と同じになる。利息は預けた側の指数を上げ、消した借金は預けた側の指数を下げる。

価格の出どころが止まっているあいだ（`test_feedStopped`）：

| 関数 | 価格を読むか | 結果 |
|---|---|---|
| repay（USD 100） | 読まない | 成功、借金600 |
| bobのwithdraw（USD 300）、担保ではない | 読まない | 成功 |
| aliceのwithdraw（COL 1）、担保 | 読む | `Stopped()` |
| borrow（USD 1） | 読む | `Stopped()` |
| liquidate | 読む | `Stopped()` |

連鎖清算のデモ（`forge test --offline --match-contract "Cascade199Test|Gas199Test" -vv`）。アカウント四つ（担保COL 1000ずつ、借金700・650・600・550、清算ラインを超える価格0.875・0.8125・0.75・0.6875）があり、価格の出どころは同じプールの30分平均で、清算で受け取ったCOLも同じプールに売る。外でCOLを売ってプールの価格を0.8575にしてから、回ごとに30分待つ。清算のプログラムは、損でも呼び続ける単純な形である。

```
[PASS] test_deepPoolStops() (gas: 10310784)
Logs:
  depth 1000000, pool price after outside sale (1e-4) 8575
  round 1: liquidations 1, pool price (1e-4) 8568
  round 2: liquidations 0, pool price (1e-4) 8568
  left: debt USD 2150, collateral value USD 3060
  written off, lender lost USD 0
  liquidator net USD (signed, 1e-2)
  1625
  deep pool total liquidations 1
[PASS] test_thinPoolCascade() (gas: 36310485)
Logs:
  depth 10000, pool price after outside sale (1e-4) 8575
  round 1: liquidations 1, pool price (1e-4) 7934
  round 2: liquidations 1, pool price (1e-4) 7360
  round 3: liquidations 2, pool price (1e-4) 6575
  round 4: liquidations 3, pool price (1e-4) 5765
  round 5: liquidations 4, pool price (1e-4) 5161
  round 6: liquidations 4, pool price (1e-4) 4864
  round 7: liquidations 3, pool price (1e-4) 4667
  round 8: liquidations 1, pool price (1e-4) 4651
  round 9: liquidations 0, pool price (1e-4) 4651
  left: debt USD 45, collateral value USD 60
  written off, lender lost USD 10
  liquidator net USD (signed, 1e-2)
  -667
  thin pool total liquidations 19
[PASS] test_gasByAssetCount() (gas: 68859253)
Logs:
  assets 2: borrow gas 204128, liquidate gas 264842
  assets 20: borrow gas 326582, liquidate gas 387284
  assets 100: borrow gas 870822, liquidate gas 931536
  assets 500: borrow gas 3592022, liquidate gas 3652736
```

| | 浅いプール | 深いプール |
|---|---|---|
| プールの深さ / 外での売却 | 10,000 / 800 | 1,000,000 / 80,000 |
| 清算の回数 | 19 | 1 |
| 最後のプールの価格 | 0.4651 | 0.8568 |
| 預けた側の損失 / 清算した側の合計 | 10 / −6.67 | 0 / +16.25 |

資産の数ごとのガスは、上限の計算が資産のリストを全部回るループ一つのせいで、資産一つにつき約6,800ずつ増える。

今回のバージョンのMarket（CIスクリプト`ci ok`）と、監査したビルドの比較：

| 項目 | 清算のバージョン | 今回のバージョン |
|---|---|---|
| テスト | 132 | 136 |
| ランタイム / 作成のコード（バイト） | 8,460 / 8,687 | 9,006 / 9,233 |
| セレクタ / イベント / エラー | 37 / 9 / 22 | 38 / 10 / 22 |
| IMarketのインターフェースID | 0x340612db | 0x6edfb350 |

| 項目 | 監査したビルド | 今回のバージョン |
|---|---|---|
| src四つの行（空行・コメントを除いた行） | 515（217） | 1,014（513） |
| セレクタ | 19 | 38 |
| 管理者専用 | 2 | 3 |
| 外部呼び出し | CALL 2 | CALL 5 + STATICCALL 3 |
| block.timestamp / ループ | 3 / 1 | 6 / 2 |
| メタデータハッシュの先頭4バイト | de70fa9e | 2fa6d798 |

### 試すときの注意

- テストは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガス記録の照合を切って実行する。`snapshots/`は添付していない。
- writeOffBadDebtは誰でも呼べて市場の状態に関係ないが、担保の値が0のときだけできる（`HasCollateral`）。損失は、その資産を預けた人たちが持ち分に応じて分けて負う。
- 消す借金が預けた量より大きいと、計算がPanic 0x11で止まる。貸し出した量は預けた量を超えないとみなし、信頼の前提に書いた。
- 平均の窓が長いと操作のコストは大きくなるが、同じ長さが本当の下落にも遅れてついていくことになる。
- Gas199の実行時に、`lastCallGas()`がまもなくなくなるという警告（`lastFrameGas`に変わる）が出る。結果には影響しない。
- 監査したビルドと比べると、範囲が2倍以上大きくなった。監査が見たコードは、メタデータハッシュ`de70fa9e`のビルドだけである。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わるとサイズとガスが変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| 事件 | MakerDAO、2020年3月（ブラックサーズデー）。価格が急に下がりネットワークが詰まった日に、清算オークションの一部が競争なしに0に近い値で落札された事件 | 2026-10-21 |
| Uniswap v2 Coreホワイトペーパー | 2020年3月、価格オラクルの節（平均の期間を長くとるほど操作のコストが大きくなる） | 2026-10-21 |
| デモの値 | 価格1.0・0.5・0.3、プールの深さ10,000・1,000,000、外での売却800・80,000はテストが決めた数字 | 2026-10-21 |
| 清算のガス（Gas199） | 資産2・20・100・500個：borrow 204,128・326,582・870,822・3,592,022、liquidate 264,842・387,284・931,536・3,652,736 | 2026-10-21 |
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| Marketのサイズ | ランタイム9,006 / 作成9,233バイト、メタデータハッシュの先頭4バイト`2fa6d798` | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 複数の価格の出どころと、止まった出どころを差し替える設計 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| 平均の窓の長さを選ぶこと | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| 損失を先に引き受ける準備金・保険 | [第202講](../../part13/lecture202/)、[第203講](../../part13/lecture203/) |
| 極限の状況の実際の事件の分け直し | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| 第53章のバージョンの再監査（範囲・発見事項） | [第254講](../../part20/lecture254/)、[第255講](../../part20/lecture255/)、[第256講](../../part20/lecture256/) |
| キャップストーンで清算の設計を組み直す | [第270講](../../part21/lecture270/)、[第271講](../../part21/lecture271/)、[第272講](../../part21/lecture272/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
