# 第243講 Dune SQLの基礎

第18部 インフラ運用とデータ・第67章 オンチェーンデータ分析

[← 第242講](../../part18/lecture242/) | [第18部 目次](../) | [第244講 →](../../part18/lecture244/)

## この講義の問い

チェーンのデータをSQLで尋ねるとは、何を尋ねることなのか。その表は誰がどうやって作り、表に何が入っていて何が抜けているのか。ログ1行を人が読める列に変えるには、ほかに何が必要なのか。

## 実習資料

### 準備

分析サービスには接続せず、ローカルのanvilにおもちゃの7日間（2026-10-01〜07）を作ったあと、そのブロック・取引・ログを、Duneの元の表（blocks、transactions、logs）とデコードされた表（`<プロジェクト>_evt_<イベント>`）と同じ形のローカルの表に移してSQLを実行した。チェーンに載せたコントラクトは、通しプロジェクトMarket（第53章の最終バージョン、第199講のバージョンと同じソース）と講義用のおもちゃのコントラクトである。ビルドにはforge-stdのremapping 1行だけがあり、テストはない。

シナリオ（ブロック1〜46、取引46件）：

| 日付 | ブロック | 出来事 |
|---|---|---|
| 10-01 | 1〜19 | TKAのデプロイ、Marketのデプロイ（管理者はアカウント0番）、addAsset(TKA, 75)、Impl67A・B、SlotProxy（実装A）、mint・approve、u1 100・u2 200・u3 150の預け入れ |
| 10-02 | 20〜23 | u4 300・u5 3,000・u1 50の預け入れ、u2 50の引き出し |
| 10-03 | 24〜26 | u3の預け入れ0がリバート、u1 30の引き出し、u4 100の預け入れ |
| 10-04 | 27〜30 | u2がTKA 50をMarketに直接transfer、Echo67のデプロイ・Deposited 1行、u3 80の預け入れ |
| 10-05 | 31〜39 | FEEのデプロイ（移すときに1%）、addAsset(FEE, 50)、u1 FEE 100・u2 FEE 200・u4 TKA 40の預け入れ |
| 10-06 | 40〜43 | u5 2,500・u4 200の引き出し、setStatus(DepositPaused)、SlotProxy upgradeTo（実装B） |
| 10-07 | 44〜46 | u2 FEE 200の引き出し、u1 FEE 100の引き出しがリバート、u3 TKA 50の引き出し |

日付は、anvilの`--timestamp`と`evm_setNextBlockTimestamp`で決めたおもちゃの時刻である。

### コード

| ファイル | 内容 |
|---|---|
| [code/src/Toy67.sol](code/src/Toy67.sol) | 講義用のトークンToyToken67（TKAと、移すときに1%を引くFEEを同じソースでデプロイ）、Marketと同じ形のDepositedログだけを出すEcho67、プロキシの後ろに置く実装Impl67A・Impl67B |
| [code/src/SlotProxy.sol](code/src/SlotProxy.sol) | EIP-1967のスロットに実装・管理者のアドレスを置くテスト用のプロキシ（アップグレード時にUpgradedログ） |
| [code/src/](code/src/) | Market、IMarket、MarketMath、MarketTypes、MockToken（第53章の最終バージョンそのまま） |
| [code/foundry.toml](code/foundry.toml) | ビルド設定（solc 0.8.30、optimizer 200、via-IR、osaka、forge-stdのremapping） |

クエリ（SQL）は[code/sql/q243.sql](code/sql/q243.sql)、[code/sql/q243b.sql](code/sql/q243b.sql)にある。各行の`-- [243-1]`の形の見出しコメントが、下の実行結果のクエリ番号と対応する。ローカルの表の名前（`anvil.*`、`market67_anvil.*`）はDuneの元の表・デコードされた表の位置をまねたもので、アドレスを名前に変えて見せる`who()`は、ローカルの実行ツールに置いた補助関数である。

### 実行結果

