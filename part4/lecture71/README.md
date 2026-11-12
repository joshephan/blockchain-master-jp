# 第71講 マッピングの保存の仕組みと走査できないこと

第4部 言語の詳細 ① ファイルと型・第15章 マッピング

[← 第70講](../../part4/lecture70/) | [第4部 目次](../) | [第72講 →](../../part4/lecture72/)

## この講義の問い

どんなキーを聞いても答えを返してくれる型は、ストレージに何を書き、何を書かないのか。そのため、ほかの言語のマップでできていたことのうち、何ができないのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクト（`demo/`）から、Counterのファイルを消して始める。コンパイルが拒否される例は、別のプロジェクト`bad/`に置く（foundry.tomlは同じ）。デプロイと送信は、ローカルのanvilで既定のアカウント（公開されたテスト用の鍵）を使って行う。アカウント100個で読み取りのガスを測る実習は、anvilを`--accounts 101`で立ち上げ、anvilのアカウントを`--unlocked --from`で使う。ビルドはすべて`--offline`である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/demo/src/Ledger.sol](code/demo/src/Ledger.sol) | `mapping(address => uint256) deposits`にイーサを預けて引き出す台帳 |
| [code/demo/src/Zeros.sol](code/demo/src/Zeros.sol) | 値型・構造体の値を持つマッピング四つ。使っていないキーはすべて0 |
| [code/demo/src/Keys.sol](code/demo/src/Keys.sol) | マッピングのキーとして許される型の一覧と、マッピングの中のマッピング、配列の値 |
| [code/demo/src/Named.sol](code/demo/src/Named.sol) | キー・値に名前をつけたマッピング（`mapping(address user => uint256 amount)`） |
| [code/demo/src/LedgerTotal.sol](code/demo/src/LedgerTotal.sol) | 預けたり引き出したりするたびに、合計の欄`totalDeposits`も一緒に直す台帳 |
| [code/demo/src/Assets.sol](code/demo/src/Assets.sol) | 資産の設定を比率一つで持つ版（AssetsNoFlag）と、`listed`の印を加えた版（AssetsListed） |
| [code/demo/src/Alias.sol](code/demo/src/Alias.sol) | マッピングをstorageの別名とinternal関数のパラメーターで渡して直す |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しのプロジェクトのMarket。資産の設定とユーザーごとのPositionをマッピングで持ち、合計の欄を置いた版。depositは欄の位置を見せるための最小の版（トークンを実際には受け取らない） |
| [code/bad/foundry.toml](code/bad/foundry.toml) | demoと同じ設定 |
| [code/bad/src/](code/bad/src/) | マッピングのキー・長さ・場所・代入・deleteが止められる例9個 |

`code/bad/src/`のファイルとエラー：

| ファイル | 行 | エラー |
|---|---|---|
| KeyStruct.sol | `mapping(Pair => uint256)` | Error (7804) |
| KeyArray.sol | `mapping(uint256[] => uint256)` | Error (2314) |
| KeyMapping.sol | `mapping(mapping(address => uint256) => uint256)` | Error (1005) |
| Length.sol | `return deposits.length;` | Error (9582) |
| MemMap.sol | 関数の中の`mapping(address => uint256) memory m;` | Error (4182)、Error (4061) |
| ParamMap.sol | public関数のパラメーター`mapping(...) storage m` | Error (6651) |
| ReturnMap.sol | external関数の戻り値`mapping(...) storage` | Error (6651) |
| AssignMap.sol | `m2 = m1;` | Error (9214) |
| DeleteMap.sol | `delete deposits;` | Error (9767) |

### 実行結果

Ledgerをデプロイした（`0x5FbDB2315678afecb367f032d93F642f64180aa3`）直後は、どのアドレスで`deposits(address)`を聞いても0である。Zerosも、使っていないキーは`0`、`false`、`0x0000000000000000000000000000000000000000`を、構造体は`0 false 0x0...`を返す。

アカウント1が1イーサを預けたあと（`deposit()`、gasUsed 43579）に欄を読んだ結果。スロット0そのものは空で、値はキーとスロット番号で計算した欄にある：

```
$ forge inspect --offline Ledger storageLayout
| Name     | Type                        | Slot | Offset | Bytes |
| deposits | mapping(address => uint256) | 0    | 0      | 32    |
$ cast storage <Ledger> 0
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast index address 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 0
0x14e04a66bf74771820a7400ff6cf065175b3d7eb25805a5bd1633b161af5d101
$ cast storage <Ledger> 0x14e04a66bf74771820a7400ff6cf065175b3d7eb25805a5bd1633b161af5d101
0x0000000000000000000000000000000000000000000000000de0b6b3a7640000
$ cast abi-encode "f(address,uint256)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 0
0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c80000000000000000000000000000000000000000000000000000000000000000
$ cast keccak 0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c80000000000000000000000000000000000000000000000000000000000000000
0x14e04a66bf74771820a7400ff6cf065175b3d7eb25805a5bd1633b161af5d101
```

