# 第168講 再入の基本形とCEI

第11部 推奨事項：敵対的環境とバージョン履歴・第44章 軸1・制御の移転

[← 第167講](../../part11/lecture167/) | [第11部 目次](../) | [第169講 →](../../part11/lecture169/)

## この講義の問い

外部呼び出しの一行は、なぜ帳簿より先にあってはいけないのか。送ることと帳簿を直すことの順番を入れ替えると何が変わるのか。Marketのwithdrawはすでに安全なのか。

## 実習資料

### 準備

プロジェクトは二つある。`vulns`は再入を見る小さなトイプロジェクトで、`market`は通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）に確認用テスト`test/Reentrancy44.t.sol`を一つだけ足したものである（srcはそのまま）。どちらもforge-stdが必要である（`lib/forge-std`）。anvilと外部への接続はない。攻撃を再現する側のコードは載せず、直したバージョンと、そのバージョンが防げるかを確認するテストだけを載せる。

### コード

| ファイル | 内容 |
|---|---|
| [code/vulns/foundry.toml](code/vulns/foundry.toml) | solc 0.8.30、optimizerオン（200）・via-IRオン・evm osaka |
| [code/vulns/src/Vault168.sol](code/vulns/src/Vault168.sol) | CEIの順番に直した金庫GoodVaultと、受け取る関数から再び入ろうとする確認用の受け取り側（脆弱な金庫と攻撃再現のコントラクトは除いた抜粋） |
| [code/vulns/test/Vault168.t.sol](code/vulns/test/Vault168.t.sol) | `test_goodVaultBlocks`：同じ再入を仕掛けてもhits 0、金庫の3イーサはそのまま（抜粋） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | withdrawが`_debit`（182行）で帳簿を先に減らし、`transfer`（183行）で送る |
| [code/market/test/Reentrancy44.t.sol](code/market/test/Reentrancy44.t.sol) | transferの途中でwithdrawを再び呼ぶテスト用トークンで、Marketが防ぐかを確認 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/) | Marketのソースとテストすべて |

### 実行結果

直した金庫に同じ再入を仕掛けたテスト（`forge test --offline --match-test test_goodVaultBlocks -vvvv`から選んだ行）。受け取り側のreceiveが読んだ取り分はすでに0なので、再び入らない：

```
[PASS] test_goodVaultBlocks() (gas: 226167)
├─ [8285] GoodVault::withdraw()
│   ├─ [971] ReentererGood::receive{value: 1000000000000000000}()
│   │   ├─ [380] GoodVault::shares(ReentererGood) [staticcall]
│   │   │   └─ ← [Return] 0
│   │   └─ ← [Stop]
│   └─ ← [Stop]
├─ [2286] ReentererGood::hits() [staticcall]
│   └─ ← [Return] 0
Suite result: ok. 1 passed; 0 failed; 0 skipped
```

Marketのwithdrawの順番：

```solidity
function withdraw(address asset, uint256 amount) public notFrozen {   // 180
    if (amount == 0) revert ZeroAmount();                              // 181
    _debit({asset: asset, user: msg.sender, amount: amount});          // 182
    bool ok = IERC20(asset).transfer(msg.sender, amount);              // 183
    if (!ok) revert TransferFailed(asset);                             // 184
    emit Withdrawn(asset, msg.sender, amount);                         // 185
}
```

transferの途中でwithdrawを再び呼ぶトークンで回した確認テスト（`forge test --offline --match-contract Reentrancy44Test -vvvv`から選んだ行）。再び入ってきたwithdrawはすでに減った帳簿を見て`InsufficientDeposit(0, 100)`で差し戻され、帳簿は100のままである：

```
[PASS] test_withdrawCeiBlocksReentry() (gas: 752155)
├─ [6970] Market::positions(Token, Token) [staticcall]
│   └─ ← [Return] 100, 0, 1, false
├─ [76659] Market::withdraw(Token, 100)
│   ├─ [39277] ReentrantToken::transfer(Token, 100)
│   │   ├─ [1079] Market::withdraw(Token, 100)
│   │   │   └─ ← [Revert] InsufficientDeposit(0, 100)
│   │   └─ ← [Revert] InsufficientDeposit(0, 100)
│   └─ ← [Revert] InsufficientDeposit(0, 100)
├─ [6970] Market::positions(Token, Token) [staticcall]
│   └─ ← [Return] 100, 0, 1, false
Suite result: ok. 1 passed; 0 failed; 0 skipped
```

Marketの`forge lint --offline`が出すログの順番の警告二つ：

```
warning[reentrancy-events]: event emitted after an external call; reentrancy can reorder or fabricate logs that off-chain consumers rely on
    ╭▸ src/Market.sol:170:9
170 │         emit Deposited(asset, msg.sender, amount); // 第105講

warning[reentrancy-events]: event emitted after an external call; reentrancy can reorder or fabricate logs that off-chain consumers rely on
    ╭▸ src/Market.sol:185:9
185 │         emit Withdrawn(asset, msg.sender, amount); // 第105講: withdrawAllもこの行で出力される
```

### 試すときの注意

- 抜粋した`Vault168.t.sol`はテスト関数が一つだけなので関数を選ぶ部分が短くなり、同じ環境で`test_goodVaultBlocks`のガスが226,167ではなく225,909と出る。
- ロックで防ぐ道もある。OpenZeppelin Contracts 5.4.0の`ReentrancyGuardTransient`は、`nonReentrant`がtransientストレージにtrueを書き（tstore）、関数が終わるとfalseに戻す。EIP-1153のあるチェーンでだけ使える。
- `forge lint`はreentrancy-eventsの二つのほかに、missing-zero-checkを一つ（Market.sol 180:23）、unsafe-typecastを二つ（MarketMath.sol 33・41）一緒に出す。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールやライブラリのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、vulns・marketともにoptimizerオン（200）・via-IRオン・evm osaka | 2026-10-21 |
| トイの金庫のテストのガス | test_goodVaultBlocks 226,167 | 2026-10-21 |
| Marketのテストのガス | test_withdrawCeiBlocksReentry 752,155 | 2026-10-21 |
| Marketのlintの警告 | reentrancy-eventsの二つ（Market 170・185）、missing-zero-checkの一つ（Market 180:23）、unsafe-typecastの二つ（MarketMath 33・41） | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0、ReentrancyGuardTransient.solはv5.3.0で更新 | 2026-10-21 |
| transientのロックの条件 | EIP-1153のあるチェーンでだけ | 2026-10-21 |
| Solidityのドキュメント | v0.8.36 security-considerations.rst Reentrancyの節49〜131行、common-patterns.rst 57〜58行 | 2026-10-21 |
| The DAO | 2016年 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ロック変数一つを複数の関数で共有する形、view側の確認 | [第169講](../../part11/lecture169/) |
| クロス関数・クロスコントラクト・読み取り専用の再入 | [第169講](../../part11/lecture169/) |
| 再入がトークン・NFTの受け取り関数で起きるケース | [第169講](../../part11/lecture169/)、[第171講](../../part11/lecture171/)、[第256講](../../part20/lecture256/) |
| トークンが少なく移したり、偽りのtrueを返したりするとき | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| ログの順番を信じる外部のプログラム | [第238講](../../part18/lecture238/) |
| The DAO事件の経緯と年表 | [第265講](../../part21/lecture265/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
