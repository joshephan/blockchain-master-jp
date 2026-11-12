# 第143講 保存アクセスのコスト感覚と最適化の優先順位

第9部 最適化と規律・第36章 ガス最適化

[← 第142講](../../part8/lecture142/) | [第9部 目次](../) | [第144講 →](../../part9/lecture144/)

## この講義の問い

1回の呼び出しにかかるガスはどこで出ていくのか。その感覚で減らす場所の順番をどう決め、減らす代わりに何が一緒に変わるのかをどう数えるのか。

## 実習資料

### 準備

通しプロジェクトMarketの第142講のバージョンから始める。第143講のバージョンはコードが第142講のバージョンと同じで、バージョン説明のコメントを1行足しただけである。テストにはforge-stdが必要である（`lib/forge-std`）。ガスはバージョンごとに新しいanvilを立ち上げ、MockTokenとMarketをデプロイしたあと、addAsset 75、deposit 100、withdraw 30、setStatus 1、setStatus 0、失敗するdeposit 0を順に送り、レシートのgasUsedで測る。命令別の内訳は、anvilで`debug_traceTransaction`の構造化ログを受け取り、命令の種類ごとに足したものである（深さ1の命令ごとに、次の深さ1の命令までの残りガスの差。呼び出しは内側を含む）。命令一つの値は、optimizerを切った`cost`プロファイルでビルドしたCost143で、関数ごとにトランザクションを一つ送って見る。欄のパッキングとチェックの削除はどちらもMarketのコピーで行い、プロジェクトのバージョンは変えていない。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30、optimizerオン runs 200、evm_version osaka、`ir`・`debug`プロファイル |
| [code/market/src/Market.sol](code/market/src/Market.sol) | Market第143講のバージョン（第142講のバージョンとコードは同じ、バージョン説明のコメントを1行追加） |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | インターフェース、イベント、カスタムエラー |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | 帳簿計算のライブラリ |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | `Amount`ユーザー定義値型と演算子、`Position`構造体 |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/](code/market/test/) | テスト17ファイル（63個のテスト） |
| [code/demo/foundry.toml](code/demo/foundry.toml) | 命令のガスを見る`cost`プロファイル（optimizerオフ） |
| [code/demo/src/Cost143.sol](code/demo/src/Cost143.sol) | ストレージの欄の読み書き、transient、ログ、ハッシュ、外部呼び出しを一回ずつ行うCost143と、呼び出し先のOther143 |
| [code/packed/src/](code/packed/src/) | 欄のパッキングのコピーで変わった四つのファイル。`Position`の金額の欄をuint128に狭め、depositedとlastUpdateを一つの欄に置く。ほかのファイルはmarketと同じ |
| [code/unchecked-sub/src/MarketTypes.sol](code/unchecked-sub/src/MarketTypes.sol) | 演算子`-`（subAmount）の本体を`unchecked`で囲んだコピー。ほかのファイルはmarketと同じ |
| [code/no-assert/src/Market.sol](code/no-assert/src/Market.sol) | withdrawの`assert`の行だけを抜いたコピー |
| [code/no-check/src/MarketMath.sol](code/no-check/src/MarketMath.sol) | `InsufficientDeposit`チェックの行だけを抜いたコピー |

### 実行結果

Market第143講のバージョンの呼び出しごとにガスを分けた結果である。`by`はMarket側の命令の種類別のガス、`callee`はトークン呼び出しの内側である。

