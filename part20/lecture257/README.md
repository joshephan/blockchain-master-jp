# 第257講 権限構造の設計

第20部 キャップストーンプロジェクト・第70章 設計と実装

[← 第256講](../../part20/lecture256/) | [第20部 目次](../) | [第258講 →](../../part20/lecture258/)

## この講義の問い

管理者一人がしていた仕事を、どう分けるのか。待ち時間は誰に何を与え、何を遅らせるのか。キーごとに奪われたときにできることを書くと、反証の項目の答えは変わるのか。

## 実習資料

### 準備

第256講のバージョン（標準の統合のバージョン）から続ける。このバージョンが第70章末のバージョンである。管理者の席一つを、できることで二つに分けた。設定キー（listAsset、setSupplyCap、setGuardian、unpause、そしてpause）はOpenZeppelinの`TimelockController`（最小待機2日）が握り、停止キー（pause一つ）はマルチシグ（署名者三人のうち二人）が握る。設定キーの席`admin`はimmutableで、変える関数がない。停止キーの席`guardian`は保存スロット4にあり、設定キーだけが変える。

依存関係はforge-std 1.17.0（`lib/forge-std`）とOpenZeppelin Contracts 5.4.0（`lib/openzeppelin-contracts`）である。テストは`governance/TimelockController.sol`を使い、テスト用のマルチシグは`test/helpers/MultiSigAdmin.sol`である。

anvilのデモは、0番アカウントがテスト用トークン二つ、価格の出どころ二つ、マルチシグ、タイムロック、Marketを順にデプロイし、castだけで動かした。デプロイの形：マルチシグ（署名者a・b・c、しきい値二人） → TimelockController（最小待機2日、提案・取り消し・実行のロール = マルチシグ、管理者ロール = タイムロック自身、コンストラクターのadmin引数0） → Market（admin = タイムロック、guardian = マルチシグ）。

設計ドキュメントは1節（キーを握るアカウント）、2節（スロット4 guardian）、3節（権限リストとデプロイの形）、7節（中央の地点）、8節（キーの表）、決定記録D-13を直した。`design/requirements.md`の判別フィルターの判定の行はまだ直していない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、via-IR、remapping 2行、自動検出オフ |
| [code/design/architecture.md](code/design/architecture.md) | 設計ドキュメント（3節の権限リスト・デプロイの形、8節のキーの表、D-13） |
| [code/design/requirements.md](code/design/requirements.md) | 要件 |
| [code/src/Market.sol](code/src/Market.sol) | 権限のバージョンのMarket：設定キー`admin`（immutable）、停止キー`guardian`、資産ごとの預け入れ・借り入れの停止ビット、`setGuardian` |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束（セレクタ38、イベント11、エラー22、インターフェースID 0x7edbb9ad） |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol)、[MarketMath](code/src/MarketMath.sol) | 型、計算の部品 |
| [code/test/Access.t.sol](code/test/Access.t.sol) | 権限の要件のテストA-01〜A-05（TimelockControllerとマルチシグでデプロイの形をそのまま立てる） |
| [code/test/helpers/MultiSigAdmin.sol](code/test/helpers/MultiSigAdmin.sol) | テスト用のマルチシグ（提案・承認・実行、しきい値、事前に承認した提案は1回だけ） |
| [code/test/Layout.t.sol](code/test/Layout.t.sol)、[Interface](code/test/Interface.t.sol) | スロットの地図（スロット4 guardian）、インターフェースID |
| [code/test/](code/test/)の残り | Functional、Safety、Standards、Ops、Gas、Mathのテストとhelpers（Base、StdToken、TwapFeed、HookToken、OddTokens、Accounts） |

### 実行結果

`forge test --offline --match-contract "AccessTest|InterfaceTest|LayoutTest" -vv`：

```
Ran 1 test for test/Interface.t.sol:InterfaceTest
[PASS] test_interfaceId() (gas: 121)
Ran 1 test for test/Layout.t.sol:LayoutTest
[PASS] test_slotMap() (gas: 20404)
Ran 5 tests for test/Access.t.sol:AccessTest
[PASS] test_A01_noKeyMovesDeposits() (gas: 5431393)
[PASS] test_A02_configWaitsForTimelock() (gas: 2455138)
[PASS] test_A03_guardianOnlyPauses() (gas: 639804)
[PASS] test_A04_unpauseNeedsTimelock() (gas: 2400254)
[PASS] test_A05_noUpgradePath() (gas: 2203576)
7 tests passed, 0 failed, 0 skipped (7 total tests)
```

全体の`forge test --offline`は38通過、0失敗、0スキップである。第253講で中身なしで始めた要件テスト25個がすべて埋まった。

| バージョン | テスト（通過 / スキップ） | Market runtime / creation |
|---|---|---|
| 要件（第253講） | 2 / 25 | なし |
| 設計（第254講） | 6 / 25 | なし |
| コアロジック（第255講） | 26 / 7 | 8,232 / 8,423 |
| 標準の統合（第256講） | 34 / 4 | 8,470 / 8,661 |
| 権限（第257講） | 38 / 0 | 8,739 / 9,070 |

