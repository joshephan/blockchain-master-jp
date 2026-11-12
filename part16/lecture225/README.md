# 第225講 メンプールのモニタリング

第16部 MEVサーチャー実習・第61章 攻撃者の道具

[← 第224講](../../part16/lecture224/) | [第16部 目次](../) | [第226講 →](../../part16/lecture226/)

## この講義の問い

自分の取引はブロックに入る前、待合室で誰に何まで見えているのか。ブロックに入れる順番は誰がどんなルールで決めるのか、そしてそのルールが変わると、同じ取引の組で自分の取引はどうなるのか。

## 実習資料

### 準備

講義用の交換プールToyAmmとトークン二つが入ったFoundryプロジェクト`mev`から始める。依存関係はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`Math`）である。`forge build`でコンパイルしたあと、anvilを2回立ち上げて同じ準備と同じ取引の組を流す。1回は`--order fees`（チップの大きい順）、1回は`--order fifo`（入ってきた順）である。

準備：アカウント0番がトークンA・BとToyAmm（手数料30 = 0.3%）をデプロイし、プールにA 1000 / B 1000を入れる。アカウント1・2番にAを200ずつ渡し、プールの利用を承認する（ここまででブロック12）。続いてJSON-RPCで`evm_setAutomine(false)`、`eth_newPendingTransactionFilter()`を呼び、取引の組を`cast send --async`で送る。

| 名前 | 送ったアカウント | 内容 | maxFee / チップ |
|---|---|---|---|
| h1 | アカウント1番 | swap A 100、受け取る最小量90.2077…（quoteの99.5%）、ガスリミット200,000 | 11 / 1 gwei |
| h2 | アカウント2番 | swap A 50、受け取る最小量0 | 13 / 3 gwei |
| h3 | アカウント3番 | アカウント0番に1 weiを送金 | 12 / 2 gwei |

アカウントはすべてanvilのデフォルトのテスト用アカウントであり、取引はすべて自分のパソコンのanvilで、自分のアカウントどうしだけでやり取りする。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、forge-std・OpenZeppelinのremappings |
| [code/src/ToyAmm.sol](code/src/ToyAmm.sol) | 講義用の定数積プール：addLiquidity、removeLiquidity、getAmountOut、quote、`swap(tokenIn, amountIn, minOut)`（受け取る最小量を下回ると`Slippage(got, minOut)`）、spotPrice |
| [code/src/ToyErc20.sol](code/src/ToyErc20.sol) | 講義用のトークン（approve、transfer、transferFrom、mint） |

### 実行結果

取引の組を送ったあとの`txpool_status`と保留中の取引のフィルター（`eth_getFilterChanges`）：

```
RPC txpool_status        → {'pending': '0x3', 'queued': '0x0'}
RPC eth_getFilterChanges → 0xae1fec45…2dce74   (h1)
                           0x716aa637…a80b66   (h2)
                           0xd40b47e2…cb6ff7   (h3)
```

`txpool_content`は、入ってきた時刻の順ではなく送ったアドレスごとに、同じアドレスの中はナンスの順に見せる：

| 送ったアドレス | ナンス | 宛先 | チップ | inputの先頭4バイト |
|---|---|---|---|---|
| 0x3C44…93BC（アカウント2番） | 1 | プール 0x9fe4…a6e0 | 3 gwei | 0x9f1d0f59 |
| 0x7099…79C8（アカウント1番） | 1 | プール 0x9fe4…a6e0 | 1 gwei | 0x9f1d0f59 |
| 0x90F7…b906（アカウント3番） | 0 | 0xf39f…2266（アカウント0番） | 2 gwei | 0x（空のinput） |

0x9f1d0f59は`swap(address,uint256,uint256)`の関数セレクターである。保留中の取引h1のinputを`cast calldata-decode`でほどくと：

```
$ cast calldata-decode "swap(address,uint256,uint256)" <h1のinput>
0x5FbDB2315678afecb367f032d93F642f64180aa3
100000000000000000000 [1e20]
90207783941074838592 [9.02e19]
```

| | 値（B） |
|---|---|
| いま受け取れる量 `quote(A, 100)` | 90.661089388014913158 |
| 受け取る最小量（99.5%） | 90.207783941074838592 |
| 差 | 0.453305446940074566 |

同じナンスでh3を置き換える二つの試み（`cast send --async --nonce 0`）：

```
$ cast send --async --private-key <アカウント3番> --nonce 0 \
    --gas-price 12000000000 --priority-gas-price 5000000000 <アカウント0番> --value 2
Error: server returned an error response: error code -32003: replacement transaction underpriced

$ cast send --async --private-key <アカウント3番> --nonce 0 \
    --gas-price 15000000000 --priority-gas-price 5000000000 <アカウント0番> --value 2
0x99dea07144ec4472a5887b75a06a494c59d3dd0b9b38ea3cf36d2451a95e0f50   (h3b)

RPC txpool_status → {'pending': '0x3', 'queued': '0x0'}
h3のハッシュで取引を照会 → なし
```

`evm_mine`1回で作った13番ブロック、`--order fees`のほう：