```
market 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 deploy 867827
deposit 100 {"status": 1, "gasUsed": 128297, "calldata": 68, "intrinsic": 21572, "exec": 106725, "refund": 0, "limit_minus_start": 21572, "by": {"other": 1573, "SLOAD": 10500, "KECCAK": 210, "SSTORE": 60000, "CALL": 32686, "LOG": 1756}, "count": {"other": 482, "SLOAD": 5, "KECCAK": 5, "SSTORE": 3, "CALL": 1, "LOG": 1}, "sstore_each": [20000, 20000, 20000], "callee": {"other": 802, "SLOAD": 6300, "KECCAK": 84, "SSTORE": 22900}, "callee_count": {"other": 246, "SLOAD": 3, "KECCAK": 2, "SSTORE": 2}}
setStatus 1 {"status": 1, "gasUsed": 45224, "calldata": 36, "intrinsic": 21204, "exec": 24020, "refund": 0, "limit_minus_start": 21204, "by": {"other": 658, "SLOAD": 2100, "SSTORE": 20000, "LOG": 1262}, "count": {"other": 186, "SLOAD": 1, "SSTORE": 1, "LOG": 1}, "sstore_each": [20000], "callee": {}, "callee_count": {}}
setStatus 0 {"status": 1, "gasUsed": 23312, "calldata": 36, "intrinsic": 21192, "exec": 6920, "refund": 4800, "limit_minus_start": 21192, "by": {"other": 658, "SLOAD": 2100, "SSTORE": 2900, "LOG": 1262}, "count": {"other": 186, "SLOAD": 1, "SSTORE": 1, "LOG": 1}, "sstore_each": [2900], "callee": {}, "callee_count": {}}
deposit 100 again {"status": 1, "gasUsed": 59897, "calldata": 68, "intrinsic": 21572, "exec": 38325, "refund": 0, "limit_minus_start": 21572, "by": {"other": 1573, "SLOAD": 10500, "KECCAK": 210, "SSTORE": 8700, "CALL": 15586, "LOG": 1756}, "count": {"other": 482, "SLOAD": 5, "KECCAK": 5, "SSTORE": 3, "CALL": 1, "LOG": 1}, "sstore_each": [2900, 2900, 2900], "callee": {"other": 802, "SLOAD": 6300, "KECCAK": 84, "SSTORE": 5800}, "callee_count": {"other": 246, "SLOAD": 3, "KECCAK": 2, "SSTORE": 2}}
```

最初のdeposit 100の128,297のうち、ストレージの欄の読み書き（トークン呼び出しの内側を含む）が99,700（78%）で、残りの命令482個は1,573（1.2%）である。同じアカウントがもう一度預けると、書き込み三つの欄が20,000から2,900に下がり、59,897になる。

Cost143で関数ごとにトランザクションを一つ送り、命令のgasCostを読んだ結果：

```
readOnce()  | gasUsed 23496 | SLOAD 2100
readThree()  | gasUsed 24147 | SLOAD 2100, SLOAD 100, SLOAD 100
writeA(uint256) 5 | gasUsed 43785 | SSTORE 22100
writeA(uint256) 6 | gasUsed 26685 | SSTORE 5000
writeA(uint256) 6 | gasUsed 23885 | SSTORE 2200
writeA(uint256) 0 | gasUsed 21873 | SSTORE 5000
writeSame()  | gasUsed 23509 | SLOAD 2100, SSTORE 100
tWriteRead(uint256) 9 | gasUsed 22032 | TSTORE 100, TLOAD 100
logs()  | gasUsed 26470 | LOG1 750, LOG2 1125, LOG3 1500, LOG1 1262
hash(bytes) 0x1111111111 | gasUsed 23140 | KECCAK256 36
hash(bytes) 0x1111111111 | gasUsed 34690 | KECCAK256 90
callTwice()  | gasUsed 28017 | SLOAD 2100, STATICCALL 2910, SLOAD 100, STATICCALL 410
```

`writeA(0)`は0を書く書き込みなので4,800が返金される。`hash`の2行は32バイトと320バイトの入力である。

バージョンごとに新しいanvilにデプロイして測ったレシートのgasUsed（`[成功かどうか, gasUsed]`、アドレスの欄は省略）：

