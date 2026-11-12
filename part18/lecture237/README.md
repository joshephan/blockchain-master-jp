# 第237講 信頼の前提の移動

第18部 インフラ運用とデータ・第64章 ノードとRPC

[← 第236講](../../part18/lecture236/) | [第18部 目次](../) | [第238講 →](../../part18/lecture238/)

## この講義の問い

RPCがくれた値をそのまま信じないためには、何を確かめるのか。確かめれば信じる相手は消えるのか、それとも移るのか。自分のノードを動かせば、何も信じなくてよくなるのか。

## 実習資料

### 準備

第236講のバージョン（第53章の最終バージョンのMarket + `ops/market_read.py`）に、運用ツールの二つ目のバージョンを加えたバージョンから始める。Marketのコントラクトとテストは第199講のバージョンと同じである。この講義で加えたのは`ops/mpt.py`と`ops/market_verify.py`である。テストにはforge-stdが必要である（`lib/forge-std`）。運用ツールはPythonの標準ライブラリだけを使う（keccakも自前で実装）。

デモはローカルのanvil二台で行った。ノードAにはMarketのデプロイ、預け入れ100、引き出し30を、ノードCには同じ順番で預け入れ1000を送り、互いに違うチェーンを作る。デプロイの順番が同じなので、二つのチェーンのMarketのアドレスは同じである。メインネットの値は、公開RPCに読み取りのリクエストだけを一度送って受け取った値である（時効性のあるデータ）。

### コード

| ファイル | 内容 |
|---|---|
| [code/ops/mpt.py](code/ops/mpt.py) | keccak-256、RLPのエンコード・デコード、ブロックヘッダーのハッシュの再計算（`header_hash`）、マークル・パトリシア・トライの証明をたどる（`mpt_get`、`verify_account`、`verify_storage`） |
| [code/ops/market_verify.py](code/ops/market_verify.py) | Marketの運用ツールの二つ目のバージョン。RPC一つがくれたtotalDepositsを、信頼するブロックハッシュ → ブロックヘッダー → ステートルート → `eth_getProof`の証明の順に確かめる。確かめられれば終了コード0、ずれていれば1 |
| [code/ops/market_read.py](code/ops/market_read.py) | 第236講の運用ツールの最初のバージョン（そのまま） |
| [code/foundry.toml](code/foundry.toml) | ビルド設定（solc 0.8.30、optimizer 200、via-IR、osaka） |
| [code/src/](code/src/) | Market、IMarket、MarketMath、MarketTypes、テスト用のMockToken（第199講のバージョンそのまま） |
| [code/test/](code/test/) | 基準バージョンのテスト（136個） |

使い方：`python -I ops/market_verify.py <Market> <資産> <RPC> <信頼するブロックハッシュ>`。信頼するブロックハッシュは、ツールの外で決めて渡す。totalDepositsの欄の番号は`TOTAL_DEPOSITS_SLOT = 4`（`forge inspect src/Market.sol:Market storageLayout`：totalDeposits 4、totalBorrows 5、reserves 6、priceConfig 7）。

### 実行結果

二つのチェーンの最新のブロックと、totalDeposits[資産]のストレージの欄の位置：

```
A 最新 5 0xebfc4997dc1558c834f8f94518989c878d0a12a00c2072894823c58f365ebe4e stateRoot 0xbf41797bd7e486a4a110fb9510a652103a481acf55bc78a5fc043d1d42937275
C 最新 5 0xd1adbaf6858346893ddac99ede7b4d50427ee14afa74af970e3268aedf8c39f6 stateRoot 0x0e541673543cf7a05511852fd1b5c142ac1476e7cf189fa0b58c21a2c5dc0b8d
totalDeposits[資産] スロット 0xa682d4351e4703267af382c1795a1188b87c4920f0c38d599cb6cba0b8fec1cb
```

`market_verify.py`を6通りに実行した結果。AにAのハッシュで尋ねると確かめられ、CにAのハッシュで尋ねると、そのブロックを知らないと言って止まる。CにCが教えたハッシュで尋ねると、970が「確認済み」と出る。証明は、信頼するハッシュが指すチェーンの中で合っているかどうかだけを教えてくれる。

