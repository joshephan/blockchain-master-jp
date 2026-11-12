# 第259講 不変条件とファジング

第20部 キャップストーンプロジェクト・第71章 検証と監査への対応

[← 第258講](../../part20/lecture258/) | [第20部 目次](../) | [第260講 →](../../part20/lecture260/)

## この講義の問い

設計ドキュメントに書いた不変条件を、どうやってランダムな順番で確かめるのか。通過は何を意味し、壊れたら何から見るのか。

## 実習資料

### 準備

通しプロジェクトMarketの第258講のバージョン（テストスイートのバージョン、テスト69）から始める。この講義でファズテスト五つ（`test/Fuzz.t.sol`）、不変条件テスト（`test/Invariant.t.sol`、不変条件六つ）、ハンドラー（`test/helpers/Handler.sol`）を加え、`foundry.toml`に`[fuzz]`（runs 256、seed `0x103`）と`[invariant]`（runs 128、depth 200、`fail_on_revert = false`、`show_metrics = true`）を置く。ciの6段階目のスナップショットは`--no-match-contract "FuzzTest|InvariantTest"`でファズ・不変条件を外す。Marketのコードはそのままである（末尾のメタデータハッシュ`47ac4829`）。依存関係はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0である。anvilは使わない。

`code/market/`がこの講義のバージョンである。`code/first/`は最初に書いたハンドラー（動作十三、openPositionなし）で、このバージョンの`test/helpers/Handler.sol`の位置に上書きし、`test/Invariant.t.sol`のセレクタをopenPositionのない十三に減らして実行する。講義で実行した残りの比較用コピーは、このバージョンと1〜2行だけが違う。

- 古いI-4の文の形：このバージョンのハンドラーのwithdraw・withdrawAllで`&& on`の二つだけを消す
- 残高の確認を抜いたハンドラー：このバージョンのハンドラーのliquidateで`vm.assume(StdToken(debtAsset).balanceOf(liq) >= amount);`の1行だけを消す
- わざと間違えたバージョン：`src/Market.sol` `_withdraw`の280行だけを変える

