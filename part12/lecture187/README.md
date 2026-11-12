# 第187講 監査のプロセスと範囲の見積もり

第12部 監査の実務・第50章 監査の方法論

[← 第186講](../../part11/lecture186/) | [第12部 目次](../) | [第188講 →](../../part12/lecture188/)

## この講義の問い

監査を受ければ、コードは安全になるのか。監査する人は正確に何を見るのか。範囲をどう決め、監査が終わったあとでコードが変わっていないことはどうやってわかるのか。

## 実習資料

### 準備

通しプロジェクトMarketの監査対象のバージョン（出金からFrozenの確認を外したバージョン）から始める。Marketのソースは変えず、監査の指摘事項を再現するテスト`Audit50.t.sol`だけを足した。テストにはforge-std（1.17.0）が必要である（`lib/forge-std`）。デプロイの照合は、ローカルのanvil一つで、anvilの既定のテスト用アカウントだけを使って行う。外部への接続はない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | ビルドの設定（solc 0.8.30、optimizerオン runs 200、via-IRオン、evm osaka、bytecode_hash ipfs）。バージョンごとに変えた理由がコメントで残っている |
| [code/src/IMarket.sol](code/src/IMarket.sol) | Marketのインターフェース（範囲内） |
| [code/src/Market.sol](code/src/Market.sol) | 監査対象のMarketの本体（範囲内） |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息計算とポジションのライブラリ（範囲内） |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | ユーザー定義値型と構造体（範囲内） |
| [code/src/MockToken.sol](code/src/MockToken.sol) | テストでだけ使うトークン（範囲外） |
| [code/test/](code/test/) | 基準のバージョンのテスト111個と、監査の再現テスト`Audit50.t.sol`（手数料を引くトークンのような、上場の前提の外のケース） |

### 実行結果

範囲内のファイルの行数（全体 / 空行・コメントを除いた行）。合計は515行 / 217行である。空行と、`//`・`///`で始まる行を除いた。

```
src/IMarket.sol 164 47
src/Market.sol 267 123
src/MarketMath.sol 43 21
src/MarketTypes.sol 41 26
```

`forge inspect Market methodIdentifiers`が見せたセレクタは19個である（表の枠線は省略）。

```
SECONDS_PER_YEAR()                    e6a69ab8
addAsset(address,uint8)               6127548a
admin()                               f851a440
assetConfig(address)                  d6dbaf58
assetCount()                          eafe7a74
assets(uint256)                       cf35bdd0
collateralCount(address)              2f0940d2
collateralRatio()                     b4eae1cb
deposit(address,uint256)              47e7ef24
elapsedOf(address,address)            340ad029
interestFor(uint256,uint256,uint256)  9bcf40a2
interestRate()                        7c3a00fd
positions(address,address)            4bd21445
setStatus(uint8)                      2e49d78b
status()                              200d2ed2
totalBorrows(address)                 8d730124
totalDeposits(address)                e9403256
withdraw(address,uint256)             f3fef3a3
withdrawAll(address)                  fa09e630
```

セレクタ19個のうち、状態を変えるもの5、自動ゲッター10、view 3、pure 1である。監査の範囲の数字で数え直した結果：

| 数えるもの | Market | 位置 |
|---|---|---|
| 状態を変える入口 | 5 | setStatus 99、addAsset 132、deposit 168、withdraw 184、withdrawAll 195 |
| 管理者専用 | 2 | setStatus、addAsset（onlyAdmin） |
| 外へかける呼び出し | 2 | transferFrom 171、transfer 187 |
| block.timestamp | 3 | MarketMath.sol 33・41、Market.sol 215 |
| ループ | 1 | collateralCount 261 |

成果物`out/Market.sol/Market.json`のrawMetadataから読んだソースと設定。ビルドに入ったソースが範囲内のファイル四つと同じである。

```
sources : src/IMarket.sol, src/Market.sol, src/MarketMath.sol, src/MarketTypes.sol
optimizer: {'enabled': True, 'runs': 200}
viaIR    : True
evmVersion: osaka
metadata : {'bytecodeHash': 'ipfs'}
compiler : 0.8.30+commit.73712a01
```

ローカルのanvilに`forge create`でデプロイした結果：

```
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Transaction hash: 0x6dff6ece7a9eb79feb89658387faa86c265679fc41a1cdace4a5db7c8a0e4011
```

`cast code`（チェーンのコード）と`forge inspect Market deployedBytecode`（ビルドのコード）はどちらも2,990バイトで、末尾53バイトが同じである。`ipfs`のあとの32バイトがメタデータのハッシュ、`solc`のあとの`00081e`が0.8.30である。

