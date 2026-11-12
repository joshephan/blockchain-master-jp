# 第197講 金利曲線と担保率

第13部 DeFi・第53章 レンディングと清算

[← 第196講](../../part13/lecture196/) | [第13部 目次](../) | [第198講 →](../../part13/lecture198/)

## この講義の問い

預けたお金を貸す市場で、利率は誰が決めるのか。預けた人が受け取る利息はどこから来るのか。担保を預けるといくらまで借りられ、その担保の値は何で決めるのか。枠だけがあったMarketの借りる欄に、何を書き込むべきか。

## 実習資料

### 準備

通しプロジェクトMarketのこの講義のバージョン（借りる・返す・利息の指数・担保の上限・時間加重平均の価格の出どころを足したバージョン）から始める。基準のバージョンのテストに、デモ用のテスト二つ（`Curve197.t.sol`、`Audit53.t.sol`）を足したコピーである。テストにはforge-std（1.17.0）が必要である（`lib/forge-std`）。COL（18桁）・USD（6桁）のトークンと価格の出どころTwapFeedはテスト用である。anvilと外部への接続は使わない。折れ曲がる点・傾き・平均の窓の値は講義用の設計値で、実在するプロトコルの値ではない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | ビルド設定（solc 0.8.30、optimizerオン runs 200、via-IRオン、evm osaka） |
| [code/src/Market.sol](code/src/Market.sol) | borrow・repay・setCollateral・setPriceFeed、利息の指数（`_indexesNow`）、debtOf・depositOf、accountHealth、priceOf（30分平均）を足したMarket |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利率の曲線`borrowRate`（折れ曲がる点80%）、utilization、divUp |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | IPriceFeed（`cumulativePrice`）、PriceConfigなどの型 |
| [code/src/IMarket.sol](code/src/IMarket.sol) | インターフェース（interestRateの意味を「折れ曲がる点での年利」に直した） |
| [code/src/MockToken.sol](code/src/MockToken.sol) | テスト用のトークン |
| [code/test/Borrow.t.sol](code/test/Borrow.t.sol) | 借りるテスト12個（上限、利息、流動性、丸めの不等式、TWAP、価格の出どころの規則など） |
| [code/test/TwapFeed.sol](code/test/TwapFeed.sol) | テスト用の価格の出どころ |
| [code/test/Curve197.t.sol](code/test/Curve197.t.sol) | 借りた比率ごとの利率と、預けた側の利息の表（デモ用、基準のバージョンにはない） |
| [code/test/Audit53.t.sol](code/test/Audit53.t.sol) | 手数料トークンを担保として登録すると、帳簿が受け取った量より大きくなることを再現（デモ用、基準のバージョンにはない） |
| [code/test/](code/test/) | そのほかの基準のバージョンのテスト（Layout、NoSigなど） |

### 実行結果

利率の曲線。借りた比率が80%まではゆるやかに、超えると急に上がる。折れ曲がる点の利率はMarketのinterestRate（5e16）である。`Curve197Test`（預けた1000、1年）：

```
borrowed 0 / 1000, borrow rate bps 0, depositor gain (USD 1e-6) 0
borrowed 200 / 1000, borrow rate bps 125, depositor gain (USD 1e-6) 2500000
borrowed 400 / 1000, borrow rate bps 250, depositor gain (USD 1e-6) 10000000
borrowed 600 / 1000, borrow rate bps 375, depositor gain (USD 1e-6) 22500000
borrowed 800 / 1000, borrow rate bps 500, depositor gain (USD 1e-6) 40000000
borrowed 850 / 1000, borrow rate bps 3000, depositor gain (USD 1e-6) 255000000
borrowed 900 / 1000, borrow rate bps 5500, depositor gain (USD 1e-6) 495000000
borrowed 950 / 1000, borrow rate bps 8000, depositor gain (USD 1e-6) 760000000
borrowed 1000 / 1000, borrow rate bps 10500, depositor gain (USD 1e-6) 1050000000
```

預けた側が受け取った利息は、借りた量 × 利率と同じである（800 × 5% = 40、1000 × 105% = 1050）。Marketが取る分はない。

