# 第202講 収益の出どころの分類

第13部 DeFi・第55章 利回りの出どころを追う

[← 第201講](../../part13/lecture201/) | [第13部 目次](../) | [第203講 →](../../part13/lecture203/)

## この講義の問い

「収益が出る」というコントラクトで、そのトークンはコードのどの行から入ってきて、どの行から出ていくのか。収益の出どころは何通りあるのか。利率が書かれたMarketは、実際に利息を払うのか。

## 実習資料

### 準備

収益の出どころを分ける講義用のおもちゃ四つ（1ファイル`Yield202.sol`）と、通しプロジェクトMarketのコピーを使う。おもちゃは実在する商品のコードではなく、10%・0.3%・1日1%はおもちゃの値である。Marketのコピーは、連鎖清算まで入ったバージョンのソースを変えず、確認テスト`Yield55.t.sol`だけを足した。二つのプロジェクトとも、forge-std（1.17.0）が必要である（`lib/forge-std`）。Marketのデプロイのデモは、ローカルのanvil一つで、anvilの既定のアカウント（`--unlocked`）だけで行う。

### コード

| ファイル | 内容 |
|---|---|
| [code/yield/src/Yield202.sol](code/yield/src/Yield202.sol) | ToyToken、LendPool202（年10%の利息）、FeePool202（0.3%の手数料）、Farm202（毎秒1個の報酬を新しく発行）、FixedYield202（1日1%の約束） |
| [code/yield/test/Source202.t.sol](code/yield/test/Source202.t.sol) | おもちゃごとに、収益を入れた側を確かめるテスト五つ |
| [code/yield/foundry.toml](code/yield/foundry.toml) | ビルド設定（via-IR、optimizerオン） |
| [code/market/test/Yield55.t.sol](code/market/test/Yield55.t.sol) | 利率の値、借りる人なしで1年、借りる側の欄、返す分と現金のテスト四つ |
| [code/market/src/](code/market/src/) | Marketのソース（変えていない） |
| [code/market/test/](code/market/test/) | Marketの基準のバージョンのテスト全体（Donation、Borrowを含む） |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |

### 実行結果

収益を探す順番は、トークンが出ていく行から逆にさかのぼる四つの段階である。払い出す行（transfer・mint） → その量を決める式 → 式に入った値が増える行 → その行でトークンを入れた人。

`forge test --offline --match-contract Source202Test -vv`（五つ通過）：

```
[PASS] test_feeFromTraders() (gas: 471789)
Logs:
  bob swap A100 -> B 90 -> A 97
  alice removes A 1003 B 1000
[PASS] test_interestFromBorrower() (gas: 374471)
Logs:
  alice got 1050 bob left 950
[PASS] test_noBorrowerNoInterest() (gas: 181158)
[PASS] test_paidByNextDepositor() (gas: 391116)
[PASS] test_rewardIsMinted() (gas: 227661)
Suite result: ok. 5 passed; 0 failed; 0 skipped
```

| おもちゃ | テストで見たもの |
|---|---|
| LendPool202 | aliceが1,000を預け、bobが500を借りる。365日後にbobが550をrepay（ウォレット950）し、aliceは1,050を引き出す。借りる人がいなければ、365日後も1,000のまま |
| FeePool202 | aliceがA・Bを1,000ずつ預ける。bobがA 100 → B 90 → A 97と交換し、aliceはA 1,003・B 1,000を引き出す。二人のA・Bの合計は最初4,000、最後4,000 |
| Farm202 | aliceが1,000を預け、50秒後にclaimで報酬50。報酬トークンのtotalSupply 0 → 50、farmの中の預けたトークンは1,000のまま |
| FixedYield202 | aliceが0日目に1,000、bobが10日目に1,000を預ける。20日目に受け取る分は1,200・1,100（合計2,300）なのに金庫は2,000。aliceが1,200を引き出したあと、bobは`NoCash(800, 1100)` |

四つの出どころ：

| 誰が入れたか | 入れる行 | おもちゃと結果 |
|---|---|---|
| 借りた人 | repayのtransferFrom | LendPool202、alice 1,050 |
| 取引した人 | swapのtransferFromと`reserveA += inA`（手数料を引いた量ではなく、入れた量全部） | FeePool202、alice A 1,003 |
| 誰もいない（新しく発行） | claimのmint | Farm202、報酬50・供給 +50 |
| あとから入ってきた人 | depositのtransferFrom | FixedYield202、alice 1,200・bobは受け取れない |

Marketは残高ではなく帳簿で数える（`DonationTest`）：

