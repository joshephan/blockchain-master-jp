# 第123講 アセンブリを使った最適化の手法

第7部 アセンブリとYul・第27章 インラインアセンブリ

[← 第122講](../../part7/lecture122/) | [第7部 目次](../) | [第124講 →](../../part7/lecture124/)

## この講義の問い

アセンブリに変えて減るガスは正確にはどこから出てきて、それを何で測るべきで、Marketにはなぜ入れないのか。

## 実習資料

### 準備

`demo`は`Opt123.sol`一つだけを置いたFoundryのプロジェクトである。同じソースを、optimizerを切ったバージョン（既定値）と入れたバージョン（foundry.tomlに`optimizer = true`、`optimizer_runs = 200`を足す）の二通りでビルドして比べた。`market`は通しプロジェクトMarketの第123講のバージョンで、`market-asm`はそのバージョンから二つの関数の本体だけをアセンブリに変えた比較用のバージョンである（Marketには入れなかった）。どれもsolc 0.8.30、既定（レガシー）のパイプラインで、テストにはforge-stdが必要である。ガスは、ローカルのanvil（既定のハードフォーク）にバージョンごとに新しくデプロイして測った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | optimizerを切ったバージョン。入れたバージョンは`optimizer = true`、`optimizer_runs = 200`の2行だけを足す |
| [code/demo/src/Opt123.sol](code/demo/src/Opt123.sol) | 同じことを3通りに書いた三つの組。配列の合計（SumSol・SumUnchecked・SumAsm）、リバート（ErrSol・ErrAsm）、状態変数の読み取り（ReadTwice・ReadCached・ReadUnchecked・ReadAsm） |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第123講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第123講のバージョン。アセンブリブロック0個 |
| [code/market/test/Assembly.t.sol](code/market/test/Assembly.t.sol) | 前の講義のテスト用のコントラクトにNoAssemblyTest（あふれる入力で`interestFor`がPanic 0x11でリバートするか）を追加 |
| [code/market/test/](code/market/test/) | Marketのテスト55個 |
| [code/market-asm/src/MarketMath.sol](code/market-asm/src/MarketMath.sol) | 比較用のバージョン。`InterestMath.interestFor`をアセンブリで書いた（オーバーフローのチェックなし） |
| [code/market-asm/src/Market.sol](code/market-asm/src/Market.sol) | 比較用のバージョン。`MarketBase._checkAdmin`をアセンブリで書いた（リバートデータ`NotAdmin(caller)`の36バイトはそのまま） |

`market-asm`の残りのファイル（foundry.toml、srcのほかのファイル、test）は`market`と同じである。

### 実行結果

配列の合計（要素は1から100まで、答えは5050 = 0x13ba）。optimizerを入れたバージョンで、`cast call --trace`のいちばん上の行はSumSol 18,153、SumAsm 7,272なのに、最後の`Gas used`はどちらも56,860である。

```
Traces:
  [18153] 0x5FbDB2315678afecb367f032d93F642f64180aa3::sum([1, 2, 3, ..., 100])
    └─ ← [Return] 0x00000000000000000000000000000000000000000000000000000000000013ba

Transaction successfully executed.
Gas used: 56860
```

```
Traces:
  [7272] 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0::sum([1, 2, 3, ..., 100])
    └─ ← [Return] 0x00000000000000000000000000000000000000000000000000000000000013ba

Transaction successfully executed.
Gas used: 56860
```

三つの組の実行ガス（トレースのいちばん上の行）とgasUsed。

| 組 | 切ったバージョンの実行 | 入れたバージョンの実行 | gasUsed |
|---|---|---|---|
| 合計、要素100（Sol / unchecked / Asm） | 31,176 / 29,888 / 7,481 | 18,153 / 18,158 / 7,272 | 切ったバージョン 66,520 / 65,232 / 56,860、入れたバージョン 三つとも56,860 |
| リバート check(0)（Sol / Asm） | 436 / 405 | 262 / 225 | 入れたバージョン どちらも21,480 |
| 状態変数の読み取り f()（2回 / 1回 / unchecked / Asm） | 3,040 / 2,854 / 2,435 / 2,428 | 2,445 / 2,450 / 2,259 / 2,259 | |

入れたバージョンで、ReadUncheckedとReadAsmのランタイムコードは末尾の53バイト（メタデータ）を除いて同じである。ErrSolとErrAsmのリバートデータは、どちらも`0x1f2a2005`（ZeroAmount）である。