`forge test --offline --match-contract "BorrowTest|NoSigTest|LayoutTest" -vv`（18個通過）のうちBorrowTest：

```
[PASS] test_borrowUpToLimit() (gas: 655918)
[PASS] test_donationAndSameBlock() (gas: 727499)
[PASS] test_frozenStillRepays() (gas: 611843)
[PASS] test_interestFlowsToDepositor() (gas: 686836)
[PASS] test_liquidityLimit() (gas: 507174)
[PASS] test_priceFeedRules() (gas: 843809)
[PASS] test_rateCurve() (gas: 937496)
[PASS] test_repayCapsAtDebt() (gas: 590587)
[PASS] test_shortHistoryReverts() (gas: 1097015)
[PASS] test_solvencyTable() (gas: 2250370)
[PASS] test_twapNotSpot() (gas: 355584)
[PASS] test_withdrawKeepsDebtCovered() (gas: 776108)
Suite result: ok. 12 passed; 0 failed; 0 skipped
```

テストごとに確かめた値：

| テスト | 確かめたこと |
|---|---|
| test_liquidityLimit | 1001を借りる → `InsufficientLiquidity(1000e6, 1001e6)`、aliceが700借りたあとbobが400引き出す → `InsufficientLiquidity(300e6, 400e6)` |
| test_rateCurve | 借りた比率50% → 年3.125% |
| test_interestFlowsToDepositor | 1年後にdebtOf(alice) 500 → 515.625、depositOf(bob) 1000 → 1015.625、全部返してbobが全部引き出すとMarketのUSDは0 |
| test_donationAndSameBlock | 30日後にMarketのアドレスへUSD 5000を直接送ってもsupplyIndexはそのまま、同じブロックで100入れて100引き出すとbobの残高はそのまま |
| test_solvencyTable | 借りる量1 wei〜333.333333、待ち時間1秒〜3年、返す量1 wei〜2000の6回ごとに「残ったUSD + 貸し出した借金 ≥ 預けた人が引き出す量」 |
| test_borrowUpToLimit | COL 1000 × 1.0 × 75% = 750。borrow 751 → `InsufficientCollateral(750e18, 751e18)`、borrow 700は成功、collateralCount(alice) = 1 |
| test_withdrawKeepsDebtCovered | 700借りたあとCOL 100を引き出す → `InsufficientCollateral(675e18, 700e18)`、担保を切る → `(0, 700e18)`、COL 60を引き出すのは成功（上限705） |
| test_frozenStillRepays | Frozenでborrowは`NotActive(2)`、repayは成功 |
| test_twapNotSpot | 最後の12秒だけ16倍：その瞬間の価格16.0なら上限12,000、30分平均1.1なら825。priceOf(COL) = 1.1e18 |
| test_shortHistoryReverts | 記録が30分より短い出どころのpriceOf → `ShortHistory` |
| test_priceFeedRules | 管理者でない側は`NotAdmin`、0アドレスは`ZeroFeed()`、2番目の出どころは`PriceFeedAlreadySet`、登録していない資産は`NotListed`、出どころのない資産は`NoPriceFeed` |

丸めは、預けた持ち分・引き出す量・担保の値は切り捨て、借りた持ち分・返す量・借金の値は切り上げ（divUp）である。桁数の違う二つのトークンは、値 = トークンの量 × 価格 / 10^decimalsで合わせる（COL 700e18とUSD 700e6がどちらも値700e18）。decimalsはsetPriceFeedのときに一度読んで保存する。

`forge lint --offline --only-lint unsafe-typecast`の警告四つ（位置ごとに縮めて書いた）。uint64の秒があふれるのは約5,800億年後なので、信頼の前提のドキュメントに書く。

```
warning[unsafe-typecast]: typecast can truncate values
  src/Market.sol      260  r.lastAccrual = uint64(block.timestamp);
  src/Market.sol      272  ... reserves[asset].lastAccrual = uint64(block.timestamp);
  src/MarketMath.sol   55  self.lastUpdate = uint64(block.timestamp);
  src/MarketMath.sol   63  self.lastUpdate = uint64(block.timestamp);
```

