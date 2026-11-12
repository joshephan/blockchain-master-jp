# 第152講 ステートマシンパターン

第9部 最適化と規律・第39章 共通パターン

[← 第151講](../../part9/lecture151/) | [第9部 目次](../) | [第153講 →](../../part9/lecture153/)

## この講義の問い

段階を状態変数一つで持ち、関数ごとに確認する形で、時間で移る段階とmodifierの順番と巻き戻しは、その変数をどうずらすのか。段階の変数のほかに一緒に合っていなければならないものは何か。

## 実習資料

### 準備

公式ドキュメントCommon PatternsのState Machineの例StateMachine（ドキュメント303〜393行）を空のFoundryプロジェクト（`demo`、optimizerオフ、evm osaka）にそのまま移し、bidのmodifier 2行の順番だけを変えたバージョンと、gの本体に`return;`を1行入れたバージョンを足した。時間で変わる段階は、anvilにデプロイしたあと`cast rpc evm_increaseTime <秒>`と`cast rpc evm_mine`で時刻を進めて見る（11日は950,400秒、13日は1,123,200秒）。失敗した呼び出しは`cast run`でトレースを見る。

通しプロジェクトMarketは第151講のバージョンから始める。第152講のバージョンはコードが第151講のバージョンと同じで、状態の表をテストに移した`test/StatusTable.t.sol`を足した。テストにはforge-stdが必要である（`lib/forge-std`）。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、optimizerオフ（既定値） |
| [code/demo/src/StateMachine.sol](code/demo/src/StateMachine.sol) | ドキュメント303〜393行の例そのまま（Stages五つ、atStage、timedTransitions、transitionNext） |
| [code/demo/src/StateMachineSwapped.sol](code/demo/src/StateMachineSwapped.sol) | bidの`timedTransitions`・`atStage`の順番だけを変えたバージョン |
| [code/demo/src/StateMachineReturn.sol](code/demo/src/StateMachineReturn.sol) | gの本体に`return;`を1行入れたバージョン |
| [code/demo/test/Return152.t.sol](code/demo/test/Return152.t.sol) | 13日後にgがreturnしてもtransitionNextが実行され、stageが3になるか |
| [code/market/foundry.toml](code/market/foundry.toml) | 第151講のバージョンと同じ |
| [code/market/src/](code/market/src/) | Market第152講のバージョン（第151講のバージョンとコードは同じ、バージョン説明のコメントを1行追加） |
| [code/market/test/StatusTable.t.sol](code/market/test/StatusTable.t.sol) | 状態三つ × 関数五つの十五の欄、同じ状態に変える呼び出しのイベント、範囲外の状態の値、合計の欄とアカウントの欄の和 |
| [code/market/test/](code/market/test/) | テスト23ファイル（75個のテスト） |

### 実行結果

ドキュメントのStateMachineをデプロイして時刻を進めた結果。かっこの中は(status, gasUsed)である（`==`の見出し行は付けた説明）：

```
== ドキュメントのStateMachine、11日後
creationTime 1792445642 stage 0
now - creationTime (days) 11.0 stage 0
bid (0, 47069)
bid trace tail: Traces:
  [26005] 0x5FbDB2315678afecb367f032d93F642f64180aa3::bid()
    └─ ← [Revert] FunctionInvalidAtThisStage()


Gas used: 47069
stage after failed bid 0
reveal (1, 47083) stage 1
== ドキュメントのStateMachine、13日後
stage 0
reveal (0, 47796) stage 0
g (1, 48464) stage 3
h (1, 27409) stage 4
i (1, 23950) stage 4
== bidのmodifierの順番を変えたバージョン、11日後
stage 0
bid (1, 47036) stage 1
bid again (0, 23430) stage 1
```

11日がたっても`stage()`は0である。時間で変わる段階は、誰かがトランザクションを送らないと変わらない。bidの中でtimedTransitionsが1に移したが、atStageで巻き戻るときに移したことも一緒に消え、revealが通るときにようやく1になる。順番を変えたバージョンでは、atStageが先に過去の段階（0）を見て通したあとでtimedTransitionsが移すので、締め切りが過ぎたbidが通る。

Market第152講のバージョンの`forge test --match-contract StatusTableTest`：

```
[PASS] test_outOfRangeStatus() (gas: 29690)
[PASS] test_sameStatusEmits() (gas: 35041)
[PASS] test_statusTable() (gas: 754910)
[PASS] test_totalsMatchPositions() (gas: 376283)
Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 1.15ms (1.02ms CPU time)
```

`test_statusTable`が照合する状態の表（成功なら通過、失敗なら巻き戻しのエラー）：

