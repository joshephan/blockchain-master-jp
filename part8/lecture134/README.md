# 第134講 移行のときの注意点

第8部 コンパイラと内部構造・第32章 IRベースのコード生成

[← 第133講](../../part8/lecture133/) | [第8部 目次](../) | [第135講 →](../../part8/lecture135/)

## この講義の問い

すでに動いているプロジェクトをvia-IRに変えると何を確かめ直さなければならず、Marketは変えるべきなのか。

## 実習資料

### 準備

通しプロジェクトMarketの第134講のバージョン（第133講のバージョンとコードが同じで、foundry.tomlにvia-IRで別にビルドする`[profile.ir]`を足したバージョン）から始める。solc 0.8.30、Foundry 1.8.3で、テストにはforge-stdが必要である（`lib/forge-std`）。ガスは、バージョンごとに新しいanvilを立ち上げてブロック間隔を1秒に固定し、アカウント0番でMockTokenとMarketをデプロイしてから、同じ順序（addAsset 75 → deposit 100 → withdraw 30 → setStatus 1 → setStatus 0 → 失敗するdeposit 0）で送ったレシートのgasUsedである。リバートした位置は、`anvil --steps-tracing`で`debug_traceTransaction`の最後のステップを見る。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | default（optimizerは切る、via-IRは切る）と`[profile.ir]`（`via_ir = true`、`out = "out-ir"`） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | Market 第134講のバージョン。バージョンを説明するコメント2行のために、deposit 0のリバートが144行目、withdraw 0が149行目 |
| [code/market/src/](code/market/src/) | IMarket・MarketMath・MarketTypes・MockToken（第133講のバージョンと同じ） |
| [code/market/test/](code/market/test/) | プロジェクトのテスト14ファイル、テスト55個。`Assembly.t.sol`にアセンブリブロックを使うテスト用のコントラクトMarketSlots・RawCaller |
| [code/fail/test/Fail.t.sol](code/fail/test/Fail.t.sol) | わざと失敗するテスト二つ（deposit 0、withdraw 150）。`code/market/test/`にコピーしてBacktraceを見る |

### 実行結果

二つのプロファイルのサイズ（列はRuntime Size / Initcode Size / Runtime Margin / Initcode Margin、バイト）。

```
$ FOUNDRY_PROFILE=ir forge build --offline --sizes
| Market      | 7,615            | 8,209             | 16,961             | 40,943              |
$ forge build --offline --sizes
| Market      | 7,353            | 7,931             | 17,223             | 41,221              |
```

テスト55個を二つの経路で。

```
$ forge test --offline
Ran 16 test suites …: 55 tests passed, 0 failed, 0 skipped (55 total tests)
$ FOUNDRY_PROFILE=ir forge test --offline
Ran 16 test suites …: 55 tests passed, 0 failed, 0 skipped (55 total tests)
```

via-IRのビルドで0x40の欄に最初に入れる値（`forge inspect --via-ir … irOptimized`のオブジェクトの見出しと0x40の行だけ）。

```
$ forge inspect --offline --via-ir test/Assembly.t.sol:MarketSlots irOptimized
  object "MarketSlots_43250"            mstore(64, memoryguard(0xe0))
  object "MarketSlots_43250_deployed"   mstore(64, memoryguard(0x80))
$ forge inspect --offline --via-ir test/Assembly.t.sol:RawCaller irOptimized
  object "RawCaller_43439"              mstore(64, memoryguard(0x80))
  object "RawCaller_43439_deployed"     mstore(64, 128)
$ forge test --offline --via-ir --match-path test/Assembly.t.sol
Ran 3 test suites …: 6 tests passed, 0 failed, 0 skipped (6 total tests)
```

四つのバージョンのガス（レシートのgasUsed、optimizer runs 200）。比較用のバージョンは、Marketのコードはそのままで、foundry.tomlの`via_ir`・`optimizer`の2行だけを変えた。

