# 第162講 UUPS

第10部 標準とアップグレード・第42章 アップグレードのパターン

[← 第161講](../../part10/lecture161/) | [第10部 目次](../) | [第163講 →](../../part10/lecture163/)

## この講義の問い

アップグレードするコードをプロキシから抜いて実装の側に置くと何が軽くなり、その代わりに何を実装のバージョンごとに守らなければならないのか。

## 実習資料

### 準備

プロジェクトは二つある。`demo`は、OpenZeppelinのUUPSUpgradeableを継承した実装のバージョン五つ（BoxUUPS、BoxUUPSV2、BoxOpen、PlainBox、LockedBox）と、コードのないアドレスへアップグレードするトレースを見るテスト一つを置いたデモ用プロジェクトである。プロキシはOpenZeppelinのERC1967Proxyをローカルのanvilにデプロイして使った。`market`は通しプロジェクトMarketの第162講のバージョンである。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0（UUPSUpgradeable、Initializable、ERC1967Proxy）である。OpenZeppelinのコードはここには載せていない。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。アカウントはanvilの既定のテスト用アカウント0〜3番をunlockedで使った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/Boxes.sol](code/demo/src/Boxes.sol) | BoxUUPS（ownerを確認する`_authorizeUpgrade`）、BoxUUPSV2（double、version 2）、BoxOpen（権限の確認を空にしたバージョン）、PlainBox（UUPSではない）、LockedBox（proxiableUUIDだけがありアップグレードの関数なし） |
| [code/demo/test/Uups162.t.sol](code/demo/test/Uups162.t.sol) | コードのないアドレス（0xBEEF）へアップグレードするときの失敗を見るテスト |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第162講のバージョンのsrcの五つのファイル。コードは第161講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/Uups.t.sol](code/market/test/Uups.t.sol) | 第162講で足したUupsTestの二つ（MarketにproxiableUUIDなし、テスト用のSlotProxyはコードのないアドレスも受け入れる） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

ブロックの中の日本語の見出し・注記（「（アカウント0番）」「アカウント1番 upgradeToAndCall(...)」など）は、実行した操作と相手を示すために付けたもので、値と`Error:`の行が実行結果である。

UUPSのプロキシを作る。初期化のcalldataをERC1967Proxyのコンストラクタに渡し、デプロイと初期化を一つのトランザクションで行った。プロキシは212バイトで、管理者のスロットは0である：

```
$ cast calldata "initialize(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
0xc4d66de8000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266

ERC1967Proxy(BoxUUPS, 上のcalldata)   0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
$ cast code ...                        212バイト
$ cast implementation ...              0x5fbdb2315678afecb367f032d93f642f64180aa3   (BoxUUPS)
$ cast admin ...                       0x0000000000000000000000000000000000000000
owner()                                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266   （アカウント0番）
```

プロキシを経由したアップグレード。アップグレードのコードはBoxUUPSの側で動き、プロキシは受け取ったcalldataを渡すだけである：

```
set(5)                                    status 1
アカウント1番 upgradeToAndCall(V2, 0x)    Error: execution reverted: not owner
アカウント0番 upgradeToAndCall(V2, 0x)    status 1
version()                                 2
value()                                   5
double()のあとvalue()                     10
```

実装に直接呼ぶと止められる。upgradeToAndCallはプロキシを経由するときだけ、proxiableUUIDは実装に直接呼ぶときだけ通る（`UUPSUnauthorizedCallContext()` 0xe07c8dba）：

```
BoxUUPSのアドレスにupgradeToAndCall(V2, 0x)   Error: execution reverted: UUPSUnauthorizedCallContext
プロキシのアドレスにproxiableUUID()           Error: execution reverted: UUPSUnauthorizedCallContext
BoxUUPSのアドレスにproxiableUUID()            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

proxiableUUIDの値二つ。OpenZeppelinはEIP-1822の尋ね方にEIP-1967のスロットを使う：

```
OpenZeppelin BoxUUPS.proxiableUUID()   0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
                                       （EIP-1967の実装のスロット）
$ cast keccak PROXIABLE                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
                                       （EIP-1822の原文のスロット）
```

UUPSではないPlainBoxと、コードのないアドレスへのアップグレード。PlainBoxはproxiableUUIDがないのでcatchに行って`ERC1967InvalidImplementation`になり、コードのないアドレスは呼び出しがそのまま終わって返ってきたバイトがないので、その場で巻き戻る（`demo`の`forge test --offline --match-contract Uups162Test -vvvv`）：

```
アカウント0番 upgradeToAndCall(PlainBox, 0x)
  Error: execution reverted: ERC1967InvalidImplementation(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9)
アカウント0番 upgradeToAndCall(アカウント3番のアドレス, 0x)
  Error: ... execution reverted, data: "0x"

$ forge test --offline --match-contract Uups162Test -vvvv
  ├─ [0] 0x000000000000000000000000000000000000bEEF::proxiableUUID() [staticcall]
  │   └─ ← [Stop]
  └─ ← [Revert] call to non-contract address 0x000000000000000000000000000000000000bEEF
