# 第173講 オラクルの操作

第11部 推奨事項：敵対的環境とバージョン履歴・第45章 軸2・順序の操作

[← 第172講](../../part11/lecture172/) | [第11部 目次](../) | [第174講 →](../../part11/lecture174/)

## この講義の問い

今この瞬間の市場価格を読めば、それが真の値なのか。一つのブロックの中でその価格を揺らせるなら、その価格を信じる貸し出しはどうなるのか。値を時間をかけて平均すると何が変わるのか。

## 実習資料

### 準備

プロジェクトは二つある。`vulns`は講義用のトイプールと、そのプールを価格の出どころに使うトイのオラクル・貸し出しを置いた小さなプロジェクトで（本物のサービスではない）、`market`は通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）のsrcをそのまま置き、確認用テスト`test/Order45.t.sol`を足したものである。どちらもforge-stdが必要である（`lib/forge-std`）。anvilと外部への接続はない。スポット価格を揺らす再現テストは載せず、時間加重平均で直した側とその確認テストを載せる。

### コード

| ファイル | 内容 |
|---|---|
| [code/vulns/foundry.toml](code/vulns/foundry.toml) | solc 0.8.30、optimizerオン（200）・via-IRオン・evm osaka |
| [code/vulns/src/Mev172.sol](code/vulns/src/Mev172.sol) | ToyPool（積が一定の交換、手数料なし） |
| [code/vulns/src/Oracle173.sol](code/vulns/src/Oracle173.sol) | プールの残高の比をそのまま読むSpotOracle、累積値で平均を出すTwapOracle、スポット価格で担保を評価するToyLender |
| [code/vulns/src/Fixed173.sol](code/vulns/src/Fixed173.sol) | 直したバージョンのTwapLender。担保の価値を時間加重平均で評価し、窓がminWindowより短ければ値を出さない |
| [code/vulns/test/Fixed173.t.sol](code/vulns/test/Fixed173.t.sol) | 同じ揺さぶりに二つの貸し出しを並べるテスト、値が時間を耐えたときだけ平均が動くテスト、窓の長さのテスト。Fixed173Testの三つ |
| [code/vulns/test/Oracle173.t.sol](code/vulns/test/Oracle173.t.sol) | `test_twapResistsOneBlock`：一ブロックの揺さぶりに平均が1.0付近にとどまるか（スポット価格の再現テスト二つは除いた抜粋） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 価格を読む行がない。collateralRatio（120行）は管理者が上場のときに決めるパーセントの設定値 |
| [code/market/test/Order45.t.sol](code/market/test/Order45.t.sol)、[code/market/test/Donation.t.sol](code/market/test/Donation.t.sol) | Marketがトークンを帳簿で数えることの確認テスト |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/) | Marketのソースとテストすべて |

### 実行結果

トイプール（1000, 1000）のスポット価格は1.0で、同じブロックでB 3000を入れると16.0になる。そのスポット価格で担保A 100を評価すると、借りられるBが100から1600になる。

一ブロックの揺さぶりを受けた時間加重平均（`forge test --offline --match-contract Oracle173Test -vvv`の`test_twapResistsOneBlock`）。正常な区間1000秒のあと1秒だけ揺らした値は、平均にほとんど入らない：

```
[PASS] test_twapResistsOneBlock() (gas: 176570)
Logs:
  spotNow: 16000000000000000000
  twap: 1000000000000000000
```

直した貸し出しと並べた結果（`forge test --offline --match-contract Fixed173Test -vvv`から選んだ行）。同じブロック、同じ揺さぶりに、スポット価格の貸し出しは1600、平均価格の貸し出しは100を出す：

```
[PASS] test_twapLenderHoldsOnSameSwing() (gas: 176621)
Logs:
  spotLender: 1600
  twapLender: 100
[PASS] test_twapLenderNeedsWindow() (gas: 8626)
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

揺らした値16.0が100秒のあいだそのまま耐えると、平均に入って借りられる量が236になる：

```
[PASS] test_twapMovesOnlyWhenHeld() (gas: 199521)
Logs:
  twapLenderAfter100s: 236
