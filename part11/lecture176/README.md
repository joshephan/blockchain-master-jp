# 第176講 アクセス制御とtx.origin

第11部 推奨事項：敵対的環境とバージョン履歴・第46章 軸4・権限と鍵

[← 第175講](../../part11/lecture175/) | [第11部 目次](../) | [第177講 →](../../part11/lecture177/)

## この講義の問い

状態を変える関数ごとに、誰が呼べるかはどこに書かれているのか。トランザクションを開いた人が持ち主なら、そのトランザクションの中の呼び出しはすべて持ち主がしたものなのか。役割を分けたり持ち主を引き渡したりするとき、権限のない呼び出しはどこで止まるのか。

## 実習資料

### 準備

二つのプロジェクトを使う。`guards`はアクセス制御のトイコントラクトを入れたFoundryプロジェクトで、forge-stdとOpenZeppelin Contracts 5.4.0が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。`market`は通しプロジェクトMarketのこの講義のバージョンである。前のバージョンからsrcはそのままで、テストファイル`test/ZeroAsset.t.sol`を一つだけ足した。forge-stdが必要である。anvilと外部への接続なしに、forgeの中だけで動く。

トイコントラクトはすべて守る側のコードである。tx.originで持ち主を確かめるウォレットがだまされる流れは、図と説明だけで扱い、コードとしては載せない。

### コード

| ファイル | 内容 |
|---|---|
| [code/guards/foundry.toml](code/guards/foundry.toml) | solc 0.8.30、optimizer・via-IRオン、OpenZeppelinのremapping、fuzz seedを固定 |
| [code/guards/src/Access176.sol](code/guards/src/Access176.sol) | OwnedVault（msg.senderで持ち主を確認）、RoleVault（AccessControl、PAUSER_ROLE）、HandoverVault（Ownable2Step） |
| [code/guards/test/Access176.t.sol](code/guards/test/Access176.t.sol) | Access176Testの六つ：持ち主は通過、他人は拒否、`vm.prank(stranger, owner)`は拒否、役割なしは拒否、役割を与えたあとは通過、二段階の引き渡し |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（optimizer・via-IRオン、ガスの記録の照合、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Marketの本体（`Market.sol`、`IMarket.sol`、`MarketMath.sol`、`MarketTypes.sol`、`MockToken.sol`）。管理者の確認は`Market.sol` 104行の`_checkAdmin` |
| [code/market/test/ZeroAsset.t.sol](code/market/test/ZeroAsset.t.sol) | この講義で足したテスト三つ：ゼロアドレスのwithdraw、ゼロアドレスの上場、`vm.prank(bob, 管理者)`で管理者関数二つ |
| [code/market/test/Access.t.sol](code/market/test/Access.t.sol) | 権限一覧のテスト（`test_permissionTable`）、tx.originを見ないことのテスト（`test_originIsNotChecked`） |
| [code/market/test/](code/market/test/) | このバージョンまでに積み重なった残りのテスト |

### 実行結果

`guards`で`forge test --offline --match-contract Access176Test -vvv`：

