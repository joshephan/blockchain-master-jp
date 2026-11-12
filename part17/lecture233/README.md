# 第233講 シーケンサーと脱出の保証

第17部 スケーラビリティ・第63章 ロールアップとZK

[← 第232講](../../part17/lecture232/) | [第17部 目次](../) | [第234講 →](../../part17/lecture234/)

## この講義の問い

L2で自分の取引の順番は誰が決め、いつ決まるのか。順番を決める側が自分の取引を外したり止めたりしたら、何が自分を守るのか。運営者が消えた日に自分のお金を引き出すには、何がなければならないのか。

## 実習資料

### 準備

プロジェクトを二つ使う。

- `rollup`：第232講と同じ講義用のプロジェクトで、L1の記録箱`Inbox233`（シーケンサーのバッチと強制的な取り込みの待ち列）と脱出の道`Exit233`を使う。どちらもアカウント四つの講義用のL2 `ToyL2`（第232講と同じファイル）を呼ぶ。依存関係はforge-std 1.17.0である。テストはforgeの中で動き、同じ流れをanvil（`--hardfork osaka`）にデプロイしてcastでもう一度実行した。anvilではシーケンサーがアカウント3番、aliceがアカウント4番である。
- `market`：通しプロジェクトMarketの第199講のバージョン（第53章の最終バージョン）そのままである。コードは変えず、テスト三つと`cast calldata`だけを実行した。依存関係はforge-stdである。

アカウントはすべてanvilのデフォルトのテスト用アカウントで、外部のチェーンには接続しない。

### コード

| ファイル | 内容 |
|---|---|
| [code/rollup/foundry.toml](code/rollup/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシード固定 |
| [code/rollup/src/ToyL2.sol](code/rollup/src/ToyL2.sol) | 講義用のL2ライブラリ（取引10バイト、バッチの実行、ステートルート、残高の証明） |
| [code/rollup/src/Inbox233.sol](code/rollup/src/Inbox233.sol) | 講義用のL1の記録箱：シーケンサーだけが呼ぶ`appendBatch(batch, take)`、L1に直接入れる`enqueue`、待ち時間（講義用に1日）が過ぎると誰でも呼べる`forceInclude`（NothingDue） |
| [code/rollup/src/Exit233.sol](code/rollup/src/Exit233.sol) | 講義用の脱出の道：運営者が7日間ルートを上げないと凍結し（`frozen`）、そこから欄ごとに1回、最後のルートの下の残高を証明して引き出す`escape`（NotFrozen、AlreadyExited、BadProof、PayFailed）、凍結後の`update`はIsFrozen |
| [code/rollup/test/Inbox233.t.sol](code/rollup/test/Inbox233.t.sol) | Inbox233Testの7個：シーケンサーが決める順番、順番が結果を決める、シーケンサーだけがバッチを上げる、待ち列の飛ばし、1日後の強制的な取り込み、待ち列が先 |
| [code/rollup/test/Exit233.t.sol](code/rollup/test/Exit233.t.sol) | Exit233Testの8個と、イーサを受け取らない空のコントラクト`NoReceive233` |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/) | Market本体（第199講のバージョンそのまま） |
| [code/market/test/](code/market/test/) | このバージョンまでに積み上がったテスト（`Keys.t.sol`の`test_lostKeyFrozenStillWithdraws`、`Borrow.t.sol`の`test_liquidityLimit`・`test_withdrawKeepsDebtCovered`を含む） |

### 実行結果

`rollup`で`forge test --offline --match-contract "Inbox233Test|Exit233Test" -vv`：

