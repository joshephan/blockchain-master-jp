# 第264講 インシデント対応のリハーサル

第20部 キャップストーンプロジェクト・第72章 デプロイと運用

[← 第263講](../../part20/lecture263/) | [第20部 目次](../) | [第265講 →](../../part21/lecture265/)

## この講義の問い

事故が起きたとき、最初の30分に誰が何をするのか。デプロイしたコードを変えられないマーケットで、事故のあとに直せるものは何か。

## 実習資料

### 準備

通しプロジェクトMarketの第263講のバージョン（監視のバージョン）から始める。この講義のバージョンが第72章末のバージョンであり、キャップストーンの最後のバージョンである。デプロイしたビルド（`d551e83c`）とsrcは変えない。事故記録の様式`ops/incident_template.md`をキャップストーンのバージョンに直し、リハーサルの記録`incidents/rehearsal-01.md`、リハーサルから出たテスト`test/Rehearsal.t.sol`（RehearsalTest 6）を加え、監視の価格のHIGHの文言（`ops/monitor.py`）と設計ドキュメント・既知の問題K-07を直す。

リハーサルは、実際のデプロイスクリプト（`script/Deploy.s.sol`）と実際の監視（`ops/monitor.py`）で、ローカルのanvil（チェーン番号31337）で行った。事故は二つで、どちらも攻撃ではない。価格の出どころの運営者（anvilの7番アカウント）が0を書いた事故と、価格の出どころが止まった事故である。ユーザーはalice（COL 1000を担保、借金700）、carol（清算する側、試し呼びだけ）、dave（9番アカウント、COL 500を担保、借金なし）で、マルチシグの署名者a・b・cはアカウント1・2・3番である。キーはすべてanvilのデフォルトのテスト用キーである。警報を受ける側は、受け取った行を書き留めるだけのローカルのプログラムである。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、`fs_permissions`、debugプロファイル、`[fuzz]`・`[invariant]`の設定 |
| [code/abi/IMarket.json](code/abi/IMarket.json) | リポジトリに置いたABIファイル。ciの7段階目がビルドとdiff、運用ツールがセレクタ・トピック・エラーをここから数える |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束（ABI）：関数・イベント・エラー（ZeroPriceを含む）とNatSpec |
| [code/src/Market.sol](code/src/Market.sol) | レンディングマーケットの本体（直したビルド`d551e83c`） |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息の曲線・丸めの計算ライブラリ |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | 共有する型、価格の出どころのインターフェース |
| [code/script/Deploy.s.sol](code/script/Deploy.s.sol) | デプロイスクリプト：タイムロック → Market、デプロイするアカウントはロールを受け取らない |
| [code/deploy/check.py](code/deploy/check.py) | デプロイ後の確認（サイズ、メタデータハッシュ、コードハッシュ、sources、コンストラクター引数）。読み取りのリクエストだけ |
| [code/ops/abi.py](code/ops/abi.py) | 運用ツールが共有するABIの表（abi/IMarket.jsonからセレクタ・トピック・エラーを数える）、`--check` |
| [code/ops/incident_template.md](code/ops/incident_template.md) | 事故記録の様式（キャップストーンのバージョン）：0節 最初の30分の順番、1節 冒頭と役割、2節 等級の基準、3節 タイムライン〜7節 事後報告 |
| [code/ops/indexer.py](code/ops/indexer.py) | Market・タイムロックのログで帳簿を立て直すインデクサー |
| [code/ops/loop.py](code/ops/loop.py) | 監視を決めた間隔で回し続け、周回ごとに終了コードとかかった時間を書く |
| [code/ops/market_read.py](code/ops/market_read.py) | 複数のRPCに同じブロックハッシュでMarketの状態を尋ねて並べる |
| [code/ops/market_verify.py](code/ops/market_verify.py) | RPC一つがくれた帳簿の値を、ブロックハッシュ一つに当てて証明で確認 |
| [code/ops/monitor.py](code/ops/monitor.py) | 不変条件の監視。価格のHIGHの文言を、リハーサルの結果（出どころが止まったときにできる道）に直した |
| [code/ops/mpt.py](code/ops/mpt.py) | keccak-256、RLP、ブロックヘッダーのハッシュ、マークルパトリシアトライの証明の確認の部品 |
| [code/ops/sendq.py](code/ops/sendq.py) | 運用アカウント一つの送信キュー（ナンスをこのキュー一つだけが付ける） |
| [code/ops/timeline.py](code/ops/timeline.py) | 事故のタイムライン（取引と警報をブロック順に） |
| [code/incidents/rehearsal-01.md](code/incidents/rehearsal-01.md) | リハーサルの記録：タイムライン、したこととその取引、お知らせ、事後報告、出てきたもの四つ（R-01〜R-04） |
| [code/test/Access.t.sol](code/test/Access.t.sol) | 権限の要件A-01〜A-05 |
| [code/test/Deploy.t.sol](code/test/Deploy.t.sol) | デプロイスクリプトのdeploy・checkをそのまま呼ぶDeployTest 5 |
| [code/test/Docs.t.sol](code/test/Docs.t.sol) | ABIの項目ごとにnoticeがあるか |
| [code/test/Errors.t.sol](code/test/Errors.t.sol) | エラー23ごとに、そのエラーで巻き戻るテスト一つ（巻き戻しデータ全体） |
| [code/test/Events.t.sol](code/test/Events.t.sol) | イベント11の引数すべて |
| [code/test/Findings.t.sol](code/test/Findings.t.sol) | 自己監査の指摘事項の確認テスト五つ |
| [code/test/Functional.t.sol](code/test/Functional.t.sol) | 機能要件F-01〜F-10 |
| [code/test/Fuzz.t.sol](code/test/Fuzz.t.sol) | ファズテスト五つ |
| [code/test/Gas.t.sol](code/test/Gas.t.sol) | 測った呼び出し五つのガス |
| [code/test/Interface.t.sol](code/test/Interface.t.sol) | 関数の数とインターフェースID |
| [code/test/Invariant.t.sol](code/test/Invariant.t.sol) | 不変条件テスト（I-1〜I-5、一覧にない失敗0） |
| [code/test/Layout.t.sol](code/test/Layout.t.sol) | ストレージの欄の地図どおりに置かれているか |
| [code/test/Math.t.sol](code/test/Math.t.sol) | 計算の部品の曲線の値と丸めの方向 |
| [code/test/Ops.t.sol](code/test/Ops.t.sol) | 運用の要件O-01〜O-02 |
| [code/test/Rebuild.t.sol](code/test/Rebuild.t.sol) | ログだけで数え直した合計と状態の比較 |
| [code/test/Rehearsal.t.sol](code/test/Rehearsal.t.sol) | リハーサルから出たRehearsalTest 6（R-01 三つ、R-02 二つ、R-03 一つ） |
| [code/test/Safety.t.sol](code/test/Safety.t.sol) | 安全の要件S-01〜S-08 |
| [code/test/Standards.t.sol](code/test/Standards.t.sol) | 標準の対照表の行ごとの確認 |
| [code/test/Trust.t.sol](code/test/Trust.t.sol) | 信頼の前提のテスト（T-01 出どころの停止・平均の遅れ、T-03 同じブロック） |
| [code/test/helpers/Accounts.sol](code/test/helpers/Accounts.sol) | テスト用のアカウントのコード二つ |
| [code/test/helpers/Base.sol](code/test/helpers/Base.sol) | テスト共用の土台（COL・USD、価格の出どころ二つ、前のバージョンと同じ場面） |
| [code/test/helpers/Handler.sol](code/test/helpers/Handler.sol) | 不変条件のハンドラー（価格0〜2.0、正常な失敗の一覧） |
| [code/test/helpers/HookToken.sol](code/test/helpers/HookToken.sol) | 移される瞬間にMarketの帳簿を読んで書き留めるテスト用トークン |
| [code/test/helpers/MultiSigAdmin.sol](code/test/helpers/MultiSigAdmin.sol) | テスト用のマルチシグ |
| [code/test/helpers/OddTokens.sol](code/test/helpers/OddTokens.sol) | 標準と違う動きをするテスト用トークン（手数料トークンなど） |
| [code/test/helpers/StdToken.sol](code/test/helpers/StdToken.sol) | テスト用の標準トークン |
| [code/test/helpers/TwapFeed.sol](code/test/helpers/TwapFeed.sol) | テスト用の価格の出どころ（積み上がった価格の合計、`stop()`、権限のない`setPrice`） |

