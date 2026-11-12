# 第117講 externalのライブラリとdelegatecall

第6部 言語の詳細 ③ コントラクト・第26章 ライブラリとusing for

[← 第116講](../../part6/lecture116/) | [第6部 目次](../) | [第118講 →](../../part6/lecture118/)

## この講義の問い

ライブラリ関数をpublicにすると、デプロイするものと呼び出しはどう分かれ、その呼び出しで誰のコードが誰のストレージを書き換え、そのコードは誰が選ぶのか。

## 実習資料

### 準備

第116講のライブラリのデモ用のプロジェクト（`demo`）に、public関数を置いたライブラリBoxExtとそれを呼ぶShelfExt、同じ本体をinternalにしたBoxIn・ShelfInを加える。ローカルのanvilにライブラリを先にデプロイし、`forge create --libraries`でリンクしてデプロイしたあと、トレースとランタイムコードを見る。Marketは第117講のバージョンでコードを変えずにコメントだけを加え、比較用にライブラリ関数をpublicに変えたバージョン（`market-public`）を別に測る。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Ext.sol](code/demo/src/Ext.sol) | public関数が三つ（put、peek、part）のBoxExtとそれを呼ぶShelfExt、同じ本体をinternalにしたBoxIn・ShelfIn、リンクの位置に入れてみたNotBoxExt（ライブラリではないコントラクト） |
| [code/demo/src/Shelf.sol](code/demo/src/Shelf.sol)、[code/demo/src/Percent.sol](code/demo/src/Percent.sol)、[code/demo/src/Who.sol](code/demo/src/Who.sol) | 第116講のデモのソース |
| [code/demo/test/Ext.t.sol](code/demo/test/Ext.t.sol) | ShelfExtを`new`で作ってput・peekを呼ぶテスト（forge testがライブラリをリンクしてくれる） |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/mix/src/X.sol](code/mix/src/X.sol) | internal関数とpublic関数が一緒にあるライブラリMix、それぞれを呼ぶUseHalf・UseThird |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol)、[code/market/src/Market.sol](code/market/src/Market.sol) | 第117講のバージョン。第116講のバージョンとコードは同じで、ライブラリを外に置かないというコメントを加えた |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/) | 残りのソースとテスト（48個） |
| [code/market-public/src/MarketMath.sol](code/market-public/src/MarketMath.sol) | 比較用：`interestFor`・`credit`・`debit`の`internal`だけを`public`に変えたバージョン。残りのファイルは`code/market`と同じ |

### 実行結果

サイズ（`forge build --sizes`、区切りの行とほかの行は省略）。BoxExtが表に別に出て、ShelfExtはShelfInより大きい。

```
| Contract  | Runtime Size (B) | Initcode Size (B) | Runtime Margin (B) | Initcode Margin (B) |
| BoxExt    | 1,141            | 1,218             | 23,435             | 47,934              |
| NotBoxExt | 133              | 159               | 24,443             | 48,993              |
| ShelfExt  | 1,530            | 1,621             | 23,046             | 47,531              |
| ShelfIn   | 1,026            | 1,117             | 23,550             | 48,035              |
```

ShelfExtの成果物の`linkReferences`。ランタイムコードの三か所（20バイトずつ）が空いていて、プレースホルダーが入っている。

```
out/Ext.sol/ShelfExt.json
"deployedBytecode": { "linkReferences": { "src/Ext.sol": { "BoxExt": [
  { "start": 277, "length": 20 },
  { "start": 405, "length": 20 },
  { "start": 570, "length": 20 } ] } } }

...5f73__$8d68f69b66115d85b178c33015f0d35838$__6345278644...
```

プレースホルダーは`src/Ext.sol:BoxExt`のkeccak256の先頭34文字である（`cast keccak "src/Ext.sol:BoxExt"` → `0x8d68f69b66115d85b178c33015f0d358383d0f87c6119bd8650ed455621e6606`）。一つのライブラリの中でも、分かれる単位は呼んだ関数である。

```
UseHalf  linkReferences {}
UseThird linkReferences {"src/X.sol": {"Mix": [{"start": 96, "length": 20}]}}
```

