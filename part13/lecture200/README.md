# 第200講 ステーブルコインの種類の分類

第13部 DeFi・第54章 ステーブルコイン

[← 第199講](../../part13/lecture199/) | [第13部 目次](../) | [第201講 →](../../part13/lecture201/)

## この講義の問い

1ドルを目標にするトークンで、1ドルはどこにあるのか。同じERC-20の関数を持つステーブルコインを、何で分けるのか。それぞれの種類は、何が壊れたときに崩れるのか。そういうトークンをMarketに資産として登録すると、何を信じることになるのか。

## 実習資料

### 準備

講義用のステーブルコイン二つ（法定通貨担保型FiatUSD、暗号資産担保型VaultUSD）と、通しプロジェクトMarketのコピーを使う。どちらも実在するトークンのコードではない。Marketのコピーは、連鎖清算まで入ったバージョンのソースを変えず、同じソースのFiatUSD（`test/FiatUSD54.sol`）と確認テスト`StableAsset54.t.sol`だけを足した。二つのプロジェクトとも、forge-std（1.17.0）が必要である（`lib/forge-std`）。デプロイのデモはローカルのanvil一つで、anvilの既定のテスト用の鍵だけで行う。担保率150%、価格1.0・0.8・0.6ドルはおもちゃの値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/stable/src/FiatUSD.sol](code/stable/src/FiatUSD.sol) | 法定通貨担保型のFUSD（decimals 6）。発行者だけがmint・setFrozen、redeemはバーンまで |
| [code/stable/src/VaultUSD.sol](code/stable/src/VaultUSD.sol) | 暗号資産担保型の金庫。担保率150%（MIN_RATIO_PCT）の範囲でVUSDを発行、清算の関数なし |
| [code/stable/src/Toys.sol](code/stable/src/Toys.sol) | テスト用のSimpleTokenと、owner一人が値を書くToyOracle |
| [code/stable/test/Stable200.t.sol](code/stable/test/Stable200.t.sol) | FiatUSDのテスト四つ、VaultUSDのテスト二つ |
| [code/stable/foundry.toml](code/stable/foundry.toml) | ビルド設定（via-IR、optimizerオン、fuzz seedを固定） |
| [code/market/test/StableAsset54.t.sol](code/market/test/StableAsset54.t.sol) | FiatUSDをMarketに登録したあと、発行者がMarketのアドレスを凍結するテスト三つ |
| [code/market/test/FiatUSD54.sol](code/market/test/FiatUSD54.sol) | テストのフォルダに置いたFiatUSD（同じソース） |
| [code/market/src/](code/market/src/) | Marketのソース（変えていない） |
| [code/market/test/](code/market/test/) | Marketの基準のバージョンのテスト全体 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |

### 実行結果

`forge test --offline --match-contract Stable200Test -vv`（六つ通過）：

