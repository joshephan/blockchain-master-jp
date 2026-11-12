# 第220講 Paymasterとガスの肩代わり

第15部 アカウント抽象化・第59章 アカウント抽象化の構造

[← 第219講](../../part15/lecture219/) | [第15部 目次](../) | [第221講 →](../../part15/lecture221/)

## この講義の問い

ETHを一つも持たないアカウントは、どうやって動くのか。他人のガスを払ってあげるコントラクトは、何を見て払うかを決め、そのお金はどこから出ていくのか。肩代わりの署名には、何を含めるべきなのか。

## 実習資料

### 準備

第59〜60章の共用のアカウント抽象化のプロジェクト`aa`から始める。第219講の`UserOp.sol`、EntryPointのまね`EntryPoint219.sol`、アカウント`Account219.sol`をそのまま使い、講義用のペイマスター二つ（`Paymaster220.sol`）とそのテストを足す。まねのEntryPointにはステーク・評判・シミュレーションの規則がなく、ペイマスター二つも講義用なので、実際の資産には使わない。

テストの土台（`test/Base.sol`）が、通しプロジェクトMarket（第53章の終わりのバージョン）のsrcのコピーと標準のトークン`StdToken`を`src/market/`に置いてデプロイする。依存はforge-std（`lib/forge-std`）一つである。anvilのデモは、`script/Demo.s.sol`の`run220()`を`forge script`で回す。肩代わりの鍵`0x5B0`、持ち主の鍵`0xA11CE`は誰でも知っているデモ用の鍵なので、実際の資産には使わない。トークンの交換レート`tokensPerEth` 2000 etherはデプロイのときに決めた固定の値で、相場ではない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシードを固定 |
| [code/src/UserOp.sol](code/src/UserOp.sol) | PackedUserOperation、IAccount、IPaymaster、PostOpMode、ValidationData |
| [code/src/EntryPoint219.sol](code/src/EntryPoint219.sol) | 講義用のEntryPointのまね（ペイマスターの分岐、預けたお金、postOpの呼び出し、AAのエラー） |
| [code/src/Account219.sol](code/src/Account219.sol) | 講義用のアカウント |
| [code/src/Paymaster220.sol](code/src/Paymaster220.sol) | SponsorPaymaster220（肩代わりする側の鍵が署名したUserOperationだけを受け付ける、getHashの材料を自分で集める、validUntil・validAfter）、TokenPaymaster220（検証で最大のコストをトークンで先に受け取り、postOpで返す） |
| [code/test/Base.sol](code/test/Base.sol) | MarketとStdTokenをデプロイするテストの土台 |
| [code/test/OpBase.sol](code/test/OpBase.sol) | UserOperationを作って署名するテストの補助 |
| [code/test/Paymaster220.t.sol](code/test/Paymaster220.t.sol) | Paymaster220Testの10個 |
| [code/script/Demo.s.sol](code/script/Demo.s.sol) | anvilのデモのスクリプト（`run220()`：肩代わり一つ、トークンでの支払い一つ） |
| [code/src/market/Market.sol](code/src/market/Market.sol) | 通しプロジェクトMarket（第53章の終わりのバージョン）のコピー |
| [code/src/market/IMarket.sol](code/src/market/IMarket.sol) | Marketのインターフェース |
| [code/src/market/MarketMath.sol](code/src/market/MarketMath.sol) | 利息・ポジションの計算のライブラリ |
| [code/src/market/MarketTypes.sol](code/src/market/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/src/market/StdToken.sol](code/src/market/StdToken.sol) | 承認を要求するテスト用の標準のトークン |

### 実行結果

`forge test --offline --match-contract Paymaster220Test -vv`：

