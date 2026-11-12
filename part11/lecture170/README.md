# 第170講 外部呼び出しの結果の処理とpull payment

第11部 推奨事項：敵対的環境とバージョン履歴・第44章 軸1・制御の移転

[← 第169講](../../part11/lecture169/) | [第11部 目次](../) | [第171講 →](../../part11/lecture171/)

## この講義の問い

低水準のcallが失敗すると何が起きるのか。お金を押して送る道と、受け取る人に引き出しに来させる道は、攻撃の前でどう分かれるのか。

## 実習資料

### 準備

プロジェクトは二つある。`vulns`は外部呼び出しの結果と支払いの方式を見る小さなトイプロジェクトで、`market`は通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）のsrcをそのまま置き、確認用テスト`test/BadTokens44.t.sol`を足したものである。どちらもforge-stdが必要である（`lib/forge-std`）。anvilと外部への接続はない。

### コード

| ファイル | 内容 |
|---|---|
| [code/vulns/foundry.toml](code/vulns/foundry.toml) | solc 0.8.30、optimizerオン（200）・via-IRオン・evm osaka |
| [code/vulns/src/Payout170.sol](code/vulns/src/Payout170.sol) | 押して送るPushPayout、帳簿に書いて引き出しに来させるPullPayout、受け取りを拒むRejecter、callの結果を見ないIgnorer |
| [code/vulns/src/Checked170.sol](code/vulns/src/Checked170.sol) | Ignorerに結果確認の一行を足したIgnorerChecked |
| [code/vulns/test/Payout170.t.sol](code/vulns/test/Payout170.t.sol) | 一人が拒むと全体が止まるpush、拒んだ人の取り分だけが残るpull、結果を見なかったcall、Payout170Testの三つ |
| [code/vulns/test/Checked170.t.sol](code/vulns/test/Checked170.t.sol) | 結果を確認すると`SendFailed`で差し戻されるか、Checked170Testの一つ |
| [code/market/src/Market.sol](code/market/src/Market.sol) | deposit・withdrawがトークン呼び出しの結果を見て`TransferFromFailed`・`TransferFailed`で差し戻す（169・184行） |
| [code/market/test/BadTokens44.t.sol](code/market/test/BadTokens44.t.sol) | falseを返すトークン、戻り値のないトークン、手数料トークンでMarketを確認するテストの三つ |
| [code/market/test/Pull.t.sol](code/market/test/Pull.t.sol) | 受け取りを拒むトークンでwithdrawが差し戻されるかなど、PullTestの二つ |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/) | Marketのソースとテストすべて |

### 実行結果

結果を見ないcall（`forge test --offline --match-contract Payout170Test -vvv`から選んだ行と`-vvvv`のトレース）。受け取り側が差し戻したのに`done`はtrueである：

```
[PASS] test_ignoredCallResult() (gas: 63933)

├─ [53587] Ignorer::pay(Rejecter: [0x2e23…470b], 1000000000000000000 [1e18])
│   ├─ [127] Rejecter::receive{value: 1000000000000000000}()
│   │   └─ ← [Revert] no thanks
│   └─ ← [Stop]
├─ [2259] Ignorer::done() [staticcall]
│   └─ ← [Return] true
```

`forge build --offline --force`がその行を捕まえる：

```
Compiler run successful with warnings:
Warning (9302): Return value of low-level calls not used.
  --> src/Payout170.sol:60:9:
warning[unchecked-call]: low-level call does not check the success return value
   ╭▸ src/Payout170.sol:60:9
```

結果確認の一行を足したバージョン（`forge test --offline --match-contract Checked170Test -vvvv`から選んだ行）：

```
[PASS] test_checkedCallReverts() (gas: 44982)
│   ├─ [127] Rejecter::receive{value: 1000000000000000000}()
│   │   └─ ← [Revert] no thanks
│   └─ ← [Revert] SendFailed(0x2e234DAe75C793f67A35089C9d99245E1C58470b)
```

押して送る形。拒む人一人のせいで支払い全体が差し戻される（`test_pushBlockedByOne`、249,900ガス）：

```
├─ [72379] PushPayout::payAll{value: 3000000000000000000}()
│   ├─ [0] 0x00000000000000000000000000000000000A11cE::receive{value: 1000000000000000000}()
│   │   └─ ← [Stop]
│   ├─ [127] Rejecter::receive{value: 1000000000000000000}()
│   │   └─ ← [Revert] no thanks
│   └─ ← [Revert] one recipient blocked all
```

引き出しに来させる形。拒む人のwithdrawだけが差し戻され、残りはそれぞれ引き出していく（`test_pullUnaffected`、347,189ガス）：

