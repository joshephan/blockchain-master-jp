# 第160講 プロキシの原理とdelegatecallのつながり

第10部 標準とアップグレード・第42章 アップグレードのパターン

[← 第159講](../../part10/lecture159/) | [第10部 目次](../) | [第161講 →](../../part10/lecture161/)

## この講義の問い

アドレスもコードも変わらないのに、同じアドレスから違う動作が出てくるようにする構造は何で、その動作を変えられるのは誰か。

## 実習資料

### 準備

プロジェクトは二つある。`demo`は、実装のアドレスをスロット0に置いたNaiveProxy、EIP-1967のスロットに置いたSlotProxy、実装のCounterV1・V2、EIP-1167の複製を作るCloneMakerを置いたデモ用プロジェクトである。テストファイルはなく、ローカルのanvilにデプロイして`cast`で呼んだ。`market`は通しプロジェクトMarketの第160講のバージョンである。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0（CloneMakerが使う`proxy/Clones.sol`）である。OpenZeppelinのコードはここには載せていない。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。アカウントはanvilの既定のテスト用アカウント0番・1番をunlockedで使った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/Counter.sol](code/demo/src/Counter.sol) | 実装のCounterV1（incは1ずつ、version 1、whoami）と同じ配置のCounterV2（incは10ずつ、version 2） |
| [code/demo/src/NaiveProxy.sol](code/demo/src/NaiveProxy.sol) | 実装のアドレスをスロット0、ownerをスロット1に置いたプロキシ |
| [code/demo/src/SlotProxy.sol](code/demo/src/SlotProxy.sol) | 実装・管理者のアドレスをEIP-1967のスロットに置いたプロキシ（状態変数なし、upgradeTo、Upgradedイベント） |
| [code/demo/src/CloneMaker.sol](code/demo/src/CloneMaker.sol) | OpenZeppelinのClonesでEIP-1167の複製を作り、CREATE2のアドレスを前もって計算する工場 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第160講のバージョンのsrcの五つのファイル。コードは第159講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/SlotProxy.sol](code/market/test/SlotProxy.sol) | 第160講で足したテスト用のプロキシ（デモのSlotProxyと同じコード、テストファイルではない） |
| [code/market/test/Proxy.t.sol](code/market/test/Proxy.t.sol) | 第160講で足したProxyTestの二つ（immutableは実装のコードから、帳簿はプロキシのストレージに） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

二つのコントラクトのスロットの配置（`forge inspect … storageLayout`）。別々にコンパイルされる二つのコントラクトが、どちらも0番のスロットから使う：

```
$ forge inspect src/NaiveProxy.sol:NaiveProxy storageLayout
| Name           | Type    | Slot | Offset | Bytes | Contract                      |
| implementation | address | 0    | 0      | 20    | src/NaiveProxy.sol:NaiveProxy |
| owner          | address | 1    | 0      | 20    | src/NaiveProxy.sol:NaiveProxy |

$ forge inspect src/Counter.sol:CounterV1 storageLayout
| Name  | Type    | Slot | Offset | Bytes | Contract                  |
| count | uint256 | 0    | 0      | 32    | src/Counter.sol:CounterV1 |
```

NaiveProxy（CounterV1）の前でincを1回。incはstatus 1で成功するが、`count += 1`がプロキシのスロット0の実装のアドレスを書き換え、末尾がaa3からaA4になる：

```
$ cast call $NAIVE "implementation()(address)"
0x5FbDB2315678afecb367f032d93F642f64180aa3
$ cast call $NAIVE "version()(uint256)"
1
$ cast send $NAIVE "inc()" --unlocked --from $ACC0
$ cast call $NAIVE "implementation()(address)"
0x5FbDB2315678AFECb367f032D93f642f64180aA4
$ cast storage $NAIVE 0
0x0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa4
```

その次のversionは、返したバイトが0個である。0x…0aA4にはコードがなく、コードのないアドレスへのアセンブリのdelegatecallは成功（1）で終わる：

```
$ cast call $NAIVE "version()(uint256)"
Error: could not decode output; did you specify the wrong function return data type?
Context:
- ABI decoding failed: buffer overrun while deserializing
$ cast call $NAIVE "version()"
0x
$ cast code 0x5FbDB2315678AFECb367f032D93f642f64180aA4
0x
```

EIP-1967のスロットの計算。`cast keccak`の値から1を引くと、末尾が…2bbd → …2bbc、…6104 → …6103でEIPの値と同じになる：

