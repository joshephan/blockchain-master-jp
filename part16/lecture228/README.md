# 第228講 防御者の視点への転換

第16部 MEVサーチャー実習・第61章 攻撃者の道具

[← 第227講](../../part16/lecture227/) | [第16部 目次](../) | [第229講 →](../../part17/lecture229/)

## この講義の問い

自分の取引がすべて見えていて、順番を他人が決めるなら、ユーザーとプロトコルはそれぞれ何で線を引くのか。

## 実習資料

### 準備

プロジェクトを二つ使う。どちらもanvilなしでforgeのテストの中だけで動き、外部のチェーンには接続しない。

- `mev`：第225講の講義用のプールToyAmmとトークンに、受け取る最小量と締め切りの時刻を一緒に受け取るユーザー側の交換の入口`GuardedSwap`とそのテストを加えた。依存関係はforge-std 1.17.0、OpenZeppelin Contracts 5.4.0。
- `market264`：通しプロジェクトMarketのキャップストーン最終バージョンの写しである。srcは変えず、順番を入れ替えてみる確認テスト`test/Order228.t.sol`だけを加えた。依存関係はforge-std 1.17.0、OpenZeppelin Contracts 5.4.0。テストの土台（`test/helpers/Base.sol`）は、COL（18桁、担保比率75）・USD（6桁、80）の二つの資産、価格1.0、alice・bob・carol・daveがそれぞれCOL 1万・USD 1万で始める。

### コード