```
[PASS] test_frozenCannotTransfer() (gas: 159538)
[PASS] test_issuerMints() (gas: 91208)
[PASS] test_mintUpToRatio() (gas: 305919)
[PASS] test_onlyIssuerMints() (gas: 34197)
[PASS] test_priceDropBreaksRatio() (gas: 450234)
Logs:
  price 0.8 value 120000000000000000000
  price 0.6 value 90000000000000000000
[PASS] test_redeemBurnsOnly() (gas: 132055)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

`forge inspect FiatUSD storageLayout`（Offset・Bytes・Contractの列は省略）。issuerはimmutableなので欄がなく、準備金の欄もない。

| スロット | 名前 | 型 |
|---|---|---|
| 0 | totalSupply | uint256 |
| 1 | balanceOf | mapping(address => uint256) |
| 2 | allowance | mapping(address => mapping(address => uint256)) |
| 3 | frozen | mapping(address => bool) |

`forge inspect FiatUSD methodIdentifiers`のセレクタは14個である。EIP-20の関数九つ（name、symbol、decimals、totalSupply、balanceOf、transfer、transferFrom、approve、allowance）のほかに、mint、redeem、setFrozen、issuer、frozenの五つがある。

```
allowance(address,address)            dd62ed3e
approve(address,uint256)              095ea7b3
balanceOf(address)                    70a08231
decimals()                            313ce567
frozen(address)                       d0516650
issuer()                              1d143848
mint(address,uint256)                 40c10f19
name()                                06fdde03
redeem(uint256)                       db006a75
setFrozen(address,bool)               ac869cd8
symbol()                              95d89b41
totalSupply()                         18160ddd
transfer(address,uint256)             a9059cbb
transferFrom(address,address,uint256) 23b872dd
```

ローカルのanvilでアカウント0番（発行者）がFiatUSDをデプロイし、アカウント1番に100 FUSD（100,000,000）を発行してから、アカウント1番を凍結した結果：

```
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
$ cast call $F "totalSupply()(uint256)"
100000000 [1e8]
$ cast storage $F 0
0x0000000000000000000000000000000000000000000000000000000005f5e100
$ cast call $F "issuer()(address)"
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
$ cast call $F "frozen(address)(bool)" $A1
true
$ cast send $F "transfer(address,uint256)" $A0 10000000 --private-key $K1
… AccountFrozen(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
$ cast send $F "mint(address,uint256)" $A1 100000000 --private-key $K1
… NotIssuer(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
$ cast codesize $F
2085
```

セレクタはAccountFrozen 0x4f2a367e、NotIssuer 0x3fd26f9eである。アカウント1番の残高100,000,000はそのままで、1単位も移せない。

- test_redeemBurnsOnly：aliceが100を受け取って40を償還すると、totalSupply 100 → 60、aliceの残高60。残るのはRedeemedイベント一つで、ドルの支払いは発行者がチェーンの外で行う。
- test_mintUpToRatio：COL 150個（150ドル相当）を預けてmint 101 → `Undercollateralized(150e18, 101e18)`、mint 100 → 通る。
- test_priceDropBreaksRatio：金庫のCOL 150個、VUSD 100のままで価格が下がると担保率が崩れる。担保2個を引き出す → `Undercollateralized(88.8e18, 100e18)`。

| COLの価格 | 担保の値 / 借金 | isSafe |
|---|---|---|
| 1.0ドル | 150 / 100 | true |
| 0.8ドル | 120 / 100 | false |
| 0.6ドル | 90 / 100 | false |

Marketのコピーで`forge test --offline --match-contract StableAsset54Test -vvv`（三つ通過）。コピー全体は44スイート139個（元の136 + 3）が通過する。

```
[PASS] test_issuerFreezeBlocksWithdraw() (gas: 130179)
[PASS] test_marketAdminCannotUnfreeze() (gas: 82225)
[PASS] test_unfreezeThenWithdraw() (gas: 162802)
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

発行者がMarketのアドレスを凍結すると、aliceの帳簿100e6、MarketのFUSD残高100e6はそのままなのに、withdrawがトークンのtransferでリバートする（`-vvvv`のトレースの一部、アドレスは省略）。

```
├─ [51523] Market::withdraw(FiatUSD: [0x2e23…470b], 100000000 [1e8])
│   ├─ [2661] FiatUSD::transfer(0x…0A11cE, 100000000 [1e8])
│   │   └─ ← [Revert] AccountFrozen(0x5615…b72f)
```

Marketの管理者がsetFrozenを呼ぶと`NotIssuer(管理者)`になり、発行者が解除してはじめてaliceは100e6を受け取る。

三つの種類の比較：

| 種類 | 1ドルを守るもの | チェーンの中か | 償還すると | 鍵 |
|---|---|---|---|---|
| 法定通貨担保型 | 銀行口座の準備金 | チェーンの外 | 発行者がドルを | 発行者（発行・凍結・償還） |
| 暗号資産担保型 | 預けた暗号資産（担保） | チェーンの中の金庫 | コードが担保を | 価格を書く側、コードを変える側 |
| アルゴリズム型 | 対になるトークンの市場の値 | 対のトークンはチェーンの中、値は市場 | コードが対のトークンを新しく発行して | 対のトークンに値をつける市場 |

### 試すときの注意

- FiatUSDのmintは、発行者がドルを受け取ったかを確かめない。準備金はチェーンの外の資料である。
- ERC-20の関数が同じでも、標準のリストの外の関数（mint、setFrozenなど）がトークンの性質を変える。リストに登録する前に、トークンのコードで発行・凍結の権限とその鍵のアドレスを読んで書いておく。
- 発行者がMarketのアドレスを凍結すると、そのトークンのwithdrawだけでなく、repay・deposit・borrowも一緒にリバートする。Marketの管理者の鍵では解除できない。
- Marketのコピーのテストは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガス記録の照合を切って実行する。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わるとサイズとアドレスが変わりうる。種類ごとの例は名前だけを書いた。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| おもちゃの値 | FUSD decimals 6、VaultUSD担保率150%（MIN_RATIO_PCT）、COLの価格1.0・0.8・0.6ドル（価格の記録1e18 = 1ドル）、Marketの担保率75 | 2026-10-21 |
| ローカルチェーンの値 | FiatUSD `0x5FbDB2315678afecb367f032d93F642f64180aa3`、ランタイム2,085バイト、セレクタAccountFrozen 0x4f2a367e・NotIssuer 0x3fd26f9e | 2026-10-21 |
| テストの数 | Stable200 6個、StableAsset54 3個、Marketのコピー44スイート139個（元の136 + 3） | 2026-10-21 |
| 種類ごとの例の名前 | 法定通貨担保型USDC・USDT、暗号資産担保型DAI（最初の設計）、アルゴリズム型UST。担保の構成・規模・価格・評価は載せない | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 清算の経済（誰がいつ清算するか、清算の報酬） | [第198講](../../part13/lecture198/) |
| オラクルの設計（フィード、更新の周期、複数のオラクル） | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| 準備金の証明と監査報告書の読み方 | 付録 |
| 担保型の設定値を投票で変えること | [第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/)、[第215講](../../part14/lecture215/)、[第216講](../../part14/lecture216/) |
| ほかのチェーンに移したステーブルコイン | [第210講](../../part14/lecture210/) |
| アルゴリズム型が崩れた事件 | [第201講](../../part13/lecture201/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