```diff
-        uint256 scaled = amount == have ? p.scaledDeposit : MarketMath.mulDivUp(amount, WAD, s); // 引く持ち分は切り上げ
+        uint256 scaled = amount == have ? p.scaledDeposit : MarketMath.mulDivDown(amount, WAD, s); // 変えたバージョン：引く持ち分を切り捨て
```

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、`fs_permissions`、debugプロファイル、`[fuzz]`・`[invariant]`の設定 |
| [code/market/abi/IMarket.json](code/market/abi/IMarket.json) | リポジトリに置いたABIファイル。ciがビルドとdiff |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | 外側の約束（ABI）：関数・イベント・エラーとNatSpec |
| [code/market/src/Market.sol](code/market/src/Market.sol) | レンディングマーケットの本体 |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | 利息の曲線・丸めの計算ライブラリ |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | 共有する型、価格の出どころのインターフェース |
| [code/market/test/Access.t.sol](code/market/test/Access.t.sol) | 権限の要件A-01〜A-05 |
| [code/market/test/Docs.t.sol](code/market/test/Docs.t.sol) | ABIの項目ごとにnoticeがあるか |
| [code/market/test/Errors.t.sol](code/market/test/Errors.t.sol) | エラー22ごとに、そのエラーで巻き戻るテスト一つ（巻き戻しデータ全体） |
| [code/market/test/Events.t.sol](code/market/test/Events.t.sol) | イベント11の引数すべて |
| [code/market/test/Functional.t.sol](code/market/test/Functional.t.sol) | 機能要件F-01〜F-10 |
| [code/market/test/Fuzz.t.sol](code/market/test/Fuzz.t.sol) | ファズ五つ：mulDivの丸め、利率の曲線の単調性、預けてすぐ引き出す、借りてすぐ返す、分けて引き出す |
| [code/market/test/Gas.t.sol](code/market/test/Gas.t.sol) | 測った呼び出し五つのガス |
| [code/market/test/Interface.t.sol](code/market/test/Interface.t.sol) | 関数の数とインターフェースID |
| [code/market/test/Invariant.t.sol](code/market/test/Invariant.t.sol) | 不変条件テスト（I-1〜I-5、一覧にない失敗0）。マーケットの準備（資産三つ、アカウント四つ）とハンドラーのセレクタ |
| [code/market/test/Layout.t.sol](code/market/test/Layout.t.sol) | ストレージの欄の地図どおりに置かれているか |
| [code/market/test/Math.t.sol](code/market/test/Math.t.sol) | 計算の部品の曲線の値と丸めの方向 |
| [code/market/test/Ops.t.sol](code/market/test/Ops.t.sol) | 運用の要件O-01〜O-02 |
| [code/market/test/Rebuild.t.sol](code/market/test/Rebuild.t.sol) | ログだけで数え直した合計と状態の比較 |
| [code/market/test/Safety.t.sol](code/market/test/Safety.t.sol) | 安全の要件S-01〜S-08 |
| [code/market/test/Standards.t.sol](code/market/test/Standards.t.sol) | 標準の対照表の行ごとの確認 |
| [code/market/test/Trust.t.sol](code/market/test/Trust.t.sol) | 信頼の前提のテスト（T-01 出どころの停止・平均の遅れ、T-03 同じブロック） |
| [code/market/test/helpers/Accounts.sol](code/market/test/helpers/Accounts.sol) | テスト用のアカウントのコード二つ |
| [code/market/test/helpers/Base.sol](code/market/test/helpers/Base.sol) | テスト共用の土台（COL・USD、価格の出どころ二つ、前のバージョンと同じ場面） |
| [code/market/test/helpers/Handler.sol](code/market/test/helpers/Handler.sol) | 最後のハンドラー：動作十四（openPositionを含む）、価格0.2〜2.0、絞った入力、正常な失敗の一覧と成功数の数え上げ |
| [code/market/test/helpers/HookToken.sol](code/market/test/helpers/HookToken.sol) | 移される瞬間にMarketの帳簿を読んで書き留めるテスト用トークン |
| [code/market/test/helpers/MultiSigAdmin.sol](code/market/test/helpers/MultiSigAdmin.sol) | テスト用のマルチシグ |
| [code/market/test/helpers/OddTokens.sol](code/market/test/helpers/OddTokens.sol) | 標準と違う動きをするテスト用トークン（手数料トークンなど） |
| [code/market/test/helpers/StdToken.sol](code/market/test/helpers/StdToken.sol) | テスト用の標準トークン |
| [code/market/test/helpers/TwapFeed.sol](code/market/test/helpers/TwapFeed.sol) | テスト用の価格の出どころ（積み上がった価格の合計、`stop()`、権限のない`setPrice`） |
| [code/first/test/helpers/Handler.sol](code/first/test/helpers/Handler.sol) | 最初のハンドラー：どのアカウント・どの金額でも、動作十三（openPositionなし） |

### 実行結果

設計ドキュメント5節の不変条件とテスト：

| テスト | 文 | 確認 |
|---|---|---|
| invariant_I1_vaultCoversPromises | 資産ごとに金庫 + 貸し出した借金 ≥ アカウント四つの引き出せる量の合計 | 手順のあとの状態 |
| invariant_I2_sharesAddUp | 持ち分の合計の欄 = アカウントの持ち分の合計（預ける側・借りる側） | 手順のあとの状態 |
| invariant_I3_indexes | 借りる側の指数は下がらない、預ける側は借金の消去でだけ | 呼び出しごとにハンドラーが数える |
| invariant_I4_healthAfterSuccess | 借り入れなどが成功した直後に借金の値 ≤ 上限 | 呼び出しごとにハンドラーが数える |
| invariant_I5_exitsNotBlocked | 引き出す道が停止・キーのエラーで失敗するのは0 | 呼び出しごとにハンドラーが数える |
| invariant_noUnexpectedFailure | 一覧にない失敗（Panic、空の巻き戻し）0 | 呼び出しごとにハンドラーが数える |

ファズ四つ（`forge test --offline --match-contract FuzzTest`）はすべて`runs: 256`で通過した。入力の範囲は`test/Fuzz.t.sol`のとおりである（mulDivはa・bがuint120以下、利率の曲線は借りた比率0〜200%、預けてすぐ引き出すは待ち時間1秒〜3650日・2〜10,000 USD、借りてすぐ返すは30日後に1〜40 USD）。

