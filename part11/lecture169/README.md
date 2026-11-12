# 第169講 再入の変種：クロス関数、クロスコントラクト、read-only

第11部 推奨事項：敵対的環境とバージョン履歴・第44章 軸1・制御の移転

[← 第168講](../../part11/lecture168/) | [第11部 目次](../) | [第170講 →](../../part11/lecture170/)

## この講義の問い

withdraw一か所だけをCEIに直せば終わりなのか。別の関数から、別のコントラクトから、view関数から入ってくる再入はどう違うのか。

## 実習資料

### 準備

プロジェクトは二つある。`vulns`は再入の変種を見る小さなトイプロジェクトで、`market`は通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）のsrcをそのまま置いたものである。どちらもforge-stdが必要である（`lib/forge-std`）。anvilと外部への接続はない。攻撃を再現する側のコードは載せず、順番だけを変えて直したバージョンを載せる。

### コード

| ファイル | 内容 |
|---|---|
| [code/vulns/foundry.toml](code/vulns/foundry.toml) | solc 0.8.30、optimizerオン（200）・via-IRオン・evm osaka |
| [code/vulns/src/Fixed169.sol](code/vulns/src/Fixed169.sol) | 直したバージョン二つ。ShareVaultCei（withdrawが取り分を先に0に）、PricedVaultCei（redeemが供給を先に減らす）。関数の形はそのままにして順番だけを変えた |
| [code/market/src/Market.sol](code/market/src/Market.sol) | deposit・withdraw・withdrawAllが同じpositionsの帳簿を、帳簿が先、トークンが後の順番で直す |
| [code/market/test/Pull.t.sol](code/market/test/Pull.t.sol) | transferの途中でトークンのコードがMarketの帳簿を読む確認テスト、PullTestの二つ |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/) | Marketのソースとテストすべて |

### 実行結果

直したバージョンに同じ流れをつないだ確認テスト二つの結果（`forge test --offline --match-contract Fixed169Test -vvv`のうち直したバージョンの行）。このテストは攻撃再現のコントラクトをそのままつないで回すので、テストファイルは載せていない：

```
[PASS] test_crossFunctionFixed() (gas: 174683)
[PASS] test_readOnlyFixed() (gas: 166980)
```

クロス関数の側は、コールバックの時点で取り分がすでに0なので、別の関数（transferShares）で渡す取り分がない。受け取り側は自分の取り分の1イーサだけを受け取り、金庫にはほかの預け手二人の2イーサが残る。読み取り専用の側は、直す前のバージョンでコールバックの途中に読んだpriceが0.5（5e17）で、終わったあとは1.0（1e18）に戻った。供給を先に減らした直したバージョンでは、コールバックの途中に読んだ値も1.0である。

Marketで帳簿を直す順番：

```solidity
function deposit(address asset, uint256 amount) external whenActive {
    _checkDeposit(asset, amount);
    _credit({asset: asset, user: msg.sender, amount: amount});            // 167
    bool ok = IERC20(asset).transferFrom(msg.sender, address(this), amount); // 168
    if (!ok) revert TransferFromFailed(asset);
    emit Deposited(asset, msg.sender, amount);
}

function withdraw(address asset, uint256 amount) public notFrozen {
    if (amount == 0) revert ZeroAmount();
    _debit({asset: asset, user: msg.sender, amount: amount}); // 182
    bool ok = IERC20(asset).transfer(msg.sender, amount);     // 183
    if (!ok) revert TransferFailed(asset);
    emit Withdrawn(asset, msg.sender, amount);
}

function withdrawAll(address asset) external {
    withdraw(asset, Amount.unwrap(positions[asset][msg.sender].deposited)); // 191
}
```

`forge test --offline --match-contract PullTest -vvv`:

```
[PASS] test_refusedWithdrawStaysWithCaller() (gas: 780522)
[PASS] test_tokenSeesDebitedLedger() (gas: 714645)
Suite result: ok. 2 passed; 0 failed; 0 skipped
```

`test_tokenSeesDebitedLedger`を`-vvvv`で回したトレースから選んだ行。100を預けたユーザーが30を引き出す途中に、トークンのコードが読んだ帳簿はすでに減った70である：

```
├─ [140499] Market::withdraw(PeekToken, 30)
│   ├─ [98590] PeekToken::transfer(0x…1001, 30)
│   │   ├─ [2970] Market::positions(PeekToken, 0x…1001) [staticcall]
│   │   │   └─ ← [Return] 70, 0, 1, false
│   │   ├─ [714] Market::totalDeposits(PeekToken) [staticcall]
│   │   │   └─ ← [Return] 70
```

### 試すときの注意

- ロックを使う道：OpenZeppelin Contracts 5.4.0の`ReentrancyGuard`は`_status`をENTEREDに変えておき、入るときにすでにENTEREDなら`ReentrancyGuardReentrantCall`で差し戻す。ロック変数一つを複数の関数で共有し、view側は`_reentrancyGuardEntered()`でロックの状態を確認できる。`ReentrancyGuardTransient`は同じことをtransientストレージで行い、EIP-1153のあるチェーンでだけ使う。
- MarketはCEIの順番ですでに防がれているので、ロックは足さなかった。
- vulnsをビルドすると、この講義のファイルではないPayout170.solの60行で"Return value of low-level calls not used"の警告が出る。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールやライブラリのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-20 |
| solc | 0.8.30、vulnsはoptimizerオン（200）・via-IRオン・evm osaka | 2026-10-20 |
| トイの金庫のテストのガス | test_crossFunction 196,350 / test_readOnlyPriceBroken 172,042 / test_crossFunctionFixed 174,683 / test_friendCashesOut 228,288 / test_readOnlyFixed 166,980 | 2026-10-20 |
| Marketのテストのガス | test_refusedWithdrawStaysWithCaller 780,522 / test_tokenSeesDebitedLedger 714,645 | 2026-10-20 |
| トイのpriceの値 | 1e18 = 1.0、コールバックで5e17 = 0.5 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0。ReentrancyGuard.solはv5.1.0で更新、ReentrancyGuardTransient.solはv5.3.0で更新、ERC4626.solはv5.4.0で更新 | 2026-10-20 |
| Solidityのドキュメント | v0.8.36 security-considerations.rst 128〜131行 | 2026-10-20 |
| transientのロックの条件 | EIP-1153のあるチェーンでだけ | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 偽りの価格を信じる別のコントラクト（オラクルと価格の操作） | [第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/) |
| 読み取り専用の値を不変条件で守るファジング | [第183講](../../part11/lecture183/) |
| 受け取る関数（onERC721Received・onERC1155Received）から再び呼ぶこと | [第256講](../../part20/lecture256/) |
| 移す前に送る側のコードを呼ぶトークンとMarketの上場の判断 | [第171講](../../part11/lecture171/)、[第256講](../../part20/lecture256/) |
| ロックをいつ足すか | [第177講](../../part11/lecture177/)、[第182講](../../part11/lecture182/)、[第183講](../../part11/lecture183/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