```
s143 ... {"deploy": 867827, "addAsset": [1, 92576], "deposit100": [1, 128297], "withdraw30": [1, 57856], "setStatus1": [1, 45224], "setStatus0": [1, 23312], "failDeposit0": [0, 26409]}
packed ... {"deploy": 897789, "addAsset": [1, 92576], "deposit100": [1, 106378], "withdraw30": [1, 52901], "setStatus1": [1, 45224], "setStatus0": [1, 23312], "failDeposit0": [0, 26409]}
v1_uncheckedSub ... {"deploy": 857226, "addAsset": [1, 92576], "deposit100": [1, 128297], "withdraw30": [1, 57545], "setStatus1": [1, 45224], "setStatus0": [1, 23312], "failDeposit0": [0, 26409]}
only_noAssert ... {"deploy": 860258, "addAsset": [1, 92576], "deposit100": [1, 128297], "withdraw30": [1, 57737], "setStatus1": [1, 45224], "setStatus0": [1, 23312], "failDeposit0": [0, 26409]}
only_noCheck ... {"deploy": 858090, "addAsset": [1, 92576], "deposit100": [1, 128297], "withdraw30": [1, 57727], "setStatus1": [1, 45224], "setStatus0": [1, 23312], "failDeposit0": [0, 26409]}
```

欄をパッキングしたバージョンは、最初のdepositが128,297から106,378に、withdrawが57,856から52,901に減るが、デプロイは867,827から897,789に増えた。チェックを一つ抜いたバージョンのwithdrawは119〜311ガス減った。

`forge build --sizes`のMarketのサイズ（runtime / creation）：default 3,755 / 4,013、`FOUNDRY_PROFILE=debug` 7,353 / 7,931、`FOUNDRY_PROFILE=ir` 3,260 / 3,473。三つのプロファイルとも`forge test` 63個が通る。

### 試すときの注意

