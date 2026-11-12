# 第126講 グローバル変数・関数・演算子の総覧

第7部 アセンブリとYul・第29章 チートシートと文法の定義

[← 第125講](../../part7/lecture125/) | [第7部 目次](../) | [第127講 →](../../part7/lecture127/)

## この講義の問い

公式ドキュメントのチートシート1枚に集まったグローバルな名前と演算子は、前の講義のどこで見たものなのか。そしてその1枚が教えてくれないこと（バージョン、evm_version、結合の順序と計算の順番）は何か。

## 実習資料

### 準備

コンパイルの事例（`c126/`、`c127/`）は、Foundryを通さずにsolc 0.8.30の実行ファイルを直接呼んでビルドした（`solc --error-codes --bin`、evm_versionを変えるときは`--evm-version`）。このように呼ぶと、evm_versionの既定値はpragueである。`Globals126`は、ローカルのanvilを新しく立ち上げてアカウント0番が`cast send --create`でデプロイした。`demo`はoptimizerを切って`evm_version = "osaka"`を書いたFoundryのプロジェクトで、`market`は通しプロジェクトMarketの第126講のバージョンである。どちらもforge-stdが必要である。

### コード

| ファイル | 内容 |
|---|---|
| [code/c126/Globals126.sol](code/c126/Globals126.sol) | ブロックの値（`block.*`、`chainid`）と呼び出しの値（`msg.*`、`tx.*`、`gasleft()`）を一度に返す |
| [code/c126/](code/c126/) | 1行だけのコンパイルの事例: `erc7201`、`now`、`msg.gas`、`sha3`、`suicide`、`block.blockhash`、`block.difficulty`、`selfdestruct`、`transfer`・`send`、`require(bool, error)`、`block.blobbasefee` |
| [code/c127/rand.sol](code/c127/rand.sol) | `block.prevrandao`と`block.difficulty`を並べて読む |
| [code/demo/foundry.toml](code/demo/foundry.toml) | optimizerを切る、`evm_version = "osaka"` |
| [code/demo/src/Ops126.sol](code/demo/src/Ops126.sol) | 演算子の優先順位（`&`と`==`、単項の`-`と`**`、`**`の連続、`<<`と`+`）、`addmod`・`mulmod`、掛け算・割り算の順序 |
| [code/demo/src/Order126.sol](code/demo/src/Order126.sol) | 三つの引数を呼ぶ順番を記録する: `addmod(a(), b(), c())`、`a() + b() * c()`、ふつうの関数 |
| [code/demo/test/Ops126.t.sol](code/demo/test/Ops126.t.sol) | Ops126の値の出力とPanicの確認 |
| [code/demo/test/Order126.t.sol](code/demo/test/Order126.t.sol) | Order126の順番の出力 |
| [code/demo/test/Show126.t.sol](code/demo/test/Show126.t.sol) | Panicの文言を見るためにわざと失敗させたテスト |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第126講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第126講のバージョン |
| [code/market/test/](code/market/test/) | Marketのテスト55個 |

### 実行結果

チートシートの二つのバージョンの比較（`diff doc/v0830/cheatsheet.rst doc/cheatsheet.rst`、行番号の表示は省略）。

```
<   returns ``false`` on failure
< - ``<address payable>.transfer(uint256 amount)``: send given amount of Wei to :ref:`address`, throws on failure
>   returns ``false`` on failure (deprecated)
> - ``<address payable>.transfer(uint256 amount)``: send given amount of Wei to :ref:`address`, throws on failure (deprecated)
< .. index:: cryptography, keccak256, sha256, ripemd160, ecrecover, addmod, mulmod
> .. index:: cryptography, keccak256, sha256, ripemd160, ecrecover, addmod, mulmod, erc7201
> - ``erc7201(string memory id) returns (uint)``: compute the base slot of an ``erc7201`` storage namespace.
>   Can be used in compile time context.
```

solc 0.8.30でビルドした事例。