```
Ran 7 tests for test/Inbox233.t.sol:Inbox233Test
[PASS] test_forceIncludeAfterDelay() (gas: 276669)
[PASS] test_onlySequencerAppends() (gas: 34517)
[PASS] test_orderDecidesWhichPasses() (gas: 110527)
[PASS] test_sequencerCanSkipQueue() (gas: 290624)
[PASS] test_sequencerOrders() (gas: 107639)
[PASS] test_sequencerTakesQueueFirst() (gas: 270112)
[PASS] test_strangerCannotEnqueue() (gas: 41277)
Suite result: ok. 7 passed; 0 failed; 0 skipped

Ran 8 tests for test/Exit233.t.sol:Exit233Test
[PASS] test_anyoneCanSendForOwner() (gas: 112198)
[PASS] test_escapeAfterFreeze() (gas: 104961)
Logs:
  escape gas 71590

[PASS] test_escapeOnce() (gas: 135916)
[PASS] test_noEscapeWhileLive() (gas: 46469)
[PASS] test_noUpdateAfterFreeze() (gas: 35419)
[PASS] test_oneRejecterDoesNotBlockOthers() (gas: 369681)
[PASS] test_operatorUpdateDelaysFreeze() (gas: 55210)
[PASS] test_wrongAmountRejected() (gas: 49091)
Suite result: ok. 8 passed; 0 failed; 0 skipped
```

| テスト | 順番 | 結果 |
|---|---|---|
| test_sequencerOrders | alice → bob 30 | alice 70、bob 80 |
| test_orderDecidesWhichPasses | alice → carol 80、alice → bob 80（alice 100） | carol 80、bob 50（後ろの取引は効果なし） |
| test_onlySequencerAppends | aliceがappendBatch | NotSequencer(alice) |
| test_sequencerCanSkipQueue | シーケンサーが12時間のあいだにバッチ二つをtake 0で | carol 0、待機 1 |
| test_forceIncludeAfterDelay | 1日 − 1秒でforceInclude、1日でbobが呼ぶ | NothingDue(1,000,000 + 86,400)、1個を移す、alice 50・carol 50、待機 0 |
| test_sequencerTakesQueueFirst | take 1：待ち列のalice → carol 50、シーケンサーのバッチのalice → bob 80 | carol 50、bob 50（残りの50では送れない） |

anvilにInbox233をデプロイ（653,103ガス）し、待ち列を飛ばしたバッチと強制的な取り込み：

```
enqueue(2, 50)        alice（アカウント4番）、L1に直接  → gasUsed 100,306
appendBatch(バッチ, 0)  シーケンサー（アカウント3番）、take 0  → gasUsed 73,409
waitingCount() → 1    entryCount() → 1
forceInclude()   すぐに       → execution reverted: NothingDue(1792613705)
evm_increaseTime 86400
forceInclude()   アカウント5番   → gasUsed 80,819
waitingCount() → 0    entryCount() → 2
entry(1) → 0x00020000000000000032   （送る欄0、受け取る欄2、金額0x32 = 50）
```

アカウント6番がappendBatchを呼ぶと、`NotSequencer(0x976E…0aa9)`でリバートする。`NothingDue`・`NotFrozen`の時刻はanvilを立ち上げた時刻によるので、実行するたびに違う。

Exit233（デプロイ503,876ガス、金庫200イーサ、最後のルートの下の残高はalice 70、bob 60、carol 20、dave 50イーサ）：

```
escape(0, 70 ether, 証明)  凍結前   → NotFrozen(1793218507)
evm_increaseTime 604800   frozen() → true
escape(0, 70 ether, 証明)  alice     → gasUsed 61,111  （alice +69.99999035897366 ether）
escape(0, …) もう一度                → AlreadyExited(0)
escape(1, 100 ether, 証明)          → BadProof
escape(1, 60 ether, 証明)  bob       → gasUsed 61,138
update(ルート)  運営者                → IsFrozen
金庫 → 70 ether
```

| テスト | 結果 |
|---|---|
| test_anyoneCanSendForOwner | carolがbobの欄で呼んでも、60イーサはbobに |
| test_operatorUpdateDelaysFreeze | 6日目にupdateすると、最初から7日が過ぎても凍結しない |
| test_oneRejecterDoesNotBlockOthers | dave（イーサを受け取らない空のコントラクト）はPayFailed(dave)、exited(3)はfalse、50イーサが残る。alice・bob・carolは成功して150イーサが出ていく |