デコードされた表で申請したコントラクト（Market、TKA、SlotProxy）と、表ごとの行数。表は、イベントのシグネチャのtopic0とアドレスで選んで作る。借り入れ・清算が入った今のバージョンなのでMarketの表は十個で、この7日間には借りる取引がないので、新しい表六つは0行である。出力は元の実行結果の文字列だけを訳したもの。

```
market67_anvil.Market_evt_AssetAdded  <- AssetAdded(address,uint8) 0x57c9e281…  アドレス Market  2行
market67_anvil.Market_evt_BadDebtWrittenOff  <- BadDebtWrittenOff(address,address,uint256) 0x9c91e380…  アドレス Market  0行
market67_anvil.Market_evt_Borrowed  <- Borrowed(address,address,uint256) 0x3fc499ae…  アドレス Market  0行
market67_anvil.Market_evt_CollateralSet  <- CollateralSet(address,address,bool) 0x480e3bc8…  アドレス Market  0行
market67_anvil.Market_evt_Deposited  <- Deposited(address,address,uint256) 0x8752a472…  アドレス Market  11行
market67_anvil.Market_evt_Liquidated  <- Liquidated(address,address,address,address,uint256,uint256) 0xda828cf6…  アドレス Market  0行
market67_anvil.Market_evt_PriceFeedSet  <- PriceFeedSet(address,address) 0xd2d8394c…  アドレス Market  0行
market67_anvil.Market_evt_Repaid  <- Repaid(address,address,uint256) 0x0a3fbbea…  アドレス Market  0行
market67_anvil.Market_evt_StatusChanged  <- StatusChanged(uint8,uint8) 0xe1377aa2…  アドレス Market  1行
market67_anvil.Market_evt_Withdrawn  <- Withdrawn(address,address,uint256) 0xd1c19fbc…  アドレス Market  6行
toy67_anvil.ToyToken67_evt_Approval  <- Approval(address,address,uint256) 0x8c5be1e5…  アドレス TKA  5行
toy67_anvil.ToyToken67_evt_Transfer  <- Transfer(address,address,uint256) 0xddf252ad…  アドレス TKA  20行
proxy67_anvil.SlotProxy_evt_Upgraded  <- Upgraded(address) 0xbc7cd75a…  アドレス SlotProxy  2行
```

[243-1]〜[243-4] 元の表。blocksは、取引のない最初のブロック0まで含めて47行である。リバートした取引はtransactionsにはあり、logsにはない。Depositedのtopic0だけで数えると、Echo67が出した行（金額1,000,000）が混ざる。topic1・topic2は後ろ20バイトがアドレス、data 32バイトが金額である。出力は元の実行結果の文字列だけを訳したもの。

```
-- [243-1] 表三つの行数
blocks | transactions | logs
-------+--------------+-----
47     | 46           | 58

-- [243-2] リバートした取引: transactionsにはあってlogsにはない
block_number | block_time          | sender | to     | success | gas_used | log_count
-------------+---------------------+--------+--------+---------+----------+----------
24           | 2026-10-03 09:00:00 | u3     | Market | 0       | 26356    | 0
45           | 2026-10-07 11:00:00 | u1     | Market | 0       | 54379    | 0

-- [243-3] 元のlogsでDepositedのtopic0だけで数えると(アドレスで絞らない)
emitter | n  | amount_sum
--------+----+-----------
Echo67  | 1  | 1000000
Market  | 11 | 4320

-- [243-4] 同じログを手でほどく: topic1・topic2は後ろ20バイトがアドレス、data 32バイトが金額
block_number | asset | user | amount
-------------+-------+------+-------
17           | TKA   | u1   | 100
18           | TKA   | u2   | 200
19           | TKA   | u3   | 150
20           | TKA   | u4   | 300
21           | TKA   | u5   | 3000
```

[243-5]〜[243-6] デコードされた表。申請したアドレスのログだけが入っているので、Echo67の行がない。日付はブロックの時刻でまとめる。出力は元の実行結果の文字列だけを訳したもの。

