# 第98講 viewとpure

第6部 言語の詳細 ③ コントラクト・第21章 関数の掘り下げ

[← 第97講](../../part6/lecture97/) | [第6部 目次](../) | [第99講 →](../../part6/lecture99/)

## この講義の問い

関数につけた`view`・`pure`は誰がいつ確かめ、実行中は何が止めてくれて、ガスとはどんな関係にあるのか。

## 実習資料

### 準備

通しプロジェクトのMarketは第97講のバージョンのままで、view・pureを点検した結果直す行がなかったので、コードは変えない（`market`）。`demo`は`forge init`で作った空のプロジェクトからCounterの例を消して始めた。どちらのプロジェクトにもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。デプロイのデモはローカルのanvilで既定のアカウント0番・1番（公開されたテスト用の鍵）を`--unlocked --from`で使って動かし、ブロックの時刻は`evm_setNextBlockTimestamp`と`evm_mine`で進めた。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | この講義の終わりのバージョンのMarket（変えたコードなし） |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol) | Marketのテスト |
| [code/market/test/Getters.t.sol](code/market/test/Getters.t.sol) | ゲッターのテスト |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Mut.sol](code/demo/src/Mut.sol) | Counter、相手の関数をviewと誤って書いたILyingと正しく書いたIHonest、Caller、Self、Clock |
| [code/demo/test/Mut.t.sol](code/demo/test/Mut.t.sol) | `test_viaView`（リバートする）、`test_viaCall`、`test_readGet`、`test_viaThis` |
| [code/demo/bad/V1.sol](code/demo/bad/V1.sol) 〜 [V7.sol](code/demo/bad/V7.sol) | view関数での状態の書き込み、emit、状態を変える内部関数、イーサの送金、`call`、`new`、アセンブリの`sstore`（Error 8961） |
| [code/demo/bad/V5s.sol](code/demo/bad/V5s.sol) | view関数での`staticcall`（ビルドは通る） |
| [code/demo/bad/P1.sol](code/demo/bad/P1.sol) 〜 [P5.sol](code/demo/bad/P5.sol) | pure関数での状態変数、`block.timestamp`、viewの内部関数、残高、`msg.sender`の読み取り（Error 2527） |
| [code/demo/bad/W1.sol](code/demo/bad/W1.sol) | view・pureをつけられるのにつけていない関数（Warning 2018） |
| [code/demo/bad/W2.sol](code/demo/bad/W2.sol) | `payable view`（Error 9680） |

`bad/`のファイルは`forge build --offline --force bad/<ファイル>.sol`で一つずつビルドする。

### 実行結果

`forge inspect Market abi --offline`のゲッターの行（一部の欄は省略）。ゲッターはすべてviewである。

```
| function    | SECONDS_PER_YEAR() view returns (uint256)                           |
| function    | admin() view returns (address)                                      |
| function    | assetConfig(address) view returns (Ratio,bool)                      |
| function    | assets(uint256) view returns (IERC20)                               |
| function    | collateralRatio() view returns (Ratio)                              |
| function    | interestRate() view returns (Rate)                                  |
| function    | positions(address,address) view returns (Amount,Amount,uint64,bool) |
| function    | status() view returns (Market.MarketStatus)                         |
| function    | totalBorrows(address) view returns (Amount)                         |
| function    | totalDeposits(address) view returns (Amount)                        |
```

`forge inspect Counter abi --offline`。何も表示のない関数は、ABIにnonpayableとして載る。

```
| function | bump() nonpayable returns (uint256) | 0x68110b2f |
| function | get() view returns (uint256)        | 0x6d4ce63c |
| function | n() view returns (uint256)          | 0x2e52d606 |
```

ビルドが止めるものと通すもの。

```
Error (9680): State mutability already specified as "payable".
```

```
Error (8961): Function cannot be declared as view because this expression (potentially) modifies the state.
 --> bad/V2.sol:6:34:
  |
6 |     function f() external view { emit Seen(1); }
  |                                  ^^^^^^^^^^^^
```

```
$ forge build --offline --force bad/V5s.sol
Compiler run successful!
```

```
Error (8961): Function cannot be declared as view because this expression (potentially) modifies the state.
Error (2527): Function declared as pure, but this expression (potentially) reads from the environment or state and thus requires "view".
```

```
Warning (2018): Function state mutability can be restricted to view
Warning (2018): Function state mutability can be restricted to pure
```

pure関数も`msg.sig`は読む。Clockの`sig()`と`cast sig "sig()"`が同じである。

```
0x00a7029b
0x00a7029b
```

pure関数は、引数が同じならブロックが違っても同じ答えになる（`interestFor`を16番・17番のブロックで、`add(2, 3)`を10番のブロックで）。

```
50
50
5
```

`cast call`で状態を変える`bump()`を呼んでも結果が返ってくるだけで、`n`はそのままである。Marketの`deposit`も同じである。

```
1
0
1
0
```

```
100
0x
100
```

view関数の`get()`を`cast send`で送ると、トランザクションになって手数料が出ていく。