`market`で、Marketのユーザーが出ていく取引：

```
$ cast calldata "withdraw(address,uint256)" 0x5FbDB2315678afecb367f032d93F642f64180aa3 30
0xf3fef3a3
  0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3
  000000000000000000000000000000000000000000000000000000000000001e
  → 68バイト（セレクター4 + 引数二つ64）
```

最初の引数は資産のアドレス（MockToken 0x5FbD…0aa3）、二つ目は金額30である。`forge test --offline --match-test "test_lostKeyFrozenStillWithdraws|test_liquidityLimit|test_withdrawKeepsDebtCovered" -vv`（ガススナップショットの確認を切って）：

```
[PASS] test_lostKeyFrozenStillWithdraws() (gas: 453775)
[PASS] test_liquidityLimit() (gas: 512402)
[PASS] test_withdrawKeepsDebtCovered() (gas: 798594)
```

管理者の鍵を失って凍結した市場でも、withdraw 50は成功する。凍結とは関係なく止まる引き出しは二つである。金庫に残ったトークンより多く引き出すと`InsufficientLiquidity(300e6, 400e6)`（貸し出された分は引き出せない）、担保に使っている資産を引き出したあとに借金が上限を超えると`InsufficientCollateral(675e18, 700e18)`である。

### 試すときの注意

- シーケンサーのレシートはシーケンサーの約束である。その順番は、バッチがL1に上がって（`appendBatch`）初めて決まる。
- 強制的な取り込みは順番を守る。取引が成功するかどうかは、その取引が呼ぶコード（ここではMarket）が決める。
- `Exit233`は、ルートを受け取る側の検証（異議申し立てや証明の確認）を省いたおもちゃである。講義用の期間は、強制的な取り込みが1日、凍結が7日である。
- escapeの証明（自分の欄の隣のリーフと隣のブランチ）を作るには、最後のルートのときのL2の状態がなければならない。その状態は、それまでのバッチのデータを最初から再実行して初めて得られる。テストの`ToyL2.proofOf`は、残高四つを全部知っている側が作る。
- 脱出が欄ごとに別々なので、イーサを受け取らない持ち主が一人いても、その分だけが残り、残りは出ていく。
- アップグレードの鍵一つですぐに変わるロールアップのコントラクトなら、強制的な取り込みも脱出の道も、その鍵の前ではないのと同じである。アップグレードの予告と適用のあいだの脱出の窓が、強制的な取り込みの待ち時間より長くなければ出ていけない（例：待ち時間7日、適用まで3日なら出ていけない）。文書より、L1にデプロイされたコントラクトのコードが優先である。

## 時効性のあるデータ

基準日時点の値。実装の名前は名前だけを書いた。実装ごとの数値（待ち時間、期限、段階）は各実装の公開文書で確かめる必要がある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30 | 2026-10-21 |
| 大きなL2のシーケンサーの運営方式 | たいてい一か所が受け持つ | 2026-10-21 |
| やり直せる入金の名前（例） | Arbitrum retryable ticket | 2026-10-21 |
| 脱出の道の名前（例） | StarkEx escape hatch、zkSync priority queue | 2026-10-21 |
| L2の段階の分類の公開サイト | L2BEAT Stages | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 複数のシーケンサーが交代で受け持ったり、L1のブロックを作る側が順番を決めたりする設計 | 付録 |
| L2の順番から生まれるMEV | 保留（第61章） |
| やり直せる入金の実装ごとの名前と期限 | 時効性のあるデータ（名前のみ） |
| 脱出に使うデータを自分で受け取っておくノード | [第235講](../../part18/lecture235/)、[第238講](../../part18/lecture238/) |
| 自分のL2のシーケンサー・脱出・鍵を信頼の前提に書く | [第237講](../../part18/lecture237/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
