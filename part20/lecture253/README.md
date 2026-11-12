# 第253講 要件定義と判別フィルターの適用

第20部 キャップストーンプロジェクト・第70章 設計と実装

[← 第252講](../../part19/lecture252/) | [第20部 目次](../) | [第254講 →](../../part20/lecture254/)

## この講義の問い

最初から建て直すシステムで、コードより先に書くべきものは何か。ブロックチェーンの上に建てる理由があるかどうかを、どうやって確かめ直すのか。反証の項目から出た例は何になるのか。

## 実習資料

### 準備

キャップストーンは空のリポジトリから建て直す。この講義のバージョンにはMarketのコントラクトがなく、要件のドキュメント、外側の約束（`IMarket`）、中身のない要件テストだけがある。コンパイラ・ビルドの設定は前のバージョン（通しプロジェクトMarketの第53章末のバージョン）の値をそのまま持ってきた。依存関係はforge-std 1.17.0（`lib/forge-std`）一つで、anvilは使わない。

コミット前の確認は六つの段階である：`forge fmt --check`、`forge lint`（名前の検査四つ）、`forge build --sizes`、`forge test`（デプロイ用ビルド）、`FOUNDRY_PROFILE=debug forge test`、`forge snapshot --check`。最後の段階はテストごとにガスを書いた`.gas-snapshot`と比べるので、最初は`forge snapshot --offline`で記録を一度作る。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、`debug`プロファイル、fmtの設定 |
| [code/design/requirements.md](code/design/requirements.md) | 要件：判別フィルターの適用表、機能F-01〜F-10、安全S-01〜S-08、権限A-01〜A-05、運用O-01〜O-02、入れないものN-01〜N-08 |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束：関数22、イベント10、エラー20 |
| [code/test/Functional.t.sol](code/test/Functional.t.sol) | 機能要件のテスト11個（中身なし、`vm.skip(true)`） |
| [code/test/Safety.t.sol](code/test/Safety.t.sol) | 安全の要件のテスト8個（中身なし） |
| [code/test/Access.t.sol](code/test/Access.t.sol) | 権限の要件のテスト5個（中身なし） |
| [code/test/Ops.t.sol](code/test/Ops.t.sol) | 運用の要件のテスト二つ。O-02は監視が呼ぶセレクタが前のバージョンと同じかを確認 |
| [code/test/Interface.t.sol](code/test/Interface.t.sol) | `IMarket`のインターフェースID 0x49ad2287を固定 |

テスト名の前の番号（`test_F01_…`）が`design/requirements.md`の要件番号である。

### 実行結果

`forge test --offline`（中身のないテストはスキップとして数える）：

```
Ran 1 test for test/Interface.t.sol:InterfaceTest
[PASS] test_interfaceId() (gas: 121)
Ran 2 tests for test/Ops.t.sol:OpsTest
[SKIP] test_O01_eventsForStateChanges() (gas: 0)
[PASS] test_O02_monitorSelectors() (gas: 288)
Ran 5 tests for test/Access.t.sol:AccessTest
[SKIP] test_A01_noKeyMovesDeposits() (gas: 0)
[SKIP] test_A02_configWaitsForTimelock() (gas: 0)
[SKIP] test_A03_guardianOnlyPauses() (gas: 0)
[SKIP] test_A04_unpauseNeedsTimelock() (gas: 0)
[SKIP] test_A05_noUpgradePath() (gas: 0)
Ran 8 tests for test/Safety.t.sol:SafetyTest
[SKIP] test_S01_exitPathsNeverPaused() (gas: 0)
...
Ran 11 tests for test/Functional.t.sol:FunctionalTest
[SKIP] test_F01_depositEarnsInterest() (gas: 0)
...
Ran 5 test suites: 2 tests passed, 0 failed, 25 skipped (27 total tests)
```

`forge inspect --offline src/IMarket.sol:IMarket methodIdentifiers`はセレクタ22個を出し、監視が呼ぶ読み取り関数二つは`cast sig "totalDeposits(address)"` → `0xe9403256`、`cast sig "assetCount()"` → `0xeafe7a74`で、前のバージョンと同じである。コミット前の確認六段階は2回実行し、2回とも`ci ok`で終わった。

判別フィルターをキャップストーンのレンディングマーケットに当てた結果は、`design/requirements.md`の最初の表にある。質問1〜4ははい、コストの質問5は条件付きではい（金額が小さいと手数料が利息より大きいので、小さい金額のユーザーは目標から外す、N-08）である。反証の項目「最終決定権の行き着く先が結局一つの主体の鍵か？」は、前のバージョンでははいに近い。管理者の席一つが資産の追加と価格の出どころを決めるからである。この席は権限の要件A-01〜A-05として書き、その要件を守ったバージョンで反証の項目を問い直す。

コストの質問に使った前のバージョンのガス：

| 呼び出し | ガス |
|---|---|
| 預け入れdeposit 100 | 136,902 |
| 借り入れborrow | 204,128 |
| 清算liquidate（資産二つ） | 264,842 |

### 試すときの注意

- 判別ワークシートは1番から順に答え、いいえが出たらその行で止める。反証の項目は1〜5番を全部通過したときだけ答え、はいなら脱落である。根拠の欄は1行で書き、状況が変わったらその行から確認し直す。
- 要件ごとにテスト名を先に付けておくと、中身を埋めていない要件が`skipped`の数として出力に残る。
- 外側の約束（インターフェースと監視が読むセレクタ）をコードより先に固定しておくと、建て直すあいだにインデクサー・監視の側が壊れていないかをテストが知らせてくれる。
- ガスをお金に換えた値は日ごとに変わるので書かなかった。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンと設計が変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| ツール | forge 1.8.3（commit cae51ad4）、solc 0.8.30、forge-std 1.17.0 | 2026-10-21 |
| このバージョンのテスト | 2通過、0失敗、25スキップ（27）、test_O02_monitorSelectors gas 288、test_interfaceId gas 121 | 2026-10-21 |
| IMarket | 関数22、イベント10、エラー20、インターフェースID 0x49ad2287 | 2026-10-21 |
| 前のバージョンの数字 | Market.sol 568行、バージョン説明のコメント53行、講義番号のコメント253行、テスト136 | 2026-10-21 |
| 監査範囲 | 監査したビルドde70fa9e・515 / 217行、前のバージョン2fa6d798・1,014 / 513行 | 2026-10-21 |
| 前のバージョンのガス | deposit100 136,902、borrow 204,128・liquidate 264,842（資産二つ） | 2026-10-21 |
| 講義用の設計値 | 折れ点80%、30分平均、ボーナス5%、一度に借金の50% | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ストレージの欄・権限・信頼の前提・不変条件をコードの前に決める | [第254講](../../part20/lecture254/) |
| 中身のないテスト二十五を埋める | [第255講](../../part20/lecture255/)、[第256講](../../part20/lecture256/)、[第257講](../../part20/lecture257/) |
| 反証の項目を問い直す | [第257講](../../part20/lecture257/) |
| 要件の一覧をテストスイートに | [第258講](../../part20/lecture258/) |
| 要件を利害関係者とすり合わせる手順（会議・承認） | 扱わない |
| 要件番号をコミット・イシューとつなぐこと | 付録 |
| 判別フィルターをほかのサービスの企画に使う事例 | [第3講](../../part1/lecture3/)の付録 |

出典と参考資料は[reference.md](reference.md)にまとめた。
