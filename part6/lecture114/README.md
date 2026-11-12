# 第114講 コンストラクタの引数と初期化の順番

第6部 言語の詳細 ③ コントラクト・第25章 継承

[← 第113講](../../part6/lecture113/) | [第6部 目次](../) | [第115講 →](../../part6/lecture115/)

## この講義の問い

親がコンストラクタの引数を受け取るとき、子はその引数をどこに書いて渡し、デプロイのときに親と子の初期値・コンストラクタはどんな順番で動くのか。

## 実習資料

### 準備

第113講の終わりのMarketのプロジェクトから始め、`admin`をMarketBaseに、`collateralRatio`をAssetRegistryに移し、親のコンストラクタに引数を渡す。`setStatus`・`addAsset`も親に移す。コンストラクタの順番は、別に作ったデモ用のプロジェクト（`demo`）の`Ctor.sol`をローカルのanvilにデプロイしたレシートのログと、同じ順番を出力するテストを既定の設定と`--via-ir`で走らせたログで見る。ビルドが止める場合は、`errors/`の下のフォルダごとに別々にビルドする。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、既定（legacy）のコード生成で、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Ctor.sol](code/demo/src/Ctor.sol) | 名前と数字を`Step`イベントで出すTrace、コンストラクタの引数を受け取るBase、abstractのLeft・Right、コンストラクタの横に`Right(r_) Base(o)`を書いたTop、継承の行に引数を書いたFixed |
| [code/demo/test/Ctor.t.sol](code/demo/test/Ctor.t.sol) | `new Top(address(0xBEEF), 3)`のログを順に出力するCtorTest |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/errors/](code/errors/) | list_param（7576）、list_sender（`is Base(msg.sender)`、通る）、twice（3364）、none（3415）、abstract_new（4614） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第114講のバージョン。MarketBaseのコンストラクタ（`admin`）、abstractのAssetRegistryのコンストラクタ（`collateralRatio`）、abstractのLedger、Marketのコンストラクタ`MarketBase(admin_) AssetRegistry(collateralRatio_)` |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol)、[code/market/src/MockToken.sol](code/market/src/MockToken.sol) | インターフェースとテスト用のトークン |
| [code/market/test/Inherit.t.sol](code/market/test/Inherit.t.sol) | `test_constructorArgsReachBases`を追加。コンストラクタの引数が三つの親に入ったか |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト |

### 実行結果

親のコンストラクタの引数を書く場所（`forge build`、`errors/`）。

```
contract C is Base(o) { constructor(address o) {} }
Error (7576): Undeclared identifier.

contract C is Base(address(0xA11CE)) { constructor(address o) Base(o) {} }
Error (3364): Base constructor arguments given twice.

contract C is Base {}
Error (3415): No arguments passed to the base constructor. Specify the arguments or mark "C" as abstract.

abstract contract C is Base {}   // そしてnew C()
Error (4614): Cannot instantiate an abstract contract.
```

`contract C is Base(msg.sender) {}`はビルドでき、アカウント1番がデプロイすると`owner()`はアカウント1番である。

```
$ forge create --offline src/X.sol:C --rpc-url $R --unlocked --from $A1 --broadcast
Deployed to: 0x71C95911E9a5D330f4D621842EC243EE1343292e
$ cast call $S "owner()(address)" --rpc-url $R
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

Topのデプロイのレシートの七つのログ（`forge create`、`cast receipt`、`cast decode-abi`）。書いた順番（Right、Base）に関係なく、Base、Left、Right、Topの順に動く。

```
$ forge create --offline src/Ctor.sol:Top --rpc-url $R --unlocked --from $A0 --broadcast --constructor-args 0x000000000000000000000000000000000000BEEF 3
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
$ for d in $(cast receipt $TX logs --rpc-url $R | grep -o '"data":"0x[0-9a-f]*"' | cut -d'"' -f4); do cast decode-abi --input "f(string,uint256)" $d | tr '\n' ' '; echo; done
"Base var" 1
"Left var" 2
"Top var" 4
"Base ctor" 4
"Left ctor" 48879 [4.887e4]
"Right ctor" 3
"Top ctor" 4
```

Topの線形化の順番はTop、Right、Left、Base、Traceである（`forge build --ast`の`linearizedBaseContracts`）。コンストラクタはこの並びの後ろから動き、コンストラクタのないTraceは飛ばす。Left ctorの48879は、Baseのコンストラクタが先に入れた`owner`（0xBEEF）である。

Baseのコンストラクタが呼ぶ`hook()`を、Topが`r * 1000 + t`に書き直した。Base ctorの値4は`0 × 1000 + 4`で、Rightのコンストラクタが入れる`r`はまだ0である。

| | 進む方向 | Topでは |
|---|---|---|
| 状態変数のスロット | 基本の側から | Baseのbが0番 |
| コンストラクタ | 基本の側から | Base、Left、Right、Top |
| 関数の探索、`super` | 派生の側から | Top、Right、Left、Base |

同じテストを既定の設定と`--via-ir`で走らせると、初期値の順番が違う（`forge test -vv`、一部）。

```
$ forge test --offline --match-contract CtorTest -vv
[PASS] test_order() (gas: 48424)
Logs:
  Base var: 1
  Left var: 2
  Top var: 4
  Base ctor: 4
  Left ctor: 48879
  Right ctor: 3
  Top ctor: 4
