# 第221講 EIP-7702とEOAの委任

第15部 アカウント抽象化・第60章 アカウント抽象化の実践

[← 第220講](../../part15/lecture220/) | [第15部 目次](../) | [第222講 →](../../part15/lecture222/)

## この講義の問い

すでに使っていたEOAのアドレスをそのままにしてコードを付けると、そのコードはどこで、何を持って動くのか。委任を許す署名は何を縛り、何を縛らないのか。委任したあとも残るものは何か。

## 実習資料

### 準備

第59〜60章の共用のアカウント抽象化のプロジェクト`aa`から始める。この講義では、EOAが委任する講義用のコード`Delegate221.sol`とそのテストを使い、委任したEOAを第219講のEntryPointのまね（`EntryPoint219.sol`、`UserOp.sol`）に入れてみる。テストの土台（`test/Base.sol`）が、通しプロジェクトMarket（第53章の終わりのバージョン）のsrcのコピーと標準のトークン`StdToken`を`src/market/`に置いてデプロイする。依存はforge-std（`lib/forge-std`）一つである。テストはforgeの`vm.signAndAttachDelegation`を使うが、forgeの中ではEOAのナンスが上がらないので、ナンスの値はanvilの出力で見る。

anvilは`--hardfork osaka`で立ち上げ、castだけで12の段階を回す：alice（デモ用の鍵`0xA11CE`、実際の資産には使わない）が`cast wallet sign-auth`で委任の許可に署名し、アカウント1番が`cast send --auth`でtype 4の取引を送る。aliceはETHが0で、署名だけをする。`Delegate221`は講義用の委任のコードなので、実際の資産が入ったEOAを委任しない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシードを固定 |
| [code/src/Delegate221.sol](code/src/Delegate221.sol) | 講義用の7702の委任のコード：SELF・entryPointのimmutable、label 221、nonce、execute（自分だけ）、executeSigned（署名者 = コードが動くアドレス）、digestOf、validateUserOp、エラーNotSelf・BadSigner・NotEntryPoint・CallFailed |
| [code/src/EntryPoint219.sol](code/src/EntryPoint219.sol) | 第219講のEntryPointのまねのまま |
| [code/src/UserOp.sol](code/src/UserOp.sol) | PackedUserOperation、IAccount、ValidationData |
| [code/test/Base.sol](code/test/Base.sol) | MarketとStdTokenをデプロイするテストの土台 |
| [code/test/Delegate221.t.sol](code/test/Delegate221.t.sol) | Delegate221Testの9個 |
| [code/src/market/Market.sol](code/src/market/Market.sol) | 通しプロジェクトMarket（第53章の終わりのバージョン）のコピー |
| [code/src/market/IMarket.sol](code/src/market/IMarket.sol) | Marketのインターフェース |
| [code/src/market/MarketMath.sol](code/src/market/MarketMath.sol) | 利息・ポジションの計算のライブラリ |
| [code/src/market/MarketTypes.sol](code/src/market/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/src/market/StdToken.sol](code/src/market/StdToken.sol) | 承認を要求するテスト用の標準のトークン |

### 実行結果

`forge test --offline --match-contract Delegate221Test -vv`：

