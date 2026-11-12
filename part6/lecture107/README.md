# 第107講 匿名イベントとオフチェーンでの利用

第6部 言語の詳細 ③ コントラクト・第23章 イベントとログ

[← 第106講](../../part6/lecture106/) | [第6部 目次](../) | [第108講 →](../../part6/lecture108/)

## この講義の問い

topic0を空けると何を得て何を失い、チェーンの外でログを受け取ってMarketの状態を組み立て直すプログラムは、何を自分で面倒を見なければならないのか。

## 実習資料

### 準備

第106講の終わりのMarketのプロジェクトから始める。Marketのコードは変えず、`IMarket`に四つのイベントを書き、ログで状態を組み立て直すテストを加える。イベントのデモ用のコントラクトは別に作ったデモ用のプロジェクト（`demo`）にまとめ、ローカルのanvilにデプロイしてレシートとログの照会を見る。ログを読む側のプログラム（`reader`）は、Pythonの標準ライブラリだけを使う。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/demo/src/Ev.sol](code/demo/src/Ev.sol) | 第23章のデモ用のコントラクトの集まり。この講義で加えたのは`Anon`（匿名イベント）と`Fake`（Marketと同じ`Deposited`を誰でも出せるコントラクト） |
| [code/demo/test/Rec.t.sol](code/demo/test/Rec.t.sol) | Outer・Failを`vm.recordLogs`で受け取り、ログの数を出力するテスト |
| [code/demo/bad/Five.sol](code/demo/bad/Five.sol) | `indexed`が五つの匿名イベント、Error 8598 |
| [code/reader/reader.py](code/reader/reader.py) | `eth_getLogs`でDeposited・Withdrawnを受け取り、アカウントごとの預け入れの額を組み立て直すプログラム。処理した最後のブロックを状態ファイルに書く |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのプロジェクトの設定 |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | この講義で四つのイベントを加えたインターフェース（Marketと同じシグネチャ・`indexed`の配置） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第107講のバージョンのMarket（第106講のバージョンとコードは同じ） |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Rebuild.t.sol](code/market/test/Rebuild.t.sol) | この講義で加えたテスト。ログで組み立て直した値と`positions`の比較、アドレスでふるい分けないと間違う場合、リバートした呼び出しのログ |
| [code/market/test/Selectors.t.sol](code/market/test/Selectors.t.sol) | `test_eventTopicsMatch`を追加（IMarketとMarketの四つのイベントのtopic0の比較） |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト |

### 実行結果

`Anon`の`move(アカウント1番, 100)`のレシート（`cast send --json`、一部）。topicsにシグネチャのハッシュの欄がなく、from・toの二つの欄だけである。

```
"status": "0x1", "gasUsed": "0x5cc2", "blockNumber": "0xe"
"logs": [{
  "address": "0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0",
  "topics": [
    "0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266",
    "0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8"
  ],
  "data": "0x0000000000000000000000000000000000000000000000000000000000000064",
  "logIndex": "0x0"
}]
```

四つとも`indexed`の`four()`はtopicsが四つの欄でdataは`0x`、五つならビルドが失敗する（`forge build`）。

```
Error (8598): More than 4 indexed arguments for anonymous event.
```

同じ`move(アカウント1番, 100)`のgasUsedは、Plain 24,168、Indexed 24,124、Anon 23,746である。シグネチャで`cast logs`を問い合わせるとAnonのログは0件で、アドレスだけで問い合わせると2件出る。`forge inspect Anon events`の表のTopicの欄は空で、ABIのイベントの項目は`"anonymous": true`である。

アドレスなしでMovedを問い合わせると、PlainとIndexedのログが混ざって出てくる（`cast logs`、address・blockNumberの行だけ）。

```
$ cast logs "Moved(address indexed from, address indexed to, uint256 amount)"
- address: 0x5FbDB2315678afecb367f032d93F642f64180aa3   blockNumber: 8
- address: 0x5FbDB2315678afecb367f032d93F642f64180aa3   blockNumber: 9
- address: 0x5FbDB2315678afecb367f032d93F642f64180aa3   blockNumber: 10
- address: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512   blockNumber: 11
- address: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512   blockNumber: 12
- address: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512   blockNumber: 13
```

`Fake`が`fake(トークン, アカウント1番, 1000)`を出したあと、Deposited・アカウント1番をアドレスありとアドレスなしで問い合わせる。

```
$ cast logs --address $M "Deposited(address indexed asset, address indexed user, uint256 amount)" "" $B
- address: 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1   blockNumber: 21   data: …0032
- address: 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1   blockNumber: 24   data: …0014
$ cast logs "Deposited(address indexed asset, address indexed user, uint256 amount)" "" $B
- address: 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1   blockNumber: 21   data: …0032
- address: 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1   blockNumber: 24   data: …0014
- address: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9   blockNumber: 27   data: …03e8
```

