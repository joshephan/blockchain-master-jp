# 第30講 フォークテスト

第2部 開発とテスト環境・第7章 ローカルチェーンとテスト

[← 第29講](../../part2/lecture29/) | [第2部 目次](../) | [第31講 →](../../part2/lecture31/)

## この講義の問い

本物のチェーンの状態を自分のコンピュータに持ってきてテストすると、何を信じていて、何が抜けているのか。

## 実習資料

### 準備

`forge init`のプロジェクトにforge-std（`lib/forge-std`）を置き、`solc = "0.8.30"`を入れる。メインネットの状態は、キーなしで使える公開ノード（`https://ethereum-rpc.publicnode.com`）から読んでくる。メインネットには読み取りのリクエストだけを送る。depositのトランザクションは、すべてローカルのanvilのフォークとforge内部のEVMでだけ実行する。

### コード

| ファイル | 内容 |
|---|---|
| [code/wethfork/foundry.toml](code/wethfork/foundry.toml) | solc 0.8.30に固定、`[rpc_endpoints]`に`mainnet`の別名 |
| [code/wethfork/test/WethFork.t.sol](code/wethfork/test/WethFork.t.sol) | メインネットのWETHに10 etherを預け、残高とtotalSupplyを確認するテスト |
| [code/wethfork/src/Jar.sol](code/wethfork/src/Jar.sol) | 受け取ったイーサをWETHに変えるJar（直したバージョン、`deposit()`が何も返さないinterface） |
| [code/wethfork/test/Jar.t.sol](code/wethfork/test/Jar.t.sol) | `vm.createSelectFork("mainnet", 26216889)`でブロックを固定してJarをテスト |
| [code/wrong/src/Jar.sol](code/wrong/src/Jar.sol) | 間違ったバージョン。`deposit()`がboolを返すと推測したinterface |
| [code/wrong/test/JarMock.t.sol](code/wrong/test/JarMock.t.sol) | 推測どおりtrueを返すMockWETHで間違ったJarをテスト |

`code/wrong/`の二つのファイルは、そのフォルダだけではビルドできない。`code/wethfork/`の`src/Jar.sol`を置き換え、`test/`に`JarMock.t.sol`を足して実行する。

### 実行結果

フォークなしで`forge test --offline`。空のチェーンにはWETHのコードがないので失敗する：

```
[FAIL: EvmError: Revert] test_Deposit() (gas: 5244)
Suite result: FAILED. 0 passed; 1 failed; 0 skipped
```

コードはそのままで`--fork-url`だけをつけると（`forge test --offline --fork-url $RPC -vv`）通る。ブロック番号を指定していないので、その瞬間の最新ブロックである：

```
[PASS] test_Deposit() (gas: 98783)
Logs:
  block 26216891
  supply before 2208957777645982377867545
  supply after  2208967777645982377867545
```

`anvil --fork-url $RPC --fork-block-number 26216889`で起動したフォークで、`cast`でdeposit。出力は元の実行結果の文字列だけを訳したもの。

```
Fork
Block number:   26216889
Chain ID:       1

totalSupply 前          2208955709867554965205689
deposit 5 ether         blockNumber 26216890   gasUsed 45038   status 1 (success)
totalSupply 後          2208960709867554965205689
アカウント0番 WETH      5000000000000000000
```

同じ時刻に公開ノードに問い合わせると、ブロック番号26216889時点のtotalSupplyは同じだが、テストアカウントのWETHは0で、最新ブロックは26216911である。フォークでできたブロック26216890はハッシュ`0x9fedfe85...`、トランザクション1件で、メインネットの同じ番号のブロックはハッシュ`0xdcc64de1...`、トランザクション143件である。

forgeがダウンロードしておいたキャッシュファイル（`~/.foundry/cache/rpc/mainnet/26216889`、zstdで圧縮したJSON 2,500バイト）をほどいてみると、テストが実際に触ったものだけが入っている。出力は元の実行結果の文字列だけを訳したもの。

```
accounts: 8個
  0xc02aaa39...56cc2   WETH (コードあり)
  0x328809bc...fdac6   alice
  0x7fa9385b...e1496   テストコントラクト
  0x00000000...652e6c6f67   console.log アドレス
  ほかにforgeの既定アドレス、ブロック生成者アドレスなど4個
storage: WETHの欄1個 + cheatcodeアドレスの欄1個
  0x77a21f60...fdaac   = keccak256(alice, 3), balanceOf[alice]
```

ブロック番号なしで13秒の間隔をあけて2回実行すると、ブロックと値が変わる：

```
  block 26216891
  supply before 2208957777645982377867545

  block 26216893
  supply before 2208961956826692803700479
```

`--fork-block-number 26216889`で固定すると、2回とも同じである：

```
  block 26216889
  supply before 2208955709867554965205689
  supply after  2208965709867554965205689
```

約1,000ブロック前に固定すると通り、約100,000ブロック前は公開ノードが拒否する：

```
[PASS] test_Deposit() (gas: 98783)

Error: server returned an error response: error code 4444:
  pruned history unavailable: requested 26116901, earliest available 26206826
```

同じブロックで2回目に実行するときはキャッシュを使うので速くなる：

```
Ran 1 test suite in 1.45s (907.53ms CPU time)
Ran 1 test suite in 479.35ms (911.00µs CPU time)
```

anvilのフォークの待機列は空で（`{"pending":"0x0","queued":"0x0"}`）、フォークのブロック番号はdepositの直後も36秒後も26216890で止まっている。同じ時刻のメインネットは26216911から26216913に増えた。

