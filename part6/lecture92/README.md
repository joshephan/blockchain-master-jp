# 第92講 コンストラクタと初期化

第6部 言語の詳細 ③ コントラクト・第19章 コントラクトの作成

[← 第91講](../../part5/lecture91/) | [第6部 目次](../) | [第93講 →](../../part6/lecture93/)

## この講義の問い

デプロイ一回につき一回だけ動く関数は何を決め、そうして決めた値はどこで読むのか。

## 実習資料

### 準備

プロジェクトを二つ使う。`before`は第18章の終わりのMarketとデモ用の最小限のトークンTokenだけを残したプロジェクトで、コンストラクタは`admin = msg.sender;`の一行である。`demo`は`forge init`で作った空のプロジェクトからCounterの例を消し、デモ用のコントラクトとコンストラクタを変えたMarketを入れたものである。どちらのプロジェクトにもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。デプロイのデモはローカルのanvilで、既定のアカウント0番・1番（公開されたテスト用の鍵）を`--unlocked --from`で使って動かした。

### コード

| ファイル | 内容 |
|---|---|
| [code/before/foundry.toml](code/before/foundry.toml) | solc 0.8.30に固定 |
| [code/before/src/Market.sol](code/before/src/Market.sol) | 第18章の終わりのバージョンのMarket、コンストラクタは`admin = msg.sender;` |
| [code/before/src/Token.sol](code/before/src/Token.sol) | デモ用の最小限のトークン |
| [code/before/test/Market.t.sol](code/before/test/Market.t.sol) | AdminTest。setUpで`new Market()`、`address(this)`と`admin()`を出力する |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Vault.sol](code/demo/src/Vault.sol) | `constructor(address admin_) payable`、コンストラクタの中の残高・`msg.value`・コードの長さを記録 |
| [code/demo/src/Holder.sol](code/demo/src/Holder.sol) | `IERC20`を受け取るHolderと、ゼロアドレスをはじくHolderChecked |
| [code/demo/src/InitOrder.sol](code/demo/src/InitOrder.sol) | 状態変数の初期値とコンストラクタ本体の順番を記録 |
| [code/demo/src/NoPay.sol](code/demo/src/NoPay.sol) | payableでないコンストラクタ |
| [code/demo/src/Boom.sol](code/demo/src/Boom.sol) | 引数がtrueならリバートするコンストラクタ |
| [code/demo/src/Token.sol](code/demo/src/Token.sol) | デモ用の最小限のトークン |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | コンストラクタを`constructor(address admin_, Rate interestRate_, Ratio collateralRatio_)`に変え、`addAsset`に上限の検査を加えたMarket |
| [code/demo/test/Market.t.sol](code/demo/test/Market.t.sol) | 管理者を引数で渡すsetUp、上限・ゼロアドレスの管理者のテスト |
| [code/demo/bad/CtorPublic.sol](code/demo/bad/CtorPublic.sol) | 可視性を書いたコンストラクタ（Warning 2462） |
| [code/demo/bad/OldName.sol](code/demo/bad/OldName.sol) | コントラクト名と同じ名前の関数（Error 5796） |
| [code/demo/bad/NoPayMaker.sol](code/demo/bad/NoPayMaker.sol) | payableでないコンストラクタに`{value: 1}`（Error 7006） |

`bad/`のファイルは`forge build --offline --force bad/<ファイル>`で一つずつビルドする。

### 実行結果

`before`で`forge test --offline -vv`。テストで`new`で作ると、管理者はテストコントラクトになる。

```
[PASS] test_admin() (gas: 15085)
Logs:
  this           0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
  market.admin() 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
```

`forge inspect Vault abi --offline`（表の見出しは省略）。constructorの行には名前とセレクタがない。

```
| function    | admin() view returns (address)             | 0xf851a440 |
| function    | balanceAtStart() view returns (uint256)    | 0x52174f5c |
| function    | codeLengthAtStart() view returns (uint256) | 0x173dfd98 |
| function    | valueAtStart() view returns (uint256)      | 0xb1e4f367 |
| constructor | constructor(address) payable               |            |
```

デプロイが終わったVaultに`cast send`で`"constructor(address)"`を送った結果。

```
gasUsed              22080
status               0 (failed)
```

`bad/CtorPublic.sol`と`bad/OldName.sol`を`forge build`した結果。

```
Warning (2462): Visibility for constructor is ignored. If you want the contract to be non-deployable, making it "abstract" is sufficient.
```

```
Error (5796): Functions are not allowed to have the same name as the contract. If you intend this to be a constructor, use "constructor(...) { ... }" to define it.
```

同じVaultのバイトコードを引数`0x…bEEF`、`0x…CAFE`で二回デプロイしたあとの`cast keccak $(cast code …)`と`cast storage … 0`。コードは同じで、スロット0だけが違う。

```
0x25088b3175da74102d6cbc640fad5431a846f0f0f33d66c32f8515b75cc8f285
0x25088b3175da74102d6cbc640fad5431a846f0f0f33d66c32f8515b75cc8f285
0x000000000000000000000000000000000000000000000000000000000000beef
0x000000000000000000000000000000000000000000000000000000000000cafe
```

デプロイのトランザクションは`cast tx … to`が空で、`cast tx … input`の最後の32バイトがコンストラクタの引数である。

```
0x6080604052…000000000000000000000000000000000000000000000000000000000000beef
```

Holderの`IERC20 token_`の位置にコードのないアカウントのアドレスやゼロアドレスを入れても、デプロイは成功する。コンストラクタの最初の行でゼロアドレスをはじくHolderCheckedは失敗する。

