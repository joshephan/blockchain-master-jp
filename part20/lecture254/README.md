# 第254講 アーキテクチャ設計ドキュメントの作成

第20部 キャップストーンプロジェクト・第70章 設計と実装

[← 第253講](../../part20/lecture253/) | [第20部 目次](../) | [第255講 →](../../part20/lecture255/)

## この講義の問い

デプロイしたら直せないコードを書く前に、何を決めておくのか。どこまでをMarketの中に置き、何を外に置くのか。常に正しくあるべき文を、コードより先に書けるのか。

## 実習資料

### 準備

第253講のバージョンから続ける。この講義のバージョンにもMarketのコントラクトはまだない。コードの前に設計ドキュメント`design/architecture.md`を11の節で立て（9節の標準の対照表は空けておく）、変わらない計算の部品（`MarketMath`）と型（`MarketTypes`）だけを先に書いてテストする。`IPriceFeed`は`IMarket.sol`から`MarketTypes.sol`に移し、インターフェースID（0x49ad2287）はそのままである。依存関係はforge-std 1.17.0（`lib/forge-std`）一つで、anvilは使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、`debug`プロファイル |
| [code/design/requirements.md](code/design/requirements.md) | 要件（第253講のバージョンそのまま） |
| [code/design/architecture.md](code/design/architecture.md) | 設計ドキュメント：1 構成と境界、2 ストレージスロットの地図、3 権限リスト（草案）、4 順番と丸め、5 不変条件、6 信頼の前提、7 攻撃の地図（草案）、8 キーの表、9 標準の対照表（空け）、10 決定記録、11 監査範囲の計画 |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束（IPriceFeedを抜いたバージョン） |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | IERC20、IPriceFeed、AssetConfig・Reserve・Position構造体 |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 計算の部品：`utilization`、`borrowRate`（折れ点）、`interestFor`、`mulDivDown`、`mulDivUp` |
| [code/test/Math.t.sol](code/test/Math.t.sol) | 計算の部品のテスト四つ |
| [code/test/Functional.t.sol](code/test/Functional.t.sol)、[Safety](code/test/Safety.t.sol)、[Access](code/test/Access.t.sol)、[Ops](code/test/Ops.t.sol)、[Interface](code/test/Interface.t.sol) | 要件のテスト（第253講のバージョンそのまま、中身のないものはスキップ） |

### 実行結果

`forge test --offline --match-contract MathTest -vv`：

```
Ran 4 tests for test/Math.t.sol:MathTest
[PASS] test_interestOneYear() (gas: 611)
[PASS] test_rateCurveTable() (gas: 3815)
[PASS] test_roundingDirections() (gas: 548)
[PASS] test_utilizationEmpty() (gas: 404)
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

| テスト | 確かめるもの |
|---|---|
| test_rateCurveTable | 折れ点の利率が年5%で、借りた比率0・20・40・60・80・85・90・95・100% → 利率0・1.25・2.5・3.75・5・30・55・80・105% |
| test_interestOneYear | 借金500、借りた比率50%（年3.125%）、1年 → 利息15.625 |
| test_roundingDirections | 切り捨てと切り上げは余りがあるときだけ1違う（10×1/3 → 3と4、9×1/3 → 3と3） |
| test_utilizationEmpty | 預けた量が0なら借りた比率0（0で割らない） |

全体の`forge test --offline`は6通過、0失敗、25スキップ（31個）で、コミット前の確認六段階は`ci ok`で終わる。

設計ドキュメント10節D-01（言語・コンパイラ）の根拠は、前のバージョンを平らに移したバージョンの結果である：同じテスト136個が通過、ランタイム9,043バイト（デプロイ用バージョン9,006）、測った呼び出し六つのガスの差は48以下。資産数の上限（S-05）の根拠は前のバージョンの清算のガスである：

| 資産数 | 2 | 20 | 100 | 500 |
|---|---|---|---|---|
| 前のバージョンの清算のガス | 264,842 | 387,284 | 931,536 | 3,652,736 |

### 試すときの注意

- デプロイしたあとに直せないもの（ストレージの欄の順番、権限、信頼の前提、不変条件）からドキュメントに書き、コードはそのドキュメントの順番どおりに書く。
- 計算の部品は状態のない`internal pure`関数にして、Marketなしで先にテストする。丸めの方向（渡す値は切り捨て、受け取る値は切り上げ）もこの段階でテストとして固定する。
- 設計値（折れ点80%、傾き年100%、30分平均、清算ラインの間隔5、ボーナス5%、一度に借金の50%、比率の上限80、資産20個）は講義用の値である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンと設計が変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| ツール | forge 1.8.3（commit cae51ad4）、solc 0.8.30、forge-std 1.17.0 | 2026-10-21 |
| このバージョンのテスト | 6通過、0失敗、25スキップ（31）、MathTest四つ gas 611・3815・548・404 | 2026-10-21 |
| 平らなバージョン | テスト136 / 136、ランタイム9,006 / 9,043バイト（debug 19,285 / 19,296）、測った呼び出しのガスの差48以下 | 2026-10-21 |
| 前のバージョンの清算のガス | 資産2・20・100・500個：264,842・387,284・931,536・3,652,736 | 2026-10-21 |
| 講義用の設計値 | 折れ点80%、傾き年100%、30分、清算ラインの間隔5、ボーナス5%、50%、比率の上限80、資産20個 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 設計ドキュメントの順番どおりにMarketを書く | [第255講](../../part20/lecture255/) |
| 9節の標準の対照表を埋める | [第256講](../../part20/lecture256/) |
| 権限リストの設定キーを分ける、停止キーの欄 | [第257講](../../part20/lecture257/) |
| 不変条件をランダムな順番のテストに | [第259講](../../part20/lecture259/) |
| 攻撃の地図を行番号で埋める、信頼の前提を読む側から見る | [第260講](../../part20/lecture260/) |
| 運用アカウントのキーの保管と署名サーバー | [第262講](../../part20/lecture262/) |
| 設計ドキュメントを図（構成図・シーケンス図）で描くツール | 付録 |
| 設計ドキュメントのレビュー会議（誰が承認するか） | 扱わない |

出典と参考資料は[reference.md](reference.md)にまとめた。
