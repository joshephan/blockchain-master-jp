# 第105講 イベントの宣言と発行

第6部 言語の詳細 ③ コントラクト・第23章 イベントとログ

[← 第104講](../../part6/lecture104/) | [第6部 目次](../) | [第106講 →](../../part6/lecture106/)

## この講義の問い

`event`を宣言して`emit`で出すと、その記録はどこにつき、いくらかかり、誰が読み直せて、実行がリバートしたらどうなるのか。

## 実習資料

### 準備

通しプロジェクトのMarketのこの講義のバージョン（`market`）は、第104講のバージョンに四つのイベント（`AssetAdded`、`StatusChanged`、`Deposited`、`Withdrawn`）を宣言し、`addAsset`、`setStatus`、`deposit`、`withdraw`の最後の行で出すバージョンである。`withdrawAll`は、中で呼ぶ`withdraw`が出す。`test/Events.t.sol`を新しく入れ、IMarketとセレクタのテストはそのままである。`demo`は`forge init`で作った空のプロジェクトからCounterの例を消して始めた。`bad/`の下のフォルダは、エラーのソースを一つずつビルドするプロジェクトである。どれもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。レシートとトレースは、ローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を`--unlocked --from`で使って見た。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | この講義のバージョンのMarket。四つのイベントの宣言と発行 |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | 第103講のインターフェースのまま |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Events.t.sol](code/market/test/Events.t.sol) | `addAsset`、`setStatus`、`deposit`・`withdrawAll`が出すイベントの確認 |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol)、[Getters.t.sol](code/market/test/Getters.t.sol)、[Receive.t.sol](code/market/test/Receive.t.sol)、[WithdrawAll.t.sol](code/market/test/WithdrawAll.t.sol)、[Selectors.t.sol](code/market/test/Selectors.t.sol)、[Status.t.sol](code/market/test/Status.t.sol) | 前の講義で加えたテスト |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Ev.sol](code/demo/src/Ev.sol) | 宣言と発行（Note）、同じ値をストレージに積むバージョン（History）、出してからリバート（Fail）、内側の呼び出しだけがリバート（Inner、Outer）、同じ名前で引数の型が違う（Over） |
| [code/bad/noemit/src/X.sol](code/bad/noemit/src/X.sol) | `emit`なしでイベントを呼ぶ（Error 3132） |
| [code/bad/emitexpr/src/X.sol](code/bad/emitexpr/src/X.sol) | `emit`を式として使う（Error 6933） |
| [code/bad/wrongtype/src/X.sol](code/bad/wrongtype/src/X.sol) | 引数の型が違う（Error 9553） |
| [code/bad/mapping/src/X.sol](code/bad/mapping/src/X.sol) | マッピングをイベントの引数に（Error 3448） |
| [code/bad/dup/src/X.sol](code/bad/dup/src/X.sol) | 名前と引数の型が同じ宣言が二つ（Error 5883） |
| [code/bad/readlog/src/X.sol](code/bad/readlog/src/X.sol) | イベントの値をコントラクトから読む（Error 9582） |
| [code/bad/viewemit/src/X.sol](code/bad/viewemit/src/X.sol) | view関数で`emit`（Error 8961） |
| [code/bad/filelevel/src/X.sol](code/bad/filelevel/src/X.sol) | ファイルレベルで宣言したイベント（ビルドは通る） |

`bad/`の下のフォルダごとに同じ設定のfoundry.tomlがあり、フォルダで`forge build --offline`でビルドする。

### 実行結果

`bad/`のビルド結果（ファイルレベルの宣言`filelevel`は`Compiler run successful!`）。

```
Error (3132): Event invocations have to be prefixed by "emit".
Error (6933): Expected primary expression.
Error (9553): Invalid type for argument in function call. Invalid implicit conversion from literal_string "one" to uint256 requested.
Error (3448): Type containing a (nested) mapping is not allowed as event parameter type.
Error (5883): Event with same name and parameter types defined twice.
Error (9582): Member "n" not found or not visible after argument-dependent lookup in event Noted(address,uint256).
Error (8961): Function cannot be declared as view because this expression (potentially) modifies the state.
```

