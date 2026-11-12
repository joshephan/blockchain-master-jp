# 第178講 鍵の管理とマルチシグ

第11部 推奨事項：敵対的環境とバージョン履歴・第46章 軸4・権限と鍵

[← 第177講](../../part11/lecture177/) | [第11部 目次](../) | [第179講 →](../../part11/lecture179/)

## この講義の問い

管理者の鍵を失ったり奪われたりすると、その鍵で何ができるのか。その被害を減らすには、コードで何を先に直すのか。鍵を複数に分けると、何が止まり何が残るのか。

## 実習資料

### 準備

二つのプロジェクトを使う。`guards`はマルチシグのトイを入れたFoundryプロジェクトで、forge-stdとOpenZeppelin Contracts 5.4.0が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。`market`は通しプロジェクトMarketのこの講義のバージョンである。このバージョンでsrcを直した（withdrawから`notFrozen`を外した、`IMarket.sol`の状態の説明コメント）。テスト用のマルチシグ`test/MultiSigAdmin.sol`とテスト`test/Keys.t.sol`を足し、Frozenが出金を止めるとみなしていたテスト三つ（ErrorList・StatusTable・Status）を直した。forge-stdが必要である。anvilなしに、forgeの中だけで動く。

鍵を奪う流れは図と説明だけで扱い、その流れを再現するコードは載せない。マルチシグは講義用の最小の形である。実際のデプロイには監査を受けたマルチシグを使う。

### コード

| ファイル | 内容 |
|---|---|
| [code/guards/foundry.toml](code/guards/foundry.toml) | solc 0.8.30、optimizer・via-IRオン、OpenZeppelinのremapping |
| [code/guards/src/MultiSigAdmin.sol](code/guards/src/MultiSigAdmin.sol) | 複数の署名者としきい値、propose・approve・execute、なくした鍵を差し替えるreplaceOwner（自分自身だけが呼ぶ） |
| [code/guards/src/Access176.sol](code/guards/src/Access176.sol) | テスト対象のOwnedVault（管理者の席にマルチシグのアドレスを入れる） |
| [code/guards/test/MultiSig178.t.sol](code/guards/test/MultiSig178.t.sol) | MultiSig178Testの九つ：しきい値に届かない、二つの承認で実行、再実行、同じ署名者が二回、他人の承認、署名者の直接呼び出し、鍵の差し替え |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 直したバージョン。withdrawに`notFrozen`がないので、どの状態でも出金できる |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | 市場の状態の説明コメントを直したインターフェース |
| [code/market/test/MultiSigAdmin.sol](code/market/test/MultiSigAdmin.sol) | テストでMarketの管理者の席に入れるマルチシグ（guardsのものとは冒頭のコメント一行だけが違う） |
| [code/market/test/Keys.t.sol](code/market/test/Keys.t.sol) | KeysTestの六つ：管理者 = マルチシグ、署名者一人ではNotAdmin、鍵一つでは凍結できない、凍結しても出金できる、鍵をなくした市場でも出金できる |
| [code/market/test/](code/market/test/) | 直したテスト三つ（`ErrorList.t.sol`、`StatusTable.t.sol`、`Status.t.sol`）と、このバージョンまでに積み重なった残りのテスト |

### 実行結果

withdrawの宣言の行の前後（`src/Market.sol`）：

```solidity
// 直す前（180行）
    function withdraw(address asset, uint256 amount) public notFrozen {

// 直したバージョン（183〜184行）
    // 第178講: notFrozenを外す。管理者の鍵を失くしたり奪われたりしても、預けた人は自分の分を引き出せる
    function withdraw(address asset, uint256 amount) public {
```

直したバージョンで`bash ci.sh`（サイズ表のほかの行、デバッグ用ビルドのテストの行、ドキュメント生成の行は省略）。ランタイムは3,260 → 2,990バイト、生成コードは3,473 → 3,203バイトに減った。