### 実行結果

リハーサルの出力ブロック（下の四つ）について：出力は元の実行結果の文字列だけを訳したもの。リハーサルを動かしたシェルはcode/に入れていないので、`[出どころ0]`のような角かっこの見出し、「---」の行、「決める人」の行はシェルとデモで付けた見出しとして訳し、監視の行はこのコードの`ops/monitor.py`が出力する文言に合わせた。値・順番・空白は元のままである（ブロックハッシュ・取引ハッシュはデプロイしたコードによって変わる）。

練習の事故1：価格の出どころがCOL 0を書く（ふだんのブロック48は、aliceの借金700 / 清算ライン800、0.875）：

```
[出どころ0] ブロック49 tx 0x5ae8f79bef58b54bf058ee49ca79d7ed28fb3296307a159491e7bd612007e5f9
--- 監視の周回: 12秒後
周回 2 | 最新 50、確認したブロック 50 0x283e13f8
  アカウント 0x9965507d 借金の値 700.00 清算ライン 794.67 (0.881)
  [HIGH] 資産 0x98eddadc 直近1分平均 0.8000、30分平均 0.9933 (差 -19.5%、平均が追いついている途中)
  対応の候補: 資産 0x98eDDadC 事前に承認しておいた停止の提案 2(マルチシグ 0x95bD8D42)。署名者一人が execute(2) = 0xfe0d94c1…0002
決める人(署名者a): 2等級。COLの預け入れ・借り入れを停止(事前に承認した提案)、出どころの運営者を呼ぶ。清算は停止では止められない(S-01)
  [停止を実行(署名者c一人)] ブロック51 tx 0x85e3c963a7ee57aaf102a5935d5e113f959318736c50b24f8c47ad7e58c6fcf7
```