```
Ran 9 tests for test/Delegate221.t.sol:Delegate221Test
[PASS] test_constructorStorageNotAtEOA() (gas: 55033)
[PASS] test_delegatedEoaInEntryPoint() (gas: 334404)
[PASS] test_delegationIndicator() (gas: 44567)
Logs:
  0xef01005991a2df15a8f6a256d3ec51e99254cd3fb576a9
[PASS] test_otherChainSigRejected() (gas: 81533)
[PASS] test_sameSigRejected() (gas: 270742)
[PASS] test_sigForOtherDelegateRejected() (gas: 83620)
[PASS] test_sponsorRunsSignedBatch() (gas: 227491)
[PASS] test_storageStaysAfterRedelegation() (gas: 301450)
[PASS] test_strangerExecuteRejected() (gas: 75514)
Suite result: ok. 9 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_delegationIndicator | code = `0xef0100` + D1のアドレス、23バイト |
| test_sponsorRunsSignedBatch | 署名つきの実行1回で、positions alice 100、aliceのトークン400・ETH 0、nonce 1 |
| test_constructorStorageNotAtEOA | D1のlabel 221、aliceで読むと0、SELFはD1 |
| test_strangerExecuteRejected | 他人がexecute → `NotSelf`、トークン500のまま |
| test_sameSigRejected | 同じ署名の2回目 → `BadSigner`、positions 100 |
| test_otherChainSigRejected | チェーンの番号1の材料で作った署名 → `BadSigner` |
| test_sigForOtherDelegateRejected | D2に委任したEOAにD1の材料の署名 → `BadSigner` |
| test_storageStaysAfterRedelegation | D1でnonce 1 → D2に変えても1 → アドレス0で消してもスロット1 = 1、codeの長さ0 |
| test_delegatedEoaInEntryPoint | 委任したaliceが、まねのEntryPointのsender。positions alice 100、getNonce(alice, 0) 1、委任のコードのnonce() 0 |

anvilでaliceが委任の許可に署名し（`cast wallet sign-auth`、チェーン31337・アドレスD1・ナンス0）、`cast from-rlp`でデコードした6欄：

```
["0x7a69","0xdc64a140aa3e981100a9beca4e685f962f0cf6c9","0x","0x","0x1fbb38...ae02e","0x065428...beef0"]
```

アカウント1番が送ったtype 4の取引（委任の表示の書き込み + executeSignedで承認100・預け入れ100）と、そのあとの状態：

```
gasUsed              191198
status               1 (success)
type                 4
to                   0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7
  alice code: 0xef0100dc64a140aa3e981100a9beca4e685f962f0cf6c9
  alice nonce 1, ETH 0, token 400
  codesize 23
  Market positions(alice): 100
  storage alice slot0 0x00...00 slot1 0x00...01
  label(): via alice 0, D1 221
  SELF() via alice 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  nonce() via alice 1
```

残りの段階の結果：

| 段階 | 結果 |
|---|---|
| 3. 同じ署名をもう一度 | `BadSigner` |
| 4. 他人（アカウント2番）がexecute | `NotSelf` |
| 5. 許可のリストなしの次の取引（預け入れ50） | type 2、gasUsed 93,198、positions 150、nonce() 2。委任は残っている |
| 6. D2への許可 + 間違った署名 | type 4、status 0（実行の失敗）、gasUsed 47,096。それでもcodeはD2に変わり、aliceのナンス2 |
| 7. チェーンの番号1で署名した許可 | status 1、gasUsed 46,062、委任はそのまま |
| 8. 間違ったナンスで署名した許可 | status 1、gasUsed 46,062、委任はそのまま |
| 9. チェーンの番号0で署名した許可 | 受け付けられる、gasUsed 36,850、code D1、ナンス3 |
| 10. アドレス0への許可 | code `0x`、ナンス4、gasUsed 36,800。ストレージのスロット1 = 2は残る |
| 11. 委任のないEOAに値0の普通の取引 | gasUsed 21,000 |

`cast`が出す確認の文言（`--force`なしで実行）：

```
Warning: Chain ID 0 creates an EIP-7702 authorization that is valid on every chain.

