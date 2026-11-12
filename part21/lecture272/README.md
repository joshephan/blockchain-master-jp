# 第272講 CBDC・規制と全体の回収

第21部 事件アーカイブと終章・第75章 権力・規制と設計思想

[← 第271講](../../part21/lecture271/) | [第21部 目次](../)

## この講義の問い

中央銀行が直接デジタルのお金を出すと、最初にブロックチェーンが解こうとした問題（帳簿1組、順番、確定）はどこに戻るのか。台帳を誰が握るか、取り消せるか、誰が見るかで三つのお金を分けると、何が見えるのか。規制の要求はシステムのどの欄に入ってくるのか。

## 実習資料

### 準備

公開チェーン上のコントラクトの二つの欄（取り消し、誰が見るか）をローカルのanvilで確かめる。通しプロジェクトMarketの第53章末のバージョンのsrcをそのまま使う（キャップストーンの最後のバージョンではないが、取り消しとログの読み取りはどのバージョンでも同じである）。forgeでビルドし、castでデプロイ・呼び出しをする。依存関係はforge-std（`lib/forge-std`）である。

anvil（Foundry 1.8.3）をブロック間隔1秒で立ち上げ、0番アカウントが`MockToken`と`Market`（admin = 0番アカウント、利率5e16、担保比率80）をデプロイしたあと、`addAsset`（75）を呼ぶ。アカウント4が100、アカウント5が40を預ける。次に三つを見る。(1) アカウントなしで`cast logs`で`Deposited`のログを全部読む。(2) `evm_snapshot`を撮り、アカウント4が100を引き出したあと`evm_revert`で取り消し、引き出した取引のレシートをもう一度尋ねる。(3) ブロックヘッダーのminerの欄を読む。`evm_snapshot`・`evm_revert`はanvilの開発用のコマンドである。アカウントはanvilのデフォルトのテスト用アカウントで、実際の資産には使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka |
| [code/src/Market.sol](code/src/Market.sol) | 通しプロジェクトMarket（第53章末のバージョン）。冒頭のコメントに、第25章 第115講末のバージョンから第53章 第199講末のバージョンまでのバージョンの説明が1行ずつ残っている |
| [code/src/IMarket.sol](code/src/IMarket.sol) | Marketのインターフェース（`Deposited`イベントなど） |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息・持ち分の計算ライブラリ |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/src/MockToken.sol](code/src/MockToken.sol) | テスト用のトークン |

### 実行結果

以下のブロックの「==」の見出しと各行の前の説明は、castの呼び出しをまとめたシェルが付けた見出し（このシェルは付録に入れていない）である。

デプロイと、(1) アカウントなしで読んだ`Deposited`のログ：

```
== デプロイ(0番アカウント): MockToken, Market(admin = 0番アカウント, 5e16, 80), addAsset 75
token 0x5FbDB2315678afecb367f032d93F642f64180aa3
market 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
== (1) どのアカウントもなしで読む: Depositedのログ全部
block 6 user 0x15d34aaf54267db7d7c367839aaf71a00a2c6a65 amount 100
block 7 user 0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc amount 40
block-number 7
```

(2) ノード一つが握る台帳で引き出しを取り消した結果と、(3) ブロックヘッダーのminer：

```
== (2) ノード一つが握る台帳: evm_snapshot → アカウント4 withdraw 100 → evm_revert
snapshot id 0x0
withdraw tx 0x6f48996cc23967e3ecf656df14bca5e936dbcad178c98688837770337a2ed987
block-number 8
token.balanceOf(アカウント4) = 100
depositOf(アカウント4) = 0
evm_revert -> true
block-number 7
token.balanceOf(アカウント4) = 0
depositOf(アカウント4) = 100
eth_getTransactionReceipt(withdraw tx) = null
== ブロックヘッダーのminer(ブロックを作る側)
0x0000000000000000000000000000000000000000
```

Marketが通ってきた道。第53章末のバージョンの`src/Market.sol`のバージョン説明のコメント（`grep -c '末の版'`）と、キャップストーンの最後のバージョンのsrc・設計ドキュメントで同じものを数えた結果：

