# 第183講 不変条件の設計とファジングの戦略

第11部 推奨事項：敵対的環境とバージョン履歴・第48章 検証と形式証明

[← 第182講](../../part11/lecture182/) | [第11部 目次](../) | [第184講 →](../../part11/lecture184/)

## この講義の問い

ランダムに長くたたけば、いつかは見つかるのか。何を不変条件として書くのか。不変条件のテストが通ったことは何を意味し、破れたことは何を意味するのか。同じテストを回し直せば同じ答えが出るのか。

## 実習資料

### 準備

二つのプロジェクトを使う。`p183`はバグのある例の配布Airdropと、ERC4626の金庫Vaultを置いてファズ・不変条件のテストを回すFoundryプロジェクトで、forge-stdとOpenZeppelin Contracts 5.4.0が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。`market`は通しプロジェクトMarketの第46章の終わりのバージョン（src・foundry.tomlはそのまま）に、テストファイル三つ（`Invariant48.t.sol`、`Fuzz48.t.sol`、`Midway48.t.sol`）だけを足した写しである。この三つは通しプロジェクトの基準のバージョンには足さない。anvilは使わない。

同じ結果を見直すには、スイートを一つずつ回し、回す前に毎回`cache/fuzz`・`cache/invariant`を消し、不変条件のテストは`FOUNDRY_INVARIANT_WORKERS=1`、seedは`--fuzz-seed 0x2a`（p183はfoundry.tomlのseed）にそろえる。Marketのテストには`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`をつける。

Airdropは、同じ番号を一つの配列に何度も書くと取り分を多く受け取れるバグのある例のコードである。テストは、そのバグをルール違反として見つけ出す側である。

### コード

| ファイル | 内容 |
|---|---|
| [code/p183/foundry.toml](code/p183/foundry.toml) | solc 0.8.30、evm osaka、fuzz runs 256・seed 0x2a |
| [code/p183/src/Airdrop.sol](code/p183/src/Airdrop.sol) | 番号四つ（0・1がalice、2・3がbob）、一つ100ずつ、全体400。同じ番号の重複のバグがある例 |
| [code/p183/src/Vault.sol](code/p183/src/Vault.sol) | テスト用のトークンAssetと、OpenZeppelinのERC4626の金庫Vault |
| [code/p183/test/Probe167.t.sol](code/p183/test/Probe167.t.sol) | RandomProbeTest：番号をuint256のまま入れるファズテスト |
| [code/p183/test/Strategy183.t.sol](code/p183/test/Strategy183.t.sol) | 入力を絞った二つのバージョン（ValueBoundProbeTest、ShapeBoundProbeTest）、AirdropHandlerと不変条件二つ（AirdropInvariantTest） |
| [code/p183/test/Round183.t.sol](code/p183/test/Round183.t.sol) | RoundTripFuzzTest：金庫に入れてすぐ出すと、入れたより多くは受け取らない |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（既定、debug、legacyプロファイル） |
| [code/market/src/](code/market/src/) | Marketの本体（第46章の終わりのバージョンのまま） |
| [code/market/test/Invariant48.t.sol](code/market/test/Invariant48.t.sol) | MarketHandler、Marketの不変条件五つ（MarketInvariantTest、MarketInvariantTunedTest）、わざと間違えて書いた不変条件（WrongInvariantTest）、ハンドラのないバージョン（NoHandlerInvariantTest）、同じ呼び出し2,000回の比較（HandlerYieldTest） |
| [code/market/test/Fuzz48.t.sol](code/market/test/Fuzz48.t.sol) | InterestFuzzTest：利息計算の最初のバージョンと直したバージョン、アセンブリ版との比較、倍率・pureの確認 |
| [code/market/test/Midway48.t.sol](code/market/test/Midway48.t.sol) | 出金の途中で帳簿と残高を読むだけのCheckToken、MidwayInvariantTest |
| [code/market/test/](code/market/test/) | 第46章の終わりのバージョンまでに積み重なった残りのテスト |

### 実行結果

Airdropのルール「aliceは何を入れても200を超えて受け取れない」を、入力の形だけを変えた三つのバージョンで回した結果。失敗メッセージは`assertion failed: 300 > 200`である。

| バージョン | 256回 | 10,000回 |
|---|---|---|
| uint256の配列のまま | PASS | PASS |
| 番号だけ0〜3 | PASS | FAIL `[33, 109, 200]` |
| 番号0〜3、長さ0〜4 | FAIL `[33, 56, 45, 233, 45, 7, 1, 5]` | FAIL |

`[33, 109, 200]`は4で割った余りが番号1、1、0なので、aliceが300を受け取る。`[33, 56, 45, 233, 45, 7, 1, 5]`は長さ8を5で割った余りが3なので、先頭の三つ（番号1、0、1）だけを使う。

