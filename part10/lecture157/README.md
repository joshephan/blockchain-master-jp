# 第157講 ERC-1155とバッチ処理

第10部 標準とアップグレード・第41章 標準の設計思想

[← 第156講](../../part10/lecture156/) | [第10部 目次](../) | [第158講 →](../../part10/lecture158/)

## この講義の問い

いくつもの種類のトークンを一つのコントラクトに置き、まとめて移すと、何が節約でき、何が一緒にまとめられてしまうのか。

## 実習資料

### 準備

プロジェクトは二つある。`demo`は、OpenZeppelinのERC1155にidを一度に発行するmintRangeを足したMultiトークン、受け取る関数のないNoHook、第154講のStdToken、Marketのソースのコピー（`src/market/`）を置いたデモ用プロジェクトである。`market`は通しプロジェクトMarketの第157講のバージョンである。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0である。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。まとめての送信のガスはローカルのanvil 1.8.3で既定のテスト用アカウントを使って測り、受け取るアドレスは`0x…0C0FFEE001`から一つずつ増やした新しいアドレス（コードなし）を使った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/Multi.sol](code/demo/src/Multi.sol) | OpenZeppelin 5.4.0のERC1155 + mintRange、受け取る関数のないNoHook |
| [code/demo/src/StdToken.sol](code/demo/src/StdToken.sol) | 第154講のStdToken（ERC-20のコントラクト五つとの比較用） |
| [code/demo/src/market/](code/demo/src/market/) | Marketのsrcの五つのファイルのコピー（MultiをMarketに当ててみるテスト用） |
| [code/demo/test/Batch.t.sol](code/demo/test/Batch.t.sol) | balanceOfBatch、まとまり全体の巻き戻し、NoHook・Holder、オペレーターの承認、TransferBatchのログ、セレクタ、MarketにMultiを当てるテスト七つ |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第157講のバージョンのsrcの五つのファイル。コードは第156講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/Multi.t.sol](code/market/test/Multi.t.sol) | 第157講で足したテスト用のMiniMultiとMultiTestの一つ（ERC-1155のアドレスのdepositの巻き戻し） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

残高の欄が二重なので、同じ名前のbalanceOfでもセレクタが違う：

| 標準 | balanceOf | セレクタ |
|---|---|---|
| ERC-20 | `balanceOf(address)` | `0x70a08231` |
| ERC-1155 | `balanceOf(address,uint256)` | `0x00fdd58e` |

ERC-1155の関数六つ（`cast sig`、test_selectors）。transferFrom・approve・allowance・totalSupplyはない：

| 関数 | セレクタ |
|---|---|
| safeTransferFrom(address,address,uint256,uint256,bytes) | `0xf242432a` |
| safeBatchTransferFrom(address,address,uint256[],uint256[],bytes) | `0x2eb2c2d6` |
| balanceOf(address,uint256) | `0x00fdd58e` |
| balanceOfBatch(address[],uint256[]) | `0x4e1273f4` |
| setApprovalForAll(address,bool) | `0xa22cb465` |
| isApprovedForAll(address,address) | `0xe985e9c5` |

`demo`で`forge test --offline -vv`のtest_balanceOfBatch。setUpで`mintRange(alice, 5, 100)`によりid 1〜5を100ずつ発行し、(alice, 1)、(alice, 5)、(bob, 1)を一度に読んだ：

```
[PASS] test_balanceOfBatch() (gas: 29747)
Logs:
  100 100 0
```

ローカルのanvilでアカウント1番にid 1〜20を100ずつ発行し、id 1〜Nを一個ずつまとめて1回（`safeBatchTransferFrom`）と、一つずつN回（`safeTransferFrom`）とを比べた。受け取るアドレスは毎回はじめて受け取るアドレスである：

| N | まとめて1回 | 一つずつN回の合計 | 差 |
|---|---|---|---|
| 1 | 60,399 | 58,645 | まとめた方が1,754多い |
| 5 | 181,754 | 293,225 | 111,471の節約 |
| 20 | 630,959 | 1,172,900 | 541,941の節約 |

一つずつの場合は毎回58,645である。比較として、ERC-20のコントラクト五つにtransfer 1ずつ送ると260,670（52,134 × 5）である。まとまりにidを一つ足すたびに(630,959 − 181,754) ÷ 15 ≈ 29,900が増え、その大部分は受け取る側の残高の欄にはじめて書く費用である。

五つ目だけに残高（100）より多い101を入れたまとまり（test_batchAllOrNothing）。`0x03dee4c5`は`ERC1155InsufficientBalance(address,uint256,uint256,uint256)`で、引数はalice、残高100（0x64）、送ろうとした101（0x65）、id 5である。まとまり全体が巻き戻り、bobのid 1は0、aliceのid 1は100のままである：