```
$ cast keccak eip1967.proxy.implementation
0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbd
$ cast keccak eip1967.proxy.admin
0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6104
```

SlotProxy（CounterV1、管理者はアカウント0番）の前でincを3回したあとの、二つのアドレスの欄。積もったのはプロキシのスロット0である：

```
$ cast call $PROXY "count()(uint256)"
3
$ cast call $V1 "count()(uint256)"
0
$ cast storage $PROXY 0
0x0000000000000000000000000000000000000000000000000000000000000003
$ cast storage $V1 0
0x0000000000000000000000000000000000000000000000000000000000000000
```

whoamiをプロキシ経由で呼ぶとaddress(this)はプロキシ、実装に直接呼ぶとCounterV1である。msg.senderはどちらもアカウント1番である：

```
$ cast call $PROXY "whoami()(address,address)" --from $ACC1
0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast call $V1 "whoami()(address,address)" --from $ACC1
0x5FbDB2315678afecb367f032d93F642f64180aa3
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

```
$ cast implementation $PROXY
0x5fbdb2315678afecb367f032d93f642f64180aa3
$ cast admin $PROXY
0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
```

upgradeToは、アカウント1番が送ると巻き戻り（status 0）、アカウント0番が送ると成功する：

```
$ cast call $PROXY "upgradeTo(address)" $V2 --from $ACC1
Error: execution reverted: not admin
$ cast send $PROXY "upgradeTo(address)" $V2 --unlocked --from $ACC0
```

アップグレードの前後。プロキシのコード（703バイト）は1バイトも変わらず、変わったのは実装のスロット一つである。count 4はアップグレードの前に送ったinc 4回である。ブロックの中の`#`で始まる行は説明のために付けた注記である：

```
# アップグレード前
$ cast keccak $(cast code $PROXY)      # 703バイト
0x78a8d241cce23d31beaf5814cab3fb16e5cf119a5abbd8e04874addfeeb8cdee
$ cast implementation $PROXY
0x5fbdb2315678afecb367f032d93f642f64180aa3
# アップグレード後
$ cast keccak $(cast code $PROXY)      # 703バイト
0x78a8d241cce23d31beaf5814cab3fb16e5cf119a5abbd8e04874addfeeb8cdee
$ cast implementation $PROXY
0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
$ cast call $PROXY "version()(uint256)"
2
$ cast call $PROXY "count()(uint256)"
4
$ cast send $PROXY "inc()" --unlocked --from $ACC0
$ cast call $PROXY "count()(uint256)"
14
```

Upgradedのログ二つ（`cast logs`、行の一部は省略。topic0は`cast keccak "Upgraded(address)"`）：

```
$ cast logs --from-block 0 --address $PROXY 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b
- address: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  blockNumber: 5
  topics: [
  	0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b
  	0x0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3
  ]
- address: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  blockNumber: 13
  topics: [
  	0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b
  	0x000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f0512
  ]
```

0でない同じ欄を書き換えるincは、CounterV1に直接だと26,417、SlotProxyを経由すると31,290である（4,873多い）。

CloneMakerのmake(CounterV1)で作った複製のコード。45バイトで、真ん中の20バイトがCounterV1のアドレスである：

```
$ cast code $CLONE
0x363d3d373d3d3d363d735fbdb2315678afecb367f032d93f642f64180aa35af43d82803e903d91602b57fd5bf3
```

複製に送ったincとupgradeTo。複製のcountは1、CounterV1のcountは先に直接送ったinc 2回の2である。upgradeToは複製にもCounterV1にもないので、データなしに巻き戻る：

```
$ cast send $CLONE "inc()" --unlocked --from $ACC0
$ cast call $CLONE "count()(uint256)"
1
$ cast call $CLONE "upgradeTo(address)" $V2
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call $V1 "count()(uint256)"
2
```

saltで前もって計算したアドレス。predictの値とmakeAtで作ったアドレスが同じで、同じsaltで二つ目を作るとそのアドレスにすでにコードがあるので巻き戻る。実装のアドレスが違えば複製のアドレスも違う。`# Clonedのログのアドレス:`の行は、送ったトランザクションのログから読んで付けた注記である：