```
| Contract      | Runtime Size (B) | Initcode Size (B) | Runtime Margin (B) | Initcode Margin (B) |
| Market        | 2,990            | 3,203             | 21,586             | 45,949              |
Ran 39 test suites in 33.17ms (38.49ms CPU time): 110 tests passed, 0 failed, 0 skipped (110 total tests)
ci ok
```

`guards`で`forge test --offline --match-contract MultiSig178Test -vvv`。署名者はa、b、c、しきい値は2である。

```
Ran 9 tests for test/MultiSig178.t.sol:MultiSig178Test
[PASS] test_badThresholdRejected() (gas: 9433)
[PASS] test_directReplaceRejected() (gas: 38772)
[PASS] test_executeOnce() (gas: 349002)
[PASS] test_oneApprovalNotEnough() (gas: 219132)
[PASS] test_ownerAloneNotAdmin() (gas: 32563)
[PASS] test_replaceLostKey() (gas: 422357)
[PASS] test_sameOwnerTwiceRejected() (gas: 211499)
[PASS] test_strangerCannotApprove() (gas: 137310)
[PASS] test_twoApprovalsExecute() (gas: 323721)
Suite result: ok. 9 passed; 0 failed; 0 skipped; finished in 1.87ms (7.15ms CPU time)
```

| テスト | やること | 結果 |
|---|---|---|
| test_oneApprovalNotEnough | aが一人で承認して実行 | BelowThreshold(0, 1)、paused false |
| test_twoApprovalsExecute | a、bが承認し、cが実行 | paused true |
| test_executeOnce | 実行した提案をもう一度実行 | AlreadyExecuted(0) |
| test_sameOwnerTwiceRejected | aが同じ提案に二回承認 | AlreadyApproved(0, a) |
| test_strangerCannotApprove | 署名者でないstrangerが承認 | NotOwner(stranger) |
| test_ownerAloneNotAdmin | 署名者aがvault.pauseを直接呼ぶ | NotOwner(a) |
| test_directReplaceRejected | 署名者aがreplaceOwnerを直接呼ぶ | NotSelf(a) |
| test_replaceLostKey | 提案・承認二つ・実行でcをdに | isOwner(c) false、isOwner(d) true、署名者の数3 |
| test_badThresholdRejected | 署名者二人にしきい値三でデプロイ | BadThreshold(3, 2) |

`market`で`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract "KeysTest|StatusTableTest|StatusTest|ErrorListTest" -vvv`（KeysTest以外は省略）：

```
Ran 6 tests for test/Keys.t.sol:KeysTest
[PASS] test_adminIsMultisig() (gas: 21922)
[PASS] test_frozenStillWithdraws() (gas: 428326)
[PASS] test_lostKeyFrozenStillWithdraws() (gas: 433327)
[PASS] test_multisigFreezes() (gas: 355083)
[PASS] test_oneKeyCannotFreeze() (gas: 246223)
[PASS] test_signerAloneNotAdmin() (gas: 33118)
Suite result: ok. 6 passed; 0 failed; 0 skipped; finished in 2.01ms (1.98ms CPU time)
...
Ran 4 test suites in 5.13ms (8.62ms CPU time): 27 tests passed, 0 failed, 0 skipped (27 total tests)
```

攻撃の問い三つと、直したバージョンの答え：

| 攻撃の問い | 直したバージョンの答え | 確認するテスト |
|---|---|---|
| 管理者の鍵を奪われたら？ | 鍵一つではBelowThreshold、署名者一人が直接呼べばNotAdmin。しきい値を越えても出金は止められない | test_oneKeyCannotFreeze、test_signerAloneNotAdmin、test_frozenStillWithdraws |
| 管理者がFrozenをかけて鍵をなくしたら？ | 解除する人はいなくてもwithdraw 50は成功、depositはNotActive(2) | test_lostKeyFrozenStillWithdraws |
| 管理者の席にコントラクトのアドレスを入れたら？ | Marketはmsg.sender == adminだけを見る。マルチシグのexecuteが呼んだ呼び出しを管理者の呼び出しとして受け付ける | test_adminIsMultisig、test_multisigFreezes |

