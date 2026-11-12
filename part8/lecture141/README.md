# 第141講 ABIエンコードの規則とセレクタ

第8部 コンパイラと内部構造・第35章 ABI仕様とメタデータ

[← 第140講](../../part8/lecture140/) | [第8部 目次](../) | [第142講 →](../../part8/lecture142/)

## この講義の問い

関数を呼ぶバイト、返されるバイト、ログとリバートデータは、一つの規則で作られる。その規則は型名をどう書き、欄をどう置き、バイトだけを見てもわからないことは何なのか。

## 実習資料

### 準備

ABIのバイトを自分で作ってみるデモのプロジェクト（`demo`）、solcを直接呼んでセレクタとエラーを見る小さなファイル（`solc`）、通しプロジェクトMarketの第141講のバージョン（第140講のバージョンとコードが同じで、`test/AbiShape.t.sol`を足したバージョン）を使う。solc 0.8.30、Foundry 1.8.3で、forge-stdが必要である（`lib/forge-std`）。デモのプロジェクトはoptimizerを入れ（runs 200）、evm_versionはosakaである。ドキュメントの例のcalldataは`cast calldata`で作り、ドキュメントに書かれた16進数と突き合わせる。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモのプロジェクトの設定 |
| [code/demo/src/Abi141.sol](code/demo/src/Abi141.sol) | セレクタのシグネチャ（canon、arrs、bags、fn、pairs、tup）、戻り値（ret、one、three）、関数型の欄（rawFn） |
| [code/demo/src/Ev141.sol](code/demo/src/Ev141.sol) | indexedの値・文字列・配列・構造体、anonymousのイベント |
| [code/demo/src/Er141.sol](code/demo/src/Er141.sol) | ドキュメントの例TestTokenと、名前だけが同じエラーを別に宣言したFaker、組み込みのエラーと予約されたセレクタ |
| [code/demo/src/Key141.sol](code/demo/src/Key141.sol) | アドレスのキー・文字列のキーのマッピングのスロットの計算 |
| [code/demo/src/V1.sol](code/demo/src/V1.sol)、[V2.sol](code/demo/src/V2.sol) | 同じtake関数、`pragma abicoder v1`のバージョンと既定（v2）のバージョン |
| [code/demo/test/](code/demo/test/) | Abi141・Call141・Coder141・Er141・Ev141・Key141・Packed141のテスト32個 |
| [code/solc/](code/solc/) | Lib141（ライブラリのシグネチャ）、Col・Col2（重なる4バイト）、Z（長さ0の配列の引数）、E1・E2（組み込みのエラーの再宣言）、P1・P2（packedに入れられない型） |
| [code/market/test/AbiShape.t.sol](code/market/test/AbiShape.t.sol) | この講義で足したテスト三つ: 返すバイト、イベントのdata、リバートデータ |
| [code/market/](code/market/) | Market 第141講のバージョン（foundry.toml、src、test）。テスト63個 |

### 実行結果

セレクタのシグネチャには、ABIの型名が入る（`forge inspect src/Abi141.sol:Abi141 methodIdentifiers`）。

```
| canon(uint256,uint8,uint128,address,address) | bd975708   |
| arrs(uint256[2],string[2])                   | 065e43cd   |
| bags((uint256,uint256[]),uint256)            | b66a9c8a   |
| fn(function)                                 | b7a4e9a1   |
| pairs((uint256,uint256),uint256)             | 671f91cf   |
| tup((uint256,uint256),(uint256,uint256[]))   | 12ae9812   |
```

canonは`canon(uint x, Side s, Price p, IThing t, address payable q)`と宣言した（Sideはenum、Priceは`type Price is uint128`、IThingはインターフェース）。ライブラリは違う。

```
$ solc --hashes Lib141.sol
f0098a8e: bump(Lib141.S storage,uint256)
0f55c4e4: pick(Lib141.K,uint256[] storage)
11546183: plain(uint256)
```

| 入れた文字列 | `cast sig` | `cast keccak`の先頭4バイト |
|---|---|---|
| `baz(uint32, bool)` | `0xcdcd77c0` | `0xdb1ae9c9` |
| `bump(Lib141.S storage,uint256)` | `0x5b6b6639` | `0xf0098a8e` |

`burn(uint256)`と`collate_propagate_storage(bytes16)`はどちらも`42966c68`なので、一つのコントラクトに置くと`Error (1860): Function signature hash collision`が出る。長さ0の配列の引数は`Error (1406): Array with zero length specified.`である。

ドキュメントの例五つを`cast calldata`で作った結果。