`FOUNDRY_INVARIANT_WORKERS=1 forge test --offline --match-contract AirdropInvariantTest`。呼び出し二つで見つけた順番を、縮小（shrink）で一つにした。5297 % 2 = 1なのでbob、配列の長さ189 % 5 = 4なので番号3、3、3、2を受け取り、bobが400である。合計400の不変条件は通る。

```
[FAIL: assertion failed: 400 > 200] invariant_nobodyOverpaid
	[Sequence] (original: 2, shrunk: 1)
		... calldata=claim(uint256,uint8[]) args=[5297, [127, 159, 219, 34, 206, …]]
AirdropInvariantTest invariants: 1/2 invariants broken
[FAIL: assertion failed: 400 > 200] invariant_nobodyOverpaid
[PASS] invariant_paidPlusRemainingIs400
 AirdropInvariantTest invariants (runs: 256, calls: 128000, reverts: 0)
```

`market`で`forge test --offline --fuzz-seed 0x2a --match-contract "^MarketInvariantTest$" -vv`。ハンドラが失敗を飲み込んで分類するので、revertsが0である。

```
MarketInvariantTest invariants:
[PASS] invariant_failuresAreListed
[PASS] invariant_statusRules
[PASS] invariant_tokenCoversLedger
[PASS] invariant_totalsMatchGhost
[PASS] invariant_totalsMatchPositions
 MarketInvariantTest invariants (runs: 256, calls: 128000, reverts: 0)
```

| 関数 | Calls |
|---|---|
| deposit | 21,393 |
| donate | 21,081 |
| setBroken | 21,348 |
| setStatus | 21,360 |
| withdraw | 21,319 |
| withdrawAll | 21,499 |

ハンドラなしでMarketを直接たたいたバージョン（`^NoHandlerInvariantTest$`、Discardsの欄は省略）。128,000回のうち127,984回が差し戻され、帳簿が一度も変わらないまま通った。

```
[PASS] invariant_tokenCoversLedger() (runs: 256, calls: 128000, reverts: 127984)

| Contract | Selector    | Calls | Reverts |
| Market   | addAsset    | 25874 | 25866   |
| Market   | deposit     | 25728 | 25728   |
| Market   | setStatus   | 25479 | 25471   |
| Market   | withdraw    | 25483 | 25483   |
| Market   | withdrawAll | 25436 | 25436   |
```

同じ呼び出し2,000回を二つのハンドラで回した比較（`forge test --offline --match-test test_yield -vv`）：

| | 既定のハンドラ | 調整したハンドラ |
|---|---|---|
| 成功した預け入れ / 出金 | 26 / 22 | 48 / 46 |
| NotActiveの失敗 | 184 | 84 |
| 故障トークンの失敗（token paused） | 46 | 3 |
| Frozenで成功した出金 | 8 | 2 |
| 不変条件五つ | PASS | PASS |

わざと間違えて書いた不変条件「トークンの残高 == 帳簿」（`^WrongInvariantTest$`）。Marketに直接送ったトークン226が帳簿に入らないので破れる。間違っているのは不変条件の側で、正しい文は「トークンの残高 ≥ 帳簿」である。

```
[FAIL: assertion failed: 226 != 0]
	[Sequence] (original: 5, shrunk: 1)
		... calldata=donate(uint256,uint256,uint256) args=[8, 1564, 4741]
 invariant_tokenEqualsLedger() (runs: 1, calls: 5, reverts: 0)
```

保存された失敗をdebugプロファイルで回し直した`FOUNDRY_PROFILE=debug forge test --offline --fuzz-seed 0x2a --match-contract "^WrongInvariantTest$" -vvvv`（cacheを消さずにそのまま）：

```
Warning: Replayed invariant failure from persisted file.
[FAIL: assertion failed: 226 != 0]
	[Sequence] (original: 1, shrunk: 1)
  [79504] MarketHandler::donate(8, 1564, 4741)
    ├─ [52305] MockToken::transfer(Market: [0x2a07706473244BC757E10F2a9E86fB532828afe3], 226)
```

利息のテストの最初のバージョン（`^InterestFuzzTest$`）。三つのうち一つでも0ならあふれないとみなした判定が間違っていた。Marketの式は((a × r) × e)の順なので、e = 0でもa × rであふれる。a × rで先に確かめるように直した`testFuzz_interestRevertsOrExact`は、256回・10,000回ともにPASSである。

```
[FAIL: assertion failed; counterexample: args=[44078286890143784772715589096311926088228387198488387716567755302837893358961 [4.407e76], 1663, 0]] testFuzz_interestDraft(uint256,uint256,uint256) (runs: 15, μ: 8107, ~: 6655)
```

オーバーフローチェックのないアセンブリ版に同じルールをかけた結果：

```
[FAIL: asm returned a value for an overflowing input: 1481498537677031945943365002378857528055296141029496 != 1157…9935; counterexample: args=[28266846444697138956729000649739972476999065 [2.826e43], 11037555857784102630094783971031053093101996443821052462 [1.103e55], 8206726016050 [8.206e12]]] 
```

