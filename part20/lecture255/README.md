# 第255講 コアロジックの実装

第20部 キャップストーンプロジェクト・第70章 設計と実装

[← 第254講](../../part20/lecture254/) | [第20部 目次](../) | [第256講 →](../../part20/lecture256/)

## この講義の問い

設計ドキュメントをコードに移すとき、何をそのまま守るのか。書き直したコードが正しいかを、何と比べるのか。ガスをもっと節約するために、機械命令に近い側へ降りる理由はあるのか。

## 実習資料

### 準備

第254講のバージョンから続ける。設計ドキュメント4節の順番（確認 → 利息の積み上げ → 現金・上限の確認 → 帳簿の更新 → 上限の確認 → トークンの移動 → イベント）どおりに、Marketの最初のバージョンを一つのコントラクト（388行、コンストラクター`(address admin_, uint256 rateAtKink_)`、設定キー一つ）で書き、中身のなかった要件テストを埋める。設計ドキュメントには12節「コアロジックで確認したこと」を加えた。依存関係はforge-std 1.17.0（`lib/forge-std`）一つで、anvilは使わない。テスト用のトークンと価格の出どころは`test/helpers/`にある。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、`debug`プロファイル |
| [code/design/requirements.md](code/design/requirements.md) | 要件 |
| [code/design/architecture.md](code/design/architecture.md) | 設計ドキュメント（12節「コアロジックで確認したこと」を追加） |
| [code/src/Market.sol](code/src/Market.sol) | Marketの最初のバージョン：deposit・withdraw・borrow・repay・liquidate・借金の消去、利息の指数二つ（`_indexesNow`、`_accrue`）、上限の計算`_health` |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束 |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | 型と構造体 |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 計算の部品 |
| [code/test/Functional.t.sol](code/test/Functional.t.sol) | 機能要件のテスト11個（中身を埋めた） |
| [code/test/Safety.t.sol](code/test/Safety.t.sol) | 安全の要件のテスト（S-01〜S-06を埋めた、S-07・S-08は次のバージョン） |
| [code/test/Ops.t.sol](code/test/Ops.t.sol) | 運用の要件のテスト二つ |
| [code/test/Access.t.sol](code/test/Access.t.sol) | 権限の要件のテスト（まだ中身なし） |
| [code/test/Layout.t.sol](code/test/Layout.t.sol) | ストレージの欄が設計ドキュメント2節の地図どおりか |
| [code/test/Gas.t.sol](code/test/Gas.t.sol) | 測った呼び出し五つのガスのログ |
| [code/test/Math.t.sol](code/test/Math.t.sol)、[Interface](code/test/Interface.t.sol) | 計算の部品のテスト、インターフェースID |
| [code/test/helpers/Base.sol](code/test/helpers/Base.sol) | テストの土台（マーケット・トークン・価格の出どころのデプロイ） |
| [code/test/helpers/StdToken.sol](code/test/helpers/StdToken.sol) | テスト用の標準トークン |
| [code/test/helpers/TwapFeed.sol](code/test/helpers/TwapFeed.sol) | テスト用の累積価格の出どころ（30分平均） |
| [code/test/helpers/HookToken.sol](code/test/helpers/HookToken.sol) | 移される瞬間にMarketの帳簿を読んで書き留めるテスト用トークン（読むだけで、Marketを呼び返さない） |

### 実行結果

`forge test --offline --match-contract FunctionalTest -vv`：

```
Ran 11 tests for test/Functional.t.sol:FunctionalTest
[PASS] test_F01_depositEarnsInterest() (gas: 3614438)
[PASS] test_F02_withdrawUpToCash() (gas: 641894)
[PASS] test_F03_collateralToggle() (gas: 892002)
[PASS] test_F04_borrowWithinLimit() (gas: 648077)
[PASS] test_F05_repayCapsAtDebt() (gas: 620737)
[PASS] test_F06_rateCurve() (gas: 3878675)
[PASS] test_F07_liquidateHalfWithBonus() (gas: 1529192)
[PASS] test_F07_underwaterFullLiquidation() (gas: 1042862)
[PASS] test_F08_writeOffSharesLoss() (gas: 1123688)
[PASS] test_F09_twapNotSpot() (gas: 372358)
[PASS] test_F10_listAssetOnce() (gas: 1182033)
Suite result: ok. 11 passed; 0 failed; 0 skipped
```

`--match-contract SafetyTest -vv`：

```
Ran 8 tests for test/Safety.t.sol:SafetyTest
[PASS] test_S01_exitPathsNeverPaused() (gas: 1217649)
[PASS] test_S02_ledgerBeforeTransfer() (gas: 1925204)
[PASS] test_S03_vaultCoversPromises() (gas: 4651846)
[PASS] test_S04_roundingFavorsMarket() (gas: 3811213)
Logs:
  dust: 2
[PASS] test_S05_assetCountCap() (gas: 12104166)
[PASS] test_S06_zeroShareDepositReverts() (gas: 3613235)
[SKIP] test_S07_creditsReceivedAmount() (gas: 0)
[SKIP] test_S08_noReturnToken() (gas: 0)
Suite result: ok. 6 passed; 0 failed; 2 skipped
```