Warning: This command will send a signed EIP-7702 authorization to the RPC endpoint. The authorization can be submitted on-chain by anyone once its nonce is valid.
```

### 試すときの注意

- 委任の許可の署名の材料は、チェーンの番号、コードのアドレス、ナンスの三つである。間違った許可は取引を失敗させず、飛ばされる（段階7・8）。それでも許可一つの値25,000ガスは送った側が払う。すでにあるアカウントなら、使ったガスの5分の1まで返ってくる（段階9・10 46,062 → 36,850）。
- チェーンの番号0で署名した許可は、すべてのチェーンで通る。EOAのアドレスはすべてのチェーンで同じなので、そのコードのアドレスにチェーンごとにどんなコードがあるかまで確かめなければならない。
- 委任すると、コードは委任先から来て、ストレージはEOAのアドレスのものである。コンストラクタは動かないので、コンストラクタが書いた値（label）はEOAでは0で、immutable（SELF）はコードに埋め込まれて一緒に来る。
- 委任を変えたり消したりしても、ストレージは残る。新しい委任のコードが、古い委任のコードのスロットを別の意味で読むことがありうる。
- 委任しても、EOAの鍵はそのまま生きている。その鍵で署名すれば、委任をいつでも変えたり消したりできる。
- 実行がリバートしても（段階6）、許可のリストはすでに処理されていて、委任は変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。標準のドキュメントとツールのバージョンが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| EIP-7702の原文 | title "Set Code for EOAs"、status Final、created 2024-05-07、ファイルの最後のコミットbbc3f958（2025-10-07、"Correct link formatting"）、Finalに変わったコミットe17d216b（2025-06-03） | 2026-10-21 |
| Pectraのメインネットでの有効化 | epoch 364032、timestamp 1746612311（2025-05-07 UTC）、requiresに7702 | 2026-10-21 |
| ERC-4337の原文 | コミットc8d8c210 | 2026-10-21 |
| Foundry | forge・cast・anvil 1.8.3、anvil `--hardfork osaka` | 2026-10-21 |
| solc・設定 | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| コントラクトのサイズ（ランタイム/initcodeのバイト） | Delegate221 1,966/2,134、EntryPoint219 5,222/5,248 | 2026-10-21 |
| anvilのgasUsed | 段階2 type 4（許可 + 承認・預け入れ） 191,198 / 段階5 type 2（預け入れ50） 93,198 / 段階6 失敗47,096 / 段階7・8 間違った許可46,062 / 段階9 チェーンの番号0の許可36,850 / 段階10 消去36,800 / 段階11 普通の取引21,000。許可一つ25,000（空のアカウント）、すでにあるアカウントは返ってくる分（使ったガスの5分の1まで） | 2026-10-21 |
| テストのガス（Delegate221Test） | constructorStorageNotAtEOA 55,033 / delegatedEoaInEntryPoint 334,404 / delegationIndicator 44,567 / otherChainSigRejected 81,533 / sameSigRejected 270,742 / sigForOtherDelegateRejected 83,620 / sponsorRunsSignedBatch 227,491 / storageStaysAfterRedelegation 301,450 / strangerExecuteRejected 75,514 | 2026-10-21 |
| デモのアドレス・鍵 | aliceの鍵0xA11CE（デモ用の公開された鍵、実際のお金には使わない） → 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7、StdToken 0x5FbDB2315678afecb367f032d93F642f64180aa3、Market 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512、EntryPoint219 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9、D1 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9、D2 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707、アカウント1番0x70997970C51812dc3A010C7d01b50e0d17dc79C8、チェーンの番号31337 | 2026-10-21 |
| castの確認の文言 | "Warning: Chain ID 0 creates an EIP-7702 authorization that is valid on every chain." / "Warning: This command will send a signed EIP-7702 authorization to the RPC endpoint. The authorization can be submitted on-chain by anyone once its nonce is valid." | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 鍵ができることを減らす下位の鍵（原文のPrivilege de-escalation） | [第222講](../../part15/lecture222/) |
| 委任したEOAの鍵をなくしたとき | [第223講](../../part15/lecture223/) |
| 委任のコードのストレージをERC-7201の形で置く方法と`layout at` | 付録 |
| 送る側が同じEOAの取引を複数メンプールで扱う方法（原文573〜602行目） | [第225講](../../part16/lecture225/) |
| 代わりに送る側がお金を受け取れない場合（原文564〜571行目） | 付録 |
| 委任の連鎖・プリコンパイルへの委任（原文161〜172行目） | 付録 |
| 7702のアカウントをUserOperationで最初に初期化する（ERC-4337 540〜546行目） | 付録（時効性のあるデータ） |

出典と参考資料は[reference.md](reference.md)にまとめた。
