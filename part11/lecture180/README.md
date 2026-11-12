# 第180講 経済的攻撃とガバナンスの乗っ取り

第11部 推奨事項：敵対的環境とバージョン履歴・第47章 コードの外からの攻撃

[← 第179講](../../part11/lecture179/) | [第11部 目次](../) | [第181講 →](../../part11/lecture181/)

## この講義の問い

コードにバグが一つもないのに、お金が出ていくことはありうるのか。投票でコードを変えるプロトコルで、票とは何か。票を一つのトランザクションのあいだだけ借りられるなら、何が壊れ、何で防ぐのか。Marketにはこういう道があるのか。

## 実習資料

### 準備

二つのプロジェクトを使う。`gov`はOpenZeppelinのガバナンスモジュールをつなぎ合わせた講義用の最小のガバナンスを入れたFoundryプロジェクトで、forge-stdとOpenZeppelin Contracts 5.4.0が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。値はすべてトイの値である。`market`は通しプロジェクトMarketの前のバージョン（第46章の終わりのバージョン）で、この講義ではコードとテストを直さず、srcをgrepで読むだけである。anvilと外部への接続なしに、forgeの中だけで動く。

借りた票で提案を通す流れは、図と説明だけで扱う。`test_votesCountedAtSnapshot`は、テストの中の普通のtransferで票を受け取ってから返し、そうして受け取った票が重み0で数えられるかを確かめる守る側のテストである。

### コード

| ファイル | 内容 |
|---|---|
| [code/gov/foundry.toml](code/gov/foundry.toml) | solc 0.8.30、optimizer・via-IRオン、OpenZeppelinのremapping |
| [code/gov/src/GovToken.sol](code/gov/src/GovToken.sol) | 投票トークン（ERC20・ERC20Permit・ERC20Votes）、1000個を発行 |
| [code/gov/src/Gov.sol](code/gov/src/Gov.sol) | Gov（投票の遅延1ブロック、投票期間50ブロック、提案のしきい値0、定足数4%、タイムロック）、タイムロックだけが変えられるBox |
| [code/gov/test/Gov180.t.sol](code/gov/test/Gov180.t.sol) | Gov180Testの六つ：残高と票、票を数えるブロック、開く前の投票、定足数、タイムロックの待機、Boxの直接呼び出し |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/) | Marketの本体（前のバージョンのまま）。immutableの三つは`Market.sol` 68・122・228行 |
| [code/market/test/](code/market/test/) | 前のバージョンまでに積み重なったテスト（そのまま） |

### 実行結果

`gov`で`forge test --offline --match-contract Gov180Test -vvv`：

```
Ran 6 tests for test/Gov180.t.sol:Gov180Test
[PASS] test_balanceIsNotVotes() (gas: 127474)
[PASS] test_boxOnlyTimelock() (gas: 29843)
[PASS] test_quorumNotMet() (gas: 382985)
[PASS] test_timelockWaitsBeforeExecute() (gas: 772406)
[PASS] test_voteBeforeStartReverts() (gas: 245697)
[PASS] test_votesCountedAtSnapshot() (gas: 603831)
Suite result: ok. 6 passed; 0 failed; 0 skipped; finished in 1.72ms (3.30ms CPU time)
```

テストの出発の状態：GovToken 1000個のうちalice 100、lender 900。タイムロックは最小の待機2日で、提案はGovだけが上げ、実行は誰でも送れる。テストは10番ブロックから始まる（10番でaliceが委任、11番で提案、12番が票を数えるブロック、13番で投票）。

`forge test --offline --match-test test_votesCountedAtSnapshot -vvvv`からGov側の呼び出しだけを抜き出したもの（0x…0B0b = bob、0x…A11cE = alice、提案番号は…に縮めた）。bobは13番ブロックで900を受け取って今の票は900だが、12番ブロックの票が0なので投票の重みは0である。

```
    ├─ [2513] Gov::proposalSnapshot(…) [staticcall]
    │   └─ ← [Return] 12
    ├─ [5048] GovToken::getVotes(0x…0B0b) [staticcall]
    │   └─ ← [Return] 900
    ├─ [62901] Gov::castVote(…, 1)
    │   ├─ [550] GovToken::clock() [staticcall]
    │   │   └─ ← [Return] 13
    │   ├─ [5186] GovToken::getPastVotes(0x…0B0b, 12) [staticcall]
    │   │   └─ ← [Return] 0
    │   ├─ emit VoteCast(voter: 0x…0B0b, …, support: 1, weight: 0, reason: "")
    │   └─ ← [Return] 0
    ├─ [83107] Gov::castVote(…, 1)
    │   ├─ [5492] GovToken::getPastVotes(0x…A11cE, 12) [staticcall]
    │   │   └─ ← [Return] 100
    ├─ [6912] Gov::proposalVotes(…) [staticcall]
    │   └─ ← [Return] 0, 100, 0
```

`test_voteBeforeStartReverts`：11番ブロックで提案し、同じブロックで投票すると差し戻される。二つ目の値0は今の状態Pending、三つ目の値0x…02は期待した状態Activeをビットで表したものである。

