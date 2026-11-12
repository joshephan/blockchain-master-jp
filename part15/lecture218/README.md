# 第218講 EOAの限界とAAの動機

第15部 アカウント抽象化・第59章 アカウント抽象化の構造

[← 第217講](../../part14/lecture217/) | [第15部 目次](../) | [第219講 →](../../part15/lecture219/)

## この講義の問い

EOAは何をプロトコルに縛りつけていて、その縛りのせいで何ができないのか。要求を受け入れるかどうかをコードに決めさせると、何がほどけ、何が自分の責任に移ってくるのか。

## 実習資料

### 準備

第59〜60章の共用のアカウント抽象化のプロジェクト`aa`から始める。この講義では、そのうち講義用のコントラクトアカウント`Wallet218.sol`とそのテストを使う。テストの土台（`test/Base.sol`）が、通しプロジェクトMarket（第53章の終わりのバージョン）のsrcのコピーと、承認を要求する標準のトークン`StdToken`を`src/market/`に置いてデプロイするので、そのファイルも一緒に入れた。依存はforge-std（`lib/forge-std`）一つである。

anvilでも同じ流れをcastで回す：ETHが0の持ち主のEOA（デモ用の鍵`0xA11CE`）は直接取引を送れず、持ち主はdigestに`cast wallet sign --no-hash`で署名だけをし、anvilのアカウント1番が`execute`を送る。`0xA11CE`は誰でも知っているデモ用の鍵なので、実際の資産には使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシードを固定 |
| [code/src/Wallet218.sol](code/src/Wallet218.sol) | LooseWallet218（材料は`abi.encode(target, value, data)`）、Wallet218（材料にチェーンの番号・アカウントのアドレス・使用番号、`execute`・`executeBatch`、エラーBadSigner・BadNonce・CallFailed） |
| [code/test/Base.sol](code/test/Base.sol) | MarketとStdTokenをデプロイするテストの土台 |
| [code/test/Wallet218.t.sol](code/test/Wallet218.t.sol) | Wallet218Testの7個 |
| [code/src/market/Market.sol](code/src/market/Market.sol) | 通しプロジェクトMarket（第53章の終わりのバージョン）のコピー |
| [code/src/market/IMarket.sol](code/src/market/IMarket.sol) | Marketのインターフェース |
| [code/src/market/MarketMath.sol](code/src/market/MarketMath.sol) | 利息・ポジションの計算のライブラリ |
| [code/src/market/MarketTypes.sol](code/src/market/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/src/market/StdToken.sol](code/src/market/StdToken.sol) | 承認（approve）を要求するテスト用の標準のトークン |

### 実行結果

`forge test --offline --match-contract Wallet218Test -vv`：