$ forge test --offline --via-ir --match-contract CtorTest -vv
[PASS] test_order() (gas: 49568)
Logs:
  Base var: 1
  Base ctor: 0
  Left var: 2
  Left ctor: 48879
  Right ctor: 3
  Top var: 4
  Top ctor: 4
```

| | 既定のコード生成 | `--via-ir` |
|---|---|---|
| 状態変数の初期値 | 階層全体を基本の側から先に | コントラクトごとに |
| コンストラクタの本体 | 初期値が全部入ったあと、基本の側から | そのコントラクトの初期値のすぐあと |
| 親のコンストラクタが見た子の初期値 | 入っている | 0 |

Marketの第114講のバージョン。AssetRegistryから`abstract`を抜いたり、Marketのコンストラクタから`MarketBase(admin_)`を抜いたりすると、3415が出る。

```
Error (3415): No arguments passed to the base constructor. Specify the arguments or mark "AssetRegistry" as abstract.
   --> src/Market.sol:106:1:

Error (3415): No arguments passed to the base constructor. Specify the arguments or mark "Market" as abstract.
   --> src/Market.sol:213:1:
```

Marketのコンストラクタの横に書く順番を`AssetRegistry(collateralRatio_) MarketBase(admin_)`に変えても、サイズとテストは同じで、実行の順番もMarketBase、AssetRegistry、Ledger、Marketのままである。

```
$ forge build --offline --sizes
| Market     | 7,233            | 7,811             | 17,343             | 41,341              |
$ forge test --offline
Ran 12 test suites: 45 tests passed, 0 failed, 0 skipped (45 total tests)
```

スロットマップはそのままで、`admin`・`collateralRatio`・`interestRate`はimmutableなのでスロットがない（`forge inspect Market storageLayout`、一部の欄）。

```
| status        | enum MarketBase.MarketStatus                            | 0    | 0      | 1     |
| assets        | contract IERC20[]                                       | 1    | 0      | 32    |
| assetConfig   | mapping(address => struct AssetConfig)                  | 2    | 0      | 32    |
| positions     | mapping(address => mapping(address => struct Position)) | 3    | 0      | 32    |
| totalDeposits | mapping(address => Amount)                              | 4    | 0      | 32    |
| totalBorrows  | mapping(address => Amount)                              | 5    | 0      | 32    |
```

```
$ forge test --offline
Ran 12 test suites: 45 tests passed, 0 failed, 0 skipped (45 total tests)
$ forge test --offline --via-ir
Ran 12 test suites: 45 tests passed, 0 failed, 0 skipped (45 total tests)
```

管理者をアカウント1番にしてデプロイし、デプロイのトランザクションのinputの最後の三つの引数の値とランタイムコードを読む（`cast tx`、`cast abi-decode`、`cast call`、`cast storage`、`cast code`）。inputの7,907バイトは、デプロイのコード7,811バイトと引数96バイトである。

```
$ forge create --offline src/Market.sol:Market --rpc-url $R --unlocked --from $A0 --broadcast --constructor-args $A1 50000000000000000 80
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
$ IN=$(cast tx $TX input --rpc-url $R); echo $(( (${#IN}-2)/2 ))
7907
$ cast abi-decode --input "constructor(address,uint256,uint8)" 0x${IN: -192}
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
50000000000000000 [5e16]
80
$ cast call $M "admin()(address)" --rpc-url $R
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast storage $M 0 --rpc-url $R
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast codesize $M --rpc-url $R
7233
$ cast code $M --rpc-url $R | grep -o -i "70997970c51812dc3a010c7d01b50e0d17dc79c8" | wc -l
2
```

アカウント1番のアドレスの20バイトは、ランタイムコードの二か所（`admin`のゲッター、`_checkAdmin`）に入っている。継承の行にアドレスを書いたFixedは、誰がデプロイしても`owner()`が0xA11CEである。

| 書いた形 | ソースに見えるもの | owner |
|---|---|---|
| `is Base(address(0xA11CE))` | アドレスそのまま | 誰がデプロイしても0xA11CE |
| `is Base(msg.sender)` | `msg.sender` | デプロイしたアカウント |
| Marketの`MarketBase(admin_)` | 引数の名前 | デプロイの一つ目の引数 |

どの形でも、Marketには`admin`を変える関数がない。

| コントラクト | コンストラクタの引数 | abstract |
|---|---|---|
| MarketBase | `admin_` | 違う |
| AssetRegistry | `cap` | abstract（MarketBaseの引数を決めない） |
| Ledger | なし | abstract |
| Market | `admin_, interestRate_, collateralRatio_`を受け取って`MarketBase(admin_) AssetRegistry(collateralRatio_)` | 違う |

コンストラクタの順番：MarketBase（ZeroAdminの検査、admin） → AssetRegistry（collateralRatio） → Ledger（なし） → Market（interestRate）。

### 試すときの注意

- 子のコンストラクタが受け取った引数を親に渡すには、コンストラクタの横に書く。継承の行からは子のコンストラクタの引数が見えない（7576）。一つの親に両方の場所で書くと3364である。
- 親のコンストラクタの引数を誰も決めないコントラクトには`abstract`をつける。abstractのコントラクトは`new`で作れない（4614）。
- 親のコンストラクタが、子が書き直した関数を呼ぶと、子のコンストラクタが入れる値はまだ0である。子の初期値が入っているかどうかは、コンパイルの設定（既定 / `--via-ir`）によって違う。
- Marketには初期値をつけた状態変数がなく、コンストラクタで書き直せる関数を呼ばないので、二つの設定でテストの結果が同じである（45個が通る）。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンや実行環境が変わると、数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のコード生成（legacy）、比較用に`--via-ir` | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| Marketのサイズ | 第114講のバージョンのruntime 7,233 / initcode 7,811バイト（第113講のバージョン7,229 / 7,796）、MarketBaseの単体883 / 1,259、デプロイのinput 7,907バイト | 2026-10-19 |
| Marketのガス（第114講のバージョン） | デプロイのgasUsed 1,619,356、addAsset 75 93,730、deposit 100 130,376、withdraw 30 59,692、setStatus 1 45,732（第113講のバージョン45,761）、setStatus 0 23,820、失敗deposit 0 26,869（ガスリミット100,000） | 2026-10-19 |
| ガスの実測の条件 | バージョンごとに新しいanvil、ブロックの間隔1秒（`cast rpc anvil_setBlockTimestampInterval 1`）、MockToken・Marketのアドレス`0x5FbDB2315678afecb367f032d93F642f64180aa3`・`0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`。順番：デプロイ → addAsset → deposit → withdraw → setStatus 1 → setStatus 0 → 失敗deposit | 2026-10-19 |
| CtorTestのテストのガス | 既定の設定48,424、`--via-ir` 49,568 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `abstract`と本体のない関数、インターフェース | [第115講](../../part6/lecture115/) |
| スロット番号の規則の全体 | [第135講](../../part8/lecture135/) |
| 既定のコード生成とIRのコード生成の違いの全体 | [第133講](../../part8/lecture133/) |
| コンストラクタなしで後から初期化する構造、管理者の交代、アップグレード | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 管理者の権限と鍵を誰が握るかの分析 | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/)、[第179講](../../part11/lecture179/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
