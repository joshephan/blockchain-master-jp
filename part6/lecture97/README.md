# 第97講 状態変数の可視性とアクセスのコスト

第6部 言語の詳細 ③ コントラクト・第20章 可視性とゲッター

[← 第96講](../../part6/lecture96/) | [第6部 目次](../) | [第98講 →](../../part6/lecture98/)

## この講義の問い

同じ状態変数一つを中で、ゲッターで、スロットで読むとき、それぞれ誰がいくら払い、`public`という一語は何を増やすのか。

## 実習資料

### 準備

通しプロジェクトのMarketは第95講・第96講のバージョンのままで、この講義で変えた行はない（`market`）。九つの状態変数をすべてpublicにしておくと決める。`cmp`は九つの状態変数をinternalに変えた比較用のバージョンである（デモ専用）。`demo`は`forge init`で作った空のプロジェクトからCounterの例を消して始めた。どれもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。ガスの測定は、ローカルのanvilで既定のアカウント0番・1番（公開されたテスト用の鍵）を`--unlocked --from`で使い、レシートのgasUsedで測った。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | この講義の終わりのバージョンのMarket（第95講のバージョンと同じ） |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol) | Marketのテスト |
| [code/market/test/Getters.t.sol](code/market/test/Getters.t.sol) | 第96講のゲッターのテスト |
| [code/cmp/src/Market.sol](code/cmp/src/Market.sol) | 九つの状態変数をinternalに変えた比較用のバージョン |
| [code/cmp/foundry.toml](code/cmp/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Store.sol](code/demo/src/Store.sol) | 同じ値を読むいくつもの道（名前で一回・三回・ローカル変数に入れる・`this.v()`）と、ほかのコントラクトから読むReader |
| [code/demo/src/StoreI.sol](code/demo/src/StoreI.sol) | `v`をinternalにしたStore |
| [code/demo/src/Pub.sol](code/demo/src/Pub.sol) | 三つの状態変数をすべてpublic、一つだけpublic、すべてinternalにした三つのコントラクト |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |

### 実行結果

同じ値`v`を読む道ごとにトランザクションで送ったときのgasUsed（anvilのレシート、アカウント1番が送る）。

| 読む道 | gasUsed |
|---|---|
| ゲッター`v()` | 23,510 |
| `readOnce()`（名前で一回） | 23,473 |
| `readThrice()`（名前で三回） | 24,129 |
| `readCached()`（ローカル変数に入れて三回） | 23,921 |
| `readViaThis()`（`this.v()`） | 24,331 |
| Readerの`readFrom(Store)`（ほかのコントラクトからゲッター） | 27,529 |
| StoreIの`readOnce()`（internal） | 23,473 |

`cast send`で`v()`を送る前とあとのアカウント1番の残高。差はgasUsed × effectiveGasPriceである。

```
9999999917775947143725
blockNumber          9
effectiveGasPrice    345414668
gasUsed              23510
status               1 (success)
9999999909655248299045
```

`cast call`で読むと残高もブロック番号もそのままで、スロットを直接読んでも同じ値が出る。

```
9999999917775947143725
5
9999999917775947143725
8
5
8
0x0000000000000000000000000000000000000000000000000000000000000005
```

`v`をinternalにしたStoreI。中で読むガスは同じで、ゲッターはないのでリバートするが、スロットからは読める。

```
gasUsed              23473
Error: server returned an error response: error code 3: execution reverted, data: "0x"
0x0000000000000000000000000000000000000000000000000000000000000005
```

コード1バイトあたりの保存のガス。33バイトと34バイトを返すデプロイのコード（`0x60215ff3`、`0x60225ff3`）のgasUsedの差が200である。

```
gasUsed              59677
gasUsed              59877
```

publicが増やすもの。三つの状態変数の可視性だけが違う三つのコントラクトと、Marketの二つのバージョン。

| コントラクト | ランタイムコード | デプロイのコード | デプロイのgasUsed |
|---|---|---|---|
| AllPublic | 256 | 284 | 108,811 |
| OnePublic | 172 | 198 | 90,643 |
| AllInternal | 62 | 88 | 66,854 |
| Market（publicのバージョン） | 6,907 | 7,583 | 1,595,824 |
| Market（internalの比較用のバージョン） | 5,425 | 6,101 | 1,275,633 |

比較用のバージョンのMarketには`admin()`がないのでリバートするが、スロット0には同じ値がある。