```
== C1 Aに、Aのブロックハッシュで
1) ブロックヘッダーのハッシュ: 同じ (ブロック 5、ステートルート 0xbf41797bd7e4…)
2) 証明: ステートルートまでつながる (アカウントノード 2個、ストレージスロットのノード 2個)
3) totalDeposits: 証明の値 70、eth_callの答え 70 -> 同じ
結果: 確認済み
終了コード 0
== C2 Cに、Aのブロックハッシュで
1) ブロックヘッダー: 不明 (このRPCにそのハッシュのブロックなし)
終了コード 1
== C3 Cに、Cが教えたハッシュで
1) ブロックヘッダーのハッシュ: 同じ (ブロック 5、ステートルート 0x0e541673543c…)
2) 証明: ステートルートまでつながる (アカウントノード 2個、ストレージスロットのノード 2個)
3) totalDeposits: 証明の値 970、eth_callの答え 970 -> 同じ
結果: 確認済み
終了コード 0
== C4 Cがくれた証明をAのヘッダーのステートルートに当てる
失敗: 証明ノードのハッシュが上のノードが指す値と違う
== C5 Cのヘッダーのステートルートだけを、Aのヘッダーに入れ替えてハッシュを計算し直す
計算したハッシュ 0x0623e75c597760c79c2d6cc60985804f64bc7b91c82be9f91373010722d2043c Aのブロックハッシュと同じ False
== C6 スロット番号を5（totalBorrowsの欄）と間違えて書いたバージョンでAに
1) ブロックヘッダーのハッシュ: 同じ (ブロック 5、ステートルート 0xbf41797bd7e4…)
2) 証明: ステートルートまでつながる (アカウントノード 2個、ストレージスロットのノード 2個)
3) totalDeposits: 証明の値 0、eth_callの答え 70 -> 違う
結果: ずれ
終了コード 1
```

メインネットの公開ノードで、最新のブロックヘッダーをまとめ直してハッシュを計算した結果と、WETHの証明（読み取りのリクエストのみ）。出力は元の実行結果の文字列だけを訳したもの。

```
clientVersion reth/v2.7.0-3d592ec/x86_64-unknown-linux-gnu
ブロック 26235741 0xd919cfd00dc96f6f48095688c3ca7aaa8086aa4a3b6d273d310d5e88322e67b3
ヘッダーの欄 ['baseFeePerGas', 'blobGasUsed', 'difficulty', 'excessBlobGas', 'extraData', 'gasLimit',
        'gasUsed', 'logsBloom', 'miner', 'mixHash', 'nonce', 'number', 'parentBeaconBlockRoot',
        'parentHash', 'receiptsRoot', 'requestsHash', 'sha3Uncles', 'stateRoot', 'timestamp',
        'transactionsRoot', 'withdrawalsRoot']
計算したハッシュが同じ True
accountProof ノード 9 storageProof ノード 7
RPCが言ったbalanceと同じ True
スロット 0 証明の値 0x577261707065642045746865720000000000000000000000000000000000001a 文字 Wrapped Ether
```

1ブロック前の証明を求めると、この公開ノードは拒否した。出力は元の実行結果の文字列だけを訳したもの。

```
eth_getProof(WETH, [0x0], ブロック 26235740)
→ {'code': -32602, 'message': 'distance to target block exceeds maximum proof window'}
```

テストは`forge test --offline`で136個がすべて通る。

### 試すときの注意

- ブロックヘッダーの欄のリストは、ハードフォークごとに後ろに付いて増えていく。`mpt.py`の`HEADER_FIELDS`は、RPCの応答にある欄だけを順番に入れる。欄が一つ抜けたり順番が違ったりすると、ハッシュが合わない。
- 第197講のバージョンから、totalDepositsの欄には利子の指数で割った持ち分が入る。このデモは借りた人がいないので指数が1で、持ち分とトークンの量が同じである。
- 欄の番号を間違えて書くと、証明は問題なくつながり、値だけが間違う（C6）。欄の番号は`forge inspect … storageLayout`で確かめて定数にしておく。
- ブロックハッシュとステートルートは実行するたびに違うことがある。判定と値（70、970、0）は同じである。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（anvil・cast・forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| 公開RPC | ethereum-rpc.publicnode.com、clientVersion reth/v2.7.0-3d592ec | 2026-10-20 18:59 UTC |
| メインネットのブロック | 26,235,741、ハッシュ0xd919cfd0…67b3、ヘッダーの欄21個（requestsHashまで、ブロックアクセスリストの欄はなし） | 2026-10-20 18:59 UTC |
| WETHの証明 | accountProofのノード9、storageProofのノード7、nonce 1、残高2206721042920693149231029 wei、codeHash 0xd0a06b12…5e23、スロット0 "Wrapped Ether" | 2026-10-20 18:59 UTC |
| 公開ノードの証明のウィンドウ | 最新のブロックの証明だけを返す。1ブロック前・finalizedのブロックは"distance to target block exceeds maximum proof window" | 2026-10-20 |
| gethの過去のブロックの証明 | v1.16.xのアーカイブは過去のブロックのeth_getProofができない、v1.17.xから`history.trienode`を設定するとできる | 2026-10-16 |
| ライトクライアント | Lodestar（TypeScript）、Helios（Rust）、Gethのライトモード（開発中）、Nimbus（Nim）。名前のみ、推薦ではない | 2026-10-20 |
| 同期委員会（sync committee） | バリデーター512人、約1.1日ごとにランダムに交代、3分の2の署名 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 分岐して合流したブロックで、受け取った記録を直す | [第238講](../../part18/lecture238/) |
| 確認ツールを定期的に動かし、ずれたら知らせる | [第241講](../../part18/lecture241/) |
| ライトクライアントを自分で立ち上げてRPCの前に置く | 付録のデータシート（名前まで） |
| 同期委員会の署名を確かめる手順 | 付録 |
| システム全体で信じている所を層ごとに書く | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
