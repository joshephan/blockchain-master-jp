# 第101講 関数セレクタと計算

第6部 言語の詳細 ③ コントラクト・第21章 関数の掘り下げ

[← 第100講](../../part6/lecture100/) | [第6部 目次](../) | [第102講 →](../../part6/lecture102/)

## この講義の問い

コントラクトは入ってきた呼び出しがどの関数なのかを何で知り、その値はどう計算され、重なったら誰が止めるのか。

## 実習資料

### 準備

通しプロジェクトのMarketは第100講のバージョンのままで、この講義では外の関数の一覧である`src/IMarket.sol`（各行のコメントにセレクタ）と、セレクタを照らし合わせる`test/Selectors.t.sol`を加える（`market`）。`demo`は`forge init`で作った空のプロジェクトからCounterの例を消して始めた。`bad`、`bad2`、`bad3`はエラーを見せるプロジェクトで、`bad2`・`bad3`は`src/`に`market`の`Market.sol`を一緒に置いてビルドする。どれもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。`demo`のコントラクトはローカルのanvilに既定のアカウント0番（公開されたテスト用の鍵）でデプロイして呼んだ。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第100講のバージョンと同じMarket |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | 外の関数18個のインターフェース、行ごとにセレクタのコメント |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Selectors.t.sol](code/market/test/Selectors.t.sol) | IMarketとMarketのセレクタ18個の比較、`withdraw`・`addAsset`のセレクタの手計算 |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol) | Marketのテスト |
| [code/market/test/Getters.t.sol](code/market/test/Getters.t.sol) | ゲッターのテスト |
| [code/market/test/Receive.t.sol](code/market/test/Receive.t.sol) | イーサ・ない関数の拒否のテスト |
| [code/market/test/WithdrawAll.t.sol](code/market/test/WithdrawAll.t.sol) | `withdrawAll`のテスト |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Sel.sol](code/demo/src/Sel.sol) | 引数の型が違う関数五つ、セレクタを得る四つの形の`forms()`、シグネチャの打ち間違いの`typo()`、`msg.sig` |
| [code/demo/src/Split.sol](code/demo/src/Split.sol) | セレクタが同じ二つの関数を別々に持つBurnerとOther |
| [code/bad/src/Clash.sol](code/bad/src/Clash.sol) | セレクタが同じ二つの関数を一つのコントラクトに（Error 1860） |
| [code/bad2/src/GetSel.sol](code/bad2/src/GetSel.sol) | 型の名前でゲッターのセレクタを取り出す（Error 9582） |
| [code/bad3/src/GetSel.sol](code/bad3/src/GetSel.sol) | インスタンスで取り出すが、pure関数の中（Error 2527） |
| [code/bad/foundry.toml](code/bad/foundry.toml)、[code/bad2/foundry.toml](code/bad2/foundry.toml)、[code/bad3/foundry.toml](code/bad3/foundry.toml) | solc 0.8.30に固定 |

### 実行結果

セレクタは、関数のシグネチャのkeccak256の先頭4バイトである（`cast keccak`、`cast sig`）。

```
0xa9059cbb2ab09eb219583f4a59a5d0623ade346d962bcd4e46b11da047c9049b
0xa9059cbb
```

Marketの`withdraw`の手計算と、`forge inspect --offline Market methodIdentifiers`のその行。

```
0xf3fef3a3f44f9c277339b67d54f015748bd8d6b77a985b0ab6e71126b018c34a
| withdraw(address,uint256)            | f3fef3a3   |
```

`cast calldata`で作った`withdraw`の呼び出しデータ（見やすいように32バイトごとに改行）。セレクタ4バイトのあとに引数がつく。

```
0xf3fef3a3
  0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3
  0000000000000000000000000000000000000000000000000000000000000064
```

`forge inspect --offline Sel methodIdentifiers`。シグネチャには外部の型が入る（`uint` → `uint256`、コントラクト・ユーザー定義値型・enum → 元になる型、構造体 → タプル）。

```
| a(uint256)           | f0fdf834   |
| b(address,uint8)     | eda86b42   |
| c(uint8)             | 1145e3f3   |
| d((uint256,string))  | a61133dc   |
| e(uint256[],bytes32) | 0d18e93e   |
```

`typo()`は、`"a(uint)"`と`"a(uint256)"`で作った4バイトを返す。前者で呼ぶと合う関数がないのでリバートする。

```
0xb0b3398f
0xf0fdf834
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

デプロイしたSelのランタイムコードの前の部分（`cast disassemble`）。calldataの先頭4バイトを取り出してセレクタと一つずつ比べ（`EQ`）、中間の値との大小の比較（`GT`）で枝を分ける。

```
00000011: PUSH1 0x04
00000013: CALLDATASIZE
00000014: LT
00000015: PUSH2 0x0085
00000018: JUMPI
00000019: PUSH0
0000001a: CALLDATALOAD
0000001b: PUSH1 0xe0
0000001d: SHR
0000001e: DUP1
0000001f: PUSH4 0xa61133dc
00000024: GT
00000025: PUSH2 0x0059
00000028: JUMPI
00000029: DUP1
0000002a: PUSH4 0xa61133dc
0000002f: EQ
00000030: PUSH2 0x0126
00000033: JUMPI
```

4バイトより短いcalldataと、合うセレクタがないcalldataはリバートする（`cast call $S 0xf0fdf8`、`0xdeadbeef`）。

```
Error: server returned an error response: error code 3: execution reverted, data: "0x"
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

