# 第177講 未初期化のプロキシとプロキシの乗っ取り

第11部 推奨事項：敵対的環境とバージョン履歴・第46章 軸4・権限と鍵

[← 第176講](../../part11/lecture176/) | [第11部 目次](../) | [第178講 →](../../part11/lecture178/)

## この講義の問い

コンストラクタで決めた持ち主は、プロキシの後ろでも持ち主なのか。誰も初期化していない実装アドレスは誰のものなのか。他人のコードに頼るコントラクトは、何まで信じているのか。

## 実習資料

### 準備

二つのプロジェクトを使う。`guards`はプロキシの後ろに置く実装のトイコントラクトを入れたFoundryプロジェクトで、forge-stdとOpenZeppelin Contracts 5.4.0が必要である（`lib/forge-std`、`lib/openzeppelin-contracts`）。`market`は通しプロジェクトMarketのこの講義のバージョンである。前のバージョンからsrcはそのままで、テストファイル`test/NoInit.t.sol`を一つだけ足した。forge-stdが必要である。anvilなしに、forgeの中だけで動く。

トイコントラクトとテストは、すべて初期化をロックする側のコードである。他人の初期化を横取りする流れ（後回しにした初期化のすき、残された実装アドレス）は、図と説明だけで扱い、コードとしては載せない。

### コード

| ファイル | 内容 |
|---|---|
| [code/guards/foundry.toml](code/guards/foundry.toml) | solc 0.8.30、optimizer・via-IRオン、OpenZeppelinのremapping |
| [code/guards/src/Init177.sol](code/guards/src/Init177.sol) | CounterV1（Initializable・UUPSUpgradeable、コンストラクタの`_disableInitializers()`、`_authorizeUpgrade`の持ち主の確認）、CounterV2（version 2） |
| [code/guards/test/Init177.t.sol](code/guards/test/Init177.t.sol) | Init177Testの三つ：実装アドレスの初期化のロック、同じトランザクションでの初期化のあと二回目の初期化を拒否、アップグレードは持ち主だけ |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/) | Marketの本体。管理者はコンストラクタが決める`immutable admin`（`Market.sol` 67・70〜72）、確認は104行 |
| [code/market/test/NoInit.t.sol](code/market/test/NoInit.t.sol) | この講義で足したテスト四つ：デプロイのときに決めた管理者、初期化関数なし、ゼロアドレスの管理者を拒否、ランタイムの命令を数える（DELEGATECALL・SELFDESTRUCT・ORIGIN） |
| [code/market/test/](code/market/test/) | このバージョンまでに積み重なった残りのテスト（プロキシの後ろのMarketを見る`Upgrade.t.sol`を含む） |

### 実行結果

`guards`で`forge test --offline --match-contract Init177Test -vvvv`の`test_implInitializeLocked`の部分。実装をデプロイした瞬間に初期化の欄がuint64の最大値でロックされ、実装アドレスに直接呼んだinitializeは差し戻される。

```
[PASS] test_implInitializeLocked() (gas: 232863)
    ├─ [357965] → new CounterV1@0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
    │   ├─ emit Initialized(version: 18446744073709551615 [1.844e19])
    ├─ [164164] → new ERC1967Proxy@0x2e234DAe75C793f67A35089C9d99245E1C58470b
    │   ├─ emit Upgraded(implementation: CounterV1: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   ├─ [46294] CounterV1::initialize(owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266]) [delegatecall]
    │   │   ├─ emit Initialized(version: 1)
    ├─ [24061] CounterV1::initialize(stranger: [0x49052147F5D97A723DEBdf07680fFFaDAd29A5dC])
    │   └─ ← [Revert] InvalidInitialization()
    ├─ [2367] CounterV1::owner() [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000
```

`test_proxyInitOnce`：プロキシを作るトランザクションの中でownerが決まり、二回目のinitializeは差し戻される。

```
[PASS] test_proxyInitOnce() (gas: 259556)
    ├─ [7174] ERC1967Proxy::fallback() [staticcall]
    │   ├─ [2367] CounterV1::owner() [delegatecall]
    │   │   └─ ← [Return] owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266]
    ├─ [28994] ERC1967Proxy::fallback(stranger: [0x49052147F5D97A723DEBdf07680fFFaDAd29A5dC])
    │   ├─ [2751] CounterV1::initialize(stranger: [0x49052147F5D97A723DEBdf07680fFFaDAd29A5dC]) [delegatecall]
    │   │   └─ ← [Revert] InvalidInitialization()
    │   └─ ← [Revert] InvalidInitialization()
```

`test_upgradeOnlyOwner`：strangerのupgradeToAndCallはNotOwner(stranger)で止まり、ownerが上げるとCounterV2になり、ownerの欄はプロキシのストレージなのでそのままである。

