# 第247講 Solana SVMとアカウントモデル

第19部 ほかの実行環境・第68章 EVMの外の実行環境

[← 第246講](../../part18/lecture246/) | [第19部 目次](../) | [第248講 →](../../part19/lecture248/)

## この講義の問い

EVMはコントラクト一つにコードとストレージの欄を束ねた。その二つを切り離した機械では何が変わるのか。取引が触るアカウントを前もって書かせると何が得られ、その代わりにプログラムは何を自分で確かめなければならないのか。

## 実習資料

### 準備

Solanaの「プログラムとデータアカウント」をEVMでまねた小さなFoundryプロジェクト`acct247`と、通しプロジェクトMarket（第53章末のバージョン）のコピーの二つを使う。依存関係はforge-std（`lib/forge-std`）一つである。Marketのコピーはコードを変えずにanvilに載せ、`cast access-list`だけを実行する（デモ用トークン`MockToken` → Marketのデプロイ、`addAsset`のあと）。まねたバージョンは同じ考え方をEVMに移したものであり、Solanaの実際の動作と同じという意味ではない。Solana CLIとAnchorは使っておらず、本文に載せたRustのコードはSolana・Anchorのドキュメントの原文なのでコンパイルしていない。

### コード

| ファイル | 内容 |
|---|---|
| [code/acct247/foundry.toml](code/acct247/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka |
| [code/acct247/src/Counter247.sol](code/acct247/src/Counter247.sol) | EVMの形のCounter：コードとストレージの欄が一つのアドレスに束ねられる |
| [code/acct247/src/CounterData247.sol](code/acct247/src/CounterData247.sol) | データアカウントのまね：値だけを置き、ownerとして書かれたプログラムだけが`write` |
| [code/acct247/src/CounterProgram247.sol](code/acct247/src/CounterProgram247.sol) | プログラムのまね：状態変数なし、直すデータアカウントを引数で受け取りownerを確認（`WrongOwner`） |
| [code/acct247/test/Acct247.t.sol](code/acct247/test/Acct247.t.sol) | テスト四つ：コード2組・値はそれぞれ、プログラム一つ・アカウント三つ、ownerだけが書き込み、他人のプログラムのアカウントを拒否 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（第53章末のバージョン） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 通しプロジェクトMarket（第53章末のバージョン）のコピー |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | Marketのインターフェース |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | 利息・ポジション計算ライブラリ |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | ユーザー定義型、構造体、インターフェース |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | デモ用トークン（承認なしで移す） |

### 実行結果

`forge test --offline -vv`（acct247）ではテスト四つがすべて通る。そのうちプログラムのまね側の三つ：

```
[PASS] test_oneProgramManyAccounts() (gas: 522878)
[PASS] test_onlyOwnerWrites() (gas: 152792)
[PASS] test_foreignAccountRejected() (gas: 156725)
```

| テスト | 結果 |
|---|---|
| test_evmCounterKeepsItsOwnSlot | 2組デプロイ、a 2・b 1、aのスロット0 = 2、コード長は同じ |
| test_oneProgramManyAccounts | アカウント三つが2・1・0、プログラムのスロット0 = 0、owner = プログラムのアドレス |
| test_onlyOwnerWrites | テスト用アカウントが`write(100)` → `NotOwner`、count 0 |
| test_foreignAccountRejected | 別のCounterProgram247が作ったアカウントを渡すと`WrongOwner(アカウントのアドレス, 本当のowner)`、count 0のまま |

`forge inspect ... storageLayout`では、CounterProgram247が空の表、CounterData247とCounter247は`count`がスロット0である。`forge build --offline --sizes`のランタイムサイズはCounter247 231、CounterData247 347、CounterProgram247 1,196バイトである。

Marketのコピーで0番アカウントが`deposit(トークン, 100)`を呼ぶときの`cast access-list ... --json`の出力を、アドレスと欄のキーの行に縮めて書いたもの（出力の順番どおり）。「トークン」はアドレスの前に付けた見出しである：

```
Market 0xe7f1…0512
  0x00…00
  0x14eee9…5903a3
  0x14eee9…5903a5
  0x39e199…3b57aa
  0x4ace22…692070
  0xa682d4…fec1cb
  0xcf5ad8…2a43ef
  0xcf5ad8…2a43f0
  0xcf5ad8…2a43f1
トークン 0x5FbD…0aa3
  0x00…01
  0x723077…8da722
  0xb5b22d…75bb37
```

`cast index address <キー> <スロット>`で照らし合わせた欄の読み解き：

| 欄のキー | 意味 |
|---|---|
| Market 0x00…00 | status（スロット0） |
| Market 0x4ace22… | assetConfig[トークン]（スロット2） |
| Market 0x14eee9…a3 / …a5 | positions[トークン][0番アカウント] deposited / lastUpdate・useAsCollateralの欄（スロット3） |
| Market 0xa682d4… | totalDeposits[トークン]（スロット4） |
| Market 0x39e199… | totalBorrows[トークン]（スロット5） |
| Market 0xcf5ad8…ef / …f0 / …f1 | reserves[トークン] borrowIndex / supplyIndex / lastAccrual（スロット6） |
| トークン 0x00…01、0x723077…、0xb5b22d… | broken / balanceOf[0番アカウント] / balanceOf[Market] |

呼ぶ人と金額によってリストが変わる：

| 呼び出し | Marketの欄 | トークンの欄 |
|---|---|---|
| 0番アカウントがdeposit 100 | 九つ | 三つ |
| 0番アカウントがwithdraw 30 | 七つ（status・assetConfigなし） | 三つ |
| 0番アカウントがdeposit 0 | 二つ、巻き戻し | なし |
| 1番アカウントがdeposit 1 | 九つ（positionsの欄が1番アカウントのもの） | 二つ（balanceOf[1番アカウント]）、巻き戻し |

まねたバージョンをanvilに載せると、CounterProgram247の`create()`のガスは123,256、`increment`のガスは48,236で、`increment`のaccess-listにはデータアカウントのスロット0一つだけが出る。プログラムのアドレスのスロット0は0、データアカウントのスロット0は1である。

### 試すときの注意

- EVMのアクセスリストは、ノードが一度実行してみないと出てこない。同じ関数でも、誰が呼ぶか、金額が0かによって触る欄が変わる。
- スロット5・6（totalBorrows、reserves）は、預ける前に利息を積む行（`_accrue`）が読む。貸し出された分が0なので、指数の欄には書かない。価格の欄（priceConfig、スロット7）は読まない。
- `deposit 100`の出力はMarketのアドレスが先に、`withdraw 30`はトークンのアドレスが先に出る。
- Solana側のPDA計算は、ドキュメント（`pda_pda-derivation.mdx`）の原文の要約が基準である：シード + プログラムID + bumpをSHA-256でハッシュし、Ed25519曲線の外のアドレスが出るまで回し、最初に曲線の外になる値がcanonical bumpである。シードは最大16個、一つにつき最大32バイト。`["user", user_pubkey]`をシードにすると、ユーザーごとに違うPDAが出る。

## 時効性のあるデータ

基準日時点の値。ドキュメントとツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solanaドキュメントのコピー | solana-foundation/solana-com コミット0bcf693a（`apps/docs/content/docs/en/core/`） | 2026-10-20 |
| ドキュメントが指すソースのバージョン | agave v3.1.8、solana-sdk clock@v2.2.3 | 2026-10-20 |
| Anchorドキュメント・ソースのコピー | solana-foundation/anchor コミット0d36a0b9 | 2026-10-20 |
| 基本手数料 | 署名一つあたり5,000 lamports | 2026-10-20 |
| 取引一つあたりのコンピュートユニット上限 | 1.4M CU | 2026-10-20 |
| アカウントのdataの最大 | 10 MiB（10,485,760バイト） | 2026-10-20 |
| 命令一つあたりのdata増加の限度 | 10 KiB（10,240バイト） | 2026-10-20 |
| 命令スタックの深さ（最上位 + CPI） | 5、SIMD-0268なら9 | 2026-10-20 |
| 保存の保証金の式 | (account_size + 128) × 3,480 lamports/byte-year × 2 years | 2026-10-20 |
| Counterアカウント16バイトの保証金の計算 | (16 + 128) × 3,480 × 2 = 1,002,240 lamports（識別子8 + u64 8） | 2026-10-21 |
| 移行案内の記事 | "Moving from Ethereum Development to Solana"、2024-04-16 | 2026-10-20 |
| Cardanoドキュメント | docs.cardano.org "Extended UTXO model" | 2026-10-21 |
| Foundry・solc | Foundry 1.8.3（forge・cast・anvil）、solc 0.8.30、optimizerオン runs 200、via-IR、osaka | 2026-10-21 |
| access-listの測定条件 | 新しいanvil、ブロック間隔1秒、0番アカウントがMockToken → Market（0番アカウント, 5e16, 80）をデプロイ、addAsset 75 gasUsed 92,861 | 2026-10-21 |
| Market deposit 100 | gasUsed 136,902 | 2026-10-21 |
| acct247のサイズ | runtime Counter247 231 / CounterData247 347 / CounterProgram247 1,196バイト | 2026-10-21 |
| acct247のガス | create() 123,256、increment 48,236（anvil） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| PDAのアドレス計算とbump | 付録（ドキュメントの原文まで） |
| Solanaの取引の構造、バージョン付きの取引、アドレス照会表 | 付録 |
| 渡されたアカウントの確認を抜かしたバグの実例 | 扱わない |
| 同じことをSolidityの形とアカウントの形で書いたバージョンのテスト設計 | [第258講](../../part20/lecture258/)、[第259講](../../part20/lecture259/)、[第260講](../../part20/lecture260/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
