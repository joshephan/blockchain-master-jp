# 第144講 最適化がセキュリティを損なうところ

第9部 最適化と規律・第36章 ガス最適化

[← 第143講](../../part9/lecture143/) | [第9部 目次](../) | [第145講 →](../../part9/lecture145/)

## この講義の問い

ガスを節約するコードは、何を抜いてガスを節約するのか。抜いたものが防いでいた呼び出しはどうなり、残ったチェックとテストはそれをどこまで捕まえるのか。

## 実習資料

### 準備

通しプロジェクトMarketの第143講のバージョンから始める。第144講のバージョンはコードが第143講のバージョンと同じで、引き出しのチェックを確かめるテスト`test/Guards.t.sol`とバージョン説明のコメント1行を足した。テストにはforge-stdが必要である（`lib/forge-std`）。チェックを抜いたバージョンと欄をパッキングしたバージョンはどれもMarketのコピーで、プロジェクトのバージョンは変えていない。ガスは第143講と同じ方法（バージョンごとに新しいanvil、レシートのgasUsed）で測った。ハードフォークの比較は、`istanbul`プロファイルで一度ビルドしたFixed144を`anvil --hardfork istanbul|berlin|osaka`の三つに同じバイトコードで載せ（istanbul・berlinのanvilには`--legacy`トランザクション）、`cast call`で`peek`を呼ぶ。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30、optimizerオン runs 200、evm_version osaka、`ir`・`debug`プロファイル |
| [code/market/src/](code/market/src/) | Market第144講のバージョン（第143講のバージョンとコードは同じ） |
| [code/market/test/Guards.t.sol](code/market/test/Guards.t.sol) | oneが900、twoが1を預けた市場でtwoが901を引き出すと`InsufficientDeposit(1, 901)`で巻き戻り、残高がそのままかを確認 |
| [code/market/test/](code/market/test/) | テスト18ファイル（64個のテスト） |
| [code/v1-unchecked-sub/src/MarketTypes.sol](code/v1-unchecked-sub/src/MarketTypes.sol) | v1：演算子`-`（subAmount）の本体を`unchecked`で囲む |
| [code/v2-no-check/src/](code/v2-no-check/src/) | v2：v1に加えて`MarketMath.sol`の`InsufficientDeposit`チェックの行を抜く |
| [code/v3-no-assert/src/](code/v3-no-assert/src/) | v3：v2に加えて`Market.sol`の`assert`の行まで抜く |
| [code/v3-no-assert/test/Drain.t.sol](code/v3-no-assert/test/Drain.t.sol) | 引き出しのデモのテスト。コピーごとに同じファイルを入れて実行 |
| [code/packed/src/](code/packed/src/) | 欄をパッキングしたバージョン（金額の欄uint128）。金額を欄に入れる場所に`AmountTooLarge`の範囲チェック |
| [code/packed-naive/src/](code/packed-naive/src/) | 欄をパッキングしたバージョンから範囲チェックを抜き、`uint128(amount)`でそのまま書いたバージョン |
| [code/packed/test/Narrow.t.sol](code/packed/test/Narrow.t.sol)、[code/packed-naive/test/Narrow.t.sol](code/packed-naive/test/Narrow.t.sol) | 2の128乗 + 5を`deal`で受け取って預け、帳簿の三つの値を出力するテスト（二つのバージョンに同じファイル） |
| [code/demo/foundry.toml](code/demo/foundry.toml) | `istanbul`プロファイル（evm_version istanbul、PUSH0なし） |
| [code/demo/src/Fixed144.sol](code/demo/src/Fixed144.sol) | 値を一つ持つBox144と、渡すガスを2000に決めておいてその値を読むFixed144 |

コピーのフォルダにはmarketと違うファイルだけを入れた。ほかのファイルはmarketと同じである。

### 実行結果

コピーごとの`forge test`（テスト64個、Drainのテストを含む）の結果：

| バージョン | 結果 | 失敗したテスト |
|---|---|---|
| 第144講のバージョン（チェック三つすべて） | 64個通過 | なし |
| v1 演算子unchecked | 63通過、1失敗 | `LibraryTest:test_amountOperators` |
| v2 + チェックの行を抜く | 60通過、4失敗 | Drain、ErrorData、ErrorList、Library |
| v3 + assertを抜く | 60通過、4失敗 | Drain、ErrorData、ErrorList、Library |
| assertの行だけを抜く | 64個通過 | なし |
| チェックの行だけを抜く | 61通過、3失敗 | Drain、ErrorData、ErrorList |

