# 第192講 実際のコードベースの分析実習

第12部 監査の実務・第51章 コンテストの実戦

[← 第191講](../../part12/lecture191/) | [第12部 目次](../) | [第193講 →](../../part12/lecture193/)

## この講義の問い

初めて受け取ったコードベースを、どこから読むのか。候補はどうやって見つけ、見つけたもののうち何を出すのか。テストをすべて通ったMarketと小さなエスクローから、実際に何が出てくるのか。

## 実習資料

### 準備

模擬コンテストの範囲は二つある。監査対象のバージョンのMarketのリポジトリの写し（ソースはそのまま、候補の確認テスト`Contest51.t.sol`だけを足した）と、講義用のエスクローEscrow51である。どちらのプロジェクトもforge-std（1.17.0）が必要である（`lib/forge-std`）。デプロイの値の確認は、ローカルのanvil一つで、anvilの既定のテスト用アカウント0番だけで行う。

### コード

| ファイル | 内容 |
|---|---|
| [code/contest/foundry.toml](code/contest/foundry.toml) | Marketのビルド設定 |
| [code/contest/src/](code/contest/src/) | 範囲内のMarketの四つのファイルと範囲外のMockToken |
| [code/contest/test/Contest51.t.sol](code/contest/test/Contest51.t.sol) | Marketの候補六つを確かめるテストと、テスト用の手数料トークンFeeToken51 |
| [code/contest/test/](code/contest/test/) | 受け取ったテスト一式111個 |
| [code/escrow/foundry.toml](code/escrow/foundry.toml) | エスクローのビルド設定（via-IR、optimizerオン、fuzz seedを固定） |
| [code/escrow/src/Escrow51.sol](code/escrow/src/Escrow51.sol) | 範囲のコードである講義用のエスクロー（直す前のバージョン） |
| [code/escrow/src/EscrowFixed51.sol](code/escrow/src/EscrowFixed51.sol) | refundに確認済みかどうかのチェックを一行足した、直したバージョン |
| [code/escrow/test/Escrow51.t.sol](code/escrow/test/Escrow51.t.sol) | 正常な道、確認後の払い戻しの再現、締め切りのその秒、直したバージョンのテスト六つと、テスト用のトークン |

### 実行結果

空行・コメント行を除いた範囲の行数は、Market.sol 123、MarketMath.sol 21、MarketTypes.sol 26、IMarket.sol 47（合計217）、Escrow51.sol 50である。

Marketを読んだ五つの順番：

| 順番 | Market |
|---|---|
| 何をしようとするのか | 管理者が上げたトークンを預けて引き出す市場 |
| 状態 | status、assets、assetConfig、positions、totalDeposits、totalBorrows / immutable admin、interestRate、collateralRatio |
| 誰がどう変えるのか | 誰でも：deposit、withdraw、withdrawAll / 管理者：addAsset、setStatus |
| 防ぐもの | 上場の確認、0の金額、Activeでないときの預け入れ、Frozenのときの資産の追加、預けたより多い引き出し |
| 防げないもの | 既知の問題の欄の信頼の前提の三行（手数料トークン、直接送ったトークン、ブロック内の順番） |

Escrow51を読んだ五つの順番：

| 順番 | Escrow51 |
|---|---|
| 何をしようとするのか | 購入者が預け、受け取ったと確認すれば販売者が引き出す。締め切りまでに確認がなければ購入者が払い戻しを受ける |
| 状態 | amount、confirmed、settled / immutable token、buyer、seller、deadline |
| 誰がどう変えるのか | 購入者：fund、confirm、refund / 販売者：release |
| 防ぐもの | 呼んだ人の確認、二重の預け入れ、確認前のrelease、二重の精算、締め切り前の払い戻し |
| 防げないもの | releaseはconfirmedを見るが、refundは見ない（候補） |

ローカルのanvilにMockTokenとMarketをデプロイした結果（`forge create`）：

```
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
Transaction hash: 0xd9752c5f5e3e20b1dc265ec0276d6011ad09c42e1daa885c67d9a2acfa6f9027
```

`cast call`と`cast storage`で読んだデプロイの値。スロット0はstatus（0ならActive）で、残りの三つはimmutableなのでランタイムのコードの中に入っている。

```
admin()            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
interestRate()     50000000000000000 [5e16]
collateralRatio()  80
storage slot 0     0x0000000000000000000000000000000000000000000000000000000000000000
```

`cast tx <ハッシュ> input`の末尾96バイト（32バイトずつ区切って表示）。管理者のアドレス、0xb1a2bc2ec50000 = 5e16、0x50 = 80である。

```
000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
00000000000000000000000000000000000000000000000000b1a2bc2ec50000
0000000000000000000000000000000000000000000000000000000000000050
```

お金が出ていく行は三つである（`grep -n "\.transfer("`）：

```
contest/src/Market.sol:187:        bool ok = IERC20(asset).transfer(msg.sender, amount); // 第83講
escrow/src/Escrow51.sol:53:        token.transfer(seller, amount);
escrow/src/Escrow51.sol:62:        token.transfer(buyer, amount);
```

Marketの候補の確認テスト（`forge test --offline --match-contract Contest51Test -vv`）。写しの全体は41スイート117個が通る。

