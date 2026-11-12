# 第230講 blobとEIP-4844

第17部 スケーラビリティ・第62章 トリレンマとデータ可用性

[← 第229講](../../part17/lecture229/) | [第17部 目次](../) | [第231講 →](../../part17/lecture231/)

## この講義の問い

ロールアップがチェーンに載せるデータは、何で代金を払うのか。blobトランザクションは普通のトランザクションと何が違うのか。コントラクトはblobから何を見られるのか。blobの値段はいつ上がり、blobはどれくらい残るのか。

## 実習資料

### 準備

Foundryプロジェクトなしで、コントラクト一つ（`BlobProbe`）をsolc 0.8.30で直接コンパイルする（`solc --optimize --bin --abi`）。anvilを`--hardfork osaka`で立ち上げ、castでblobの取引を送る（cancunでも1回実行）。blobのマスの数と値段の変化を見るときは`--no-mining`で立ち上げ、`evm_mine`でブロックを自分で作る。アカウントはanvilのデフォルトのテスト用アカウントで、外部のチェーンには接続しない。

### コード

| ファイル | 内容 |
|---|---|
| [code/src/BlobProbe.sol](code/src/BlobProbe.sol) | blobの取引の中でコントラクトが見られる値：`blobhash(0)`・`blobhash(1)`・`blobhash(2)`、`block.blobbasefee` |
| [code/blob1.txt](code/blob1.txt) | blobに載せた1,000バイトの文字（"rollup batch 1: alice->bob 5, bob->carol 2, …"の繰り返し） |

### 実行結果

同じデータをcalldataで送った三つのほう（アカウント0番 → アカウント1番、`eth_sendTransaction`）：

| 送ったデータ | gasUsed | 計算 |
|---|---|---|
| 文字1,000バイト | 61,000 | 21,000 + 10 × 4,000 |
| 0のバイト1,000個 | 31,000 | 21,000 + 10 × 1,000 |
| 文字126,976バイト（blobの一マス分） | 5,100,040 | 21,000 + 10 × 507,904 |

実行がほとんどないデータの取引なので、EIP-7623の下限値（`TOTAL_COST_FLOOR_PER_TOKEN` 10、0でないバイトはトークン4）で計算される。古い計算（0でないバイト16ガス）なら21,000 + 16 × 1,000 = 37,000である。

blobの取引（`cast send --blob`）のレシートから6行：

```
$ cast send --blob --path blob1.txt 0x7099…79C8 \
    --private-key <アカウント0番のテスト用の鍵> --rpc-url <RPC_URL>
effectiveGasPrice    1000000001
gasUsed              21000
status               1 (success)
type                 3
blobGasPrice         1
blobGasUsed          131072
```

取引の`input`は0x、`blobVersionedHashes`は[0x01b3b340…2a2a]、`maxFeePerBlobGas`は0x1である。1番ブロックのヘッダーはgasUsed 21,000 / blobGasUsed 131,072 / excessBlobGas 0である。最初のブロックの`eth_blobBaseFee`は1である。手数料は二つのメーターを足す：

```
21,000 × 1,000,000,001 + 131,072 × 1 = 21,000,000,021,000 + 131,072 = 21,000,000,152,072 wei
```

`cast rpc anvil_getBlobsByTransactionHash <取引のハッシュ>`（anvil専用）で受け取ったblobは、4,096マス × 32バイト = 131,072バイトである。マスごとに最初のバイトが0で、残りの31バイトにデータが入る（blob一つで126,976バイト）。先頭に長さ0x3e8（1,000）があり、0でないバイトは1,002個である。

| 126,976バイト | 実行のガス | blobのガス |
|---|---|---|
| calldata | 5,100,040 | 0 |
| blobの一マス | 21,000 | 131,072 |

blobの取引でコントラクトを作ろうとすると：

```
$ cast send --blob --path blob1.txt --create 0x<BlobProbeの生成コード> ...
Error: EIP-4844 transactions can't be CREATE transactions and require a destination address
```

BlobProbe（デプロイ116,601ガス）の`probe()`を、blobを二つ載せた取引と普通の取引で呼んだ結果：

| | blob二つ（200,000バイトのファイル） | 普通の取引（type 2） |
|---|---|---|
| gasUsed / blobGasUsed | 112,019 / 262,144 | 32,656 / なし |
| h0 | 0x016cf516…18f1 | 0 |
| h1 | 0x012f1dff…28ef | 0 |
| h2 / blobFee | 0 / 1 | 0 / 1 |

h0・h1はその取引の`blobVersionedHashes`の二つである。ない番号には0が返る。

`cast mktx --blob`（送らずに署名だけ）が作ったバイトをRLPでほどき、versioned hashを計算し直した結果：

```
commitment（48バイト）   0xb4e9e4ed…b82e
sha256(commitment)     0xccb3b340b93c88ee…98e42a2a
0x01 + sha256[1:]      0x01b3b340b93c88ee…98e42a2a
取引のversioned hash    0x01b3b340b93c88ee…98e42a2a  （同じ）
```