直したバージョンの状態表のFrozenの行：

| 関数 | 直す前 | 直したバージョン |
|---|---|---|
| addAsset | MarketFrozen | MarketFrozen |
| deposit | NotActive(2) | NotActive(2) |
| withdraw | MarketFrozen | 成功 |
| withdrawAll | MarketFrozen | 成功 |
| setStatus | 管理者だけ | 管理者だけ |

### 試すときの注意

- 鍵をなくした日の被害は、権限一覧の管理者の欄が決める。Marketにはアップグレードの鍵がないので管理者の欄はaddAsset・setStatusの二つで、直したバージョンではその二つでも出金を止められない。
- マルチシグが呼んだ呼び出しでMarketが見るmsg.senderは、マルチシグのアドレスである。署名者一人がMarketを直接呼べばNotAdminである。
- 署名者を差し替えることもしきい値を越えなければならない。そうしないと、鍵一つで署名者を増やして一人でしきい値を越えられる。
- 署名者の鍵が一つの機器に集まっていれば、鍵一つと同じである。署名者の鍵は、互いに違う人が互いに違う装置に置く。この前提はコードでは防げない。
- トイで省いたもの：差し替えられた署名者が以前にした承認もそのまま数え、署名者の数を増減する関数がなく、しきい値は固定である。
- 貼り付けた管理者のアドレスは、前後の数文字だけを見ずに最初から最後まで照合し、デプロイのあとにチェーンでadminを読んで、入れようとしたアドレスかを確かめる。
- withdraw 30のガスが57,448 → 55,289に減ったのは、statusの欄の読み取りが一つ抜けたからである。`snapshots/Market.json`を使うガスの記録のテストがこの値を照合する。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| solc | 0.8.30。guards・marketともにoptimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| Marketのサイズ | ランタイム3,260 → 2,990バイト、生成コード3,473 → 3,203バイト（上限24,576） | 2026-10-21 |
| Marketの呼び出しのガス（snapshots/Market.json） | addAsset75 92,656 → 92,632、deposit100 127,515 → 127,516、withdraw30 57,448 → 55,289、failDeposit0 26,264・setStatus0 23,089・setStatus1 45,001はそのまま | 2026-10-21 |
| テストのガス（guards） | badThresholdRejected 9,433 / directReplaceRejected 38,772 / executeOnce 349,002 / oneApprovalNotEnough 219,132 / ownerAloneNotAdmin 32,563 / replaceLostKey 422,357 / sameOwnerTwiceRejected 211,499 / strangerCannotApprove 137,310 / twoApprovalsExecute 323,721 | 2026-10-21 |
| テストのガス（KeysTest） | adminIsMultisig 21,922 / frozenStillWithdraws 428,326 / lostKeyFrozenStillWithdraws 433,327 / multisigFreezes 355,083 / oneKeyCannotFreeze 246,223 / signerAloneNotAdmin 33,118 | 2026-10-21 |
| 実務のマルチシグ・署名の機器 | 製品名・現状は載せない。選ぶときは監査の履歴と署名者の差し替えの手順を確認 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 時間の遅延のあとに実行する管理の形 | [第180講](../../part11/lecture180/) |
| 票で決める管理（ガバナンス）とその乗っ取り | [第180講](../../part11/lecture180/) |
| 実務のマルチシグを選んで運用すること（署名者の機器、差し替えの手順） | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |
| マルチシグのトイの単純化（差し替えられた署名者の過去の承認も数える、署名者の数は固定） | 付録（この表） |
| アップグレードの鍵を複数・時間の遅延で束ねること | [第256講](../../part20/lecture256/) |
| 別のチェーンのことを署名者のしきい値で信じる仕組み | [第179講](../../part11/lecture179/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
