# 第191講 Code4rena・Sherlockの仕組みと参加の仕方

第12部 監査の実務・第51章 コンテストの実戦

[← 第190講](../../part12/lecture190/) | [第12部 目次](../) | [第192講 →](../../part12/lecture192/)

## この講義の問い

監査コンテストとは何で、誰が何をし、どんな順番で回っていくのか。見つけた問題はどれが認められ、等級は誰が決めるのか。テストをすべて通ったコードが、なぜコンテストに出てくるのか。参加するには何から始めるのか。

## 実習資料

### 準備

監査対象のバージョンのMarketのリポジトリをそのままコピーして、模擬コンテストのリポジトリとして使う。ソースとテストは変えなかった。テストにはforge-std（1.17.0）が必要である（`lib/forge-std`）。anvilは使わない。コンテストのプラットフォームの公開ドキュメントは読むだけにした。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | Marketのビルド設定（solc 0.8.30、optimizerオン runs 200、via-IRオン、evm osaka） |
| [code/src/](code/src/) | 範囲内のファイル四つ（Market、MarketMath、MarketTypes、IMarket）と、範囲外のテスト用のMockToken |
| [code/test/](code/test/) | 参加者が受け取るテスト一式111個 |

### 実行結果

受け取ったリポジトリがそのまま動くかを、まず確かめる。`forge test --offline`（実行時間は回すたびに違う）：

```
Ran 12 tests for test/ErrorList.t.sol:ErrorListTest
...
[PASS] test_marketFrozen() (gas: 77834)
...
[PASS] test_zeroAmount() (gas: 60211)
...
Ran 40 test suites in 29.25ms (38.32ms CPU time): 111 tests passed, 0 failed, 0 skipped (111 total tests)
```

CIのスクリプト（書式、名前のチェック、ビルドとサイズ、デプロイ用ビルドとdebugビルドのテスト、ガスの記録、ドキュメント）も最後まで回り、`ci ok`で終わる。テストは二つのビルドの両方で111個が通る。

空行とコメント行（`//`、`///`、`/* */`）を除いた行数（nSLOC）：

```
src/Market.sol 123
src/MarketMath.sol 21
src/MarketTypes.sol 26
src/IMarket.sol 47
total 217
```

この値で書いた模擬コンテストのREADMEの欄：

| 欄 | 内容 |
|---|---|
| 範囲 | src/Market.sol 123、src/MarketMath.sol 21、src/MarketTypes.sol 26、src/IMarket.sol 47（nSLOCの合計217、ファイルの行数267・43・41・164の合計515） |
| 範囲外 | src/MockToken.sol（テスト用のトークン）、test/、lib/（forge-std） |
| デプロイの値 | admin 管理者のアドレス（三人中二人のマルチシグ）、interestRate 5e16、collateralRatio 80 |
| 信頼する役割 | 管理者（三人中二人のマルチシグ）：addAsset、setStatus |
| 既知の問題 | 手数料を引いたり残高がひとりでに変わったりするトークンは上場しない / depositを通らずに入ってきたトークンは帳簿の外 / 同じブロックの順番とblock.timestampはブロックを作る側が決める / Market監査報告書の指摘事項（L-01〜L-03、I-01〜I-04） |
| 使うトークン | boolを返すEIP-20標準トークン |

READMEに照らした認定の可否：

| 見つけたもの | どこで | 判定 |
|---|---|---|
| MockTokenのsetBrokenを誰でも呼べて、トークンの移動をすべて差し戻させる | 範囲外のファイル | 認められない |
| 手数料を引くトークンを上場すると、帳簿と実際の残高が分かれる | 既知の問題の欄（上場トークンの行、監査報告書L-01） | 認められない |
| Marketの四つのファイルから出た、一覧にない問題 | 範囲内 | 判定に進む |

管理者がsetStatus(Frozen)で預け入れと資産の追加を止めるケースを、二つのプラットフォームの基準が受け取る方式：

| 基準 | 受け取り方 |
|---|---|
| Sherlockの旧コンテスト基準 | 管理者関数は正しく使われるとみなし、問題としない |
| Code4rena | 権限の誤用はQA報告書の中の項目 |
| 模擬README | 信頼する役割の欄が判定に一緒に入る |

一チームの監査とコンテスト、バグバウンティの違い：