リンクなしでデプロイすると止まり、ライブラリを先にデプロイしてから`--libraries`でアドレスを渡す（`forge create`、一部の行）。

```
$ forge create --offline src/Ext.sol:ShelfExt --rpc-url $R --unlocked --from $A --broadcast
Compiler run successful!
Error: Dynamic linking not supported in `create` command - deploy the following library contracts first, then provide the address to link at compile time
	BoxExt: src/Ext.sol

$ forge create --offline src/Ext.sol:BoxExt --rpc-url $R --unlocked --from $A --broadcast
Deployed to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

$ forge create --offline src/Ext.sol:ShelfExt --libraries src/Ext.sol:BoxExt:0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 --rpc-url $R --unlocked --from $A --broadcast
Deployed to: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
```

デプロイされたShelfExtのランタイムコード（1,530バイト）の276・404・569番目のバイトは0x73（PUSH20）で、そのあとの20バイトがBoxExtのアドレス`9fe46736679d2d9a65f0992f2272de9f3c7fa6e0`である（`cast code`）。

ライブラリ関数のセレクタ。storageの引数は型の名前のあとに` storage`をつけてハッシュし、put・peekはABIのJSONに載らない（BoxExtのabiにはpartとイベントPutだけ）。

```
$ forge inspect --offline BoxExt methodIdentifiers
| Method                   | Identifier |
| part(uint256,uint256)    | 45278644   |
| peek(Box storage)        | 5feb2d0e   |
| put(Box storage,uint256) | 04769612   |

$ cast keccak "put(Box storage,uint256)"
0x0476961201f021fde4abe6c13131ac62f1592264e3c6d3e30b8f738a8d1f7e9d
$ cast keccak "peek(Box storage)"
0x5feb2d0e5286f21401cbe336f79212d1c10048bebc2ef63f2f4f032c77b9a96b
```

storageの引数として渡る値はスロット番号である。putのcalldataは、セレクタ、`boxes[アカウント1番]`のスロット番号（`cast index address $B 1`）、amountの順である。

```
0x04769612
  3c8e904cdb19937d60d41c8d984b1a8803ad6e0891b4f9e032dcec2a22c2c7f5   ← boxes[アカウント1番]のスロット番号
  0000000000000000000000000000000000000000000000000000000000000005   ← amount
```

アカウント1番の`put(70)`のトレース（`cast run`）。ライブラリ関数はdelegatecallで動き、その中の`msg.sender`はアカウント1番、`address(this)`とログのアドレスはShelfExtである。

```
  [50572] 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9::put(70)
    ├─ [47043] 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0::put() [delegatecall]
    │   ├─ emit Put(sender: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, self: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9, amount: 70)
    │   └─ ← [Stop]
    └─ ← [Stop]
```

viewの`peek()`と、pureの`part`を呼ぶ`fee(1000)`にも`[delegatecall]`の行ができる（`cast call --trace`、結果は75と30）。

| | ShelfIn（internal） | ShelfExt（public） |
|---|---|---|
| デプロイ | 297,943 | 407,231 + BoxExt 299,558 |
| アカウント1番の最初のput(70) | 68,189 | 71,776 |
| アカウント1番の二回目のput(5) | 33,989 | 37,576 |

同じBoxExtのアドレスでShelfExtをもう一つデプロイすると、コードはBoxExt一つを共有し、値はそれぞれのストレージにある（新しいShelfExtに`put(9)`したあとpeekは9、最初のShelfExtは75）。

BoxExtのアドレスに直接putのcalldataを送るとリバートし（`--gas-limit 100000`、status 0、gasUsed 22,790）、pureの`part`は30を返し、viewの`peek`はBoxExt自身のストレージを読んで0である。デプロイされたBoxExtのコードの先頭のPUSH20の位置には、自分のアドレスが入っている。

```
第116講のPercentの成果物      0x73 0000000000000000000000000000000000000000 30 14 6080604052 5f5f fd fe ...
BoxExtの成果物                0x73 0000000000000000000000000000000000000000 30 14 6080604052 ...
デプロイされたBoxExt（cast code）  0x73 9fe46736679d2d9a65f0992f2272de9f3c7fa6e0 30 14 6080604052 ...
```