anvilのデモ（新しいanvil、0番アカウントがデプロイ、castで実行）の出力。`##`の見出しと値の前の説明は、castの呼び出しをまとめたシェルが出力した見出し（シェルはcode/に入れていない）である：

```
## 席の読み取り
admin() 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
guardian() 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
スロット4 0x000000000000000000000000dc64a140aa3e981100a9beca4e685f962f0cf6c9
タイムロックの管理者ロール: デプロイしたアカウント false, タイムロック自身 true, マルチシグ false
提案ロール: マルチシグ true, デプロイしたアカウント false
最小待機 172800 [1.728e5]
## マルチシグがMarketを直接呼ぶと
  listAsset: NotAdmin(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9)
## タイムロックに載せる (資産二つ)
  提案0 実行 status 0x1 ブロック12
  提案1 実行 status 0x1 ブロック16
  CallScheduledログ(誰でも読める):
    ブロック12 作業id 0x054462e28f4a1b5a7a7aecd77a63a244fe43bc554cadc6315ca74be1ef39bde1
    ブロック16 作業id 0xcec8026b756af5e539ebb9472755917d34fdd85231776d2b4759226d3da46e0f
  2日前に実行してみる(タイムロックを直接シミュレーション): TimelockUnexpectedOperationState(0x054462e28f4a1b5a7a7aecd77a63a244fe43bc554cadc6315ca74be1ef39bde1, 0x0000000000000000000000000000000000000000000000000000000000000004)
  提案2 実行 status 0x1 ブロック21
  提案3 実行 status 0x1 ブロック25
  assetCount 2
## bobの預け入れ
  deposit 1000 status 0x1 gasUsed 134386
## 事前に承認した停止の提案(署名者c一人で実行)
  提案4 承認数 2
  c一人でexecute(4) status 0x1 ブロック32 gasUsed 73552
  assetConfig(USD) pausedBits 3
  bob deposit: ActionPaused(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, 1)
  bob withdraw 400 status 0x1
  c一人で新しい提案(再開):
    executeシミュレーション: BelowThreshold(5, 1)
  マルチシグが直接unpause: NotAdmin(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9)
  知らないアカウントがpause: NotGuardian(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65)
```

予約した作業の実行可能な時刻は、予約したブロックの時刻 + 172,800秒である。時刻の値はanvilの時計に従うので、実行するたびに違う。

### 試すときの注意

- 遅れてもよい仕事（資産の追加、上限の変更、再開）はタイムロックに、遅れてはいけない仕事（停止）はマルチシグに置く。予約は`CallScheduled`ログで誰でも読めるので、預けた人は待機の2日のあいだに引き出して出ていける。
- 停止は預け入れ・借り入れだけを止める。引き出し・返済・清算・借金の消去・担保のオフは停止に関係なくできる（S-01）。上のデモでも、停止したあとのbobのwithdraw 400は成功する。
- 資産ごとの停止の提案は事前に承認しておき、署名者一人が実行する。事前に承認した提案は一度使えば終わりで、再開する提案は事前に承認しない。
- タイムロックのコンストラクターのadmin引数を0にして、デプロイしたアカウントがデプロイ後に何のロールも持たないようにする。タイムロックの待機時間（`updateDelay`）もタイムロック自身だけが変える。
- 三つのキーが同じ場所にあれば、しきい値がないのと同じである。署名者は互いに違う人・機器にする。
- タイムロックの最小待機2日とマルチシグの三人のうち二人は講義用の値である。

## 時効性のあるデータ

基準日時点の値。ツール・ライブラリのバージョンとコードが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry・solc | forge・anvil・cast 1.8.3（commit cae51ad4）、solc 0.8.30 | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0、TimelockController 116〜136行・updateDelay 448〜455行 | 2026-10-21 |
| 講義用の設計値 | タイムロックの最小待機2日（172,800秒）、マルチシグ三人のうち二人 | 2026-10-21 |
| anvilのデモ | アドレスCOL `0x5FbD…0aa3`・USD `0xe7f1…0512`・価格の出どころ`0x9fE4…a6e0`・`0xCf7E…0Fc9`・マルチシグ`0xDc64…6C9`・タイムロック`0x5FC8…5707`・Market `0x0165…Eb8F`、予約ブロック12・16、実行ブロック21・25、bob deposit gasUsed 134,386、事前に承認した停止はブロック32 gasUsed 73,552、最後のブロック35 | 2026-10-21 |
| 権限のバージョン | テスト38 / 0 / 38、runtime 8,739 / creation 9,070、メタデータハッシュの先頭4バイト`ef24c031`、セレクタ38・イベント11・エラー22、インターフェースID `0x7edbb9ad` | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 署名者の装置と署名者の交代の手順 | 付録 |
| タイムロックの待機時間の選び方（実在する値の比較） | 扱わない（時効性） |
| デプロイスクリプトでこの順番を自動に | [第262講](../../part20/lecture262/) |
| 事故のときに停止をかける練習 | [第264講](../../part20/lecture264/) |
| ガバナンスの投票で設定キーを置く設計 | 扱わない（N-03） |
| requirements.mdの判別フィルターの判定の行の書き直し | [第260講](../../part20/lecture260/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
