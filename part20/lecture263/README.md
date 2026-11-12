# 第263講 モニタリングの構築

第20部 キャップストーンプロジェクト・第72章 デプロイと運用

[← 第262講](../../part20/lecture262/) | [第20部 目次](../) | [第264講 →](../../part20/lecture264/)

## この講義の問い

デプロイしたMarketを何で見守るのか。前のバージョンに合わせて書いた監視を新しいバージョンに移すとき、何が変わり、監視に見えないものは何か。

## 実習資料

### 準備

通しプロジェクトMarketの第262講のバージョン（デプロイスクリプトのバージョン）から始める。この講義で、前のバージョンの運用ツールをキャップストーンのバージョンに移して`ops/`に置き（`abi.py`、`indexer.py`、`monitor.py`、`loop.py`、`market_read.py`、`market_verify.py`、`timeline.py`、`mpt.py`、`sendq.py`）、ciに8段階目（`python -I ops/abi.py --check`）を加える。srcはそのままである。運用ツールはPythonの標準ライブラリだけを使い、読み取りのリクエストだけをしてキーを受け取らない（`sendq.py`だけが署名・送信に`cast`を使う）。

デモは、ローカルのanvil（チェーン番号31337）で第262講の順番どおりにデプロイ・上場したMarketを監視した。ユーザーのアカウントはanvilのデフォルトのアカウント（bob 4番、alice 5番、carol 6番）、価格の出どころの運営者は7番である。警報を受ける側は、HTTPで受け取った行を書き留めるだけのローカルのプログラムである。実際の通知サービスとジョブスケジューラーは使っていない。監視のコマンドの形は次のとおりである。

```
python -I -X utf8 ops/monitor.py <RPC_URL> <Market> indexer.json monitor.json --timelock <タイムロック> --alerts alerts.jsonl --hook <受ける側のアドレス> --expected expected.txt --move 5 --pause <マルチシグ>:<COL>=2,<USD>=3
```

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
| [code/ops/indexer.py](code/ops/indexer.py) | Market・タイムロックのログで帳簿を立て直すインデクサー |
| [code/ops/loop.py](code/ops/loop.py) | 監視を決めた間隔で回し続け、周回ごとに終了コードとかかった時間を書く |
| [code/ops/market_read.py](code/ops/market_read.py) | 複数のRPCに同じブロックハッシュでMarketの状態を尋ねて並べる |
| [code/ops/market_verify.py](code/ops/market_verify.py) | RPC一つがくれた帳簿の値を、ブロックハッシュ一つに当てて証明で確認 |
| [code/ops/monitor.py](code/ops/monitor.py) | 不変条件の監視（ログで数えた金庫と残高、設定・予約、価格、健全性、出金の試し呼び、heartbeat） |
| [code/ops/mpt.py](code/ops/mpt.py) | keccak-256、RLP、ブロックヘッダーのハッシュ、マークルパトリシアトライの証明の確認の部品 |
| [code/ops/sendq.py](code/ops/sendq.py) | 運用アカウント一つの送信キュー（ナンスをこのキュー一つだけが付ける） |
| [code/ops/timeline.py](code/ops/timeline.py) | 事故のタイムライン（取引と警報をブロック順に） |
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

前のバージョンの監視ツールが呼んでいた`status()`は、キャップストーンのバージョンにはない（停止は資産ごとの`pause(資産, ビット)`）：

```
$ cast call <Market> "status()(uint8)" --rpc-url <RPC_URL>
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast sig "status()"
0x200d2ed2
```

そこで、セレクタ・トピックを手で書かず、`abi/IMarket.json`から数える：

```
$ python -I ops/abi.py --check
運用ツールが使う名前 27 個がabi/IMarket.jsonに全部ある
$ python -I ops/abi.py
totalDeposits            0xe9403256
assetCount               0xeafe7a74
withdrawAll              0xfa09e630
pause                    0x3ae308fa
PauseSet                 0xd90577e7
ZeroPrice                0x4a6f5ccb
...
```

ABIにない値は、設計ドキュメント2節のストレージの欄の地図どおりに欄から読む（`ops/abi.py`）：

```python
SLOT_CONFIG, SLOT_RESERVES, SLOT_POSITIONS = 1, 2, 3

def slot_config(asset):
    """assetConfig[asset] +0: feed(0~19)·decimals(20)·collateralRatio(21)·pausedBits(22)·listed(23)"""

def slot_reserve(asset, k):
    """reserves[asset] +k: 0 scaledDeposits, 1 scaledBorrows, 2 supplyIndex, 3 borrowIndex, 4 lastAccrual"""

def slot_position(asset, user, k):
    """positions[asset][user] +k: 0 scaledDeposit, 1 scaledDebt, 2 useAsCollateral"""
```

