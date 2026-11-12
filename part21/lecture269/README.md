# 第269講 7つの層の分析

第21部 事件アーカイブと終章・第74章 分散化の実際のスペクトラム

[← 第268講](../../part21/lecture268/) | [第21部 目次](../) | [第270講 →](../../part21/lecture270/)

## この講義の問い

「分散」という言葉は、システムのどの部分を指して言う言葉なのか。コードを誰も直せず、自己監査が「いいえに近い」と答えたサービスは分散なのか。Marketを使う人は、実際に誰を信じているのか。

## 実習資料

### 準備

通しプロジェクトMarketのキャップストーンの最後のバージョン（第264講のバージョン、テスト92個）をコード・テストのまま使い、デモ用の法定通貨担保型トークン`FiatUSD`（FUSD）一つだけを`test/helpers/`に加えた。依存関係はforge-std（`lib/forge-std`）とOpenZeppelin Contracts（`lib/openzeppelin-contracts`、タイムロック）である。運用ツール`ops/market_read.py`・`ops/market_verify.py`はPythonの標準ライブラリだけを使う。

anvilのノード一つを`--hardfork osaka`（chain-id 31337）で立ち上げ、デプロイスクリプトどおりにタイムロック（admin）と2-of-3のマルチシグ（guardian）を立て、マルチシグ → タイムロックの予約 → 2日後の実行でCOL・USD・FUSDを上場する。ユーザー三人が預けて借りたあと、層ごとに確かめる：コード・アップグレードの層（コードのサイズ、EIP-1967のスロット、`upgradeToAndCall`）、管理者キーの層（席、しきい値、タイムロックの待機）、停止キー、価格の層（出どころが止まったあと）、トークンの層（発行者による凍結）、接続の層、チェーンの層。接続の層は、最初のノードをフォークしたノードをもう一つ立ち上げ、そのノードが開発用のコマンド`anvil_setStorageAt`で自分の状態の欄二つ（FUSDの預けた合計、FUSDの停止ビット）を変えたあと、二つのノードの答えを照らし合わせる。アカウントはanvilのデフォルトのテスト用アカウントである（署名者a・b・c = アカウント1・2・3、bob 4、alice 5、FUSDの発行者6、関係ないアカウント7、carol 9）。実際の資産には使わない。

テストはgas snapshotの検査を切って実行する（`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline`）。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシード固定、debugプロファイル |
| [code/src/Market.sol](code/src/Market.sol) | キャップストーンの最後のバージョンのMarket（アップグレードの道なし、admin・guardianの二つの席、listAssetで価格の出どころを一度決める） |
| [code/src/IMarket.sol](code/src/IMarket.sol) | Marketのインターフェース |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息・持ち分の計算ライブラリ |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | 型、構造体、IERC20・IPriceFeed |
| [code/script/Deploy.s.sol](code/script/Deploy.s.sol) | タイムロック・Marketのデプロイスクリプト |
| [code/test/Access.t.sol](code/test/Access.t.sol) | AccessTest（`test_A01`〜`test_A05`：キーで預けたお金を移せない、設定はタイムロックを待つ、guardianは停止だけ、解除はタイムロック、アップグレードの道なし） |
| [code/test/Safety.t.sol](code/test/Safety.t.sol) | SafetyTest（`test_S01_exitPathsNeverPaused`など） |
| [code/test/Trust.t.sol](code/test/Trust.t.sol) | TrustTest（`test_T01_feedStoppedRepayStillWorks`、`test_T01_twapLagsRealDrop`など） |
| [code/test/Rehearsal.t.sol](code/test/Rehearsal.t.sol) | RehearsalTest（`test_R02_*` 出どころの停止のあとに出ていく、`test_R03_preApprovedPauseOnlyOnce`） |
| [code/test/Deploy.t.sol](code/test/Deploy.t.sol) | DeployTest（`test_O03_deployLeavesNoDeployerRole`など） |
| [code/test/Standards.t.sol](code/test/Standards.t.sol) | StandardsTest（`test_contractWallet`、`test_delegatedEoaBatch`） |
| [code/test/](code/test/)の残り | キャップストーンのバージョンのテスト全体（Functional、Errors、Events、Findings、Fuzz、Invariant、Gas、Interface、Layout、Math、Ops、Rebuild、Docs） |
| [code/test/helpers/FiatUSD.sol](code/test/helpers/FiatUSD.sol) | デモ用の法定通貨担保型トークン。発行者のキー一つが発行・凍結（`setFrozen`）を受け持ち、準備金の欄はない |
| [code/test/helpers/TwapFeed.sol](code/test/helpers/TwapFeed.sol) | テスト用の価格の出どころ（誰でも`stop()`、権限の確認なし） |
| [code/test/helpers/StdToken.sol](code/test/helpers/StdToken.sol) | テスト用の標準トークン |
| [code/test/helpers/MultiSigAdmin.sol](code/test/helpers/MultiSigAdmin.sol) | テスト用のマルチシグ（しきい値、提案・承認・実行） |
| [code/test/helpers/](code/test/helpers/)の残り | テストの土台（Base、Accounts、Handler）と特殊なトークン（HookToken、OddTokens） |
| [code/abi/IMarket.json](code/abi/IMarket.json) | 運用ツールが読むMarketのABI |
| [code/deploy/check.py](code/deploy/check.py) | デプロイ後の確認六つ（デプロイ取引の入力、immutableの場所だけを隠したチェーンのコードの比較、immutableの値、メタデータハッシュなど）。読み取りのリクエストだけで、キーを受け取らない |
| [code/ops/market_read.py](code/ops/market_read.py) | 同じブロックハッシュで複数のRPCノードにMarketの値を尋ねて並べる（違えば終了コード1） |
| [code/ops/market_verify.py](code/ops/market_verify.py) | 信じるブロックハッシュで、アカウント・ストレージの欄の証明をステートルートまで当ててみて、ノードの答えと比べる |
| [code/ops/mpt.py](code/ops/mpt.py) | マークルパトリシアの証明の確認、keccak |
| [code/ops/abi.py](code/ops/abi.py) | ABIのJSONからセレクタ・トピック・エラーを数える |

