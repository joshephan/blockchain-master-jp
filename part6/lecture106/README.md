# 第106講 indexedとトピックの構造

第6部 言語の詳細 ③ コントラクト・第23章 イベントとログ

[← 第105講](../../part6/lecture105/) | [第6部 目次](../) | [第107講 →](../../part6/lecture107/)

## この講義の問い

ログ一件はどんな欄でできていて、`indexed`は値をどの欄に移し、ノードに何を条件としてかけて探せるのか。

## 実習資料

### 準備

第105講の終わりのMarketのプロジェクトから始め、四つのイベントの宣言に`indexed`をつける。別に`forge init`で作ったデモ用のプロジェクト（`demo`）にイベントのデモ用のコントラクトを四つ置き、ローカルのanvilにデプロイしてレシートとログの照会を見る。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/demo/src/Ev.sol](code/demo/src/Ev.sol) | `Over`（名前が同じ`Set`が二つ）、`Plain`・`Indexed`（`indexed`の配置だけが違う二つのバージョン）、`Label`（文字列を`indexed`に） |
| [code/errors/four/src/X.sol](code/errors/four/src/X.sol) | `indexed`を四つつけたイベント、Error 7249 |
| [code/errors/dup/src/X.sol](code/errors/dup/src/X.sol) | `indexed`だけが違う同じイベントが二つ、Error 5883 |
| [code/gas/test/LogGas.t.sol](code/gas/test/LogGas.t.sol) | アセンブリの`log0`〜`log3`を`gas()`の間に置き、LOG命令のガスを測るテスト |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのプロジェクトの設定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第106講のバージョンのMarket。Deposited・Withdrawnはasset・user、AssetAddedはassetに`indexed` |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | Marketのインターフェース |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Topics.t.sol](code/market/test/Topics.t.sol) | この講義で加えたテスト。topic0の手計算、`vm.recordLogs`でdepositのログのtopics・dataを確認 |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト（Events、Getters、Market、Receive、Selectors、Status、WithdrawAll） |

### 実行結果

関数セレクタはハッシュの先頭4バイト、topic0は32バイト全体である（`cast sig`、`cast sig-event`）。

```
$ cast sig-event "Moved(address,address,uint256)"
0x000e6e1d52477156459d942cdb0bc0970a404c1ea857ab5b75b5ad32f334dfc1
$ cast keccak "Moved(address,address,uint256)"
0x000e6e1d52477156459d942cdb0bc0970a404c1ea857ab5b75b5ad32f334dfc1
$ cast sig "deposit(address,uint256)"
0x47e7ef24
$ cast sig-event "Deposited(address,address,uint256)"
0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7
```

シグネチャには`indexed`と引数の名前は入らない。`cast sig-event "Moved(address indexed from, address indexed to, uint256 amount)"`も同じ`0x000e6e1d…dfc1`である。ユーザー定義型と列挙型は、ABIの型`uint8`で書く（`AssetAdded(address,uint8)` → `0x57c9e281…`、`StatusChanged(uint8,uint8)` → `0xe1377aa2…`）。`cast keccak "AssetAdded(address,Ratio)"`は`0xd98b89b1…`で、Marketのログにはない値である。

`Over`の`a()`と`b()`のレシートのtopics（`cast send --json`）。引数の型が違えば、topic0も違う。

```
a()のログのtopics: ["0xdf7a95aebff315db1b7716215d602ab537373cdb769232aae6055c06e798425b"]
b()のログのtopics: ["0x3c4dbb057f7df48b080ac34e14a9186ad0847e234436b06de4078464d5936c62"]
```

二種類のコンパイルエラー（`forge build`、`errors/dup`と`errors/four`）。

```
Error (5883): Event with same name and parameter types defined twice.
Error (7249): More than 3 indexed arguments for event.
```

`Plain`と`Indexed`に同じ`move(アカウント1番, 100)`を送ったレシート。

