# 第96講 自動ゲッター

第6部 言語の詳細 ③ コントラクト・第20章 可視性とゲッター

[← 第95講](../../part6/lecture95/) | [第6部 目次](../) | [第97講 →](../../part6/lecture97/)

## この講義の問い

`public`という一語でコンパイラが作って入れる関数は、何を受け取って何を返し、なぜその形なのか。

## 実習資料

### 準備

通しプロジェクトのMarketは第95講のバージョンのままで、この講義ではゲッターを確かめるテストファイル`test/Getters.t.sol`だけを加える（`market`）。`cmp`は、Marketの九つの状態変数で`public`だけを`internal`に変えた比較用のバージョンである（デモ専用）。`demo`と`bad`は`forge init`で作った空のプロジェクトから始めた。どれもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。`demo`のコントラクトはローカルのanvilに既定のアカウント0番（公開されたテスト用の鍵）でデプロイし、`cast call`で読んだ。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第95講のバージョンのMarket（九つの状態変数がpublic） |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol) | Marketのテスト |
| [code/market/test/Getters.t.sol](code/market/test/Getters.t.sol) | `positions`、`assets`、`assetConfig`のゲッターのテスト |
| [code/cmp/src/Market.sol](code/cmp/src/Market.sol) | 九つの状態変数をinternalに変えた比較用のバージョン |
| [code/cmp/foundry.toml](code/cmp/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Getters.sol](code/demo/src/Getters.sol) | 値・配列・マッピング・二重のマッピング・構造体・string・constant・immutableの状態変数と`readInside()` |
| [code/demo/src/Peek.sol](code/demo/src/Peek.sol) | 配列のゲッターと、`list[i]`を直接読む`at(i)` |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/bad/src/Bad1.sol](code/bad/src/Bad1.sol) | 中で`count()`を関数のように呼ぶ（Error 5704） |
| [code/bad/src/Bad2.sol](code/bad/src/Bad2.sol) | public状態変数と同じ名前の関数（Error 2333） |
| [code/bad/foundry.toml](code/bad/foundry.toml) | solc 0.8.30に固定 |

`bad`の二つのファイルは、それぞれ別にビルドする（一つのプロジェクトに一つずつ置いて`forge build --offline`）。

### 実行結果

`forge inspect --offline Market abi`の関数17行。ソースに書いた関数七つのほかの十は、public状態変数（定数`SECONDS_PER_YEAR`を含む）のゲッターである。九つの状態変数をinternalに変えた比較用のバージョンは8行である。

```
SECONDS_PER_YEAR() view returns (uint256)
addAsset(IERC20,Ratio) nonpayable
admin() view returns (address)
assetConfig(address) view returns (Ratio,bool)
assetCount() view returns (uint256)
assets(uint256) view returns (IERC20)
collateralCount(address) view returns (uint256)
collateralRatio() view returns (Ratio)
deposit(address,uint256) nonpayable
elapsedOf(address,address) view returns (uint256)
interestFor(uint256,Rate,uint256) pure returns (uint256)
interestRate() view returns (Rate)
positions(address,address) view returns (Amount,Amount,uint64,bool)
status() view returns (Market.MarketStatus)
totalBorrows(address) view returns (Amount)
totalDeposits(address) view returns (Amount)
withdraw(address,uint256) nonpayable
```

`forge inspect --offline Getters abi`。ソースに書いた関数は`readInside`一つである。

```
FEE() view returns (uint256)
allowance(address,address) view returns (uint256)
balanceOf(address) view returns (uint256)
count() view returns (uint256)
item() view returns (uint256,string,bool)
list(uint256) view returns (uint256)
owner() view returns (address)
readInside() view returns (uint256,uint256)
title() view returns (string)
```

配列のゲッターは番号を一つ受け取る。`count()`、`list(1)`、引数なしの`list()`の呼び出し。