```
Ran 10 tests for test/Paymaster220.t.sol:Paymaster220Test
[PASS] test_onlyEntryPointCallsPaymaster() (gas: 81567)
[PASS] test_paymasterDepositTooLowRejected() (gas: 190418)
[PASS] test_sponsorSigExpiredRejected() (gas: 138193)
[PASS] test_sponsorSigForOtherSenderRejected() (gas: 139035)
[PASS] test_sponsorSigNotReusable() (gas: 414187)
[PASS] test_sponsorSigWrongKeyRejected() (gas: 133102)
[PASS] test_sponsoredOpAccountPaysNothing() (gas: 345608)
Logs:
  sponsored cost 495188000000000

[PASS] test_tokenPaymasterChargesRevertedOp() (gas: 359211)
Logs:
  tokens paid on revert 617736000000000000

[PASS] test_tokenPaymasterPrechargeRefund() (gas: 474867)
Logs:
  prefund wei 2250000000000000
  max tokens 4500000000000000000
  actualGasCost wei 558326000000000
  tokens paid 1095296000000000000
  tokens for cost 1116652000000000000

[PASS] test_tokenPaymasterWithoutApprovalRejected() (gas: 159649)
Suite result: ok. 10 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_onlyEntryPointCallsPaymaster | ペイマスターの関数二つをEntryPoint以外のアドレスが呼ぶと`NotEntryPoint` |
| test_sponsoredOpAccountPaysNothing | アカウントのETH 0、預けたお金0で、Marketのpositions 100。コスト495,188,000,000,000 weiはペイマスターの預けたお金から出ていく |
| test_paymasterDepositTooLowRejected | ペイマスターの預けたお金1 gwei → `FailedOp(0, "AA31 paymaster deposit too low")`、ペイマスターのコードを呼ぶ前 |
| test_sponsorSigForOtherSenderRejected | ほかのアカウント宛てにもらった肩代わりの署名 → AA34 signature error |
| test_sponsorSigNotReusable | nonce 0に使ったpaymasterAndDataをnonce 1に付ける → AA34、positions 100のまま |
| test_sponsorSigExpiredRejected | 時刻1,000,000、validUntil 999,999 → AA32 paymaster expired or not due |
| test_sponsorSigWrongKeyRejected | 肩代わりする側ではない鍵で署名 → AA34 |
| test_tokenPaymasterPrechargeRefund | prefund 2,250,000,000,000,000 wei → 最大のトークン4.5e18を先に受け取り、実際のコスト558,326,000,000,000 weiに合わせて、払ったトークン1,095,296,000,000,000,000だけを残す |
| test_tokenPaymasterChargesRevertedOp | 実行がリバートしても、トークン617,736,000,000,000,000を払う |
| test_tokenPaymasterWithoutApprovalRejected | ペイマスターへのトークンの承認なし → `transferFrom`がリバート、`FailedOp(0, "AA33 reverted")` |

anvilで`run220()`により、一つのアカウントが出したUserOperation二つ（一つ目は肩代わりのペイマスター、二つ目はトークンのペイマスター）：

```
EntryPoint219 0x5FbDB2315678afecb367f032d93F642f64180aa3
Account219 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
Market 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
StdToken 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
owner 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7
SponsorPaymaster220 0x0165878A594ca255338adfa4d48449f69242Eb8F
TokenPaymaster220 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6