`Audit53Test`（デモ）：移すときに1%をバーンするテスト用のトークンを担保として登録すると、Marketに入ったトークンは990なのにdepositOfは1000、借りられる上限は1000で数えた750である。

```
[PASS] test_L01_feeTokenCollateralOverstated() (gas: 2319599)
```

今回のバージョンのMarket（CIスクリプト`ci ok`、テスト125個）：

| 項目 | 前のバージョン | 今回のバージョン |
|---|---|---|
| テスト | 111 | 125 |
| ランタイム / 作成のコード（バイト） | 2,990 / 3,203 | 7,226 / 7,453 |
| セレクタ / イベント / エラー | 19 / 4 / 12 | 32 / 8 / 18 |
| IMarketのインターフェースID | 0xab691738 | 0x93a1e693 |
| 外部呼び出し（CALL / STATICCALL） | 2 / 0 | 4 / 3 |

スロットマップに足した2行。0〜5はそのままで、positionsのdeposited・borrowedは指数で割った持ち分になる。

| スロット | 欄 | コントラクト |
|---|---|---|
| 6 | reserves[asset]：keccak256(asset . 6)から3欄。+0 borrowIndex、+1 supplyIndex、+2 lastAccrual | Ledger |
| 7 | priceConfig[asset]：keccak256(asset . 7) 1欄。feedはオフセット0、decimalsはオフセット20 | Market |

### 試すときの注意

- テストは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガス記録の照合を切って実行する。`snapshots/`は添付していない。
- 利息の指数の保存欄の0は1（1e18）として読む。トークンの量は持ち分 × 指数である。
- 利息の指数は、経過した秒と帳簿の借りた持ち分だけで上がる。Marketのトークン残高は計算に入らないので、直接送ったトークンが利率を変えることはできない。
- priceOfは`cumulativePrice(0) - cumulativePrice(TWAP_WINDOW)`を30分で割る。その瞬間の価格を読む関数はない。
- setPriceFeedは管理者だけが、資産ごとに一度だけ呼べ、変えたり消したりする関数はない。折れ曲がる点、傾き、平均の窓はすべて定数である。
- 返す（repay）は市場の状態と価格を見ない。凍結した市場でも借金は返せる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わるとサイズとガスが変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| 利率の曲線・平均の窓 | 折れ曲がる点80%（KINK 0.8e18）、折れ曲がる点の利率 = interestRate 5e16、折れ曲がる点のあとの傾き年100%（JUMP_RATE 1e18）、TWAP_WINDOW 30分。講義用の設計値、実在するプロトコルの値ではない | 2026-10-21 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| Marketのサイズ | ランタイム7,226 / 作成7,453バイト（前のバージョン2,990 / 3,203）、メタデータハッシュの先頭4バイト`03712eb2` | 2026-10-21 |
| ガス記録（snapshots/Market.json） | addAsset75 92,751・deposit100 136,833・withdraw30 66,211・failDeposit0 26,312・setStatus0 23,125・setStatus1 45,037 | 2026-10-21 |
| テストのガス | test_borrowUpToLimit 655,918 / test_interestFlowsToDepositor 686,836 / test_twapNotSpot 355,584 / test_solvencyTable 2,250,370（`.gas-snapshot`はほかのテストで12・24ずつ揺れる） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 清算ラインと清算ボーナス | [第198講](../../part13/lecture198/) |
| 価格が急に下がるときと回収できない借金 | [第199講](../../part13/lecture199/) |
| 利率の曲線の値を誰がどう変えるか（ガバナンス） | [第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/)、[第215講](../../part14/lecture215/)、[第216講](../../part14/lecture216/) |
| 価格の出どころの設定の時間的な遅延 | [第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/)、[第215講](../../part14/lecture215/)、[第216講](../../part14/lecture216/) |
| 複数の価格の出どころと、桁数の違う出どころ | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| プロトコルの手数料の取り分と準備金 | [第202講](../../part13/lecture202/)、[第203講](../../part13/lecture203/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