| バージョン | runtime | デプロイ | addAsset 75 | deposit 100 | withdraw 30 | setStatus 1 | setStatus 0 | 失敗するdeposit 0 |
|---|---|---|---|---|---|---|---|---|
| 既定、optimizerを切る（Marketのデプロイ物） | 7,353 | 1,645,279 | 93,730 | 130,478 | 59,911 | 45,732 | 23,820 | 26,869 |
| via-IR、optimizerを切る | 7,615 | 1,708,626 | 97,685 | 136,529 | 66,820 | 46,132 | 24,220 | 27,491 |
| 既定、optimizerを入れる | 3,755 | 867,827 | 92,576 | 128,297 | 57,856 | 45,224 | 23,312 | 26,409 |
| via-IR、optimizerを入れる | 3,260 | 760,316 | 92,656 | 127,515 | 57,448 | 45,001 | 23,089 | 26,264 |

二つのバージョンの成果物のメタデータのsettings。

```
既定の経路: {'optimizer': {'enabled': False, 'runs': 200}, 'evmVersion': 'osaka'}
via-IR:    {'viaIR': True, 'optimizer': {'enabled': False, 'runs': 200}, 'evmVersion': 'osaka'}
```

storageLayout（status 0、assets 1、assetConfig 2、positions 3、totalDeposits 4、totalBorrows 5）、ABIの項目36個、セレクタ19個は二つのバージョンで同じである。同じsaltでCREATE2のアドレスを計算すると違う（init codeはcreation + コンストラクタの引数、`cast keccak`）。

```
$ cast create2 --deployer <アカウント0番> --salt 0x00…01 --init-code-hash 0xb6f871ee…5079
0x9102c4E2101742F9a54dF3C1DD0AA971Ea99788c
$ cast create2 --deployer <アカウント0番> --salt 0x00…01 --init-code-hash 0x4f976753…d772
0xe821ca67f788460f21C181E86503ce1C88097865
```

上が既定の経路、下がvia-IRである。`Fail.t.sol`のBacktrace（行だけを選んで書いた）。

```
$ forge test --offline --match-path test/Fail.t.sol -vvvvv
[FAIL: ZeroAmount()] test_depositZero() (gas: 127779)
  at Market.deposit (src/Market.sol:144:33)
[FAIL: InsufficientDeposit(0, 150)] test_withdrawOver() (gas: 128164)
  at Market.withdraw (src/MarketMath.sol:38:35)
$ forge test --offline --via-ir --match-path test/Fail.t.sol -vvvvv
[FAIL: ZeroAmount()] test_depositZero() (gas: 136505)
  at Market.deposit
[FAIL: InsufficientDeposit(0, 150)] test_withdrawOver() (gas: 137746)
  at Market.withdraw
```

anvilに二つの経路のバージョンを別々にデプロイし、リバートしたトランザクションの最後のpcを、それぞれのソースマップで読んだ結果。

| 送ったもの | 既定の経路 | via-IR |
|---|---|---|
| deposit(token, 0) | pc 4703 → 命令2233 → `11285:12:21:-:0` → 144:33 | pc 6989 → 命令4271 → `11285:12:21:-:0` → 144:33 |
| withdraw(token, 0) | pc 3177 → `11511:12:21:-:1` → 149:33、m 1 | pc 6112 → `11511:12:21:-:0` → 149:33、m 0 |
| withdraw(token, 150) | pc 4872 → MarketMath.sol 38:35 | pc 7441 → MarketMath.sol 38:35 |
| setStatus(3)（enumの範囲外） | pc 5276 → #utility.yul 45:35 `revert(0, 0)` | pc 588 → src/Market.sol 185:1 コントラクト全体 |

別の経路のソースマップで読むと合わない。via-IRのpc 6989・7441は既定の経路のコードでは命令の境目ではなく（PUSHのデータの中）、via-IRのpc 588は既定の経路のソースマップで130行目の`totalBorrows`の宣言を指す。

### 試すときの注意