```
├─ [97536] PullPayout::fund{value: 3000000000000000000}()
│   └─ ← [Stop]
├─ [33570] PullPayout::withdraw()                      // Rejecterが呼ぶ
│   ├─ [127] Rejecter::receive{value: 1000000000000000000}()
│   │   └─ ← [Revert] no thanks
│   └─ ← [Revert] send failed
├─ [33200] PullPayout::withdraw()                      // 0xA11CEが呼ぶ
│   ├─ [0] 0x00000000000000000000000000000000000A11cE::receive{value: 1000000000000000000}()
│   │   └─ ← [Stop]
│   └─ ← [Stop]
```

Marketはfalseを返すトークンのdepositを差し戻す（`forge test --offline --match-contract "PullTest|BadTokens44Test" -vvvv`から選んだ行）：

```
[PASS] test_falseTokenDepositReverts() (gas: 414968)
├─ [96253] Market::deposit(FalseToken: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100)
│   ├─ [298] FalseToken::transferFrom(0x0000000000000000000000000000000000001001, Market: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 100)
│   │   └─ ← [Return] false
│   └─ ← [Revert] TransferFromFailed(0x2e234DAe75C793f67A35089C9d99245E1C58470b)
```

受け取る人に送るときだけ差し戻すトークンなら、その人のwithdrawだけが差し戻され、取り分は帳簿にそのまま残る：

```
[PASS] test_refusedWithdrawStaysWithCaller() (gas: 780522)
├─ [42404] Market::withdraw(RefusingToken: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 50)
│   ├─ [2516] RefusingToken::transfer(0x0000000000000000000000000000000000002002, 50)
│   │   └─ ← [Revert] refused
│   └─ ← [Revert] refused
```

Marketの`forge lint src`が出すゼロアドレスの警告：

```
warning[missing-zero-check]: address parameter is used in a state write or value transfer without a zero-address check
    ╭▸ src/Market.sol:180:23
    │
180 │     function withdraw(address asset, uint256 amount) public notFrozen {
    │                       ━━━━━━━━━━━━━
```

### 試すときの注意

- イーサを`transfer`・`send`で送ると、受け取り側には2300ガスしか渡らない。受け取り側のコードがそれより多く使うと失敗する。
- vulnsをビルドすると、lintはunchecked-call（60:9）のほかにもcalls-loop（18:26）、require-revert-in-loop（19:13）、arbitrary-send-ethなどを出す。
- Marketのlintの警告は五つである：unsafe-typecastの二つ（MarketMath.sol 33・41）、reentrancy-eventsの二つ（Market.sol 170・185）、missing-zero-checkの一つ（Market.sol 180:23）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-20 |
| solc | 0.8.30。vulns・marketともにoptimizerオン（runs 200）・via-IRオン・evm osaka | 2026-10-20 |
| 2300ガス | `transfer`・`send`が受け取り側に渡すガス | 2026-10-20 |
| vulnsのテストのガス | test_ignoredCallResult 63,933、test_pullUnaffected 347,189、test_pushBlockedByOne 249,900、test_checkedCallReverts 44,982 | 2026-10-20 |
| marketのテストのガス | test_falseTokenDepositReverts 414,968、test_feeTokenLedgerDivergence 537,680、test_noReturnTokenDepositReverts 464,482、test_refusedWithdrawStaysWithCaller 780,522、test_tokenSeesDebitedLedger 714,657 | 2026-10-20 |
| 二つの形のガス（アカウント同士） | 送る形becomeRichest 41,041 / 引き出す形becomeRichest 53,858 + withdraw 28,709 = 82,567。solc 0.8.30・optimizerオフ・evm osaka（第150講の測定） | 2026-10-20 |
| vulnsのビルドの警告 | コンパイラのWarning 9302（Payout170.sol 60:9）、lintのunchecked-call（60:9）、calls-loop（18:26）、require-revert-in-loop（19:13）、arbitrary-send-ethなど | 2026-10-20 |
| Marketのlintの警告 | 五つ：unsafe-typecastの二つ（MarketMath 33・41）、reentrancy-eventsの二つ（Market 170・185）、missing-zero-checkの一つ（Market 180:23） | 2026-10-20 |
| Solidityのドキュメント | v0.8.36 common-patterns.rst Withdrawal from Contracts | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 長さが伸びるリストを分けて処理したり、引き出しに来させたりする設計 | [第229講](../../part17/lecture229/)〜[第234講](../../part17/lecture234/) |
| try/catchで外部呼び出しの失敗を捕まえる実務 | [第183講](../../part11/lecture183/) |
| ゼロアドレスのチェック（missing-zero-check）とアクセス制御 | [第176講](../../part11/lecture176/) |
| 返ってきた巻き戻りデータを信じるかどうか | [第171講](../../part11/lecture171/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| 戻り値のないトークンと手数料を引くトークン | [第171講](../../part11/lecture171/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
