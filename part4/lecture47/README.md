# 第47講 状態変数と関数

第4部 言語の詳細 ① ファイルと型・第12章 コントラクトの構造

[← 第46講](../../part4/lecture46/) | [第4部 目次](../) | [第48講 →](../../part4/lecture48/)

## この講義の問い

コントラクトの波かっこのすぐ下に書いた変数一行と関数一行は、デプロイしたあと、機械のどこにあるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトから、`src`、`test`、`script`のCounterのファイルを消して始める。テストにはforge-stdが必要である（`lib/forge-std`）。コンパイルできない例は`src`の外の`bad/`に、比較用のコピーは`v2/`に置き、パスを指定して別々にビルドする。ローカルのanvilの既定のアカウント0がデプロイし、アカウント1・2が呼び出す。`src/Ballot.sol`は、[第37講](../../part3/lecture37/)の公式ドキュメントのVotingの例の原文である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Visits.sol](code/src/Visits.sol) | 状態変数二つと定数一つ、external・view・internal pureの関数がある訪問カウンター |
| [code/src/Free.sol](code/src/Free.sol) | コントラクトの外のファイルレベルの関数と、それを使うUsesFree |
| [code/src/Temp.sol](code/src/Temp.sol) | ふつうの状態変数と`transient`状態変数 |
| [code/src/Ballot.sol](code/src/Ballot.sol) | 公式ドキュメントのVotingの例の原文（ストレージの欄の配置とABIの比較用） |
| [code/v2/Visits.sol](code/v2/Visits.sol) | Visitsのいちばん上に`address public owner;`一行だけを入れたコピー |
| [code/bad/ViewWrites.sol](code/bad/ViewWrites.sol) | view関数の中で状態を変える版（コンパイルエラー） |
| [code/test/Visits.t.sol](code/test/Visits.t.sol) | visitを1回呼んだあとvisitsが1かを確認 |

### 実行結果

ストレージの欄の配置（`forge inspect Visits storageLayout`）。定数`MAX_VISITS`には欄がない。いちばん上に一行を挟んだコピーは、番号が一つずつずれる：

```
| Name        | Type    | Slot | Offset | Bytes | Contract              |
| visits      | uint256 | 0    | 0      | 32    | src/Visits.sol:Visits |
| lastVisitor | address | 1    | 0      | 20    | src/Visits.sol:Visits |

$ forge inspect --offline v2/Visits.sol:Visits storageLayout
| owner       | address | 0    | 0      | 20    | v2/Visits.sol:Visits |
| visits      | uint256 | 1    | 0      | 32    | v2/Visits.sol:Visits |
| lastVisitor | address | 2    | 0      | 20    | v2/Visits.sol:Visits |
```

`transient`変数はstorageLayoutに出ず、transientStorageLayoutに別に出る：

```
$ forge inspect --offline Temp storageLayout
| visits | uint256 | 0    | 0      | 32    | src/Temp.sol:Temp |
$ forge inspect --offline Temp transientStorageLayout
| lock   | uint256 | 0    | 0      | 32    | src/Temp.sol:Temp |
```

Visitsをデプロイし、アカウント1、アカウント2の順に`visit()`を呼びながら欄0・1を読んだ結果（`cast storage`）。欄7のように使っていない欄は0である：

```
デプロイ直後 欄0          0x0000000000000000000000000000000000000000000000000000000000000000
アカウント1のあと 欄0     0x0000000000000000000000000000000000000000000000000000000000000001
アカウント1のあと 欄1     0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
アカウント2のあと 欄0     0x0000000000000000000000000000000000000000000000000000000000000002
アカウント2のあと 欄1     0x0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc
```

`visit()`のgasUsedは、1回目の呼び出しが65,727、2回目が31,527、3回目（アカウント2がもう一度、lastVisitorの値はそのまま）が28,727である。ガスは呼んだアカウントが払う。アカウント1の残高は減り、デプロイしたアカウント0の残高はそのままである：

```
アカウント1、visit()の前   10000000000000000000000
アカウント1、visit()のあと 9999999942357809775205
アカウント0、visit()の前   9999999760709999760710
アカウント0、visit()のあと 9999999760709999760710
```

view関数`preview()`を`cast call`で呼ぶと、トランザクションなしで値だけが返ってくる。同じ関数を`cast send`で送ると、ブロックに入ってガスを払うが、状態はそのままである：

```
$ cast call <Visits> "preview()(uint256,address)" --from 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
3
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast block-number
3
$ cast send <Visits> "preview()" --private-key <アカウント1のテスト用キー>
blockNumber          4
gasUsed              23925
status               1 (success)
$ cast storage <Visits> 0
0x0000000000000000000000000000000000000000000000000000000000000002
```