```
$ cast call $MAKER "predict(address,bytes32)(address)" $V1 0x000000000000000000000000000000000000000000000000000000000000002a
0x1d9b2f526682c83167EFc0981F23eD7359C22FBf
$ cast send $MAKER "makeAt(address,bytes32)" $V1 0x…2a --unlocked --from $ACC0
# Clonedのログのアドレス: 0x1d9b2f526682c83167efc0981f23ed7359c22fbf
$ cast call $MAKER "makeAt(address,bytes32)" $V1 0x…2a
Error: execution reverted: FailedDeployment
$ cast call $MAKER "predict(address,bytes32)(address)" $V2 0x…2a
0x09D44308aF7BecFC565D4697Ce044B52aC938c3C
```

| | SlotProxy | 複製（EIP-1167） |
|---|---|---|
| 実装のアドレス | 実装のスロット（ストレージ） | ランタイムコードのバイト |
| アップグレード | 管理者がupgradeTo | 方法なし |
| プロキシのコード | 703バイト | 45バイト |

`market`で`forge test --offline --match-contract ProxyTest -vvvv`（行の一部は省略）。Marketをテスト用のSlotProxyの後ろに置くと、immutableの三つは実装のコードから出てきて、プロキシのスロット0は0である。depositした帳簿はプロキシのストレージ（totalDepositsの欄keccak256(トークン, 4)）に100として積もり、実装のアドレスのassetCountは0である：

```
[PASS] test_immutablesFromImplementationCode() (gas: 42266)
    ├─ [5406] SlotProxy::fallback() [staticcall]
    │   ├─ [548] Market::admin() [delegatecall]
    │   │   └─ ← [Return] ProxyTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]
    ├─ [0] VM::load(SlotProxy: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0x0000…0000) [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
[PASS] test_ledgerLivesInProxy() (gas: 270222)
    ├─ [132376] SlotProxy::fallback(MockToken: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 100)
    │   ├─ [105943] Market::deposit(MockToken: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 100) [delegatecall]
    │   │   ├─ [29804] MockToken::transferFrom(ProxyTest: [0x7FA9…1496], SlotProxy: [0x2e23…470b], 100)
    ├─ [0] VM::load(SlotProxy: [0x2e23…470b], 0xd518eb0c450b7cb6cde9c89785309342131a13b97904292f190d4079230ea42c) [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000064
    ├─ [2586] Market::assetCount() [staticcall]
    │   └─ ← [Return] 0
```

| 値 | 出てくるところ | テストで見た値 |
|---|---|---|
| admin・interestRate・collateralRatio | 実装のコード（immutable） | テストのコントラクト、5e16、80。プロキシのスロット0は0 |
| 帳簿（スロット0〜5） | プロキシのストレージ | totalDepositsの欄keccak256(トークン, 4)に100 |
| トークンの残高 | プロキシのアドレス | 100 |
| Marketの実装のアドレスの帳簿 | 実装のストレージ | assetCount 0、totalDeposits 0 |

Market第160講のバージョンの`bash ci.sh`（行の一部は省略）：

```
| Market        | 3,260            | 3,473             | 21,316             | 45,679              |
Ran 32 test suites in 36.29ms (31.61ms CPU time): 90 tests passed, 0 failed, 0 skipped (90 total tests)
ci ok
```

第160講で新しく始めたMarketのアップグレードの判断記録の最初の行：

| 講義 | 検討した形 | Marketで測ったもの | 判断 | 確認するテスト |
|---|---|---|---|---|
| 160 | プロキシの後ろに置く（EIP-1967のスロットのプロキシ） | immutableの三つ（admin・interestRate・collateralRatio）は実装のコードから、帳簿（スロット0〜5）はプロキシのストレージから。コンストラクタがストレージに書く値がないので、初期化なしで動く | 検討中 | test/Proxy.t.sol |

### 試すときの注意

