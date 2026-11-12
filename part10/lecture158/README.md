# 第158講 ERC-4626 金庫の標準

第10部 標準とアップグレード・第41章 標準の設計思想

[← 第157講](../../part10/lecture157/) | [第10部 目次](../) | [第159講 →](../../part10/lecture159/)

## この講義の問い

預けた資産を持ち分に替えてくれる金庫は、資産と持ち分を何で数え、標準はその計算をどこまで決めたのか。

## 実習資料

### 準備

プロジェクトは二つある。`demo`は、OpenZeppelinのERC4626を継承しただけの金庫Vaultと、原資産のトークンAssetを置いたデモ用プロジェクトである。`market`は通しプロジェクトMarketの第158講のバージョンである。すべての実行はanvilなしでforgeの中で動く（通しプロジェクトのガスだけローカルのanvil）。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0である。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。デモの金庫はOpenZeppelinの既定値`_decimalsOffset` 0のままである。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/Vault.sol](code/demo/src/Vault.sol) | 原資産Asset（ERC20 + mint）と、ERC4626を継承しただけのVault（"Vault Share"、"vAST"） |
| [code/demo/test/Vault.t.sol](code/demo/test/Vault.t.sol) | 最初の預け入れ、直接送った500、丸め、小さな最初の預け入れ、セレクタ・イベントのテスト五つ |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第158講のバージョンのsrcの五つのファイル。コードは第157講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/Donation.t.sol](code/market/test/Donation.t.sol) | 第158講で足したDonationTestの二つ（depositのセレクタがERC-4626と違う、直接送ったトークンはwithdrawAllのあとも残る） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

`demo`で`forge test --offline -vv`。空の金庫にaliceが1000を承認し、deposit(1000, alice)を呼んだ最初の預け入れ：

```
[PASS] test_firstDeposit() (gas: 199375)
Logs:
  alice shares 1000 totalAssets 1000
  decimals asset/vault 18 18
```

名前は同じで引数の順番が違うdepositの二つ：

| | ERC-4626 | Market |
|---|---|---|
| シグネチャ | deposit(uint256,address) | deposit(address,uint256) |
| セレクタ | 0x6e553f65 | 0x47e7ef24 |
| 引数 | 預ける量、持ち分を受け取る人 | 資産のアドレス、量 |

aliceが1000を預けたあと、bobが金庫のアドレスに500をtransferした。OpenZeppelinのtotalAssetsは金庫のアドレスのトークン残高なので、aliceの持ち分1000の価値が1499になる：

```
[PASS] test_directTransferMovesPrice() (gas: 290390)
Logs:
  before: assets for 1000 shares 1000
  after: totalAssets 1500 totalSupply 1000
  after: assets for 1000 shares 1499
  bob shares 0
```

資産1500、持ち分1000で呼んだ換算の関数と、carolの100 → 66 → 99。carolが入ったあとは資産1600・持ち分1066なので、98ではなく99が出て、1は金庫に残る：

```
[PASS] test_rounding() (gas: 534078)
Logs:
  convertToShares(100) 66
  previewDeposit(100) 66
  previewWithdraw(100) 67
  previewMint(66) 99
  previewRedeem(66) 98
  convertToAssets(66) 98
  carol deposit 100 -> shares 66
  carol redeem -> assets 99
```

| 呼んだ関数 | 値 | 方向 |
|---|---|---|
| convertToShares(100) | 66 | 切り捨て |
| previewDeposit(100) | 66 | 切り捨て（ユーザーに渡す持ち分） |
| previewWithdraw(100) | 67 | 切り上げ（ユーザーから受け取る持ち分） |
| previewMint(66) | 99 | 切り上げ（ユーザーから受け取る資産） |
| previewRedeem(66) | 98 | 切り捨て（ユーザーに渡す資産） |
| convertToAssets(66) | 98 | 切り捨て |

計算はOpenZeppelinの`_convertToShares`が`assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding)`で行う。100 × 1001 ÷ 1501 = 66.68…、66 × 1501 ÷ 1001 = 98.96…である。

小さな最初の預け入れ。aliceが空の金庫に1を預け（持ち分1）、金庫のアドレスに5000を直接送ったあと、bobが4000を預けた：