```
== 前のバージョン(第53章末のバージョンのコピー) src/Market.sol
grep -c '末の版' src/Market.sol = 53
講義番号が付いたsrcのコメント行 = 253
srcに名前が残った講義の数 = 81
== キャップストーンの最後のバージョン(第72章末のバージョンのコピー)
grep -c '末の版' src/*.sol:
src/IMarket.sol:0
src/Market.sol:0
src/MarketMath.sol:0
src/MarketTypes.sol:0
講義番号が付いたsrcの行 = 0
決定記録の行 = 18
要件の表の行(F/S/A/O/N) = 37
F 10
S 8
A 5
O 5
N 9
```

第53章末のバージョンのバージョン説明のコメントの最初の行は「第25章 第115講末の版」、最後の行は「第53章 第199講末の版」である。キャップストーンの最後のバージョンは、その場所を決定記録18行（D-01 言語・コンパイラ〜D-18 リハーサルへの対応）と要件の表（F 10、S 8、A 5、O 5、N 9）に移した。

### 試すときの注意

- ノード一つが台帳を握ると、ブロック番号（8 → 7）、残高（100 → 0）、帳簿（0 → 100）が戻り、引き出した取引のレシートも消える（null）。anvilでは開発用のコマンドがそれをする。大勢が同じ計算をするチェーンには、このコマンドはない。
- `cast logs`は、アカウントなしでも誰がいくら預けたかを全部読む。チェーンに残るのはアドレスと金額で、そのアドレスが誰かはチェーンの外の資料で探す。
- anvilのブロックヘッダーのminerの欄は0である。ローカルのチェーンでブロックを作る側は、そのノード一つである。
- デモ用のMarketは、adminが0番アカウントの第53章末のバージョンである。キャップストーンの最後のバージョンの権限構造（設定キー = タイムロック2日、停止キー = マルチシグ）とは違う。

## 時効性のあるデータ

基準日時点の値。原文のページとツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| ECB Digital euroの定義 | "The digital euro would be a digital form of cash, issued by the central bank and available to everyone in the euro area." / "a central bank digital currency, an electronic equivalent to cash" | 2026-10-21 |
| ECB Digital euroの進行 | 2025年10月 Governing Council: "the Eurosystem will move to the next phase of the digital euro project" / 2026年7月 rulebook草案0.91公開 / 2027年 試験 / "We aim to be ready for a potential first issuance of the digital euro during 2029"（2026年のEU法の採択が条件） | 2026-10-21 |
| ECB Digital euroのプライバシー・オフライン | "The ECB and the Eurosystem would not be able to identify who you are or what you are buying from the payment data we get" / "You could pay in digital euro either online or offline" | 2026-10-21 |
| 法令（ステーブルコイン・暗号資産） | 載せない（原文を開いて名前・日付を確認できなかった） | 2026-10-21 |
| 国ごとのCBDCの数・進行段階 | 載せない（確認できなかった） | 2026-10-21 |
| ローカルのチェーン | anvil（Foundry 1.8.3）、`evm_snapshot`・`evm_revert`はanvilの開発用のコマンド、ブロック間隔1秒 | 2026-10-21 |
| ツール | Foundry 1.8.3（forge・cast・anvil）、solc 0.8.30 | 2026-10-21 |
| デモ用のMarket | 第53章末のバージョンのsrc | 2026-10-21 |
| 基準のバージョン（ドキュメントの読み取り） | キャップストーンの最後のバージョン（決定記録D-01〜D-18、要件A-05・S-01） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 国ごとのCBDCの進行状況 | 付録のデータシート（出典・日付） |
| ステーブルコイン・暗号資産の法令 | 付録のデータシート（確認できたものだけ、今はなし） |
| CBDCのプライバシー技術（ゼロ知識証明など） | 扱わない |
| ホールセール型CBDCと銀行間決済 | 扱わない |
| ステーブルコインの規制（[第267講](../../part21/lecture267/)の先送りにしたテーマ） | この講義（規制の要求が入ってくる欄） |
| キャップストーンのバージョンでMarketの道を書き直す | この講義（Marketが通ってきた道） |

出典と参考資料は[reference.md](reference.md)にまとめた。