コードのないアドレス（0x…dEaD）をリンクしたShelfExtはデプロイはできるが、`put(70)`は呼ぶ前にリバートし（トレースは`call to non-contract address`）、`fee(1000)`は返ってきた値が空なので`execution reverted, data: "0x"`である。

ライブラリではないNotBoxExt（`fallback`で`admin = msg.sender`）をリンクしたShelfExtも、警告なしでビルド・デプロイされる。アカウント1番が`put(70)`を送ると、NotBoxExtのコードがShelfExtのアドレスで動き、ShelfExtのスロット0（admin）を書き換える。

```
$ cast call 0x0165878A594ca255338adfa4d48449f69242Eb8F "admin()(address)" --rpc-url $R
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
$ cast send 0x0165878A594ca255338adfa4d48449f69242Eb8F "put(uint256)" 70 --rpc-url $R --unlocked --from $B
status 1, gasUsed 29837, logs []
  [8633] 0x0165...Eb8F::put(70)
    ├─ [5104] 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707::put() [delegatecall]
    │   └─ ← [Stop]
    └─ ← [Stop]

admin()               0x70997970C51812dc3A010C7d01b50e0d17dc79C8
boxes(アカウント1番)    0 0
cast storage ... 0    0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
```

ソースが同じ二つのShelfExt（BoxExtをリンクしたバージョン、NotBoxExtをリンクしたバージョン）のランタイムコードはどちらも1,530バイトで、違うバイト92個は、リンクしたアドレスの三か所（277〜296、405〜424、570〜589）とメタデータハッシュ（1487〜1518）である。`--libraries`の値がコンパイルの設定に入り、メタデータハッシュが変わる。

Marketのライブラリ関数をpublicに変えたバージョン（`forge build --sizes`、`linkReferences`）。

```
| InterestMath | 645              | 722               | 23,931             | 48,430              |
| Market       | 7,353            | 7,931             | 17,223             | 41,221              |

Market linkReferences
{"src/MarketMath.sol": {"InterestMath": [{"start": 2903, "length": 20}],
  "PositionLib": [{"start": 3931, "length": 20}, {"start": 4525, "length": 20}]}}
```

| | 第117講のバージョン | publicに変えたバージョン |
|---|---|---|
| runtime / creation | 7,298 / 7,876 | 7,353 / 7,931 |
| デプロイ | 1,633,390 | 1,646,023 + 二つのライブラリ414,065 |
| interestFor(1000e18, 5e16, 365 days) | 23,497 | 27,800 |
| deposit 100 | 130,369 | 133,922 |
| withdraw 30 | 59,697 | 63,272 |

どちらのバージョンも`forge test`の48個が通り、publicのバージョンのdepositのトレースには`PositionLib::credit() [delegatecall]`の行ができる。第117講のバージョンのMarketの`linkReferences`は空である。

### 試すときの注意