間違ったJarはMockWETHでは`[PASS] test_WrapMock()`だが、メインネットのWETHにつなぐと`[FAIL: EvmError: Revert] test_Wrap() (block: 26216889)`である。`forge test --offline --match-contract JarForkTest -vvv`で展開すると、WETHのdepositは問題なく終わり、Jarの側でリバートされている：

```
├─ Jar::wrap{value: 1000000000000000000}()
│   ├─ 0xC02a...6Cc2::deposit{value: 1000000000000000000}()
│   │   └─ ← [Stop]
│   └─ ← [Revert] EvmError: Revert
```

interfaceから`returns (bool)`を外し、requireを消した直したバージョンは`[PASS] test_Wrap() (gas: 69196)`である。

### 試すときの注意

- ブロック番号を固定していないフォークテストは、メインネットが変わると結果が変わることがある。コードがそのままでもそうである。
- この公開ノードは、ブロック番号で問い合わせるeth_getBalanceを127ブロック前から403（Archive requests require a personal token）で拒否した。ブロックハッシュで問い合わせると1,000ブロック前も応答した。forgeのフォークは1,000・5,000ブロック前まで通った。ノードのポリシーによって変わる。
- キャッシュファイルは、Node.js 24の`zlib.zstdDecompressSync`でほどいて見られる。
- anvilのフォークで初めて問い合わせるbalanceOfは約180ms、2回目は約100msかかった（castのプロセス時間を含む）。

## 時効性のあるデータ

基準日時点の値。メインネットの値と公開ノードのポリシーは変わる。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公開RPCのアドレス | `https://ethereum-rpc.publicnode.com`（キーなしで使える公開ノード） | 2026-10-18 |
| WETHのアドレス | `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` | 固定 |
| 固定したフォークのブロック | 26216889、ハッシュ`0x7a9c924d59dadb0beb670c674330c3a5ddc8551d6f2906eccf15841730216ac5`、timestamp 1792295675（2026-10-18 03:54:35 UTC） | 2026-10-18 |
| 固定ブロックのWETHのtotalSupply | 2,208,955,709,867,554,965,205,689 wei | 2026-10-18 |
| ブロック番号なしの実行1 | 03:55:10 UTC、ブロック26216891、totalSupply 2,208,957,777,645,982,377,867,545 wei | 2026-10-18 |
| ブロック番号なしの実行2 | 03:55:23 UTC、ブロック26216893、totalSupply 2,208,961,956,826,692,803,700,479 wei | 2026-10-18 |
| anvilのフォークでのdeposit | 5 ether、ブロック26216890、gasUsed 45,038、フォークのtotalSupply 2,208,960,709,867,554,965,205,689 wei | 2026-10-18 03:58:57 UTC |
| 同じ時刻の公開ノード | 最新ブロック26216911、totalSupply（latest）2,208,754,065,773,871,404,532,421 wei、テストアカウント0番のWETHは0 | 2026-10-18 03:58:57 UTCごろ |
| ブロック番号26216890の比較 | フォーク：ハッシュ`0x9fedfe85ecd2f5688a024234cf2aff8a625b1b3d76559da5d4dfeced448b02a5`、トランザクション1件 / メインネット：ハッシュ`0xdcc64de12a86a829e794a6ac0d0cdca21c80c42fddbc7744d00c7c4228c8e466`、トランザクション143件 | 2026-10-18 |
| フォークのブロック番号の停止 | 03:58:57 / 03:59:33 UTC フォーク26216890 / 26216890、メインネット26216911 / 26216913 | 2026-10-18 |
| キャッシュファイル | 2,500バイト（zstd圧縮）、アカウント8個、ストレージの欄2個（WETH 1、cheatcodeのアドレス1） | 2026-10-18 |
| 公開ノードの過去の状態への応答 | ブロック番号でのeth_getBalance：127ブロック前から403（Archive requests require a personal token） / ブロックハッシュで：1,000ブロック前は応答 / forgeのフォーク：1,000・5,000ブロック前はPASS、100,000ブロック前はerror code 4444 pruned history unavailable（earliest available 26206826）。ノードのポリシーによって変わる | 2026-10-18 |
| キャッシュの効果 | 初回の実行1.45s（CPU 907.53ms） / キャッシュでの実行479.35ms（CPU 911.00µs） | 2026-10-18 |
| anvilのフォークでの照会時間 | 初めて問い合わせるbalanceOf 約180ms、2回目 約100ms（castのプロセス時間を含む） | 2026-10-18 |
| 実行環境 | Foundry 1.8.3（forge、cast、anvil）、solc 0.8.30、forge-std | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 入力をツールが選ぶテスト（ファズ・不変条件） | [第31講](../../part2/lecture31/) |
| -vvvの呼び出しツリーを詳しく読む | [第32講](../../part2/lecture32/) |
| フォークで試したデプロイと実際のデプロイの違い | [第34講](../../part2/lecture34/) |
| フォークのブロック固定と計測の再現 | [第145講](../../part9/lecture145/) |
| 待合室のほかの参加者が順番に割り込む問題 | [第172講](../../part11/lecture172/) |
| フォークの上で実際のプロトコルの状態を使った事件の再現 | [第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/) |
| 敵対性 | [第167講](../../part11/lecture167/)、第11部 |

出典と参考資料は[reference.md](reference.md)にまとめた。