最初のハンドラーで`FOUNDRY_INVARIANT_RUNS=64 FOUNDRY_INVARIANT_DEPTH=100 forge test --offline --match-contract InvariantTest`。不変条件六つは通過したが、清算・借金の消去は一度も成功しなかった（成功 = Calls − Reverts − Discards）：

```
 InvariantTest invariants (runs: 64, calls: 6400, reverts: 2053)
| Contract | Selector      | Calls | Reverts | Discards |
| Handler  | borrow        | 694   | 662     | 0        |
| Handler  | liquidate     | 659   | 13      | 646      |
| Handler  | repay         | 609   | 7       | 598      |
| Handler  | withdraw      | 647   | 492     | 0        |
| Handler  | writeOff      | 589   | 589     | 0        |
```

絞ったハンドラーで最初に壊れたのはI-4である（古いI-4の文の形のコピー）。縮めた手順は次のとおりで、長さと引数は実行ごとに違う。行末の`//`は手で付けたコメントである：

```
[FAIL: assertion failed: 1 != 0] invariant_I4_healthAfterSuccess
  [Sequence] (original: 140, shrunk: 6)
  calldata=openPosition(...)   // carol: COLを預けて担保としてオンにし、FEEを借りる
  calldata=deposit(...)        // carol: USDを預ける（担保ではない）
  calldata=setPrice(...)       // COLの価格を0.64に下げる
  calldata=setPrice(...)       // FEEの価格が上がる
  calldata=warp(...)           // 約9.9日
  calldata=withdrawAll(...)    // carol: USDを全部引き出す → 直後に借金の値 > 上限
```

コードは、引き出す資産が担保としてオンになっているときだけ上限を見る。間違っていたのは不変条件の文の方なので、5節のI-4を「borrow、担保としてオンにした資産のwithdraw、担保のオフが成功した直後に、そのアカウントの借金の値 ≤ 借りられる上限（担保ではない資産の引き出しは上限を見ない、S-01）」に直し、ハンドラーも同じように直した。Marketのコードは直していない。

次に壊れたのは一覧にない失敗である（残高の確認を抜いたハンドラーのコピー）。`forge test --offline --mt invariant_noUnexpectedFailure -vvvv`で、保存された失敗の手順を再実行した跡：

```
[FAIL: 0x4e487b71: 1 != 0] invariant_noUnexpectedFailure
├─ Market::liquidate(alice, FeeSwitchToken, StdToken(COL), 3023029136650787704159 [3.023e21])
│   ├─ TwapFeed::cumulativePrice(0) ... cumulativePrice(1800) ...
│   ├─ FeeSwitchToken::balanceOf(Market) [staticcall]
│   ├─ FeeSwitchToken::transferFrom(bob, Market, 3023029136650787704159 [3.023e21])
│   │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
│   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
```

`0x4e487b71`は`Panic(uint256)`のセレクタである。PanicはMarketではなくトークンの`transferFrom`の中（清算するbobのFEE残高不足）で起き、間違っていたのはハンドラーだった。清算する側が返すトークンを持っている場合だけ呼ぶように直した。

最後のバージョン（`code/market/`）の不変条件の結果（128 × 200、今回の実行の値）：

```
[PASS] invariant_I1_vaultCoversPromises   [PASS] invariant_I2_sharesAddUp
[PASS] invariant_I3_indexes               [PASS] invariant_I4_healthAfterSuccess
[PASS] invariant_I5_exitsNotBlocked       [PASS] invariant_noUnexpectedFailure
 InvariantTest invariants (runs: 128, calls: 25600, reverts: 8086)
| Handler  | openPosition  | 5066  | 3154    | 1390     |
| Handler  | borrow        | 2526  | 1308    | 830      |
| Handler  | liquidate     | 2597  | 107     | 2434     |
| Handler  | writeOff      | 2589  | 492     | 2095     |
```

成功はopenPosition 522、borrow 388、liquidate 56、writeOff 2である。同じseedでciを3回実行した不変条件の巻き戻し数は、デフォルトのバージョン8,086・8,066・8,024、debugのバージョン7,984・8,146・8,043と揺れた。