- ライブラリ関数をpublic・externalにすると、ライブラリを先にデプロイし、呼ぶ側のコントラクトを`--libraries <ファイル>:<ライブラリ>:<アドレス>`でリンクしてデプロイする。`forge test`はこの手順を自動でする。
- リンクしたアドレスはランタイムコードに埋め込まれ、デプロイのあとは変えられない。コンパイラは、そのアドレスにどんなコードがあるかを確かめない。
- delegatecallで動くコードは、呼ぶ側のコントラクトのストレージのどのスロットでも書き換えられる。リンクされたライブラリがあるコントラクトを読むときは、成果物の`linkReferences`、デプロイのときに渡したアドレス、そのアドレスのコードまで見る。
- `linkReferences`のキーとプレースホルダーは、ライブラリのファイルのパスで決まる。ファイルを動かすと変わる。
- 直接送ったputのようにリバートするトランザクションは、`--gas-limit`を与えないとcastがガスの見積もりで止まる（execution reverted）。
- ブロックの間隔を固定しないと（`anvil_setBlockTimestampInterval 1`）、同じ秒のブロックに入ったputが同じ値を書いて、ガスが2,800少なく出ることがある。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンや実行環境が変わると、数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | 2026-10-19 |
| ランタイムコードのサイズの上限 | 24,576バイト（EIP-170）。`forge build --sizes`のRuntime Margin = 上限 - runtime | 2026-10-19 |
| 外部呼び出しのコードの確認 | 呼ぶ前に`extcodesize`で確認。0.8.10から、返ってくる値を解く呼び出しでは確認を省略、低水準の呼び出しは確認しない | 2026-10-19 |
| サイズ（runtime / initcode） | BoxExt 1,141 / 1,218、ShelfExt 1,530 / 1,621、ShelfIn 1,026 / 1,117、NotBoxExt 133 / 159、Mix 410 / 487、UseHalf 416 / 444、UseThird 514 / 542、Percentの成果物85バイト。Marketの第117講のバージョン7,298 / 7,876、publicに変えたバージョン7,353 / 7,931、InterestMath 645 / 722、PositionLib 782（成果物のJSON） | 2026-10-19 |
| linkReferences | ShelfExtのランタイム277・405・570（作成のコード368・496・661）、長さ20ずつ。UseThird 96。publicに変えたMarketのInterestMath 2903、PositionLib 3931・4525。第117講のバージョンのMarket {} | 2026-10-19 |
| セレクタ | put(Box storage,uint256) 04769612、peek(Box storage) 5feb2d0e、part(uint256,uint256) 45278644、interestFor(uint256,uint256,uint256) 9bcf40a2、credit(Position storage,uint256) bd46d1a1、debit(Position storage,uint256) dc036675 | 2026-10-19 |
| ガス（ShelfExtのデモ） | デプロイBoxExt 299,558、ShelfExt 407,231、ShelfIn 297,943 / アカウント1番のput(70) ShelfExt 71,776・ShelfIn 68,189、put(5) 37,576・33,989 / 直接送ったput 22,790（status 0） / 0x…dEaDのバージョンのput 24,590（status 0） / NotBoxExtのバージョンのput(70) 29,837（status 1）。anvilのブロックの間隔は1秒に固定 | 2026-10-19 |
| 二つのShelfExtのランタイムコードの比較 | 1,530バイトが二つ、違うバイト92個（277〜296、405〜424、570〜589、1487〜1518） | 2026-10-19 |
| Marketのガス（第117講のバージョン / publicのバージョン） | デプロイ1,633,390 / 1,646,023 + 414,065、interestFor 23,497 / 27,800、addAsset 75 93,730 / 93,730、deposit 100 130,369 / 133,922、withdraw 30 59,697 / 63,272、setStatus 1 45,732 / 45,732、setStatus 0 23,820 / 23,820、失敗deposit 0 26,869 / 26,869 | 2026-10-19 |
| Marketのガスの実測の条件 | バージョンごとに新しいanvil、`anvil_setBlockTimestampInterval 1`、アカウント0番がMockToken →（publicのバージョンはInterestMath・PositionLib） → Marketをデプロイ、コンストラクタの引数はアカウント0番・5e16・80。順番はaddAsset 75 → deposit 100 → withdraw 30 → setStatus 1 → setStatus 0 → 失敗deposit 0（`--gas-limit 100000`）。interestForは`cast estimate` | 2026-10-19 |
| テスト | 第117講のバージョン・publicのバージョンのどちらも48個が通る、ExtTestは1個が通る | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ライブラリ関数を型につけて使う（`using for`） | [第118講](../../part6/lecture118/) |
| `address.delegatecall`とYulで直接かける呼び出し | [第122講](../../part7/lecture122/)、[第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| コードを差し替える構造（プロキシ）とスロットの衝突 | [第135講](../../part8/lecture135/)、[第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| リンクしたコードが書き換えられる範囲を超えた実際の事故（Parityのマルチシグ） | [第177講](../../part11/lecture177/) |
| 相手のコードが自分の状態を見ている間に、また入ってくる場合 | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| リンクするアドレスを決める運用と鍵 | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/)、[第179講](../../part11/lecture179/) |
| 検証済みのソースとリンクされたアドレスの照合 | [第130講](../../part8/lecture130/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| サイズの上限に合わせるほかの方法とガスの選び方 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 標準の実装がライブラリを置くやり方 | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| publicのライブラリ関数の中のselfdestruct | [第177講](../../part11/lecture177/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