ここから下の監視の出力（周回・警報・受信・証明の確認、loopとheartbeatを含む）について：出力は元の実行結果の文字列だけを訳したもの。文言はこのコードの`ops/`のツールが出力する文言に合わせ、値・順番・空白は元のままである（ブロックハッシュ・ステートルートはデプロイしたコードによって変わる）。「予約 listAsset(…)」の2行と「受信」の行は、デモで付けた見出しと受ける側のプログラムの出力である。

上場の予約のあとの周回（予約二つ、実行二つはINFO）：

```
予約 listAsset(0x98eDDadC): ブロック12、作業 0x1546d047941d2cd126e4e574bbe8b56fdcb2e8789272645f32ae7720823d32bf
予約 listAsset(0x2B574555): ブロック16、作業 0x14768498382b40d022484ca9983097be226534951fe13db0c9aa5b6b3e1e081b
周回 2 | 最新 22、確認したブロック 22 0x3b2a1e7f
  [INFO] タイムロックの予約 listAsset (作業 0x1546d047、ブロック 12、実行可能まで 172797 秒)
  [INFO] タイムロックの予約 listAsset (作業 0x14768498、ブロック 16、実行可能まで 172798 秒)
周回 3 | 最新 31、確認したブロック 31 0x4dfe703e
  [INFO] タイムロックの作業 0x1546d047 実行 (listAsset)
  [INFO] タイムロックの作業 0x14768498 実行 (listAsset)
```

ユーザーの取引（bobがUSD 1000を預け、aliceがCOL 1000を担保にUSD 700を借り、carolがCOL 500を預ける）のあとの周回4と、30日後の周回5：

```
周回 4 | 最新 44、確認したブロック 44 0xf0524dc2
  資産 0x2b574555 引き出す量 1000000000 トークン残高 300000000 貸し出した借金 700000001 | ログで数えた金庫 300000000 (預け入れ 1000000000 引き出し 0 借り入れ 700000000 返済 0) | 持ち分の合計の欄 1000000000/700000000 アカウントの欄の合計 1000000000/700000000(アカウント 2)
  アカウント 0x9965507d 借金の値 700.00 清算ライン 800.00 (0.875)

周回 5 | 最新 45、確認したブロック 45 0xb3c02cf2
  資産 0x2b574555 引き出す量 1002517124 トークン残高 300000000 貸し出した借金 702517125 | ログで数えた金庫 300000000 (預け入れ 1000000000 引き出し 0 借り入れ 700000000 返済 0) | 持ち分の合計の欄 1000000000/700000000 アカウントの欄の合計 1000000000/700000000(アカウント 2)
  アカウント 0x9965507d 借金の値 702.52 清算ライン 800.00 (0.878)
  開いている警報 2 件
```

ログで数えた預けた合計1,000と引き出す量1,002.517124の差2.517124は30日分の利息で、ログにはない。周回4の開いている警報二つは、出金の試し呼びのLOWである：

```
[LOW] 資産 0x98eddadc アカウント 0x9965507d 出金の試し呼び InsufficientCollateral(uint256,uint256) (ドキュメントに書いた失敗: 借金の上限(F-03))
[LOW] 資産 0x2b574555 アカウント 0x15d34aaf 出金の試し呼び InsufficientLiquidity(uint256,uint256) (ドキュメントに書いた失敗: 残ったトークンを借りていった(F-02))
```

carolがdepositなしでUSD 5をMarketのアドレスに直接送ったあと（ブロック46）：

```
周回 6 | 最新 46、確認したブロック 46 0xb18bb3d7
  資産 0x2b574555 引き出す量 1002517125 トークン残高 305000000 貸し出した借金 702517126 | ログで数えた金庫 300000000 (預け入れ 1000000000 引き出し 0 借り入れ 700000000 返済 0) | ...
  [LOW] 資産 0x2b574555 トークン残高 305000000 > ログで数えた金庫 300000000: ログなしで入ってきたトークン 5000000 (K-04、帳簿にない)
  開いている警報 3 件
```

予定ファイル`expected.txt`に上場の作業id二つを書いておき、マルチシグが予定にない`setSupplyCap(USD, 2000)`を予約して（ブロック50）取り消した（ブロック54）周回：

