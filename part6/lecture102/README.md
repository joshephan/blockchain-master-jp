# 第102講 constantとimmutable

第6部 言語の詳細 ③ コントラクト・第21章 関数の掘り下げ

[← 第101講](../../part6/lecture101/) | [第6部 目次](../) | [第103講 →](../../part6/lecture103/)

## この講義の問い

値を変えないと決めた状態変数はどこに置かれ、`constant`と`immutable`はいつ値が決まり、その選択はガス・コード・スロットマップに何を残すのか。

## 実習資料

### 準備

通しプロジェクトのMarketのこの講義のバージョン（`market`）は、第101講のバージョンから、コンストラクタで一度決めて変える関数のない三つの状態変数`collateralRatio`、`admin`、`interestRate`を`immutable`に変えたバージョンである。コンストラクタと残りの行はそのままである。`demo`は`forge init`で作った空のプロジェクトにデモ用のコントラクトとエラーのソースを入れたものである。どちらのプロジェクトにもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。ガスとスロットは、ローカルのanvilで既定のアカウント0番・1番（公開されたテスト用の鍵）を`--unlocked --from`で使って測った。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | この講義のバージョンのMarket。三つの値をimmutableに |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | 第101講のインターフェース |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Selectors.t.sol](code/market/test/Selectors.t.sol) | セレクタのテスト（ABIがそのままかを確認） |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol)、[Getters.t.sol](code/market/test/Getters.t.sol)、[Receive.t.sol](code/market/test/Receive.t.sol)、[WithdrawAll.t.sol](code/market/test/WithdrawAll.t.sol) | 前の講義で加えたテスト |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Fixed.sol](code/demo/src/Fixed.sol) | 同じ値30を、普通の状態変数（Plain）、constant（Const）、immutable（Immut）にした三つのバージョン |
| [code/demo/src/Consts.sol](code/demo/src/Consts.sol) | constantにできる式（`keccak256`、string、大きな数の式、`365 days`） |
| [code/demo/src/Rules.sol](code/demo/src/Rules.sol) | コンストラクタの中のimmutableの規則：二回の代入（Twice）、代入前の読み取り（ReadEarly）、代入しない（Never） |
| [code/demo/src/CstRuntime.sol](code/demo/src/CstRuntime.sol) | constantだけがあるコントラクトの`type(C).runtimeCode` |
| [code/demo/bad/K1.sol](code/demo/bad/K1.sol) 〜 [K5.sol](code/demo/bad/K5.sol) | constantのエラー：`block.timestamp`、`msg.sender`、状態変数の式（Error 8349）、初期値なし（Error 4266）、関数で代入（Error 6520） |
| [code/demo/bad/M1.sol](code/demo/bad/M1.sol)、[M3.sol](code/demo/bad/M3.sol) | immutableのエラー：普通の関数で代入（Error 1581）、stringのimmutable（Error 6377） |
| [code/demo/bad/M5.sol](code/demo/bad/M5.sol) | 条件文の中でだけ代入（ビルドは通る） |
| [code/demo/bad/ImmRuntime.sol](code/demo/bad/ImmRuntime.sol) | immutableがあるコントラクトの`type(C).runtimeCode`（Error 9274） |

`bad/`のファイルは`forge build --offline --force bad/<ファイル>.sol`で一つずつビルドする。

### 実行結果

第101講のバージョンのMarketの`forge inspect --offline Market storageLayout`（欄の一部）。`collateralRatio`、`admin`がスロット0に、`interestRate`がスロット1にある。

```
| status          | enum Market.MarketStatus | 0 | 0 | 1  |
| collateralRatio | Ratio                    | 0 | 1 | 1  |
| admin           | address                  | 0 | 2 | 20 |
| interestRate    | Rate                     | 1 | 0 | 32 |
| assets          | contract IERC20[]        | 2 | 0 | 32 |
| assetConfig     | mapping(...)             | 3 | 0 | 32 |
| positions       | mapping(...)             | 4 | 0 | 32 |
| totalDeposits   | mapping(...)             | 5 | 0 | 32 |
| totalBorrows    | mapping(...)             | 6 | 0 | 32 |
```

constantのエラー（`bad/K1.sol`〜`K5.sol`、順番どおり）。