- プロキシが自分の変数を0番のスロットに置くと、実装のコードが自分の変数の順番どおりにその欄を上書きする。EIP-1967は、コンパイラが使わないスロット（文字列のハッシュから1を引いた値）に実装・管理者のアドレスを置く。
- アセンブリのdelegatecallは、相手のアドレスにコードがあるかを確認しない。コードのないアドレスに行くと何のコードも動かずに成功（1）で終わり、プロキシは空のデータをそのまま返す。
- `cast implementation`・`cast admin`はEIP-1967のスロットを読む。管理者が誰かはソースではなくスロットにだけある。
- テスト用のtest/SlotProxy.solはtestフォルダにあるが、テストファイルではない。デモのSlotProxyとは冒頭のコメントだけが違う。
- Marketのコンストラクタはimmutableの三つだけを決めてストレージには書かないので、プロキシの後ろに置いても初期化なしで動く。第160講のバージョンのMarketはプロキシなしでデプロイする。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ用プロジェクトはevm_version osaka、optimizerは既定値（オフ）。Market第160講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3（Commit `cae51ad`） | 2026-10-20 |
| Solidityの文書のバージョン | v0.8.36。introduction-to-smart-contracts.rst 547〜554（delegatecall）、units-and-global-variables.rst 286〜288（`<address>.delegatecall`）、320〜324（配置が合っていなければならない）。講義のコンパイラは0.8.30 | 2026-10-20 |
| EIPの原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`。ERC-1967 Final（created 2019-04-24）、ERC-1167 Final（created 2018-06-22）。二つのファイルの最終更新2023-10-25。行番号：1967 14・16・21・23・30・36〜37・42・71〜74・94・102、1167 14・22・31・32 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（`package.json`）。`contracts/proxy/Proxy.sol` 22〜45 `_delegate`、`contracts/proxy/Clones.sol` clone・cloneDeterministic・predictDeterministicAddress | 2026-10-20 |
| デモのガス（ローカルのanvil） | CounterV1・V2のデプロイ各167,647、NaiveProxyのデプロイ287,527、NaiveProxyのinc 29,375、SlotProxyのデプロイ256,722、プロキシのinc 48,390 / 31,290 / 31,290、CounterV1に直接inc 43,517 / 26,417、upgradeTo アカウント1番 24,285（巻き戻し）・アカウント0番 30,172、CloneMakerのデプロイ365,643、make 64,567、複製のinc 46,180、makeAt 64,924。同じ欄の書き換え：直接26,417 / プロキシ31,290 | 2026-10-20 |
| デモのアドレス（ローカルのanvil） | CounterV1 `0x5FbDB2315678afecb367f032d93F642f64180aa3`、CounterV2 `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、NaiveProxy `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、SlotProxy `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、CloneMaker `0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82`、複製`0x32467b43bfa67273fc7ddda0999ee9a12f2aaa08`、salt 0x…2aの複製`0x1d9b2f526682c83167EFc0981F23eD7359C22FBf` | 2026-10-20 |
| SlotProxyのコード | ランタイム703バイト、keccak `0x78a8d241cce23d31beaf5814cab3fb16e5cf119a5abbd8e04874addfeeb8cdee`（アップグレードの前後で同じ）。Upgradedのtopic0 `0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b` | 2026-10-20 |
| サイズ | 第160講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第160講のバージョンdefault `dc45e3be`（第159講のバージョン`1322ba3a`） | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第160講のバージョン デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264。MockToken `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Market `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` | 2026-10-20 |
| テストのガス（.gas-snapshot） | `ProxyTest:test_immutablesFromImplementationCode() (gas: 42266)`、`ProxyTest:test_ledgerLivesInProxy() (gas: 270222)`、90行 | 2026-10-20 |
| 行番号 | 第160講のバージョンdebugのdeposit 0 src/Market.sol 172:33、NotActive 87、`contract Market` 216。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | anvilのアカウント0番`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`、1番`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`（anvilの既定のテスト用アカウント、unlockedのアカウントで送る）。テストのコントラクト`0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496`、テスト用のプロキシの管理者0xAD | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| プロキシ自身の関数と実装の関数のセレクタの重なり、管理者とユーザーの呼び出しを分けるプロキシ | [第161講](../../part10/lecture161/) |
| アップグレードの関数を実装の側に置く形（UUPS） | [第162講](../../part10/lecture162/) |
| セレクタごとに違う実装へ送るプロキシ（ダイヤモンド） | [第163講](../../part10/lecture163/) |
| コンストラクタの代わりの初期化関数、バージョン間の状態変数の順番とスロットの衝突 | [第164講](../../part10/lecture164/) |
| 実装のアドレスを複数のプロキシが一つの欄から一緒に読む形（Beacon、EIP-1967の55・61行） | [第256講](../../part20/lecture256/) |
| プロキシのイベント（Upgraded）を見張り、実装が変わったら知らせる監視 | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| アップグレードの鍵を複数の人に分けること | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/) |
| 同じ実装を呼ぶ複製の工場で市場をいくつも作ること | [第256講](../../part20/lecture256/) |
| 監査でプロキシが実装のアドレスを上書きする配置を探すこと | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
