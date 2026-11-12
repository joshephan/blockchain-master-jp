# 第249講 CosmWasm

第19部 ほかの実行環境・第68章 EVMの外の実行環境

[← 第248講](../../part19/lecture248/) | [第19部 目次](../) | [第250講 →](../../part19/lecture250/)

## この講義の問い

コントラクトが実行の途中でほかのコントラクトを呼べないようにすると、何が防がれ、何が面倒になるのか。コード1組を複数のインスタンスが使い、管理者がコードを変えられる機械では、「デプロイしたコード」は何を意味するのか。三つの機械を見たあとで、EVMが選んだものは何か。

## 実習資料

### 準備

CosmWasmの「呼ばずにメッセージを返す」実行の形をEVMでまねた小さなFoundryプロジェクト`actor249`一つを使う。依存関係はforge-std（`lib/forge-std`）一つで、anvilは使わない。Rustのwasmターゲットとwasmdは使っておらず、本文のRustのコードはCosmWasmのドキュメントの原文なのでコンパイルしていない。まねたバージョンは同じ考え方をEVMに移したものであり、CosmWasmの実際の動作と同じという意味ではない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka |
| [code/src/Direct249.sol](code/src/Direct249.sol) | EVMの形：関数の途中で外を呼び（`call`）、成功したかどうかだけを書いたまま進む |
| [code/src/Actor249.sol](code/src/Actor249.sol) | アクターの形のまね`Actor249`（送るメッセージ`Msg249`を返す、`reply`）とチェーン側のまね`Router249`（関数が終わったあとにメッセージを順に実行し、失敗したら`replyOnError`のときだけreply、そうでなければ全部巻き戻す） |
| [code/src/Observer249.sol](code/src/Observer249.sol) | 呼ばれる側：呼んだコントラクトの二つの欄`a`・`b`を読んで書き留める、`fail`は常に巻き戻す |
| [code/test/Actor249.t.sol](code/test/Actor249.t.sol) | テスト六つ |

### 実行結果

`forge test --offline -vv`：

```
Ran 6 tests for test/Actor249.t.sol:Actor249Test
[PASS] test_actorFailureRevertsAll() (gas: 99284)
[PASS] test_actorMessageSeesFinal() (gas: 138799)
[PASS] test_actorReplyOnError() (gas: 129071)
[PASS] test_directCallSeesHalf() (gas: 135529)
[PASS] test_directFailureContinues() (gas: 90409)
[PASS] test_onlyRouterRuns() (gas: 35139)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_directCallSeesHalf | 関数の途中で呼んだObserverが見た値はa 1・b 0、終わったあとはb 1 |
| test_actorMessageSeesFinal | 関数が終わったあとに実行されたメッセージが見た値はa 1・b 1 |
| test_directFailureContinues | 呼ばれた側が失敗しても進む：lastOk false、a 2・b 2 |
| test_actorFailureRevertsAll | メッセージの失敗 → `MessageFailed(0)`、a 0・b 0（全部巻き戻し） |
| test_actorReplyOnError | replyOnErrorならa 1・b 1が残り、replies 1、lastReplyOk false |
| test_onlyRouterRuns | ルーターでない側が呼ぶと`OnlyRouter` |

`forge build --offline --sizes`のランタイムサイズはActor249 1,090、Direct249 581、Observer249 505、Router249 963バイトである。

### 試すときの注意

- EVMの形では、外を呼んだ瞬間に自分の状態が半分変わったまま相手に見える（a 1・b 0）。メッセージの形では、状態を全部書いたあとにメッセージが出ていくので、相手は終わった値だけを見る。
- 低水準の`call`は失敗しても自分のコードを止めない。返された成功かどうかを自分で見なければ、失敗が成功として通り過ぎる。
- メッセージの形で失敗を受けて処理するには、replyを別に受け取る必要があり、デフォルト値（`ReplyOn::Success`）なら失敗したメッセージが取引全体を巻き戻す。
- トレースを見るには`forge test --offline -vvvv`で、Direct249・Router249の呼び出しの順番を見る。

## 時効性のあるデータ

基準日時点の値。ドキュメントとツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| CosmWasmドキュメントのコピー | CosmWasm/docs コミットf6672ac0 | 2025-12-03 |
| cosmwasmリポジトリ | CosmWasm/cosmwasm コミット160f8c53、最新リリースv3.0.11（2026-10-08） | 2026-10-21 |
| wasmd | CosmWasm/wasmd コミット64b9bea7（2026-10-09）、`proto/cosmwasm/wasm/v1/tx.proto` | 2026-10-21 |
| Solanaドキュメントのコピー | solana-foundation/solana-com コミット0bcf693a | 2026-10-20 |
| migrate_versionマクロ | ドキュメント原文 "For CosmWasm `v2.2.0` and newer" | 2025-12-03 |
| Foundry・solc | Foundry 1.8.3、solc 0.8.30、optimizerオン runs 200、via-IR、osaka | 2026-10-21 |
| actor249のサイズ | runtime Actor249 1,090 / Direct249 581 / Observer249 505 / Router249 963バイト | 2026-10-21 |
| actor249のテストのガス | directCallSeesHalf 135,529 / actorMessageSeesFinal 138,799 / directFailureContinues 90,409 / actorFailureRevertsAll 99,284 / actorReplyOnError 129,071 / onlyRouterRuns 35,139 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| CosmWasmの保存ライブラリ（cw-storage-plus、storey） | 付録 |
| IBCでほかのチェーンにメッセージを送る | 扱わない |
| アップグレードの鍵をキャップストーンでどう置くか | [第253講](../../part20/lecture253/)、[第254講](../../part20/lecture254/)、[第255講](../../part20/lecture255/)、[第256講](../../part20/lecture256/)、[第257講](../../part20/lecture257/) |
| メッセージの形と呼び出しの形のテスト設計 | [第258講](../../part20/lecture258/)、[第259講](../../part20/lecture259/)、[第260講](../../part20/lecture260/) |
| CosmWasmのガスとSDKのガスの倍率 | 付録（ドキュメント`core_architecture_gas.mdx`の原文まで） |

出典と参考資料は[reference.md](reference.md)にまとめた。