| 順番 | Marketの残高 | totalDeposits | alice |
|---|---|---|---|
| aliceがdeposit 100 | 100 | 100 | 100 |
| ほかのアカウントが直接送る50 | 150 | 100 | 100 |
| aliceがwithdrawAll | 50 | 0 | 200 |

Marketのコピーで`forge test --offline --match-contract "Yield55Test|DonationTest" -vv`（六つ通過）。コピー全体は44スイート140個（元の136 + Yield55の4）が通過する。

```
[PASS] test_depositSelectorDiffersFrom4626() (gas: 316)
[PASS] test_directTransferStaysAfterWithdrawAll() (gas: 280262)
[PASS] test_noBorrowSide() (gas: 165392)
[PASS] test_owedNeverAboveCash() (gas: 484816)
[PASS] test_rateIsSet() (gas: 13169)
[PASS] test_yearLaterSameAmount() (gas: 262027)
```

- test_rateIsSet：interestRate 5e16、interestFor(100e18, 5e16, 365日) = 5e18
- test_yearLaterSameAmount：借りる人なしで365日、withdraw 101 → `InsufficientDeposit(100, 101)`、withdrawAllのあとaliceは200のまま
- test_noBorrowSide：誰も借りなければtotalBorrows 0、borrowed 0
- test_interestFlowsToDepositor（`Borrow.t.sol`）：bobが1,000を預け、aliceが500を借りる（借りた比率50%、年3.125%）、1年後にaliceが515.625を返し、bobが1,015.625を引き出す

ローカルのanvilでMockTokenとMarket（interestRate 5e16、collateralRatio 80）をデプロイし、100を預けてから1年を進めた結果。lastUpdateの値は実行した時刻である。

```
MockToken 0x5FbDB2315678afecb367f032d93F642f64180aa3
Market    0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
$ cast call $MARKET "interestRate()(uint256)"
50000000000000000 [5e16]
$ cast rpc evm_increaseTime 31536000
$ cast call $MARKET "elapsedOf(address,address)(uint256)" $TOKEN $ME
31536000 [3.153e7]
$ cast call $MARKET "positions(address,address)(uint256,uint256,uint64,bool)" $TOKEN $ME
100
0
(lastUpdate)
false
$ cast call $MARKET "depositOf(address,address)(uint256)" $TOKEN $ME
100
$ cast call $MARKET "borrowRate(address)(uint256)" $TOKEN
0
$ cast call $MARKET "interestFor(uint256,uint256,uint256)(uint256)" 100 50000000000000000 31536000
5
$ cast send $MARKET "withdraw(address,uint256)" $TOKEN 101
… InsufficientDeposit(100, 101)
$ cast send $MARKET "withdraw(address,uint256)" $TOKEN 100
$ cast call $TOKEN "balanceOf(address)(uint256)" $ME
1000
```

Marketでトークンが入ってくる行はdeposit（177）・repay（426）・liquidate（447）、出ていく行はwithdraw（199）・borrow（416）である。預けた持ち分につく利息は、借りた人がrepayで入れるか、清算する側が代わりに入れるトークンだけである。

### 試すときの注意

- 受け取る側のウォレットでは、四つとも「預けたより多く受け取った」に見える。分ける問いは一つ、そのトークンを誰が入れたかである。
- FixedYield202は、金庫の残高（`token.balanceOf(address(this))`）で引き出せるかを見る。金庫にトークンが入ってくる行はdeposit一つだけである。
- MarketのRateは1e18倍率である（5e16 = 5%）。倍率は型ではなくコメントにだけ書かれている。interestRateは借りた比率が折れ曲がる点（80%）のときの利率で、実際の利率はborrowRateが借りた比率で決める。
- addAssetの2番目の引数は`Ratio`（uint8）なので、castのシグネチャは`addAsset(address,uint8)`と書く。
- Marketのコピーのテストは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガス記録の照合を切って実行する。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。パーセントはすべておもちゃの値で、実際の商品の利回りではない。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka | 2026-10-21 |
| テストの数 | Source202Test 5個通過 / Marketのコピー136個 + Yield55 4個 = 140個通過（44スイート） | 2026-10-21 |
| パーセント | 10%、0.3%、1日1%、5%はすべて講義用のおもちゃ・通しプロジェクトの値。実際のプロトコルの利回りは載せない | 2026-10-21 |
| anvilのデプロイのアドレス | MockToken `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Market `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 出どころごとに収益が出続けるかの判定 | [第203講](../../part13/lecture203/) |
| 利率が借りた比率によって変わる仕組み | [第197講](../../part13/lecture197/) |
| 手数料とインパーマネントロス | [第195講](../../part13/lecture195/) |
| 報酬を1トランザクションで借りて受け取る手口 | 扱わない |

出典と参考資料は[reference.md](reference.md)にまとめた。