v1で失敗したテスト：

```
[FAIL: next call did not revert as expected] test_amountOperators() (gas: 4269)
```

v2では、引き出しのデモ（twoが901を引き出す）は`InsufficientDeposit`の代わりにassertのPanic 0x01で巻き戻る：

```
[FAIL: assertion failed: 0x4e487b710000000000000000000000000000000000000000000000000000000000000001 != 0x25c3f46e00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000385] test_withdrawMoreThanDeposit() (gas: 104049)
```

v3では同じ呼び出しが成功し、oneの取り分まで出ていく：

```
  ok true
  0x
  two token balance 901
  market token balance 0
  two deposited 115792089237316195423570985008687907853269984665640564039457584007913129639036
```

twoの預け入れ額は2の256乗 - 900（1 - 901が一周して回り込んだ値）である。

欄をパッキングした二つのバージョンに2の128乗 + 5を預けた結果。チェックを入れたバージョンは`AmountTooLarge`で巻き戻る：

```
  ok false
  0x08083b2a0000000000000000000000000000000100000000000000000000000000000005
  positions deposited 0
  totalDeposits 0
  market token balance 0
```

チェックを抜いたバージョンは呼び出しが成功し、帳簿と実際の残高が食い違う：

```
  ok true
  0x
  positions deposited 5
  totalDeposits 340282366920938463463374607431768211461
  market token balance 340282366920938463463374607431768211461
```

バージョンごとに新しいanvilにデプロイして測ったレシートのgasUsed：

| バージョン | デプロイ | deposit 100 | withdraw 30 |
|---|---|---|---|
| 第144講のバージョン | 867,827 | 128,297 | 57,856 |
| v1 演算子unchecked | 857,226 | 128,297 | 57,545 |
| v2 + チェックの行を抜く | 845,337 | 128,297 | 57,393 |
| v3 + assertを抜く | 829,544 | 128,297 | 57,185 |
| assertの行だけを抜く | 860,258 | 128,297 | 57,737 |
| チェックの行だけを抜く | 858,090 | 128,297 | 57,727 |
| 欄のパッキング、チェックあり | 897,789 | 106,378 | 52,901 |
| 欄のパッキング、チェックなし | 916,750 | 106,626 | 53,324 |

欄をパッキングしたバージョンは、チェックを抜いたほうがかえってガスが多くかかる。

Fixed144をハードフォークの違うanvil三つに載せて`peek`を呼んだ結果と、`Box144.v()`のSLOADのgasCost：

```
istanbul peek -> true 7 | Fixed144 code bytes 344
berlin peek -> false 0 | Fixed144 code bytes 344
osaka peek -> false 0 | Fixed144 code bytes 344
istanbul SLOAD gasCost [800] | v() gasUsed 22025
berlin SLOAD gasCost [2100] | v() gasUsed 23325
osaka SLOAD gasCost [2100] | v() gasUsed 23325
```

`cast sig "AmountTooLarge(uint256)"`は`0x08083b2a`である。Market第144講のバージョンの`src/`で`unchecked`・`assembly`・`{gas:`をgrepすると、バージョン説明のコメント1行のほかには出てこない。

### 試すときの注意

