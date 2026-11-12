# 第171講 標準違反のトークンとコンポーザビリティのリスク

第11部 推奨事項：敵対的環境とバージョン履歴・第44章 軸1・制御の移転

[← 第170講](../../part11/lecture170/) | [第11部 目次](../) | [第172講 →](../../part11/lecture172/)

## この講義の問い

「ERC-20」と書かれたトークンは本当に標準どおりに動くのか。標準をゆるく破るトークンが自分の帳簿をどうずらすのか。SafeERC20は何を手で覆い隠してくれるのか。

## 実習資料

### 準備

プロジェクトは二つある。`vulns`は標準と違う動きをするトークンと、そのトークンを呼ぶ側を見る小さなトイプロジェクトで、`market`は通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）のsrcをそのまま置き、確認用テスト`test/BadTokens44.t.sol`を足したものである。どちらもforge-stdが必要である（`lib/forge-std`）。OpenZeppelin Contracts 5.4.0のSafeERC20は原文を読むだけで、プロジェクトには入れなかった。anvilと外部への接続はない。

### コード

| ファイル | 内容 |
|---|---|
| [code/vulns/foundry.toml](code/vulns/foundry.toml) | solc 0.8.30、optimizerオン（200）・via-IRオン・evm osaka、fuzz runs 256・seed 0x2a |
| [code/vulns/src/Tokens171.sol](code/vulns/src/Tokens171.sol) | GoodToken、戻り値のないNoReturnToken、手数料を引くFeeToken、SafeERC20を縮めたSafeTransferLib、boolを信じるStrictConsumer、SafeTransferLibを使うSafeConsumer |
| [code/vulns/test/Tokens171.t.sol](code/vulns/test/Tokens171.t.sol) | Tokens171Testの四つ |
| [code/market/src/Market.sol](code/market/src/Market.sol) | deposit・withdrawがトークン呼び出しの結果をboolで受けて確認（168・169・183・184行）、addAsset（130行） |
| [code/market/test/BadTokens44.t.sol](code/market/test/BadTokens44.t.sol) | falseを返すトークン、戻り値のないトークン、手数料トークンでMarketを確認するテストの三つ |
| [code/market/test/Donation.t.sol](code/market/test/Donation.t.sol) | 直接送ったトークンが帳簿の外に残るテスト |
| [code/market/test/Standard.t.sol](code/market/test/Standard.t.sol) | 標準インターフェースの確認テスト |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/) | Marketのソースとテストすべて |

### 実行結果

`forge test --offline --match-contract Tokens171Test -vvv`:

```
[PASS] test_feeTokenDivergence() (gas: 103427)
[PASS] test_safeConsumerHandlesNoReturn() (gas: 109486)
[PASS] test_safeTransferRevertsOnNoCode() (gas: 29575)
[PASS] test_strictConsumerBreaksOnNoReturn() (gas: 199523)
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

boolを信じる側は、戻り値のないトークンでデコードに失敗して差し戻される（`--match-test test_strictConsumerBreaksOnNoReturn -vvvv`から選んだ行）：

```
    ├─ StrictConsumer::send(GoodToken: [0x2e23…470b], ECRecover: [0x…0001], 40)
    │   ├─ GoodToken::transfer(ECRecover: [0x…0001], 40)
    │   │   └─ ← [Return] true
    │   └─ ← [Return] true
    ├─ StrictConsumer::send(NoReturnToken: [0xc718…0bB1], ECRecover: [0x…0001], 40)
    │   ├─ NoReturnToken::transfer(ECRecover: [0x…0001], 40)
    │   │   └─ ← [Stop]
    │   └─ ← [Revert] EvmError: Revert
```

SafeTransferLibは、コードのないアドレスへのtransferを成功とみなさない：

```
[PASS] test_safeTransferRevertsOnNoCode() (gas: 29575)
    ├─ VM::expectRevert(SafeTransferFailed(0x000000000000000000000000000000000000dEaD))
    ├─ SafeConsumer::send(0x…dEaD, ECRecover: [0x…0001], 1)
    │   ├─ 0x000000000000000000000000000000000000dEaD::transfer(ECRecover: [0x…0001], 1)
    │   │   └─ ← [Stop]
    │   └─ ← [Revert] SafeTransferFailed(0x000000000000000000000000000000000000dEaD)