デフォルトの形（EIP-7594）は、外側のリスト5要素、wrapper_version 1、blob 1、コミットメント1、セル証明128個（それぞれ48バイト）で137,552バイトである。`--eip4844`の形は証明1個で131,326バイトである。

shanghaiでコンパイルすると、blobの命令がない：

```
$ solc --evm-version shanghai --bin src/BlobProbe.sol
Error: Undeclared identifier. Did you mean "blockhash"?
  --> src/BlobProbe.sol:13:14:
   |
13 |         h0 = blobhash(0);
   |              ^^^^^^^^
```

同じエラーが14・15行目にも出る。

取引一つにblob 7個：

```
$ cast send --blob --path blob7.txt 0x7099…79C8 ...
Error: server returned an error response: error code -32003:
too many blobs in one transaction, have: 7, max: 6
```

6個の取引は通り、blobGasUsedは786,432である。

`--no-mining`で立ち上げたanvilで、アカウント0番・1番が6マスの取引を一つずつ送ったあと：

```
evm_mine → ブロック1：blobGasUsed 786,432（6マス）、txs 1、待機 1
evm_mine → ブロック2：blobGasUsed 786,432（6マス）、txs 1、待機 0
```

ブロック一つは最大9マスなので、6 + 6マスは一つのブロックに入らない。続いて、ブロックごとに9マス（目標6）を載せたブロック24個：

| ブロック | 次のblobのベースフィー（wei） | 実行のベースフィー（wei） |
|---|---|---|
| 3 | 1 | 765,931,281 |
| 10 | 2 | 301,621,269 |
| 15 | 3 | 155,013,903 |
| 19 | 4 | 91,011,779 |
| 22 | 5 | 61,043,977 |
| 24 | 6 | 46,774,193 |
| 26 | 7 | 35,840,147 |

excessBlobGasはブロックごとに393,216ずつ増える（3番ブロック 524,288 → 26番ブロック 9,568,256）。そのあと空のブロック110個：

| 空のブロック | 次のblobのベースフィー | 実行のベースフィー |
|---|---|---|
| 27 | 7 | 31,372,673 |
| 121 | 7 | 114 |
| 122 | 6 | 100 |
| 123 | 5 | 88 |
| 130 | 2 | 37 |
| 134 | 1 | 23 |

excessBlobGasは、27〜122番ブロックのあいだ9,961,472のままで、123番ブロックで9,175,040に初めて減る。EIP-7918の条件`BLOB_BASE_COST(2**13) * parent.base_fee_per_gas > GAS_PER_BLOB * blobのベースフィー`により、8,192 × 実行のベースフィー > 131,072 × 7、つまり実行のベースフィーが112を超えているあいだは、blobの値段7が保たれる。

### 試すときの注意

- レシートのgasUsedだけを見ると、blobの値段は見えない。手数料は、gasUsed × effectiveGasPriceとblobGasUsed × blobGasPriceを足す。
- blobは1,000バイトだけ載せても一マス（131,072 blobガス）を使う。
- コントラクトはblobの中身を読めず、versioned hashだけを受け取る。範囲外の番号の`blobhash`は失敗せずに0を返すので、呼んだ側が確かめなければならない。
- `blobhash`・`block.blobbasefee`はcancunからある命令（BLOBHASH・BLOBBASEFEE）で、Solidity 0.8.24から使える。
- `cast send --blob`はデフォルトでEIP-7594の形（セル証明）で送り、`--eip4844`は古い形で送る。ローカルのanvilはosaka・cancunのどちらでも両方の形を受け付ける。実際のネットワークが求める形はEIP-7594の原文に従う。
- ローカルのanvilはblobを持ち続けるが、実際のネットワークのノードは保管期間が過ぎると消す。

## 時効性のあるデータ

基準日時点の値。ハードフォークとツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（anvil・cast） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30+commit.73712a01 | 2026-10-21 |
| ハードフォークのメインネットでの有効化 | Dencun 2024-03-13（タイムスタンプ1710338135）、Pectra 2025-05-07（1746612311）、Fusaka 2025-12-03 21:49:11 UTC、BPO1 2025-12-09 14:21:11 UTC、BPO2 2026-01-07 01:01:11 UTC | 2026-10-21 |
| blobの目標・最大（ブロックあたり） | EIP-4844 3・6、EIP-7691 6・9。BPO以後の値はコンセンサス層の設定で確認 | 2026-10-21 |
| 取引一つのblobの最大 | 6（EIP-7594） | 2026-10-21 |
| blobの保管 | `MIN_EPOCHS_FOR_BLOB_SIDECARS_REQUESTS` 4096エポック、エポック32スロット × 12秒と仮定すると約18.2日 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| blobの中の値をコントラクトで証明によって確かめる手順（0x0Aプリコンパイル） | [第232講](../../part17/lecture232/) |
| ブロックにblobを入れる側がマスを選ぶこと | [第233講](../../part17/lecture233/) |
| 過去のblobを長く保管する側と受け取る方法 | [第238講](../../part18/lecture238/) |
| blobを増やして分けて受け取るサンプリング | [第231講](../../part17/lecture231/) |
| メインネットのblobの手数料の流れ | 時効性のある数字なので載せない |

出典と参考資料は[reference.md](reference.md)にまとめた。
