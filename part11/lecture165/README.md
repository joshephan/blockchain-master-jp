# 第165講 不変性・透明性・決定性

第11部 推奨事項：敵対的環境とバージョン履歴・第43章 敵対的環境の法則と5つの軸

[← 第164講](../../part10/lecture164/) | [第11部 目次](../) | [第166講 →](../../part11/lecture166/)

## この講義の問い

チェーンの上では、なぜバグ一つがそのままお金を失うことになるのか。チェーンが決めている三つの法則は何で、その三つが攻撃する側に何を握らせるのか。

## 実習資料

### 準備

通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）を、コードもテストもそのまま使う。ローカルのanvilノードを三つ（A・Bは同じ開始時刻、Cは1秒遅い開始時刻）立ち上げ、ブロック間隔を1秒に固定して、取引一つがブロック一つになるようにする。デプロイは`forge create`、取引と照会は`cast`で行う。アカウント0番〜2番はanvilの公開されたテスト用アカウントで、秘密鍵はコマンドに書かずunlockedアカウントとして送る。外部への接続はない。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka、ガスの記録の確認 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | レンディング市場の本体（addAsset、setStatus、deposit、withdrawなど） |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | 金額型の演算と利息計算のライブラリ |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | Amount・Rate・Ratio型と構造体 |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | Marketのインターフェース |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | デモ用のトークン |
| [code/market/test/](code/market/test/) | 第42章の終わりのバージョンのテストすべて。直接送ったトークンが帳簿の外に残るテストは[Donation.t.sol](code/market/test/Donation.t.sol) |

### 実行結果

ノードAに入れた取引八つ（ブロック1〜8）とガス：

| ブロック | 送ったアカウント | 取引 | 結果 | ガス |
|---|---|---|---|---|
| 1 | 0番 | MockTokenのデプロイ | 0x5FbDB2315678afecb367f032d93F642f64180aa3 | 211,593 |
| 2 | 0番 | Marketのデプロイ（管理者0番、5e16、80） | 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 | 760,316 |
| 3 | 0番 | addAsset（トークン、75） | 成功 | 92,656 |
| 4 | 0番 | トークン200をアカウント1番へ | 成功 | 51,411 |
| 5 | 0番 | deposit 100 | 成功 | 127,515 |
| 6 | 1番 | deposit 50 | 成功 | 93,315 |
| 7 | 2番 | setStatus(2) | 失敗 | 21,510 |
| 8 | 0番 | Marketのアドレスへトークン10を直接送る | 成功 | 34,311 |

Marketのコードのkeccak（`cast keccak $(cast code <Market>)`）。コードの長さは3,260バイトで、三回とも同じである：

```
ブロック2（デプロイ直後）  0x1f283f933a08e9f3b55bf2af69dfa1af6d3d2384cf78bae072b1d8c0d1cf9cb8
ブロック8（取引八つのあと） 0x1f283f933a08e9f3b55bf2af69dfa1af6d3d2384cf78bae072b1d8c0d1cf9cb8
ブロック9（withdraw 20のあと） 0x1f283f933a08e9f3b55bf2af69dfa1af6d3d2384cf78bae072b1d8c0d1cf9cb8
```

アカウント2番のsetStatus(2)を`cast call`で先に走らせた結果と、7番ブロックに入った失敗取引のレシート（`cast receipt --json`から選んだ欄）：

```
Error: execution reverted: NotAdmin(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)

blockNumber  7
status       0x0
logs         0個
from         0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc
```

失敗のあともstatusの欄は0（Active）のままである。取引とブロック番号、払ったガス、失敗したという結果は残り、状態の変更とイベントは残らない。

直接送ったトークン10。`totalDeposits(トークン)`とMarketのトークンの`balanceOf`：

```
150
160
```

withdraw 20のあとは帳簿130、トークン140である。帳簿の外の10を取り出す関数はMarketにない。

何の権限もないアカウント2番が読んだアカウント1番の`positions(トークン, アカウント1番)`（預けた量、借りた量、最後の更新時刻、担保に使うかどうか）：

```
50
0
1767225606 [1.767e9]
false
```

同じ値をスロット計算で直接読んだ結果（`cast index address <トークン> 3`、その値で再び`cast index address <アカウント1番> ...`、`cast storage`）：

```
0x835e38f0832364c68c1db3e8485c5a079d31ca20e910af006fd438c39d06286c
0x0000000000000000000000000000000000000000000000000000000000000032
```

automineを切ってアカウント1番が`--async`で送ったwithdraw 20は、ブロックに入る前でも見える。`txpool_status`、`cast tx`のblockNumber（空欄）とfrom：