アカウント3が2イーサを預けたトランザクションを`cast rpc debug_traceTransaction <ハッシュ> '{"tracer":"prestateTracer","tracerConfig":{"diffMode":true}}'`で見ると、変わった保存の欄はアカウント3の欄一つだけである。キーのリストのような欄は別にできない：

```
"post": {
  "0x5fbdb2315678afecb367f032d93f642f64180aa3": {
    "balance": "0x29a2241af62c0000",
    "storage": {
      "0x6d1035fce6503985ab075a4ff3f7ce2e57cd5a9c5e6a0589dccacfea7bcb0af4": "0x0000000000000000000000000000000000000000000000001bc16d674ec80000"
    }
  },
```

```
$ cast index address 0x90F79bf6EB2c4f870365E785982E1f101E93b906 0
0x6d1035fce6503985ab075a4ff3f7ce2e57cd5a9c5e6a0589dccacfea7bcb0af4
```

アカウント1が1イーサをまた引き出すと（`withdraw`、gasUsed 29243）、アカウント1の欄は0になり、一度も預けていないアカウント2と区別できなくなる。

新しくデプロイした台帳で`deposits(address)`を`cast send`で読んだgasUsedは、預けたアカウントが1個のときも100個のときも、使っていないアドレスも1番目・100番目に預けたアカウントも、すべて24255である。

ビルド。demoの`forge build --offline`は`Compiler run successful!`で、`bad/`の各ファイルは：

```
$ forge build --offline src/KeyStruct.sol
Error (7804): Only elementary types, user defined value types, contract types or enums are allowed as mapping keys.
  --> src/KeyStruct.sol:10:13:
   |
10 |     mapping(Pair => uint256) public m;
$ forge build --offline src/KeyArray.sol
Error (2314): Expected '=>' but got '['
$ forge build --offline src/KeyMapping.sol
Error (1005): Expected elementary type name or identifier for mapping key type
$ forge build --offline src/Length.sol
Error (9582): Member "length" not found or not visible after argument-dependent lookup in mapping(address => uint256).
 --> src/Length.sol:8:16:
$ forge build --offline src/MemMap.sol
Error (4182): Uninitialized mapping. Mappings cannot be created dynamically, you have to assign them from a state variable.
 --> src/MemMap.sol:6:9:
Error (4061): Type mapping(address => uint256) is only valid in storage because it contains a (nested) mapping.
$ forge build --offline src/ParamMap.sol
Error (6651): Data location must be "memory" or "calldata" for parameter in function, but "storage" was given.
 --> src/ParamMap.sol:7:19:
$ forge build --offline src/ReturnMap.sol
Error (6651): Data location must be "memory" or "calldata" for return parameter in function, but "storage" was given.
$ forge build --offline src/AssignMap.sol
Error (9214): Types in storage containing (nested) mappings cannot be assigned to.
 --> src/AssignMap.sol:9:9:
$ forge build --offline src/DeleteMap.sol
Error (9767): Built-in unary operator delete cannot be applied to type mapping(address => uint256).
 --> src/DeleteMap.sol:8:9:
```

`forge inspect --offline Named storageLayout`は、名前をつけてもLedgerと同じ`mapping(address => uint256)`、スロット0である。

AssetsNoFlagに`setAsset(0x1111...1111, 0)`（gasUsed 26685）を呼ぶと、その資産の欄は0なので、登録していない0x2222...2222と区別できない。AssetsListed（setAssetのgasUsed 47010）は欄が`0x...0100`になり、`assetConfig`が登録した資産には`0 true`、していない資産には`0 false`を返す。

LedgerTotalにアカウント1・2・3が1・2・3イーサを預けると`totalDeposits()`は6000000000000000000、アカウント2が1イーサを引き出すと5000000000000000000である。最初のdepositはgasUsed 65911（合計の欄を初めて書く）、次のdepositは48811、withdrawは39254である。

Aliasに`credit(<アカウント1>, 100)`（gasUsed 44601）と`creditTwice(<アカウント1>, 10)`（gasUsed 28043）を呼ぶと、`deposits(<アカウント1>)`は120である。

MarketのstorageLayout（一部）と、アカウント1が`deposit(500)`（gasUsed 88517）を呼んだあとの欄。アカウント1のPositionは、`cast index address <アカウント1> 4`で求めた欄から三つの欄である：