```
[PASS] test_voteBeforeStartReverts() (gas: 245697)
    ├─ [29009] Gov::castVote(…, 1)
    │   └─ ← [Revert] GovernorUnexpectedProposalState(…, 0, 0x0000…0002)
```

`test_quorumNotMet`：aliceが90をbobに渡し、残りの10だけを委任してから一人で賛成すると、定足数quorum(12) = 40に届かず、投票期間のあとの状態はDefeatedである。

`test_timelockWaitsBeforeExecute`（行の一部を抜き出し）：通った提案をqueueしてすぐexecuteすると差し戻され、Boxの値は0で、2日（172800秒）後にexecuteするとBoxの値が42になる。

```
[PASS] test_timelockWaitsBeforeExecute() (gas: 772406)
    ├─ [143992] Gov::queue(…)
    │   ├─ [2838] TimelockController::getMinDelay() [staticcall]
    │   │   └─ ← [Return] 172800 [1.728e5]
    ├─ [73902] Gov::execute(…)
    │   ├─ [5290] TimelockController::executeBatch(…)
    │   │   └─ ← [Revert] TimelockUnexpectedOperationState(0x2670…0990, 0x0000…0004)
    ├─ [2247] Box::value() [staticcall]
    ├─ [112750] Gov::execute(…)
    │   ├─ [37525] TimelockController::executeBatch(…)
    │   │   ├─ [22299] Box::setValue(42)
```

`test_boxOnlyTimelock`：テストコントラクトがBoxに直接setValue(7)を呼ぶとNotOwnerである。

`market`でsrcを読んだgrep三行：

```
$ grep -rniE "vote|govern|delegate|proposal|timelock" src/
src/MarketMath.sol:10:// publicに変えるとライブラリを別にデプロイしてリンクし、呼ぶたびにdelegatecall(第117講のpublic変形版で確認)
$ grep -rniE "price|oracle" src/
$ grep -n "public immutable" src/Market.sol
68:    address public immutable admin;
122:    Ratio public immutable collateralRatio;
228:    Rate public immutable interestRate;
```

引っかかった行はコメントのdelegatecallという単語一つだけで、投票でコードや設定を変えるコードの行は0か所である。admin・collateralRatio・interestRateはコンストラクタで一度決め、変える関数がない。

### 試すときの注意

- ERC20Votesでは、トークンの残高がそのまま票ではない。委任（delegate）してはじめてチェックポイントができて票が数えられる（委任前のaliceは残高100、票0）。
- `getPastVotes`は過去の時点だけを読む。今や未来の時点を入れると`ERC5805FutureLookup`で差し戻す。ブロック番号の時計では、そのブロックの終わりの記録を返すので、13番ブロックのどのトランザクションも12番ブロックの記録を変えられない。
- 定足数は、関心の薄い日に少ない票で一人で通すことを防ぐ。定足数を超える大きな票は、票を数えるブロックが防ぐ。
- タイムロックが過ぎても、誰かがexecuteを送らないと実行されない。実行の役割をaddress(0)に与えると、誰でも送れる（TimelockControllerの原文 "Granting a role to `address(0)` is equivalent to enabling this role for everyone."）。
- 投票のときに読んだ対象アドレスのコードと実行のときのコードが違えば、票は別のコードを承認したことになる。提案のときに対象アドレスのcodehashを書き留めておき、実行の直前に読み直して比べる確認を置ける。対象がプロキシなら、アップグレードの鍵一つで実装が変わる。
- 投票で変えるコントラクトに尋ねること：票をどのブロックの記録で数えるか、定足数、実行まで待つ時間、実行の行が呼べる呼び出し。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | 2026-10-21 |
| Govの設定（トイの値） | 投票の遅延1ブロック、投票期間50ブロック、提案のしきい値0、定足数4%、タイムロックの最小の待機2日（172800秒） | 2026-10-21 |
| テストのガス（gov） | balanceIsNotVotes 127,474 / boxOnlyTimelock 29,843 / quorumNotMet 382,985 / timelockWaitsBeforeExecute 772,406 / voteBeforeStartReverts 245,697 / votesCountedAtSnapshot 603,831 | 2026-10-21 |
| Marketのバージョン | 第46章の終わりのバージョン（テスト111個、ランタイム2,990バイト）、immutableの行68・122・228、管理者の席三つのうち二つがマルチシグ（デプロイの決定） | 2026-10-21 |
| 事件の年 | Beanstalk 2022 | 2026-10-21 |
| selfdestructの動作の変更 | EIP-6780、Cancunハードフォーク | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ガバナンスの設計全般（委任、投票方式、定足数の選び方） | [第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/)、[第215講](../../part14/lecture215/)、[第216講](../../part14/lecture216/) |
| アルゴリズム型ステーブルコインと経済設計の崩壊 | [第201講](../../part13/lecture201/) |
| 貸し出しの担保比率と清算の経済 | [第197講](../../part13/lecture197/)、[第198講](../../part13/lecture198/)、[第199講](../../part13/lecture199/) |
| 収益の出どころと持続可能性 | [第202講](../../part13/lecture202/)、[第203講](../../part13/lecture203/) |
| 同じアドレスに別のコードを載せ直す手口 | 扱わない |
| 事件を軸で分け直す | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| 7つの層の分析のガバナンス層 | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