```

Marketを標準と違うトークン三つで確認した結果（`forge test --offline --match-contract BadTokens44Test -vvvv`から選んだ行）。falseを返すトークンと戻り値のないトークンは、depositが差し戻される：

```
[PASS] test_falseTokenDepositReverts() (gas: 414968)
    ├─ Market::deposit(FalseToken: [0x2e23…470b], 100)
    │   ├─ FalseToken::transferFrom(0x…1001, Market: [0x5615…b72f], 100)
    │   │   └─ ← [Return] false
    │   └─ ← [Revert] TransferFromFailed(0x2e234DAe75C793f67A35089C9d99245E1C58470b)
[PASS] test_noReturnTokenDepositReverts() (gas: 464482)
    ├─ Market::deposit(NoReturnToken: [0x2e23…470b], 100)
    │   ├─ NoReturnToken::transferFrom(0x…1001, Market: [0x5615…b72f], 100)
    │   │   └─ ← [Stop]
    │   └─ ← [Revert] EvmError: Revert
```

手数料トークンはdepositが通るが、帳簿は100なのにMarketが受け取ったトークンは99である。100を再び引き出そうとすると、トークン側の算術で差し戻される：

```
[PASS] test_feeTokenLedgerDivergence() (gas: 537680)
    ├─ Market::deposit(FeeToken: [0x2e23…470b], 100)
    │   ├─ FeeToken::transferFrom(0x…1001, Market: [0x5615…b72f], 100)
    │   │   └─ ← [Return] true
    │   ├─ emit Deposited(asset: FeeToken: [0x2e23…470b], user: 0x…1001, amount: 100)
    ├─ Market::positions(FeeToken, 0x…1001) [staticcall]
    │   └─ ← [Return] 100, 0, 1, false
    ├─ FeeToken::balanceOf(Market) [staticcall]
    │   └─ ← [Return] 99
    ├─ Market::totalDeposits(FeeToken) [staticcall]
    │   └─ ← [Return] 100
    ├─ Market::withdraw(FeeToken: [0x2e23…470b], 100)
    │   ├─ FeeToken::transfer(0x…1001, 100)
    │   │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
    │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
```

直接送ったトークンが帳簿の外に残るテストもそのまま通る（`test_directTransferStaysAfterWithdrawAll`、260,125ガス）。

### 試すときの注意

- OpenZeppelin Contracts 5.4.0の`SafeERC20._callOptionalReturn`は、返ってきたデータがなければトークンのアドレスにコードがあるかで、あれば値が1かで成功を判定する。この講義のSafeTransferLibは、その判定を縮めて移したものである。
- 手数料トークンのように送った量と受け取った量が違うトークンは、帳簿に送った量を書くMarketと合わない。どのトークンを受け付けるかは、addAssetで管理者が決める。
- テストの中のトイトークンのアドレスは、デプロイの順番によって変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールやライブラリのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3、commit cae51ad4 | 2026-10-20 |
| solc | 0.8.30。vulns・marketともにoptimizerオン（runs 200）・via-IRオン・evm osaka。vulnsは`[fuzz] runs=256 seed=0x2a` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0。`token/ERC20/utils/SafeERC20.sol` 33〜35（safeTransfer）・173〜191（_callOptionalReturn）・22（SafeERC20FailedOperation）、`token/ERC20/extensions/ERC4626.sol` 247 | 2026-10-20 |
| EIP-20 | 34行（Callers MUST handle false）、103行（transfer returns bool） | 2026-10-20 |
| テストのガス（vulns） | feeTokenDivergence 103,427 / safeConsumerHandlesNoReturn 109,486 / safeTransferRevertsOnNoCode 29,575 / strictConsumerBreaksOnNoReturn 199,523 | 2026-10-20 |
| テストのガス（market） | BadTokens44 false 414,968・fee 537,680・noReturn 464,482 / Donation selector 316・directTransfer 260,125 / Standard interfaceIds 448・mockToken 107,642・noApprove 111,918・roundTrip 270,047 | 2026-10-20 |
| トイトークンのアドレス（テストの中） | GoodToken・FalseToken・NoReturnToken・FeeToken 0x2e234DAe…58470b、StrictConsumer・SafeConsumer・Market 0x5615dEB7…23b72f、NoReturnToken（vulns）0xc7183455…320bB1。デプロイの順番によって変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| SafeERC20をMarketに実際に入れるかの判断 | [第256講](../../part20/lecture256/) |
| リベース・手数料トークンを受け付ける金庫の会計設計 | [第256講](../../part20/lecture256/) |
| 受け取る関数（onERC721Received・onERC1155Received）を持つトークン標準 | [第256講](../../part20/lecture256/) |
| 巻き戻りデータで他人のエラーをまねるケース | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