名前が同じでも、引数の型が違えば別のイベントである（`cast sig-event`）。

```
0xdf7a95aebff315db1b7716215d602ab537373cdb769232aae6055c06e798425b
0x3c4dbb057f7df48b080ac34e14a9186ad0847e234436b06de4078464d5936c62
```

Noteの`note(7)`を`cast send --json`で送ったレシート（gasUsed 23,176）のログの部分。ログは、出したコントラクトのアドレス、トピック、dataと一緒にレシートにつく。

```
"logs": [{
  "address": "0x5fbdb2315678afecb367f032d93f642f64180aa3",
  "topics": ["0x89e703998a4a2f9a875399f420ba8ca67bb71952ecb8e87599cf13d528f65972"],
  "data": "0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
           0000000000000000000000000000000000000000000000000000000000000007",
  "blockNumber": "0x6",
  "transactionHash": "0xcff63363038bb97d7eaa825f142599d78de80502b7e3a35162260e7fdb85ea9a",
  "logIndex": "0x0",
  "removed": false
}]
```

（`data`は見やすいように32バイトで改行した。）`topics`の最初の値は、イベントのシグネチャのkeccak256である。`cast sig-event`、`cast keccak`、コントラクトの中の`Noted.selector`（`topic0()`）がすべて同じになる。

```
0x89e703998a4a2f9a875399f420ba8ca67bb71952ecb8e87599cf13d528f65972
0x89e703998a4a2f9a875399f420ba8ca67bb71952ecb8e87599cf13d528f65972
0x89e703998a4a2f9a875399f420ba8ca67bb71952ecb8e87599cf13d528f65972
```

ログはストレージに書かない。`note`を二回送ったNoteの`cast proof`はstorageHashが空のストレージの値で、同じ値を配列に積むHistoryはstorageHashが変わる（`keep(7)`のgasUsed 65,924 / 48,824）。

```
  "balance": "0x0",
  "codeHash": "0x5c24e0b4b3a14ff53d2686f8b49fca35cec910187ba97edb6469aa5d57097897",
  "nonce": "0x1",
  "storageHash": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
```

```
  "storageHash": "0x876e1e78cd35c68cbec7d585be466726659ce5f744376535611053886f5aaaed",
```

出してからリバートするFailの`tryIt(5)`。ガスの見積もりで先に止まり、ガスリミットを与えるとstatus 0でブロックに入り、レシートのログは空である。トレースには出した記録が見える。

```
Error: Failed to estimate gas: ... execution reverted: no ...
blockNumber          11
gasUsed              45380
logs                 []
status               0 (failed)
0
```

```
Traces:
  [24176] 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0::tryIt(5)
    ├─ emit Tried(n: 5)
    └─ ← [Revert] no
```

Outerの`go(3)`。内側の呼び出しだけがリバートすると、内側で出した`InnerLog`だけが消え、外側の`Before`、`After`はレシートに残る（status 1、ログ2件）。

```
  logIndex 0  address 0xcf7e...0fc9 (Outer)  topics [0x7ce90b35...] Before  data 3
  logIndex 1  address 0xcf7e...0fc9 (Outer)  topics [0xd826f927...] After   data 0 (false)
```

```
  [9760] 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9::go(3)
    ├─ emit Before(n: 3)
    ├─ [1844] 0xd8058efe0198ae9dD7D563e1b4938Dcbc86A1F81::run(3)
    │   ├─ emit InnerLog(n: 3)
    │   └─ ← [Revert] inner failed
    ├─ emit After(ok: false)
    └─ ← [Stop]
```

`market`で`forge test --offline --mc EventsTest`と全体のテスト。

```
[PASS] test_addAssetEmits() (gas: 106762)
[PASS] test_depositWithdrawAllEmit() (gas: 287957)
[PASS] test_setStatusEmits() (gas: 56004)
Ran 7 test suites in 10.69ms (7.98ms CPU time): 19 tests passed, 0 failed, 0 skipped (19 total tests)
```

