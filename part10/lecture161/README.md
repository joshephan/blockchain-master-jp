# 第161講 Transparentプロキシ

第10部 標準とアップグレード・第42章 アップグレードのパターン

[← 第160講](../../part10/lecture160/) | [第10部 目次](../) | [第162講 →](../../part10/lecture162/)

## この講義の問い

プロキシにも関数があり、実装にも関数があるとき、入ってきた呼び出しはどちらへ行き、Transparentプロキシはその分かれ道を何で決めるのか。

## 実習資料

### 準備

プロジェクトは二つある。`demo`は、実装のBox・BoxV2、実装のburnとセレクタが同じ公開関数をプロキシに置いたClashProxy、OpenZeppelinのプロキシ三つをビルドに入れるためにimportだけをしたDeploy.solを置いたデモ用プロジェクトである。テストファイルはなく、ローカルのanvilにデプロイして`cast`で呼んだ（OpenZeppelinのTransparentUpgradeableProxy・ERC1967Proxyは`forge create`でデプロイ）。`market`は通しプロジェクトMarketの第161講のバージョンである。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0（TransparentUpgradeableProxy、ProxyAdmin、ERC1967Proxy）である。OpenZeppelinのコードはここには載せていない。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。アカウントはanvilの既定のテスト用アカウント0番・1番・2番をunlockedで使った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/Box.sol](code/demo/src/Box.sol) | 実装の最初のバージョンBox（set、burn、version 1）と、同じ配置にdoubleを足したBoxV2 |
| [code/demo/src/ClashProxy.sol](code/demo/src/ClashProxy.sol) | `collate_propagate_storage(bytes16)`（セレクタ0x42966c68、burnと同じ）をプロキシ自身の関数として置いたプロキシ |
| [code/demo/src/Deploy.sol](code/demo/src/Deploy.sol) | OpenZeppelinのプロキシ三つを`forge create`でデプロイするためにimportだけをしたファイル |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第161講のバージョンのsrcの五つのファイル。コードは第160講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/ProxySelectors.t.sol](code/market/test/ProxySelectors.t.sol) | 第161講で足したProxySelectorsTestの二つ（Marketにアップグレードのセレクタなし、プロキシ自身の関数はプロキシが受ける） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

名前も引数の型も違うのに、セレクタは同じである：

```
$ cast sig "burn(uint256)"
0x42966c68
$ cast sig "collate_propagate_storage(bytes16)"
0x42966c68
```

ClashProxy（実装はBox）にset 100のあとburn(2^128)を送った。status 1で成功したが、ログはプロキシの`Intercepted(address)`一つだけで、Boxの`Burned(uint256)`（0xd83c…7e6e）はない。valueは100のままなので、Boxのburnは1行も動いていない。ブロックの中の`#`で始まる行は説明のために付けた注記である：

```
$ cast send $CLASH "set(uint256)" 100 --unlocked --from $ACC0
$ cast send $CLASH "burn(uint256)" 340282366920938463463374607431768211456 --unlocked --from $ACC0
# レシートのログ
address 0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0   (ClashProxy)
topics  [0x77d020328a33bb1d3d2334be3ed6f5239d5ae6bf6211b60f6dd769915cdc30d5]
data    0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
$ cast call $CLASH "value()(uint256)"
100
```

burn(5)はデータなしに巻き戻る。bytes16の欄は32バイトのうち前の16バイトで、後ろの16バイトは0でなければならないが、5は後ろの16バイトにある。2^128は前の16バイトの最後に1があり、後ろの16バイトが0なので通る：

```
$ cast call $CLASH "burn(uint256)" 5
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast calldata "burn(uint256)" 5
0x42966c680000000000000000000000000000000000000000000000000000000000000005
$ cast calldata "burn(uint256)" 340282366920938463463374607431768211456
0x42966c680000000000000000000000000000000100000000000000000000000000000000
```

Boxに直接burn(5)（value 0）を呼ぶと、`panic: arithmetic underflow or overflow (0x11)`で違う失敗をする。