| 状態 | addAsset（管理者） | deposit | withdraw | withdrawAll | setStatus（管理者） |
|---|---|---|---|---|---|
| Active（0、デプロイ直後） | 通過 | 通過 | 通過 | 通過 | 通過 |
| DepositPaused（1） | 通過 | NotActive(1) | 通過 | 通過 | 通過 |
| Frozen（2） | MarketFrozen | NotActive(2) | MarketFrozen | MarketFrozen | 通過 |

同じ状態に変える呼び出しも`StatusChanged(Active, Active)`を出力する。範囲外の値3は巻き戻しデータなしで巻き戻り、statusはそのままである。二つのアカウントが預けて引き出してwithdrawAllしたあと、totalDeposits、二つのアカウントの預け入れ額の和、Marketのトークン残高が同じである。

第152講のバージョンのサイズ（runtime / creation）はdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931、三つのプロファイルでテスト75個が通り、`.gas-snapshot`は75行、コミット前の確認は`ci ok`である。レシートのgasUsedはデプロイ760,304（第151講のバージョンは760,316）、addAsset 92,656、deposit 127,515、withdraw 57,448、setStatus 45,001 / 23,089、失敗26,264である。デプロイが12少ないのは、末尾のハッシュの中の0のバイトが一つ増えたためで、呼び出しは第151講のバージョンと同じである。

### 試すときの注意

- 段階を移すmodifierは、段階を確認するmodifierより前に書く（ドキュメント277〜282行のnote）。
- ドキュメント288〜298行のnote（transitionNextを飛ばすこと）は0.4.0より前の話である。0.8.30では、gの本体でreturnしてもtransitionNextが実行される（`Return152.t.sol`）。
- ドキュメントの例のg・hには呼び出すアカウントを確認するチェックがないので、誰でも段階を進められる。
- Marketの市場の状態は管理者のトランザクションでしか変わらず、時間では変わらない。資産は上場するだけで外す遷移がない（`delete`で消すとlistedだけがfalseになり、assets配列の欄とその資産の帳簿の欄は残る）。
- 合計の欄とアカウントの欄が合っているかは、知っているアカウントでしかテストしない。すべてのアカウントを回る確認はチェーンにない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。コンパイラとツールのバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ用プロジェクトはoptimizerオフ（Foundryの既定値）・evm osaka。Market第152講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyがデフォルトの経路 + optimizerオン、debugがデフォルトの経路でoptimizerオフ | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| 公式ドキュメントの版 | Solidity Common Patterns v0.8.36（393行）。引用236〜238、246〜258、262〜264、269〜286、288〜298、303〜393行 | 2026-10-20 |
| 0.4.0より前のmodifierの動作 | "Modifier May be Skipped. This only applies to Solidity before version 0.4.0"（ドキュメント288〜298） | 2026-10-20 |
| anvilの時刻を進める | `cast rpc evm_increaseTime <秒>`、`cast rpc evm_mine`。11日950,400秒、13日1,123,200秒 | 2026-10-20 |
| ドキュメントのStateMachineのガス（optimizerオフ） | 11日後 bid 0・47,069（トレース26,005）、reveal 1・47,083 / 13日後 reveal 0・47,796、g 1・48,464、h 1・27,409、i 1・23,950 / 順番を変えたバージョン bid 1・47,036、再びbid 0・23,430 / gの本体でreturnするバージョンのテスト56,012 | 2026-10-20 |
| StatusTableのテストのガス | test_outOfRangeStatus 29,690、test_sameStatusEmits 35,041、test_statusTable 754,910、test_totalsMatchPositions 376,283 | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第152講のバージョン：デプロイ760,304、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ（runtime / creation） | 第152講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第152講のバージョンdefault `32e6a065` | 2026-10-20 |
| 120バイトを超える行（src） | 第149講のバージョン84、第150講のバージョン85、第151講のバージョン86、第152講のバージョン87（IMarket 10、Market 67、MarketMath 6、MarketTypes 4） | 2026-10-20 |
| 行番号 | 第152講のバージョンdebug deposit 0 src/Market.sol 165:33、NotActive 80行、`contract Market` 209行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（anvilの既定のアカウント、公開されたテスト用の鍵） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ブロックの時刻を決める側と締め切りの時刻 | [第175講](../../part11/lecture175/) |
| 段階を進める関数に権限がないとき | [第176講](../../part11/lecture176/)、[第180講](../../part11/lecture180/) |
| すべてのアカウントで合計が合うかをランダムな入力でたたく（不変条件とファジング） | [第183講](../../part11/lecture183/) |
| 状態の表とコードが食い違う場所を見つける | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| 資産を外す遷移を決め直す | [第253講](../../part20/lecture253/)〜[第264講](../../part20/lecture264/)（第70〜72章）の再構築 |

出典と参考資料は[reference.md](reference.md)にまとめた。
