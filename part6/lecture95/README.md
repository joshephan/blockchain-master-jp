# 第95講 可視性の四段階

第6部 言語の詳細 ③ コントラクト・第20章 可視性とゲッター

[← 第94講](../../part6/lecture94/) | [第6部 目次](../) | [第96講 →](../../part6/lecture96/)

## この講義の問い

宣言の前につける四つの単語は、誰がこの名前を呼べるかをどう分け、何は止めないのか。

## 実習資料

### 準備

プロジェクトを三つ使う。`market`は通しプロジェクトのMarketのこの講義のバージョン（第19章の終わりのバージョンから`interestFor`の一行を`public`から`external`に変えたバージョン）である。`demo`と`bad`は`forge init`で作った空のプロジェクトから始めたデモ用である。どれもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。デプロイのデモはローカルのanvilで、既定のアカウント0番・1番（公開されたテスト用の鍵）を`--unlocked --from`で使って動かした。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | この講義のバージョンのMarket。`interestFor`を`external`に |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol) | Marketのテスト |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Vis.sol](code/demo/src/Vis.sol) | 四つの可視性をつけた状態変数・関数と、internalを呼ぶ子のChild |
| [code/demo/src/VisY.sol](code/demo/src/VisY.sol) | 可視性を書かない状態変数 |
| [code/demo/src/Args.sol](code/demo/src/Args.sol) | 同じ配列の引数をexternal calldata、public calldata、public memoryで受け取る三つの関数 |
| [code/demo/test/Vis.t.sol](code/demo/test/Vis.t.sol) | `callAll()`と`useInternal()` |
| [code/demo/test/Args.t.sol](code/demo/test/Args.t.sol) | 長さ50の配列で三つの関数のガスを`gasleft()`の差で測る |
| [code/bad/foundry.toml](code/bad/foundry.toml) | solc 0.8.30に固定 |
| [code/bad/src/ExtVar.sol](code/bad/src/ExtVar.sol) | 状態変数に`external`（Error 2314） |
| [code/bad/src/ExtByName.sol](code/bad/src/ExtByName.sol) | external関数を名前だけで呼ぶ（Error 7576） |
| [code/bad/src/ChildExt.sol](code/bad/src/ChildExt.sol) | 子から親のexternalを名前で呼ぶ（Error 7576） |
| [code/bad/src/ChildPriv.sol](code/bad/src/ChildPriv.sol) | 子から親のprivateを呼ぶ（Error 7576） |
| [code/bad/src/ThisIntl.sol](code/bad/src/ThisIntl.sol) | internalを`this.`で呼ぶ（Error 9582） |
| [code/bad/src/OtherPriv.sol](code/bad/src/OtherPriv.sol) | 同じファイルの別のコントラクトのprivate（Error 9582） |
| [code/bad/src/OtherIntl.sol](code/bad/src/OtherIntl.sol) | 同じファイルの別のコントラクトのinternal（Error 9582） |
| [code/bad/src/NoVis.sol](code/bad/src/NoVis.sol) | 可視性を書かない関数（Error 4937） |
| [code/bad/src/PubStorage.sol](code/bad/src/PubStorage.sol) | storageの参照を受け取るpublic関数（Error 6651） |

`bad`のファイルは`forge build --offline --force src/<ファイル>.sol`で一つずつビルドする。ファイルの上のほうに空行があるので、エラーの行番号が下の出力と2〜3行ずれることがある。

### 実行結果

デプロイしたMarketの`admin()`とスロット0。同じアドレスを二つの道で読む。

```
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
0x00000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb922665000
```

`forge inspect --offline Vis abi`（表の見出しは省略）。internal・privateの関数と、private・internalの状態変数はABIにない。

```
| function | callAll() view returns (uint256) | 0x6b2bafa4 |
| function | ext() pure returns (uint256)     | 0xcf9f23b5 |
| function | open() view returns (uint256)    | 0xfcfff16f |
| function | pub() pure returns (uint256)     | 0x7defb410 |
```

ビルドが止める場合（`bad`）。

```
Error (2314): Expected identifier but got 'external'
 --> src/ExtVar.sol:5:13:
  |
5 |     uint256 external x;
  |             ^^^^^^^^
```

```
Error (7576): Undeclared identifier. "ext" is not (or not yet) visible at this point.
 --> src/ExtByName.sol:8:16:
  |
8 |         return ext();
  |                ^^^
```

```
Error (7576): Undeclared identifier.
  --> src/ChildPriv.sol:10:16:
   |
10 |         return priv();
   |                ^^^^
```

```
Error (9582): Member "intl" not found or not visible after argument-dependent lookup in contract ThisIntl.
 --> src/ThisIntl.sol:8:16:
  |
8 |         return this.intl();
  |                ^^^^^^^^^
```

```
Error (9582): Member "secret" not found or not visible after argument-dependent lookup in contract O.
Error (9582): Member "intl" not found or not visible after argument-dependent lookup in contract O2.
```

```
Error (4937): No visibility specified. Did you intend to add "public"?
 --> src/NoVis.sol:5:5:
  |
5 |     function f() pure returns (uint256) {
  |     ^ (Relevant source part starts here and spans across multiple lines).
```

```
Error (6651): Data location must be "memory" or "calldata" for parameter in function, but "storage" was given.
  --> src/PubStorage.sol:10:20:
```

`forge test --offline --mc VisTest -vvvv`のトレースの一部。`this.ext()`は自分のアドレスへの外部呼び出しとして出力され、子のinternal呼び出しは別には出力されない。