| 欄 | Plain | Indexed |
|---|---|---|
| topics[0] | `0x000e6e1d…dfc1` | `0x000e6e1d…dfc1` |
| topics[1] | なし | アカウント0番のアドレス（32バイトの欄の左を0で埋める） |
| topics[2] | なし | アカウント1番のアドレス（32バイトの欄の左を0で埋める） |
| data | 96バイト：アカウント0番、アカウント1番、100 | 32バイト：100 |
| gasUsed | 24,168 | 24,124 |

ABIのイベントの項目は、`"indexed"`の値だけが違う（`forge inspect Indexed abi --json`、イベントの項目だけ）。

```
{"type": "event", "name": "Moved", "inputs": [
  {"name": "from", "type": "address", "indexed": true, "internalType": "address"},
  {"name": "to", "type": "address", "indexed": true, "internalType": "address"},
  {"name": "amount", "type": "uint256", "indexed": false, "internalType": "uint256"}],
 "anonymous": false}
```

二つのコントラクトに`move`を三つずつ（アカウント1番に100、アカウント2番に50、アカウント1番に30）送ったあと、受け取る側がアカウント1番のログだけを問い合わせる（`cast logs`、一部の行だけ）。

```
$ cast logs --rpc-url $R --address $I "Moved(address indexed from, address indexed to, uint256 amount)" "" $A1
- address: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  blockNumber: 6
  data: 0x0000000000000000000000000000000000000000000000000000000000000064
- address: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  blockNumber: 10
  data: 0x000000000000000000000000000000000000000000000000000000000000001e
```

同じ条件を`cast rpc eth_getLogs`で直接送ると（topics `[t0, null, アカウント1番]`）、Indexedは2件、Plainは0件である。三つ目の欄を配列`[アカウント1番, アカウント2番]`にすると、Indexedから3件が出る。`null`はどんな値でも、配列はそのうちの一つと同じなら合う。「50より大きい」のような範囲の条件は、書く欄がない。

文字列を`indexed`にした`Label`の`label("alice")`のレシート。topics[1]は文字列のハッシュで、候補を入れてみると`alice`で合う（`cast keccak`）。

```
"topics": ["0x13334f6b4d3942694c8f99c24921cfc54de74de4e24301a0b44bcf2c40b90c40",
           "0x9c0257114eb9399a2985f8e75dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501"]
$ cast keccak bob
0x38e47a7b719dce63662aeaf43440326f551b8a7ee198cee35cb5d517f2d296a2
$ cast keccak carol
0x2c52130a69b3254240c961f6acfb09713f4f9cc14aa498cbf844b94a27da64ff
$ cast keccak alice
0x9c0257114eb9399a2985f8e75dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501
```

Marketの第105講のバージョンと第106講のバージョンのDepositedは、topic0がどちらも`0x8752a472…68a7`である。第106講のバージョンのログのdata（32バイト、`$D6`）を第105講のシグネチャで解くと壊れ、第105講のバージョンのログのdata（96バイト、`$D5`）は解ける（`cast decode-event`）。

```
$ cast decode-event --sig "Deposited(address,address,uint256)" $D6
Error: ABI decoding failed: buffer overrun while deserializing
$ cast decode-event --sig "Deposited(address,address,uint256)" $D5
0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
100
```

逆に、第106講のシグネチャ（`indexed`）で第105講のバージョンのMarketにアカウント1番の条件をかけて`cast logs`で問い合わせると、アカウント1番の預け入れがあるのに出力がない。エラーも出ない。

第106講のバージョンのMarketのdepositのレシート（`cast send --json`）。topicsはtopic0、資産のアドレス、預け入れたアカウントである。

```
"topics": ["0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7",
           "0x000000000000000000000000959922be3caee4b8cd9a407cc3ac1c251c2007b1",
           "0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266"],
"data": "0x0000000000000000000000000000000000000000000000000000000000000064"
```

