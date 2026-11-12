# 第135講 ストレージのスロット配置の規則

第8部 コンパイラと内部構造・第33章 保存配置の内部

[← 第134講](../../part8/lecture134/) | [第8部 目次](../) | [第136講 →](../../part8/lecture136/)

## この講義の問い

一つの状態変数が何番のスロットの何番目のバイトに置かれるかは、どんな規則で決まり、その規則はどこまで固定されているのか。

## 実習資料

### 準備

通しプロジェクトMarketの第135講のバージョン（第134講のバージョンとコードが同じで、スロットの配置を`vm.load`で確かめる`test/Layout.t.sol`を足したバージョン）と、ドキュメントの例を集めたデモのプロジェクト（`demo`）を使う。solc 0.8.30、Foundry 1.8.3で、どちらのプロジェクトもforge-stdが必要である（`lib/forge-std`）。デモのプロジェクトはoptimizerを切り、evm_versionはosakaである。`layout at`のエラーを見るファイルは、solcを直接呼んで`solc --storage-layout --transient-storage-layout`で見る。ガスとMarketの欄の値は、ローカルのanvilにアカウント0番でデプロイして測る。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | default（optimizerは切る）と`[profile.ir]` |
| [code/market/src/Market.sol](code/market/src/Market.sol) | Market 第135講のバージョン（コードは第134講のバージョンと同じ、バージョンを説明するコメント1行） |
| [code/market/src/](code/market/src/) | IMarket・MarketMath・MarketTypes・MockToken |
| [code/market/test/Layout.t.sol](code/market/test/Layout.t.sol) | この講義で足したテスト三つ: assetsの長さと要素の欄、assetConfigの一つの欄に二つ、Positionの三つの欄 |
| [code/market/test/](code/market/test/) | プロジェクトのテスト15ファイル、テスト58個 |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモのプロジェクトの設定 |
| [code/demo/src/DocC.sol](code/demo/src/DocC.sol) | ドキュメントの例Cの原文（A、B、`C is A, B layout at 42`） |
| [code/demo/src/Layout135.sol](code/demo/src/Layout135.sol) | CFill（例Cを一つのコントラクトに展開して値を埋める）、Order1・Order2・NoBackfill、Packed・Wide、DocData、StrKey、Nested24、Str135、BadStr |
| [code/demo/test/Layout135.t.sol](code/demo/test/Layout135.t.sol) | スロットの値を`vm.load`で読んで出すテスト六つ |
| [code/solc/Wrap.sol](code/solc/Wrap.sol)、[Abs.sol](code/solc/Abs.sol)、[Mid.sol](code/solc/Mid.sol) | `layout at`のエラー三つを出すファイル（ビルドできないのが正常） |
| [code/solc/TrLayout.sol](code/solc/TrLayout.sol) | `layout at 100`とtransientの変数 |
| [code/solc/Erc.sol](code/solc/Erc.sol) | ドキュメントの`layout at erc7201("…")`の形。solc 0.8.30ではエラー |

### 実行結果

ドキュメントの例Cの`solc --storage-layout --transient-storage-layout src/DocC.sol`を表にまとめたもの。

| 変数 | slot | offset |
|---|---|---|
| a | 42 | 0 |
| e / f | 43 / 44 | 0 |
| g / h | 45 / 45 | 0 / 2 |
| s | 46 | 0 |
| k / l | 47 / 47 | 0 / 1 |
| m / n / o | 48 / 49 / 51 | 0 |

transientの側は、bが0番のオフセット0、iが0番のオフセット16で、ストレージの番号とは別に数える。A単独ではa 0、B単独ではe 0、f 1、g 2:0、h 2:2、s 3、k 4である。

デモのプロジェクトで`forge test --match-path test/Layout135.t.sol -vv`のtest_docCが出したCFillのスロット42〜51（2行を1行にまとめた）。