OpenZeppelinのTransparentUpgradeableProxyを`forge create`でデプロイ（引数はBox、アカウント0番、`0x`）すると、ProxyAdminが一緒に作られ、管理者のスロットにはProxyAdminのアドレスが、ProxyAdminの持ち主にはアカウント0番が入る：

```
$ forge create ...TransparentUpgradeableProxy --constructor-args $BOX $ACC0 0x
$ cast admin $TUP
0x3b02ff1e626ed7a8fd6ec5299e2c54e1421b626b
$ cast call 0x3b02ff1e626ed7a8fd6ec5299e2c54e1421b626b "owner()(address)"
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

ユーザー（アカウント0番）のset 100、burn 5はBoxまで行ってBurned(5)を記録し、valueは95になる。ProxyAdminのアドレスから呼ぶと、実装の関数value()も`ProxyDeniedAdminAccess`（0xd2b576ec）で止められる。`#`で始まる行は注記である：

```
# アカウント0番：set 100、burn 5
address 0x0165878a594ca255338adfa4d48449f69242eb8f   (TUP)
topics  [0xd83c63197e8e676d80ab0122beba9a9d20f3828839e9a1d6fe81d242e9cd7e6e]
data    0x0000000000000000000000000000000000000000000000000000000000000005
$ cast call $TUP "value()(uint256)"
95
# ProxyAdminのアドレスから
$ cast call $TUP "value()(uint256)" --from 0x3b02ff1e626ed7a8fd6ec5299e2c54e1421b626b
Error: execution reverted: ProxyDeniedAdminAccess
```

管理者ではないアカウント1番がプロキシに送ったupgradeToAndCallはBoxに渡され、Boxにはその関数もfallbackもないので、データなしに巻き戻る：

