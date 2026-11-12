# 第223講 ソーシャルリカバリーとウォレットの設計

第15部 アカウント抽象化・第60章 アカウント抽象化の実践

[← 第222講](../../part15/lecture222/) | [第15部 目次](../) | [第224講 →](../../part16/lecture224/)

## この講義の問い

鍵をなくしたとき、アカウントは何で持ち主を替えるのか。保護者に何を任せ、何を任せないのか、待ち時間は誰を守るのか。これまで見てきたアカウントを並べてウォレットを設計するとき、何を決めるのか。

## 実習資料

### 準備

第59〜60章の共用のアカウント抽象化のプロジェクト`aa`から始める。この講義では、講義用のソーシャルリカバリーのアカウント`Recovery223.sol`とそのテストを使い、第219講のEntryPointのまね（`EntryPoint219.sol`、`UserOp.sol`）でUserOperationを回す。テストの土台（`test/Base.sol`）が、通しプロジェクトMarket（第53章の終わりのバージョン）のsrcのコピーと標準のトークン`StdToken`を`src/market/`に置いてデプロイするので、そのファイルも一緒に入れた。この講義のテストはMarketを呼ばず、トークンだけを使う。依存はforge-std（`lib/forge-std`）一つである。

anvilは`--hardfork osaka`で立ち上げ、castだけで回す：デプロイ、保護者が署名するハッシュの計算し直し、失敗三つ、復旧の開始、失敗二つ、`evm_increaseTime 172800`、仕上げ、終わった復旧の署名の再利用。持ち主の鍵`0xA11CE`、新しい持ち主の鍵`0xB0B`、保護者の鍵`0x6A1`・`0x6A2`・`0x6A3`は誰でも知っているデモ用の鍵なので、実際の資産には使わない。`Recovery223`は講義用のアカウントである。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシードを固定 |
| [code/src/Recovery223.sol](code/src/Recovery223.sol) | 講義用のソーシャルリカバリーのアカウント：owner、isGuardian、threshold・delayのimmutable、recoveryNonce、pending、recoveryDigest、startRecovery、cancelRecovery（自分だけ）、finishRecovery、validateUserOp、execute（EntryPointだけ）、エラーNotGuardian・GuardiansNotSorted・NotEnoughGuardians・RecoveryPending・NoPendingRecovery・RecoveryNotReady |
| [code/src/EntryPoint219.sol](code/src/EntryPoint219.sol) | 第219講のEntryPointのまねのまま |
| [code/src/UserOp.sol](code/src/UserOp.sol) | PackedUserOperation、IAccount、ValidationData |
| [code/test/Base.sol](code/test/Base.sol) | MarketとStdTokenをデプロイするテストの土台 |
| [code/test/Recovery223.t.sol](code/test/Recovery223.t.sol) | Recovery223Testの11個 |
| [code/src/market/Market.sol](code/src/market/Market.sol) | 通しプロジェクトMarket（第53章の終わりのバージョン）のコピー |
| [code/src/market/IMarket.sol](code/src/market/IMarket.sol) | Marketのインターフェース |
| [code/src/market/MarketMath.sol](code/src/market/MarketMath.sol) | 利息・ポジションの計算のライブラリ |
| [code/src/market/MarketTypes.sol](code/src/market/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/src/market/StdToken.sol](code/src/market/StdToken.sol) | 承認を要求するテスト用の標準のトークン |

### 実行結果

`forge test --offline --match-contract Recovery223Test -vv`：