Marketのシナリオ（ブロック18〜26）。

| ブロック | 呼び出し | ログ |
|---|---|---|
| 18 / 19 | アカウント0番 addAsset(トークン, 75)、deposit 100 | AssetAdded / Deposited |
| 20 | アカウント0番がアカウント1番にトークン300 | なし（MockTokenはイベントなし） |
| 21 / 22 | アカウント1番 deposit 50 / アカウント0番 withdraw 30 | Deposited / Withdrawn |
| 23 / 24 | アカウント1番 withdrawAll / deposit 20 | Withdrawn / Deposited |
| 25 / 26 | setStatus(2) / アカウント1番 withdraw 5 | StatusChanged / なし |

`cast logs --address $M`は7件である。このログで組み立て直した値とMarketの状態を照らし合わせる（`reader.py`、`cast call`）。アドレスでふるい分けないと（`any`）、Fakeの1000が混ざる。

```
$ python -I reader.py $M a.json
blocks 0 .. 27 logs 5
0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 70
0x70997970c51812dc3a010c7d01b50e0d17dc79c8 20
$ cast call $M "positions(address,address)(uint256,uint256,uint64,bool)" $T $B
20
$ cast call $M "totalDeposits(address)(uint256)" $T
90
$ python -I reader.py any b.json
blocks 0 .. 27 logs 6
0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 70
0x70997970c51812dc3a010c7d01b50e0d17dc79c8 1020
```

`positions`の出力は最初の値だけを載せた。凍結したあとの引き出し（ブロック26）はブロックに入ったが、status 0、gasUsed 24,761、`"logs": []`である。

同じ状態ファイルでもう一度実行すると、28番のブロックから問い合わせ、新しいログは0件である。書いておいたブロック番号（`last`）を-1に消して実行すると、二重に数える。

```
$ python -I reader.py $M a.json
blocks 28 .. 27 logs 0
0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 70
0x70997970c51812dc3a010c7d01b50e0d17dc79c8 20
$ python -I reader.py $M a.json
blocks 0 .. 27 logs 5
0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 140
0x70997970c51812dc3a010c7d01b50e0d17dc79c8 40
```

Rebuildのテスト（`forge test --match-contract RebuildTest`）。アドレスでふるい分けた値はalice 150、bob 100で`positions`と同じで、アドレスの検査を抜くとbobが1100になる。

```
[PASS] test_rebuildMatchesPositions() (gas: 384606)
[PASS] test_recordedLogsIncludeReverted() (gas: 222640)
[PASS] test_withoutEmitterCheck() (gas: 346895)
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

`vm.getRecordedLogs()`とanvilのレシートのログの数。

| 呼び出し | `vm.getRecordedLogs()` | anvilのレシートのlogs |
|---|---|---|
| 出してからリバートする`tryIt(5)` | 1件（Tried） | 0件（status 0） |
| Outerの`go(3)` | 3件（Before、InnerLog、After） | 2件（Before、After） |

`Note`を購読（`cast logs --subscribe`、wsのアドレス）しながら`note(41)`（ブロック30）、`note(42)`（ブロック31）を送ったあと、`cast rpc anvil_rollback 1`で最後のブロックを消すと、同じログが`removed: true`でもう一度来る（一部の行だけ）。

```
- address: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  blockNumber: 30
  data: 0x…f39fd6e51aad88f6f4ce6ab8827279cfffb92266…0029
  removed: false
- address: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  blockNumber: 31
  data: 0x…f39fd6e51aad88f6f4ce6ab8827279cfffb92266…002a
  removed: false
- address: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  blockNumber: 31
  data: 0x…f39fd6e51aad88f6f4ce6ab8827279cfffb92266…002a
  removed: true