```
a2 64 69706673 58 22 1220
de70fa9e1585f2dae1720ff3231bcf64fa6532a535aa3488b797d723f0176fba
64 736f6c63 43 00081e 0033
```

丸ごと比べると違うが、違うのはimmutableの三つの値が入る五つの欄だけである（キーの名前は、ASTのノードidを宣言の名前に置き換えて書いた）。

```
immutableReferences (deployedBytecode)
admin           start 333,  2850   length 32   チェーン側の値 0x7099...4f8c
collateralRatio start 693,  1025   length 32   チェーン側の値 0x50
interestRate    start 876          length 32   チェーン側の値 0xb1a2bc2ec50000
ビルド側の五つの欄：すべて0
五つの欄を0で消してから比較：same after zeroing immutables: True
```

| バージョン | ランタイムのサイズ | メタデータのハッシュの先頭4バイト |
|---|---|---|
| 出金からFrozenの確認を外す前のバージョン | 3,260バイト | `408088f5` |
| 監査対象のバージョン | 2,990バイト | `de70fa9e` |

`cast tx <ハッシュ> input`で読んだデプロイのトランザクションは3,299バイト（生成コード3,203 + 引数96）である。末尾96バイトがコンストラクタの引数三つ（admin、interestRate、collateralRatio）である。

```
00000000000000000000000070997970c51812dc3a010c7d01b50e44ef1d4f8c
00000000000000000000000000000000000000000000000000b1a2bc2ec50000
0000000000000000000000000000000000000000000000000000000000000050
```

`cast call`でチェーンから読んだ三つの値も同じである。

```
admin()           0x70997970C51812dc3A010C7d01B50e44Ef1D4f8c
interestRate()    50000000000000000 [5e16]
collateralRatio() 80
```

### 試すときの注意

- メタデータにはソースファイルごとのハッシュが入る。コメントを一行変えただけでも、バイトコードの末尾のメタデータのハッシュが変わる。
- チェーンのコードとビルドのコードを丸ごと比べると、immutableの欄のせいで違って出る。`immutableReferences`の欄を0で消してから比べる。
- adminの欄に別のアドレスが入っても、メタデータのハッシュは同じである。管理者が誰かは、ソースではなくデプロイのトランザクションとチェーンから読む。
- solcの実行ファイルのsha256は、受け取ったファイルが基準である。バージョン名とハッシュを一緒に書く。
- `Audit50Test`を除いて回すと（`forge test --offline --no-match-contract Audit50Test`）、基準のバージョンのテスト111個が通る。このバージョンのfoundry.tomlはガスの記録の照合（`gas_snapshot_check`）をオンにしているが、`snapshots/`は添付していないので、最初に回すときは`FOUNDRY_GAS_SNAPSHOT_CHECK=false`で切る。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンやコードが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30+commit.73712a01、実行ファイルのsha256 `ccbd3ed44d5fbd26fe039702d403421f1212d2e8752e3cbe3bfd074986911586` | 2026-10-21 |
| ビルドの設定 | optimizerオン runs 200、via-IRオン、evm osaka、bytecode_hash ipfs、cbor_metadataオン | 2026-10-21 |
| 0.8.30の既知のバグ | 四つ（設定の条件は一致、Marketのソースの条件は0か所） | 2026-10-21 |
| Marketのランタイム | 2,990バイト、メタデータのハッシュ`de70fa9e1585f2dae1720ff3231bcf64fa6532a535aa3488b797d723f0176fba`、生成コード3,203バイト | 2026-10-21 |
| 前のバージョン（出金からFrozenの確認を外す前） | 3,260バイト、ハッシュの先頭4バイト`408088f5` | 2026-10-21 |
| immutableの欄 | admin 333・2850、collateralRatio 693・1025、interestRate 876（各32バイト） | 2026-10-21 |
| テストの数 | 基準のバージョンで111 passed（`Audit50.t.sol`を足すと117） | 2026-10-21 |
| 監査報告書の公開場所の例 | Trail of Bits（公開リポジトリpublications）、OpenZeppelin（監査記事の公開） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| チェックリストと精読の順番 | [第188講](../../part12/lecture188/) |
| 指摘事項の深刻度 | [第189講](../../part12/lecture189/) |
| 報告書の書き方（指摘事項の本文、修正の提案、修正の確認） | [第190講](../../part12/lecture190/) |
| コンテストの範囲文書の形 | [第191講](../../part12/lecture191/) |
| 検証サービスに実際に上げて照合する（外部への接続） | 付録 |
| コンパイラのバージョンを実際に上げる判断 | 付録（バージョンを上げる手順） |
| プロキシの後ろの実装を範囲に入れる順番 | 付録 |

出典と参考資料は[reference.md](reference.md)にまとめた。