```
3
20
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

範囲外の番号。Peekのゲッター`list(3)`は空のデータでリバートし、`list[i]`を直接読む`at(3)`はPanic 0x32でリバートする。

```
Error: server returned an error response: error code 3: execution reverted, data: "0x"
Error: execution reverted: panic: array out-of-bounds access (0x32)
... data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000032"
```

`title()`はstringを丸ごと、`balanceOf`は入れたキーにも入れていないキーにも値を返し、二重のマッピング`allowance`はキーを二つ受け取る。

```
"market"
500
0
0
```

構造体のゲッター`item()`。配列`history`とマッピング`liked`の欄は抜けて、三つの欄だけがタプルで返ってくる。`forge inspect --offline Getters storageLayout`（一部）と`cast storage … 6`。

```
99
"pen"
true
```

```
| item      | struct Getters.Item | 4    | 0      | 160   |
| title     | string              | 9    | 0      | 32    |
```

```
0x0000000000000000000000000000000000000000000000000000000000000001
```

`readInside()`と`cast call --trace`。名前で読んだ`count`にはトレースの行がなく、`this.count()`は自分のアドレスへのstaticcallの行が一つできる。

```
3
3
```

```
Traces:
  [3479] 0x5FbDB2315678afecb367f032d93F642f64180aa3::readInside()
    ├─ [425] 0x5FbDB2315678afecb367f032d93F642f64180aa3::count() [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000003
    └─ ← [Return] 0x0000…0003 0000…0003
```

`bad`の二つのビルドエラー。

```
Error (5704): This expression is not callable.
 --> src/Bad1.sol:8:16:
  |
8 |         return count();
  |                ^^^^^^^
```

```
Error (2333): Identifier already declared.
 --> src/Bad2.sol:7:5:
Note: The previous declaration is here:
 --> src/Bad2.sol:5:5:
  |
5 |     uint256 public count = 3;
```

`market`で`forge test --offline`。

```
Ran 1 test for test/Market.t.sol:MarketTest
[PASS] test_depositWithdraw() (gas: 191802)
Ran 3 tests for test/Getters.t.sol:GettersTest
[PASS] test_assetConfigGetter() (gas: 11392)
[PASS] test_assetsGetter() (gas: 24061)
[PASS] test_positionsGetter() (gas: 16773)
```

### 試すときの注意

- 配列のゲッターでは、配列全体を一度に読めない。チェーンの外で長さを別に読み（Marketでは`assetCount()`）、番号ごとに呼ぶ。
- マッピングのゲッターはキーの一覧を返せない。入れていないキーでも0を返す。
- 構造体のゲッターは、フィールドを宣言の順にタプルで返す。構造体の中の配列・マッピングの欄は抜ける。
- コントラクトの中で名前だけを書くと状態変数を直接読み、`this.`をつけるとゲッターを外部呼び出しで呼ぶ。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、長さとガスが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節 Visibility and Getters（State Variable Visibility、Getter Functions） | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| バイトの長さ | Gettersのランタイム1,889 / Market（第95講・第96講のバージョン）のデプロイのコード7,583、ランタイム6,907 / 状態変数をinternalにした比較用のバージョンのランタイム5,425 | 2026-10-19 |
| セレクタ | `item()` 0xf2a4a82e、`list(uint256)` 0x80c9419e、引数なしの`list()` 0x0f560cd7（Gettersにはない）、`positions(address,address)` 0x4bd21445 | 2026-10-19 |
| ガス（参考） | `readInside()`の`cast call --trace` Gas used 24,543、内側の`count()`のstaticcall 425 / テストのgas：depositWithdraw 191,802、assetConfigGetter 11,392、assetsGetter 24,061、positionsGetter 16,773 | 2026-10-19 |
| ローカルのanvilのアドレス | Getters `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Peek `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 同じ値を中で・ゲッターで・`this.`で・ほかのコントラクトから読むガス、`public`が増やすデプロイのガス | [第97講](../../part6/lecture97/) |
| `view`の表示の意味と検査 | [第98講](../../part6/lecture98/) |
| 関数セレクタの計算 | [第101講](../../part6/lecture101/) |
| `public`状態変数がインターフェースの関数の位置を埋める規則 | [第111講](../../part6/lecture111/)、[第115講](../../part6/lecture115/) |
| ゲッターの戻り値のエンコード（stringのオフセット、タプル） | [第141講](../../part8/lecture141/) |
| 構造体・配列・文字列のスロットの配置の規則 | [第135講](../../part8/lecture135/) |
| 配列全体を返す関数とストレージへのアクセスのコスト | [第143講](../../part9/lecture143/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
