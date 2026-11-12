# 第213講 投票権トークンと委任

第14部 オラクル・クロスチェーン・ガバナンス・第58章 ガバナンスの実装

[← 第212講](../../part14/lecture212/) | [第14部 目次](../) | [第214講 →](../../part14/lecture214/)

## この講義の問い

票はどこに積み上がるのか。他人に票を預けると、何が渡り何が残るのか。トークンを移すと、票はどうなるのか。票の記録は、誰がいくら払って残すのか。

## 実習資料

### 準備

Marketとは関係のない小さなFoundryプロジェクト（`gov`）一つで行う。投票権トークンGovTokenはOpenZeppelinのERC20、ERC20Permit、ERC20Votesを継承し、コンストラクタで1000を発行する。依存はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`lib/`）である。テストの中のブロックの時刻は、via-IRのビルドで`vm.getBlockTimestamp()`で読む。ガスは、ローカルのanvil一つにGovTokenをデプロイし、既定のテスト用アカウント0・2・3・4・5で取引を送ってレシートから読んだ。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka |
| [code/src/GovToken.sol](code/src/GovToken.sol) | 投票権トークン（ERC20 + ERC20Permit + ERC20Votes）、コンストラクタで発行 |
| [code/test/Votes213.t.sol](code/test/Votes213.t.sol) | Votes213Testの十個。デプロイしたアカウントがaliceに100を渡し、10番ブロックから始める |

### 実行結果

`forge test --offline --match-contract Votes213Test -vvv`：