- 欄をパッキングしたコピーに第143講のバージョンの`test/`をそのまま付けると、Getters・Layout・Library・Rebuild・WithdrawAllの五つのファイルがコンパイルエラーになり、残り49個のうちAbiShapeの`test_returnDataBytes`一つが失敗する。欄の配置を変えると、スロットマップ、`positions`の戻り値の型（ABI）、金額が欄に入る場所ごとの範囲チェック、テストが一緒に変わる。
- Market.solのバージョン説明コメントの「(トークン呼び出しの内側を含む)」は、トークン呼び出しの内側まで含めた割合という意味である（99,700 / 128,297 = 77.7%）。Market側だけを数えると70,500で55%である。
- トークン呼び出しの32,686は、内側の30,086と、初めて触れるトークンのアドレスの2,600を足した値である。
- 欄をパッキングしたバージョンでは、Market側のSLOADが最初のdepositで10,500から8,500に減る。
- 設定を変えたビルドはコピーで行う。プロジェクトのバージョンでは、via-IRは`FOUNDRY_PROFILE=ir`でだけオンにする。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンやハードフォークが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。Market第143講のバージョンはdefaultがoptimizerオン runs 200・via-IRオフ、debugがoptimizerオフ、irがvia-IR + optimizer、evm_version osaka。Cost143は`cost`プロファイル（optimizerオフ） | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3、anvilの既定のハードフォークで実測 | 2026-10-20 |
| 公式ドキュメントの版 | v0.8.36。`docs/internals/layout_in_storage.rst` 141〜162行（warning）、`docs/security-considerations.rst` 133〜145行（Gas Limit and Loops） | 2026-10-20 |
| EIP-2200 | イスタンブール（2019-12-08）：SSTOREの初回の書き込み・書き換え・同じ値の分岐 | 2026-10-20 |
| EIP-2929 | ベルリン（2021-04-15）：初めて読む欄のSLOAD 2,100・再読 100、初めて触れるアドレス 2,600。実測SSTORE 0 → 値 22,100、値 → 別の値 5,000、同じ値 2,200（読んだあとは100） | 2026-10-20 |
| EIP-3529 | ロンドン（2021-08-05）：0を書くときの返金4,800、返金の上限はgasUsedの5分の1。実測writeA(0) gasUsed 21,873、setStatus 0 返金4,800 | 2026-10-20 |
| EIP-1153 | カンクン（2024-03-13）：TSTORE・TLOAD 100 | 2026-10-20 |
| EIP-7623 | プラハ（2025-05-07）：calldataの下限値 21,000 + 10 × トークン（トークン = 0のバイト数 + 4 × 0でないバイト数）。Market deposit 100の下限値22,430 < gasUsed 128,297なのでかからない。Cost143 hash 32バイトgasUsed 23,140・320バイト34,690 = 下限値 | 2026-10-20 |
| ログ・ハッシュのガス | LOG 375 + トピックごとに375 + dataのバイトごとに8、KECCAK256 30 + 32バイトごとに6（実測と同じ） | 2026-10-20 |
| 基本コスト | 21,000 + calldataの0のバイト4・0でないバイト16。deposit 100は68バイト（0が43個、0でないものが25個）で21,572 | 2026-10-20 |
| 測定方法 | バージョンごとに新しいanvil、ブロック間隔1秒（`anvil_setBlockTimestampInterval 1`）、アカウント0番がMockToken（0x5FbD…0aa3）→ Market（0xe7f1…0512、引数はアカウント0番・5e16・80）、addAsset 75 → deposit 100 → withdraw 30 → setStatus 1 → setStatus 0 → 失敗するdeposit 0（`--gas-limit 100000`）。レシートのgasUsed。トレースの内訳は深さ1の命令ごとに次の深さ1の命令までの残りガスの差（呼び出しは内側を含む）、基本コストはcalldataの式 | 2026-10-20 |
| Market第143講のバージョンのガス | デプロイ867,827、addAsset 75 92,576、deposit 100 128,297、withdraw 30 57,856、setStatus 1 45,224、setStatus 0 23,312、失敗するdeposit 0 26,409、同じアカウントで再びdeposit 100 59,897（第142講のバージョンと同じ） | 2026-10-20 |
| コピーのガス | 欄のパッキング：デプロイ897,789、deposit 106,378、withdraw 52,901、再びdeposit 55,078、runtime 3,894 / 演算子unchecked：デプロイ857,226、withdraw 57,545、runtime 3,706 / assertだけ抜く：860,258、57,737、3,720 / InsufficientDepositだけ抜く：858,090、57,727、3,710 | 2026-10-20 |
| サイズ（runtime / creation） | 第143講のバージョンdefault 3,755 / 4,013、debug 7,353 / 7,931、ir 3,260 / 3,473 | 2026-10-20 |
| 行番号 | 第143講のバージョンのdeposit 0 src/Market.sol 153:33（debug）、NotActive 71行、`contract Market` 194行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| 前の講義の値 | 第28講 increment 26,439 / 43,539、第33講 セレクタ比較22、第47講 65,727 / 31,527、第64講 23,497 / 24,132、第74講 26,686 / 21,460 / 21,874、第89講 sumPlusEq 179、第104講 +24、第135講 43,820 / 43,762、第136講 52,881 / 44,200、第137講 451 / 180,641 | 2026-10-20 |
| アカウント | アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（anvilの既定のアカウント、公開されたテスト用の鍵） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Positionの欄のパッキングを決め直す（フィールドがすべて決まったあと） | [第253講](../../part20/lecture253/)〜[第264講](../../part20/lecture264/)（第70〜72章） |
| チェックを抜く最適化が引き起こすこと | [第144講](../../part9/lecture144/) |
| ガスの記録と回帰の確認、via-IRとoptimizerを一緒にオンにするか | [第145講](../../part9/lecture145/) |
| ループの上限と引き出しの設計 | [第150講](../../part9/lecture150/) |
| ブロックガスリミットと手数料市場 | [第229講](../../part17/lecture229/)〜[第234講](../../part17/lecture234/) |
| 欄の配置がアップグレードで持つ意味 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