- v2・v3のビルドで`Warning (2072): Unused local variable.`が`src/MarketMath.sol:37:9`に出る（消したチェックの行が使っていた`have`）。v1は警告が出ない。
- v1のコピーのsubAmountの上のコメント（「Panic 0x11で巻き戻す」）はそのまま残っていて、コードと合わない。
- v2のErrorListTestの失敗0x11はMarketではなく`MockToken::transfer`から出る（`-vvvv`で確認）。
- assertの1行だけを抜いたバージョンは、Guardsのテストを入れてもすべてのテストが通る。前の二つのチェックが先に止めるので、その行を捕まえるテストがない。
- 欄をパッキングしたコピーの`IMarket.sol`の`AmountTooLarge`の行末のコメント`// 0x1f2a2005`は、ほかの行のコメントが移ってきたものである。実際のセレクタは`0x08083b2a`である。
- `istanbul`プロファイルでプロジェクト全体をビルドすると、Cost143のtransient変数のために失敗する。`src/Fixed144.sol`だけをビルドする。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンやハードフォークが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。第144講のバージョンはdefaultがoptimizerオン runs 200、debugがオフ、irがvia-IR + オン、evm_version osaka。デモ用プロジェクトのプロファイルistanbulはevm_version istanbul | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| 公式ドキュメントの版 | v0.8.36。`docs/control-structures.rst` 551〜552行、`docs/security-considerations.rst` 156、158行 | 2026-10-20 |
| anvilのハードフォーク名 | `--hardfork istanbul`、`berlin`、`osaka`（anvil 1.8.3の既定はosaka側の規則）。istanbul・berlinのanvilには`--legacy`トランザクション | 2026-10-20 |
| SLOADのガス | istanbul 800 / berlin・osaka 初回の読み込み2,100（再読100）。EIP-1884（Istanbul、2019-12-08）、EIP-2929（Berlin、2021-04-15） | 2026-10-20 |
| ハードフォーク別の結果 | `Fixed144.peek` istanbul `true 7` / berlin `false 0` / osaka `false 0`、Fixed144のコード344バイト、`v()`トランザクション22,025 / 23,325 / 23,325 | 2026-10-20 |
| Market第144講のバージョンのガス | バージョンごとに新しいanvil、ブロック間隔1秒、MockToken 0x5FbD…0aa3 → Market 0xe7f1…0512。デプロイ867,827、addAsset 75 92,576、deposit 100 128,297、withdraw 30 57,856、setStatus 1 45,224、setStatus 0 23,312、失敗するdeposit 0 26,409 | 2026-10-20 |
| コピーのガス | withdraw 30 / デプロイ：一つ抜いたバージョン57,545 / 857,226、二つ抜いたバージョン57,393 / 845,337、三つ抜いたバージョン57,185 / 829,544、assertだけ抜いたバージョン57,737 / 860,258、InsufficientDepositの行だけ抜いたバージョン57,727 / 858,090。パッキングしたバージョンのチェックあり / なし：deposit 100 106,378 / 106,626、withdraw 30 52,901 / 53,324、デプロイ897,789 / 916,750 | 2026-10-20 |
| サイズ（runtime / creation） | 第144講のバージョンdefault 3,755 / 4,013、debug 7,353 / 7,931、ir 3,260 / 3,473。コピーのruntime 3,706 / 3,651 / 3,578、assertだけ3,720、チェックの行だけ3,710、パッキングしたバージョン3,894 / 3,982 | 2026-10-20 |
| 第109講の値 | デプロイgasUsed Bare 171,408、NoArg 181,072、IfErr 192,536、ReqStr 208,812、巻き戻しデータ0 / 4 / 68 / 100バイト | 2026-10-19 |
| 第140講の値 | Gas140 `w.work{gas: 5000}(20)` オフのビルドok false（workの実行10,541）、オンのビルドok true（4,624） | 2026-10-20 |
| 行番号 | 第144講のバージョンdebug deposit 0 src/Market.sol 154:33、NotActive 72行、`contract Market` 195行、バージョン説明のコメント39行。コピーの警告src/MarketMath.sol:37:9。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（anvilの既定のアカウント、公開されたテスト用の鍵） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 引き出しの順序と他人のコードに移る制御 | [第150講](../../part9/lecture150/)、[第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| 監査で抜けたチェックを見つける | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| 金額の欄の大きさとトークンの小数点以下の桁数 | [第194講](../../part13/lecture194/)、[第195講](../../part13/lecture195/)、[第196講](../../part13/lecture196/) |
| ハードフォークごとに変わった命令のガス | [第229講](../../part17/lecture229/)〜[第234講](../../part17/lecture234/) |
| 失敗した呼び出しのガスとデバッグ | [第183講](../../part11/lecture183/) |
| Positionの欄のパッキングを決め直す | [第253講](../../part20/lecture253/)〜[第264講](../../part20/lecture264/)（第70〜72章） |
| ガスの記録と回帰の確認 | [第145講](../../part9/lecture145/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