トランザクションのgasUsedは、calldataの下限値より低くならない。下限値は21,000 + 10 ×（0のバイト数 + 4 × 0でないバイト数）で、手で計算した値が測定値と一致する。

| 呼び出し | calldata | 下限値 |
|---|---|---|
| check(5) | 36バイト（0が31、0でないものが5） | 21,510 |
| check(0) | 36バイト（0が32、0でないものが4） | 21,480 |
| interestFor(1000e18, 5e16, 31536000) | 100バイト（0が80、0でないものが20） | 22,600 |
| sum、要素100 | 3,268バイト（0が3,162、0でないものが106） | 56,860 |

Marketの二つのバージョン（optimizerを入れる）で、`interestFor(1000e18, 5e16, 31536000)`の実行ガスは元のバージョン725、アセンブリのバージョン391で、gasUsedはどちらも22,600である。アカウント1番が呼んだ`setStatus(1)`は、どちらも同じデータでリバートする。

```
Error: execution reverted: NotAdmin(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
```

`interestFor(2**200, 5e16, 31536000)`は、元のバージョンがリバートし、アセンブリのバージョンはあふれた値を返す。

```
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
```

```
2993799163073923480010332860587816099299237424794285 [2.993e51]
```

そのためアセンブリのバージョンの`forge test`は、54個が通り、1個が失敗する。

```
[FAIL: next call did not revert as expected] test_interestForOverflowPanics()
```

Market 第123講のバージョンは、`forge test`の55個がすべて通り、Market runtime 7,353 / creation 7,931、`grep -n assembly src/*.sol`は0行である。

### 試すときの注意

