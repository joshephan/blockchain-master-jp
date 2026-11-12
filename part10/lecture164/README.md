# 第164講 初期化・スロットの衝突、そしてアップグレード可能 = 非中央集権ではない

第10部 標準とアップグレード・第42章 アップグレードのパターン

[← 第163講](../../part10/lecture163/) | [第10部 目次](../) | [第165講 →](../../part11/lecture165/)

## この講義の問い

プロキシの後ろの実装に替えるとき、コンストラクタとスロットの配置はどう扱うべきで、アップグレードできるという事実は、そのコントラクトを誰を信じて使うものにするのか。

## 実習資料

### 準備

プロジェクトは三つある。`demo`は、コンストラクタと初期化関数（CtorBox、InitBox、LockedInitBox、ShadowInit）、バージョン間のスロットの配置（LedgerV1と次のバージョンたち、LedgerAt）、第160講のSlotProxyのコピー、OpenZeppelinのプロキシをビルドに入れるDeploy.sol、Marketのソースのコピー（`src/market/`）を置いたデモ用プロジェクトである。`e7576`は、0.8.30に`erc7201`の組み込み関数がないことを見るファイル一つである。`market`は通しプロジェクトMarketの第164講のバージョン（第42章末のバージョン）である。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0（Initializable、ERC1967Proxy、TransparentUpgradeableProxy、ProxyAdmin）である。OpenZeppelinのコードはここには載せていない。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。アカウントはanvilの既定のテスト用アカウント0〜3番をunlockedで使った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/Init.sol](code/demo/src/Init.sol) | コンストラクタで値を入れるCtorBox、初期化関数を置いたInitBox（initializer、reinitializer(2)）、コンストラクタで実装をロックしたLockedInitBox |
| [code/demo/src/Shadow.sol](code/demo/src/Shadow.sol) | 初期化関数の引数の名前が状態変数と同じShadowInit |
| [code/demo/src/Layouts.sol](code/demo/src/Layouts.sol) | LedgerV1と次のバージョン三つ（真ん中に挟む、最後に付ける、親に変数）、`layout at`で開始の欄を移したLedgerAt、その行を抜かしたLedgerAtForgot |
| [code/demo/src/SlotProxy.sol](code/demo/src/SlotProxy.sol) | 第160講のSlotProxyのコピー（バージョン間のスロットのデモ用） |
| [code/demo/src/Deploy.sol](code/demo/src/Deploy.sol) | OpenZeppelinのプロキシを`forge create`でデプロイするためにimportだけをしたファイル |
| [code/demo/src/market/](code/demo/src/market/) | Marketのsrcの五つのファイルのコピー（Transparentプロキシの後ろに置いたMarketのデモ用） |
| [code/demo/test/Init.t.sol](code/demo/test/Init.t.sol) | ShadowInit、コンストラクタの値がプロキシにない、Initializableの欄がERC-7201の値かのテスト三つ |
| [code/e7576/foundry.toml](code/e7576/foundry.toml) | solc 0.8.30、evm osaka |
| [code/e7576/src/E.sol](code/e7576/src/E.sol) | `erc7201("example.main")`を呼ぶファイル（0.8.30ではError 7576） |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第164講のバージョンのsrcの五つのファイル。コードは第163講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/Upgrade.t.sol](code/market/test/Upgrade.t.sol) | 第164講で足したUpgradeTestの二つ（アップグレードでimmutableの管理者が変わる、プロキシの後ろのスロットの地図） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

CtorBoxとそのプロキシ（OpenZeppelinのERC1967Proxy、空の初期化データ）。コンストラクタはCtorBoxをデプロイしたときにCtorBoxのストレージで一度動き、プロキシには値がない。出力は元の実行結果の文字列だけを訳したもの：

```
--- コンストラクタ
CtorBox 0x5FbDB2315678afecb367f032d93F642f64180aa3 owner 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 value 42
proxy(CtorBox) 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 owner 0x0000000000000000000000000000000000000000 value 0
```

```
[PASS] test_ctorValuesNotInProxy() (gas: 208917)
```

