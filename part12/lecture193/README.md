# 第193講 提出と審査への対応

第12部 監査の実務・第51章 コンテストの実戦

[← 第192講](../../part12/lecture192/) | [第12部 目次](../) | [第194講 →](../../part13/lecture194/)

## この講義の問い

見つけた問題を、どんな文章で出すのか。同じ問題を何人もが違う書き方をすると、どうまとめられるのか。等級はどう主張し、判定に納得できなければ何を根拠に異議を出すのか。

## 実習資料

### 準備

模擬コンテストの二つの範囲をそのまま使う。講義用のエスクローEscrow51（対象）と直したバージョンのEscrowFixed51、監査対象のバージョンのMarketの写しに候補の確認テスト`Contest51.t.sol`を足したものである。どちらのプロジェクトもforge-std（1.17.0）が必要である（`lib/forge-std`）。anvilは使わない。プラットフォームのドキュメントは読むだけで、何も提出していない。

### コード

| ファイル | 内容 |
|---|---|
| [code/escrow/src/Escrow51.sol](code/escrow/src/Escrow51.sol) | 提出対象のコード。refundがconfirmedを読まない |
| [code/escrow/src/EscrowFixed51.sol](code/escrow/src/EscrowFixed51.sol) | refundに`if (confirmed) revert AlreadyConfirmed();`の一行を足した直したバージョン |
| [code/escrow/test/Escrow51.t.sol](code/escrow/test/Escrow51.t.sol) | 再現テスト（`test_refundAfterConfirm`）、締め切りのその秒のテスト、直したバージョンのテスト二つなど六つ |
| [code/escrow/foundry.toml](code/escrow/foundry.toml) | エスクローのビルド設定（via-IR、optimizerオン runs 200、evm osaka、fuzz runs 256 seed 0x2a） |
| [code/contest/test/Contest51.t.sol](code/contest/test/Contest51.t.sol) | Marketの候補の確認テスト六つ（管理者のFrozenの候補を含む） |
| [code/contest/src/](code/contest/src/) | 監査対象のバージョンのMarketのソース |
| [code/contest/test/](code/contest/test/) | Marketのテスト一式111個 |
| [code/contest/foundry.toml](code/contest/foundry.toml) | Marketのビルド設定 |

### 実行結果

直したバージョンの一行のdiff。残りの行はそのままである。

```diff
 function refund() external {
     if (msg.sender != buyer) revert NotBuyer();
     if (block.timestamp <= deadline) revert TooEarly();
+    if (confirmed) revert AlreadyConfirmed();
     if (settled) revert AlreadySettled();
     settled = true;
     token.transfer(buyer, amount);
 }
```

もとのバージョンの再現と、直したバージョンのテスト（`forge test --offline --match-test "test_refundAfterConfirm|test_fixedRefund" -vv`）：