| 順番 | 取引 | チップ | status | 使ったガス |
|---|---|---|---|---|
| 0 | h3b アカウント3番の送金 | 5 gwei | 1 | 21,000 |
| 1 | h2 アカウント2番の交換 A 50 | 3 gwei | 1 | 86,146 |
| 2 | h1 アカウント1番の交換 A 100 | 1 gwei | 0 | 47,273 |

リバートしたh1を`cast run`でもう一度実行した結果：

```
$ cast run 0xae1fec451f1fd5a5729cb4e2b1887572face32ea8e55b77922ea302c7f2dce74
  └─ ← [Revert] Slippage(82600632787954991801 [8.26e19], 90207783941074838592 [9.02e19])
```

h1の順番でのプールの残高はA 1050 / B 952.517026である（h2のA 50が先に入った）。その残高にA 100を入れると受け取りは82.60になり、受け取る最小量90.21に届かない。effectiveGasPriceは1,205,387,712 wei（baseFee 205,387,712 + チップ1 gwei）であり、リバートしても47,273 × 1,205,387,712 = 56,982,293,309,376 wei（約0.000057 ETH）を払う。

同じ準備・同じ取引・同じハッシュで流した`--order fifo`のほう：

| 順番 | 取引 | チップ | status | 使ったガス |
|---|---|---|---|---|
| 0 | h1 アカウント1番の交換 A 100 | 1 gwei | 1 | 86,254 |
| 1 | h2 アカウント2番の交換 A 50 | 3 gwei | 1 | 86,146 |
| 2 | h3b アカウント3番の送金 | 5 gwei | 1 | 21,000 |

終わったあとのプールの残高は、feesのほうがA 1050 / B 952.517026、fifoのほうがA 1150 / B 869.915904である。順番によって、アカウント2番が受け取った量も47.48（feesのほう）と39.42（fifoのほう）に分かれる。

### 試すときの注意

- anvilはデフォルトでは、取引が来るとすぐにブロックを作る。待合室を見るには`evm_setAutomine(false)`で自動マイニングを切り、ブロックは`evm_mine`で自分で作る。
- 保留中の取引のフィルターは、自分の取引だけを選んではくれない。そのノードの待合室に入ってくる保留中の取引を、誰のものでも集めてくる。
- queuedは、前のナンスが空いていて待っている取引である。ナンス0を飛ばしてナンス1を送るとqueuedに行く。
- 同じナンスで置き換えるとき、手数料をどれだけ上げれば受け付けてくれるかはノードの実装ごとに違う。この実習では、maxFee 12のまま・チップ5は拒否（-32003）、maxFee 15・チップ5は受け付けた。
- 受け取る最小量を0で送った交換は、順番が悪く出てもそのまま約定する。受け取る最小量を書いた交換はリバートし、使ったガスの分だけ手数料を払う。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンとノードの実装が変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry | forge・cast・anvil 1.8.3、anvil `--order fees`（チップの大きい順） / `--order fifo`（入ってきた順） | 2026-10-21 |
| solc・設定 | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| 置き換えを拒否する閾値 | ノードの実装ごとに違う。この実習：maxFee 12のまま・チップ5は拒否（-32003）、maxFee 15・チップ5は受け付けた | 2026-10-21 |
| 13番ブロックのbaseFee | 205,387,712 wei（両方で同じ） | 2026-10-21 |
| ガス | feesのほう h3b 21,000 / h2 86,146 / h1 47,273（リバート）、fifoのほう h1 86,254 / h2 86,146 / h3b 21,000 | 2026-10-21 |
| h1が払った手数料 | effectiveGasPrice 1,205,387,712 wei × 47,273 = 56,982,293,309,376 wei（約0.000057 ETH） | 2026-10-21 |
| デモのアドレス | トークンA 0x5FbDB2315678afecb367f032d93F642f64180aa3、トークンB 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512、ToyAmm 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0、アカウント0〜3番はanvilのデフォルトのテスト用アカウント（本物のお金は禁止） | 2026-10-21 |
| デモのハッシュ（両方で同じ） | h1 0xae1fec451f1fd5a5729cb4e2b1887572face32ea8e55b77922ea302c7f2dce74、h2 0x716aa637ed8b62883e84525f81d27340fc420737e573478482cab5bc38a80b66、h3 0xd40b47e26e95a2bba3ccf115f20d42e588e26d122ec71f374ee3000b7cbb6ff7、h3b 0x99dea07144ec4472a5887b75a06a494c59d3dd0b9b38ea3cf36d2451a95e0f50 | 2026-10-21 |
| 委任の印があるEOAの保留中の取引 | EIP-7702 "Transaction propagation"節：委任の印があるEOAは保留中の取引を一つだけ受け付けるようクライアントに勧めている（"the authors recommend that clients do not accept more than one pending transaction for any EOA with a non-zero delegation indicator"） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 委任の印があるEOAの保留中の取引の扱い（EIP-7702原文の該当節） | 時効性のあるデータ |
| ブロックを作る側が待合室の外で取引を受け取る道 | [第227講](../../part16/lecture227/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
