# 第242講 インシデント対応の手順

第18部 インフラ運用とデータ・第66章 モニタリングとインシデント対応

[← 第241講](../../part18/lecture241/) | [第18部 目次](../) | [第243講 →](../../part18/lecture243/)

## この講義の問い

チェーンの上で事故が起きたとき、できることは何で、できないことは何か。誰が決め、何を根拠に調べ、ユーザーに何を知らせるのか。終わった事故から何を残せば、次に同じことを防げるのか。

## 実習資料

### 準備

第241講のバージョン（第53章の最終バージョンのMarket + 運用ツール六つ、テスト143個）に、タイムラインのツールと事故記録の書式を加えたバージョン（第66章の最終バージョン）から始める。Marketのコントラクトとテストは第241講のバージョンと同じである。テストにはforge-stdが必要である（`lib/forge-std`）。タイムラインのツールはPythonの標準ライブラリだけを使う。

練習用の事故のチェーンは、第241講のデモをローカルのanvilでそのままもう一度実行して作る（手数料をオンにしたトークン、carolの預け入れのあとの残高の警報、署名者cによる停止、失敗したdaveの預け入れ、bob・carolの引き出し）。そのチェーンが生きているあいだに、下の調査のコマンドを順に呼ぶ。結果の`$RPC`は、練習用の事故のチェーンのRPCアドレスである。

### コード

| ファイル | 内容 |
|---|---|
| [code/ops/timeline.py](code/ops/timeline.py) | ブロックを順に読み、Market・マルチシグ・上場トークンへ行った取引と警報の記録を、ブロック番号の順に一つの表にまとめる。セレクターの表（deposit、withdraw、withdrawAll、setStatus、addAsset、propose、approve、execute、setFee、transfer）で関数名を付ける |
| [code/ops/incident_template.md](code/ops/incident_template.md) | 事故記録の書式の七つの節（ヘッダー、等級の基準、タイムライン、わかっていること・わかっていないこと、やったこととその取引、外に知らせた文、事後報告） |
| [code/ops/](code/ops/) | 第236〜241講の運用ツール（そのまま） |
| [code/test/Breaker.t.sol](code/test/Breaker.t.sol)、[code/test/FeeSwitchToken.sol](code/test/FeeSwitchToken.sol) | 第241講のテストとテスト用のトークン（そのまま） |
| [code/foundry.toml](code/foundry.toml) | ビルド設定（solc 0.8.30、optimizer 200、via-IR、osaka） |
| [code/src/](code/src/) | Market、IMarket、MarketMath、MarketTypes、テスト用のMockToken（第199講のバージョンそのまま） |
| [code/test/](code/test/) | そのほかの基準バージョンのテスト（合わせて143個） |

使い方：`python -I ops/timeline.py <RPC> <開始ブロック> <終了ブロック> <警報ファイル> <アドレス=名前> ...`。

### 実行結果

警報が指した取引（carolの預け入れ）のレシートとトレース。取引は成功し、トークンの中で100が99と1に分かれて移されたのに、Marketは100と書いた。

```
$ cast receipt 0x50dbf1df39737a0556540da2fe776d5acad170dd77d85f84276e80c4ecce4121 status --rpc-url $RPC
true
$ cast receipt 0x50dbf1df39737a0556540da2fe776d5acad170dd77d85f84276e80c4ecce4121 blockNumber --rpc-url $RPC
16
$ cast run 0x50dbf1df39737a0556540da2fe776d5acad170dd77d85f84276e80c4ecce4121 --rpc-url $RPC
Traces:
  [90063] 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0::deposit(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, 100)
    ├─ [21637] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::transferFrom(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, 100)
    │   ├─ emit Transfer(from: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, amount: 99)
    │   ├─ emit Transfer(from: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, to: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, amount: 1)
    │   └─ ← [Return] true
    ├─ emit Deposited(asset: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, user: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, amount: 100)
    └─ ← [Stop]

Transaction successfully executed.
Gas used: 106835
```

警報のブロック16を基準にしたMarketの帳簿とトークンの残高：

```
$ cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 totalDeposits(address)(uint256) 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 --block 16 --rpc-url $RPC
200
$ cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 balanceOf(address)(uint256) 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 --block 16 --rpc-url $RPC
199
```

トークンの側で何が変わったのか。FeeChangedのログは一つだけで、ブロック番号は15である（0 → 0x64 = 100、万分率で1%）。ブロックごとに`feeBps`を尋ねると、14は0、15は100である。

```
$ cast logs --from-block 0 --to-block latest --address 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 FeeChanged(uint256,uint256) --rpc-url $RPC
- address: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  blockNumber: 15
  data: 0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064
  topics: [
  	0x5fc463da23c1b063e66f9e352006a7fbe8db7223c455dc429e881a2dfe2f94f1
  ]
  transactionHash: 0x0e3d7bec411a9b6781382ce1035a243da89875f406e249cc2f25909211b192f9
$ cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 feeBps()(uint256) --block 14 --rpc-url $RPC
0
$ cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 feeBps()(uint256) --block 15 --rpc-url $RPC
100
```

止めたあとに入ったdaveの預け入れは、status false、ログなし、NotActive(1)でリバートした。停止の取引は、署名者c（0x90F7…b906）がマルチシグ（0x5FbD…0aa3）経由で送った。