```
周回 7 | 最新 50、確認したブロック 50 0xcae2c8db
  [HIGH] 予定にない タイムロックの予約 setSupplyCap (作業 0x05740ce3、ブロック 50、実行可能まで 172800 秒)
周回 8 | 最新 54、確認したブロック 54 0x23898579
  [INFO] タイムロックの作業 0x05740ce3 取り消し (setSupplyCap)
  [RESOLVED] 解消 op-0x05740ce38ab3960f65afb422b484a2f2d6b68f8da6ea6d43c8a279c
```

価格の出どころがCOL 0.9を書いてから1分後（ブロック55〜56）と30分後：

```
周回 9 | 最新 56、確認したブロック 56 0xa52db185
  アカウント 0x9965507d 借金の値 702.52 清算ライン 797.33 (0.881)
  [HIGH] 資産 0x98eddadc 直近1分平均 0.9000、30分平均 0.9967 (差 -9.7%、平均が追いついている途中)
  対応の候補: 資産 0x98eDDadC 事前に承認しておいた停止の提案 2(マルチシグ 0x95bD8D42)。署名者一人が execute(2) = 0xfe0d94c10000000000000000000000000000000000000000000000000000000000000002
周回 10 | 最新 57、確認したブロック 57 0x340885d7
  アカウント 0x9965507d 借金の値 702.52 清算ライン 720.00 (0.976)
  [INFO] アカウント 0x9965507d 借金の値 / 清算ライン 0.976: 清算ラインが近い
  [RESOLVED] 解消 move-0x98eddadcfde04dc22a0e62119617e74a6bc77313
  priceOf(COL) 900000000000000000, alice accountHealth 675000000000000000000 [6.75e20] / 702518935000000000000 [7.025e20]
```

借りられる上限675 < 借金702.52 < 清算ライン720なので、これ以上借りられず、清算はまだできない。監視は停止のcalldataまでを出力し、実行は人がする。

`ops/loop.py 1 3 loop.txt -- <monitorの引数>`（1秒間隔で3周、周回ごとに終了コードとかかった時間）：

```
07:53:12 | 開いている警報 | 0.2秒 | 周回 11 | 最新 57、確認したブロック 57 0x340885d7
07:53:13 | 開いている警報 | 0.2秒 | 周回 12 | 最新 57、確認したブロック 57 0x340885d7
07:53:14 | 開いている警報 | 0.2秒 | 周回 13 | 最新 57、確認したブロック 57 0x340885d7
```

受ける側が受け取った13行のうち五つ：

```
受信 [LOW] ブロック 46 資産 0x2b574555 トークン残高 305000000 > ログで数えた金庫 300000000: ログなしで入ってきたトークン 5000000 (K-04、帳簿にない)
受信 [HIGH] ブロック 50 予定にない タイムロックの予約 setSupplyCap (作業 0x05740ce3、ブロック 50、実行可能まで 172800 秒)
受信 [RESOLVED] ブロック 54 解消 op-0x05740ce38ab3960f65afb422b484a2f2d6b68f8da6ea6d43c8a279c
受信 [HIGH] ブロック 56 資産 0x98eddadc 直近1分平均 0.9000、30分平均 0.9967 (差 -9.7%、平均が追いついている途中)
受信 [INFO] ブロック 57 アカウント 0x9965507d 借金の値 / 清算ライン 0.976: 清算ラインが近い
```

`ops/market_read.py`（RPC一つ）と`ops/market_verify.py`で、同じブロックハッシュで帳簿の値を証明で確認：

```
基準ブロック: latest 57 0x340885d740c534eac14473019588b53886320ae0ab8c6026e5465359b3bb195b (RPC 1が教えたもの)
結果: すべてのRPCが同じ答え
1) ブロックヘッダーのハッシュ: 同じ (ブロック 57、ステートルート 0x52103819ae94…)
2) 証明: ステートルートまでつながる (アカウントノード 2個、ストレージスロットのノード 3個)
3) scaledDeposits(reserves[資産] +0): 証明の値 1000000000、eth_getStorageAtの答え 1000000000 -> 同じ
結果: 確認済み
```

監視自身が生きているか（`--heartbeat`）：

```
$ python -I ops/monitor.py --heartbeat monitor.json 60
監視正常: 最後の周回 1 秒前、確認したブロック 57
$ python -I ops/monitor.py --heartbeat monitor_old.json 60   (最後の周回を600秒前に書き換えた状態ファイル)
[CRITICAL] 監視が 601 秒間回っていない(最後に確認したブロック 57)
```

検査の表（設計ドキュメント15節）：