- ガスはoptimizerを入れたバージョンで測り、トレースのいちばん上の行の実行ガスで比べる。トランザクションのgasUsedには、calldataの下限値が混ざることがある。
- anvilの既定のハードフォークでは、calldataの下限値（EIP-7623）が適用される。実行ガスが小さい呼び出しは、互いに違っていてもgasUsedが同じに出る。
- デプロイ・トランザクションのガスをバージョンどうしで比べるときは、バージョンごとにanvilを新しく立ち上げ、同じ順序（MockTokenのあとにMarket）でデプロイした。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやハードフォークが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、既定（レガシー）のパイプライン。切ったバージョンはoptimizerを切る（既定値）、入れたバージョンは`optimizer = true`、`optimizer_runs = 200` | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | 2026-10-19 |
| anvilのハードフォーク | 既定値（latest、Prague以降の規則）。calldataの下限値が適用される | 2026-10-19 |
| calldataの下限値 | EIP-7623: 21,000 + 10 ×（0のバイト数 + 4 × 0でないバイト数）。もとのcalldataの値は0のバイトが4、0でないバイトが16（EIP-2028）。gasUsedはもとの計算と下限値の大きいほう。Pectraハードフォーク | 2026-10-19 |
| 合計の計算（要素100） | 切ったバージョン 実行31,176 / 29,888 / 7,481、gasUsed 66,520 / 65,232 / 56,860。入れたバージョン 実行18,153 / 18,158 / 7,272、gasUsed 三つとも56,860。要素10: 切ったバージョン 実行3,726 / 3,608 / 1,361・gasUsed 26,470 / 26,352 / 25,360、入れたバージョン 実行2,223 / 2,228 / 1,152・gasUsed 三つとも25,360。要素1: 切ったバージョン 実行981 / 980 / 749・gasUsed 22,465 / 22,464 / 22,233、入れたバージョン 実行630 / 635 / 540・gasUsed 三つとも22,210 | 2026-10-19 |
| サイズ（ランタイム / initcode） | 切ったバージョン SumSol 593 / 621、SumUnchecked 596 / 624、SumAsm 418 / 446、ErrSol 351 / 379、ErrAsm 290 / 318、ReadTwice 417 / 449、ReadCached 420 / 452、ReadUnchecked 225 / 256、ReadAsm 222 / 253。入れたバージョン 370 / 398、372 / 400、277 / 305、187 / 213、175 / 201、223 / 254、225 / 256、138 / 168、138 / 168 | 2026-10-19 |
| 状態変数の読み取り f() | 切ったバージョン 実行3,040 / 2,854 / 2,435 / 2,428（estimate 24,104 / 23,918 / 23,499 / 23,492）、入れたバージョン 2,445 / 2,450 / 2,259 / 2,259（estimate 23,509 / 23,514 / 23,323 / 23,323）。入れたバージョンのReadUnchecked・ReadAsmのランタイムコードは末尾の53バイト（メタデータ）を除いて同じ | 2026-10-19 |
| リバート check | 切ったバージョン check(5) estimate 21,797 / 21,792（実行593 / 588）、check(0) status 0 gasUsed 21,628 / 21,597（実行436 / 405）。入れたバージョン check(5) 21,510 / 21,510（実行271 / 266）、check(0) 21,480 / 21,480（実行262 / 225）。リバートデータはどちらも0x1f2a2005 | 2026-10-19 |
| calldataの手計算 | check(5) 36バイト（0が31・0でないものが5）下限21,510、check(0) 36バイト（32・4）21,480、interestFor(1000e18, 5e16, 31536000) 100バイト（80・20）22,600、sum 要素100 3,268バイト（3,162・106）56,860・もとのcalldataの値14,344、要素10 388バイト（372・16）25,360、要素1 100バイト（93・7）22,210 | 2026-10-19 |
| Marketの四つのバージョンのサイズ | 元のバージョン 切る7,353 / 7,931、入れる3,755 / 4,013。アセンブリのバージョン 切る7,078 / 7,656、入れる3,636 / 3,894 | 2026-10-19 |
| Marketの四つのバージョンのgasUsed | デプロイ・interestFor estimate・addAsset 75・deposit 100・withdraw 30・setStatus 1・setStatus 0・失敗するdeposit 0: 元のバージョン 切る1,645,279、23,497、93,730、130,478、59,911、45,732、23,820、26,869 / 元のバージョン 入れる867,827、22,600、92,576、128,297、57,856、45,224、23,312、26,409 / アセンブリのバージョン 切る1,586,480、22,677、93,730、130,478、59,911、45,732、23,820、26,869 / アセンブリのバージョン 入れる842,065、22,600、92,563、128,297、57,856、45,211、23,299、26,409 | 2026-10-19 |
| Marketの四つのバージョンの実行ガス | interestFor(1000e18, 5e16, 31536000) 1,857 / 725 / 1,037 / 391、管理者のsetStatus(1) 24,528 / 24,020 / 24,528 / 24,007、アカウント1番のsetStatus(1)のリバート686 / 418 / 467 / 350（元のバージョン切る / 元のバージョン入れる / アセンブリのバージョン切る / アセンブリのバージョン入れる） | 2026-10-19 |
| 2の200乗 | interestFor(2**200, 5e16, 31536000): 元のバージョン二つは`panic: arithmetic underflow or overflow (0x11)`、アセンブリのバージョン二つは2993799163073923480010332860587816099299237424794285 | 2026-10-19 |
| テスト | 基準のバージョンは55個が通る（NoAssemblyTest 1個を追加）。アセンブリのバージョンは切る・入れるとも54個が通り1個が失敗`[FAIL: next call did not revert as expected] test_interestForOverflowPanics()`（gas 10481 / 8660） | 2026-10-19 |
| デプロイのアドレス | Opt123の入れたバージョン、新しく立ち上げたanvilでアカウント0番がデプロイした順にSumSol 0x5FbDB2315678afecb367f032d93F642f64180aa3、SumUnchecked 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512、SumAsm 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0、ErrSol 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9、ErrAsm 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9、ReadTwice 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707、ReadCached 0x0165878A594ca255338adfa4d48449f69242Eb8F、ReadUnchecked 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853、ReadAsm 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 / アカウント0番 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266、アカウント1番 0x70997970C51812dc3A010C7d01b50e0d17dc79C8（公開されたテスト用の鍵） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Yulだけでコントラクトを書くオブジェクトの構造と最適化のステップ | [第124講](../../part7/lecture124/)、[第125講](../../part7/lecture125/) |
| コマンドラインとStandard JSONでのoptimizer・via-IRの設定 | [第128講](../../part8/lecture128/) |
| IRコード生成で変わるガスと移行 | [第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| optimizerのステップごとの動作と結果の検証 | [第139講](../../part8/lecture139/)、[第140講](../../part8/lecture140/) |
| ガス最適化の優先順位と判断、ベンチマーク | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| ディスパッチャの比較の順序とガス | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| calldataのコストと下限値の規則 | [第143講](../../part9/lecture143/) |
| あふれる入力を不変条件・ファジングで見つけること | [第183講](../../part11/lecture183/) |
| 監査でアセンブリブロックを読むことと判定 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