```
[PASS] test_upgradeOnlyOwner() (gas: 292369)
    ├─ [29520] ERC1967Proxy::fallback(CounterV2: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0x)
    │   ├─ [2997] CounterV1::upgradeToAndCall(CounterV2: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0x) [delegatecall]
    │   │   └─ ← [Revert] NotOwner(0x49052147F5D97A723DEBdf07680fFFaDAd29A5dC)
    ├─ [37080] ERC1967Proxy::fallback(CounterV2: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0x)
    │   ├─ [10564] CounterV1::upgradeToAndCall(CounterV2: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0x) [delegatecall]
    │   │   ├─ emit Upgraded(implementation: CounterV2: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a])
    │   ├─ [241] CounterV2::version() [delegatecall]
    │   │   └─ ← [Return] 2
    │   ├─ [2389] CounterV2::owner() [delegatecall]
    │   │   └─ ← [Return] owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266]
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

`market`で`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract "NoInitTest|UpgradeTest" -vvv`：

```
Ran 2 tests for test/Upgrade.t.sol:UpgradeTest
[PASS] test_slotMapSameBehindProxy() (gas: 63559)
[PASS] test_upgradeSwapsImmutableAdmin() (gas: 102924)
Ran 4 tests for test/NoInit.t.sol:NoInitTest
[PASS] test_adminSetAtDeploy() (gas: 6093)
[PASS] test_noInitializer() (gas: 33336)
[PASS] test_opcodeCounts() (gas: 642148)
[PASS] test_zeroAdminRejected() (gas: 4043)
Ran 2 test suites in 3.46ms (1.98ms CPU time): 6 tests passed, 0 failed, 0 skipped (6 total tests)
```

`test_noInitializer`のトレースには`unrecognized function selector 0xc4d66de8 … which has no fallback function`が出て、adminはそのままである。`test_zeroAdminRejected`は`ZeroAdmin()`（セレクタ0x7289db0e）で差し戻される。`test_opcodeCounts`が数えたMarketのランタイムの命令は、DELEGATECALL 0、SELFDESTRUCT 0、ORIGIN 0である。このバージョン全体の`forge test --offline`は104個が通る。

### 試すときの注意

- プロキシの後ろのコントラクトを読むとき、最初に探す行は三つある。実装のコンストラクタの`_disableInitializers()`、プロキシを作るトランザクションの生成データに入った`initialize`、アップグレード権限の関数（`_authorizeUpgrade`）の持ち主の確認。
- 実装のコンストラクタが書いた値は、実装アドレスのストレージにだけ残る。プロキシのストレージの持ち主の欄は、初期化関数が埋めるまで、エラーも警告もなく0である。
- `_disableInitializers()`は初期化の欄をuint64の最大値（18446744073709551615）にする。トレースの`Initialized(version: 18446744073709551615)`がその跡である。
- OpenZeppelinの`UUPSUpgradeable`の`_authorizeUpgrade`は本体のない宣言なので、継承する側が確認の行を自分で埋めなければならない。
- `test_opcodeCounts`はPUSHのあとのデータとコード末尾のメタデータを飛ばし、命令のバイトだけを数える。単純にバイトを数えると、データの中の0xf4・0xffを命令と数え間違える。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30（optimizerオン、runs 200、via-IRオン、evm osaka） | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | 2026-10-21 |
| Init177Testのガス | test_implInitializeLocked 232,863 / test_proxyInitOnce 259,556 / test_upgradeOnlyOwner 292,369 | 2026-10-21 |
| デプロイのガスとサイズ | CounterV1 357,965ガス、1,671バイト / CounterV2 365,571ガス、1,709バイト / ERC1967Proxy 164,164ガス、130バイト | 2026-10-21 |
| NoInitTestのガス | adminSetAtDeploy 6,093 / noInitializer 33,336 / opcodeCounts 642,148 / zeroAdminRejected 4,043 | 2026-10-21 |
| Marketのサイズ | ランタイム3,260 / creation 3,473バイト | 2026-10-21 |
| Marketのテストの数 | 104個が通過 | 2026-10-21 |
| selfdestructのルール | Cancun以降はイーサだけを送り、同じトランザクションで作ったコントラクトだけを消す（EIP-6780） | 2026-10-21 |
| Parityのマルチシグ | 2017 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| バージョンを変えるときに初期化をもう一度呼ぶ形（reinitializer） | [第256講](../../part20/lecture256/) |
| ロック（ReentrancyGuard）をいつ足すか | [第182講](../../part11/lecture182/)、[第183講](../../part11/lecture183/) |
| ライブラリ・依存コードを選ぶ運用 | [第181講](../../part11/lecture181/) |
| Parityのマルチシグ事件の経緯 | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| 管理者の鍵・アップグレードの鍵を誰がどう握るか | [第178講](../../part11/lecture178/) |
| 初期化のロック・アップグレード権限を監査で読む方法 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