```
[PASS] test_adminFreezeBlocksDeposit() (gas: 283572)
[PASS] test_collateralAndBorrowsStayZero() (gas: 155520)
[PASS] test_elapsedOfNeverDeposited() (gas: 15319)
[PASS] test_feeTokenIsKnownIssue() (gas: 722606)
[PASS] test_interestForOverflowPanics() (gas: 9281)
[PASS] test_withdrawWhileDepositPaused() (gas: 232304)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

Escrow51のテスト（`forge test --offline --match-contract Escrow51Test -vv`）。`test_fixed`の二つは直したバージョンのテストである。

```
[PASS] test_fixedRefundAfterConfirmReverts() (gas: 209405)
[PASS] test_fixedRefundWithoutConfirm() (gas: 157310)
[PASS] test_refundAfterConfirm() (gas: 216763)
[PASS] test_refundAtDeadlineTooEarly() (gas: 104519)
[PASS] test_refundWithoutConfirm() (gas: 157044)
[PASS] test_releaseAfterConfirm() (gas: 183877)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

`test_refundAfterConfirm`は、購入者がfund(100)、confirmのあと締め切り + 1秒にrefundすると、購入者100、販売者0になり、販売者のreleaseが`AlreadySettled`で止まることを見せる。

候補九つの振り分け：

| 候補 | 結果 | 振り分け |
|---|---|---|
| 1 Marketの手数料トークン | 帳簿200・残高198、bobの出金が差し戻し | 既知の問題（監査報告書L-01）、出さない |
| 2 管理者のFrozen | 預け入れはNotActive(2)、資産の追加はMarketFrozen、出金は通る | 基準によって低の報告書の中央集権の項目か無効 |
| 3 elapsedOf | 時刻1,700,000,000で1,700,000,000 | 既知の問題（監査報告書I-02）、出さない |
| 4 常に0の二つ | collateralCount 0、totalBorrows 0 | 既知の問題（監査報告書I-01）、出さない |
| 5 interestFor | uint256の最大値でPanic 0x11 | 情報 |
| 6 DepositPausedでの出金 | 出金が通る | 仕様どおり、出さない |
| 7 Escrow51の確認後の払い戻し | 販売者の代金100が損なわれる | 中の候補、提出 |
| 8 Escrow51のtransferの戻り値 | READMEの使うトークンの欄がboolの標準トークン | 低 |
| 9 Escrow51の締め切りのその秒 | TooEarly、コメント「締め切りが過ぎると」のとおり | 仕様どおり、出さない |

### 試すときの注意

- Marketのテストは、`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガスの記録の照合を切って回す。`snapshots/`は添付していない。
- デプロイのアドレスは、新しいanvilでアカウント0番がMockTokenを先にデプロイしたときの値である。順番が変わればアドレスも変わる。
- `cast tx ... input`の出力は一行である。末尾192文字（96バイト）を切り取り、32バイトずつ区切って読む。
- 実際のデプロイなら、管理者の欄には三人中二人のマルチシグのアドレスが入る。この実習のアカウント0番はローカル専用である。
- 「おかしい」という感覚は、数字に変えてから出す。確認後の払い戻しは販売者0・購入者100と見え、締め切りのその秒は仕様どおりTooEarlyだった。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンとプラットフォームのルールは変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30。contestはMarketのfoundry.toml（via-IR、optimizerオン）、escrowはoptimizerオン（runs 200）・via-IRオン・evm osaka | 2026-10-21 |
| 行数の数え方 | 空行・コメント行（`//`、`///`、`/* */`）を除いた行。Market.sol 123、MarketMath.sol 21、MarketTypes.sol 26、IMarket.sol 47、Escrow51.sol 50、EscrowFixed51.sol 49 | 2026-10-21 |
| デプロイのアドレス（ローカル） | MockToken 0x5FbDB2315678afecb367f032d93F642f64180aa3、Market 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512。アカウント0番が新しいanvilでMockTokenを先にデプロイしたとき | 2026-10-21 |
| デプロイの値 | admin 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266、interestRate 5e16、collateralRatio 80、スロット0・1 = 0、ランタイムのコードの中の管理者のアドレス2か所、ランタイム2,990バイト | 2026-10-21 |
| テストのガス（contest） | adminFreezeBlocksDeposit 283,572 / collateralAndBorrowsStayZero 155,520 / elapsedOfNeverDeposited 15,319 / feeTokenIsKnownIssue 722,606 / interestForOverflowPanics 9,281 / withdrawWhileDepositPaused 232,304 | 2026-10-21 |
| テストのガス（escrow） | fixedRefundAfterConfirmReverts 209,405 / fixedRefundWithoutConfirm 157,310 / refundAfterConfirm 216,763 / refundAtDeadlineTooEarly 104,519 / refundWithoutConfirm 157,044 / releaseAfterConfirm 183,877 | 2026-10-21 |
| Sherlockの判定基準（旧コンテスト） | 管理者関数は正しく使うとみなす、内部の役割は基本的に信頼、損失のない設計の問題は情報、READMEがコメントより優先。Highは外部条件の大きな制約のない直接の損失、Mediumは特定の条件・状態が必要か、大きく制限された損失 | 2026-10-21 |
| Code4renaの深刻度の分類 | Mediumは資産が直接危険ではないが機能・可用性が損なわれる。QAにGovernance/Centralization risk（管理者権限を含む）。権限の誤用はQA報告書で。手数料トークン・標準と違うERC-20は、対応トークンとして書いていなければ範囲外（USDTは例外） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 低の報告書と中の等級の提出文の書き方、等級の主張 | [第193講](../../part12/lecture193/) |
| 手数料トークンを受け付ける帳簿の設計 | [第256講](../../part20/lecture256/) |
| 外部の公開リポジトリを受け取って同じ手順で読む | [第260講](../../part20/lecture260/) |
| プラットフォームごとの等級の定義・判定ルールの原文全体 | 付録（時効性のシート） |

出典と参考資料は[reference.md](reference.md)にまとめた。
