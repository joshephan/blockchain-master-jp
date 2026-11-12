# 第250講 Vyper

第19部 ほかの実行環境・第69章 EVMの中のほかの言語

[← 第249講](../../part19/lecture249/) | [第19部 目次](../) | [第251講 →](../../part19/lecture251/)

## この講義の問い

同じEVMの上でSolidity以外の言語を選ぶと、何が変わるのか。Vyperは何をわざと外し、外したものはバイトコードではどれだけ違ってくるのか。Pythonのように見える言語はPythonのように動くのか。言語が代わりに入れてくれる安全装置は、誰を信じることなのか。

## 実習資料

### 準備

プロジェクトを三つ使う。`market`は通しプロジェクトMarketの第53章末のバージョンのコピーで、比較の基準である。`flat`はそのコピーで`src/Market.sol`一つだけを「平らなバージョン」（Vyperが入れていない文法であるmodifier、継承、演算子の定義、usingを取り除いてSolidityで書き直した344行のバージョン）に替えたものである。残りのsrc・test・foundry.tomlは`market`と同じなので、ここには変えたファイルだけを入れた。`lang250`は負の数の割り算と再入ロックを見る小さなプロジェクトである。

依存関係はforge-std（`lib/forge-std`）と、`lang250`のOpenZeppelin Contracts 5.4.0 `contracts/utils/ReentrancyGuard.sol`の1ファイルである（`lib/oz/utils/ReentrancyGuard.sol`に置き、`@oz/`のremappingで呼ぶ）。anvilは使わない。Vyperのコンパイラは使っておらず、本文のVyperのソース（`storage.vy`、`safe_remote_purchase.vy`）はVyperのドキュメントの原文なのでコンパイルしていない。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（デプロイ用ビルドはvia-IR・optimizerオン runs 200・osaka、`debug`・`legacy`プロファイル） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 基準のバージョンのMarket（第53章末のバージョン、568行、親三つとmodifierを含む） |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | Marketのインターフェース |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | 利息・ポジション計算ライブラリ |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | ユーザー定義型と演算子、構造体、インターフェース |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | デモ用トークン |
| [code/market/test/](code/market/test/) | Marketのテスト136個（ガスのテスト`Gas.t.sol`を含む）、二つのバージョンともこのテストで確認 |
| [code/flat/src/Market.sol](code/flat/src/Market.sol) | 平らなバージョンのMarket（344行、親なしで`contract Market is IMarket`一つ） |
| [code/lang250/foundry.toml](code/lang250/foundry.toml) | solc 0.8.30、via-IR、`@oz/`のremapping |
| [code/lang250/src/Div250.sol](code/lang250/src/Div250.sol) | int256の割り算`a / b`と余り`a % b` |
| [code/lang250/src/Lock250.sol](code/lang250/src/Lock250.sol) | ReentrancyGuardを継承し、ロック一つを二つの関数`a`・`b`が共有する |
| [code/lang250/test/Lang250.t.sol](code/lang250/test/Lang250.t.sol) | テスト二つ：負の数の割り算、ロック一つ |

### 実行結果

二つのバージョンを同じ方法で測った結果（`forge test --offline`、`FOUNDRY_PROFILE=debug forge test --offline`、`forge build --offline --sizes`、`forge inspect ... methodIdentifiers`・`storageLayout`、GasTestのガス記録）：

| 項目 | 基準のバージョン | 平らなバージョン |
|---|---|---|
| テスト（デプロイ用ビルド / debugビルド） | 136 / 136通過 | 136 / 136通過 |
| セレクタ一覧38個、保存スロット0〜7 | 同じ | 同じ |
| ランタイムサイズ（デプロイ用 / debug） | 9,006 / 19,285バイト | 9,043 / 19,296バイト |
| initcodeサイズ（デプロイ用 / debug） | 9,233 / 19,870バイト | 9,284 / 19,898バイト |
| addAsset / deposit / withdraw | 92,861 / 136,902 / 66,415 | 92,813 / 136,902 / 66,415 |
| setStatus 1 / setStatus 0 / 失敗するdeposit | 45,059 / 23,147 / 26,356 | 45,035 / 23,123 / 26,356 |

基準のバージョンの`deposit`をたどって読むと、親三つ（MarketBase、AssetRegistry、Ledger）とほかのファイル二つ（MarketMath.sol、MarketTypes.sol）を行き来する。平らなバージョンの`deposit`は検査の順番（市場の状態、上場の確認、金額の確認）が同じで、上から下へ9行である。

PythonとSolidityの負の数の割り算（`python -c`、`lang250`で`forge test --offline -vv`）：