| 関数 | `cast calldata`の結果 | ドキュメントの16進数と |
|---|---|---|
| `bar(bytes3[2])` | 68バイト、`0xfce353f6` | 同じ |
| `baz(uint32,bool)` | 68バイト、`0xcdcd77c0` | 同じ |
| `sam(bytes,bool,uint256[])` | 292バイト、`0xa5643bf2` | 同じ |
| `f(uint256,uint32[],bytes10,bytes)` | 292バイト、`0x8be65246` | 同じ |
| `g(uint256[][],string[])` | 644バイト、`0x2289b18c` | 欄20個が同じ |

gの欄20個（32バイトの欄を縮めて説明をつけた）。

```
$ cast calldata "g(uint256[][],string[])" "[[1,2],[3]]" '["one","two","three"]'
0x2289b18c
 0  …0040   f: [[1, 2], [3]]の開始位置
 1  …0140   g: ["one", "two", "three"]の開始位置
 2  …0002   [[1, 2], [3]]の要素の数
 3  …0040   [1, 2]の開始位置
 4  …00a0   [3]の開始位置
 5  …0002 / 6 …0001 / 7 …0002   [1, 2]
 8  …0001 / 9 …0003             [3]
10  …0003   文字列の数
11  …0060 / 12 …00a0 / 13 …00e0  文字列三つの開始位置
14~19  3 "one" / 3 "two" / 5 "three"
```

欄3・4の0x40・0xa0は、欄3から数えた距離である。デモのプロジェクトのテスト（`forge test --match-path test/Abi141.t.sol -vv`など）のバイトを、32バイトの欄の値に縮めて書くと次のとおり。

```
pairs(Pair(1, 2), 9)          100バイト
671f91cf | 1 | 2 | 9
bags(Bag(3, [4, 5]), 9)       228バイト
b66a9c8a | 0x40 | 9 | 3 | 0x40 | 2 | 4 | 5
ret()   → (Pair(1, 2), Bag(3, [4, 5]), 6)   288バイト
          1 | 2 | 0x80 | 6 | 3 | 0x40 | 2 | 4 | 5
one()   → uint32 7                          32バイト
three() → (7, true, "hi")                   160バイト
          7 | 1 | 0x60 | 2 | "hi"
```

`rawFn(IThing(0x1234).ping)`は36バイトで、関数型の欄はアドレス20バイト + セレクタ4バイトを左寄せにする（`00…1234` `5c36b186` `0000000000000000`）。`cast abi-encode "f(string)" "日本"`は`0x20`、長さ`6`、`e697a5e69cac`である（文字数ではなくUTF-8のバイト数）。

コントラクト型で呼んだ外部呼び出しが作ったバイト（`test/Call141.t.sol`）。

```
[PASS] test_external_call_bytes() (gas: 11760)
  got 100 want 100
```

コーダの二つのバージョン（`test/Coder141.t.sol`、takeに入れた値）。

| takeに入れた値 | V1（abicoder v1） | V2（既定） |
|---|---|---|
| 7、1、0x1234、1 | 成功、128バイト | 成功、同じ128バイト |
| uint8の欄0x1ff | 成功、x = 0xff | 失敗、リバートデータ0バイト |
| boolの欄2 | 成功、b = 1 | 失敗、0バイト |
| アドレスの欄の先頭のバイトff | 成功、a = 0x…1234 | 失敗、0バイト |
| 列挙型の欄5 | 失敗、`0x4e487b71…21`（Panic 0x21）36バイト | 失敗、0バイト |

すき間を一つの欄だけ置いたバイトを`abi.decode`でほどいた結果（`test_nonstrict_decode`、開始位置0x40のあいだに0xdeadの欄一つ）。

```
  2 7 8
  len 128
  0x…20 | 0x…02 | 0x…07 | 0x…08
```

デコーダはリバートせずに[7, 8]とほどき、もう一度`abi.encode`すると、0x20から始まる厳格な形（128バイト）になる。

イベント（`test/Ev141.t.sol`、`forge inspect src/Ev141.sol:Ev141 events`、`solc --hashes`）。

```
| Dd(Ev141.D)   | 0xa521347ac8fa78887b69fe0a12843d806f11af477e3e25a94afb706d7623f00e |
| St(Ev141.S)   | 0x7638109396bd76ec892bb0b387edd221d28e65f16b8f9013677571e2d74a69c7 |
a521347ac8fa78887b69fe0a12843d806f11af477e3e25a94afb706d7623f00e: Dd((uint256[],uint256[]))
7638109396bd76ec892bb0b387edd221d28e65f16b8f9013677571e2d74a69c7: St((string,uint256))
$ cast keccak "Dd(Ev141.D)"
0x00621272b80ca975a6f06f84d2628f0464101298a1de1f242c084408e476ce3d
```