| ファイル | 内容 |
|---|---|
| [code/mev/foundry.toml](code/mev/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシード固定 |
| [code/mev/src/GuardedSwap.sol](code/mev/src/GuardedSwap.sol) | ユーザー側の交換の入口：締め切りの時刻が過ぎるとプールを呼ぶ前に`Expired(deadline, nowTs)`、受け取る最小量はプールが確認 |
| [code/mev/src/ToyAmm.sol](code/mev/src/ToyAmm.sol) | 講義用の定数積プール、`swap(tokenIn, amountIn, minOut)` → `Slippage(got, minOut)` |
| [code/mev/src/ToyErc20.sol](code/mev/src/ToyErc20.sol) | 講義用のトークン |
| [code/mev/test/Guard228.t.sol](code/mev/test/Guard228.t.sol) | Guard228Testの四つ：そのまま通る、受け取る最小量が止める、最小量0なら悪い値で約定、締め切りの時刻が過ぎた |
| [code/market264/foundry.toml](code/market264/foundry.toml) | Marketのキャップストーンバージョンの設定（solc 0.8.30、via-IR、osaka、ファズ・不変条件の設定） |
| [code/market264/src/](code/market264/src/) | Market.sol、IMarket.sol、MarketMath.sol、MarketTypes.sol（キャップストーン最終バージョンそのまま） |
| [code/market264/script/Deploy.s.sol](code/market264/script/Deploy.s.sol) | キャップストーンのデプロイスクリプト |
| [code/market264/test/Order228.t.sol](code/market264/test/Order228.t.sol) | この講義の確認テストの三つ：預け入れ・引き出しは順番と無関係、自分の前の大きな預け入れ、清算は勝った側だけが変わる |
| [code/market264/test/](code/market264/test/) | キャップストーンの残りのテストと`helpers/`（Base、Accounts、Handler、StdToken、TwapFeedなど） |

### 実行結果

`forge test --offline --match-contract Guard228Test -vv`：

```
Ran 4 tests for test/Guard228.t.sol:Guard228Test
[PASS] test_deadlinePassed() (gas: 57283)
[PASS] test_minOutStopsWorsePrice() (gas: 234373)
Logs:
  quote at send 90661089388014913158
  quote at run 54829920090148527874

[PASS] test_passesWhenNothingMoved() (gas: 167893)
Logs:
  quote 90661089388014913158
  minOut 90207783941074838592
  out 90661089388014913158

[PASS] test_zeroMinOutTakesWorsePrice() (gas: 251823)
Logs:
  quote at send 90661089388014913158
  out 54829920090148527874

Suite result: ok. 4 passed; 0 failed; 0 skipped
```

プール1000 / 1000、手数料0.3%、ユーザー（0xA11CE）A 100、ほかのユーザー（0xB0B）A 300。受け取る最小量は、送るときに見た受け取る量の99.5%である。

| テスト | 受け取る量 | 結果 |
|---|---|---|
| test_passesWhenNothingMoved | 90.661089388014913158 | 最小量90.207783941074838592、90.661をそのまま受け取る |
| test_minOutStopsWorsePrice | 54.829920090148527874（ほかのユーザーがA 300を先に） | `Slippage(54829920090148527874, 90207783941074838592)`でリバート |
| test_zeroMinOutTakesWorsePrice | 54.829920090148527874（同じ状況） | 最小量0、54.83で約定 |

`-vvvv`トレースの締め切りの時刻のテスト（締め切りの時刻 = 1 + 120秒 = 121、600秒後のblock.timestamp 601）：

```
[PASS] test_deadlinePassed() (gas: 57283)
    ├─ [0] VM::expectRevert(Expired(121, 601))
    │   └─ ← [Revert] Expired(121, 601)
```

`market264`で`forge test --offline --match-contract Order228Test -vv`：

```
Ran 3 tests for test/Order228.t.sol:Order228Test
[PASS] test_bigDepositBeforeMeChangesNothing() (gas: 340507)
Logs:
  alice usd 10000000000

[PASS] test_liquidationOrderPicksWinnerOnly() (gas: 1420180)
Logs:
  alice debt 350000000 350000000
  alice col 567647058823529411765 567647058823529411765
  winner col 432352941176470588235 432352941176470588235

[PASS] test_orderDoesNotMoveShares() (gas: 826443)
Logs:
  150000000 150000000
  70000000 70000000
  9850000000 9850000000
  9930000000 9930000000

Suite result: ok. 3 passed; 0 failed; 0 skipped
```

| 値 | aliceが先 | bobが先 |
|---|---|---|
| aliceが預けたUSD | 150 | 150 |
| bobが預けたUSD | 70 | 70 |
| aliceのUSD残高 | 9,850 | 9,850 |
| bobのUSD残高 | 9,930 | 9,930 |

清算のテストは、bobがUSD 1,000を預け、aliceがCOL 1,000を担保にUSD 700を借りたあと、COLの価格を0.85に下げ（30分後に平均に反映）、carolとdaveが同じポジションを清算する。

| 値 | carolが先 | daveが先 |
|---|---|---|
| 遅れた側 | dave `NotLiquidatable(386e18, 350e18)` | carol `NotLiquidatable(386e18, 350e18)` |
| aliceの借金 | USD 350 | USD 350 |
| aliceのCOL | 567.647058823529411765 | 567.647058823529411765 |
| 勝った側が受け取ったCOL | carol 432.352941176470588235 | dave 432.352941176470588235 |

`NotLiquidatable(limit, debt)`の二つの引数は、清算ライン386と借金350である。勝った側が受け取った432.35は、返済した値にボーナス5%を上乗せした担保（350 ÷ 0.85 × 1.05）である。キャップストーンのテスト全体（`forge test --offline`）は20スイート95個が通る（キャップストーン92 + Order228 3）。

### 試すときの注意

- 受け取る最小量と締め切りの時刻は、署名した取引のcalldataの中に入っている。待合室ですべて見えるが、誰も書き換えられない。画面やサーバーでだけ確かめた値は、ブロックの中では守られない。
- 前に入ってきた取引が挟み込もうとした取引でも普通の交換でも、自分の側の結果は受け取る最小量という同じ線で分かれる（90.208より上なら約定、下ならリバート）。最小量0なら、どんな値でも約定する。
- 締め切りの時刻が過ぎた交換は、プールを呼ぶ前にリバートし、トークンは動かない。
- 預け入れ・引き出しは、順番を入れ替えてもそれぞれの帳簿が同じである。順番に取り分がかかっていなければ、順番を買って持っていく取り分はない。
- 同じアカウントを狙った清算が二つあれば、前の取引が借金を減らしたあとの清算ラインで後ろの取引を計算し直す。このテストでは、前の清算で清算ラインの内側に戻り、遅れた側がリバートした。1回に借金の半分まで清算するバージョンなので、まだ清算ラインを超えていれば後ろの取引も成功する。借りた側の帳簿は誰が勝っても同じで、ボーナスを受け取る側だけが変わる。
- キャップストーンの設計文書`design/architecture.md` 6節 T-04：「順番：同じブロックの中の順番はブロックを作る側が決める。同じアカウントの清算が二つあれば、前の取引が借金を減らしたあとの清算ラインで後ろの取引を計算し直す（後ろの取引も清算ラインを超えていれば成功）」。7節の攻撃マップの順番操作の行：「順番操作 | 清算の競争、価格、利子の時刻 | 30分平均、同じブロックの中は指数そのまま | F-09」。
- `market264`は`.gas-snapshot`の確認を切って実行した（`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`）。スナップショットファイルは一緒に載せていない。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わるとガスが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizer runs 200、via-IR、evm osaka | 2026-10-21 |
| Marketのバージョン | キャップストーン最終バージョンの写し（srcそのまま） + 確認テストの三つ（`test/Order228.t.sol`） | 2026-10-21 |
| Marketのテスト数 | 20スイート95個が通る（キャップストーン92 + Order228 3） | 2026-10-21 |
| Guard228のガス | test_deadlinePassed 57,283 / test_minOutStopsWorsePrice 234,373 / test_passesWhenNothingMoved 167,893 / test_zeroMinOutTakesWorsePrice 251,823 | 2026-10-21 |
| Order228のガス | test_bigDepositBeforeMeChangesNothing 340,507 / test_liquidationOrderPicksWinnerOnly 1,420,180 / test_orderDoesNotMoveShares 826,443 | 2026-10-21 |
| 第225講の二つのほうの値 | feesのほうの最終残高 1050 / 952.517026、fifoのほう 1150 / 869.915904、アカウント1番の交換の手数料 56,982,293,309,376 wei | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 監査で順番操作の行を確かめる方法 | [第253講](../../part20/lecture253/)〜[第264講](../../part20/lecture264/) |
| 大きな交換を分けて送る連携 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| 公開のメンプールがないL2の順番 | [第233講](../../part17/lecture233/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