停止したあと：

```
新しく預けるCOL: ActionPaused(address,uint8)
周回 3 | 最新 52、確認したブロック 52 0x201502b4
  アカウント 0x9965507d 借金の値 700.00 清算ライン 767.56 (0.912)
  [INFO] 資産 0x98eddadc 停止ビット 0 -> 3 (1は預け入れ、2は借り入れ)
```

停止は新しい預け入れと新しい借り入れだけを止め、引き出し、返済、清算、借金の消去、担保のオフはそのままにする（S-01）。分ごとの平均と清算ライン（aliceの借金700）：

| 時点 | COLの30分平均 | 清算ライン | 借金の値 / 清算ライン |
|---|---|---|---|
| ブロック48 ふだん | 1.000000 | 800.00 | 0.875 |
| ブロック50、12秒 | 0.993333 | 794.67 | 0.881 |
| ブロック52、1分12秒 | 0.959444 | 767.56 | 0.912 |
| ブロック54、181秒（出どころを1.0に直す） | 0.899444 | 719.56 | 0.973（INFO 清算ラインが近い） |
| ブロック57、直して40分後 | 1.000000 | 800.00 | 0.875（解消） |

carolの清算の試し呼びはずっと`NotLiquidatable`だった。同じ停止の提案をもう一度実行すると（eth_call）`AlreadyExecuted(uint256)`なので、新しい停止の提案7（`pause(COL, 3)`）を作り、署名者a・bが承認しておいた。再開はタイムロックの2日である。unpauseの作業idを予定ファイルに書いておいたので、INFOで出る：

```
[再開の予約] ブロック61 tx 0x9ad84f1b194442125a30089c509ae4eeaeea877f9bc33baf4e16706338ec0704
周回 8 | 最新 61、確認したブロック 61 0x5a775f7d
  [INFO] タイムロックの予約 unpause (作業 0xec8ec5d7、ブロック 61、実行可能まで 172800 秒)
[再開の実行] ブロック69 tx 0xa97ccd0982fc529dee2e2f1b4e3c67eb704a49303cf49f71911c5aa021a9b2e0
周回 9 | 最新 69、確認したブロック 69 0x86856b90
  [INFO] タイムロックの作業 0xec8ec5d7 実行 (unpause)
  [INFO] 資産 0x98eddadc 停止ビット 3 -> 0 (1は預け入れ、2は借り入れ)
```

練習の事故2：価格の出どころが止まる：

