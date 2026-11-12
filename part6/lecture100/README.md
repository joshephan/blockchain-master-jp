# 第100講 関数のオーバーロード

第6部 言語の詳細 ③ コントラクト・第21章 関数の掘り下げ

[← 第99講](../../part6/lecture99/) | [第6部 目次](../) | [第101講 →](../../part6/lecture101/)

## この講義の問い

同じ名前の関数をいくつも置くと、コンパイラは何で選び、デプロイのあとではそれらがどう分かれるのか。

## 実習資料

### 準備

通しプロジェクトのMarketのこの講義のバージョン（`market`）は、第99講のバージョンに`withdrawAll`を加え、`withdraw`を`external`から`public`に変えたバージョンである。`withdraw(address)`でオーバーロードせず、名前を別につけた。`market-ov`は比較用に、同じ位置に引数一つの`withdraw(address)`を置いたバージョンである。`ov`は`forge init`で作った空のプロジェクトからCounterの例を消して始めたデモ用である。どれもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。Ovはローカルのanvilに既定のアカウント0番（公開されたテスト用の鍵）でデプロイし、`cast call`で呼んだ。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | この講義のバージョンのMarket。`withdraw`をpublicに、`withdrawAll`を追加 |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol) | Marketのテスト |
| [code/market/test/Getters.t.sol](code/market/test/Getters.t.sol) | ゲッターのテスト |
| [code/market/test/Receive.t.sol](code/market/test/Receive.t.sol) | イーサ・ない関数の拒否のテスト |
| [code/market/test/WithdrawAll.t.sol](code/market/test/WithdrawAll.t.sol) | `withdrawAll`の成功と、預け入れが0のときの`zero amount` |
| [code/market-ov/src/Market.sol](code/market-ov/src/Market.sol) | `withdrawAll`の位置に`withdraw(address)`を置いた比較用のバージョン |
| [code/market-ov/src/MockToken.sol](code/market-ov/src/MockToken.sol) | テスト用のトークン |
| [code/market-ov/foundry.toml](code/market-ov/foundry.toml) | solc 0.8.30に固定 |
| [code/ov/foundry.toml](code/ov/foundry.toml) | solc 0.8.30に固定 |
| [code/ov/src/Ov.sol](code/ov/src/Ov.sol) | `f(uint8)`、`f(uint256)`、`f(uint256,uint256)`と、中で`f(300)`を呼ぶ`h()` |
| [code/ov/bad/RetOnly.sol](code/ov/bad/RetOnly.sol)、[VisOnly.sol](code/ov/bad/VisOnly.sol)、[ViewOnly.sol](code/ov/bad/ViewOnly.sol)、[NameOnly.sol](code/ov/bad/NameOnly.sol) | 戻り値の型・可視性・状態変更可能性・引数の名前だけが違う二つの関数（Error 1686） |
| [code/ov/bad/CallOne.sol](code/ov/bad/CallOne.sol)、[CallCast8.sol](code/ov/bad/CallCast8.sol)、[CallNamed.sol](code/ov/bad/CallNamed.sol) | `f(1)`、`f(uint8(1))`、`f({a: 1})`（Error 4487） |
| [code/ov/bad/CallBig.sol](code/ov/bad/CallBig.sol) | `f(300)`（ビルドは通る） |
| [code/ov/bad/SelOv.sol](code/ov/bad/SelOv.sol) | オーバーロードした関数の`this.f.selector`（Error 6675） |
| [code/ov/bad/DepositOv.sol](code/ov/bad/DepositOv.sol) | `address`と`IERC20`だけが違うオーバーロード（Error 9914） |
| [code/ov/bad/ExtByName.sol](code/ov/bad/ExtByName.sol) | externalの`withdraw`を中から名前で呼ぶ（Error 7576） |

`bad/`のファイルは、`ov`で`forge build --offline --force bad/<ファイル>`で一つずつビルドする。

### 実行結果

戻り値の型・可視性・状態変更可能性・引数の名前だけが違う二つの関数は、四つとも同じエラーになる（`bad/RetOnly.sol`）。

```
Error (1686): Function with same name and parameter types defined twice.
 --> bad/RetOnly.sol:5:5:
Note: Other declaration is here:
 --> bad/RetOnly.sol:9:5:
```

呼ぶ側が選べない呼び出し。`f(1)`は候補が二つとも合うのでエラーになる。`f(uint8(1))`、`f({a: 1})`も同じエラーである。

```
Error (4487): No unique declaration found after argument-dependent lookup.
  --> bad/CallOne.sol:14:16:
   |
14 |         return f(1);
   |                ^
Note: Candidate:
 --> bad/CallOne.sol:5:5:
  |
5 |     function f(uint8 a) public pure returns (uint256) {
Note: Candidate:
 --> bad/CallOne.sol:9:5:
  |
9 |     function f(uint256 a) public pure returns (uint256) {
```

`f(300)`は`uint8`に入らないので`uint256`のほうに決まり、ビルドが通る。デプロイしたOvの`h()`。

```
1300
```

オーバーロードした関数のセレクタを名前で取り出そうとすると、選べない。