金庫の丸め（`RoundTripFuzzTest`）と出金の途中の読み取り（`^MidwayInvariantTest$`）：

```
[PASS] testFuzz_roundTripNeverGains(uint256,uint256,uint256) (runs: 256, μ: 569251, ~: 575397)
[PASS] invariant_midwayLedgerCovered() (runs: 256, calls: 128000, reverts: 0)
```

三つのビルドに同じseedで`MarketInvariantTunedTest`を回すと、不変条件五つがすべてPASSで、関数ごとのCallsが同じである（deposit 21,393、withdraw 21,319、withdrawAll 21,499）。不変条件のテストのあと`forge coverage --offline --fuzz-seed 0x2a --match-contract MarketInvariantTunedTest --report summary`：

| ファイル | 行 | 分岐 | 関数 |
|---|---|---|---|
| Market.sol | 84.29% (59/70) | 30.77% (4/13) | 82.61% (19/23) |
| MarketMath.sol | 80.00% (8/10) | 100.00% (1/1) | 66.67% (2/3) |

### 試すときの注意

- たくさん回しても見つからない。ランダムなuint256は0〜3にほとんど落ちない。runsはそのままにして、入力の形を絞る側が反例を見つける。
- ハンドラなしでたたいた不変条件の通過は、何の意味もないことがある。forgeの既定値`fail_on_revert = false`なので、差し戻しは失敗と数えない。成功した呼び出しの数を一緒に見る。
- runs・depthを増やすと呼び出しの数だけが増え、差し戻しの比率はそのままである。比率を変えるのは、ハンドラが入力を選ぶ方式である。
- 不変条件が破れたら、コードより先に不変条件の文を疑う。残高 == 帳簿は、depositを通らないトークンのせいで破れる間違った文である。
- 破れた順番は`cache/invariant/failures`に保存され、次の実行は保存された順番から回り直す。新しく探すには消す。
- 同じseed・ワーカー一つ・保存された失敗の消去をそろえても、ビルドし直したあとに反例の値が変わることがある。破れるという結果は毎回同じである（下の時効性の表）。
- カバレッジで0回しか届かなかった行は、使わないコードの候補か、ハンドラが行けなかった道の候補である。172・188行のTransferFromFailed・TransferFailedの分岐は、MockTokenがfalseの代わりに差し戻すので届かなかった。
- 出金の途中で読んでも帳簿 ≤ トークンが守られ（128,000回で違反0）、Marketにロック（ReentrancyGuard）は足さなかった。帳簿を先に減らしてトークンを後で送り、委任呼び出しがない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンと実行環境によって値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| solc | 0.8.30+commit.73712a01.Windows.msvc | 2026-10-21 |
| forgeのファズの既定値 | fuzz runs 256 | 2026-10-21 |
| forgeの不変条件の既定値 | runs 256、depth 500、workers auto、fail_on_revert false、shrink_run_limit 5000 | 2026-10-21 |
| 再現の設定 | `--fuzz-seed 0x2a`（p183はfoundry.tomlのseed）、`FOUNDRY_INVARIANT_WORKERS=1`、実行前に`cache/fuzz`・`cache/invariant`を消す | 2026-10-21 |
| 実行時間 | Airdropの不変条件8.77秒、Marketの不変条件18.16秒（既定）・30.20秒（debug）・20.07秒（legacy）、Midway 5.19秒、ハンドラのないバージョン0.99秒 | 2026-10-21 |
| OpenZeppelin | 5.4.0（ERC4626の金庫） | 2026-10-21 |
| SMTソルバー | z3・cvc5・Eldaricaはインストールされていない | 2026-10-21 |
| 状態のないファズの反例 | 同じコマンドでも実行ごとに違う（利息の最初のバージョン`[4.407e76, 1663, 0]` / `[17, 8.195e76, 0]`） | 2026-10-21 |
| 不変条件の反例 | seed・ワーカー一つ・保存された失敗の消去をそろえても、ビルドし直したあとは違う（Airdrop original 2 → shrunk 1でbob / original 17 → shrunk 2でalice、残高 == 帳簿は`226 != 0` original 5 / `123 != 0` original 53）。間違った不変条件は`forge build --force`のあと123、debugプロファイルをビルドしてから既定のプロファイルで回すと226 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 不変条件のテストを通しプロジェクトの基準のバージョンに入れてCIで回す | [第258講](../../part20/lecture258/)、[第259講](../../part20/lecture259/) |
| オラクル・清算がついた複数コントラクトの不変条件 | [第259講](../../part20/lecture259/) |
| ファザーのコーパス・カバレッジ誘導の設定 | [第259講](../../part20/lecture259/) |
| 監査で不変条件の一覧を範囲の見積もりとチェックリストに使う | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/) |
| 長さが伸びるリストとまとめる長さ | [第229講](../../part17/lecture229/)〜[第234講](../../part17/lecture234/) |
| 借り入れ・担保の欄ができたら、その欄の不変条件 | [第197講](../../part13/lecture197/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