`--match-contract GasTest -vv`のログ：

```
  deposit: 137297
  borrow: 160226
  repay: 61481
  withdraw: 64704
  liquidate: 233854
```

全体の`forge test --offline`は26通過、0失敗、7スキップ（33個）である。`forge build --offline --sizes`では、Marketはruntime 8,232 / initcode 8,423バイト（残りの余裕16,344 / 40,729）である。

テストが確かめる数字（前のバージョンのテストと同じ場面で同じ数字）：

| 場面 | 結果 |
|---|---|
| F-01 1年の利息 | 折れ点5%のマーケット、bobがUSD 1000を預け、aliceがCOL 1000を担保にUSD 500を借りる（借りた比率50%、年3.125%） → 1年後に借金515.625、預けた量1015.625 |
| F-04 上限 | COL 1000 × 価格1.0 × 担保比率75% = 750。751 → `InsufficientCollateral(750e18, 751e18)` |
| F-09 30分平均 | 最後の12秒だけ価格16倍 → (1,788秒 × 1.0 + 12秒 × 16) ÷ 1,800秒 = 1.1、上限825 |
| F-02 引き出し | 700を貸し出したあとに400 → `InsufficientLiquidity(300e6, 400e6)`、701 → `InsufficientDeposit(700e6, 701e6)` |
| F-07 半分の清算 | 価格0.85で清算ライン680 < 借金700。351 → `AboveCloseFactor(350e6, 351e6)`、350 → 成功、受け取ったCOL 432.352941176470588235、次の清算 → `NotLiquidatable(386e18, 350e18)` |
| F-07・F-08 水面下の場面 | 価格0.3で借金全部まで。返した量285.714286、残りの借金414.285714を消し、bobの預けた量585.714286 = 金庫のUSD |
| S-02 順番 | トークンが移される瞬間に読んだ帳簿：預け入れのとき100e18、借り入れのとき50e18（帳簿をすでに直したあと） |
| S-06 持ち分0 | 30日分の利息のあとに1単位を預け入れ → `ZeroShares`、2単位 → 成功 |
| S-05 資産数 | 21番目の資産 → `TooManyAssets(20)` |

`forge lint --offline src`は警告十一（calls-loop 2、reentrancy-events 5、block-timestamp 2、require-revert-in-loop 1、unused-return 1）を残し、設計ドキュメント12節に自己監査の候補として書いた。

### 試すときの注意

- 五つの関数（deposit、withdraw、borrow、repay、liquidate）はすべて同じ順番に従う。最後にトークンを移すので、トークン側のコードが動く瞬間には帳簿はすでに直したあとである。
- 丸めは常に金庫の側にする（渡す値は切り捨て、受け取る値は切り上げ）。`Market.sol`の中の`mulDivDown` 17か所、`mulDivUp` 11か所を設計ドキュメント4節と照らし合わせた。S-04の`dust: 2`（USD 6桁で0.000002）は、全部返して全部引き出したあとに金庫に残るかけらである。
- 借金の消去が預けた合計を超える場合は`LossExceedsDeposits(loss, deposits)`で防いだが、その巻き戻しを直接見るテストはこのバージョンにはない。
- テスト用マーケットの利率（折れ点0または5%）と設計値は講義用の値である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンとコードが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| ツール | forge 1.8.3（commit cae51ad4）、solc 0.8.30、forge-std 1.17.0 | 2026-10-21 |
| このバージョンのテスト | 26通過、0失敗、7スキップ（33） | 2026-10-21 |
| Marketのサイズ | runtime 8,232 / initcode 8,423バイト（残りの余裕16,344 / 40,729） | 2026-10-21 |
| 測った呼び出し五つ | deposit 137,297、borrow 160,226、repay 61,481、withdraw 64,704、liquidate 233,854 | 2026-10-21 |
| forge lint | calls-loop 2、reentrancy-events 5、block-timestamp 2、require-revert-in-loop 1、unused-return 1 | 2026-10-21 |
| 切り捨て・切り上げの箇所 | mulDivDown 17、mulDivUp 11 | 2026-10-21 |
| 講義用の設計値 | 折れ点80%（テスト用マーケットの利率0または5%）、30分、清算ラインの間隔5、ボーナス5%、50%、比率の上限80、資産20個 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 入ってきた量を数える（S-07）、返り値のないトークン（S-08） | [第256講](../../part20/lecture256/) |
| 設定キーを分ける（A-01〜A-05） | [第257講](../../part20/lecture257/) |
| 価格の出どころが止まったとき・平均が遅れてついてくるときのテスト | [第258講](../../part20/lecture258/) |
| 不変条件五つをランダムな順番で | [第259講](../../part20/lecture259/) |
| lintの警告十一の判定 | [第260講](../../part20/lecture260/) |
| コアロジックの行ごとのガス削減 | 扱わない |

出典と参考資料は[reference.md](reference.md)にまとめた。