テスト（`forge test`）。第105講で作ったEventsのテストはソースの宣言をそのまま使うので、第106講のバージョンでも通る。

```
$ forge test --offline --mc TopicsTest
[PASS] test_depositTopics() (gas: 146038)
[PASS] test_topic0ByHand() (gas: 438)
Suite result: ok. 2 passed; 0 failed; 0 skipped
$ forge test --offline
Ran 8 test suites: 21 tests passed, 0 failed, 0 skipped (21 total tests)
```

### 試すときの注意

- `indexed`のないシグネチャで`cast logs`に引数を渡すと、castはその引数を条件に入れず、エラーなしで全部を返す（Plainにアカウント1番を渡したのに3件）。
- `cast decode-event --sig`に`indexed`の入ったシグネチャを渡すと、ログが合うバージョンかどうかにかかわらず`invalid log topic list length: expected 3 topics, got 1`が出る。配置が食い違っているかを見るのには使わない。
- ブロックヘッダーの`logsBloom`（`cast block <番号> -f logsBloom`）は、ログのないブロックでは256バイトすべてが0で、ログのあるブロックではところどころビットが立つ。
- `vm.expectEmit(true, true, false, true)`の前の三つはtopics[1]〜[3]、四つ目はdataを比べるかどうかを決める。topic0は常に比べる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| LOGのガスの規則 | 基本375、トピック一つ375、data 1バイト8、メモリ拡張は別 | 2026-10-19 |
| LOG命令一つを測った値 | log0 0バイト387、log1 0バイト765、log3 0バイト1,521、log0 32バイト644、log0 96バイト1,156（測定の行そのものの分12前後を含む） | 2026-10-19 |
| Plain・IndexedのgasUsed | Plain `move(アカウント1番, 100)` 24,168、Indexed 24,124 | 2026-10-19 |
| LabelのgasUsed | `label("alice")` 24,571 | 2026-10-19 |
| Marketのサイズ（runtime / creation） | 第105講のバージョン8,107 / 8,803、第106講のバージョン8,173 / 8,869 | 2026-10-19 |
| Marketのガス、gas-reportの最大値（第105講のバージョン / 第106講のバージョン） | addAsset 93,752 / 93,730、deposit 130,278 / 130,240、withdraw 56,949 / 56,908、setStatus 45,732 / 45,732 | 2026-10-19 |
| Marketのガス、anvilのレシート（第105講のバージョン / 第106講のバージョン） | addAsset 93,752 / 93,730、deposit（アカウント0番、100）130,278 / 130,240、deposit（アカウント1番、50）96,078 / 96,040 | 2026-10-19 |
| シグネチャの一覧を照会するコマンド | `cast 4byte-event`：topic0でイベントのシグネチャをopenchain.xyzに問い合わせる | 2026-10-19 |
| 公式ドキュメントのEventsの節 | `indexed`は引数三つまで（匿名イベントは四つ）、トピック一つは32バイト、参照型の引数を`indexed`にすると値のKeccak-256ハッシュがトピックに入る | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `anonymous`イベントとtopic0のないログ | [第107講](../../part6/lecture107/) |
| 同じシグネチャを出す別のコントラクトと、アドレスでのふるい分け | [第107講](../../part6/lecture107/) |
| ログでMarketの状態を組み立て直す、`IMarket`のイベントの規格 | [第107講](../../part6/lecture107/) |
| ブルームフィルタの原理とインデクサ | [第238講](../../part18/lecture238/) |
| 配列・構造体を`indexed`にするときのエンコードの規則の全体 | [第141講](../../part8/lecture141/) |
| 標準が決めているイベントと`indexed`の配置 | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| イベントのコストをめぐる最適化 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| ログを原材料に使う分析 | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| 文字列処理のライブラリと、文字列を扱う関数の集まり | [第116講](../../part6/lecture116/)、[第117講](../../part6/lecture117/)、[第118講](../../part6/lecture118/)、[第126講](../../part7/lecture126/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