| ファイル | 結果 |
|---|---|
| xfer.sol（`transfer`・`send`） | エラー・警告なし |
| reqerr.sol（`require(v > 0, Bad(v))`） | エラーなし |
| erc7201.sol | Error (7576): Undeclared identifier. |
| now.sol | Error (7359): "now" has been deprecated. Use "block.timestamp" instead. |
| msggas.sol | Error (1400): "msg.gas" has been deprecated in favor of "gasleft()" |
| sha3.sol | Error (3557): "sha3" has been deprecated in favour of "keccak256". |
| suicide.sol | Error (8050): "suicide" has been deprecated in favour of "selfdestruct". |
| bbh.sol | Error (8113): "block.blockhash()" has been deprecated in favor of "blockhash()" |
| difficulty.sol | Warning (8417): Since the VM version paris, "difficulty" was replaced by "prevrandao", which now returns a random number based on the beacon chain. |
| selfd.sol | Warning (5159): "selfdestruct" has been deprecated. |
| blobbase.sol `--evm-version paris`・`shanghai` | Error (1006): "blobbasefee" is not supported by the VM version. |
| blobbase.sol `--evm-version cancun`・`osaka` | エラーなし |
| rand.sol `--evm-version london` | Warning (9432): "prevrandao" is not supported by the VM version and will be treated as "difficulty". |

`--asm`で見ると、londonのビルドは`difficulty`が二つ、osakaのビルドは`prevrandao`が二つで、`--bin-runtime`ではどちらの箇所も同じバイト0x44である。

`Globals126`（`cast call`）。

```
$ cast call --rpc-url $R $G "blockRow()(uint256,uint256,uint256,uint256,uint256,address,uint256)"
1
1792420333 [1.792e9]
60186539709054828793235584242789472121836932262802854165950138200049077107228 [6.018e76]
1000000000 [1e9]
31337 [3.133e4]
0x0000000000000000000000000000000000000000
30000000 [3e7]
$ cast call --rpc-url $R --from $A0 --value 7 $G "callRow(uint256)(address,bytes4,uint256,address,uint256,uint256,bytes)" 5
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
0x746e74dc
7
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
0
29978394 [2.997e7]
0x746e74dc0000000000000000000000000000000000000000000000000000000000000005
```

timestampはanvilを立ち上げた時刻で、prevrandaoは立ち上げるたびに違う。

`forge test --match-contract Ops126Test -vv`のログ。

```
  bitEq(2) true
  bitEq(3) false
  negPow(3) 9
  powPow(2,3,2) 512
  shiftAdd(2) 8
  mm(2**255,4,7) 4
  interest(1000e18, 5e16, 1 days) 136986301369863013
  interestSwapped 136986301369863000
```

`Show126Test`は、Panicの文言を見せるためにわざと失敗する。

```
[FAIL: panic: division or modulo by zero (0x12)] test_am0() (gas: 6642)
[PASS] test_mm() (gas: 7119)
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_plainMulMod() (gas: 6833)
```

`Order126Test`のログ（値と、a・b・cを呼んだ順番）。既定の経路。

```
  addmod 4 321
  expr   47 321
  plain  4 123
```

`--via-ir`。

```
  addmod 4 123
  expr   47 123
  plain  4 123
```

Market 第126講のバージョンはruntime 7,353 / creation 7,931、`forge test`の55個が通り、警告はなく、`grep -n assembly src/*.sol`は0行である。コメントを除いたソースで数えたグローバルな名前は、`msg.sender`が9か所、`block.timestamp`が3か所、`address(this)`が1か所である。

### 試すときの注意