| 検査 | 比べるもの | 警報 |
|---|---|---|
| 照合 | ログで数えた金庫 = トークンのbalanceOf(Market) | 残高が多ければLOW（K-04）、少なければCRITICAL |
| 合計 | アカウントの欄の持ち分の合計 = 合計の欄 | HIGH |
| 残高 | トークン残高 + totalBorrows ≥ totalDeposits | CRITICAL（I-1） |
| 出金 | 持ち分のあるアカウントごとにwithdrawAllの試し呼び | ドキュメントに書いた失敗四つはLOW、それ以外はHIGH |
| 価格 | priceOfの巻き戻し、直近1分平均 vs 30分平均 | HIGH |
| 設定 | 停止ビット、タイムロックの予約・実行・取り消し | INFO、予定にない予約はHIGH |
| 健全性 | 借金の値 / 清算ライン | INFO |
| 流出 | 今回の周回で出ていった量 vs 前のブロックの中央値 | INFO |
| ノード | ノードの応答 | HIGH |
| 監視自身 | `--heartbeat` | CRITICAL |

### 試すときの注意

- 判定の基準は、設計ドキュメントの不変条件（5節）と信頼の前提（6節）から持ってくる。ノードが生きていてブロックが出ていても、金庫と帳簿、価格の平均、タイムロックの予約は崩れることがある。
- topic0はどのコントラクトでも同じものを出せる。インデクサーはMarket・タイムロックの二つのアドレスのログだけを、ブロックハッシュで読む。
- キャップストーンのイベントはトークンの量だけを書くので、ログで数えるのは金庫一つである（D-17）。持ち分と利息は欄から読む。
- 照合でトークン残高がログで数えた金庫より多ければ、預けた人が失うものはないのでLOWである。少なければCRITICALである。
- 予定ファイルは、運用日誌から移したタイムロックの作業idの一覧である。一覧にない予約はHIGHに上げ、人が見る時間はタイムロックの待機の2日である。
- しきい値はこのリポジトリの運用値である（価格`--move 5`%、清算ライン0.95、出ていった量の中央値の10倍、heartbeat 60秒）。ふだんの値は平均ではなく中央値で取る。
- 出金の試し呼びで、ドキュメントに書いた失敗は四つ（`InsufficientLiquidity`、`InsufficientCollateral`、`Stopped`、`ZeroPrice`）である。
- heartbeatの検査は監視と別の機械で動かす。同じ機械なら一緒に止まる。
- 監視は、自分が尋ねたノードが見せたものだけを知っている。警報がないというのは、監視が見た行に異常がないという意味である。
- `positions(address,address)`はMarketの自動ゲッターなので答えが返るが、IMarketと`abi/IMarket.json`にはない。運用ツールはABIファイルにある名前だけを使う。
- 再編成への対応はインデクサーの形のまま移し、このデモでは再編成を起こしていない。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると変わることがあり、アドレス・ブロック・数字はローカルのanvilでこの順番で実行した値である。

| 項目 | 値 | 基準日 |
|---|---|---|
| ツール | Foundry 1.8.3（commit cae51ad4）、solc 0.8.30、Pythonの標準ライブラリ | 2026-10-21 |
| 監視のしきい値（このリポジトリの運用値） | 価格--move 5%、清算ライン0.95、出ていった量の中央値の10倍、heartbeat 60秒 | 2026-10-21 |
| アドレス・ブロック（ローカルのanvil 31337） | タイムロック`0x5FbD…0aa3`、Market `0xe7f1…0512`、上場の予約12・16・実行27・31、ユーザーの取引〜43、直接送金46、予定にない予約50・取り消し54、出どころ0.9はブロック55、最後のブロック57 | 2026-10-21 |
| 数字（USD 6桁） | 30日後の引き出す量1,002.517124・借金702.517125、ログで数えた金庫300、直接送った5、1分平均0.9000・30分平均0.9967（-9.7%）、清算ライン720 / 借金702.52（0.976）、上限675 | 2026-10-21 |
| 通知・スケジューラー | ローカルの受ける側と`ops/loop.py`まで。実際の通知サービス・ジョブスケジューラーの名前・料金は確認していない | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 実際の通知サービス・ジョブスケジューラー | 扱わない（時効性のあるデータ） |
| ブロックに入る前の取引の監視 | 扱わない |
| 二つ目のノードの検査をもう一度取る | 扱わない |
| 再編成への対応 | 扱わない |
| 価格の出どころの事故のときの停止と再開 | [第264講](../../part20/lecture264/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