```
Ran 6 tests for test/Access176.t.sol:Access176Test
[PASS] test_ownerPasses() (gas: 53263)
[PASS] test_relayedCallRejected() (gas: 33962)
[PASS] test_roleGrantedPasses() (gas: 125342)
[PASS] test_roleMissingRejected() (gas: 39196)
[PASS] test_strangerRejected() (gas: 31136)
[PASS] test_twoStepHandover() (gas: 135822)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

`test_relayedCallRejected`の`-vvvv`のトレース。`vm.prank`の第一引数がmsg.sender、第二引数がtx.originである。トランザクションを開いた側がownerでも、直接呼んだ側がstrangerなので止まる。

```
├─ [0] VM::prank(stranger: [0x49052147F5D97A723DEBdf07680fFFaDAd29A5dC], owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266])
├─ [0] VM::expectRevert(NotOwner(0x49052147F5D97A723DEBdf07680fFFaDAd29A5dC))
├─ [21282] OwnedVault::pause()
│   └─ ← [Revert] NotOwner(0x49052147F5D97A723DEBdf07680fFFaDAd29A5dC)
├─ [2259] OwnedVault::paused() [staticcall]
│   └─ ← [Return] false
```

`test_roleMissingRejected`：役割を与える人（DEFAULT_ADMIN_ROLEを持つowner）でも、PAUSER_ROLEがなければ止まる。

```
├─ [23532] RoleVault::pause()
│   └─ ← [Revert] AccessControlUnauthorizedAccount(0x7c8999dC9a822c1f0Df42023113EDB4FDd543266, 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a)
```

`test_twoStepHandover`（一部）：引き渡しをかけただけではownerはそのままで、strangerの`acceptOwnership`は差し戻され、nextが受け取ってはじめて移る。

```
├─ [47624] HandoverVault::transferOwnership(next: [0xD673D9Ac731383cE0A1Cc0854125443D9f5630AA])
│   ├─ emit OwnershipTransferStarted(previousOwner: owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266], newOwner: next: [0xD673D9Ac731383cE0A1Cc0854125443D9f5630AA])
├─ [2315] HandoverVault::owner() [staticcall]
│   └─ ← [Return] owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266]
├─ [2338] HandoverVault::pendingOwner() [staticcall]
│   └─ ← [Return] next: [0xD673D9Ac731383cE0A1Cc0854125443D9f5630AA]
├─ [23380] HandoverVault::acceptOwnership()
│   └─ ← [Revert] OwnableUnauthorizedAccount(0x49052147F5D97A723DEBdf07680fFFaDAd29A5dC)
├─ [32946] HandoverVault::acceptOwnership()
│   ├─ emit OwnershipTransferred(previousOwner: owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266], newOwner: next: [0xD673D9Ac731383cE0A1Cc0854125443D9f5630AA])
├─ [2315] HandoverVault::owner() [staticcall]
│   └─ ← [Return] next: [0xD673D9Ac731383cE0A1Cc0854125443D9f5630AA]
```

`market`で`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract "ZeroAssetTest|AccessTest" -vvv`：

```
Ran 3 tests for test/ZeroAsset.t.sol:ZeroAssetTest
[PASS] test_adminOnlyByCaller() (gas: 65408)
[PASS] test_listZeroAssetReverts() (gas: 32290)
[PASS] test_withdrawZeroAssetReverts() (gas: 47756)
Suite result: ok. 3 passed; 0 failed; 0 skipped

Ran 2 tests for test/Access.t.sol:AccessTest
[PASS] test_originIsNotChecked() (gas: 35962)
[PASS] test_permissionTable() (gas: 436538)
Suite result: ok. 2 passed; 0 failed; 0 skipped
```

`test_adminOnlyByCaller`のトレース。`vm.prank(bob, 管理者)`で呼ぶと、addAsset・setStatusのどちらもNotAdmin(bob)で、資産の数とstatusはそのままである。

```
├─ [21920] Market::addAsset(0x00000000000000000000000000000000000a55E7, 50)
│   └─ ← [Revert] NotAdmin(0x0000000000000000000000000000000000000B0b)
├─ [21510] Market::setStatus(2)
│   └─ ← [Revert] NotAdmin(0x0000000000000000000000000000000000000B0b)
├─ [2586] Market::assetCount() [staticcall]
│   └─ ← [Return] 1
├─ [2305] Market::status() [staticcall]
│   └─ ← [Return] 0
```

`forge lint --offline src`の警告五つのうちの一つ：

```
warning[missing-zero-check]: address parameter is used in a state write or value transfer without a zero-address check
    ╭▸ src/Market.sol:180:23
    │