### 実行結果

テスト（`forge test --offline --match-test "test_A0|test_S01|test_T01|test_R02|test_R03|test_O03_deployLeavesNoDeployerRole|test_contractWallet|test_delegatedEoaBatch" -vv`、そして全体）：

```
Ran 6 test suites: 14 tests passed, 0 failed, 0 skipped (14 total tests)
Ran 19 test suites: 92 tests passed, 0 failed, 0 skipped (92 total tests)
```

十四は、AccessTestの五つ（`test_A01_noKeyMovesDeposits`、`test_A02_configWaitsForTimelock`、`test_A03_guardianOnlyPauses`、`test_A04_unpauseNeedsTimelock`、`test_A05_noUpgradePath`）、SafetyTest `test_S01_exitPathsNeverPaused`、TrustTestの二つ（`test_T01_feedStoppedRepayStillWorks`、`test_T01_twapLagsRealDrop`）、RehearsalTestの三つ（`test_R02_feedStoppedDebtFreeExits`、`test_R02_feedStoppedBorrowerRepaysThenExits`、`test_R03_preApprovedPauseOnlyOnce`）、DeployTest `test_O03_deployLeavesNoDeployerRole`、StandardsTestの二つ（`test_contractWallet`、`test_delegatedEoaBatch`）である。

ここから下のanvilのデモの出力ブロックについて：出力は元の実行結果の文字列だけを訳したもの。デモを動かしたシェルはcode/に入れていないので、各行の前の説明（「==」の見出し、「〜を呼ぶ:」のような説明）はシェルが付けた見出しとして訳し、`ops/market_read.py`・`ops/market_verify.py`の行はこのコードのツールが出力する文言に合わせた。値・順番・空白は元のままである（ブロックハッシュ・stateRootはデプロイしたコードによって変わる）。

デプロイとユーザー：

```
マルチシグ 0x95bD8D42f30351685e96C62EDdc0d0613bf9a87A (署名者a・b・c = アカウント1・2・3、しきい値2)
タイムロック 0x5fbdb2315678afecb367f032d93f642f64180aa3, Market 0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
予約の時刻: getTimestamp = 1792714415 [1.792e9], 今のブロックの時刻 = 1792541619
事前に承認した停止の提案(a・b承認): COL 5, USD 6, FUSD 7
== ユーザー: bob(アカウント4)がUSD 1000を預け、alice(アカウント5)がCOL 1000を担保にUSD 700を借り、carol(アカウント9)がFUSD 100を預ける
totalDeposits USD 1000001748, COL 1000000000000000000000, FUSD 100000000 / alice debtOf USD 700001749
```