```

`forge build --offline --force`のlintの警告のうち、直したバージョンの窓の長さの比較：

```
warning[block-timestamp]: usage of `block.timestamp` in a comparison may be manipulated by validators
   ╭▸ src/Fixed173.sol:28:13
   │
28 │         if (block.timestamp - startTimestamp < minWindow) revert WindowTooShort();
   │             ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Marketには価格を読む行がない（`grep -rniE "price|oracle|swap|reserve|getPrice|latestAnswer" src | wc -l`）：

```
0
```

帳簿で数えるMarket（`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract "Order45Test|DonationTest" -vvv`から選んだ行）。aliceが100を預け、誰かが50を直接送ってもtotalDepositsは100で、aliceが全部引き出したあとMarketには50が残る：

```
[PASS] test_directTransferStaysAfterWithdrawAll() (gas: 260125)
[PASS] test_depositWithdrawOneToOne() (gas: 219780)
Ran 2 test suites: 6 tests passed, 0 failed, 0 skipped (6 total tests)
```

### 試すときの注意

- 抜粋した`Oracle173.t.sol`はテスト関数が一つだけなので、同じ環境で`test_twapResistsOneBlock`のガスが176,570ではなく176,360と出る。
- TwapLenderは、窓の始まりをデプロイ時点一つに固定した最小の形である。窓をずらしていく部分はない。
- TWAPのテストの中の時刻は`vm.getBlockTimestamp()`で読む。`block.timestamp`をローカル変数に受けておくと、via-IRのビルドで値がずれる。
- ブロックの時刻は前のブロックより大きければよく、前後二つのブロックの時刻のあいだのどこかだということしか保証されない。そのため、lintは比較に使ったblock.timestampを警告する。
- 窓の長さ1000秒はトイの値である。実際のプロトコルの窓の長さはプロトコルごとに違う。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30。vulns・marketともにoptimizerオン（runs 200）・via-IRオン・evm osaka | 2026-10-21 |
| TWAPの窓の長さ | トイの値：test_twapResistsOneBlock 1001秒、TwapLender minWindow 1000秒。実際のプロトコルの窓の長さはプロトコルごとに違う | 2026-10-21 |
| ブロックの時刻 | 前のブロックより大きければよく、前後二つのブロックの時刻のあいだのどこかだということだけを保証。メインネットのブロック間隔と、ブロックを作る側が時刻を動かせる範囲は、版・合意ルールによって違う | 2026-10-21 |
| 事件の年 | bZx 2020、Mango Markets 2022 | 2026-10-21 |
| vulnsのテストのガス | test_twapResistsOneBlock 176,570、test_twapLenderHoldsOnSameSwing 176,621、test_twapLenderNeedsWindow 8,626、test_twapMovesOnlyWhenHeld 199,521 | 2026-10-21 |
| marketのテストのガス | test_depositWithdrawOneToOne 219,780、test_elapsedReadsBlockTimestamp 151,799、test_freezeBeforeWithdrawBlocks 208,491、test_withdrawBeforeFreezePasses 233,010、test_depositSelectorDiffersFrom4626 316、test_directTransferStaysAfterWithdrawAll 260,125 | 2026-10-21 |
| vulnsのlintの警告 | block-timestampの二つ（Oracle173.sol 44:13、Fixed173.sol 28:13）、weak-prngの一つ（Random175.sol 14:16） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| フラッシュローンで元手なしに揺らす攻撃 | [第174講](../../part11/lecture174/) |
| 複数のソースを集めるオラクルとTWAPの窓の長さの選び方 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| 金庫の最初の預け入れ・直接送ったトークンで持ち分を動かすこと | [第197講](../../part13/lecture197/) |
| 実際の事件の経緯 | [第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/) |
| 窓をずらしていくTWAPの実装（累積値のスナップショットの更新） | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| オラクル・清算を組み合わせた設計 | [第194講](../../part13/lecture194/)〜[第199講](../../part13/lecture199/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