```
[出どころの停止] ブロック70 tx 0x59eecb5aa16c8c34e34902c1f060d64b377dad25baae0175e9cd2ba9f69520a8
周回 10 | 最新 71、確認したブロック 71 0xb03ce165
  [HIGH] 資産 0x98eddadc 価格の読み取りがリバート Stopped(): その資産を担保にしたアカウントの借り入れ・一部の引き出し・清算・借金の消去が停止。借金がなければ全部の引き出し・担保のオフはできる(T-01)
  対応の候補: 資産 0x98eDDadC 事前に承認しておいた停止の提案 7(マルチシグ 0x95bD8D42)。署名者一人が execute(7) = 0xfe0d94c1…0007
  priceOf(COL): Stopped()
  daveの一部の引き出し100: Stopped()
  daveの全部の引き出し: 成功
  aliceの全部の引き出し(借金あり): InsufficientCollateral(uint256,uint256)
  aliceの返済100: 成功
  carolの清算: Stopped()
  [daveが全部引き出し] ブロック72 tx 0x419d86fdc53fa20b377721aaee00e72e3bfe648aacade0456499c81d5e9eef65
```

`python -I ops/timeline.py <RPC_URL> 49 72 <警報ファイル> アドレス=名前 …`が出した表（取引十六と警報九）から選んだ行。名前は引数で付けたもので、かっこの中のunpauseの説明は書き足したものである：

| ブロック | 経過(秒) | 起きたこと | tx |
|---|---|---|---|
| 49 | 0 | COL出どころ.setPrice <- 運営者 | 0x5ae8f79bef |
| 50 | 12 | 警報 [HIGH] 1分平均0.8000、30分平均0.9933 | |
| 51 | 12 | マルチシグ.execute(uint256) <- 署名者c | 0x85e3c963a7 |
| 54 | 181 | COL出どころ.setPrice <- 運営者 | 0xa9adcf8313 |
| 61 | 2584 | マルチシグ.execute(uint256) <- 署名者a（unpauseの予約） | 0x9ad84f1b19 |
| 69 | 175386 | マルチシグ.execute(uint256) <- 署名者a（unpauseの実行） | 0xa97ccd0982 |
| 70 | 175387 | COL出どころ.stop <- 運営者 | 0x59eecb5aa1 |
| 71 | 175399 | 警報 [HIGH] 価格の読み取りがリバート Stopped() | |
| 72 | 175399 | Market.withdrawAll <- dave | 0x419d86fdc5 |

気づくまで1ブロック（49 → 50）、止めるまで2ブロック（49 → 51）、出どころを直すまで181秒（49 → 54）かかった。リハーサルのあいだずっと、ログで数えた金庫とトークン残高は同じだった（COL 1,500 → 1,000、USD 300）。

`forge test --offline --match-contract RehearsalTest -vv`：

```
[PASS] test_R01_fixWithinThreeMinutesNoLiquidation() (gas: 4612168)
[PASS] test_R01_zeroForThirtyMinutesStops() (gas: 359932)
[PASS] test_R01_zeroPriceLiquidationWindow() (gas: 681261)
[PASS] test_R02_feedStoppedBorrowerRepaysThenExits() (gas: 295106)
[PASS] test_R02_feedStoppedDebtFreeExits() (gas: 451063)
[PASS] test_R03_preApprovedPauseOnlyOnce() (gas: 1239756)
Ran 1 test suite in 4.64ms (3.35ms CPU time): 6 tests passed, 0 failed, 0 skipped (6 total tests)
```

`test_R01_zeroPriceLiquidationWindow`は、出どころが0を書くと30分平均が1分に1/30ずつ下がり、清算ライン800 × (1 − t/30)が借金700の下に行くまで3分45秒（225秒）かかる境目を見る。225秒では`NotLiquidatable(700e18, 700e18)`、1秒後から清算ができる。`bash ci.sh`は92通過である。

リハーサルから出てきた四つ（`incidents/rehearsal-01.md` 7節）：

| 番号 | 出てきたもの | 答え |
|---|---|---|
| R-01 | 出どころが0を書くと3分45秒後に清算ラインを超え、停止では清算を止められない | 設計どおり（F-09、S-01、K-07） |
| R-02 | 出どころが止まっても、借金のない担保アカウントは全部の引き出し・担保のオフができる | ドキュメントをコードに合わせる（T-01、8節、監視の文言、お知らせ） |
| R-03 | 事前に承認した停止の提案は一度使えば終わり | 修正（手順、様式0節の3番） |
| R-04 | 出どころを変える関数を入れよう | 設計どおり（D-13、K-06） |

キャップストーンのバージョンの最後の表：