```
Error (8349): Initial value for constant variable has to be compile-time constant.
Error (8349): Initial value for constant variable has to be compile-time constant.
Error (8349): Initial value for constant variable has to be compile-time constant.
Error (4266): Uninitialized "constant" variable.
Error (6520): Cannot assign to a constant variable.
```

Constsをデプロイしたあとの四つのゲッター（`ROLE()`、`NAME()`、`BIG()`、`YEAR()`）。

```
0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
"Market"
2
31536000 [3.153e7]
```

PlainとConstの`cast codesize`と`cast storage … 0`。Constにはスロットがない。

```
172
172
0x000000000000000000000000000000000000000000000000000000000000001e
0x0000000000000000000000000000000000000000000000000000000000000000
```

immutableのエラー（`bad/M1.sol`、`bad/M3.sol`）。

```
Error (1581): Cannot write to immutable here: Immutable variables can only be initialized inline or assigned directly in the constructor.
Error (6377): Immutable variables cannot have a non-value type.
```

コンストラクタの中では規則がゆるい。solc 0.8.30ではTwiceはビルドでき、最後の値2が残る。ReadEarlyは代入前に読んだ値が0で、最終的な値は7である。条件文の中でだけ入れるM5、まったく入れないNeverもビルドでき、Neverは0である。

Immutを30、45で二回デプロイした結果。どちらも203バイトで、0から数えて101番目のバイトだけが`1e`、`2d`と違う。スロット0は空で、ビルド成果物がその位置を記録している。

```
203
203
0x0000000000000000000000000000000000000000000000000000000000000000
"immutableReferences":{"11":[{"start":70,"length":32}
```

immutableがあると`type(C).runtimeCode`は使えず、constantだけなら使える（UseCstの`f()`）。

```
Error (9274): "runtimeCode" is not available for contracts containing immutable variables.
172
```

三つのバージョンの比較（Immutのコンストラクタの引数は30）。

| | Plain | Const | Immut |
|---|---|---|---|
| ランタイムコード | 172バイト | 172バイト | 203バイト |
| デプロイのgasUsed | 112,812 | 90,643 | 99,712 |
| ゲッターの`cast send`のgasUsed | 23,466 | 21,367 | 21,367 |
| `cast storage … 0` | 30 | 0（スロットなし） | 0（スロットなし） |

ゲッターの差23,466 - 21,367 = 2,099は、ストレージの欄をトランザクションで初めて読むコスト（コールドのSLOAD 2,100）とほぼ同じである。

この講義のバージョンのMarketをデプロイすると、スロット0・1は空で、値はゲッターとランタイムコードから読む。