コード・アップグレードの層：

```
== コード・アップグレードの層
Market runtime bytes = 8921, タイムロック runtime bytes = 5450
EIP-1967 実装スロット = 0x0000000000000000000000000000000000000000000000000000000000000000
EIP-1967 管理者スロット = 0x0000000000000000000000000000000000000000000000000000000000000000
upgradeToAndCallを呼ぶ: Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

管理者キーの層（席としきい値、タイムロック）：

```
admin() = 0x5FbDB2315678afecb367f032d93F642f64180aa3 (タイムロック)
guardian() = 0x95bD8D42f30351685e96C62EDdc0d0613bf9a87A (マルチシグ)
タイムロック getMinDelay() = 172800 [1.728e5]
マルチシグ threshold() = 2, owners = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 0x90F79bf6EB2c4f870365E785982E1f101E93b906
デプロイしたアカウントのタイムロック管理者ロール = false, タイムロック自身 = true
署名者a一人でMarket.listAsset: NotAdmin(0x70997970c51812dc3a010c7d01b50e0d17dc79c8)
マルチシグ(a・b承認)がMarket.listAssetを直接: 提案0 CallFailed(0) / 内側の理由(eth_call from マルチシグ): NotAdmin(0x95bd8d42f30351685e96c62eddc0d0613bf9a87a)
タイムロックの予約を承認一つでexecute: 提案1 BelowThreshold(1, 1)
二つ目の承認のあとexecute: 成功(予約済み)
予約 "USD": 提案2 成功
予約 "FUSD": 提案3 成功
予約直後の実行(a・b承認): 提案4 CallFailed(4) / 内側の理由: TimelockUnexpectedOperationState(0x1546d047…32bf, 4)
2日後の実行: 提案8 成功
2日後の実行: 提案9 成功
2日後の実行: 提案10 成功
assetCount() = 3
```

停止キー（事前に承認した停止の提案を署名者一人が実行）：

```
署名者c一人でCOL停止の提案をexecute: 成功
assetConfig(COL) pausedBits = 3
同じ提案をもう一度execute(eth_call): AlreadyExecuted(5)
aliceがCOL 1をさらに預ける(eth_call): ActionPaused(0x98eddadcfde04dc22a0e62119617e74a6bc77313, 1)
aliceがUSD 1を返す(eth_call): 成功
bobがUSD 100を引き出す(eth_call): 成功
署名者a一人でunpause: NotAdmin(0x70997970c51812dc3a010c7d01b50e0d17dc79c8)
関係ないアカウント7がpause: NotGuardian(0x14dc79964da2c08b23698b3d3cc7ca32193d9955)
```

価格の層（前のバージョンの`setPriceFeed`はないので巻き戻り、価格の出どころが止まると価格を読む道だけが止まる）：

```
setPriceFeedを呼ぶ(前のバージョンの関数): Error: server returned an error response: error code 3: execution reverted, data: "0x"
== 価格の層: COLの価格の出どころが止まる(テスト用のTwapFeedは誰でもstop)
priceOf(COL) 前 = 1000000000000000000
アカウント7のstop()のあとのpriceOf(COL): Stopped()
aliceがUSD 1をさらに借りる(eth_call): Stopped()
aliceがCOL 1を引き出す(eth_call): Stopped()
aliceがUSD 1を返す(eth_call): 成功
bobがUSD 100を引き出す(eth_call): 成功
```

トークンの層（FUSDの発行者がMarketのアドレスを凍結）：

```
== トークンの層: FUSDの発行者(アカウント6)
関係ないアカウント7がsetFrozen(Market): NotIssuer(0x14dc79964da2c08b23698b3d3cc7ca32193d9955)
発行者がsetFrozen(Market, true) 成功
carolがFUSD 100を引き出す: AccountFrozen(0xe7f1725e7734ce288f8367e1bb143e90bb3f0512)
carol depositOf FUSD = 100000000, FUSD balanceOf(Market) = 100000000
タイムロックの席(eth_call from タイムロック)でsetFrozen(Market, false): NotIssuer(0x5fbdb2315678afecb367f032d93f642f64180aa3)
発行者がsetFrozen(Market, false)したあとcarolが引き出す(eth_call): 成功
```

接続の層。二つ目のノード（最初のノードをフォーク）が自分の状態の欄二つを変えたあとの比較：

| | 最初のノード | 二つ目のノード（最初のノードをフォーク） |
|---|---|---|
| 最初のブロック66番のハッシュ | 0x6df6…5620 | 0x6df6…5620 |
| 変えたあとのtotalDeposits(FUSD) | 100000000 | 50000000 |
| 変えたあとのlatestブロック・ハッシュ | 66、0x6df6…5620 | 66、0x6df6…5620 |
| 変えたあとのstateRoot | 0x50f8…8ed9 | 0x50f8…8ed9 |
| carolがFUSD 1を預ける試し実行 | 成功 | ActionPaused(FUSD, 1) |

`ops/market_read.py`で同じブロックハッシュを二つのノードに尋ねた結果：

```
基準ブロック: latest 66 0x6df637ab182461360dcd437be4c0c302bb20b2cfa7683b52d30f7dc039c75620 (RPC 1が教えたもの)
RPC                         assetCount              totalDeposits           totalBorrows            priceOf
http://127.0.0.1:9269       3                       100000000               0                       1000000000000000000
http://127.0.0.1:9270       3                       50000000                0                       1000000000000000000
違い: totalDeposits -> ['100000000', '50000000']
結果: ずれあり
(終了コード 1)
```

`ops/market_verify.py`で最初のノードのブロックハッシュを信じ、二つのノードの答えを証明に当てた結果：

```
--- ops/market_verify.py 9269, 信じるハッシュ = 9269 latest 0x6df637ab182461360dcd437be4c0c302bb20b2cfa7683b52d30f7dc039c75620
1) ブロックヘッダーのハッシュ: 同じ (ブロック 66、ステートルート 0x50f872380349…)
2) 証明: ステートルートまでつながる (アカウントノード 2個、ストレージスロットのノード 2個)
3) scaledDeposits(reserves[資産] +0): 証明の値 100000000、eth_getStorageAtの答え 100000000 -> 同じ
結果: 確認済み
(終了コード 0)
--- ops/market_verify.py 9270, 信じるハッシュ = 9269 latest 0x6df637ab182461360dcd437be4c0c302bb20b2cfa7683b52d30f7dc039c75620
1) ブロックヘッダーのハッシュ: 同じ (ブロック 66、ステートルート 0x50f872380349…)
2) 証明: ステートルートまでつながる (アカウントノード 2個、ストレージスロットのノード 2個)
3) scaledDeposits(reserves[資産] +0): 証明の値 100000000、eth_getStorageAtの答え 50000000 -> 違う
結果: ずれ
(終了コード 1)
```

チェーンの層：

```
== チェーンの層
chain-id 31337, block 66
miner(最近のブロック) = 0x0000000000000000000000000000000000000000
anvil_nodeInfo hardFork = Osaka
```

### 試すときの注意

- コードの層は空である。アップグレードの道がなく（`test_A05_noUpgradePath`、EIP-1967の二つのスロットが0、`upgradeToAndCall`は巻き戻し）、署名者一人やマルチシグが直接呼ぶと`NotAdmin`である。設定は、マルチシグ → タイムロックの予約 → 2日（172,800秒）後の実行でだけ変わる。
- 停止は、事前に承認しておいた提案を署名者一人が実行してすぐにかける。一度使えば終わりなので（`AlreadyExecuted(5)`）、止めたあとに同じ提案を作り直して承認しておく。止めても返済・引き出しは開いている。
- 価格の出どころは`listAsset`の1回でトークンと一緒に決まる。出どころが止まると、価格を読む借り入れ・担保の引き出しだけが`Stopped()`で止まり、返済と借金のない引き出しはできる。
- FUSDの発行者がMarketのアドレスを凍結すると、Marketの帳簿（carol 100）と残高（100）がそのままでも引き出せず、Marketのタイムロックも解除できない（`NotIssuer`）。
- ノードは、ブロック番号・ハッシュ・stateRootをそのまま返しながら、違う状態の値を答えられる。ほかのノードと比べるか（`market_read.py`）、信じるブロックハッシュの証明に当ててみれば（`market_verify.py`）、ずれが見える。証明に当てる道にも、そのブロックハッシュをどこから受け取ったかが信頼として残る。
- ブロックハッシュ、stateRoot、タイムロックの作業id、利息の端数、予約の時刻は実行ごとに違う。テスト用の価格の出どころ（`TwapFeed`）とテスト用のトークン（`StdToken`）は、権限の確認がないテスト用である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| ツール | Foundry（forge・cast・anvil）1.8.3、solc 0.8.30（`--offline`）、Pythonの標準ライブラリ | 2026-10-21 |
| ローカルのチェーン | anvil一つ（`--hardfork osaka`、chain-id 31337、ブロックヘッダーのminer 0）、そのノードをフォークしたanvil一つ（`--fork-url`） | 2026-10-21 |
| 基準のバージョン | キャップストーンの最後のバージョン（テスト92、Market runtime 8,921 / creation 9,252、末尾のメタデータハッシュの先頭4バイトd551e83c） | 2026-10-21 |
| デモのアドレス | マルチシグ0x95bD8D42f30351685e96C62EDdc0d0613bf9a87A、COL 0x98eDDadCfde04dC22a0e62119617e74a6Bc77313、USD 0x2B574555158337Cd46d47c2Ca57E4698A1f04e70、価格の出どころCOL 0xcA8b49076D1A8039599e24979abf819af784c27a・USD 0xc039b3B46814D8388e5205D37Dd0D154D806F1f4・FUSD 0x2B15063A6F8a11d18404C801F295b1d19dCC8574、FUSD 0x7ef8E99980Da5bcEDcF7C10f41E55f759F6A174B、タイムロック0x5FbDB2315678afecb367f032d93F642f64180aa3、Market 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 | 2026-10-21 |
| 実行ごとに変わる値 | ブロック66番のハッシュ（今回の実行0x6df6…5620）、stateRoot（0x50f8…8ed9）、タイムロックの作業id（0x1546d047…32bf）、利息の端数（totalDeposits USD 1000001748、alice debtOf USD 700001749） | 2026-10-21 |
| テスト用の代役 | テスト用の価格の出どころ（TwapFeed）・トークン（StdToken）は権限の確認なし。FUSD（FiatUSD）はこの講義で加えたデモ用のトークン | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 層ごとの決定権の表を数字に（層ごとに何人が集まれば動くか） | [第270講](../../part21/lecture270/) |
| 実際のRPC・フロントエンド・ウォレット業者の選び方 | 扱わない（付録のデータだけ） |
| 実際の価格の出どころの運営者の選び方、複数の出どころの合成 | オラクルの統合の章（前で扱った）、付録 |
| MarketをL2にデプロイするときのチェーンの層（シーケンサー） | 1行まで、デプロイするチェーンの選び方は付録 |
| 事前に承認した停止の提案を使ったあとに承認し直す運用 | [第264講](../../part20/lecture264/)（前で扱った） |
| [第3講](../../part1/lecture3/)の判別フィルターをシステム全体の層ごとに | この講義（[第3講](../../part1/lecture3/)・[第92講](../../part6/lecture92/)・[第166講](../../part11/lecture166/)・[第179講](../../part11/lecture179/)の先送りにしたテーマの答え） |
| アップグレードキーを複数の署名・時間の遅れ・ガバナンスで束ねること | この講義（[第164講](../../part10/lecture164/)の先送りにしたテーマの答え） |
| ガバナンスの層の分析 | この講義（[第180講](../../part11/lecture180/)・[第215講](../../part14/lecture215/)・[第216講](../../part14/lecture216/)の先送りにしたテーマの答え）、[第271講](../../part21/lecture271/) |
| クロスチェーンの五つの席を層ごとに見直す | この講義（[第212講](../../part14/lecture212/)の先送りにしたテーマの答え） |
| 体系全体で信じるところを層ごとに書く、キャップストーンのバージョンの層ごとの信頼の表 | この講義（[第237講](../../part18/lecture237/)・[第264講](../../part20/lecture264/)の先送りにしたテーマの答え） |
| 事件の表の欄と7つの層の突き合わせ | この講義（[第268講](../../part21/lecture268/)の先送りにしたテーマの答え） |
| 代理人に票が集まる度合い、署名者の機器と交代の手順 | [第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
