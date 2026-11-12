# 第37講 投票

第3部 Solidity入門・第10章 Solidity by Example

[← 第36講](../../part3/lecture36/) | [第3部 目次](../) | [第38講 →](../../part3/lecture38/)

## この講義の問い

初めて見るコントラクト一つを、どんな順番で読めば読んだと言えるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトから`src`と`test`のCounterのファイルを消し、下のファイルを入れる。テストにはforge-stdが必要である（`lib/forge-std`）。`src/Ballot.sol`は、Solidity公式ドキュメントv0.8.36のSolidity by ExampleにあるVotingの例の原文そのままである（SPDX GPL-3.0、`pragma solidity >=0.7.0 <0.9.0;`、156行のうちコメント56行）。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Ballot.sol](code/src/Ballot.sol) | 公式ドキュメントのVotingの例の原文 |
| [code/src/BallotPrivate.sol](code/src/BallotPrivate.sol) | コントラクト名と、`voters`を`private`に変えた2行だけが違うコピー |
| [code/test/Ballot.t.sol](code/test/Ballot.t.sol) | 議長による投票権の付与と、議長でないアカウントの失敗 |
| [code/test/DelegateGas.t.sol](code/test/DelegateGas.t.sol) | 委任の連鎖が1・5・20人のときの`delegate`1回のガス |

### 実行結果

ビルドすると、forgeのリンターがwhileの中のrequire（95行目）に`require-revert-in-loop`の警告を一つ出す。原文のままなので直さない。

`forge test --match-contract DelegateGas -vv`。ログの値が`delegate`1回のガスである（gasleft()の差、トランザクションの基本コストは含まない）：

```
[PASS] test_Chain1() (gas: 165888)
Logs:
  chain 1 : 55434
[PASS] test_Chain20() (gas: 2231746)
Logs:
  chain 20: 105727
[PASS] test_Chain5() (gas: 600839)
Logs:
  chain 5 : 66022
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

ローカルのanvilに議案coffee、teaでデプロイしたあと（`cast --format-bytes32-string`でbytes32の値を作る）、アカウント0が議長、1〜4がアリス・ボブ・キャロル・デイブという実演。アリスがcoffeeに投票し、ボブがアリスに委任し、キャロルがteaに投票した結果：

```
proposals(0)  coffee, 2
proposals(1)  tea, 1
winnerName()  coffee
```

失敗三つ（`cast send`のリバートの理由）：

```
アリスがgiveRightToVoteを呼ぶ   Only chairperson can give right to vote.
アリスが再びvote                Already voted.
デイブがvote(5)                 panic: array out-of-bounds access (0x32)
```

`voters`マッピングでのアリスの欄の番号（`cast index address <アリス> 1`）と、その欄から三つの欄（`cast storage`）。weight、votedとdelegateを一緒に入れた欄、voteの順である：

```
0x3c8e904cdb19937d60d41c8d984b1a8803ad6e0891b4f9e032dcec2a22c2c7f5   1
0x3c8e904cdb19937d60d41c8d984b1a8803ad6e0891b4f9e032dcec2a22c2c7f6   1
0x3c8e904cdb19937d60d41c8d984b1a8803ad6e0891b4f9e032dcec2a22c2c7f7   0
```

アリスの`vote(0)`のトランザクションの入力（`cast tx <ハッシュ> input`）では、セレクタの後ろに議案の番号がそのまま見える：

```
0x0121b93f0000000000000000000000000000000000000000000000000000000000000000
```

`voters`を`private`に変えたBallotPrivateでは、`voters(address)`の呼び出しが`execution reverted, data: "0x"`で失敗する。それでも同じ方法で計算した欄を`cast storage`で読むと、アリスは2、1、1が出て、アリスに委任したボブの2番目の欄にはアリスのアドレスが入っている：

```
0x000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c801
```

デイブがキャロルに委任して2対2の同点にすると、`winnerName()`は番号が前の議案であるcoffeeを返す。

### 試すときの注意

- DelegateGasでは、委任の連鎖を前の人から作る。後ろの人から作ると、`delegate`が最後までたどったアドレスを保存するので、連鎖が一段に縮む。
- 同点なら、`winningProposal`は先に最大値に達した、番号が前の議案を選ぶ。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidity公式ドキュメントのバージョン | v0.8.36（Solidity by Example、Votingの節） | 2026-10-19 |
| solcのバージョン | 0.8.30 | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| delegateのガス（連鎖1 / 5 / 20人） | 55,434 / 66,022 / 105,727（トランザクションの基本コストは含まない） | 2026-10-19 |
| anvilでの実演のgasUsed | giveRightToVote 48,642（最初の付与） / vote 72,984（アリス） / delegate 61,199（ボブ） | 2026-10-19 |
| テストのガス | test_ChairGivesRight 65,543 / test_RevertWhen_NotChair 37,854 | 2026-10-19 |
| Panicのコード | 0x32 = 配列の範囲外アクセス | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 関数宣言1行の表記（可視性、view、戻り値の名前） | [第47講](../../part4/lecture47/) |
| 可視性の4段階（public、external、internal、private） | [第95講](../../part6/lecture95/) |
| 自動getterの形（マッピング・配列・structの返し方） | [第96講](../../part6/lecture96/) |
| 状態変数の可視性とアクセスのコスト | [第97講](../../part6/lecture97/) |
| requireの行をmodifierにまとめる、modifierの誤用 | [第48講](../../part4/lecture48/)、[第104講](../../part6/lecture104/) |
| storageの参照とコピーの規則 | [第63講](../../part4/lecture63/) |
| structの欄の配置（boolとaddressが一つの欄） | [第135講](../../part8/lecture135/) |
| 投票内容を隠す（コミットと公開） | [第38講](../../part3/lecture38/) |
| 投票の締め切りと時間の条件 | [第38講](../../part3/lecture38/)、[第76講](../../part5/lecture76/) |
| 議長一人に集まった権限、アクセス制御のパターン | [第151講](../../part9/lecture151/)、[第176講](../../part11/lecture176/) |
| 投票権トークン、委任、スナップショットでの集計 | [第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/) |
| 初めて見るコードベースを読む監査の手順 | [第187講](../../part12/lecture187/)、[第192講](../../part12/lecture192/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