初期化なしで作ったプロキシは、先に呼んだ人が持ち主になる。プロキシを作ったのはアカウント0番だが、アカウント2番が先にinitializeを呼んだ。init slotはInitializableが初期化したかどうかを書く欄（0xf0c5…6a00）で、32バイトの値の真ん中を縮めた。出力は元の実行結果の文字列だけを訳したもの：

```
--- 初期化関数
InitBox 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
proxy no init 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 148540 owner 0x0000000000000000000000000000000000000000 init slot 0x0000…0000
acct2 initialize(acct2) (1, 73791)
acct0 initialize(acct0) (0, 29609) Error: execution reverted: InvalidInitialization
 owner 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC init slot 0x0000…0001
```

初期化のcalldataをERC1967Proxyのコンストラクタに入れると、プロキシの作成と初期化がトランザクション一つになる：

```
$ cast calldata "initialize(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
0xc4d66de8000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266

proxy with init 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 197302 owner 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

ロックしていないInitBoxの実装のアドレスに直接initializeを呼ぶと、アカウント3番が実装の持ち主になる：

```
impl InitBox initialize(acct3) directly (1, 68832) impl owner 0x90F79bf6EB2c4f870365E785982E1f101E93b906
```

コンストラクタで`_disableInitializers()`を呼んだLockedInitBox。実装の欄はuint64の最大値なので実装では初期化が止められ、プロキシの欄は1である：

```
LockedInitBox 0x0165878A594ca255338adfa4d48449f69242Eb8F init slot 0x000000000000000000000000000000000000000000000000ffffffffffffffff
 initialize on impl (0, 24497) Error: execution reverted: InvalidInitialization
 proxy(LockedInitBox) with init owner 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 proxy init slot 0x0000…0001
```

初期化データを入れて作ったプロキシにinitializeV2(5)（reinitializer(2)）を呼ぶと欄が1 → 2になり、二回目は止められる：

```
reinitializer(2) on p2 (1, 56072) fee 5 slot 0x0000…0002
 again (0, 29083) Error: execution reverted: InvalidInitialization
 InvalidInitialization sel 0xf92ee8a9
```

ShadowInitは引数の名前が状態変数と同じなので、警告とlintの1行でビルドが終わる（`forge build --offline`）：

```
Compiler run successful with warnings:
Warning (2519): This declaration shadows an existing declaration.
 --> src/Shadow.sol:9:25:
warning[uninitialized-state]: state variable is read but never written
  ╭▸ src/Shadow.sol:6:5
```

プロキシの後ろのownerは0のアドレス、doneはtrueで、もう一度呼ぶと`done`で巻き戻る。ERC1967ProxyにもShadowInitにもアップグレードの関数がないので、直す道がない：

```
[PASS] test_shadowedInitializeLeavesOwnerEmpty() (gas: 288602)
```

四つのバージョンのstorageLayout（`forge inspect --offline src/Layouts.sol:<バージョン> storageLayout`、四つともオフセット0）。LedgerV2ParentのcreatedAtは親のStampから継承した変数である：

| バージョン | スロット0 | スロット1 | スロット2 |
|---|---|---|---|
| LedgerV1 | owner | total | なし |
| LedgerV2Insert | owner | fee | total |
| LedgerV2Append | owner | total | fee |
| LedgerV2Parent | createdAt | owner | total |

SlotProxyの後ろでLedgerV1にsetup(アカウント1番, 1000)をしたあと、管理者のアカウント0番がupgradeToでバージョンを順に替えた結果。最後に付けたV2Appendだけが古い値を正しい名前で読む。V2ParentのcreatedAtはアカウント1番のアドレスを数として読んだ値で、ownerは0x3e8（1000）である。出力は元の実行結果の文字列だけを訳したもの：

```
--- バージョン間のスロット
V1 setup(acct1, 1000) (1, 71383)
 slots 0,1,2 0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8 0x00000000000000000000000000000000000000000000000000000000000003e8 0x0000000000000000000000000000000000000000000000000000000000000000