わざと間違えたバージョン（280行`mulDivDown`）で`forge test --offline --match-contract "InvariantTest|FuzzTest"`を実行すると、ファズ四つと不変条件六つがすべて通過した。全部の引き出し（withdrawAll）はアカウントの持ち分全部を引くので、変えた行を通らない。そこで分けて引き出すファズ`testFuzz_partialWithdrawNoGain`を加え、変えたバージョンではこのテスト一つが失敗する（5 passed, 1 failed）：

```
[FAIL: assertion failed: 10000000002 > 10000000000; counterexample: ... args=[1226, 5832, 2940]]
```

あふれた単位数と反例は実行ごとに違うことがある（別の実行：`10000000018 > 10000000000`、args=[12249, 6252, 8215]）。元のバージョンでは`[PASS] testFuzz_partialWithdrawNoGain (runs: 256, ...)`である。

この講義を終えたバージョンの`bash ci.sh`：

```
Ran 16 test suites: 75 tests passed, 0 failed, 0 skipped (75 total tests)
ci ok
```

### 試すときの注意

- 不変条件テストが通ったら、まず動作ごとに成功した呼び出しの数（Calls − Reverts − Discards）を見る。最初のハンドラーは清算・借金の消去の成功が0だった。
- 最初のハンドラーが失敗した理由：どのアカウント・どの金額でもよいので上限の外が多く、借金のあるアカウントに当たらずNoDebt・HasCollateralで巻き戻った。
- ハンドラーは借り入れの金額を上限の内側に絞りつつ、上限を少し超える値も残す（`InsufficientCollateral`も通るように）。選ばなかった入力は`vm.assume`で捨ててDiscardsとして数える。
- ハンドラーが選んだ範囲が、不変条件テストが見た世界である。このバージョンは価格0.2〜2.0、時間は1回に1秒〜10日、金額は残高・預けた量・借金の内側である。
- 手数料トークン（FEE）の手数料がオンになると、100を送っても99が届き、預け入れが`AmountMismatch`で巻き戻る。一覧にある失敗である。
- 不変条件が壊れたら、コードと不変条件（またはハンドラー）のどちらが間違っているかから見分ける。この講義の2回は、どちらもコードではない側だった。
- ファズ・不変条件の表の数字は、seedを固定しても実行ごとに違った。理由は確かめられなかった。通過・失敗はciのtestの段階が見て、スナップショットの段階ではファズ・不変条件を外す。
- 残高の確認を抜いたコピーは、同じ設定（128 × 200）の最初の実行では通過し、環境変数で与え直した実行三つ（64 × 100、128 × 200、256 × 200）ではすべて失敗した。
- このバージョンにはソルバーがなく、ファザーだけを使う。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると変わることがあり、ファズ・不変条件の表の数字は実行ごとに違う。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry・solc・ライブラリ | forge 1.8.3（commit cae51ad4）、solc 0.8.30、forge-std 1.17.0、OpenZeppelin Contracts 5.4.0 | 2026-10-21 |
| ファズ・不変条件の設定 | `[fuzz] runs 256 seed "0x103"`、`[invariant] runs 128 depth 200 fail_on_revert false show_metrics true` | 2026-10-21 |
| 不変条件のバージョン（第259講のバージョン） | テスト75 / 0 / 75、Market runtime 8,739 / creation 9,070、ハッシュ`47ac4829`（第258講のバージョンと同じ） | 2026-10-21 |
| 最初のハンドラーの表 | 64 × 100、borrow 694・662・0、liquidate 659・13・646、writeOff 589・589・0、repay 609・7・598（今回の実行の値） | 2026-10-21 |
| 最後のバージョンの表 | 128 × 200、openPosition 5,066・3,154・1,390、borrow 2,526・1,308・830、liquidate 2,597・107・2,434、writeOff 2,589・492・2,095（今回の実行の値） | 2026-10-21 |
| 変えたバージョン | testFuzz_partialWithdrawNoGain `10000000002 > 10000000000`（再実行した7回すべて、別の1回は`10000000018`。実行ごとに違うことがある） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ハンドラーが絞った価格範囲の外（0を含む） | [第260講](../../part20/lecture260/) |
| ソルバーによる実際の証明と反例、帰納的な不変条件 | 確かめられなかった |
| ファザーのコーパスの設定 | 扱わない |
| 同じseedで数字が揺れる理由 | 確かめられなかった |
| デプロイ後にブロックごとに不変条件を確認 | [第263講](../../part20/lecture263/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