```
[PASS] test_fixedRefundAfterConfirmReverts() (gas: 209405)
[PASS] test_fixedRefundWithoutConfirm() (gas: 157310)
[PASS] test_refundAfterConfirm() (gas: 216763)
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

- test_refundAfterConfirm（もとのバージョン）：fund 100 → confirm → 締め切り + 1秒 → refund → releaseの順で、購入者100、販売者0、releaseは`AlreadySettled`
- test_fixedRefundAfterConfirmReverts（直したバージョン）：refundは`AlreadyConfirmed`、releaseで販売者100
- test_fixedRefundWithoutConfirm（直したバージョン）：確認なしで締め切りのあとrefund、購入者100

三つの症状（「購入者が確認のあと払い戻しを受ける」「販売者のreleaseがAlreadySettled」「settledがtrueのまま残る」）は、一つの根本原因（refundがconfirmedを読まない）から出てくる。一行を直せば三つの症状が一緒に消えるので、提出する文章は一つである。

候補7の提出の文章の欄：

| 欄 | 内容 |
|---|---|
| タイトル | refundが確認の有無を見ないので、確認のあと締め切りが過ぎると、販売者の代金が購入者に戻る |
| 等級 | Medium |
| 範囲内の行 | `src/Escrow51.sol` 57〜63 refund |
| 根本原因 | refundがconfirmedを読まない |
| 影響 | 販売者の代金100の全部が購入者に行き、販売者のreleaseはAlreadySettled |
| 条件 | 購入者がconfirmしたあと、販売者が締め切り前にreleaseを呼ばない |
| 再現 | `test/Escrow51.t.sol`の`test_refundAfterConfirm`、結果は購入者100・販売者0 |
| 修正 | refundに`if (confirmed) revert AlreadyConfirmed();`、直したバージョンのテスト二つが通過 |
| Environment | solc 0.8.30、via-IRオン・optimizerオン（200）、EVM osaka、Foundry 1.8.3 |

条件を抜いたHighと、条件を書いたMedium：

| | 条件を抜いたHigh | 条件を書いたMedium |
|---|---|---|
| タイトル | 購入者が販売者のお金をいつでも持っていく | 確認のあと締め切りが過ぎると、販売者の代金が購入者に |
| 判定する人が回してみると | 販売者が先にreleaseすれば止まる | 同じテスト、同じ数字 |
| 結果 | 等級を下げる | 確認 |

縮めてみたら仕様どおりだった候補9。締め切りのその秒のrefundは、`test_refundAtDeadlineTooEarly`で`TooEarly`として止まる。コメントが「締め切りが過ぎると」で、その秒はまだ過ぎていないので出さない。

低の報告書に入れるもの：

| 候補 | 行 | 入れるか |
|---|---|---|
| 8 transferの戻り値を見ない | `src/Escrow51.sol` 53、62 | 入れる（READMEはboolを返す標準トークンだけを使う） |
| 2 管理者のFrozen | `src/Market.sol` 99 setStatus | 基準によって（中央集権の項目か無効） |
| 3 elapsedOf、4 常に0の二つ | `src/Market.sol` 213〜216、162、260 | 除く、監査報告書I-02・I-01（既知の問題） |
| 5 interestForの最大値でPanic 0x11 | `src/Market.sol` 254 | 除く、状態を変えない計算でオーバーフローチェックが止める（情報） |

候補2は`test_adminFreezeBlocksDeposit`が通る（預け入れはNotActive(2)、資産の追加はMarketFrozen、aliceの出金300）。Marketの写しの全体は、41スイート117個（基準のバージョン111 + Contest51 6）が通る。

### 試すときの注意

- 症状ごとに文章を分けない。「この行を直せば、あの症状もなくなるか」で根本原因が同じかを分ける。直す行が違えば別に出す。
- 影響の欄には、お金がどこにいくら行ったかを書く。「releaseが差し戻される」とだけ書くと、もう一度呼べばよい問題と読まれる。
- 行番号はソースで、数字はテストの出力で突き合わせてから出す。プラットフォームによっては、提出のあと直せる時間が短いか、まったくない。
- 異議を出すときは、ルール文書の文とその再現の数字を根拠に使い、判定する人に個別に連絡しない。その前に、READMEに条件を消す行があるかをまず見る。
- Marketのテストは、`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガスの記録の照合を切って回す。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。基準日に公開ドキュメントを読んだ値と、直接測った値で、プラットフォームのルールはよく変わるので、提出する前に原文を確かめ直す。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc・設定（escrow） | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka、fuzz runs 256 seed 0x2a | 2026-10-21 |
| テストのガス（escrow） | fixedRefundAfterConfirmReverts 209,405 / fixedRefundWithoutConfirm 157,310 / refundAfterConfirm 216,763 / refundAtDeadlineTooEarly 104,519 / refundWithoutConfirm 157,044 / releaseAfterConfirm 183,877 | 2026-10-21 |
| テストのガス（contest） | adminFreezeBlocksDeposit 283,572 / collateralAndBorrowsStayZero 155,520 / elapsedOfNeverDeposited 15,319 / feeTokenIsKnownIssue 722,606 / interestForOverflowPanics 9,281 / withdrawWhileDepositPaused 232,304 | 2026-10-21 |
| Code4renaの提出ルール | Solidity/EVMのHigh・Mediumは回せるコードのPoCが必要、High・Mediumは一つずつ別に、Lowは参加者ごとにQA報告書一つ、提出後2時間以内だけ修正・取り下げ可能、ライブのコードの提出は機密情報 | 2026-10-21 |
| Code4renaの判定 | 判定者が有効性・等級を決める（スポンサーの意見を参考）、根本原因が同じなら重複、最大の影響を指摘できなければ部分点・等級の引き下げ、判定後48時間のPJQA、PJQA以外での判定者への直接連絡は禁止 | 2026-10-21 |
| Code4renaの等級 | High・Medium・QA（Low、中央集権のリスクを含む）、権限の直接の誤用はQA報告書で | 2026-10-21 |
| Code4renaの報酬 | 同じ問題を見つけた人が増えるほど一人の取り分が減る計算方法、報告書に載る提出への加算、QAの取り分の上限 | 2026-10-21 |
| Sherlockの判定基準（旧コンテスト） | High・Mediumの定義、管理者関数は正しく使われるとみなす、READMEが優先、重複の要件三つのうち一つ目が根本原因、PoCなしで理解できなければ無効、High・Mediumだけを扱う | 2026-10-21 |
| Sherlockの旧コンテストの判定の段階 | リアルタイムの判定 → Lead Judgeの予備判定 → 予備結果のあと24時間の異議（Signal Score） → 最終判定 | 2026-10-21 |
| Sherlock Audit Engineへの参加 | 出した文章は取り下げも修正もできない、書き直して新たに提出（よくある形で一つの問題の系統につき5回まで、Issues Ratioに数える）、範囲・既知の問題・等級の定義をまず読む、範囲内の発見を公開バウンティ・SNS・他の業者に流さない、NDA | 2026-10-21 |
| Sherlockのドキュメントの構成 | コンテストのドキュメントがaudit-contests-deprecated-replaced-by-audit-engineのパスに移され、Audit Engine（AIの判定 + Lead Judge）のドキュメントが前にある。変わった日付・範囲は確認できていない | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 自分のプロジェクトを自分で監査し、直したバージョンを確認する | [第260講](../../part20/lecture260/) |
| デプロイされたコードのバグバウンティの報告文 | 付録 |
| プラットフォームごとの提出数の上限・正確度のスコア・報酬の計算方法の原文 | 付録（時効性のシート） |

出典と参考資料は[reference.md](reference.md)にまとめた。