```

LockedBoxに替えたあとは、プロキシが委任する先にアップグレードの関数もfallbackもないので、そのプロキシは二度とアップグレードされない：

```
アカウント0番 upgradeToAndCall(LockedBox, 0x)   status 1
version()                                       4
$ cast implementation ...                       0xdc64a140aa3e981100a9beca4e685f962f0cf6c9   (LockedBox)
アカウント0番 upgradeToAndCall(V2, 0x)          Error: ... execution reverted, data: "0x"
```

権限の確認を空にしたBoxOpenに替えると、ownerではないアカウント2番もアップグレードする。owner変数はアカウント0番のままである：

```
アカウント0番 upgradeToAndCall(BoxOpen, 0x)   status 1
version()                                     3
アカウント2番 upgradeToAndCall(V2, 0x)        status 1
version()                                     2
owner()                                       0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266   （アカウント0番）
```

同じプロキシのアドレス（0x5FC8d32690cc91D4c39d9d3abcBD16989F875707）のversionの答え：

| 順番 | アップグレードしたアカウント | 新しい実装 | version() |
|---|---|---|---|
| 最初 | （プロキシのデプロイ） | BoxUUPS | 1 |
| 1 | アカウント0番 | BoxUUPSV2 | 2 |
| 2 | アカウント0番 | BoxOpen | 3 |
| 3 | アカウント2番（ownerではない） | BoxUUPSV2 | 2 |
| 4 | アカウント0番 | LockedBox | 4 |
| 5 | アカウント0番 | BoxUUPSV2 | 巻き戻し、4のまま |

Transparent（第161講のデモ）とUUPSの値（デモ用ビルド、solc 0.8.30、optimizerオフ、evm osaka）：

| 項目 | Transparent | UUPS |
|---|---|---|
| プロキシのランタイム | 2,008 + ProxyAdmin 1,935バイト | 212バイト |
| プロキシのデプロイ | 1,051,299（ProxyAdminの作成を含む） | 197,346（初期化を含む） |
| 実装のランタイム | Box 585バイト | BoxUUPS 4,089バイト |
| set 7（直接 / プロキシ経由） | 26,662 / 31,716 | 26,619 / 31,590 |
| アップグレード1回 | 39,524（ProxyAdmin.upgradeAndCall） | 38,404（upgradeToAndCall） |

プロキシのアドレスを受け取ったときに読む順番：

| 順番 | 読むもの | デモのプロキシでは |
|---|---|---|
| 1 | `cast implementation` | 0xe7f1…0512（BoxUUPSV2）など、アップグレードのたびに変わる |
| 2 | その実装の検証済みのソース・ABI・文書 | BoxUUPSV2のdouble、version |
| 3 | プロキシのコンストラクタの引数（デプロイのトランザクション） | initialize(アカウント0番)のcalldata |
| 4 | 今の実装のアップグレードの権限の関数 | `_authorizeUpgrade`（ownerの確認 / BoxOpenは空） |

`market`で`forge test --offline --match-contract UupsTest -vvvv`。MarketにはproxiableUUID（0x52d1902d）がなく、テスト用のSlotProxyはコードのないアドレス（0xDEAD）に替わったあとも、admin()の呼び出しがデータなしに成功する：

```
[PASS] test_marketHasNoProxiableUuid() (gas: 4882)
[PASS] test_slotProxyAcceptsCodelessAddress() (gas: 273169)
    ├─ [0] 0x000000000000000000000000000000000000dEaD::admin() [delegatecall]
    │   └─ ← [Stop]