```
$ cast run 0x2eddd4f5fbe8e72ce1ed0756b18c2e0fce77fa96dfb9fe196fd043219ff8ade8 --rpc-url $RPC
Traces:
  [2607] 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0::deposit(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, 100)
    └─ ← [Revert] NotActive(1)

Gas used: 24179
Error: Transaction failed.
$ cast run 0xb841e6c0753b580c9453e5ca2238a9611f8fe3659c8a99eb7a22cbc365bd1e2f --rpc-url $RPC
Traces:
  [64503] 0x5FbDB2315678afecb367f032d93F642f64180aa3::execute(1)
    ├─ [23855] 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0::setStatus(1)
    │   ├─ emit StatusChanged(from: 0, to: 1)
    │   └─ ← [Stop]
    └─ ← [Stop]

Transaction successfully executed.
Gas used: 85707
```

`ops/timeline.py`で、ブロック1〜19を警報の記録と一緒に一つの表にまとめた結果。経過秒は実行するたびに違う。

| ブロック | 経過(秒) | 起きたこと | tx |
|---|---|---|---|
| 4 | 0 | マルチシグ.propose <- a, 成功, ログ 0 | 0x778971ba09 |
| 5 | 0 | マルチシグ.approve <- a, 成功, ログ 0 | 0x32b348594a |
| 6 | 0 | マルチシグ.approve <- b, 成功, ログ 0 | 0xfa8e70e7b9 |
| 7 | 0 | マルチシグ.execute <- a, 成功, ログ 1 | 0x22b9058cd4 |
| 8 | 1 | マルチシグ.propose <- a, 成功, ログ 0 | 0xb45f291796 |
| 9 | 1 | マルチシグ.approve <- a, 成功, ログ 0 | 0xe81379542b |
| 10 | 1 | マルチシグ.approve <- b, 成功, ログ 0 | 0x2bc465b7af |
| 11 | 1 | トークン.transfer <- トークンの持ち主, 成功, ログ 1 | 0x214acc6357 |
| 12 | 1 | トークン.transfer <- トークンの持ち主, 成功, ログ 1 | 0x256821568b |
| 13 | 1 | トークン.transfer <- トークンの持ち主, 成功, ログ 1 | 0xd9c098b2a2 |
| 14 | 2 | Market.deposit <- bob, 成功, ログ 2 | 0x6b97aeaa16 |
| 15 | 4 | トークン.setFee <- トークンの持ち主, 成功, ログ 1 | 0x0e3d7bec41 |
| 16 | 5 | Market.deposit <- carol, 成功, ログ 3 | 0x50dbf1df39 |
| 16 | 5 | 警報 [CRITICAL] 資産 0xe7f1725e トークン残高 199 + 貸し出した借金 0 < 引き出す量 200 (不足 1) |  |
| 17 | 7 | マルチシグ.execute <- c, 成功, ログ 1 | 0xb841e6c075 |
| 17 | 7 | Market.deposit <- dave, 失敗(status 0), ログ 0 | 0x2eddd4f5fb |
| 17 | 7 | 警報 [INFO] マーケットの状態 Active -> DepositPaused |  |
| 18 | 10 | Market.withdrawAll <- bob, 成功, ログ 3 | 0x304a297b2a |
| 18 | 10 | 警報 [HIGH] 資産 0xe7f1725e アカウント 0x9965507d 持ち分 100 出金の試し呼び失敗 0x4e48…0011 |  |
| 19 | 12 | Market.withdraw <- carol, 成功, ログ 2 | 0xb6de58fe0c |

同じコマンドのレシートの欄の出力の一部と、ログのblockHash・logIndexの行は省いた。テストは`forge test --offline`で143個がすべて通る。

### 試すときの注意

- 事故の記録は「午前3時ごろ」ではなく、ブロック番号と取引のハッシュで書く。ブロック番号で`--block`を指定すれば、その時点の帳簿と残高をもう一度尋ねられる。
- 事故記録の書式の5節には、停止の取引を送ったアカウント・ナンスと、そのナンスで署名したハッシュを手数料を上げて送り直したものまで、すべて書く。
- 署名者一人が、二つの端末から同じ鍵で送らない。連絡先と代わりに連絡する人を、書式のヘッダーに書いておく。
- 取引のハッシュはベースフィーによって変わることがある。ブロック番号、警報の順番と等級は同じに出る。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | 2026-10-21 |
| solc | 0.8.30 | 2026-10-21 |
| Compound 2021 | 提案64 "Fix COMP Accrual Bug"："Proposal 62 introduced a bug in the COMP distribution logic"。2021-10-02に提案、2021-10-09に実行 | 2026-10-21 |
| Euler 2023 | 事件 2023-03-13、"recovered after negotiations with the exploiter"。金額は載せない | 2026-10-21 |
| Ronin 2022、Nomad 2022 | 名前・年のみ（公式の事後報告書は確かめられなかった） | 2026-10-21 |
| 事故対応を手伝う団体（例） | SEAL 911、"24/7 cryptocurrency incident response"。名前のみ | 2026-10-21 |
| 通しプロジェクトのバージョン | 第241講のバージョン + ops/timeline.py + ops/incident_template.md、テスト143個 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 対応のリハーサル（役割を分けて実際に回してみる） | [第264講](../../part20/lecture264/) |
| 事件ごとの対応の年代記 | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| 不足分の補償・法的対応・懸賞金の交渉 | 付録のデータの行 |
| バグの報告窓口と懸賞金の制度 | 付録のデータの行 |
| 署名者の端末と交代の手順 | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