| イベント（出した値） | topics[1] | dataまたは同じ値 |
|---|---|---|
| `Neg(int8 indexed x, int8 y)`（-1、-1） | `0xffff…ffff` | data `0xffff…ffff` 32バイト |
| `Str(string indexed s)`（"hi"） | `0x7624778d…9c6f` = keccak256("hi") | data 0バイト |
| `Both(string indexed key, string key2)`（"hi"、"hi"） | `0x7624778d…9c6f` | data 96バイト、中に"hi" |
| `Arr(uint256[] indexed)`（[1, 2]） | `0xe90b7bce…c2e0` | keccak256(abi.encode(1, 2)) |
| `St(S indexed)`（S("hi", 7)） | `0xe28ae5a7…062e` | keccak256(bytes32("hi") ++ 7) |
| `Dd(D indexed)`（D([1], [2, 3])） | `0x6e0c6279…949c` | keccak256(abi.encode(1, 2, 3)) |
| `Dd(D indexed)`（D([1, 2], [3])） | `0x6e0c6279…949c` | 上と同じ |

anonymousのイベント（indexed四つ）は`topics 4 data 0`で、topic0がない。Key141のマッピングのスロットは、アドレスのキーが`abi.encode(key, uint256(0))`の64バイト、文字列のキーが`abi.encodePacked("hi", uint256(1))`の34バイトのハッシュである。

リバートデータ（`test/Er141.t.sol`）。

| 呼んだもの | リバートデータ |
|---|---|
| `TestToken.transfer(…, 150)` | `0xcf479181` + 0 + 0x96、68バイト |
| `Faker.transfer(…, 150)` | 同じ |
| `Faker.raw(上の68バイト)` | 同じ |
| `revert("no")` → `Error(string)` | `0x08c379a0` + 0x20 + 2 + "no"、100バイト |
| `10 / 0` → `Panic(uint256)` | `0x4e487b71` + 0x12、36バイト |
| `Faker.raw(hex"ffffffff")` / `hex"00000000"` | そのまま4バイト |

```
[PASS] test_expect_revert_fooled() (gas: 8785)
```

`vm.expectRevert`にTestTokenのエラーのバイトをかけてFakerを呼んでも通る。`error Error(string);`・`error Panic(uint256);`を宣言すると`Error (1855): The built-in errors "Error" and "Panic" cannot be re-defined.`が出る。

packedの形（`test/Packed141.t.sol`）。

| 入れた値 | `abi.encodePacked`の結果 |
|---|---|
| ドキュメントの例`int16(-1), bytes1(0x42), uint16(0x03), string("Hello, world!")` | `0xffff42000348656c6c6f2c20776f726c6421`、18バイト（`abi.encode`は192バイト） |
| `uint8[]` [1, 2] | 64バイト（要素ごとに32バイト） |
| `uint8(1), uint8(2)` | `0x0102` |
| `uint16(0x12)` / `uint256(0x12)` | `0x0012` / 32バイト |
| `"a", "bc"` / `"ab", "c"` | どちらも`0x616263`、keccak256もどちらも`0x4e03657a…6c45` |
| `uint8(1), uint16(0x0203)` / `uint16(0x0102), uint8(3)` | どちらも`0x010203` |
| 構造体、`uint[][]` | `Error (9578): Type not supported in packed mode.` |

Market 第141講のバージョンのABI（`forge inspect src/Market.sol:Market abi --json`）は、constructor 1、function 19（ゲッター10、読み取り関数4、状態を変える関数5）、event 4、error 12で36項目であり、引数・戻り値の欄61個のすべてに`internalType`がある（例: setStatusの引数`uint8` / `enum IMarket.MarketStatus`、addAssetの引数`address` / `contract IERC20`、`uint8` / `Ratio`）。`test/AbiShape.t.sol`とビルド・テスト。

```
[PASS] test_errorDataBytes() (gas: 107985)
[PASS] test_eventDataBytes() (gas: 116653)
[PASS] test_returnDataBytes() (gas: 57848)

$ forge build --offline --force --sizes
| Market      | 3,755            | 4,013             | 20,821             | 45,139              |
$ forge test --offline
Ran 19 test suites …: 63 tests passed, 0 failed, 0 skipped (63 total tests)
$ FOUNDRY_PROFILE=debug forge test --offline
Ran 19 test suites …: 63 tests passed, 0 failed, 0 skipped (63 total tests)
$ FOUNDRY_PROFILE=ir forge test --offline
Ran 19 test suites …: 63 tests passed, 0 failed, 0 skipped (63 total tests)
```

Marketが返すバイトは、positions 128、assetConfig 64、ほかの読み取り関数32、状態を変える関数五つは0である。イベントのtopics / dataはAssetAdded 2 / 32、StatusChanged 1 / 64、Deposited 3 / 32、Withdrawn 3 / 32、リバートデータはZeroAdmin・MarketFrozen・ZeroAsset・ZeroAmountが4バイト、NotAdmin・NotActive・AlreadyListed・NotListed・TransferFromFailed・TransferFailedが36バイト、InsufficientDeposit・RatioAboveCapが68バイトである。すべて静的な型なので、尾がない。