この講義のバージョンのMarketのイベントの一覧。

| イベント | シグネチャ | topic0の先頭4バイト | 出す関数 | 載せた値 |
|---|---|---|---|---|
| AssetAdded | `AssetAdded(address,uint8)` | 0x57c9e281 | addAsset | 資産のアドレス、担保比率 |
| StatusChanged | `StatusChanged(uint8,uint8)` | 0xe1377aa2 | setStatus | 変える前の状態、変えた状態 |
| Deposited | `Deposited(address,address,uint256)` | 0x8752a472 | deposit | 資産のアドレス、預け入れたアカウント、金額 |
| Withdrawn | `Withdrawn(address,address,uint256)` | 0xd1c19fbc | withdraw（withdrawAll経由を含む） | 資産のアドレス、引き出したアカウント、金額 |

### 試すときの注意

- イベントのシグネチャには外部の型が入る。`Ratio`は`uint8`、enumの`MarketStatus`は`uint8`と書かれる。
- コントラクトは、自分が出したログを読み直せない。判断に使う値は状態変数に置く。
- リバートした呼び出しで出したログは、レシートに残らない。トレース（`cast run`）には出した記録が見えるが、チェーンに残るのはレシートである。
- リバートするトランザクションは、`--gas-limit`なしで送るとガスの見積もりで止まる。レシートを見るには、ガスリミットを与える。
- イベントを加えた分だけガスが増える。StatusTestの最大値で、addAsset 92,023 → 93,752、deposit 128,291 → 130,278である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、サイズとガスが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity公式ドキュメント Contractsの節 Events（latestのバージョンで確認） | 2026-10-19 |
| ファイルレベルのイベント | 0.8.22から（"Allow defining events at file level."）、0.8.30でビルドは通る | 2026-10-19 |
| イベントの`.selector` | 0.8.15から | 2026-10-19 |
| ほかのコントラクトのイベントを名前つきで出す（`emit Market.Deposited(...)`） | 0.8.21から | 2026-10-19 |
| ログのガスの規則 | LOGの基本375、トピック一つに375、dataのバイトあたり8、メモリ拡張のコストは別 | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| Note・HistoryのgasUsed | `note(7)` 23,176 / 23,176、`noteNamed(7)` 23,198、`keep(7)` 65,924 / 48,824 | 2026-10-19 |
| Fail・OuterのgasUsed | `tryIt(5)` 45,380（status 0、ガスリミット100,000）、`go(3)` 30,964 | 2026-10-19 |
| Marketのサイズ | 第104講のバージョンのruntime 7,779 / creation 8,475、第105講のバージョン8,107 / 8,803 | 2026-10-19 |
| Marketのガス | `forge test --offline --gas-report --mc StatusTest`の最大値、第104講のバージョン / 第105講のバージョン：addAsset 92,023 / 93,752、deposit 128,291 / 130,278、setStatus 43,852 / 45,732、withdraw 54,959 / 56,949。anvilのレシートのgasUsedも第105講のバージョンの値と同じ | 2026-10-19 |
| ローカルのanvilのアドレス | Note `0x5FbDB2315678afecb367f032d93F642f64180aa3`、History `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Fail `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、Outer `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`（Inner `0xd8058efe0198ae9dD7D563e1b4938Dcbc86A1F81`）、Over `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、MockToken `0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0`、Market `0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ログの欄の構造、`indexed`とtopic0、ノードにかける条件 | [第106講](../../part6/lecture106/) |
| `anonymous`イベント、チェーンの外でのログの読み取りと組み立て直し | [第107講](../../part6/lecture107/) |
| カスタムエラー | [第108講](../../part6/lecture108/)、[第109講](../../part6/lecture109/) |
| 継承とイベント | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| インラインアセンブリとLOG命令 | [第119講](../../part7/lecture119/)〜[第127講](../../part7/lecture127/) |
| イベントのコストをめぐる最適化 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 最後の行で出す順番を、外部呼び出しと合わせて考えること | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| インデクサとチェーンの再編成への対応 | [第238講](../../part18/lecture238/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