```
42  0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
43  0x0000000000000000000000000000000000000000000000000000000000000001
44  0x0000000000000000000000000000000000000000000000000000000000000000
45  0x0000000000000000000000000000000000000000000000000000000022221111
46  0x0000000000000000000000000000000000000000000000000000000133333333
47  0x00000000000000000000555555555555555555555555555555555555555555fe
48  0x0000000000000000000000000000000000000000000069686766656463626160
49  0x0000707070700570707070047070707003707070700270707070017070707000
50  0x0000000000000000000000000000000000000000000070707070077070707006
51  0x0000000000000000000000000000000000000000000000000000008888888888
```

同じテストの中の`tload(0)`は`0x99999999999999999999999999999999` + `0000000000000000000000000000bbbb`である。オフセット0は欄の右端（下位のバイト）である。

`forge inspect src/Layout135.sol:NoBackfill storageLayout`（Contractの列は省略）。

```
| a    | uint8   | 0    | 0      | 1     |
| b    | uint256 | 1    | 0      | 32    |
| c    | uint8   | 2    | 0      | 1     |
```

Order1（`uint128 a; uint256 b; uint128 c;`）は3欄、Order2（`uint128 a; uint128 c; uint256 b;`）は2欄である。コンパイラは順序を入れ替えて空きを埋めない。

Packed（uint128二つが一つの欄）とWide（uint256二つが二つの欄）を、anvilにバージョンごとに新しくデプロイして測ったgasUsed。

| | Packed | Wide |
|---|---|---|
| setA(7) SLOAD / SSTORE | 1 / 1 | 0 / 1 |
| setA(7) マスクの命令 | AND 3、NOT 1、OR 1、MUL 2、EXP 1 | なし |
| setA(7) 最初の書き込み | 43,820 | 43,762 |
| setA(7) 2回目・3回目の書き込み | 26,720 | 26,662 |
| setBoth optimizerを切る、最初 | 44,386 | 66,164 |
| setBoth optimizerを切る、2回目 | 27,286 | 31,964 |
| setBoth optimizerを入れる、最初 | 43,860 | 65,809 |

マッピング・動的配列・文字列の欄（同じテストのtest_docData・test_strKey・test_nested24・test_badStr）。

```
data[4][9]の開始の欄 keccak256(uint256(9) . keccak256(uint256(4) . uint256(1)))
0x27a93c3e7d03e75f149a36691115f591e714097122c43aa51fa243e8f7faf082
値  0x0000000000000000000000000000000000000000000000000000000000020001
+1  0x000000000000000000000000000000000000000000000000000000000000004d

keccak256(abi.encodePacked("abc", uint256(1)))   3 + 32 = 35バイト
0xac85c8cc1ac92e94a731b8df588044cbfd366c5ee08805d198cb1b094f3cacac   値 5
keccak256(abi.encode("abc", uint256(1)))         値 0

スロット0            …02    xの長さ
keccak256(0) + 1    …0c    x[1]の長さ12
keccak256(keccak256(0) + 1)       0x0000100009100008100007100006100005100004100003100002100001100000
keccak256(keccak256(0) + 1) + 1   0x000000000000000000000000000000000000000000000000000010000b10000a
formula x[1][11]: 1048587
getter x[1][11]: 1048587

poke(3)のあと
len revert   0x4e487b71…0022
read revert  0x4e487b71…0022
```

BadStrのPanic(0x22)は、`--via-ir`をつけても同じである。31バイトの文字列は、欄pにデータと末尾のバイト`3e`（31 × 2）が、32バイトの文字列は、欄pに`…41`（32 × 2 + 1）が、keccak256(p)にデータが置かれる。

`layout at`のエラー三つ（`solc --storage-layout <ファイル>`、位置の行は省略）。

```
contract Wrap layout at 2**256 - 2 { uint[3] x; }
Error: Contract extends past the end of storage when this base slot value is specified.

abstract contract Abs layout at 10 { uint x; }
Error: Storage layout cannot be specified for abstract contracts.

contract P layout at 10 { uint x; }
contract Q is P { uint y; }
Error: Cannot inherit from a contract with a custom storage layout.
```