```
[PASS] test_tinyFirstDeposit() (gas: 411414)
Logs:
  bob deposit 4000 -> shares 1
  bob can redeem 3000
  alice can redeem 3000
  totalAssets 9001
```

bobの持ち分は4000 × (1 + 1) ÷ (5001 + 1) = 1.59… → 切り捨てで1、持ち分一つの価値は1 × (9001 + 1) ÷ (2 + 1) = 3000.66… → 切り捨てで3000である。

| よくある思い込み | 実測（OpenZeppelin 5.4.0のVault） |
|---|---|
| 金庫の標準に従えば資産の計算は合う | 1を預けて5000を送った金庫で、4000 → 持ち分1、引き出せる価値3000 |
| 持ち分一つは資産一つ | 500を直接送ったあと、持ち分1000 = 資産1499 |
| 丸めはユーザーの味方 | 100 → 持ち分66 → 99、引き出すときは持ち分67 |

`market`ではdepositなしで送ったトークンは帳簿に計上されない（test/Receive.t.sol、第158講のバージョンで測り直したガス）：

```
[PASS] test_directTransferNotCounted() (gas: 67752)
```

`market`で`forge test --offline --match-contract DonationTest -vvvv`（トレースの行を縮めて1行にまとめ、アドレスは省略）。aliceが100を預けて50を直接送ったあとでwithdrawAllを呼ぶと、100だけが戻り、50は誰のpositionsにもないまま残る：

```
    ├─ [127515] Market::deposit(MockToken: [...], 100)
    ├─ [34311] MockToken::transfer(Market: [...], 50)
    ├─ MockToken::balanceOf(Market) [staticcall]  ← [Return] 150
    ├─ Market::totalDeposits(MockToken) [staticcall]  ← [Return] 100
    ├─ [54782] Market::withdrawAll(MockToken: [...])
    │   ├─ [12739] MockToken::transfer(0x...A11cE, 100)
    ├─ MockToken::balanceOf(0x...A11cE) [staticcall]  ← [Return] 200
    ├─ MockToken::balanceOf(Market) [staticcall]  ← [Return] 50
    ├─ Market::totalDeposits(MockToken) [staticcall]  ← [Return] 0
[PASS] test_directTransferStaysAfterWithdrawAll() (gas: 260125)
```

| | Vault（OpenZeppelin） | Market |
|---|---|---|
| 資産を数える欄 | 金庫のアドレスのトークン残高 | totalDeposits・positions |
| 直接送ったトークン | 500 → 持ち分1000の価値1499 | 50 → 帳簿の外、最後まで残る |

ERC-4626とMarketの形の対照：

| 欄 | ERC-4626 | Market |
|---|---|---|
| 原資産 | 一つ | 複数（assetsの配列） |
| 持ち分 | ERC-20トークン、移せる | positionsのマッピング、移す関数なし |
| 資産の計算 | totalAssets（実装が決める、OpenZeppelinは残高） | totalDeposits（deposit・withdrawだけが書き換える） |
| deposit | deposit(assets, receiver) | deposit(asset, amount)、受け取る人はmsg.sender |
| withdraw | withdraw(assets, receiver, owner)、他人の持ち分は承認で | withdraw(asset, amount)、自分のものだけ |
| 換算 | convert・preview・max | なし、資産と持ち分は1:1 |

Market第158講のバージョンの点検：`forge build --offline --sizes`でMarket 3,260 / 3,473、`forge test --offline`と`FOUNDRY_PROFILE=debug`・`legacy`はいずれも86個が通過、`.gas-snapshot` 86行、`bash ci.sh`は`ci ok`。

Market第158講のバージョンの標準の対照表に足した行：

| 標準 | Marketが立つ側 | Marketにあるもの | Marketにないもの | 確認するテスト |
|---|---|---|---|---|
| ERC-4626 | 従わない（形の対照だけ） | deposit(address,uint256)・withdraw(address,uint256)、帳簿totalDeposits・positions | 持ち分のトークン、receiver・owner引数、convert・preview・maxの関数、直接送ったトークンは数えない | test/Donation.t.sol、test/Receive.t.sol |