```
$ cast call $TUP "upgradeToAndCall(address,bytes)" $BOXV2 0x --from $ACC1
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

ProxyAdminを経由したアップグレード。アカウント1番は`OwnableUnauthorizedAccount`（0x118cdaa7）で止められ、アカウント0番はUpgraded(BoxV2)を記録する。そのあとversion 2、valueは95のまま、doubleのあと190である：

```
$ cast call $PA "upgradeAndCall(address,address,bytes)" $TUP $BOXV2 0x --from $ACC1
Error: execution reverted: OwnableUnauthorizedAccount(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
$ cast send $PA "upgradeAndCall(address,address,bytes)" $TUP $BOXV2 0x --unlocked --from $ACC0
# レシートのログ
address 0x0165878a594ca255338adfa4d48449f69242eb8f   (TUP)
topics  [0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b,
         0x000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f0512]
$ cast implementation $TUP
0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
```

| プロキシ | 管理者 | アップグレードの道 |
|---|---|---|
| SlotProxy（第160講） | 管理者のスロットのアドレス | プロキシのupgradeTo |
| ERC1967Proxy（OpenZeppelin） | なし（管理者のスロットは0） | プロキシにはない |
| TransparentUpgradeableProxy（OpenZeppelin） | ProxyAdmin（持ち主の鍵一つ） | ProxyAdmin.upgradeAndCall |

0でない欄を書き換えるset 7のgasUsedは、Boxに直接26,662、ERC1967Proxy 31,633、TransparentUpgradeableProxy 31,716（管理者の比較の分だけ83多い）である。value()の`cast estimate`は23,466 / 28,437 / 28,520である。

ProxyAdminの持ち主をアカウント2番に渡し（transferOwnership）、アカウント2番が放棄すると（renounceOwnership）、デプロイしたアカウント0番もアカウント2番もアップグレードできない。実装はBoxV2、管理者のスロットはProxyAdminのままなので、`cast admin`だけでは放棄したかどうかわからず、ProxyAdminの`owner()`を読んではじめてわかる：

```
$ cast send $PA "transferOwnership(address)" $ACC2 --unlocked --from $ACC0
$ cast call $PA "upgradeAndCall(address,address,bytes)" $TUP $BOX 0x --from $ACC0
Error: execution reverted: OwnableUnauthorizedAccount(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
$ cast send $PA "renounceOwnership()" --unlocked --from $ACC2
$ cast call $PA "owner()(address)"
0x0000000000000000000000000000000000000000
$ cast call $PA "upgradeAndCall(address,address,bytes)" $TUP $BOX 0x --from $ACC2
Error: execution reverted: OwnableUnauthorizedAccount(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
$ cast implementation $TUP
0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
$ cast admin $TUP
0x3b02ff1e626ed7a8fd6ec5299e2c54e1421b626b
```

`market`で`forge test --offline --match-contract ProxySelectorsTest -vvvv`（行の一部は省略）。プロキシのアップグレードのセレクタはMarketになく、SlotProxyのupgradeToは管理者でない側が呼ぶとプロキシが`not admin`で巻き戻し、Marketのコードまで行かない：

```
[PASS] test_proxyAnswersItsOwnSelector() (gas: 247411)
    ├─ [23583] SlotProxy::upgradeTo(ECRecover: [0x0000000000000000000000000000000000000001])
    │   └─ ← [Revert] not admin
    ├─ [5406] SlotProxy::fallback() [staticcall]
    │   ├─ [548] Market::admin() [delegatecall]
    │   │   └─ ← [Return] ProxySelectorsTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]
[PASS] test_proxySelectorsNotInMarket() (gas: 48811)
    ├─ [21686] Market::upgradeTo(ECRecover: [0x0000000000000000000000000000000000000001])
    │   └─ ← [Revert] unrecognized function selector 0x3659cfe6 for contract 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, which has no fallback function.
    ├─ [22180] Market::upgradeToAndCall(ECRecover: [0x0000000000000000000000000000000000000001], 0x)
    │   └─ ← [Revert] unrecognized function selector 0x4f1ef286 for contract 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, which has no fallback function.
```

Market第161講のバージョンの`bash ci.sh`（行の一部は省略）：

```
| Market        | 3,260            | 3,473             | 21,316             | 45,679              |
Ran 33 test suites in 47.13ms (35.50ms CPU time): 92 tests passed, 0 failed, 0 skipped (92 total tests)
ci ok
```

Marketのアップグレードの判断記録に足した行：

| 講義 | 検討した形 | Marketで測ったもの | 判断 | 確認するテスト |
|---|---|---|---|---|
| 161 | Transparentプロキシ（OpenZeppelin 5.4.0） | Marketのセレクタ十九とプロキシのアップグレードのセレクタの重なりなし。プロキシの管理者のコントラクト（ProxyAdmin）とその持ち主の鍵が新しくできる、デプロイ1,051,299ガス（デモのバージョン） | 取り入れない（管理者の鍵がもう一つできる） | test/ProxySelectors.t.sol |

### 試すときの注意

- プロキシと実装は別々にコンパイルされるので、セレクタが重なってもビルドは止まらない。プロキシに公開関数があると、そのセレクタで来る呼び出しは名前が違ってもプロキシが先に受ける。
- OpenZeppelinのTransparentUpgradeableProxyは自身の公開関数を持たず、`_fallback`の中で呼んだアドレスによって道を分ける。管理者（ProxyAdmin）は実装の関数を呼べず、ほかのアドレスはupgradeToAndCallに届かない。
- ProxyAdminの`UPGRADE_INTERFACE_VERSION`が"5.0.0"ならupgradeAndCallしかなく、呼ぶ関数がなければ三つ目の引数に空のバイト（`0x`）を入れる。
- OwnableのtransferOwnershipは、受け取る側の確認なしに一度で渡る（Ownable2Stepとは違う）。
- Market第161講のバージョンのデプロイのガスは760,316である（バージョン説明のコメントが変わっても、末尾のメタデータのハッシュの中の00のバイトの数は第160講のバージョンと同じ）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・ライブラリ・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ用プロジェクトはevm_version osaka、optimizerは既定値（オフ）。Market第161講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3（Commit `cae51ad`） | 2026-10-20 |
| EIPの原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`、ERC-1967 Final（created 2019-04-24）、ファイルの最終更新2023-10-25。行番号82・84・86・88 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（`package.json`）。`TransparentUpgradeableProxy.sol`（冒頭last updated v5.2.0）30〜34 規則二つ、36〜40 ProxyAdminを置く理由、42〜46 ABIなし、51〜55 adminはimmutable、57〜60 関数を足すなという警告、63〜67 `_admin`、72 `ProxyDeniedAdminAccess`、79〜83 コンストラクタ、95〜105 `_fallback` / `ProxyAdmin.sol`（last updated v5.2.0）13 Ownable、22 `UPGRADE_INTERFACE_VERSION = "5.0.0"`、38〜44 upgradeAndCall / `ERC1967Proxy.sol` 26〜28 コンストラクタ / `access/Ownable.sol` 76 renounceOwnership、84 transferOwnership | 2026-10-20 |
| エラー・セレクタ | `ProxyDeniedAdminAccess()` 0xd2b576ec、`OwnableUnauthorizedAccount(address)` 0x118cdaa7、burn(uint256)・collate_propagate_storage(bytes16) 0x42966c68、upgradeTo(address) 0x3659cfe6、upgradeToAndCall(address,bytes) 0x4f1ef286、proxiableUUID() 0x52d1902d。イベントのtopic0 Intercepted(address) 0x77d02032…30d5、Burned(uint256) 0xd83c6319…7e6e、Upgraded(address) 0xbc7cd75a…2d3b | 2026-10-20 |
| デモのガス（ローカルのanvil） | Boxのデプロイ179,411、BoxV2 203,591、ClashProxy 180,934、ClashProxyのset 100 48,638、burn(5) 21,513（巻き戻し）、burn(2^128) 22,824、TUPのデプロイ1,051,299（ProxyAdminの作成を含む）、TUPのset 100 48,816、burn 5 33,057、アカウント1番のプロキシのupgradeToAndCall 26,931（巻き戻し）、アカウント1番のupgradeAndCall 25,975（巻き戻し）、アカウント0番のupgradeAndCall 39,524、double 31,597、ERC1967Proxyのデプロイ148,540、transferOwnership 29,014、renounceOwnership 23,429。set 7（0でない欄の書き換え） Box 26,662 / ERC1967Proxy 31,633 / TUP 31,716、value()の`cast estimate` 23,466 / 28,437 / 28,520 | 2026-10-20 |
| サイズ（デモ、optimizerオフ） | ランタイム Box 585、TUP 2,008、ProxyAdmin 1,935、ERC1967Proxy 212バイト。テストの中のSlotProxy（via-IR optimizerオン）357バイト | 2026-10-20 |
| デモのアドレス（ローカルのanvil） | Box `0x5FbDB2315678afecb367f032d93F642f64180aa3`、BoxV2 `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、ClashProxy `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、TUP `0x0165878A594ca255338adfa4d48449f69242Eb8F`、ProxyAdmin `0x3b02ff1e626ed7a8fd6ec5299e2c54e1421b626b`、ERC1967Proxy `0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e` | 2026-10-20 |
| サイズ | 第161講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第161講のバージョンdefault `18f964a4`（第160講のバージョン`dc45e3be`） | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第161講のバージョン デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264。MockToken `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Market `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` | 2026-10-20 |
| テストのガス（.gas-snapshot） | `ProxySelectorsTest:test_proxyAnswersItsOwnSelector() (gas: 247411)`、`ProxySelectorsTest:test_proxySelectorsNotInMarket() (gas: 48811)`、92行 | 2026-10-20 |
| 行番号 | 第161講のバージョンdebugのdeposit 0 src/Market.sol 173:33、NotActive 88、`contract Market` 217。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | anvilのアカウント0番`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`、1番`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`、2番`0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`（anvilの既定のテスト用アカウント、unlockedのアカウントで送る）。テストのコントラクト`0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496` | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| アップグレードの関数を実装の側に置く形（UUPS）、管理者のいないERC1967Proxyでアップグレードすること | [第162講](../../part10/lecture162/) |
| セレクタごとに違う実装へ送る形と、そのセレクタの表の重なり | [第163講](../../part10/lecture163/) |
| プロキシの管理者の鍵を複数の署名や時間の遅延で縛ること | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/) |
| 監査でプロキシと実装のセレクタの重なりをツールで探すこと | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| 他人が立てたプロキシの後ろの実装が変わるかを見張ること | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| 実装のコードが管理者のスロットを上書きする場合（OZ 51〜55 IMPORTANT） | [第164講](../../part10/lecture164/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