```
{"pending":"0x1","queued":"0x0"}

0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

その取引のinputと、アカウント2番が`cast calldata-decode "withdraw(address,uint256)"`で解いた値：

```
0xf3fef3a30000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3
  0000000000000000000000000000000000000000000000000000000000000014

0x5FbDB2315678afecb367f032d93F642f64180aa3
20
```

この取引は9番ブロックに入り、status 1、ガス57,448で終わった。

同じ取引を同じ順番で入れたノード三つのブロック9：

| | ノードA | ノードB | ノードC |
|---|---|---|---|
| 開始時刻 | 1767225600 | 1767225600 | 1767225601 |
| stateRoot | 0x10ee34f8…d516 | 0x10ee34f8…d516 | 0x9b331a68…f17c |
| ブロックハッシュ | 0xa226a289…30df | 0xa226a289…30df | 0xa87f2438…7d8e |
| totalDeposits | 130 | 130 | 130 |
| アカウント1番のlastUpdate | 1767225609 | 1767225609 | 1767225610 |

ノードCは帳簿の量は同じだが、withdrawが書いたblock.timestampが1大きいのでstateRootが分かれる。

送る前に`cast call --from <アカウント1番>`で走らせてみたwithdraw 20とwithdraw 1000：

```
0x
Error: execution reverted: InsufficientDeposit(50, 1000)
```

### 試すときの注意

- anvilを同じ`--timestamp`で立ち上げ、ブロック間隔を1秒に固定しないと、ノード同士でstateRootが同じにならない。開始時刻が1秒違うだけでstateRootが変わる。
- ブロック前の取引を見るには、automineを切って（`evm_setAutomine false`）`cast send --async`で送ったあと、`evm_mine`でブロックを作る。
- アカウント2番のsetStatusは、`cast call`で先に走らせると`NotAdmin`が出るが、実際に送るとブロックに失敗取引として残り、ガスを払う。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンや実行環境が変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| solc | 0.8.30、Market第42章の終わりのバージョンの既定プロファイル（via-IR + optimizerオン runs 200） | 2026-10-20 |
| anvilの開始時刻 | ノードA・B `--timestamp 1767225600`（2026-01-01 00:00:00 UTC）、ノードC 1767225601、ブロック間隔1秒 | 2026-10-20 |
| アドレス | MockToken 0x5FbDB2315678afecb367f032d93F642f64180aa3、Market 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512（アカウント0番のnonce 0・1） | 2026-10-20 |
| Marketのコード | runtime 3,260バイト、keccak 0x1f283f933a08e9f3b55bf2af69dfa1af6d3d2384cf78bae072b1d8c0d1cf9cb8（ブロック2・8・9で同じ） | 2026-10-20 |
| ガス | MockTokenのデプロイ211,593、Marketのデプロイ760,316、addAsset 75 92,656、トークン200の送付51,411、deposit 100 127,515、アカウント1番のdeposit 50 93,315、アカウント2番のsetStatus(2)失敗21,510、トークン10の直接送付34,311、withdraw 20 57,448 | 2026-10-20 |
| ブロック9 | ノードA・B stateRoot 0x10ee34f8546c8622897ce5904914fa4986451b4f4f1d164248b605cf3cafd516、ブロックハッシュ0xa226a289300177975fbb316381c40c69a98066773b50a4bcaec842d4da8330df、timestamp 1767225609。ノードC stateRoot 0x9b331a686186f011c2b195d83b54946b3b6217cab38c8b89b15afaf98f0ef17c、ブロックハッシュ0xa87f2438cad0a5642a37360feaf1e713dfbe91985400dd1d13cb074036dc7d8e、timestamp 1767225610 | 2026-10-20 |
| positionsのスロット | 0x835e38f0832364c68c1db3e8485c5a079d31ca20e910af006fd438c39d06286c（トークン、アカウント1番） | 2026-10-20 |
| エラー | InsufficientDepositのセレクタ0x25c3f46e、NotAdmin(0x3C44…93BC) | 2026-10-20 |
| EIP-6780 | selfdestructの動作変更、2024年3月のCancunハードフォーク | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ブロック前の取引を見て先に入ること | [第172講](../../part11/lecture172/) |
| ブロックの時刻をブロックを作る側が決められる範囲とオンチェーンの乱数 | [第172講](../../part11/lecture172/)、[第175講](../../part11/lecture175/) |
| チェーンのルールを変えて状態を戻した事件 | [第168講](../../part11/lecture168/) |
| 帳簿の外に入ってきたトークンと標準と違う動きで移すトークン | [第171講](../../part11/lecture171/) |
| 事件を三つの法則で分け直す | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