### 試すときの注意

- OpenZeppelin 5.4.0のERC4626のtotalAssetsは、金庫のアドレスの原資産のトークン残高である（ERC4626.solの115〜118行）。標準は"managed"とだけ書き、計算と配分をわざと空けておいた。
- 丸めは金庫の側に寄せる。ユーザーに渡す値（depositの持ち分、redeemの資産）は切り捨て、ユーザーから受け取る値（withdrawの持ち分、mintの資産）は切り上げる。convertToの二つは常に切り捨てる。
- テストで`Market.deposit.selector`と書くと、Error (9582)でビルドが止まる。depositは親のLedgerにある関数だからである。`IMarket.deposit.selector`と書く。
- Marketは利息を帳簿に付けないので資産と持ち分が1:1で、金庫の形（持ち分のトークン）には従わない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| EIP-4626の原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`、`ERCS/erc-4626.md` 612行、status Final、created 2021-12-22、requires 20, 2612、ファイルの最終更新2024-09-25。引用4、16〜19、23〜27、31〜34、43〜46、74〜82、555〜557、587〜588、599〜605行 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（package.json）、MIT。`token/ERC20/extensions/ERC4626.sol` 48・49・115〜118・121〜167・225〜227・232〜234・247・263〜265・279行、`_decimalsOffset`の既定は0。`interfaces/IERC4626.sol` 関数16・イベント2 | 2026-10-20 |
| solc | 0.8.30。デモ用プロジェクトはoptimizerオフ（Foundryの既定値）・evm osaka。Market第158講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacy・debugプロファイル | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| Vaultのテスト | test_firstDeposit 199,375 / test_directTransferMovesPrice 290,390 / test_rounding 534,078 / test_selectorsAndEvents 18,472 / test_tinyFirstDeposit 411,414 | 2026-10-20 |
| Vaultの値 | 最初の預け入れ1000 → 持ち分1000。500を直接 → totalAssets 1500・totalSupply 1000・持ち分1000 = 資産1499。convertToShares(100) 66、previewDeposit(100) 66、previewWithdraw(100) 67、previewMint(66) 99、previewRedeem(66) 98、convertToAssets(66) 98、carol 100 → 66 → 99。1 + 5000を直接 → bob 4000 → 持ち分1、bob・aliceが引き出せる価値3000、totalAssets 9001 | 2026-10-20 |
| セレクタ・トピック | deposit(uint256,address) 0x6e553f65、withdraw(uint256,address,address) 0xb460af94、Marketのdeposit(address,uint256) 0x47e7ef24、Depositのtopic0 0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7、Withdrawのtopic0 0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db、type(IERC4626).interfaceId 0x87dfe5a0 | 2026-10-20 |
| Marketのテストのガス | DonationTest test_depositSelectorDiffersFrom4626 316、test_directTransferStaysAfterWithdrawAll 260,125 / ReceiveTest test_directTransferNotCounted 67,752（第99講のバージョン74,690） | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第158講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ | 第158講のバージョンdefault 3,260 / 3,473 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第158講のバージョンdefault `b31b170f` | 2026-10-20 |
| 行番号 | 第158講のバージョンdebugのdeposit 0 src/Market.sol 170:33、NotActiveの行85、`contract Market` 214行、Ledger 146行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| 120バイトを超える行（src） | 第158講のバージョン91 | 2026-10-20 |
| テストの数 | 第158講のバージョン86（default・debug・legacy）、`.gas-snapshot` 86行 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 金庫の最初の預け入れと直接送ったトークンで持ち分の価値を動かすこと、防ぐ設定（`_decimalsOffset`など） | [第172講](../../part11/lecture172/)、[第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/) |
| SafeERC20を使う理由 | [第171講](../../part11/lecture171/) |
| 利息が帳簿に付くレンディング市場と持ち分の形 | [第197講](../../part13/lecture197/) |
| キャップストーンで金庫の形を取り入れるかを決めること | [第256講](../../part20/lecture256/) |
| 丸めの差をランダムな入力でたたくこと | [第183講](../../part11/lecture183/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