| バージョン | テスト（通過/スキップ） | Market runtime | 末尾のハッシュ |
|---|---|---|---|
| 第253講 要件 / 第254講 設計 | 2 / 25、6 / 25 | なし | - |
| 第255講 コアロジック / 第256講 標準 | 26 / 7、34 / 4 | 8,232、8,470 | 2940c095、13394016 |
| 第257講 権限 | 38 / 0 | 8,739 | ef24c031 |
| 第258講 テスト / 第259講 不変条件 / 第260講 自己監査 | 69 / 0、75 / 0、77 / 3 | 8,739 | 47ac4829 |
| 第261講 指摘への対応 | 81 / 0 | 8,921 | d551e83c |
| 第262講 デプロイ / 第263講 監視 / 第264講 リハーサル | 86 / 0、86 / 0、92 / 0 | 8,921 | d551e83c |

### 試すときの注意

- キャップストーンのバージョンでコードが開けておいた道は三つである。停止`pause(資産, ビット)`（停止キー、事前に承認した提案は署名者一人、待ちなし）、再開`unpause(資産, ビット)`（設定キー、2日）、停止キーの変更`setGuardian`（設定キー、2日）。
- 事故記録の様式0節は最初の30分の順番である。決める人を一人先に決め、原因を探す人・署名者を集める人・外に知らせる人は別に置く。署名の前にはcalldataを解いて読む。
- 等級の基準（2節）は事故の前に決める。1等級は残高・照合のCRITICAL、2等級は価格・合計のHIGHと未知の出金の失敗・予定にないタイムロックの予約、3等級は設定のINFO・監視自身の故障・ドキュメントに書いた失敗のLOWである。
- 止めれば新しく生まれる損害は防げるが、すでに生じた不足分はそのままである。清算は停止では止められない。時間を稼ぐのは30分平均の遅れである。
- 事前に承認した停止の提案は一度使えば終わる（`AlreadyExecuted`）。止めたあとに新しい提案を作って承認しておく。
- 止める取引と直す取引も、ブロックに入る前に誰でも見られる。
- 出どころが止まった日にお知らせすること：返済と担保ではない資産の引き出しはできる。その資産を担保にしたアカウントは、借金がなければ全部の引き出し・担保のオフができ、一部だけの引き出しはできない。借金があれば先に全部返す。出どころがいつ復活するかはわからないと書く。
- 出どころが止まっても全部の引き出し・担保のオフができる理由：帳簿を直したあとに上限を見て、その資産の欄が0なら価格を読まない。
- 価格の出どころを変える関数は入れない（D-13）。出どころを変えられるキーがあれば、そのキーも出どころである。復活できない出どころの資産はユーザーが返して引き出して移し、直したコードが必要なら次のバージョン・新しいアドレスである（K-06）。
- 事故の記録はブロック番号と取引ハッシュで書く。取引ハッシュは実行し直すと変わり、ブロック番号は同じである。
- キャップストーンのバージョンの最後の表の第253〜261講の値は、それらのバージョンを作ったときに記録した値を移したもので、第262〜264講の値は実行し直したciの値である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると変わることがあり、ブロック・ハッシュはローカルのanvilでこの順番で実行した値である。

| 項目 | 値 | 基準日 |
|---|---|---|
| ツール | Foundry 1.8.3（commit cae51ad4）、solc 0.8.30、forge-std 1.17.0、OpenZeppelin Contracts 5.4.0 | 2026-10-21 |
| ブロック・ハッシュ（ローカルのanvil 31337） | 出どころ0はブロック49、警報50、停止51、出どころを直す54（181秒）、再開の予約61・実行69、新しい停止の提案7（62〜64）、出どころの停止70、警報71、daveが全部引き出し72。txハッシュはこの実行の値（実行し直すと変わる） | 2026-10-21 |
| 平均・清算ライン | 0.993333 / 794.67、0.959444 / 767.56、いちばん低い平均0.899444 / 719.56、境目225秒（3分45秒） | 2026-10-21 |
| 監視のしきい値（このリポジトリの運用値） | 価格--move 5%、清算ライン0.95、出ていった量の中央値の10倍 | 2026-10-21 |
| テストの合計 | 第264講のバージョン92 / 0 / 0、RehearsalTest 6通過 | 2026-10-21 |
| キャップストーンのバージョンの最後の表 | 第253〜261講のバージョンの値はそのバージョンを作ったときに記録した値、第262〜264講のバージョンは実行し直したci | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 次のバージョン（借金のないアカウントの一部の引き出しなど）と移行 | 扱わない |
| 実際の価格の出どころの停止・復活の方式 | 扱わない |
| 実際の事故対応の年代記 | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| キャップストーンのバージョンの層ごとの信頼の表を出し直す | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