- チートシートにある名前でも、使うコンパイラのバージョンになければビルドできない（v0.8.36のドキュメントの`erc7201`は0.8.30では7576）。
- 同じグローバルな名前でも、evm_versionによってビルドできたり止められたりする。evm_versionはビルドの設定に書いておく。
- `addmod`・`mulmod`は途中の値があふれない（`mm(2**255,4,7)` 4）。同じ式を`(a * b) % k`と書くとPanic 0x11で、割る数が0ならどちらもPanic 0x12である。
- `2 & 1 == 0`は、Solidityでは`&`が先なのでtrueで、C・JavaScriptでは0である。`-3 ** 2`はSolidityで9、Pythonで-9である。
- 引数を計算する順番は、コード生成の経路によって違う。順番に頼るコードは書かない。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやドキュメントのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Cheatsheet（節は11、優先順位の表は`types/operator-precedence-table.rst`をinclude）、Units and Globally Available Variables、Expressions and Control Structures（649行目に`require`の三つの形）、v0.8.36。比較用にv0.8.30・v0.7.6の`cheatsheet.rst` | 2026-10-19 |
| チートシートのバージョンの違い | v0.8.30 → v0.8.36: `send`・`transfer`の行末に"(deprecated)"、`erc7201`の行を追加。v0.7.6にだけ別名の削除の注記2行（0.5.0、0.7.0） | 2026-10-19 |
| solc | 0.8.30+commit.73712a01。そのまま呼ぶとevm_versionはprague、forge 1.8.3はosaka | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| エラー・警告の番号（solc 0.8.30） | 7576 `erc7201`、7359 `now`、1400 `msg.gas`、3557 `sha3`、8050 `suicide`、8113 `block.blockhash`、1006 `blobbasefee`（paris・shanghai）、9432 `prevrandao`（london）、8417 `difficulty`（paris以降）、5159 `selfdestruct`。`transfer`・`send`・`require(bool, error)`はエラー・警告なし | 2026-10-19 |
| ハードフォークとEIP | paris（EIP-4399 prevrandao）、cancun（EIP-7516 blobbasefee、EIP-6780 selfdestruct）、shanghai、osaka | 2026-10-19 |
| 0x44 | londonのビルドの`--asm`でdifficultyが二つ、osakaのビルドでprevrandaoが二つ、`--bin-runtime`ではどちらの箇所もバイト0x44 | 2026-10-19 |
| Globals126 | anvil 1.8.3（hardFork Bpo1）を新しく立ち上げ、アカウント0番がデプロイ`0x5FbDB2315678afecb367f032d93F642f64180aa3`。blockRow: 1 / 1792420333（立ち上げた時刻） / 60186539709054828793235584242789472121836932262802854165950138200049077107228（立ち上げるたびに違う） / 1000000000 / 31337 / 0x0000…0000 / 30000000。callRow(5) `--value 7`: アカウント0番 / 0x746e74dc / 7 / アカウント0番 / 0 / 29978394 / `0x746e74dc…05` | 2026-10-19 |
| Ops126 | bitEq(2) true、bitEq(3) false、negPow(3) 9、powPow(2,3,2) 512、shiftAdd(2) 8、mm(2**255,4,7) 4、plainMulMod Panic 0x11、am(1,2,0) Panic 0x12、interest 136986301369863013、interestSwapped 136986301369863000 | 2026-10-19 |
| Order126 | 既定の経路（optimizerを切る、evm_version osaka）: addmod 4 / 321、expr 47 / 321、plain 4 / 123。`--via-ir`: 三つとも123 | 2026-10-19 |
| ほかの言語での値 | C・JavaScriptの`2 & 1 == 0` → 0、Pythonの`-3 ** 2` → -9。node v24.11.0で`2 & 1 == 0` → 0、Python 3.12.10で`-3 ** 2` → -9（Pythonの`2 & 1 == 0`は`&`が先なのでTrue）。Cは優先順位の規則（`==`が`&`より先）だけで判断 | 2026-10-19 |
| Market 第126講のバージョン | runtime 7,353 / creation 7,931、テスト55個、警告なし、linkReferences {}、`grep -n assembly src/*.sol` 0行、グローバルな名前の数はmsg.sender 9・block.timestamp 3・address(this) 1 | 2026-10-19 |
| アカウント | アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（公開されたテスト用の鍵） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 文法ファイルで結合の順序を読む | [第127講](../../part7/lecture127/) |
| バージョンごとの破壊的な変更の一覧 | [第127講](../../part7/lecture127/)、[第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| コマンドラインのオプションのevm_versionとStandard JSON | [第128講](../../part8/lecture128/) |
| バージョン・設定をそろえて作り直す | [第130講](../../part8/lecture130/) |
| 二つのコード生成の経路の計算の順番 | [第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| ABIエンコードの規則の全体 | [第141講](../../part8/lecture141/) |
| 演算のコストと選ぶ判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| transient storage | [第136講](../../part8/lecture136/) |
| `prevrandao`・`timestamp`を判断に使う危険 | [第172講](../../part11/lecture172/)、[第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/) |
| 倍率の計算と`mulmod` | [第194講](../../part13/lecture194/)、[第195講](../../part13/lecture195/)、[第196講](../../part13/lecture196/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