```
-- [243-5] デコードされた表: 申請したアドレスのログだけが入っている
contract | asset | n | amount_sum
---------+-------+---+-----------
Market   | TKA   | 9 | 4020
Market   | FEE   | 2 | 300

-- [243-6] 日付ごとの預け入れ件数と金額(ブロック時刻の日付でまとめる)
day        | asset | n | amount
-----------+-------+---+-------
2026-10-01 | TKA   | 3 | 450
2026-10-02 | TKA   | 3 | 3350
2026-10-03 | TKA   | 1 | 100
2026-10-04 | TKA   | 1 | 80
2026-10-05 | TKA   | 1 | 40
2026-10-05 | FEE   | 2 | 300
```

[243-7]〜[243-8] 表に欄がないもの。トークンのシンボルは、デプロイ取引のdataの末尾のコンストラクタ引数からバイトで読む。TKAとFEEは同じソースだが、immutableの手数料の値がランタイムコードに埋め込まれ、長さは1,623バイトで同じでも、952番目・1297番目のバイト（1から数える、TKA 0x00 / FEE 0x64）が違うので同じではない（same 0）。出力は元の実行結果の文字列だけを訳したもの。

```
-- [243-7] デプロイ取引のdataの末尾に付いたコンストラクタ引数からトークンシンボルを読む: 最後の32バイトの欄の先頭3バイトが文字のバイト
block_number | deployer | data_len | str_len | str_bytes | symbol
-------------+----------+----------+---------+-----------+-------
1            | admin    | 2344     | 3       | 0x544b41  | TKA
31           | admin    | 2344     | 3       | 0x464545  | FEE

-- [243-8] 同じソースで作った二つのトークンのランタイムコード: 長さと違うバイトの数
a   | b   | len_a | len_b | same
----+-----+-------+-------+-----
TKA | FEE | 1623  | 1623  | 0
```

Duneは、バイトコードが100%同じときだけ、同じコントラクトの別のインスタンスとみなす。だから、TKAのアドレスだけを申請すると`ToyToken67_evt_Transfer`は20行で、FEEも別に申請すると28行である。

### 試すときの注意

- デコードされた表は、申請したアドレスのログだけを入れる。同じソースでデプロイした別のアドレス（FEE）は、別に申請しないと入らない。
- 失敗した取引はログがないので、ログの表だけを見ると試みそのものが見えない。失敗を数えるには、transactionsの表のsuccessの欄を見る。
- varbinaryのバイトの位置は、DuneSQLの関数と同じように1から数える。
- ガスの値は、ローカルのanvil、第53章の最終バージョンのMarketを基準にしている。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | 2026-10-21 |
| solc | 0.8.30 (optimizer 200、via-IR、osaka) | 2026-10-21 |
| Duneの公式ドキュメント | docs.dune.comの各ページの`.md`版（raw blocks・transactions・logs、decoded overview・event logs・call tables・contracts、decoding contracts、query engine、varbinary関数） | 2026-10-21 |
| DuneSQLの実行エンジン | ドキュメントの文言 "DuneSQL, a Trino fork" | 2026-10-21 |
| デコードの処理時間 | ドキュメントの文言 "Decoding usually takes about 24 hours, in special cases it might take longer." | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 指標の設計（帳簿の残高、金庫の残高、集中、失敗の指標） | [第244講](../../part18/lecture244/) |
| 関数の呼び出しをほどくcallの表（`_call_`）とtraces | 付録 |
| 表を作った側がブロックの再編成をどう扱うか | データの行 |
| 同じtopic0を別のアドレスが出した行を探すクエリ | [第246講](../../part18/lecture246/) |
| リバートのデータを再実行して読む | [第246講](../../part18/lecture246/) |
| 実在するプロトコルのクエリとダッシュボード | 入れない |

出典と参考資料は[reference.md](reference.md)にまとめた。