### 試すときの注意

- ABIでエンコードしたバイトには型がない。どう読むかは、別に置いたABI（スキーマ）が決める。
- セレクタのシグネチャにはABIの型名を書く（`uint` → `uint256`、enum → `uint8`、ユーザー定義の値型 → 元の型、コントラクト・`address payable` → `address`、構造体 → かっこでくくった型の一覧）。ライブラリの関数は例外で、構造体名・`storage`・列挙型の名前がシグネチャに残る。
- `cast sig`は空白と`uint`を直してくれるが、`abi.encodeWithSignature`に入れた文字列は書かれたとおりにハッシュされる。ライブラリのシグネチャは、`cast sig`が直した結果が間違いで、`cast keccak`が正しい。
- 動的な型の位置の開始位置は、その値が入ったまとまりの最初の欄から数えた距離である。Solidityのエンコーダはいつも厳格な形を作るが、デコーダは開始位置が形どおりかを問わない。
- 文字列・配列・構造体を`indexed`にすると、トピックにはハッシュだけが残り、配列・構造体は長さなしでつなげてハッシュするので、違う値が同じトピックになりうる（`Dd`の2行）。
- リバートデータは、どのコントラクトでもまったく同じに作れる。エラーの名前が合っていても、そのコントラクトが出したエラーだという保証はない。
- packedの形は埋めず長さもないので、違う入力が同じバイトになる。動的な型を二つ以上`keccak256(abi.encodePacked(…))`に入れない。
- forge 1.8.3の`forge inspect … events`の表は、名前の欄にSolidityの名前（`Dd(Ev141.D)`）を書くが、Topicの欄はABIの型名のシグネチャのハッシュである。名前の欄の文字列を`cast keccak`に入れると、違う値が出る。
- ドキュメントv0.8.36のJSONの節には`internalType`の欄がないが、solc 0.8.30の出力にはある。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンやソースのコメントが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモのプロジェクトはoptimizerを入れるruns 200、evm_version osaka。第141講のバージョンのdefaultはoptimizerを入れるruns 200、debugは切る、irはvia-IR + 入れる | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| 公式ドキュメントのバージョン | Contract ABI Specification（`docs/abi-spec.rst`、828行）v0.8.36、節15と下位の節2 | 2026-10-20 |
| ABIコーダ | v2が0.8.0から既定、`pragma abicoder v1;`でファイルごとにv1 | 2026-10-20 |
| internalType | ドキュメントv0.8.36のJSONの節に欄なし。solc 0.8.30の出力にはMarketの引数・戻り値の61欄すべてにある | 2026-10-20 |
| forge inspect eventsの表 | 名前の欄がSolidityの名前（`Dd(Ev141.D)`）、Topicの欄はABIの型名のシグネチャのハッシュ、anonymousのイベントはTopicが空欄 | 2026-10-20 |
| ドキュメントの例五つ | bar 68、baz 68、sam 292、f 292、g 644バイト、ドキュメントの16進数と同じ | 2026-10-20 |
| 通しプロジェクトのガス | 第141講のバージョン、新しいanvil、ブロック間隔1秒: デプロイ867,827、addAsset 75 92,576、deposit 100 128,297、withdraw 30 57,856、setStatus 1 45,224、setStatus 0 23,312、失敗するdeposit 0 26,409。第140講のバージョンのデプロイ867,827と同じ（作成のコードの0x00のバイトの数はどちらも214） | 2026-10-20 |
| サイズ | 第141講のバージョンのdefault 3,755 / 4,013、debug 7,353 / 7,931、ir 3,260 / 3,473 | 2026-10-20 |
| 行番号 | 第141講のバージョンのdeposit 0のリバートはsrc/Market.solの151行目、NotActiveは69行目。バージョンを説明するコメントが変わると変わる | 2026-10-20 |
| テストのガス | AbiShape 107,985 / 116,653 / 57,848（forgeのテストのガス） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| メタデータのoutputの欄に載るABIとNatSpec | [第142講](../../part8/lecture142/) |
| ABIでほかの人のコントラクトの呼び出しデータ・ログを読む | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| イベントをインデクサがトピックで絞り込む方法 | [第238講](../../part18/lecture238/) |
| packedの形を署名・認証のハッシュに使うとき（ドキュメントのpackedの警告799〜800行目） | [第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| 受け取ったリバートデータを信じるコード | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| 標準の形でない入力を受け取るコードの監査 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| インターフェースの標準（ERC）が決める関数・イベントのシグネチャ | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
