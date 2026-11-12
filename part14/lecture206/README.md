# 第206講 VRFとランダム性の調達

第14部 オラクル・クロスチェーン・ガバナンス・第56章 オラクルの統合

[← 第205講](../../part14/lecture205/) | [第14部 目次](../) | [第207講 →](../../part14/lecture207/)

## この講義の問い

チェーンの上で誰も前もって知らない数を使うには、どこから受け取ってくるのか。受け取ってくる道の途中で、誰が結果を選んだり止めたりできるのか。受け取る側のコントラクトは、何を守るべきなのか。

## 実習資料

### 準備

Marketとは関係のない小さなFoundryプロジェクト（`vrf`）一つで行う。チェーンの外の乱数を要求と応答の二つの取引で受け取る流れを、講義用にまねたコードで、実在する乱数サービスのコードではない。依存はforge-std 1.17.0（`lib/`）一つである。テストはforgeの中で動き、二つの取引のデモはローカルのanvil一つに既定のテスト用アカウントで取引を送る。オラクルの鍵はanvilのアカウント9番（公開されたテスト用の鍵）である。外部のサービスへの要求・サブスクリプション・鍵は使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、evm osaka |
| [code/src/CommitRaffle.sol](code/src/CommitRaffle.sol) | コミット・リビールの抽選。コミット1時間・リビール1時間の締め切り、保証金1 ether、開かなかった人の保証金は当選者に |
| [code/src/MockCoordinator.sol](code/src/MockCoordinator.sol) | 乱数の要求と応答のまね。オラクルの鍵の署名を確かめ、乱数 = keccak256(署名)、sが大きい側の署名は拒否、受け取る側を呼ぶ前にdoneを書く |
| [code/src/Raffle.sol](code/src/Raffle.sol) | チェーンの外の乱数で当選者を選ぶ抽選。要求のあとの参加・再要求・取り消しなし、受け取る関数は乱数だけを書き、当選者は`settle`で |
| [code/src/HeavyRaffle.sol](code/src/HeavyRaffle.sol) | 比較用。受け取る関数の中で参加者のリストを全部回る形（ガスリミットに引っかかる） |
| [code/test/Vrf206.t.sol](code/test/Vrf206.t.sol) | Vrf206Testの七つ |

### 実行結果

`forge test --offline -vv`、7個通過：

| テスト | ガス | 結果 |
|---|---|---|
| test_commitRevealDeadlineAndDeposit | 535,339 | p1・p2・p3が1 etherずつコミット。間違った秘密999は`BadReveal`、締め切りのあとのリビールは`WrongPhase(今, commitEnd, revealEnd)`。finalizeのあと当選者の残高2 ether、開かなかったp3は0 |
| test_proofChecks | 257,844 | ほかの鍵（0xB0B）の署名は`BadProof`。sをn − sに、vを27 ↔ 28に変えた署名は、ecrecoverが同じオラクルのアドレスを出すが`BadProof`（s ≤ n/2だけを受け付ける） |
| test_twoTransactions | 346,722 | 要求のあと乱数0、確認ブロック三つのあとに応答、乱数 = keccak256(署名) |
| test_closedAfterRequest | 200,064 | 要求のあと、enter・drawが`NotOpen(Drawing)` |
| test_onlyCoordinator | 177,580 | p1が受け取る関数を直接呼ぶと`OnlyCoordinator(p1, coordinator)` |
| test_tooEarly | 197,897 | 要求 + 2ブロックで送った応答が`TooEarly(要求 + 2, 要求 + 3)` |
| test_heavyCallbackNotRetried | 15,227,458 | 参加者300人を受け取る関数の中で回すと、ガスリミット100,000に引っかかって`RandomWordsFulfilled`のsuccessがfalse。抽選はDrawingにとどまり、同じ署名でもう一度送ると`AlreadyFulfilled(1)` |

`test_commitRevealDeadlineAndDeposit`のログ：

```
[PASS] test_commitRevealDeadlineAndDeposit() (gas: 535339)
Logs:
  winner 0x0000000000000000000000000000000000001001
```

anvilで要求の取引と応答の取引を別々に送った出力。署名は`cast wallet sign --no-hash`で作った：