シグネチャが違う二つの関数のセレクタが同じである。

```
0x42966c68
0x42966c68
```

一つのコントラクトに二つの関数を置くと、ビルドが止める（`bad`）。

```
Error (1860): Function signature hash collision for collate_propagate_storage(bytes16)
 --> src/Clash.sol:3:1:
```

別のコントラクトにあれば止める手段はない。Burner（`burn`だけがある）に`collate_propagate_storage(bytes16)`で呼ぶと、Burnerの`burn`がそのバイトを`uint256`として読み、1を足して返す。

```
0x42966c680000000000000000000000000000000100000000000000000000000000000000
340282366920938463463374607431768211457 [3.402e38]
6
```

順にシグネチャを作ってハッシュしてみると、130,172個目でセレクタが重なる組`f_75241()`・`f_130171()`（`0x5158e766`）が出た（`cast sig`で確認）。

セレクタを得る四つの形（`this.a.selector`、`Sel.a.selector`、`IERC20.transfer.selector`、`bytes4(keccak256("a(uint256)"))`）を`forms()`で呼んだ結果。

```
0xf0fdf834
0xf0fdf834
0xa9059cbb
0xf0fdf834
```

ゲッターのセレクタは型の名前では取り出せず、インスタンスで取り出すとその関数はviewでなければならない（`bad2`、`bad3`）。

```
Error (9582): Member "status" not found or not visible after argument-dependent lookup in type(contract Market).
Error (2527): Function declared as pure, but this expression (potentially) reads from the environment or state and thus requires "view".
```

`market`で`forge test --offline --mc SelectorsTest`と全体のテスト。

```
[PASS] test_selectorsMatch() (gas: 1764)
[PASS] test_withdrawSelectorByHand() (gas: 329)
Suite result: ok. 2 passed; 0 failed; 0 skipped
Ran 5 test suites: 11 tests passed, 0 failed, 0 skipped (11 total tests)
```

### 試すときの注意

- 関数のシグネチャは、名前と外部の引数の型をコンマだけでつないで書く。空白、引数の名前、`uint`のような省略形を入れると別のハッシュになる。戻り値の型はシグネチャに入らない。
- Marketのランタイムコードの中には関数の名前がない。バイトの中から関数の名前18個を探すと、`"not admin"`という文字列の中の`admin`一つだけが引っかかる。
- 同じコントラクトの中のセレクタの重なりはビルドが止めるが、ほかのコントラクトの関数と重なるかどうかは誰も確かめない。
- インターフェースと実装のセレクタが同じかどうかは、`IMarket.x.selector`と`Market.x.selector`を比べるテストで確かめる。

## 時効性のあるデータ

基準日時点の値。登録数のような外部のデータは、時間がたつと変わる。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Contract ABI SpecificationのFunction Selectorの節、Mapping Solidity to ABI types（contract → address、enum → uint8、ユーザー定義値型 → 元になる型、struct → tuple）。latestのバージョンで確認 | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 4バイトの場合の数 | 2の32乗 = 4,294,967,296 | 2026-10-19 |
| 重なる組の探索の実測 | `f_0()`から順に130,172個をハッシュ、`f_75241()`・`f_130171()` = `0x5158e766`、純粋なPythonのkeccak256で145.2秒 | 2026-10-19 |
| `burn(uint256)`・`collate_propagate_storage(bytes16)`の組 | 二つのシグネチャの4バイトが`0x42966c68`で同じだと書いた記事（2019-07-19） | 2026-10-19 |
| 関数のシグネチャの一覧の例 | Ethereum Signature Database（4byte.directory）の登録数1,463,214 | 2026-10-19 |
| バイトの長さ | Marketのcreation 7,757 / runtime 7,081バイト（第100講のバージョンと同じ） | 2026-10-19 |
| ローカルのanvilのアドレス | Sel `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Burner `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Other `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| イベントのシグネチャのハッシュとトピック | [第106講](../../part6/lecture106/) |
| カスタムエラーのセレクタとエンコード | [第108講](../../part6/lecture108/) |
| 継承で同じ関数のシグネチャをオーバーライドするときのセレクタ | [第110講](../../part6/lecture110/)、[第111講](../../part6/lecture111/) |
| インターフェースと抽象コントラクトの規則 | [第115講](../../part6/lecture115/) |
| ディスパッチャをアセンブリで直接書く、低水準の呼び出しでセレクタをつける | [第122講](../../part7/lecture122/)、[第123講](../../part7/lecture123/) |
| Yulのオブジェクトと、最適化がディスパッチャにすること | [第124講](../../part7/lecture124/)、[第125講](../../part7/lecture125/) |
| バイトコードの構造全体を読む | [第131講](../../part8/lecture131/) |
| ABIエンコードの規則の全体と正規の型の詳細 | [第141講](../../part8/lecture141/) |
| インターフェースIDとERC-165 | [第159講](../../part10/lecture159/) |
| プロキシと実装コントラクトの間のセレクタの重なり、セレクタのルーティング | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 形式検証のツールでセレクタの重なりを見る | [第182講](../../part11/lecture182/) |
| ウォレット・アカウント抽象化でセレクタによって権限を分ける | [第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| オンチェーンデータからセレクタで関数の呼び出しを探す | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