TrLayout（`contract T layout at 100 { uint a; uint transient t; uint b; }`）は、ストレージのaが100、bが101、transientのtが0である。開始のスロットは、ストレージの番号だけを動かす。

anvilにMockTokenとMarketをデプロイし、addAsset 75 → deposit 100 → setStatus 1のあとに`cast storage`で読んだMarketの欄。

```
$ cast storage $MARKET 0     0x…01   status = 1（1バイト、オフセット0）
$ cast storage $MARKET 1     0x…01   assetsの長さ1
$ cast storage $MARKET 2     0x…00   assetConfig
$ cast storage $MARKET 3     0x…00   positions
$ cast storage $MARKET 4     0x…00   totalDeposits
$ cast storage $MARKET 5     0x…00   totalBorrows
```

| 変数 | 計算式 | 値 |
|---|---|---|
| assets[0] | keccak256(1) = 0xb10e…0cf6 | トークンのアドレス（20バイト、一つの欄に一つ） |
| assetConfig[トークン] | keccak256(トークン . 2) = 0x4ace…2070 | `0x…014b`: collateralRatio 0x4bがオフセット0、listed 01がオフセット1 |
| positions[トークン][アカウント0番] | keccak256(アカウント . keccak256(トークン . 3)) = 0x14ee…03a3 | +0 deposited 100、+1 borrowed 0、+2 lastUpdate（uint64、オフセット0）・useAsCollateral（bool、オフセット8） |
| totalDeposits[トークン] | keccak256(トークン . 4) | 100 |
| totalBorrows[トークン] | keccak256(トークン . 5) | 0 |

addAsset 75の1回でSSTOREが4回起き、そのうち二つがassetConfigの同じ欄（75 → 0x14b）である。構造体の1行の代入も、メンバーごとに別々に書く。

Market 第135講のバージョンのビルドとテスト。

```
$ forge build --offline --force --sizes
| Market      | 7,353            | 7,931             | 17,223             | 41,221              |
$ forge test --offline
Ran 17 test suites …: 58 tests passed, 0 failed, 0 skipped (58 total tests)
$ FOUNDRY_PROFILE=ir forge test --offline
Ran 17 test suites …: 58 tests passed, 0 failed, 0 skipped (58 total tests)
```

既定の経路・via-IR・optimizerを変えた四つのバージョンのstorageLayoutは、どれもstatus 0、assets 1、assetConfig 2、positions 3、totalDeposits 4、totalBorrows 5（オフセットはすべて0）である。

### 試すときの注意