```
5425
Error: server returned an error response: error code 3: execution reverted, data: "0x"
0x00000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb922665000
```

publicのバージョンのMarketは、コンストラクタで決めた値をゲッターで読む（`admin()`、`interestRate()`、`collateralRatio()`）。

```
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
50000000000000000 [5e16]
80
```

### 試すときの注意

- `cast call`はトランザクションを作らないので、ガスを払わない。同じ読み取りを`cast send`で送ると、基本のガス21,000に実行のガスがつく。
- コントラクトの中では、状態変数を名前で読む。`this.v()`は自分のアドレスへの外部呼び出しなので、高くつく。
- 同じスロットを何度も読むときは、ローカル変数に一度入れて使うと減る（24,129 → 23,921）。コールドアクセスになるのは最初の読み取りだけである。
- publicは読むガスを変えず、ゲッターのコードの分だけランタイムコードとデプロイのガスを増やす。Marketの九つのゲッターが、ランタイムコード1,482バイトを使う。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやハードフォークが変わると、ガスと長さが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節 Visibility and Getters | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3、anvilは既定の設定 | 2026-10-19 |
| トランザクションの基本のガス | 21,000。アカウント1番が1 weiをEOAに送る`cast estimate` 21000 | 2026-10-19 |
| スロットの読み取り（SLOAD） | コールドアクセス2,100 / ウォームアクセス100ガス | ベルリン（2021.04）以降 |
| アカウントへのアクセス（CALLの対象など） | コールドアクセス2,600 / ウォームアクセス100ガス。トランザクションを受け取るアドレスは最初からウォームの状態 | ベルリン（2021.04）以降 |
| コード1バイトあたりの保存のガス | 200。33バイトを返すデプロイ59,677 / 34バイトを返すデプロイ59,877 | 2026-10-19 |
| コードの欄のサイズの上限 | 24,576バイト（EIP-170） | 2026-10-19 |
| 読む道ごとのgasUsed | v() 23,510 / readOnce 23,473 / readViaThis 24,331 / readFrom 27,529 / readThrice 24,129 / readCached 23,921 / StoreI readOnce 23,473 | 2026-10-19 |
| cast send v()の前後の残高 | 9999999917775947143725 → 9999999909655248299045（差8,120,698,844,680 wei = 23,510 × effectiveGasPrice 345,414,668） | 2026-10-19 |
| 三つのコントラクト（AllPublic / OnePublic / AllInternal） | ランタイム256 / 172 / 62バイト、デプロイのコード284 / 198 / 88バイト、デプロイのgasUsed 108,811 / 90,643 / 66,854 | 2026-10-19 |
| Marketの二つのバージョン（public / internal） | ランタイム6,907 / 5,425、デプロイのコード7,583 / 6,101、ABIの関数17 / 8行、デプロイのgasUsed 1,595,824 / 1,275,633 | 2026-10-19 |
| ローカルのanvilのアドレス | Store `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Reader `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、AllPublic `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、OnePublic `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、AllInternal `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、Market（publicのバージョン）`0xa513E6E4b8f2a923D98304ec87F64353C4D5C853`、Market（比較用のバージョン）`0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6`、StoreI `0x8A791620dd6260079BF849Dc5567aDC3F2FdC318` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `view`・`pure`の表示の意味と、`eth_call`が状態を扱うやり方 | [第98講](../../part6/lecture98/) |
| Marketの外の関数の一覧と外部インターフェースの確定 | [第98講](../../part6/lecture98/)、[第99講](../../part6/lecture99/)、[第100講](../../part6/lecture100/)、[第101講](../../part6/lecture101/)、[第102講](../../part6/lecture102/) |
| `constant`・`immutable`の値とランタイムコード | [第102講](../../part6/lecture102/) |
| アセンブリでストレージの読み取りを減らす技法 | [第123講](../../part7/lecture123/) |
| スロットの配置の規則と、一つのスロットに複数の値を入れる配置 | [第135講](../../part8/lecture135/) |
| ストレージへのアクセスのコストを見て、どこから減らすかを決める基準 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| デプロイのあとで関数を変えるプロキシの構造 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| チェーンに置いた値を読んで、乱数のような秘密を前もって知る手口 | [第175講](../../part11/lecture175/) |
| 点検のチェックリストでの読み取りの経路と可視性の確認 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