-> V2Insert owner 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 fee 1000 total 0
-> V2Append owner 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 total 1000 fee 0
-> V2Parent createdAt 642829559307850963015472508762062935916233390536 [6.428e47] owner 0x00000000000000000000000000000000000003e8 total 0
```

| | DBのテーブル | コントラクトのストレージ |
|---|---|---|
| 値を探す基準 | カラムの名前 | スロット番号 |
| 真ん中に一つ挟むと | 古い値はそのまま | 後ろの変数が古い値を読む |
| 名前が残るところ | スキーマ | コンパイルの成果物（storageLayout）、チェーンにはない |

ERC-7201の公式`keccak256(keccak256(id) - 1) & ~0xff`で計算した開始の欄（`cast keccak`で2回ハッシュ、keccakの列は真ん中を縮めた）。example.mainの値はERC-7201の例の73〜75行の値と同じで、openzeppelin.storage.Initializableの値はInitializable.solの77行の定数と同じである：

```
example.main keccak 0xb0ae…3425 erc7201 0x183a6125c38840424c4a85fa12bab2ab606c4b6d0e7cc73c0c06ba5300eab500
openzeppelin.storage.Initializable keccak 0xaa9e…ec0e erc7201 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00
course.ledger keccak 0x1ec7…8805 erc7201 0x5faaca7103cb5180a377ac4272c65fac3890b581a0bebb7fd617513a33dc9f00
```

`e7576`で`forge build --offline`。0.8.30には`erc7201`の組み込み関数がないので（文書v0.8.36にはある）、計算した値を数で書かなければならない：

```
Error: Compiler run failed:
Error (7576): Undeclared identifier.
 --> src/E.sol:6:13:
```

`layout at 0x5faa…9f00`で開始の欄を移したLedgerAt。値はその欄と次の欄に入り、スロット0は空である（storageLayoutのスロットの列は43271481816058234514150855041809414722784706254913814370102195584276170055424、…425）：

```
--- layout at
LedgerAt setup (1, 71384) owner 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 total 1000
 slot AT 0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8 AT+1 0x00000000000000000000000000000000000000000000000000000000000003e8 slot0 0x0000000000000000000000000000000000000000000000000000000000000000
```

次のバージョンが`layout at`の行を抜かすと、スロット0・1を読むので値が0に見える：

```
-> Forgot owner 0x0000000000000000000000000000000000000000 total 0
```

Transparentプロキシの後ろに置いたMarket（実装1：Market(アカウント0番, 5e16, 80)、デモのバージョンはoptimizerオフ、ProxyAdminの持ち主はアカウント0番）。初期化なしでimmutableの三つが読める：

```
--- Market behind Transparent proxy
MockToken 0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f
Market impl 1 0x4A679253410272dd5232B3Ff7cF5dbB88f295319 1645279
TUP 0x7a2088a1bFc9d81c55368AE168C2C02570cB814F 1051287 ProxyAdmin 0xdc17c27ae8be831af07cc38c02930007060020f4
 via proxy admin()(address) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 via proxy status()(uint8) 0
 via proxy interestRate()(uint256) 50000000000000000 [5e16]
 via proxy collateralRatio()(uint8) 80
 via proxy assetCount()(uint256) 0