```
Error (6675): Member "f" not unique after argument-dependent lookup in contract SelOv.
  --> bad/SelOv.sol:14:16:
   |
14 |         return this.f.selector;
   |                ^^^^^^
```

`forge inspect --offline Ov abi`と`methodIdentifiers`。ABIでは別々の三つの関数である。

```
| Type     | Signature                                 | Selector   |
| function | f(uint256,uint256) pure returns (uint256) | 0x13d1aa2e |
| function | f(uint8) pure returns (uint256)           | 0x3120d434 |
| function | f(uint256) pure returns (uint256)         | 0xb3de648b |
| function | h() pure returns (uint256)                | 0xb8c9d365 |
```

`cast calldata`。同じ引数1でも、先頭の4バイトだけが違う。

```
0x3120d4340000000000000000000000000000000000000000000000000000000000000001
0xb3de648b0000000000000000000000000000000000000000000000000000000000000001
```

`cast call`は、シグネチャの文字列全体で関数を選ぶ。`f(uint8)`に300を入れると、castが送る前に止める。

```
1
1001
Error: parser error:
300
   ^
number too large to fit in target type
```

`address`と`IERC20`のように、外部の型が同じになるオーバーロード。

```
Error (9914): Function overload clash during conversion to external types for arguments.
  --> bad/DepositOv.sol:13:5:
```

external関数を中から名前で呼ぶと見えない。そのためMarketの`withdraw`をpublicに変えた。

```
Error (7576): Undeclared identifier. "withdraw" is not (or not yet) visible at this point.
  --> bad/ExtByName.sol:10:16:
   |
10 |         return withdraw(asset, 100);
   |                ^^^^^^^^
```

`market`で`forge test --offline --mc WithdrawAllTest -vvvv`（一部）と`forge test --offline`。

```
[PASS] test_withdrawAll() (gas: 195082)
    ├─ [52774] Market::withdrawAll(MockToken: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   ├─ [13633] MockToken::transfer(WithdrawAllTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 100)
[PASS] test_withdrawAllEmptyReverts() (gas: 35422)
    ├─ [24596] Market::withdrawAll(MockToken: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   └─ ← [Revert] zero amount
```

```
Ran 4 test suites in 727.05ms (230.94ms CPU time): 9 tests passed, 0 failed, 0 skipped (9 total tests)
```

`forge inspect --offline Market methodIdentifiers`で、`market`は`withdraw(address,uint256)` f3fef3a3、`withdrawAll(address)` fa09e630、`market-ov`は`withdraw(address)` 51cff8d9、`withdraw(address,uint256)` f3fef3a3である。

### 試すときの注意

- オーバーロードは引数の型でだけ分かれる。戻り値の型、可視性、状態変更可能性、引数の名前だけが違うと、同じ関数を二回定義したことになる。
- リテラルの引数が複数の候補に合うと、コンパイラは選ばない。`uint8(1)`に変えても`uint256`の候補にも合うので、エラーのままである。
- チェーンの外のツールは、オーバーロードした関数をシグネチャの文字列全体で呼ぶ必要がある。castでは`"f(uint8)(uint256)"`のように書く。
- 同じ名前で増やす代わりに名前を別につければ（`withdrawAll`）、呼ぶ側がシグネチャを選ぶ必要がない。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、長さとガスが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節 Function Overloading、Overload resolution and Argument matching | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 標準のオーバーロードの例 | ERC-721 `safeTransferFrom(address,address,uint256)`、`safeTransferFrom(address,address,uint256,bytes)` | 2026-10-19 |
| ツールごとのオーバーロード関数の呼び方 | cast：シグネチャの文字列全体（`"f(uint8)(uint256)"`）。JavaScriptのライブラリ・ウォレットの画面での形は実行では確かめていない | 2026-10-19 |
| バイトの長さ | Marketの第100講のバージョンのcreation 7,757 / runtime 7,081、オーバーロードの比較用のバージョンのruntime 7,081 | 2026-10-19 |
| テストのガス（参考） | test_withdrawAll 195,082、test_withdrawAllEmptyReverts 35,422、withdrawAllの呼び出し52,774 | 2026-10-19 |
| アドレス | ローカルのanvilのOv `0x5FbDB2315678afecb367f032d93F642f64180aa3` / forge test：MockToken `0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f`、WithdrawAllTest `0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| セレクタの計算（keccak256）と、コントラクトが4バイトで関数を選ぶコード | [第101講](../../part6/lecture101/) |
| 継承で同じ名前の関数を書き直すオーバーライド（virtual、override） | [第110講](../../part6/lecture110/)、[第111講](../../part6/lecture111/) |
| ABIエンコードの規則の全体と、ツールがシグネチャを扱うやり方 | [第141講](../../part8/lecture141/) |
| ERC-721の`safeTransferFrom`の二つの形と受け取る側のコールバック | [第156講](../../part10/lecture156/) |
| 標準のインターフェースをセレクタで読む方法 | [第159講](../../part10/lecture159/) |
| コードの精読でのオーバーロード・シグネチャの確認 | [第188講](../../part12/lecture188/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