```
0x0000000000000000000000000000000000000000000000000000000000000000
0x0000000000000000000000000000000000000000000000000000000000000000
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

この講義のバージョンの`forge inspect --offline Market storageLayout`。

```
| status        | enum Market.MarketStatus | 0 | 0 | 1  |
| assets        | contract IERC20[]        | 1 | 0 | 32 |
| assetConfig   | mapping(...)             | 2 | 0 | 32 |
| positions     | mapping(...)             | 3 | 0 | 32 |
| totalDeposits | mapping(...)             | 4 | 0 | 32 |
| totalBorrows  | mapping(...)             | 5 | 0 | 32 |
```

Marketの二つのバージョンの比較（コンストラクタの引数はアカウント1番・5e16・80）。

| | 第101講のバージョン | 第102講のバージョン |
|---|---|---|
| デプロイのコード / ランタイムコード | 7,757 / 7,081 | 7,841 / 7,145 |
| デプロイのgasUsed | 1,633,425 | 1,601,257 |
| `admin()` | 23,710 | 21,525 |
| `interestRate()` | 23,670 | 21,570 |
| `collateralRatio()` | 23,735 | 21,550 |
| `status()` | 23,641 | 23,641 |
| addAsset | 92,114 | 89,732 |
| deposit | 126,150 | 126,138 |

ABIはそのままである。`forge test --offline --mc SelectorsTest`。

```
[PASS] test_selectorsMatch() (gas: 1764)
[PASS] test_withdrawSelectorByHand() (gas: 329)
```

### 試すときの注意

- `constant`と`immutable`はストレージのスロットを使わない。デプロイのあとは、変える欄も変えるコードもない。
- immutableの値はランタイムコードのバイトに入る。同じソースでもコンストラクタの引数が違えばランタイムコードは違い、コントラクトを検証するときはコンストラクタの引数を合わせる必要がある。
- コンパイラの成果物のdeployedBytecodeでは、immutableの位置が0で空いている。チェーン上のコードと比べるときは、`immutableReferences`が記録した位置を除く。この講義のバージョンのMarketのadminは二か所（ゲッターとaddAssetの検査）に入る。
- 第102講のバージョンから、Marketのスロット番号が一つずつ前に詰まる。前の講義の`cast storage … 0`でadminを読んでいた方法は、このバージョンでは通じない。
- depositのガスの差（126,150 / 126,138）は、Marketではなく、トークンのアドレスのcalldataの0のバイトの数の差（43 / 44個）から来た。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやハードフォークが変わると、ガスと長さが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節 Constant and Immutable State Variables | 2026-10-19 |
| コンストラクタの中のimmutableの規則 | 0.8.21（2023-07-19）から作成中に関数・modifierの外ならどこでも読み書き可能、明示的な初期化は必須ではない / 0.8.8（2021-09-27）から初期化後の作成中に読み取り可能 | 2026-10-19 |
| immutableの導入 | solc 0.6.5 | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| adminのバイトの二か所 | 成果物の`immutableReferences`にadminの欄が二つ（1,912番目・3,250番目から32バイト）。addAssetの検査を`address(1)`に変えた試しのバージョンでは一つだけ残る | 2026-10-19 |
| コールドのSLOAD | 2,100ガス（ウォームアクセス100）、EIP-2929、ベルリン（2021.04）以降。ゲッターの差2,099と比較 | 2026-10-19 |
| 三つのバージョン（Plain / Const / Immut） | ランタイム172 / 172 / 203バイト、デプロイのgasUsed 112,812 / 90,643 / 99,712、ゲッターのgasUsed 23,466 / 21,367 / 21,367 | 2026-10-19 |
| Marketの二つのバージョン（第101講 / 第102講） | creation 7,757 / 7,841、runtime 7,081 / 7,145、デプロイ1,633,425 / 1,601,257、`admin()` 23,710 / 21,525、`interestRate()` 23,670 / 21,570、`collateralRatio()` 23,735 / 21,550、`status()` 23,641 / 23,641、addAsset 92,114 / 89,732、deposit 126,150 / 126,138（トークンのアドレスのcalldataの0のバイト43 / 44個、calldataの値572 / 560） | 2026-10-19 |
| ローカルのanvilのアドレス | Plain `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Const `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Immut 30 `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、Immut 45 `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、Twice `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853`、ReadEarly `0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6`、Never `0x8A791620dd6260079BF849Dc5567aDC3F2FdC318`、Consts `0x610178dA211FEF7D417bC0e6FeD39F05609AD788`、UseCst `0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e`、第101講のバージョンのMarket `0xa51c1fc2f0d1a1b8494ed1fe312d7c3a78ed91c0`、第102講のバージョンのMarket `0x3aa5ebb10dc797cac828524e59a333d0a371443c` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 継承でのコンストラクタの引数と`immutable`の初期化の順番 | [第114講](../../part6/lecture114/) |
| ライブラリのアドレスのようにコードに入るほかの値とdelegatecall | [第117講](../../part6/lecture117/) |
| アセンブリで`constant`・`immutable`にアクセスする規則 | [第120講](../../part7/lecture120/) |
| デプロイのコードが`immutable`の欄を埋める構造 | [第124講](../../part7/lecture124/) |
| コンパイラの出力のオプション（`immutableReferences`など） | [第128講](../../part8/lecture128/) |
| `immutable`があるコントラクトのソースの検証とコンストラクタの引数合わせ | [第130講](../../part8/lecture130/) |
| ストレージのスロット番号の計算規則と、一つのスロットにまとめられる規則 | [第135講](../../part8/lecture135/) |
| ストレージへのアクセスのコストと最適化の優先順位 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| `status`を変える関数と状態マシンの設計 | [第152講](../../part9/lecture152/) |
| インターフェースの表を標準のインターフェースとして読む方法 | [第159講](../../part10/lecture159/) |
| プロキシでの`immutable`の値とスロット | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