```
    ├─ [4310] Vis::callAll() [staticcall]
    │   ├─ [354] Vis::ext() [staticcall]
    │   │   └─ ← [Return] 1
    │   └─ ← [Return] 10
```

```
    ├─ [344] Child::useInternal() [staticcall]
    │   └─ ← [Return] 3
```

`interestFor`をexternalに変えたバージョンのABIの行。変える前のバージョンとABIのJSONは同じで、ランタイムコードはどちらも6,907バイト、違うのはメタデータハッシュの32バイトだけである。

```
| function | interestFor(uint256,Rate,uint256) pure returns (uint256) | 0x9bcf40a2 |
```

`forge test --offline --mc ArgsTest -vv`。長さ50の配列を渡すとき、calldataで受け取るとexternalとpublicの差は小さく、memoryで受け取るとコピーのコストがつく。

```
[PASS] test_gas() (gas: 100429)
Logs:
  external calldata 19282
  public   calldata 19237
  public   memory   30953
```

Visをデプロイしたあと、`cast storage`でスロット0〜2を読むと、privateの`secret`（42）とinternalの`inner`（7）もそのまま見える。`forge inspect --offline Vis storageLayout`（表の一部）。

```
0x000000000000000000000000000000000000000000000000000000000000002a
0x0000000000000000000000000000000000000000000000000000000000000007
0x0000000000000000000000000000000000000000000000000000000000000001
```

```
| Name   | Type    | Slot | Offset | Bytes | Contract        |
| secret | uint256 | 0    | 0      | 32    | src/Vis.sol:Vis |
| inner  | uint256 | 1    | 0      | 32    | src/Vis.sol:Vis |
| open   | uint256 | 2    | 0      | 32    | src/Vis.sol:Vis |
```

ゲッターのない`secret()`を呼ぶとリバートし、`open()`は1を返す。

```
Error: server returned an error response: error code 3: execution reverted, data: "0x"
1
```

可視性を書かない状態変数`y`は、スロットは確保されるがABIにはない（`forge inspect --offline VisY storageLayout`、`abi`）。

```
| y      | uint256 | 3    | 0      | 32    | src/VisY.sol:VisY |
| function | open() view returns (uint256) | 0xfcfff16f |
```

Marketの`addAsset`を管理者でないアカウントで送ると、ガスの見積もりで`not admin`で止まり、読む関数の`interestFor`は誰でも呼べる。

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: not admin, ...
50000 [5e4]
```

### 試すときの注意

- 可視性が決めるのは、ほかのコントラクトが呼んで読む道だけである。private・internalの状態変数も、`cast storage`で誰でも読める。
- external関数を中から呼ぶには`this.f()`で呼ぶ必要があり、そうすると自分のアドレスへの外部呼び出しになる。
- public関数も配列の引数を`calldata`で受け取れる（0.6.9から）。ガスの差は、可視性よりも引数の位置で大きく出る。
- ガスの測定は、同じアドレスを先に一度呼んでおいてから測った。初めてアクセスするアドレスの追加コストが、三つのうち一つだけにつかないようにするためである。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、長さとガスが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節 Visibility and Getters（State Variable Visibility、Function Visibility） | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 関数の可視性の必須化 | 0.4.17で省略に警告、0.4.21の実験モードでエラー、0.5.0で必須。0.4.24のドキュメント：関数の既定は`public`、状態変数の既定は`internal`、状態変数に`external`は不可 | 2026-10-19 |
| public関数のcalldataの引数 | 0.6.9（2020-06-04）"Permit calldata location for all variables." | 2026-10-19 |
| SWC-100 | Function Default Visibility（可視性を書かない関数はpublic）。登録簿に実際の事故の事例は書かれていない、2020年以降は更新停止の表記 | 2026-10-19 |
| 引数の位置のガス | 長さ50の`uint256[]`、`forge test`の中の`gasleft()`の差、同じアドレスを先に一度呼んだあと：external calldata 19,282 / public calldata 19,237 / public memory 30,953 | 2026-10-19 |
| バイトの長さ | Marketのランタイムコード6,907バイト（第19章の終わりのバージョン・第95講のバージョンで同じ、違うバイト32個はメタデータハッシュ）、ABIの関数17行。Visのデプロイ時のランタイム693バイト、Child 748バイト | 2026-10-19 |
| ガス（参考） | addAsset（アカウント0番）のgasUsed 92,114 | 2026-10-19 |
| ローカルのanvilのアドレス | Vis `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Market `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、MockToken `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| public状態変数が作るゲッターの形（配列・マッピング・構造体・二重のマッピング） | [第96講](../../part6/lecture96/) |
| 状態変数の可視性と読む経路ごとのガス、publicが増やすランタイムコード | [第97講](../../part6/lecture97/) |
| viewとpure | [第98講](../../part6/lecture98/) |
| 継承の文法（is、override、virtual）と、継承したコントラクトでの可視性 | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| スロット番号の計算規則 | [第135講](../../part8/lecture135/) |
| ABIエンコードの規則とセレクタ | [第141講](../../part8/lecture141/) |
| ストレージへのアクセスのコストと最適化の優先順位 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| アクセス制御のパターンとtx.origin | [第151講](../../part9/lecture151/)、[第176講](../../part11/lecture176/) |
| 隠すべき値をチェーンに置く設計（オンチェーン乱数のシードの露出、コミット・リビール） | [第175講](../../part11/lecture175/)、[第206講](../../part14/lecture206/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