```
| assets          | contract IERC20[]                      | 2 | 0 | 32 |
| assetConfig     | mapping(address => struct AssetConfig) | 3 | 0 | 32 |
| positions       | mapping(address => struct Position)    | 4 | 0 | 32 |
| totalDeposits   | Amount                                 | 5 | 0 | 32 |
$ cast index address 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 4
0xdc7650c48de5cf00f484bb70bd6c7e289f258724008a4ca733979e35bcd7fb94
$ cast storage <Market> 0xdc76...fb94
0x00000000000000000000000000000000000000000000000000000000000001f4
$ cast storage <Market> 0xdc76...fb95
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast storage <Market> 0xdc76...fb96
0x000000000000000000000000000000000000000000000000000000006ad5bcf8
$ cast storage <Market> 4
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast call <Market> "positions(address)(uint256,uint256,uint64,bool)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
500
0
1792392440 [1.792e9]
false
```

### 試すときの注意

- スロットpで宣言したマッピングで、キーkの値はkeccak256(h(k) ‖ p)番の欄に置かれる。値型のキーではh(k)が32バイトに埋めた値で、`bytes`・`string`のキーはパディングなしでバイトをそのままつなぐ。値が構造体なら、その欄から構造体の配置どおりに続く。
- マッピングには長さもキーのリストもない。使っていないキーと0を入れたキーは読んでも区別できないので、登録されているかどうかが必要なら`listed`のような印の欄を置く。
- 合計が必要なら、`totalDeposits`のように別に欄を置き、預けたり引き出したりするたびに一緒に直す。
- anvilのブロックの時刻（上の`lastUpdate`の0x6ad5bcf8）はanvilを立ち上げた時刻に従うので、実行するたびに違う。

## 時効性のあるデータ

基準日時点の値。ハードフォークとツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Types、Mapping Types、v0.8.36（この講義の説明はsolc 0.8.30の実際の出力が基準） | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| マッピングのキーとして許される型（solc 0.8.30） | 基本型（`bytes`・`string`を含む）、ユーザー定義の値型、コントラクト型、列挙型。構造体はError 7804、配列・マッピングは文法エラー | 2026-10-19 |
| キーの型が増えたバージョン | 0.1.1で`string`のキー、0.6.3でコントラクト型・列挙型のキー（"Allow contract types and enums as keys for mappings."）、0.8.8でユーザー定義の値型の導入 | 2026-10-19 |
| マッピングのキー・値の名前の文法 | 0.8.18（2023-02-01）"Allow named parameters in mapping types." | 2026-10-19 |
| 読み取りのgasUsed（`cast send ... "deposits(address)"`） | 預けたアカウント1個：使っていないアドレス24,255 / 預けたアカウント24,255。預けたアカウント100個：使っていないアドレス24,255 / 1番目に預けたアカウント24,255 / 100番目24,255 | 2026-10-19 |
| 書き込みのgasUsed | Ledgerのdeposit初回の預け入れ43,579 / withdraw全額29,243。LedgerTotalの最初のdeposit 65,911（合計の欄を初めて書く）、次のdeposit 48,811、withdraw 39,254。AssetsNoFlagのsetAsset（比率0）26,685、AssetsListedのsetAsset 47,010。Marketのdeposit(500) 88,517。Aliasのcredit 44,601、creditTwice 28,043 | 2026-10-19 |
| SLOADの価格 | コールド2,100 / ウォーム100（ベルリン以降、EIP-2929） | 2026-10-19 |
| anvilの設定 | `--accounts 101`（アカウント100個の測定用）、ブロックの時刻0x6ad5bcf8 = 1,792,392,440 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| マッピングの中のマッピング、キーのリストを別に持つ列挙できるマッピング | [第72講](../../part4/lecture72/) |
| ハッシュから入力に戻る計算がない理由（ハッシュ関数の性質） | [第79講](../../part5/lecture79/) |
| 欄の番号の計算のルール全体（`bytes`・`string`のキー、マッピングの中のマッピング、構造体の値） | [第135講](../../part8/lecture135/) |
| deleteのルール全般（マッピングのフィールドを含む構造体を含む） | [第74講](../../part4/lecture74/) |
| publicのマッピングが作る照会関数の形 | [第96講](../../part6/lecture96/) |
| チェーンの外でキーのリストを集める方法（イベント、インデクサー） | [第105講](../../part6/lecture105/)、[第106講](../../part6/lecture106/)、[第107講](../../part6/lecture107/)、[第238講](../../part18/lecture238/) |
| マッピングの読み書きのガスを減らす設計 | [第143講](../../part9/lecture143/) |
| 合計の欄とユーザーの欄が食い違っていないかを点検する方法 | [第152講](../../part9/lecture152/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