```
contractAddress      0x0165878A594ca255338adfa4d48449f69242Eb8F
gasUsed              66145
status               0 (failed)
```

InitOrderをデプロイしたあと、`cast call`で`logged()`、`a()`、`b()`、`c()`を読んだ値。

```
[1, 2, 3]
100
2
3
```

Vaultを`--value 1ether`でデプロイすると、コンストラクタの最初の行で残高と`msg.value`はすでに1 etherで、コンストラクタの中のコードの長さは0である。デプロイ後の`cast codesize`は443。

```
1000000000000000000 [1e18]
1000000000000000000 [1e18]
0
443
```

payableでないコンストラクタ。`bad/NoPayMaker.sol`のビルドエラーと、アカウントが1 weiを載せてNoPayをデプロイした結果。

```
Error (7006): Cannot set option "value", since the constructor of contract NoPay is not payable.
```

```
contractAddress      0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6
gasUsed              56313
status               0 (failed)
```

Boomを`true`でデプロイした`cast receipt`。contractAddressは出力されるが、そのアドレスにコードはなく（`cast code` → `0x`）、送ったアカウントのナンスは9から10に上がった。

```
blockNumber          10
contractAddress      0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
gasUsed              61425
logs                 []
status               0 (failed)
```

`demo`で`forge test --offline -vv`。

```
[PASS] test_addAssetAboveCap() (gas: 41239)
[PASS] test_addAssetByAdmin() (gas: 113791)
[PASS] test_addAssetNotAdmin() (gas: 36065)
[PASS] test_admin() (gas: 15085)
Logs:
  this           0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
  market.admin() 0x00000000000000000000000000000000000000Ad
[PASS] test_depositWithdraw() (gas: 328306)
[PASS] test_zeroAdmin() (gas: 5205)
```

Marketを管理者アカウント1番、利率5e16、担保比率の上限80でデプロイしたあと、`cast storage … 0`、`cast storage … 1`、デプロイのinputの最後の96バイトを`cast abi-decode --input "constructor(address,uint256,uint8)"`で解いた結果。

```
0x0000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c85000
0x00000000000000000000000000000000000000000000000000b1a2bc2ec50000
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
50000000000000000 [5e16]
80
```

### 試すときの注意

- コンストラクタにはセレクタがない。デプロイが終わったアドレスに`"constructor(address)"`で送ると、castが作った4バイトを受け取る関数がないので失敗する。
- 失敗したデプロイでも、receiptにcontractAddressが出力される。そのアドレスにコードがあるかどうかは`cast code`で別に確かめる。送ったアカウントのナンスは失敗しても上がる。
- Marketの`admin`は、スロット0にほかの小さな値と一緒に入っている（オフセット2）。スロットの値の右端の2バイトはadminではない。`forge inspect Market storageLayout --offline`で位置を確かめる。
- コンストラクタの引数の値はソースにはない。デプロイのトランザクションのinputの最後とストレージから読む。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、バイトの長さとガスが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節 Creating Contracts | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| `constructor`キーワード | 0.4.22で導入 | 2026-10-19 |
| コントラクト名のコンストラクタの廃止 | 0.5.0から`constructor`キーワードでだけ定義 | 2026-10-19 |
| コンストラクタの可視性 | 0.7.0から不要、デプロイを止めるには`abstract` | 2026-10-19 |
| バイトの長さ | Vaultのバイトコード743、デプロイのinput 775、デプロイ後のコード443 / Market（この講義のバージョン）のバイトコード7,583、デプロイのinput 7,679、デプロイ後のコード6,907 / Boomのデプロイ後のコード172 | 2026-10-19 |
| gasUsed | Vaultにconstructor(address)を送った呼び出し22,080（失敗）、HolderCheckedのゼロアドレスでのデプロイ66,145（失敗）、NoPayの1 weiでのデプロイ56,313（失敗）、Boomのtrueでのデプロイ61,425（失敗） | 2026-10-19 |
| ローカルのanvilでのデプロイアドレス | Vault `0x5FbDB2315678afecb367f032d93F642f64180aa3`、`0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、`0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` / Holder `0x0B306BF915C4d645ff596e518fAf3F9669b97016`、`0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1` / InitOrder `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853` / Market `0xa51c1fc2f0d1a1b8494Ed1FE312d7C3a78Ed91C0` / Token `0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| デプロイのコードとランタイムコード、コンストラクタのコードがデプロイ後のアドレスにない理由 | [第93講](../../part6/lecture93/) |
| コンストラクタの引数がバイトとしてつくやり方と、検証のときの引数合わせ | [第93講](../../part6/lecture93/)、[第130講](../../part8/lecture130/) |
| アドレスの計算式（ナンス、salt）と失敗したデプロイのあとのアドレス | [第94講](../../part6/lecture94/) |
| 状態変数の初期値をランタイムコードに埋め込む`immutable` | [第102講](../../part6/lecture102/) |
| 受け取る関数（`receive`、`fallback`）とイーサの受け取り全般 | [第99講](../../part6/lecture99/) |
| 継承が絡むときのコンストラクタの引数と初期化の順番 | [第114講](../../part6/lecture114/) |
| ライブラリのリンクでコードに残るアドレス | [第117講](../../part6/lecture117/) |
| アップグレード可能なコントラクトと初期化関数 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 管理者の鍵の管理、マルチシグ、管理者の鍵を狙った事件 | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/)、[第179講](../../part11/lecture179/) |
| 分散化の層ごとの分析 | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
