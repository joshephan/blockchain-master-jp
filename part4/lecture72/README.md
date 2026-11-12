# 第72講 入れ子のマッピングと列挙できるマッピングのパターン

第4部 言語の詳細 ① ファイルと型・第15章 マッピング

[← 第71講](../../part4/lecture71/) | [第4部 目次](../) | [第73講 →](../../part4/lecture73/)

## この講義の問い

マッピングの中にマッピングを入れると場所はどう決まり、マッピングにないキーのリストがどうしても必要なとき、自分でつけると何を一緒に背負うのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクト（`demo/`）から、Counterのファイルを消して始める。コンパイルエラーを見るファイルは、demoをコピーした別のプロジェクト`bad/`に置く（foundry.tomlは同じ）。デプロイはローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を使って行い、アリス・ボブ・キャロル・デイブ（既定のアカウント1〜4番）の呼び出しは`cast send ... --unlocked --from <アドレス>`で送る。資産のアドレス`0x...AAAA`、`0x...bBbB`はテスト用のアドレスである。ビルドはすべて`--offline`である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/demo/src/Types.sol](code/demo/src/Types.sol) | Amount・Rate・Ratioの値型、IERC20、ユーザー1人分のPosition |
| [code/demo/src/Book.sol](code/demo/src/Book.sol) | 資産 × ユーザーの2重のマッピング`deposits`と、内側のマッピングをstorageの名前でつかむ`pairTotal` |
| [code/demo/src/Desk.sol](code/demo/src/Desk.sol) | 2重のマッピングの構造体の値をstorageの別名で直す版と、memoryのコピーで直して書き戻しを忘れた版 |
| [code/demo/src/Members.sol](code/demo/src/Members.sol) | 値のマッピング + キーのリストの配列 + 位置のマッピング（位置 + 1）で最後まで回れるようにした列挙できるマッピング、長さごとのガス測定用のMembersSeed |
| [code/demo/src/MembersBuggy.sol](code/demo/src/MembersBuggy.sol) | 削除で移したキーの位置（`indexOf[moved] = pos;`）を直さなかった版 |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しのプロジェクトのMarketの会計のマッピング構造。資産リストと`listed`、資産 × ユーザーのPosition、資産ごとの合計。depositはトークンを移す行なしで欄だけを直す草案 |
| [code/bad/foundry.toml](code/bad/foundry.toml) | demoと同じ設定 |
| [code/bad/src/BookMem.sol](code/bad/src/BookMem.sol) | Bookの`storage inner`を`memory inner`に変えた版。Error (4061) |

### 実行結果

Bookをデプロイし（`0x5FbDB2315678afecb367f032d93F642f64180aa3`）、アリスが資産AAAAで500を預けた結果（gasUsed 44450）。スロット0と外側のキーの欄は空で、値は`cast index`を2回つなげて求めた欄にある：

```
$ cast storage <Book> 0
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast index address 0x000000000000000000000000000000000000AAAA 0
0x839613f731613c3a2f728362760f939c8004b5d9066154aab51d6dadf74733f3
$ cast storage <Book> 0x839613f731613c3a2f728362760f939c8004b5d9066154aab51d6dadf74733f3
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast index address 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 0x839613f731613c3a2f728362760f939c8004b5d9066154aab51d6dadf74733f3
0xa029a37741b56ca4edb4f207a16ec3faabf58370df8080cfb46746dfe49225d4
$ cast storage <Book> 0xa029a37741b56ca4edb4f207a16ec3faabf58370df8080cfb46746dfe49225d4
0x00000000000000000000000000000000000000000000000000000000000001f4
```

`deposits(address,address)`は（AAAA、アリス）だけが500で、（bBbB、ボブ）、（0x0、アリス）、（AAAA、ボブ）はすべて0である。`pairTotal(AAAA, アリス, ボブ)`は500である。

`bad/`で`forge build --offline --force src/BookMem.sol`：