```
oracle (account 9): 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
coordinator 0x5FbDB2315678afecb367f032d93F642f64180aa3
raffle 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
players: 3
--- tx 1: draw (request)
blockNumber          6
gasUsed              142104
status               1 (success)
requestId 1, state 1, word 0
  data: 0xfce06849465a0dc8443a0c40831876759b16fe1174d0cb911e97abae76337590
--- oracle side (off chain): sign digest
digest 0xdf6a9879b9f4aa209dca9f3615e44f0c503ce8f0ea4816d97bab6307ee554046
--- fulfill too early
0xe58369d1...07...09
--- tx 2: fulfill (response)
blockNumber          10
gasUsed              88585
status               1 (success)
keccak(sig) 0xcdab18a772826c98fc72ea052a9b62bc2657a3dd128ff1326a48ef53a2243943
winner 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
--- same fulfill again
AlreadyFulfilled
```

`0xe58369d1`は`TooEarly`のセレクタで、引数は7と9である。digestはkeccak256(コーディネーター、チェーンの番号、要求の番号、seed)で、seedには要求したコントラクトのアドレスが入る。当選者はアカウント1番である。

### 試すときの注意

- まねでは、本物のVRFの証明の代わりにECDSAの署名を使う。署名には毎回新しいランダムな値が入り、同じ入力に合う署名が複数あるので、まねではオラクルが気に入った署名を選んで送れる。本物のVRFは、同じ入力に合う答えが一つしかない。
- 応答の取引のcalldataに署名が入っているので、ブロックに入る前に誰でも乱数を計算できる。だから要求を送ったあとは参加を締め切る。当選番号は乱数を参加者の数で割った余りなので、参加者が一人増えるだけで結果が変わる。
- まねのseedにはブロックの値がないので、要求のブロックからブロックの数だけを数える。実際のサービスで確認ブロックを待つ理由は、要求のブロックが書き直されると要求と答えが食い違うことがあるからである。
- 受け取る関数は乱数だけを書いて終わり、重い処理は`settle`のように別に呼ぶ関数に出す。受け取る関数がリバートしても、もう一度は呼んでくれない。
- オラクルは答えを選べなくても、答えを送らないことはできる。引き直す関数を開けておくと、その扉を開ける側が結果を選べることになるので、Raffleには置かなかった。
- 確認ブロック3、受け取る関数のガスリミット100,000、保証金1 ether、コミット・リビール1時間ずつ、参加者300人は講義用の設計値である。
- Marketは乱数を読まない（prevrandao・blockhashを使う箇所は0）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンや公式ドキュメントが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizer 200、osaka | 2026-10-21 |
| Vrf206Testのガス | closedAfterRequest 200,064 / commitRevealDeadlineAndDeposit 535,339 / heavyCallbackNotRetried 15,227,458 / onlyCoordinator 177,580 / proofChecks 257,844 / tooEarly 197,897 / twoTransactions 346,722 | 2026-10-21 |
| anvilのデモ | アカウント0番がデプロイしたMockCoordinator `0x5FbDB2315678afecb367f032d93F642f64180aa3`・Raffle `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、オラクルはアカウント9番`0xa0Ee7A142d267C1f36714E4a8F75612F20a79720`、drawはブロック6・gasUsed 142,104、fulfillはブロック10・gasUsed 88,585、当選者はアカウント1番`0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | 2026-10-21 |
| 公式ドキュメントの原文 | Chainlink VRF v2.5のセキュリティの考慮事項の見出し六つと最初の文 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| VRFの証明の計算（楕円曲線上の証明） | 付録（原文） |
| 実在する乱数サービスのサブスクリプション・料金・確認ブロックの値 | 付録のデータシート |
| block.prevrandaoを使う道とその限界 | 付録（[第175講](../../part11/lecture175/)のドキュメントの画面） |
| 投票・抽選の締め切りの設計 | [第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/)、[第215講](../../part14/lecture215/)、[第216講](../../part14/lecture216/) |
| チェーン間のメッセージを要求と応答で受け取る流れ | [第209講](../../part14/lecture209/) |
| 受け取る関数の失敗のイベントを見張ること | [第238講](../../part18/lecture238/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