180 │     function withdraw(address asset, uint256 amount) public notFrozen {
    │                       ━━━━━━━━━━━━━
```

ゼロアドレスのテスト二つのトレース。withdraw(0, 1)は帳簿でInsufficientDeposit(0, 1)として止まり、bobの帳簿は100のままで、addAsset(0)はZeroAssetで止まる。そこでゼロアドレスのチェックは足さず、根拠をテストとして残した。

```
├─ [26411] Market::withdraw(0x0000000000000000000000000000000000000000, 1)
│   └─ ← [Revert] InsufficientDeposit(0, 1)
├─ [6970] Market::positions(MockToken: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 0x0000000000000000000000000000000000000B0b) [staticcall]
│   └─ ← [Return] 100, 0, 1, false
├─ [23961] Market::addAsset(0x0000000000000000000000000000000000000000, 50)
│   └─ ← [Revert] ZeroAsset()
```

### 試すときの注意

- Marketで状態を変える関数は五つである。管理者専用はaddAsset・setStatusの二つで、確認は`Market.sol` 104行の`msg.sender != admin`一つである。誰でも呼べるdeposit・withdraw・withdrawAllはmsg.sender自身の欄だけを直し、他人の欄を指す引数（from、user）がない。
- Marketのソースでtx.originは、説明コメント一か所のほかには出てこない。onlyAdmin・_checkAdminには`virtual`がないので、継承するコントラクトが変えることはできない。
- `vm.prank(a, b)`はmsg.senderをa、tx.originをbにする。中間のコントラクトなしに、「持ち主が開いたトランザクションの中で別のアドレスが呼ぶ」状況を作れる。
- OpenZeppelinの`hasRole`はマッピングを読むので、一度も与えたことのない役割と、与えてから取り上げた役割はどちらもfalseである。二つを分ける記録はRoleGranted・RoleRevokedのイベントである。
- `market`のテストを選んで回すときは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`をつける。foundry.tomlが、テストのガスの記録を前回の記録と照合する設定になっている。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| solc | 0.8.30。guards・marketともにoptimizerオン（runs 200）、via-IRオン、evm osaka。guardsはfuzz runs 256、seed 0x2a | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | 2026-10-21 |
| テストのガス（guards） | ownerPasses 53,263 / relayedCallRejected 33,962 / roleGrantedPasses 125,342 / roleMissingRejected 39,196 / strangerRejected 31,136 / twoStepHandover 135,822 | 2026-10-21 |
| テストのガス（market） | adminOnlyByCaller 65,408 / listZeroAssetReverts 32,290 / withdrawZeroAssetReverts 47,756 / originIsNotChecked 35,962 / permissionTable 436,538 | 2026-10-21 |
| テストの中のアドレス（makeAddr） | owner 0x7c89…3266、stranger 0x4905…A5dC、pauser 0x1733…F9Fb、next 0xD673…30AA。金庫0x5615…b72f。Marketのテストのbob 0x…0B0b | 2026-10-21 |
| Marketのlintの警告 | 五つ（unsafe-typecastの二つMarketMath 33・41、reentrancy-eventsの二つMarket 170・185、missing-zero-checkの一つMarket 180:23） | 2026-10-21 |
| 損失が最も大きいセキュリティの領域 | 鍵の管理とブリッジ（金額・順位の数値は載せない） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 初期化関数をロックする方法、プロキシの後ろの持ち主 | [第177講](../../part11/lecture177/) |
| 管理者の鍵を奪われたり失ったりしたケース、マルチシグ | [第178講](../../part11/lecture178/) |
| ブリッジの署名者の鍵 | [第179講](../../part11/lecture179/) |
| ウォレット側で署名の要求と承認の範囲を狭めること | [第222講](../../part15/lecture222/)、[第223講](../../part15/lecture223/) |
| 役割を置いたガバナンスと、票で権限を変えること | [第180講](../../part11/lecture180/) |
| 監査で権限一覧を作る順番 | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/) |
| コードの長さで人だけが呼べるようにするチェックの別の形 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