- `[profile.ir]`に書かない値（optimizer、evm_version、remappings）は、defaultの値を引き継ぐ。プロファイルを足しても、defaultがsolcに渡すsettingsはそのままなので、defaultの成果物は末尾のメタデータハッシュまで同じである。
- プロファイルなしで`forge build --via-ir`（または`forge test --via-ir`）だけをつけると、outの成果物がvia-IRのバージョン（メタデータ`viaIR: true`）で上書きされる。via-IRのバージョンはout-irのようにフォルダを分け、上書きしてしまったら`forge build --force`でdefaultの成果物を作り直す。
- optimizerを切ったままvia-IRだけを入れると、サイズとガスの七つの欄がすべて増える。via-IRが小さくなるのは、optimizerを一緒に入れたときである。
- Foundry 1.8.3のBacktraceは、via-IRのビルドでは行番号を出さない。行を探すときは、デプロイしたバイトコードを作った経路のソースマップを使う。
- メタデータのsettingsの`viaIR`の欄は、via-IRのバージョンにだけある（falseなら欄そのものがない）。
- テストがすべて通っても、テストがないところ（継承の初期値の順番、`_;`が2回、一つの式の中の計算の順番）は、ドキュメントの違いの一覧をソースと1行ずつ突き合わせる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやソースのコメントが変わると数字が変わる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30+commit.73712a01、Marketのビルドのevm_versionはosaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3。`FOUNDRY_PROFILE=ir`なら`[profile.ir]`に書かない値はdefaultを引き継ぐ、プロファイルなしで`--via-ir`だけをつけるとoutを上書きする | 2026-10-20 |
| forgeのBacktrace | 既定の経路`at Market.deposit (src/Market.sol:144:33)`、via-IRのビルド`at Market.deposit`（行番号なし） | 2026-10-20 |
| サイズ | 第134講のバージョンのdefault runtime 7,353 / creation 7,931、`FOUNDRY_PROFILE=ir` 7,615 / 8,209、既定・optimizerを入れる3,755、via-IR・optimizerを入れる3,260 | 2026-10-20 |
| 四つのバージョンのガス | 上の表。バージョンごとに新しいanvil、ブロック間隔1秒、アカウント0番がMockToken → Marketをデプロイ（コンストラクタの引数はアカウント0番・5e16・80） | 2026-10-20 |
| メタデータのsettings | 既定`{optimizer: {enabled: false, runs: 200}, evmVersion: osaka}`、via-IRは先頭に`viaIR: true`、ipfsハッシュ6d7b08b2… / d4fc5148… | 2026-10-20 |
| CREATE2 | アカウント0番`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`、salt 0x…01、init codeのkeccak 0xb6f871eea1d4cba59b62942d4e06bbaad93063489ccd23a4ce5631c8d0de5079 → 0x9102c4E2101742F9a54dF3C1DD0AA971Ea99788c / 0x4f97675353e95bdddd60bdb1b1584ab82941f66f6429a4bbdb52084d2a14d772 → 0xe821ca67f788460f21C181E86503ce1C88097865 | 2026-10-20 |
| ソースマップ（optimizerを切る） | 既定 runtime 7,353、命令3,933、項目3,932、移動の種類{-: 3641, i: 193, o: 98} / via-IR 7,615、命令4,631、項目4,630、{-: 3887, i: 537, o: 206}、ソース番号-1の項目3 | 2026-10-20 |
| memoryguard（via-IR、optimizerを切る） | MarketSlotsのデプロイのコード`memoryguard(0xe0)`（immutable三つで0x80・0xa0・0xc0）、ランタイム`memoryguard(0x80)` / RawCallerのデプロイのコード`memoryguard(0x80)`、ランタイム`mstore(64, 128)` | 2026-10-20 |
| via-IRの既定値 | solc 0.8.30ではfalse | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| structのメンバーのスロットの配置と、deleteが消す範囲 | [第135講](../../part8/lecture135/) |
| メモリの配置とmemoryguardの位置 | [第137講](../../part8/lecture137/) |
| optimizerの結果を検証する方法 | [第139講](../../part8/lecture139/)、[第140講](../../part8/lecture140/) |
| メタデータのsettingsと、検証サービスが見せる経路 | [第142講](../../part8/lecture142/) |
| optimizerとvia-IRを一緒に入れるかどうか | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| すでにデプロイしたコントラクトを新しいビルドに変える構造 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 二つのビルドの動作をツールで突き合わせる | [第183講](../../part11/lecture183/) |
| コンパイラのバージョン・経路ごとの既知のバグ | [第184講](../../part11/lecture184/)、[第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 監査でビルドの設定と成果物を確かめる | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