```

rollbackのあと`cast block-number`は31から30になり、`cast logs`で問い合わせ直すと41の一件だけが残る。

IMarketとMarketのイベントの表（`forge inspect … events`、Topicは前後8桁）。表示名は違っても、四つのtopic0は同じである。

```
$ forge inspect --offline IMarket events
| AssetAdded(address,Ratio)                              | 0x57c9e281…9989 |
| Deposited(address,address,uint256)                     | 0x8752a472…68a7 |
| StatusChanged(uint8,uint8)                             | 0xe1377aa2…9a62 |
| Withdrawn(address,address,uint256)                     | 0xd1c19fbc…e5fb |
$ forge inspect --offline Market events
| AssetAdded(address,Ratio)                              | 0x57c9e281…9989 |
| Deposited(address,address,uint256)                     | 0x8752a472…68a7 |
| StatusChanged(Market.MarketStatus,Market.MarketStatus) | 0xe1377aa2…9a62 |
| Withdrawn(address,address,uint256)                     | 0xd1c19fbc…e5fb |
```

```
$ forge test --offline --mt test_eventTopicsMatch
[PASS] test_eventTopicsMatch() (gas: 438)
$ forge test --offline
Ran 9 test suites: 25 tests passed, 0 failed, 0 skipped (25 total tests)
```

### 試すときの注意

- 一つのトランザクションの中のログの順番は`logIndex`が決める。ログを（blockNumber, logIndex）の順に並べないと、同じブロックの預け入れ・引き出しを逆に数えることがある。
- `reader.py`は、処理する区間が空なら（`start > latest`）`eth_getLogs`を呼ばない。空の区間で問い合わせると、応答に`result`がなくエラーになる。
- `anvil_rollback`は標準のJSON-RPCにはない、anvil専用のコマンドである。本物のチェーンでは再編成が同じことをする。
- `vm.recordLogs`でログを数えるテストにリバートする呼び出しを混ぜると、レシートにはないログまで数える。
- 広いブロックの区間を一度に問い合わせると、RPCサービスが拒むことがある。`cast logs --query-size`で区間を分けて問い合わせる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやサービスの方針が変わると、変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| gasUsed | Plain `move` 24,168、Indexed 24,124、Anon 23,746、Anon `four()` 23,118、Market addAsset 93,730、deposit（アカウント0番100）130,240、凍結したあとの引き出し24,761（status 0）、Fail `tryIt(5)` 45,380（status 0）、Outer `go(3)` 30,964 | 2026-10-19 |
| LOGのガス | 基本375、トピック一つに375、dataのバイトあたり8、メモリ拡張は別。IndexedとAnonの差378 | 2026-10-19 |
| Marketのサイズ | runtime 8,173 / creation 8,869バイト（第106講のバージョンと同じ） | 2026-10-19 |
| topic0 | AssetAdded `0x57c9e281a77ac9ba91a9f926dda440cd98f47ee4f2d5030b5d54688cecbc9989`、StatusChanged `0xe1377aa21d49fa10bb9ece6a0cd4f75597a90a80c3750f7f7674967f49ab9a62`、Deposited `0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7`、Withdrawn `0xd1c19fbcd4551a5edfb66d43d2e337c04837afda3482b42bdf569a8fccdae5fb`、Moved `0x000e6e1d52477156459d942cdb0bc0970a404c1ea857ab5b75b5ad32f334dfc1` | 2026-10-19 |
| `vm.recordLogs`の動作 | リバートした呼び出しのログも返す（ドキュメントに関連する文はない、forge 1.8.3での実測） | 2026-10-19 |
| `anvil_rollback` | anvil 1.8.3で応答null、ブロック31 → 30。標準のJSON-RPCのメソッド一覧とFoundryのanvilのリファレンスに項目なし | 2026-10-19 |
| `cast logs --query-size` | プロバイダーの区間・結果数の制限を避けるため、クエリをこのブロック数ずつに分ける | 2026-10-19 |
| RPCサービスのeth_getLogsの制限 | Alchemy（イーサリアム）：ブロックの区間 Free 10、Pay As You Go・Enterprise 制限なし、応答150MBの上限。Infura：リクエストあたりパラメータ5,000個、結果10,000個、照会10秒まで（超えると-32005 "query returned more than 10000 results"）。QuickNode：ブロックの区間 Free Trial 5、有料10,000 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 継承とイベントの宣言 | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| 配列・構造体を`indexed`にするときのエンコードの規則 | [第141講](../../part8/lecture141/) |
| イベントのコストをめぐる最適化の判断（anonymousを含む） | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 標準が決めたイベント（ERC-20の`Transfer`など）とその`indexed`の配置 | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| 同じ形のログを利用した実際の事件 | [第179講](../../part11/lecture179/) |
| ノードの運用とRPCの層、ノードを信じる範囲 | [第235講](../../part18/lecture235/)、[第236講](../../part18/lecture236/)、[第237講](../../part18/lecture237/) |
| インデクサの構築、続きから読む実装、再編成への対応の手順、何ブロック後に確定とみなすか | [第238講](../../part18/lecture238/) |
| ログを原材料に使う分析と指標 | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| recordLogsを使うテストスイートの構成 | [第258講](../../part20/lecture258/) |
| ログに基づくモニタリング | [第263講](../../part20/lecture263/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
