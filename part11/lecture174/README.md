# 第174講 フラッシュローン

第11部 推奨事項：敵対的環境とバージョン履歴・第45章 軸2・順序の操作

[← 第173講](../../part11/lecture173/) | [第11部 目次](../) | [第175講 →](../../part11/lecture175/)

## この講義の問い

一つのトランザクションの中で返しさえすれば元手なしで大金を借りられるなら、「大きな攻撃は大金を持つ人しかしない」という前提はどうなるのか。その借りたお金でできる最も危険な一手は何か。

## 実習資料

### 準備

プロジェクトは二つある。`vulns`は講義用のトイプール、トイのオラクル・貸し出し、一つのトランザクションの中で貸して返してもらうトイの貸し出しプールを置いた小さなプロジェクトで（本物のサービスではない）、`market`は通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）のsrcをそのまま置き、確認用テスト`test/Order45.t.sol`を足したものである。どちらもforge-stdが必要である（`lib/forge-std`）。anvilと外部への接続はない。借りたお金で価格を揺らす側（借りる側のコントラクト）とその再現テストは載せず、返さなければ差し戻す貸し出しプールと、時間加重平均で直したバージョンを載せる。

### コード

| ファイル | 内容 |
|---|---|
| [code/vulns/foundry.toml](code/vulns/foundry.toml) | solc 0.8.30、optimizerオン（200）・via-IRオン・evm osaka、fuzz runs 256・seed 0x2a |
| [code/vulns/src/Flash174.sol](code/vulns/src/Flash174.sol) | ToyFlashLender。持っているBを貸し、借りた側のコールバック（`onFlashLoan`）のあと残高が減っていれば`NotRepaid`で差し戻す |
| [code/vulns/src/Mev172.sol](code/vulns/src/Mev172.sol) | ToyPool（積が一定の交換、手数料なし） |
| [code/vulns/src/Oracle173.sol](code/vulns/src/Oracle173.sol) | SpotOracle、TwapOracle、スポット価格で担保を評価するToyLender |
| [code/vulns/src/Fixed173.sol](code/vulns/src/Fixed173.sol) | 時間加重平均で担保を評価するTwapLender（窓1000秒） |
| [code/vulns/test/Flash174.t.sol](code/vulns/test/Flash174.t.sol) | `test_flashLoanMustRepay`：返さない借り手は`NotRepaid`で差し戻される（借りたお金で価格を揺らすテストは除いた抜粋） |
| [code/vulns/test/Oracle173.t.sol](code/vulns/test/Oracle173.t.sol) | `test_twapResistsOneBlock`（スポット価格の再現テスト二つは除いた抜粋） |
| [code/market/test/Order45.t.sol](code/market/test/Order45.t.sol) | Marketがトークンを帳簿で数えるかと順番を見る確認テスト四つ |
| [code/market/src/Market.sol](code/market/src/Market.sol) | deposit（165行）・withdraw（180行）。価格を読む行がない |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/) | Marketのソースとテストすべて |

### 実行結果

返さなければ、同じトランザクションが丸ごと差し戻される（`forge test --offline --match-test test_flashLoanMustRepay -vvvv`から選んだ行）：

```
[PASS] test_flashLoanMustRepay() (gas: 446464)
    ├─ [0] VM::expectRevert(NotRepaid())
    ├─ [54574] NoRepay::go(1000)
    │   ├─ [28265] ToyFlashLender::flashLoan(1000)
    │   │   ├─ [130] NoRepay::onFlashLoan(1000)
    │   │   │   └─ ← [Stop]
    │   │   └─ ← [Revert] NotRepaid()
    │   └─ ← [Revert] NotRepaid()
```

元手なしでB 3000を借りてプールに入れると、同じトランザクションの中でスポット価格が1.0から16.0になり、スポット価格で担保A 100を評価する貸し出しは100の代わりに1600を出す。同じ揺さぶりを時間加重平均の貸し出し（TwapLender、窓1000秒）にかけると、借りられる量は100のままである（`forge test --offline --match-contract Flash174FixTest -vvv`の直したバージョンの行。このテストは借りたお金で揺らすコントラクトをつないで回すので、テストファイルは載せていない）：

```
[PASS] test_twapLenderInFlash() (gas: 858802)
Logs:
  borrowFair: 100
  borrowDuring: 100
```

同じトランザクションの中では流れた時間が0なので、揺らした値が平均に入れない。一ブロックの揺さぶりを受けた平均（`forge test --offline --match-test test_twapResistsOneBlock -vvv`）：

```
[PASS] test_twapResistsOneBlock() (gas: 176570)
Logs:
  spotNow: 16000000000000000000
  twap: 1000000000000000000
```

Marketはトークンを帳簿で数え、価格を読まない（`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract Order45Test -vvv`）：

```
Ran 4 tests for test/Order45.t.sol:Order45Test
[PASS] test_depositWithdrawOneToOne() (gas: 219780)
[PASS] test_elapsedReadsBlockTimestamp() (gas: 151799)
[PASS] test_freezeBeforeWithdrawBlocks() (gas: 208491)
[PASS] test_withdrawBeforeFreezePasses() (gas: 233010)
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

### 試すときの注意

- 抜粋したテストファイルはテスト関数の数が減ったので、同じ環境でガスが`test_flashLoanMustRepay` 446,464 → 446,406、`test_twapResistsOneBlock` 176,570 → 176,360と少し違って出る。
- ToyFlashLenderはトークンの代わりに内部の帳簿（balanceB）だけで数える。返したかどうかは、コールバックのあとの残高確認の一行（`NotRepaid`）だけで見る。
- 窓の長さ1000秒はトイの値である。実際のオラクルの窓の長さはサービスごとに違う。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30。vulns・marketともにoptimizerオン（runs 200）・via-IRオン・evm osaka。vulnsは`[fuzz] runs=256 seed=0x2a` | 2026-10-21 |
| テストのガス（vulns） | flashLoanMustRepay 446,464 / twapLenderInFlash 858,802 / twapResistsOneBlock 176,570 | 2026-10-21 |
| テストのガス（market） | Order45 depositWithdrawOneToOne 219,780・elapsedReadsBlockTimestamp 151,799・freezeBeforeWithdrawBlocks 208,491・withdrawBeforeFreezePasses 233,010 | 2026-10-21 |
| TWAPの窓の長さ | テストでは1000秒（トイの値）。実際のオラクルの窓の長さはサービスごとに違う | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| フラッシュローンでガバナンスの票を買うこと | [第180講](../../part11/lecture180/) |
| アルゴリズム型ステーブルコインへの攻撃 | [第201講](../../part13/lecture201/) |
| フラッシュローンの返済を強制するコールバックの設計 | 付録 |
| 複数のブロックにまたがる平均を使うと、なぜ同じトランザクションの攻撃が止まるのか、窓の長さの決め方 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