```

Market第162講のバージョンの点検：`forge build --offline --sizes`でMarket 3,260 / 3,473、`forge test --offline`と`FOUNDRY_PROFILE=debug`・`legacy`はいずれも94個が通過、`.gas-snapshot` 94行、`bash ci.sh`は`ci ok`。

Marketのアップグレードの判断記録に足した行：

| 講義 | 検討した形 | Marketで測ったもの | 判断 | 確認するテスト |
|---|---|---|---|---|
| 162 | UUPS（OpenZeppelin 5.4.0） | MarketにproxiableUUID・upgradeToAndCallなし。取り入れるならABIが関数二つ以上増え、IMarketのID 0xab691738・Docsのテスト（19）・Selectorsが変わり、バージョンごとにアップグレードの関数と権限の関数を残さなければならない | 取り入れない | test/Uups.t.sol |

### 試すときの注意

- UUPSのプロキシ（ERC1967Proxy）にはアップグレードの関数がない。upgradeToAndCallと権限の確認`_authorizeUpgrade`は実装の側のコードで、新しい実装にこの二つが抜けると、そのプロキシは二度とアップグレードされない。
- OpenZeppelinのUUPSUpgradeableは、immutableの`__self`（実装のデプロイ時の自分のアドレス）で直接の呼び出しと委任の呼び出しを分ける。アップグレードはプロキシを経由しなければならず、proxiableUUIDは実装に直接呼ばなければならない。
- 新しい実装を受け入れるときにOpenZeppelinが尋ねるのはproxiableUUID一つである。ERC1967Utilsは実装のスロットに書く前にコードの長さも確認する。テスト用のSlotProxyには両方の確認がない。
- プロキシのコンストラクタの引数（実装のアドレスと初期化のcalldata）はメタデータに入らない。デプロイのトランザクションから別に読む。
- UUPSUpgradeable.solの`@custom:oz-upgrades-unsafe-allow`の印は、コンパイラではなくOpenZeppelinのアップグレードのツールが読む。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・ライブラリ・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ用プロジェクトはoptimizerオフ（Foundryの既定値）・evm osaka。Market第162講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（package.json）、MIT。UUPSUpgradeable.solの冒頭のコメント"last updated v5.3.0"、`UPGRADE_INTERFACE_VERSION = "5.0.0"`（31行） | 2026-10-20 |
| OpenZeppelinの行番号 | UUPSUpgradeable.sol 13〜15・20・21・36・41・50・59・68〜70・72・84・86〜89・95〜102・108〜113・122・125・135〜145、ERC1967Utils.sol 21・26・53〜58、ERC1967Proxy.sol 26〜28 | 2026-10-20 |
| EIPの原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`。erc-1822.md 319行（14・28〜31・47・52・111・113行を引用）、erc-1967.md 468行（23行を引用）。最後の行はCC0 | 2026-10-19 |
| EIPの状態 | 1822 Stagnant（created 2019-03-04）、1967 Final（created 2019-04-24）。ファイルの最終更新のコミットの日付はどちらも2023-10-25 | 2026-10-19 |
| デモのアドレス（ローカルのanvil） | BoxUUPS `0x5FbDB2315678afecb367f032d93F642f64180aa3`、BoxUUPSV2 `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、BoxOpen `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、PlainBox `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、LockedBox `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、ERC1967Proxy `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707` | 2026-10-20 |
| デモのサイズ | BoxUUPSのランタイム4,089バイト、ERC1967Proxy 212バイト。第161講の値：TUP 2,008、ProxyAdmin 1,935、Box 585 | 2026-10-20 |
| デモのガス（UUPS） | BoxUUPSのデプロイ933,232、BoxUUPSV2 969,665、プロキシのデプロイ197,346（初期化を含む）、set 5 48,690、実装に直接upgradeToAndCall 22,938（巻き戻し）、アカウント1番のアップグレード30,622（巻き戻し）、PlainBox 33,458（巻き戻し）、コードのないアドレス33,181（巻き戻し）、V2へ38,404、double 31,493、BoxOpenへ38,404、アカウント2番36,236、LockedBoxへ38,289、LockedBoxのあと26,848（巻き戻し）。同じ欄の書き換えset 7：実装に直接26,619 / プロキシ31,590 | 2026-10-20 |
| デモのガス（Transparent、第161講） | TUPのデプロイ1,051,299（ProxyAdminの作成を含む）、set 7 Boxに直接26,662 / ERC1967Proxy 31,633 / TUP 31,716、ProxyAdmin.upgradeAndCall 39,524 | 2026-10-20 |
| エラーのセレクタ | UUPSUnauthorizedCallContext 0xe07c8dba、ERC1967InvalidImplementation 0x4c9c8ce3、UUPSUnsupportedProxiableUUID 0xaa1d49a4。関数のセレクタ proxiableUUID 0x52d1902d、upgradeToAndCall 0x4f1ef286、initialize(address) 0xc4d66de8 | 2026-10-20 |
| スロットの値 | EIP-1967の実装のスロット0x360894a1…2bbc、`cast keccak PROXIABLE` 0xc5f16f0f…bcf7 | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第162講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ | 第162講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第162講のバージョンdefault `8fbefd93` | 2026-10-20 |
| テストのガス | UupsTest test_marketHasNoProxiableUuid 4,882、test_slotProxyAcceptsCodelessAddress 273,169。`.gas-snapshot` 94行（既存の92行のうち、RebuildTest:test_recordedLogsIncludeReverted 155,244 → 155,232とtest_tokenSeesDebitedLedger 714,657 → 714,633の2行が第161講のバージョンから変わり、ほかは同じ） | 2026-10-20 |
| 120バイトを超える行（src） | 第162講のバージョン95（バージョン説明のコメントが1行増えた） | 2026-10-20 |
| 行番号 | 第162講のバージョンdebugのdeposit 0 src/Market.sol 174:33、NotActiveの行89、`contract Market` 218行。バージョン説明のコメントが変わると変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| OpenZeppelinのアップグレードのツールが、新しい実装の配置と`@custom:oz-upgrades`の印を検査すること | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| 監査で`_authorizeUpgrade`とアップグレードの関数が新しいバージョンごとに残っているかを確認すること | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| アップグレードの権限を時間の遅延の後ろに置くこと | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/) |
| プロキシを作るときに初期化を抜かしたり他人が先に呼んだりすること、バージョン間の変数の配置 | [第164講](../../part10/lecture164/) |
| プロキシの後ろの実装の検証・文書の読み取りを実際のエクスプローラーで行う手順 | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| Transparent・UUPSの値の比較をデプロイの手数料で計算すること | [第229講](../../part17/lecture229/)〜[第234講](../../part17/lecture234/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