| 欄 | 一チームが担う監査 | コンテスト | バグバウンティ |
|---|---|---|---|
| 対象 | 決めた範囲 | 決められた範囲 | すでにデプロイされたコード |
| 期間 | 契約期間 | 決められた期間、締め切りのあと一度に判定 | なし、いつも開いている |
| 読む人 | 決まった数人が一緒に | あらかじめ決まっていない多数が別々に | 誰でも |
| 受け取るもの | 監査契約 | 認められた問題の分、同じ問題は分け合う | 先に報告した人 |

### 試すときの注意

- テストは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガスの記録の照合を切って回す。`snapshots/`は添付していない。
- nSLOCの数え方はツールとプラットフォームごとに違う。範囲の表には、ファイルの行数と数えた行数を一緒に書き、何を除いたかも書く。
- High・Mediumの提出には、リポジトリのテスト一式で動く再現テスト（PoC）が必要だというルールがある（Code4renaの提出ガイドライン）。再現テストは、受け取ったテスト一式の横に置く。
- 報告書が公開される前は、見つけたものをissue・記事・チャットルームに出さない。コンテストのコードがすでにデプロイされていることがある。
- 等級は提出する人が決めない。プラットフォームのルール文書とそのコンテストのREADMEが決め、判定する側が有効性・等級・重複を決める。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。基準日に公開ドキュメントを読んだ値で、プラットフォームのルールとドキュメントの構成はよく変わるので、参加する前に原文を確かめ直す。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka | 2026-10-21 |
| テスト | 40スイート111個が通過、CIのスクリプトのテストはどちらも111個、Marketのランタイム2,990バイト | 2026-10-21 |
| 行数 | nSLOC（空行・コメント行を除く）Market.sol 123、MarketMath.sol 21、MarketTypes.sol 26、IMarket.sol 47、合計217。MockToken.sol 23。ファイルの行数267・43・41・164（合計515） | 2026-10-21 |
| Code4renaの段階 | 提出期間はたいてい1〜3週間、判定、判定後48時間のQA（PJQA）、報酬は二回に分けて支払い、報告書の公開時に提出もたいてい公開 | 2026-10-21 |
| Code4renaの等級 | High・Medium、QA（Low risk、Governance/Centralization risk）。権限の誤用はQA報告書で提出 | 2026-10-21 |
| Code4renaの提出 | High・Mediumには動くコードのPoCが必要、リポジトリのテスト一式を使う、ライブのコードを含む提出は機密情報 | 2026-10-21 |
| Code4renaの判定 | 判定者が有効性・等級・重複を決める、根本原因が同じなら重複、PJQA以外での判定者への直接連絡は禁止 | 2026-10-21 |
| Code4renaの報酬 | 同じ問題を見つけた人が増えるほど、一人の取り分が減る計算方法 | 2026-10-21 |
| Code4renaへの参加 | 誰でもWardenとして登録して参加 | 2026-10-21 |
| Sherlockのドキュメントの構成 | 旧コンテストのドキュメントはaudit-contests-deprecated-replaced-by-audit-engineのパス、Audit Engineのドキュメントが前。変わった日付・範囲は確認できていない | 2026-10-21 |
| Sherlockの旧判定 | Lead Judgeの予備判定 → 予備結果のあと24時間の異議 → 最終判定 | 2026-10-21 |
| Sherlockの旧基準 | High・Mediumの定義、管理者関数は正しく使われるとみなす、READMEとコードのコメントが食い違えばREADME | 2026-10-21 |
| Sherlock Audit Engine | AIの判定 → Lead Judge → プロトコルチームの意見、等級はCritical・High・Medium・Low・Informational | 2026-10-21 |
| Sherlockへの参加 | Audit Engineでだけ提出、出した文章は取り下げも修正もできない（書き直して新たに提出）、NDA、範囲内の発見の流出は禁止 | 2026-10-21 |
| バウンティのアドレス | Ethereum bounty program bounty.ethereum.org（Solidity SECURITY.md 49行） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 模擬の範囲を実際に分析する | [第192講](../../part12/lecture192/) |
| 提出する文章と異議 | [第193講](../../part12/lecture193/) |
| 自分のプロジェクトを自分で監査する | [第260講](../../part20/lecture260/) |
| プラットフォームごとの参加資格と報酬の計算方法の原文 | 付録のデータシート |

出典と参考資料は[reference.md](reference.md)にまとめた。