`forge inspect Visits abi`。internal関数`bump`と定数はABIにない：

```
| Type     | Signature                                | Selector   |
| function | lastVisitor() view returns (address)     | 0x27c0b4d5 |
| function | preview() view returns (uint256,address) | 0xefae2305 |
| function | visit() nonpayable                       | 0x0cc4330c |
| function | visits() view returns (uint256)          | 0x91932950 |
```

`--json`で見ると、戻り値の名前（`next`、`who`）と`stateMutability`が一緒に入っている。

`forge test -vvvv`：

```
[PASS] test_visit() (gas: 74136)
Traces:
  [74136] VisitsTest::test_visit()
    ├─ [65727] Visits::visit()
    │   └─ ← [Stop]
    ├─ [2446] Visits::visits() [staticcall]
    │   └─ ← [Return] 1
    └─ ← [Stop]
```

view関数の中の状態の変更（`forge build bad/ViewWrites.sol`）：

```
Error (8961): Function cannot be declared as view because this expression (potentially) modifies the state.
 --> bad/ViewWrites.sol:8:9:
  |
8 |         visits += 1;
  |         ^^^^^^
```

Ballotのストレージの欄は、chairpersonが0、votersが1、proposalsが2である。

### 試すときの注意

- Temp.solをビルドすると、forgeのリントが`uninitialized-state`の警告（visitsを読むだけで書かない）を出す。ストレージの欄の配置を確かめるためのものなので、そのままにしておく。
- 新しいanvilで同じ順番で実行すると、Visitsのアドレスが`0x5FbDB2315678afecb367f032d93F642f64180aa3`になり、ブロック番号も上と同じになる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンとネットワークのルールが変わると違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidityドキュメントのバージョン | v0.8.36、Structure of a Contractの節の七つの項目 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundryのバージョン | forge・cast・anvil 1.8.3 | 2026-10-19 |
| visit()のgasUsed | 1回目の呼び出し65,727 / 2回目31,527 / 3回目（アカウント2がもう一度、lastVisitorの値はそのまま）28,727 | 2026-10-19 |
| preview()のcast sendのgasUsed | 23,925 | 2026-10-19 |
| テストのトレース | test_visit 74,136 / visit() 65,727 / visits() 2,446 | 2026-10-19 |
| SSTOREの価格 | 0から0でない値へ20,000 / 0でない値を別の値へ2,900 / コールドな欄は+2,100 | ベルリン（2021.04）以降 |
| アカウント1の残高の変化 | 10000000000000000000000 → 9999999942357809775205 wei（effectiveGasPrice 876,994,085 wei） | 2026-10-19 |
| transient状態変数が導入されたバージョン | 0.8.28から値型を全面サポート（0.8.27は宣言の構文を受け付けるだけでコード生成なし）。storageLayoutに出ずtransientStorageLayoutに別に出る（Tempのlockは0番）。constant・immutableにもストレージの欄はない | 2026-10-19 |
| エラー番号 | 8961（view関数の中の状態の変更） | 2026-10-19 |
| デプロイのサイズ | Visitsのランタイム865 / UsesFree 433 / Temp 172（バイト） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 状態変数の可視性と自動getter、アクセスのコスト | [第95講](../../part6/lecture95/)、[第96講](../../part6/lecture96/)、[第97講](../../part6/lecture97/) |
| viewとpureのルール全体 | [第98講](../../part6/lecture98/) |
| payableとイーサの受け取り | [第99講](../../part6/lecture99/) |
| 関数modifierの文法 | [第48講](../../part4/lecture48/)、[第103講](../../part6/lecture103/) |
| 関数のオーバーロード | [第100講](../../part6/lecture100/) |
| コンストラクター | [第92講](../../part6/lecture92/)、[第93講](../../part6/lecture93/)、[第94講](../../part6/lecture94/) |
| constantとimmutable | [第102講](../../part6/lecture102/) |
| スロットの配置のルール（複数の変数が一つの欄に入る場合を含む） | [第135講](../../part8/lecture135/) |
| データの場所（storage、memory、calldata） | [第62講](../../part4/lecture62/)、[第63講](../../part4/lecture63/)、[第64講](../../part4/lecture64/) |
| 内部呼び出しと外部呼び出しの違い | [第82講](../../part5/lecture82/)、[第83講](../../part5/lecture83/) |
| transientストレージ | [第136講](../../part8/lecture136/) |
| ガス最適化 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