```
[PASS] test_batchAllOrNothing() (gas: 189404)
Logs:
  0x03dee4c500000000000000000000000000000000000000000000000000000000000a11ce000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000650000000000000000000000000000000000000000000000000000000000000005
```

同じまとまり（10、10、10、10、101）をローカルのanvilに`--gas-limit 300000`で送ったレシートと、そのあとの残高。3番のブロックに入ってstatus 0、使ったガス145,100、ログ0個である：

```
bad batch status/gas (0, 145100)
bad receipt logs 0 blockNumber 3
after bad: acc1 id 1 100 acc2 0
after bad: acc1 id 5 100 acc2 0
```

受け取る関数のないNoHookにsafeTransferFrom(id 1, 10)を送ると、`0x57f447ce`（`ERC1155InvalidReceiver(address)`、引数はNoHookのアドレス）で巻き戻る。OpenZeppelinのERC1155Holderを継承したHolderには同じ移動が成功し、id 1の残高が10になる：

```
[PASS] test_noHookReverts() (gas: 620740)
Logs:
  0x57f447ce000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a
```

受け取る関数二つが返す4バイト：

| 受け取る関数 | 返す4バイト | 呼ばれるとき |
|---|---|---|
| onERC1155Received(address,address,uint256,uint256,bytes) | `0xf23a6e61` | safeTransferFromの最後 |
| onERC1155BatchReceived(address,address,uint256[],uint256[],bytes) | `0xbc197c81` | safeBatchTransferFromの最後 |

オペレーターの承認1回で、五つのidの100ずつをすべて移す（test_operatorAll）。承認には金額の欄もidの欄もない：

```
[PASS] test_operatorAll() (gas: 272618)
```

TransferBatchとTransferSingleのログ（test_batchLog：五つのidのまとまりを1回、id 1を一つ1回）：

```
[PASS] test_batchLog() (gas: 281280)
Logs:
  logs 1 topics 4
  data bytes 448
  0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
  single data bytes 64
  0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
```

TransferBatchのtopics四つはtopic0、operator、from、toである。data 448バイトは、配列二つの位置の欄2 + `_ids`の長さ1 + id五つ + `_values`の長さ1 + 値五つ = 14欄 × 32バイトである。TransferSingleのdataはid一つ + 値一つ = 64バイトである。

ERC-721と並べると：

| | ERC-721 | ERC-1155 |
|---|---|---|
| 受け取る側を呼ばない移動 | transferFromあり | なし |
| 受け取る関数のないコントラクトに入れる | transferFromで入って閉じ込められる | 標準の移動では入らない |
| 受け取る側が止められる移動 | safeTransferFromの二つ | すべての移動 |

`market`で`forge test --offline --match-contract MultiTest -vvvv`（デプロイ・mint・prankの行は省略）。Marketが呼ぶ`transferFrom(address,address,uint256)`（0x23b872dd）がMiniMultiにないので、depositがデータなしに巻き戻る。`demo`のOpenZeppelinのMultiでも同じである（test_marketDeposit1155、巻き戻しデータ0バイト）：

```
[PASS] test_multiDepositReverts() (gas: 552233)
    ├─ [92656] Market::addAsset(MiniMulti: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 75)
    ├─ [44136] MiniMulti::setApprovalForAll(Market: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], true)
    ├─ [95849] Market::deposit(MiniMulti: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100)
    │   ├─ [174] MiniMulti::transferFrom(0x00000000000000000000000000000000000A11cE, Market: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 100)
    │   │   └─ ← [Revert] unrecognized function selector 0x23b872dd for contract 0x2e234DAe75C793f67A35089C9d99245E1C58470b, which has no fallback function.
    │   └─ ← [Revert] EvmError: Revert
    ├─ [2461] MiniMulti::balanceOf(0x00000000000000000000000000000000000A11cE, 1) [staticcall]
    │   └─ ← [Return] 100
    ├─ [2714] Market::totalDeposits(MiniMulti: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]) [staticcall]
    │   └─ ← [Return] 0
```

Market第157講のバージョンの全体の点検（サイズの行と三つのプロファイルのテスト、テストは83個から84個に）：

```
| Market        | 3,260            | 3,473             | 21,316             | 45,679              |
Ran 29 test suites …: 84 tests passed, 0 failed, 0 skipped (84 total tests)
Ran 29 test suites …: 84 tests passed, 0 failed, 0 skipped (84 total tests)
Ran 29 test suites …: 84 tests passed, 0 failed, 0 skipped (84 total tests)
ci ok
```