- 状態変数は宣言の順に0番のスロットから置かれ、継承があればC3線形化の順でいちばん基本の親から番号を受け取る。残りのバイトが足りなければ次の欄に移り、前の欄の空きをあとの変数で埋めることはない。
- 同じ欄に入った値を一つ直すだけでも、欄全体を読み（SLOAD）、マスクで混ぜて書き直す。一緒に読んで一緒に書く値どうしをまとめてはじめて、ガスが減る。
- マッピングの欄は空で、値はkeccak256(h(k) . p)に置かれる。値型のキーは32バイトに埋め、string・bytesのキーは埋めないデータのまま入れる。
- constant・immutable・transientの変数はstorageLayoutにない。transientはtransientStorageLayoutで別に0番から数える。
- storageLayoutのastIdはビルドごとに違う（forgeのビルドでstatus 254、`solc --storage-layout src/Market.sol`単独で18）。スロットマップにはslot・offsetだけを書く。
- ドキュメントの例Cの説明の"each taking up 5 bytes"は実際と違う。int32 4バイト + bool 1バイトで構造体全体が5バイトで、図の`yxxxx`が正しい。
- ドキュメントは、間違って書かれた長い文字列の欄のPanic(0x22)を"If you are compiling via IR"とだけ書いているが、solc 0.8.30は既定の経路でも同じPanicを出す。
- ドキュメントの`layout at erc7201("…")`の組み込み関数は、solc 0.8.30にはない（`Error: Undeclared identifier.`）。同じ開始のスロットの値は、`cast index-erc7201 market.main`で計算できる。
- positionsの+2の欄のlastUpdateの値はブロックの時刻なので、回すたびに違う。デプロイのアドレスが同じなら、keccakで計算したスロットの番号は同じである。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30+commit.73712a01（直接呼ぶときのevm_versionの既定はprague）。`layout at`は0.8.29から、`erc7201(...)`の組み込み関数は0.8.30にない | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3、デモのプロジェクトのevm_versionはosaka、optimizerは切る | 2026-10-20 |
| ドキュメントの例Cの説明の文 | "each taking up 5 bytes"は実際と違う（int32 4バイト + bool 1バイト = 5バイト、図の`yxxxx`が正しい） | 2026-10-20 |
| 間違って書かれた長い文字列の欄 | ドキュメントはvia-IRだけを書いている、solc 0.8.30は既定の経路・via-IRのどちらでもPanic(0x22) | 2026-10-20 |
| storageLayoutのJSON | ドキュメントが形式を実験的と書いている（"still considered experimental"） | 2026-10-20 |
| SLOAD・SSTOREのガス | はじめて読む欄のSLOAD 2,100、0から0でない値へのSSTORE 20,000（はじめて触る欄なら + 2,100 = 22,100）、すでに0でない欄は2,900 / 5,000、同じトランザクションの2回目は100 | 2026-10-20 |
| 一つの欄への書き込みのガス | setA(7) Packed 43,820 / Wide 43,762、2回目・3回目26,720 / 26,662。setBoth optimizerを切る44,386 / 66,164、2回目27,286 / 31,964、optimizerを入れる43,860 / 65,809 | 2026-10-20 |
| Marketの欄の値 | トークン0x5FbDB2315678afecb367f032d93F642f64180aa3、Market 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512。keccak256(1) 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6、assetConfig 0x4ace221c3c265e8444dd224598300347d682bc5b143f1c7eaacaff6645692070 = 0x14b、positions[トークン][アカウント0番] 0x14eee92b0bcedb42b8bd88dd5d7d61652eb7c2c319a1e9771b7db7fe5e5903a3（+0 0x64、+1 0、+2 ブロックの時刻）、totalDeposits 0xa682d4351e4703267af382c1795a1188b87c4920f0c38d599cb6cba0b8fec1cb = 0x64、totalBorrows 0x39e1997aaec5046e387a0566fd32c016a185b967ebcf59dc34e22921e43b57aa = 0 | 2026-10-20 |
| Marketのガス | addAsset 75 93,730、deposit 100 130,478、setStatus 1 45,732 | 2026-10-20 |
| astId | forgeのビルドでstatus 254・assets 370・assetConfig 375・positions 518・totalDeposits 523・totalBorrows 528 / solc単独で18・134・139・282・287・292 | 2026-10-20 |
| ERC-7201の開始のスロット | `cast index-erc7201 market.main` = 0x250641b3369b28b9a894e0373e13cfcd244c4ea6849efaaad2a44b9d7f9ed600 | 2026-10-20 |
| 行番号 | 第135講のバージョンのdeposit 0のリバートはsrc/Market.sol 145:33。バージョンを説明するコメントが変わると変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| transientのスロット（同じ0番、トランザクションの終わりに0） | [第136講](../../part8/lecture136/) |
| メモリの配置 | [第137講](../../part8/lecture137/) |
| calldataの配置とクリーンアップ（cleanup） | [第138講](../../part8/lecture138/) |
| ABIエンコードとマッピングのキーのパディングの関係 | [第141講](../../part8/lecture141/) |
| 宣言の順序・まとめ方をガスで選ぶ判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 開始のスロット（`layout at`、ERC-7201）を使うアップグレードの構造とスロットの衝突 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| バージョンごとに変わるコンパイラの動作（`erc7201`の組み込み関数） | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 監査でスロットマップを使ってほかの人のコントラクトを読む | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/)、[第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