```
$ python -c "print(-1//2, -7//2, -7%2)"
-1 -4 1

$ forge test --offline -vv
[PASS] test_negativeDivisionRoundsTowardZero() (gas: 10535)
[PASS] test_oneLockForBoth() (gas: 96158)
Suite result: ok. 2 passed; 0 failed; 0 skipped
```

| 計算 | Python | Solidity int256 | Vyperドキュメント |
|---|---|---|---|
| -1割る2 | -1 | 0 | 0 |
| -7割る2 | -4 | -3 | |
| -7の2での余り | 1 | -1 | |

Vyperの値はドキュメントの原文（`types.rst`のnote、"`-1 // 2` will return `-1` in Python, but `0` in Vyper"）であり、コンパイラで実行した値ではない。

`forge inspect src/Lock250.sol:Lock250 storageLayout`は`_status`がスロット0、`count`がスロット1である。`test_oneLockForBoth`：スロット0の最初の値1 → `b()`を単独で呼ぶとcount 10 → `a()`は中で`this.b()`を呼び、`ReentrancyGuardReentrantCall`で巻き戻る → count 10、スロット0の値は1のまま。

### 試すときの注意

- Marketの`foundry.toml`は、ガス記録（`snapshots/Market.json`）と照らし合わせる設定（`gas_snapshot_check = true`）がオンになっている。ガス記録ファイルなしで実行するときは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`を与え、GasTestの値を新しく残すには`FOUNDRY_GAS_SNAPSHOT_EMIT=true`で`--match-contract GasTest`を実行する。
- 平らなバージョンもdebugビルド（via-IRオフ）では`liquidate`の中のローカル変数が多くてStack too deepが出るので、`_checkLiquidation`・`_moveCollateral`は同じコントラクトのinternal関数として残した。
- `flat`を自分で作るには、`market`フォルダをコピーして`src/Market.sol`だけを替える。
- Pythonの`print(2**256)`は78桁の整数をそのまま出力する。VyperはPythonのように見えるがEVMで動くので、整数があふれると巻き戻り、負の数の割り算は0の側に切り捨てる。
- `nonReentrant`を付けた関数どうしは互いに呼べない（OpenZeppelinの原文 "functions marked `nonReentrant` may not call one another"）。ロックの欄の位置と値は継承したソースに書かれており、Vyperの`@nonreentrant`はコンパイラが決める（上書きしなければスロット0）。

## 時効性のあるデータ

基準日時点の値。ドキュメントとツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Vyperドキュメントの基準のバージョン | v0.4.3（"Buttermilk Racer"、2025-06-19） | 2026-10-21 |
| Vyperのセキュリティ勧告 | GHSA-5824-cm3x-3c38、公開2023-08-05、critical、影響 ">= 0.2.15, < 0.3.1"、修正バージョン0.3.1 | 2026-10-21 |
| Vyper 0.3.1のリリース | 2021-12-01、Fixes "Fix allocation of unused storage slots (#2439, #2514)" | 2026-10-21 |
| Solidityドキュメント | v0.8.36（Safe Remote Purchase、Language Influences） | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0（ReentrancyGuard.solのファイル冒頭 "last updated v5.1.0"） | 2026-10-21 |
| Foundry・solc | forge 1.8.3（commit cae51ad4）、solc 0.8.30 | 2026-10-21 |
| ビルド設定 | デプロイ用ビルドvia-IR、optimizerオン runs 200、evm osaka / debugビルドoptimizerオフ、via-IRオフ | 2026-10-21 |
| サイズ | 基準のバージョン（第53章末のバージョン）runtime 9,006 / creation 9,233、debug 19,285 / 19,870 / 平らなバージョン9,043 / 9,284、debug 19,296 / 19,898 | 2026-10-21 |
| ガス（GasTestの記録） | 基準のバージョンaddAsset75 92,861、deposit100 136,902、withdraw30 66,415、setStatus1 45,059、setStatus0 23,147、failDeposit0 26,356 / 平らなバージョン92,813、136,902、66,415、45,035、23,123、26,356 | 2026-10-21 |
| Lang250のテストのガス | test_negativeDivisionRoundsTowardZero 10,535、test_oneLockForBoth 96,158 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Vyperのモジュール（0.4の`import`・`uses`・`initializes`）でコードを分ける方法 | 付録 |
| Vyperコンパイラの出力（`-f layout`・`source_map`・integrityハッシュ）の実際の確認 | 付録 |
| Curve事件の攻撃の過程 | 扱わない（事件の再分類は[第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/)） |
| Vyperのdecimalと固定小数点の計算 | 付録 |
| 同じプロトコルを二つの言語で書いたバージョンの同等性の確認 | [第258講](../../part20/lecture258/)、[第259講](../../part20/lecture259/)、[第260講](../../part20/lecture260/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