Market第157講のバージョンの標準の対照表に足した行：

| 標準 | Marketが立つ側 | Marketにあるもの | Marketにないもの | 確認するテスト |
|---|---|---|---|---|
| ERC-1155 | 該当なし | 資産の欄はアドレス一つにトークン一つ | idの欄なし、onERC1155Received・onERC1155BatchReceivedなし。ERC-1155のアドレスはdepositが巻き戻る | test/Multi.t.sol |

### 試すときの注意

- まとめての送信のガスを測るときは、受け取るアドレスを毎回新しいアドレスにする。同じアドレスでもう一度受け取ると残高の欄がすでにあるので、はじめて書く費用が抜けてガスが変わる。
- まとめて送ると、トランザクション一つ分と呼び出し一つ分の費用が節約できる。受け取る欄ごとにかかる保存の費用はそのままなので、N=1ではまとめた方がかえって1,754多くかかる。
- まとまりの中で一つでも残高が足りなければ、まとまり全体が巻き戻る。ブロックに入った記録と払った手数料は残り、ログは0個である。
- OpenZeppelinのERC1155の残高の欄は`mapping(uint256 id => mapping(address account => uint256))`でidが外側のキーだが、標準の関数の引数の順番は(アドレス, id)である。
- Market第157講のバージョンのデプロイのガスは760,316で、第156講のバージョンと同じである。バージョン説明のコメントが変わると末尾のメタデータのハッシュが変わり、その中の00のバイトの数によってデプロイのガスが12単位で動きうるが、この二つのバージョンでは00のバイトの数が同じだった。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30（`0.8.30+commit.73712a01.Windows.msvc`）。デモ用プロジェクトはoptimizerオフ・evm osaka。Market第157講のバージョンはdefaultがvia-IR + optimizerオン runs 200・evm osaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| EIPの原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`、`ERCS/erc-1155.md` 710行、status Final、created 2018-06-17、requires 165、最終更新2023-10-25 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0、MIT。`token/ERC1155/ERC1155.sol`（`_balances` id → アドレス → 金額、transferFromなし）、`token/ERC1155/utils/ERC1155Holder.sol` | 2026-10-20 |
| まとめての送信のガス（ローカルのanvil） | Multiのデプロイ1,846,622、mintRange 20 513,959。N=1 まとめて60,399 / 一つずつ58,645、N=5 181,754 / 293,225、N=20 630,959 / 1,172,900。ERC-20のコントラクト五つにtransfer 1ずつ260,670（52,134 × 5）。受け取るアドレスは毎回はじめて受け取るアドレス、値は1ずつ | 2026-10-20 |
| 巻き戻ったまとまり（ローカルのanvil） | mintRange 5 100ずつ150,749。五つ目だけ101：status 0、145,100（`--gas-limit 300000`）、ログ0個、ブロック3。10ずつ：status 1、181,922、ログ1個 | 2026-10-20 |
| anvilのアドレス | Multi `0x5FbDB2315678afecb367f032d93F642f64180aa3`（二つの実行どちらも最初のデプロイ）。既定のテスト用アカウント、unlockedのアカウントで送る | 2026-10-20 |
| テストのガス（forge） | Batch：test_balanceOfBatch 29,747、test_batchAllOrNothing 189,404、test_batchLog 281,280、test_marketDeposit1155 256,796、test_noHookReverts 620,740、test_operatorAll 272,618、test_selectors 15,411。MultiTest:test_multiDepositReverts 552,233。RebuildTest:test_recordedLogsIncludeReverted 155,244（第156講のバージョンも155,244） | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第157講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ・ハッシュ・行番号 | 第157講のバージョンdefault 3,260 / 3,473（legacy 3,755 / 4,013、debug 7,353 / 7,931）、末尾のハッシュの先頭4バイト`55a8357d`、`.gas-snapshot` 84行。debugの行番号deposit 0 169:33、NotActive 84、`contract Market` 213 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 受け取る関数の中でトークンや元のコントラクトをもう一度呼ぶとき（1155の受け取る関数二つ） | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/) |
| オペレーターの承認の範囲を狭める追加のインターフェースとウォレット側の設計 | [第222講](../../part15/lecture222/)、[第223講](../../part15/lecture223/) |
| まとまりの長さとブロックのガス上限 | [第170講](../../part11/lecture170/)、[第183講](../../part11/lecture183/) |
| ログで1155の帳簿を組み立てるインデクサーとreorg | [第238講](../../part18/lecture238/) |
| 標準の実装を選び、いくつもの種類のトークンを受け取るキャップストーンの設計 | [第256講](../../part20/lecture256/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