positions deposited 300
getNonce key0 2
account ETH 0
account EP deposit 0
account token 99589557272468781700
sponsorPm EP deposit 999651868927353694
tokenPm EP deposit 999788146169566042
tokenPm token 410442727531218000
owner ETH 0, owner nonce 0
bundler ETH before 10000000000000000000000 after 10000000446967128255568
block 11 ... paymaster 0x0165878a594ca255338adfa4d48449f69242eb8f nonce 0 success 1 actualGasCost 348131072646306 actualGasUsed 272793
block 12 ... paymaster 0x2279b7a0a67db372996a5fab50d91eaa73d2ebe6 nonce 1 success 1 actualGasCost 211853830433958 actualGasUsed 170538
```

二つのhandleOpsのトランザクションのレシートは、gasUsed 267,736 / 161,294、effectiveGasPrice 276,173,043 / 242,267,592である。アカウントのETHと預けたお金は最後まで0で、持ち主の鍵は署名しかしていない。

### 試すときの注意

- ペイマスターの付いたUserOperationなら、EntryPointはペイマスターの預けたお金を見て、アカウントの`validateUserOp`の`missingAccountFunds`は0である。`validatePaymasterUserOp`が返したcontextが空でなければ、実行のあとに`postOp`を呼ぶ。
- ガスは、ペイマスターがEntryPointに前もって預けておいたお金から出ていく。預けたお金が最大のコストより少なければ、検証で止められる（AA31）。
- paymasterAndDataはuserOpHashの材料なので、その中に入った肩代わりの署名が自分自身を縛ることはできない。だからSponsorPaymaster220は、sender、nonce、callDataのハッシュ、ガスの欄三つ、チェーンの番号、ペイマスターのアドレス、validUntil、validAfterを自分で集めてハッシュする。
- トークンで払った量（1,095,296,000,000,000,000）がコストの換算（1,116,652,000,000,000,000）より少ないのは、postOp自身のガスが、EntryPointが渡すコストにまだ入っていないからである。公開の例のTokenPaymaster（v0.7.0）は、この分を`refundPostopCost`で別に足す。
- AAのエラーの先頭：AA2xはアカウントの検証（AA21 預けたお金の不足、AA24 署名、AA25 ナンス）、AA3xはペイマスターの検証（AA31 預けたお金の不足、AA32 期限、AA33 リバート、AA34 署名）、AA50はpostOpのリバート、AA91はbeneficiaryへの送金の失敗である。AA20・AA22・AA23はまねのコードにだけあり、この講義のテストには出てこない。
- 実行がリバートしても（opReverted）、ペイマスターはガスを払う。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。標準のドキュメント、公開の例、サービスのリスト、ツールのバージョンが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| ERC-4337の原文のバージョン | status Final、created 2021-09-29、requires 712・7702、ファイルの最後のコミットc8d8c210（2026-06-02、"Update ERC-4337: Move to Final"） | 2026-10-21 |
| paymasterSignature | v0.9.0のリリース（2025-11-16）"Enable parallelizable Paymaster signing with `paymasterSignature` field"。その前はpaymasterAndData全体がuserOpHashに入っていた。PAYMASTER_SIG_MAGIC 0x22e325a297439656 | 2026-10-21 |
| トークンのペイマスターのpostOpの分 | 例のTokenPaymasterの`refundPostopCost`を、検証のときはmaxFeePerGas、postOpのときはactualUserOpFeePerGasで掛けて足す | 2026-10-21 |
| トークンのペイマスターの価格の扱い | 例のTokenPaymasterは検証の段階で価格を読めないので（"storage access restrictions of ERC-4337"）、価格を保存しておいてpostOpで直す（コメント：変わった幅が10%を超えるとき）、validUntil = cachedPriceTimestamp + priceMaxAge | 2026-10-21 |
| ペイマスターのサービスのリスト | Alchemy、Candide、Circle（USDC Paymaster）、Etherspot、Openfort、Pimlico、ZeroDev、Visa（実験） | 2026-10-21 |
| Foundry・solc | forge・cast・anvil 1.8.3、solc 0.8.30、optimizer runs 200、via-IR、evm osaka | 2026-10-21 |
| コントラクトのサイズ（runtime / initcodeのバイト） | SponsorPaymaster220 1,523 / 1,716、TokenPaymaster220 1,583 / 1,807、EntryPoint219 5,222 / 5,248、Account219 1,443 / 1,637 | 2026-10-21 |
| テストのガス・値（Paymaster220Test） | sponsored cost 495,188,000,000,000 wei / prefund 2,250,000,000,000,000 wei、最大のトークン4.5e18、actualGasCost 558,326,000,000,000 wei、払ったトークン1,095,296,000,000,000,000、コストの換算1,116,652,000,000,000,000 / リバートのときのトークン617,736,000,000,000,000 | 2026-10-21 |
| anvilの値 | UserOperation二つのactualGasCost 348,131,072,646,306 / 211,853,830,433,958、actualGasUsed 272,793 / 170,538、トランザクションのgasUsed 267,736 / 161,294、effectiveGasPrice 276,173,043 / 242,267,592、バンドラー +446,967,128,255,568 wei | 2026-10-21 |
| デモの値 | tokensPerEth 2000 ether（デモ用の固定の値）、肩代わりの鍵0x5B0・持ち主の鍵0xA11CEはデモ用の公開された鍵（実際のお金には使わない） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| トークンの交換レートを価格フィードで受け取る | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)（価格フィードの読み方）、付録（公開の例のTokenPaymaster） |
| ペイマスターのステーク・評判・ストレージへのアクセスの規則 | 付録（ERC-4337の原文） |
| paymasterSignatureで肩代わりの署名を別に受け取る | 付録（時効性のあるデータ、v0.9） |
| 期限と権限を縛るセッションキー | [第222講](../../part15/lecture222/) |
| ウォレットの設計で、ガスを誰が払うかを決める | [第223講](../../part15/lecture223/) |
| バンドラー・ペイマスターのサービスの選び方 | 付録（時効性のあるデータ） |

出典と参考資料は[reference.md](reference.md)にまとめた。
