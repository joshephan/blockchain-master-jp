# 第248講 Moveのリソース型

第19部 ほかの実行環境・第68章 EVMの外の実行環境

[← 第247講](../../part19/lecture247/) | [第19部 目次](../) | [第249講 →](../../part19/lecture249/)

## この講義の問い

EVMではトークンは帳簿に書かれた数字である。お金を数字ではなく値として扱い、その値をコピーしたり捨てたりすることを型が防ぐ言語では、何が変わるのか。Solidityではその規則をどこまでまねできるのか。

## 実習資料

### 準備

Moveのリソースの規則をSolidityでどこまでまねできるかを見る小さなFoundryプロジェクト`res248`一つを使う。依存関係はforge-std（`lib/forge-std`）一つで、anvilは使わない。警告は`forge`ではなくsolc 0.8.30を直接呼んで（`solc --error-codes --via-ir --optimize --evm-version osaka --bin`）確認する。Move CLIは使っておらず、本文のMoveのコードはMove本の原文なのでコンパイルしていない。まねたバージョンは同じ考え方をEVMに移したものであり、Moveの動作と同じという意味ではない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka |
| [code/src/Bank248.sol](code/src/Bank248.sol) | 残高を帳簿の数字として置く`Bank248`、引く行が抜けた`BankNoDebit248`、足す行が抜けた`BankNoCredit248` |
| [code/src/Drop248.sol](code/src/Drop248.sol) | 返された値を使わない三か所（`ignoreReturn`、`unusedLocal`、`ignoreCall`）とmemory構造体の代入`copyCoin` |
| [code/test/Res248.t.sol](code/test/Res248.t.sol) | 合計のテスト三つとmemory代入のテスト |
| [code/test/Invariant248.t.sol](code/test/Invariant248.t.sol) | ハンドラー`Handler248`、不変条件「アカウントの欄の合計 = 供給」のテスト`InvariantOk248`・`InvariantNoDebit248` |

### 実行結果

`solc ... src/Bank248.sol`は警告0個、エラー0個である。`solc ... src/Drop248.sol`は警告を二つ出す（バイナリの行は省略）：

```
Warning (9302): Return value of low-level calls not used.
  --> src/Drop248.sol:23:9:
   |
23 |         a.call("");
   |         ^^^^^^^^^^

Warning (2072): Unused local variable.
  --> src/Drop248.sol:19:9:
   |
19 |         Coin memory c = take(5);
   |         ^^^^^^^^^^^^^
```

`ignoreReturn`（返された構造体を捨てる）には警告がない。三つともビルドはできる。

`forge test --offline -vv --fuzz-seed 0x248`（実行する前に`cache/invariant`・`cache/fuzz`を消す）：

```
Ran 4 tests for test/Res248.t.sol:Res248Test
[PASS] test_memoryAssignIsSameCoin() (gas: 4156)
[PASS] test_moveKeepsTotal() (gas: 139945)
[PASS] test_noCreditLosesSome() (gas: 117651)
[PASS] test_noDebitMakesMore() (gas: 134591)
Suite result: ok. 4 passed; 0 failed; 0 skipped

Ran 1 test for test/Invariant248.t.sol:InvariantNoDebit248
[FAIL: assertion failed: 2130 != 2000]
	[Sequence] (original: 1, shrunk: 1)
		sender=0x6eDd…3784 addr=[test/Invariant248.t.sol:Handler248]0x2e23…470b calldata=move(uint256,uint256) args=[4649, 130]
 invariant_sumEqualsSupply() (runs: 1, calls: 1, reverts: 0)

Ran 1 test for test/Invariant248.t.sol:InvariantOk248
[PASS] invariant_sumEqualsSupply() (runs: 256, calls: 128000, reverts: 0)
```

| テスト | 結果 |
|---|---|
| test_moveKeepsTotal | aliceに100を発行、bobに30を移す → 合計100、供給100 |
| test_noDebitMakesMore | 引く行が抜けたバージョン → 合計130、供給100 |
| test_noCreditLosesSome | 足す行が抜けたバージョン → 合計70、供給100 |
| test_memoryAssignIsSameCoin | `Coin memory b = a; b.value = 7;`のあと、a・bとも7（コピーではなく同じ値を指す） |
| InvariantOk248 | 128,000回呼び出し、巻き戻し0、通過 |
| InvariantNoDebit248 | 最初の呼び出しで合計2130 ≠ 供給2000となり失敗 |

### 試すときの注意

- Moveなら、引く行が抜けたバージョンは値をコピーしたことになり、足す行が抜けたバージョンは値を捨てたことになるので、コンパイルが通らない。EVMでは両方ともビルドでき、テストだけが捕まえる。
- 不変条件のテストが通ったら、成功した呼び出しの数（calls、reverts）から見る。全部巻き戻っていたなら、何もテストしていないことになる。
- 失敗した手順の引数（args）は、ファズのシードとキャッシュによって変わることがある。同じ値を見るには`--fuzz-seed 0x248`を与え、`cache/invariant`・`cache/fuzz`を消してから実行する。

## 時効性のあるデータ

基準日時点の値。ドキュメントとツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Move本の元のバージョン | move-language/move コミットc453c909（リポジトリはアーカイブ済み） | 2024-05-04 |
| Move本のSui側のバージョン | MystenLabs/move-book コミットd060f943（reference） | 2026-08-31 |
| Foundry・solc | Foundry 1.8.3、solc 0.8.30、optimizerオン runs 200、via-IR、osaka | 2026-10-21 |
| 不変条件テストの条件 | runs 256、depthはデフォルト値（500）、`--fuzz-seed 0x248`、実行前に`cache/invariant`・`cache/fuzz`を消す | 2026-10-21 |
| 不変条件の結果 | InvariantOk248 calls 128,000・reverts 0 PASS / InvariantNoDebit248 FAIL 2130 != 2000、args [4649, 130] | 2026-10-21 |
| テストのガス | test_moveKeepsTotal 139,945 / test_noDebitMakesMore 134,591 / test_noCreditLosesSome 117,651 / test_memoryAssignIsSameCoin 4,156 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Moveのジェネリクスと条件付きの能力（`Cup<T>`） | 付録（ドキュメントの原文まで） |
| Move Proverのような形式検証ツール | [第258講](../../part20/lecture258/)、[第259講](../../part20/lecture259/)、[第260講](../../part20/lecture260/) |
| Suiのオブジェクトの所有・共有の規則 | 付録 |
| トークン標準を型で強制する設計 | 扱わない |

出典と参考資料は[reference.md](reference.md)にまとめた。