```
Ran 7 tests for test/Wallet218.t.sol:Wallet218Test
[PASS] test_batchApproveDeposit() (gas: 211902)
[PASS] test_garbageSigRejected() (gas: 41961)
[PASS] test_looseSameSigPassesTwice() (gas: 124181)
[PASS] test_otherChainSigRejected() (gas: 57855)
[PASS] test_otherWalletSigRejected() (gas: 112025)
[PASS] test_relayerPaysOwnerSigns() (gas: 127982)
[PASS] test_sameSigRejected() (gas: 174731)
Suite result: ok. 7 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_relayerPaysOwnerSigns | bob 100、持ち主のETH 0、nonce 1 |
| test_batchApproveDeposit | 承認とMarketへの預け入れを署名一つで。Marketのpositionsのウォレット100、ウォレットのトークン400 |
| test_looseSameSigPassesTwice | LooseWallet218で同じ署名が2回通り、bob 200 |
| test_sameSigRejected | 2回目は`BadNonce(1, 0)`、番号だけを1に上げると`BadSigner`、bob 100 |
| test_otherChainSigRejected | チェーンの番号1で作った署名 → `BadSigner` |
| test_otherWalletSigRejected | 同じ持ち主の二つ目のウォレット → `BadSigner` |
| test_garbageSigRejected | v 29・r 0・s 0 → `BadSigner` |

anvilでETH 0の持ち主のEOAが直接送ろうとしたとき（ガスリミットを書かなかった場合、書いた場合）：

```
Error: Failed to estimate gas: server returned an error response: error code -32003: Out of gas: gas required exceeds allowance: 0
Error: server returned an error response: error code -32003: Insufficient funds for gas * price + value
```

持ち主が署名し、アカウント1番が`execute`を送った結果：

```
wallet 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
digest 0x6327acfc96868145488eee37bd36b259f2546ad32e6788de3f51e4e754c3d3d1
-- アカウント1番がexecuteを送る
from                 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
gasUsed              82752
status               1 (success)
bob token 100
wallet token 400
owner ETH 0, owner nonce 0
wallet nonce() 1
-- 同じ署名をもう一度
... execution reverted: custom error 0x3ddd5131: ... BadNonce(1, 0)
```

`cast code`で読んだコードの長さは、持ち主のEOAが`0x`（コードなし）、ウォレットが1,738バイトである。

### 試すときの注意

- 持ち主はチェーンに何も送らない。持ち主のEOAのETHとナンスは最後まで0で、変わるのはウォレットの`nonce()`である。
- Marketは、呼んだ側がEOAかどうかを問わず`msg.sender`の名義で記録する。だからウォレットが預けたお金はウォレットの名義で記録される。
- 署名の材料にチェーンの番号、このアカウントのアドレス、使用番号を入れないと、同じ署名をもう一度出したり、ほかのチェーン・同じ持ち主のほかのウォレットに出したりできる。
- `ecrecover`は復元に失敗してもリバートせず、`address(0)`を返す。`signer == address(0)`の確認がないと、持ち主の欄が空のアカウントででたらめな署名が通る。
- Wallet218は誰でも`execute`を送れるので、送る側はガスを先に払い、署名が間違っていればそのガスを失う。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。標準のドキュメントとツールのバージョンが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| ERC-4337の原文 | status Final、created 2021-09-29、requires 712・7702、ファイルの最後のコミットc8d8c210（2026-06-02、"Update ERC-4337: Move to Final"） | 2026-10-21 |
| Foundry | forge・cast・anvil 1.8.3 | 2026-10-21 |
| solc・設定 | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| コントラクトのサイズ（ランタイム/initcodeのバイト） | LooseWallet218 670/803、Wallet218 1,738/1,879 | 2026-10-21 |
| anvilのexecuteのgasUsed | execute（bobに100） 82,752 | 2026-10-21 |
| テストのガス（Wallet218Test） | batchApproveDeposit 211,902 / garbageSigRejected 41,961 / looseSameSigPassesTwice 124,181 / otherChainSigRejected 57,855 / otherWalletSigRejected 112,025 / relayerPaysOwnerSigns 127,982 / sameSigRejected 174,731 | 2026-10-21 |
| デモのアドレス・鍵 | 持ち主の鍵0xA11CE（デモ用の公開された鍵、実際のお金には使わない） → 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7、StdToken 0x5FbDB2315678afecb367f032d93F642f64180aa3、Wallet218 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0、アカウント1番0x70997970C51812dc3A010C7d01b50e0d17dc79C8、チェーンの番号31337 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 代わりに送る側がどうやってお金を受け取るか、バンドルとEntryPoint | [第219講](../../part15/lecture219/) |
| 署名メッセージの標準（EIP-712）の構造 | [第219講](../../part15/lecture219/) |
| ほかのアカウントがガスを肩代わりすること | [第220講](../../part15/lecture220/) |
| EOAにコードを付ける委任 | [第221講](../../part15/lecture221/) |
| 鍵ができることを減らすセッションキー | [第222講](../../part15/lecture222/) |
| 鍵をなくしたときに替える規則 | [第223講](../../part15/lecture223/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