```
Ran 11 tests for test/Recovery223.t.sol:Recovery223Test
[PASS] test_finishAfterDelayChangesOwner() (gas: 456224)
[PASS] test_finishBeforeDelayRejected() (gas: 140365)
[PASS] test_guardianCannotMoveFunds() (gas: 142218)
[PASS] test_nonGuardianSigRejected() (gas: 67954)
[PASS] test_oneGuardianNotEnough() (gas: 62964)
[PASS] test_ownerCancelsDuringDelay() (gas: 299211)
[PASS] test_printDigest() (gas: 38451)
Logs:
  guardian 0 0xffac882a21894FbD370Fc70124a90050EB7272Ec
  guardian 1 0x37334Ba085B98D764d7dA6c007f5b124FEe38422
  guardian 2 0x1BfBe039Af61225f7Ce54c2e8E6Af477531376d7
  0xe2a204450c2dffa5b2886ac8b8b0696e66042fc8a727f3552670475d2bb240ea
[PASS] test_sameGuardianTwiceRejected() (gas: 68603)
[PASS] test_sigsForOtherAccountRejected() (gas: 82070)
[PASS] test_sigsNotReusable() (gas: 295453)
[PASS] test_twoGuardiansStartRecovery() (gas: 138863)
Suite result: ok. 11 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_twoGuardiansStartRecovery | pendingに新しい持ち主、readyAt 1,172,800、ownerはそのまま、recoveryNonce 1 |
| test_oneGuardianNotEnough | `NotEnoughGuardians(1, 2)` |
| test_sameGuardianTwiceRejected | 同じ署名二つ → `GuardiansNotSorted` |
| test_nonGuardianSigRejected | 保護者ではない鍵（0xBAD）のアドレスで`NotGuardian` |
| test_finishBeforeDelayRejected | 1秒前 → `RecoveryNotReady(1172800)` |
| test_finishAfterDelayChangesOwner | owner = 新しい持ち主。古い鍵のUserOperation → AA24、新しい鍵のUserOperationでトークン100を送る |
| test_ownerCancelsDuringDelay | 持ち主のUserOperationで取り消し → pending 0、待ってからfinish → `NoPendingRecovery`、ownerはそのまま |
| test_sigsNotReusable | 取り消しのあと同じ保護者の署名をもう一度 → 見当違いのアドレスで`NotGuardian` |
| test_sigsForOtherAccountRejected | 保護者が同じほかのアカウントに出す → 見当違いのアドレスで`NotGuardian` |
| test_guardianCannotMoveFunds | 保護者の鍵のUserOperation → AA24、トークン500のまま |
| test_printDigest | 保護者のアドレス三つ、recoveryDigest 0xe2a20445…240ea |

anvilでデプロイし、保護者が署名する前にハッシュを`cast keccak`・`cast abi-encode`で計算し直した結果（アカウントが返した値と同じ）：

```
owner 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7 new 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c
guardians 0xffac882a21894FbD370Fc70124a90050EB7272Ec 0x37334Ba085B98D764d7dA6c007f5b124FEe38422 0x1BfBe039Af61225f7Ce54c2e8E6Af477531376d7
entryPoint 0x5FbDB2315678afecb367f032d93F642f64180aa3 account 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
owner() 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7 threshold 2 delay 172800
recoveryDigest(new) 0x633a66a1a1eaf59195b879cdc46ed63147b384b4817d6c1a285253712ee3a81d
check: 0x633a66a1a1eaf59195b879cdc46ed63147b384b4817d6c1a285253712ee3a81d
```

続く段階（リバートは、castがデコードしたエラーの名前だけを書き写した）：

```
== 保護者一人（G3）だけ
NotEnoughGuardians(1, 2)
== 同じ保護者二人（G3、G3）
GuardiansNotSorted
== 保護者二人（G3、G1）、アカウント2番が送る
gasUsed              83664
status               1 (success)
pending 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c 1792697030  now 1792524230 recoveryNonce 1
== すぐに仕上げ
RecoveryNotReady(1792697030)
== 同じ署名でもう一度開始
RecoveryPending
== 2日後に仕上げ
gasUsed              28446
status               1 (success)
owner() 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c pending 0x0000000000000000000000000000000000000000 0
== 終わった復旧の署名をもう一度（復旧の使用番号1）
NotGuardian(0x3bBB537ABaedE4ce6f2B14461027693D6d67A1BF)
```

時刻の値はanvilの時計に従うので、実行するたびに違う。

### 試すときの注意

- 保護者は、持ち主の交換一つのためだけに集まる。保護者の鍵でUserOperationを出しても、お金は移せない（AA24）。
- 保護者の署名の材料は、チェーンの番号、アカウントのアドレス、復旧の使用番号、新しい持ち主の四つである。だから取り消された復旧や終わった復旧の署名、保護者が同じほかのアカウントに出した署名は、見当違いのアドレスに復元されて`NotGuardian`になる。
- 保護者の署名は、アドレスの昇順に付ける。同じ保護者を2回入れると`GuardiansNotSorted`である。
- 保護者も、署名の前にハッシュを自分で計算し直し、アカウントが見せた値と突き合わせる。
- 待ち時間（2日）は、保護者二人が示し合わせて持ち主を替えようとしたときに、持ち主が取り消す時間を与える。その時間の分だけ、本当の復旧も遅れる。
- テストの保護者の数（三人のうち二人）と待ち時間2日は講義用の値である。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ドキュメントとツールのバージョンが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Vitalik Buterinの記事 | "Why we need wide adoption of social recovery wallets"、2021-01-11 | 2026-10-21 |
| EIP-2612のpermitの欄 | `Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)` + EIP-712のドメイン | 2026-10-21 |
| ERC-1271の先頭の欄 | "Standard Signature Validation Method for Contracts"、Final、2018-07-25 | 2026-10-21 |
| EIP-7702の原文 | status Final、ファイルの最後のコミットbbc3f958（2025-10-07） | 2026-10-21 |
| Foundry | forge・cast・anvil 1.8.3、anvil `--hardfork osaka` | 2026-10-21 |
| solc・設定 | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| コントラクトのサイズ（ランタイム/initcodeのバイト） | Recovery223 2,410/2,859、EntryPoint219 5,222/5,248 | 2026-10-21 |
| anvilのgasUsed | startRecovery（保護者二人） 83,664 / finishRecovery 28,446 | 2026-10-21 |
| anvilの時刻 | 開始のブロック1792524230、readyAt 1792697030（anvilの時計、実行ごとに違う） | 2026-10-21 |
| テストのガス（Recovery223Test） | finishAfterDelayChangesOwner 456,224 / finishBeforeDelayRejected 140,365 / guardianCannotMoveFunds 142,218 / nonGuardianSigRejected 67,954 / oneGuardianNotEnough 62,964 / ownerCancelsDuringDelay 299,211 / printDigest 38,451 / sameGuardianTwiceRejected 68,603 / sigsForOtherAccountRejected 82,070 / sigsNotReusable 295,453 / twoGuardiansStartRecovery 138,863 | 2026-10-21 |
| デモのアドレス・鍵 | 持ち主の鍵0xA11CE → 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7、新しい持ち主の鍵0xB0B → 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c、保護者の鍵0x6A1 → 0xffac882a21894FbD370Fc70124a90050EB7272Ec、0x6A2 → 0x37334Ba085B98D764d7dA6c007f5b124FEe38422、0x6A3 → 0x1BfBe039Af61225f7Ce54c2e8E6Af477531376d7（すべてデモ用の公開された鍵、実際のお金には使わない）、EntryPoint219 0x5FbDB2315678afecb367f032d93F642f64180aa3、Recovery223 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512、アカウント2番0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 保護者のリストをハッシュで隠す | 付録 |
| 保護者の交換とその待ち時間（原文"only after a delay"） | 付録 |
| 鍵を奪われたときにアカウントを凍結する設計 | 付録 |
| コントラクトのアカウントの署名の確認（EIP-1271） | 付録（時効性のあるデータ） |
| キャップストーンでウォレットの設計の表を書き直す | [第253講](../../part20/lecture253/)、[第254講](../../part20/lecture254/)、[第255講](../../part20/lecture255/)、[第256講](../../part20/lecture256/) |
| ウォレットの画面の設計 | 扱わない |

出典と参考資料は[reference.md](reference.md)にまとめた。