```
Error: Compiler run failed:
Error (4061): Type mapping(address => uint256) is only valid in storage because it contains a (nested) mapping.
  --> src/BookMem.sol:12:9:
   |
12 |         mapping(address => uint256) memory inner = deposits[asset];
   |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

Deskでアリスとボブが`open(AAAA, 1000, 400)`（gasUsed 89371）をして60秒を過ぎたあと（`cast rpc evm_increaseTime 60`）、アリスは`updateStorage(AAAA, 1500, 600)`（gasUsed 39221）、ボブは`updateMemoryForgot(AAAA, 1500, 600)`（gasUsed 30933）を呼んだ。どちらもstatus 1だが、欄は違う：

```
アリスの欄 0xa029...25d4から: 0x5dc / 0x258 / 0x...01000000006ad5c001  (1500, 600, 新しい時刻)
ボブの欄 0x68bd...efd4から:   0x3e8 / 0x190 / 0x...01000000006ad5bfc5  (1000, 400, 古い時刻)
```

MembersとMembersBuggyに、同じ順番でdeposit・exitを送った結果。削除で移したキーの位置を直さないと、あとの削除が見当違いのキーを消す：

| 順番 | Members | MembersBuggy |
|---|---|---|
| アリス100（+50）、ボブ200、キャロル300 | [アリス、ボブ、キャロル] | [アリス、ボブ、キャロル] |
| アリスのexit（status 1） | [キャロル、ボブ]、キャロルのindexOfは1 | [キャロル、ボブ]、キャロルのindexOfは3 |
| デイブ400 | [キャロル、ボブ、デイブ]、デイブは3 | [キャロル、ボブ、デイブ]、デイブは3 |
| キャロルのexit（status 1） | [デイブ、ボブ] | [キャロル、ボブ] |
| sumAll | 600 | 200 |

MembersBuggyは、最後にデイブがbalanceOf 400・indexOf 3なのにリストになく、キャロルはbalanceOf 0・indexOf 0なのにリストに残っている。

Membersの追加のgasUsed：いちばん最初のdeposit（アリス）110854、新しいキー（ボブ）93754、すでにあるキー（アリス +50）29168、exit 42312。同じ順番で、MembersBuggyのexitは38231、33480である。

MembersSeedでキーを埋め、`sumAll()`を`cast send`で送ったgasUsed。長さ10：72149、100：509279、1000：4880579である。6,200個まで埋めると、anvilのブロックガスリミットの中で終わらない：

```
$ cast call <MembersSeed> "count()(uint256)"
6200
$ cast send <MembersSeed> "sumAll()" --private-key <アカウント0のキー> --gas-limit 30000000 --json
status 0x0, gasUsed 30000000
```

Market。管理者だけが資産を追加でき、同じ資産は2回入れられない：

```
$ cast send <Market> "addAsset(address,uint8)" 0x000000000000000000000000000000000000AAAA 75 --private-key <アカウント0のキー>
status 1, gasUsed 91663
$ cast send <Market> "addAsset(address,uint8)" 0x000000000000000000000000000000000000bBbB 75 --unlocked --from <アリス>
reverted: not admin
$ cast send <Market> "addAsset(address,uint8)" 0x000000000000000000000000000000000000AAAA 80 --private-key <アカウント0のキー>
already listed
```

`forge inspect --offline Market storageLayout`（一部）と、アリスがAAAAで1000を預けたあと（gasUsed 91448）の欄：

```
| status          | enum Market.MarketStatus                                        | 0 | 0 | 1  |
| collateralRatio | Ratio                                                           | 0 | 1 | 1  |
| admin           | address                                                         | 0 | 2 | 20 |
| interestRate    | Rate                                                            | 1 | 0 | 32 |
| assets          | contract IERC20[]                                       | 2 | 0 | 32 |
| assetConfig     | mapping(address => struct AssetConfig)                  | 3 | 0 | 32 |
| positions       | mapping(address => mapping(address => struct Position)) | 4 | 0 | 32 |
| totalDeposits   | mapping(address => Amount)                              | 5 | 0 | 32 |
| totalBorrows    | mapping(address => Amount)                              | 6 | 0 | 32 |
$ cast index address <アリス> $(cast index address 0x000000000000000000000000000000000000AAAA 4)
0x38bb39d3455c9ab9596b6ddbdd0e9f6d06a6d98609d16fa00df0a9d840121780
$ cast storage <Market> 0x38bb39d3455c9ab9596b6ddbdd0e9f6d06a6d98609d16fa00df0a9d840121780
0x00000000000000000000000000000000000000000000000000000000000003e8
$ cast storage <Market> 4
0x0000000000000000000000000000000000000000000000000000000000000000
```

登録していない資産bBbBでdepositすると、`not listed`で巻き戻る。

### 試すときの注意

- スロットpで宣言した`mapping(K1 => mapping(K2 => V))`で、`m[a][b]`の欄はkeccak256（bを32バイトに埋めた値 . keccak256（aを32バイトに埋めた値 . p））である（`.`は連結）。値が構造体なら、この欄からフィールドの配置どおりに続く。
- キーのリストをつけたマッピングでの削除は、最後のキーを空いた位置に移してpopする。このとき、移したキーの位置の欄も一緒に直さなければならない。削除を経ると、入ってきた順番は残らない。
- MembersSeedの`seed(300)`1回はgasUsed 20,352,983なので、anvilのブロックのリミットに収まるように300個ずつ分けて送った。
- OpenZeppelin ContractsのEnumerableSetも同じ形（値の配列`_values` + 位置のマッピング`_positions`、位置 + 1、削除は最後の要素を移してpop）である。

## 時効性のあるデータ

基準日時点の値。ハードフォーク、ブロックガスリミット、ツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Types、Mapping Typesの節のIterable Mappingsの例、v0.8.36（`struct IndexValue { uint keyIndex; uint value; }`、`struct KeyFlag { uint key; bool deleted; }`、`struct itmap { mapping(uint => IndexValue) data; KeyFlag[] keys; uint size; }`、`library IterableMapping`のinsert・remove・contains・iterateStart・iterateValid・iterateNext・iterateGet、`contract User`のsum。insertは`keyIndex + 1`を書き、removeは`keys[keyIndex - 1].deleted = true`で印をつけるだけで配列を縮めない） | 2026-10-19 |
| 同じ節のキーの型 | "any built-in value type, bytes, string, or any contract or enum type" / マッピング・構造体・配列はキーになれない | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| OpenZeppelin Contracts | 5.4.0（EnumerableSet：`_values`配列 + `_positions`マッピング、位置 + 1、削除は最後の要素を移してpop / EnumerableMap） | 2026-10-19 |
| BookのgasUsed | アリスの最初のdeposit 44,450 | 2026-10-19 |
| DeskのgasUsed | open 89,371（アリス・ボブで同じ） / updateStorage 39,221 / updateMemoryForgot 30,933 | 2026-10-19 |
| MembersのgasUsed | いちばん最初のdeposit（アリス）110,854 / 新しいキーのdeposit（ボブ）93,754、（キャロル・デイブ）93,766 / すでにあるキーのdeposit（アリス +50）29,168 / exit 42,312（MembersBuggyは38,231、33,480） | 2026-10-19 |
| sumAllのgasUsed | 長さ10：72,149 / 100：509,279 / 1,000：4,880,579（キー一つに4,857、固定分23,579） / 6,200：失敗（status 0、gasUsed 30,000,000） | 2026-10-19 |
| 第66講の配列のsumの要素あたりのガス | 2,633 | 2026-10-19 |
| anvilのブロックガスリミット | 30,000,000（既定値） | 2026-10-19 |
| メインネットのブロックガスリミット | 60,000,000 | 2026-10-19 |
| メインネットのトランザクション一つのガスの上限 | 16,777,216（EIP-7825） | 2026-10-19 |
| sumAllのおおよその最大の長さ | メインネットのトランザクションの上限で約3,450（(16,777,216 - 23,579) ÷ 4,857） / メインネットのブロックのリミットだけで割ると約12,350 / anvilの3千万で約6,170 | 2026-10-19 |
| MarketのgasUsed | addAsset 91,663 / アリスのdeposit 91,448 | 2026-10-19 |
| テストのアドレス | Book `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Desk `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Members `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、MembersBuggy `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、Market `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、MembersSeed `0x0165878A594ca255338adfa4d48449f69242Eb8F` / アカウント0番`0xf39F...2266`（デプロイ・管理者）、1番アリス`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`、2番ボブ`0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`、3番キャロル`0x90F79bf6EB2c4f870365E785982E1f101E93b906`、4番デイブ`0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65`（anvilの既定のアカウント、公開されたテスト用の鍵） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 重なったマッピング・`bytes`のキーの欄の番号の計算のルール全体 | [第135講](../../part8/lecture135/) |
| 承認（allowance）の意味と、approve・transferFromの流れ | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| publicの2重のマッピングが作る照会関数の形 | [第96講](../../part6/lecture96/) |
| 際限なく伸びるリストを回る関数の設計判断（分けて処理、引き出し方式） | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |
| withdrawが台帳を先に0にしてから送る理由 | [第83講](../../part5/lecture83/)、[第150講](../../part9/lecture150/)、[第168講](../../part11/lecture168/) |
| チェーンの外でキーを集める手段（イベント、インデクサー） | [第105講](../../part6/lecture105/)、[第106講](../../part6/lecture106/)、[第107講](../../part6/lecture107/)、[第238講](../../part18/lecture238/) |
| キーのリストとマッピングが食い違うコードを見つける方法 | [第152講](../../part9/lecture152/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/) |
| 追加のガスを減らす設計 | [第143講](../../part9/lecture143/) |
| deleteのルール全般 | [第74講](../../part4/lecture74/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