```

帳簿とトークンはプロキシのアドレスにあり、実装のアドレスの帳簿は空である。アカウント2番のsetStatusはNotAdminである：

```
 addAsset 75 via proxy (1, 98775)
 deposit 100 via proxy (1, 135523)
 positions via proxy 100 0 1792475904 [1.792e9] false
 token balance proxy 100 impl 0
 impl assetCount 0 impl admin 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 acct2 setStatus 2 via proxy (0, 26951) Error: execution reverted: NotAdmin(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
```

同じソースでコンストラクタの引数だけが違う実装2（アカウント2番、9e16、80）に、アカウント0番がProxyAdmin.upgradeAndCallを一度呼ぶと、プロキシのコードは同じなのにadminと利率が変わり、帳簿はそのままである：

```
Market impl 2 (admin acct2, rate 9e16) 0x67d269191c92Caf3cD7723F116c85e6E9bf55933
 upgradeAndCall (1, 39524)
 proxy code same True impl 0x67d269191c92caf3cd7723f116c85e6e9bf55933
 via proxy admin 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC interestRate 90000000000000000 [9e16] assetCount 1 totalDeposits 100
```

アップグレードのあとは、アカウント0番ではなくアカウント2番が管理者である。アカウント2番がFrozen(2)をかけると、100を預けたアカウント0番は30も引き出せない：

```
 acct0 setStatus 2 (0, 26951) Error: execution reverted: NotAdmin(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
 acct2 setStatus 2 (1, 50786)
 acct0 withdraw 30 (0, 29561) Error: execution reverted: MarketFrozen
```

`market`で`forge test --offline --match-contract UpgradeTest -vvvv`。テスト用のSlotProxy（管理者0xAD）の後ろで実装をMarket(0xB0B, 9e16, 80)に替えると、adminが0xB0Bに変わり、帳簿の100は残る。プロキシのスロット0はstatus、1はassetsの長さ、keccak(トークン, 4)はtotalDepositsである：

```
[PASS] test_slotMapSameBehindProxy() (gas: 63559)
[PASS] test_upgradeSwapsImmutableAdmin() (gas: 102924)
```

Market第164講のバージョンの点検：`forge build --offline --force --sizes`でMarket 3,260 / 3,473、`forge test --offline`と`FOUNDRY_PROFILE=debug`・`legacy`はいずれも97個が通過、`.gas-snapshot` 97行、`bash ci.sh`は`ci ok`。

第42章末のMarketのアップグレードの判断記録：

| 講義 | 検討した形 | Marketで測ったもの | 判断 | 確認するテスト |
|---|---|---|---|---|
| 160 | プロキシの後ろに置く（EIP-1967のスロットのプロキシ） | immutableの三つ（admin・interestRate・collateralRatio）は実装のコードから、帳簿（スロット0〜5）はプロキシのストレージから。コンストラクタがストレージに書く値がないので、初期化なしで動く | 検討中 | test/Proxy.t.sol |
| 161 | Transparentプロキシ（OpenZeppelin 5.4.0） | Marketのセレクタ十九とプロキシのアップグレードのセレクタの重なりなし。プロキシの管理者のコントラクト（ProxyAdmin）とその持ち主の鍵が新しくできる、デプロイ1,051,299ガス（デモのバージョン） | 取り入れない（管理者の鍵がもう一つできる） | test/ProxySelectors.t.sol |
| 162 | UUPS（OpenZeppelin 5.4.0） | MarketにproxiableUUID・upgradeToAndCallなし。取り入れるならABIが関数二つ以上増え、IMarketのID 0xab691738・Docsのテスト（19）・Selectorsが変わり、バージョンごとにアップグレードの関数と権限の関数を残さなければならない | 取り入れない | test/Uups.t.sol |
| 163 | ダイヤモンド（EIP-2535） | ランタイム3,260バイト、上限24,576の13%。関数十九が一つのコード、分けるファセットなし | 取り入れない | test/Size.t.sol |
| 164 | 初期化・バージョン間のスロット・アップグレードの権限 | プロキシの後ろで実装を替えるとimmutableのadmin・interestRateが変わり、帳簿は残る。第151講の「移す関数なし」が、アップグレードの鍵一つにかかった言葉になる | プロキシを置かない。直したバージョンは新しいアドレスに新しくデプロイし、預けた人がwithdrawで引き出して移す | test/Upgrade.t.sol |

第42章でMarketに足したテストは88 + 9 = 97個である（Proxyの二つ、ProxySelectorsの二つ、Uupsの二つ、Sizeの一つ、Upgradeの二つ）。srcのコードは第41章末のバージョンのままで、Market.solにはバージョン説明のコメントを5行足しただけである。

### 試すときの注意

- プロキシは実装のコンストラクタを動かさない。`uint256 public value = 42;`の形の初期値もコンストラクタの中に入るので、プロキシにはない。
- 初期化関数は先に呼んだ人が持ち主になる。プロキシを作るトランザクションの中で初期化のcalldataを一緒に渡し、実装はコンストラクタで`_disableInitializers()`によってロックする。
- 新しいバージョンは、古いバージョンの状態変数の順番をそのままにして最後にだけ付ける。真ん中に挟んだり親に変数を足したりすると、古い値が別の名前で読まれる。
- solc 0.8.30では`layout at`は使えるが（0.8.29から）、`erc7201`の組み込み関数はない。開始の欄の値を計算して数で書く。`layout at`はtransientの変数には影響しない。
- このデモのTransparentUpgradeableProxyのデプロイのガス1,051,287は、第161講のデモの1,051,299と12違う。プロジェクトごとにコンパイルし直した作成コードのメタデータのハッシュの中に、00のバイトが一つ多いからである。
- Market第164講のバージョンはプロキシを置かない。直したバージョンは新しいアドレスにデプロイし、預けた人が古いバージョンからwithdrawで引き出して、新しいバージョンに預け直す。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・ライブラリ・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ用プロジェクトはoptimizerオフ（Foundryの既定値）・evm osaka。Market第164講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | 2026-10-20 |
| Solidityの文書とコンパイラ | 文書はv0.8.36（custom-storage-layout.rst、value-types.rst、units-and-global-variables.rst）。`erc7201`の組み込み関数は0.8.30にない（Error 7576）、`layout at`は0.8.29からなので0.8.30で使える | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| EIPの原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（erc-1822 319行 Stagnant、erc-2535 435行 Final、erc-7201 99行 Final）。最後の行はCC0 | 2026-10-19 |
| ファイルの最終更新のコミットの日付 | erc-1822・erc-2535 2023-10-25、erc-7201 2024-04-23 | 2026-10-19 |
| OpenZeppelin Contracts | 5.4.0（package.json）、MIT。Initializable.solの冒頭のコメント"last updated v5.3.0" | 2026-10-20 |
| ERC-7201の値 | example.main 0x183a6125…eab500、openzeppelin.storage.Initializable 0xf0c57e16…9c6a00、course.ledger 0x5faaca71…dc9f00 | 2026-10-20 |
| デモのガス（optimizerオフのデモ用ビルド、ローカルのanvil） | 初期化なしで作ったプロキシ148,540、initialize 73,791、初期化データを入れたプロキシ197,302、実装に直接initialize 68,832、initializeV2 56,072、V1のsetup 71,383、LedgerAtのsetup 71,384、Marketの実装1のデプロイ1,645,279、TransparentUpgradeableProxy 1,051,287（ProxyAdminの作成を含む。第161講のデモの1,051,299との12の差はメタデータのハッシュの中の00のバイト一つ）、addAsset 75 98,775、deposit 100 135,523、upgradeAndCall 39,524、setStatus 2 50,786 | 2026-10-20 |
| 委任1回の費用 | 同じ欄の書き換えを基準に4,900〜5,000ガス（第160〜163講のデモのバージョン） | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第164講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ | 第164講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931、上限24,576 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第164講のバージョンdefault `408088f5` | 2026-10-20 |
| テストのガス | UpgradeTest test_slotMapSameBehindProxy 63,559、test_upgradeSwapsImmutableAdmin 102,924。RebuildTest:test_recordedLogsIncludeReverted 155,244（バージョンによって155,232） | 2026-10-20 |
| 120バイトを超える行（src） | 第159講のバージョン92、第164講のバージョン97 | 2026-10-20 |
| 行番号 | 第164講のバージョンdebugのdeposit 0 src/Market.sol 176:33、NotActiveの行91、`contract Market` 220行。バージョン説明のコメントが変わると変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| アップグレードの鍵を複数の署名・時間の遅延・ガバナンスで縛ること | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/)、[第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |
| アップグレードの鍵を失ったり奪われたりした実際の事件 | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/)、[第179講](../../part11/lecture179/) |
| selfdestructのあと同じアドレスに別のコードを載せる攻撃 | [第180講](../../part11/lecture180/) |
| 他人の初期化のトランザクションを見て先に呼ぶこと | [第172講](../../part11/lecture172/)、[第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/) |
| 監査で新しいバージョンの配置が古いバージョンを引き継いでいるかをツールで確認すること | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| キャップストーンでアップグレードするかどうかを最初から決め直すこと | [第256講](../../part20/lecture256/) |
| 7つの層の分析のうちアップグレードの鍵の層 | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