```
10000000000000000000000
blockNumber          7
effectiveGasPrice    456621588
gasUsed              23517
status               1 (success)
9999999989261630115004
```

状態を変える`bump()`を、viewと書いたインターフェースILyingで呼んだ`forge test --offline -vvvv`のトレース。呼び出しがSTATICCALLで出ていき、相手が状態を変えようとした瞬間にリバートする。

```
[PASS] test_viaView() (gas: 1040429857)
Traces:
  [1040429857] MutTest::test_viaView()
    ├─ [0] VM::expectRevert(custom error 0xf4844814)
    │   └─ ← [Return]
    ├─ [1040419298] Caller::viaView(Counter: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]) [staticcall]
    │   ├─ [2444] Counter::bump() [staticcall]
    │   │   └─ ← [StateChangeDuringStaticCall] EvmError: StateChangeDuringStaticCall
    │   └─ ← [Revert] EvmError: Revert
    └─ ← [Stop]
```

ローカルのチェーンで同じ呼び出し。`cast call`はリバートし、ガスリミットを与えて`cast send`すると、失敗したトランザクションがほぼリミットいっぱいのガスを使う。

```
Error: server returned an error response: error code 3: execution reverted, data: "0x"
gasUsed              984794
status               0 (failed)
```

view関数の値は、呼んだブロックの時点の値である。Clockを10番のブロックでデプロイし、11番・12番のブロックを100秒・150秒後に作ったあと、`elapsed()`をブロックごとに呼んだ結果（ブロックの時刻、elapsedの順）。

```
1792403323
1792403423
1792403473
0
100
150
```

Marketの`elapsedOf`を、預け入れた16番のブロックと3,600秒後の17番のブロックで呼んだ結果。

```
0
3600
```

### 試すときの注意

- view・pureは、コンパイラが関数の本体を検査するための表示である。ガスは決めない。`cast call`で呼べば表示に関係なくガスを払わず、`cast send`で送ればview関数でも手数料を払う。
- インターフェースにviewと書いた関数はSTATICCALLで出ていく。相手の関数が実際に状態を変えれば、その呼び出しはリバートする。インターフェースの表示は、相手のコードを確かめない。
- STATICCALLの中で状態を変えようとして止まると、その呼び出しに渡したガスを使い切る。テストのgas 1,040,429,857とgasUsed 984,794が大きいのはそのためである。
- `cast call --block N`で、過去のブロックの時点のviewの値を読める。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやガス価格が変わると、数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節 State Mutability（View Functions、Pure Functions） | 2026-10-19 |
| `STATICCALL` | EIP-214、ビザンチウムハードフォーク | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 第97講の読み取りのgasUsed | ゲッター`v()` 23,510、`this.v()` 24,331 | 2026-10-19 |
| 第47講のpreview() | blockNumber 4、gasUsed 23,925 | 2026-10-19 |
| gasUsed（この講義） | `get()`のcast send 23,517、`viaCall` 47,828、`viaView`のcast send 984,794（ガスリミット1,000,000、失敗）、MarketのaddAsset 92,114、deposit 100 126,150 | 2026-10-19 |
| テストのgas | test_viaView 1,040,429,857、test_viaCall 58,765、test_readGet 13,814、test_viaThis 11,074 | 2026-10-19 |
| ガス価格（getのcast send） | effectiveGasPrice 456,621,588、残高の減少10,738,369,884,996 wei | 2026-10-19 |
| Marketの長さ | creation 7,583 / runtime 6,907バイト | 2026-10-19 |
| ローカルのanvilのアドレス | Counter `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Caller `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Self `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、一つ目のClock `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`（sigの呼び出し）、二つ目のClock `0x0165878A594ca255338adfa4d48449f69242Eb8F`（10番のブロックでデプロイ）、MockToken `0x71C95911E9a5D330f4D621842EC243EE1343292e`、Market `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853` | 2026-10-19 |
| ブロックの時刻 | ブロック10 1792403323、11 1792403423、12 1792403473 / ブロック16 1792403699、17 1792407299 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `payable`とイーサを受け取る関数（`receive`、`fallback`） | [第99講](../../part6/lecture99/) |
| セレクタの計算とコントラクトが関数を選ぶやり方、インターフェースの表のセレクタの欄 | [第101講](../../part6/lecture101/) |
| オーバーライドのときに状態変更可能性を変える規則 | [第111講](../../part6/lecture111/) |
| インターフェースの宣言の規則と抽象コントラクト | [第115講](../../part6/lecture115/) |
| アセンブリで状態変数にアクセスする規則 | [第120講](../../part7/lecture120/) |
| 低水準の`staticcall`を直接使う呼び出しのパターン | [第122講](../../part7/lecture122/) |
| 不変条件の設計とファジング | [第183講](../../part11/lecture183/) |
| 監査のときの状態変更可能性の点検とコードを読む順番 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/) |
| 他人のコントラクトが渡す価格を信じる問題（価格フィード、オラクル） | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