```
Ran 10 tests for test/Votes213.t.sol:Votes213Test
[PASS] test_checkpointsPerBlock() (gas: 301023)
[PASS] test_clockMode() (gas: 13285)
[PASS] test_delegateBySig() (gas: 204017)
[PASS] test_delegateBySigExpired() (gas: 53363)
[PASS] test_delegateToOther() (gas: 176524)
[PASS] test_redelegateMovesAll() (gas: 215599)
[PASS] test_supplyCap() (gas: 4205)
[PASS] test_transferGas() (gas: 416984)
Logs:
  transfer, no delegation: 58619
  transfer, both delegated: 136408

[PASS] test_transferToDelegatedMovesVotes() (gas: 289971)
[PASS] test_votesFollowTransfer() (gas: 208397)
Suite result: ok. 10 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_delegateToOther | aliceがdaveに委任すると、aliceの残高100・票0、`delegates(alice)` = dave、daveの残高0・票100。daveがaliceの100をtransferFromすると`ERC20InsufficientAllowance(dave, 0, 100)` |
| test_redelegateMovesAll | aliceがerinに委任し直すと、dave 0、erin 100 |
| test_votesFollowTransfer | 委任していないcarolに40を送ると、aliceの票60、carolの票0（代理人は0アドレス）。総供給量1000のまま |
| test_transferToDelegatedMovesVotes | 残高0のときにdaveに委任しておいたcarolに40を送ると、alice 60、dave 40 |
| test_checkpointsPerBlock | aliceの欄は（ブロック10、100）、（ブロック11、50）。11番ブロックの中で経由した60は残らない。12番ブロックで`getPastVotes(alice, 12)`は`ERC5805FutureLookup(12, 12)` |
| test_clockMode | `CLOCK_MODE()` = `mode=blocknumber&from=default` |
| test_supplyCap | 2^208を発行すると`ERC20ExceededSafeSupply(2^208, 2^208 − 1)` |
| test_delegateBySig | ほかのアカウントが送ったaliceの署名の委任で、`delegates(alice)` = dave、`nonces(alice)` 1。同じ署名をもう一度出すと`InvalidAccountNonce(alice, 1)` |
| test_delegateBySigExpired | 期限の1秒後に`VotesExpiredSignature(expiry)` |

`test_transferGas`のログの値は一つのテストのトランザクションの中で測った値なので、前のアクセスで温まったスロットの影響が混ざる。送金・委任のガスは、下のanvilのレシートの値で見る。

anvilでアカウント0がGovTokenを1000発行し、アカウント2・3・4・5に100ずつ配ってから測ったgasUsed：

```
$ anvil --port 9213
$ forge create src/GovToken.sol:GovToken --rpc-url http://127.0.0.1:9213 \
    --private-key <アカウント0の鍵> --broadcast --offline --constructor-args 1000
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
$ cast send <トークン> "transfer(address,uint256)" <アカウント3> 10 --private-key <アカウント2の鍵> ...
$ cast send <トークン> "delegate(address)" <アカウント4> --private-key <アカウント4の鍵> ...
$ cast send <トークン> "transfer(address,uint256)" <アカウント5> 10 --private-key <アカウント4の鍵> ...
```

| したこと | gasUsed | 変えた欄 |
|---|---|---|
| 委任していないアカウント2 → アカウント3、transfer 10 | 39,033（2回同じ、ブロック6・7） | 残高二つ |
| アカウント4・5の最初のdelegate（自分） | 95,581（ブロック8・9） | delegatesの1欄、票の欄を新しく |
| 両方委任したアカウント4 → アカウント5、transfer 10 | 104,217（ブロックを変えて2回同じ、ブロック10・11） | 残高二つ、代理人の欄二つを新しく |

そのあと`getVotes`はアカウント4が80、アカウント5が120、アカウント2・3は0で、`balanceOf`はアカウント2が80、アカウント3が120である。`numCheckpoints`はアカウント4・5のどちらも3、アカウント4の欄は（8、100）、（10、90）、（11、80）である。`CLOCK_MODE`は`mode=blocknumber&from=default`、`clock`は11（ブロック番号11）である。

### 試すときの注意

- 票として数えるには、必ず委任しなければならない。直接投票するには自分自身に委任する。委任の前の`getVotes`は、残高があっても0である。
- 委任は、`delegates`マッピングの1欄と代理人側の票の記録だけを変える。残高と許可の上限（allowance）はそのままなので、代理人はトークンを移せない。
- チェックポイントの欄一つは、ブロック番号48ビットと票の数208ビットでスロット一つを占める（`Checkpoint208`）。最後の欄のブロックが今のブロックと同じなら値だけを直し、違えば新しい欄を付け足す。
- 今のブロックは問い合わせられない。まだ終わっていないブロックの欄は、そのブロックの中で変わりうるからである。だから一つのトランザクションの中で借りて返した票は、前のブロックの記録にない。
- 発行の上限2^208 − 1は、欄の票の数208ビットから来る。
- `delegateBySig`が署名する値は、受け取る代理人、使用番号（nonce）、期限の時刻（expiry）で、EIP-712のドメインにトークンの名前、バージョン、チェーンの番号、トークンのアドレスが入る。送った人ではなく、署名から復元したアドレスの委任になる。
- 票を数える根拠はストレージのチェックポイントである。`DelegateChanged`・`DelegateVotesChanged`のログは、チェーンの外のツールが読む記録である。
- 鍵はanvilの起動画面の既定のテスト用の鍵である。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンやライブラリのバージョンが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0（Votes.solの先頭の表記last updated v5.2.0） | 2026-10-21 |
| anvilのガス | 委任していないtransfer 10：39,033 / 最初のdelegate（自分）：95,581 / 両方委任したtransfer 10：104,217 | 2026-10-21 |
| Votes213Testのガス | checkpointsPerBlock 301,023 / clockMode 13,285 / delegateBySig 204,017 / delegateBySigExpired 53,363 / delegateToOther 176,524 / redelegateMovesAll 215,599 / supplyCap 4,205 / transferGas 416,984 / transferToDelegatedMovesVotes 289,971 / votesFollowTransfer 208,397 | 2026-10-21 |
| 事件の年 | Beanstalk 2022 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 委任された票を、委任した人が直接の投票で上書きする集計（OZ GovernorCountingOverridable） | 付録（扱わない） |
| タイムスタンプの時計で票を数えること | 付録（扱わない） |
| NFTを票として数える形（ERC721Votes） | 付録（扱わない） |
| 代理人に票が集まる度合いを測ること | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |
| 票を数えるブロック、定足数、賛成・反対・棄権の集計 | [第214講](../../part14/lecture214/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
