# 第41講 モジュール式のコントラクト

第3部 Solidity入門・第10章 Solidity by Example

[← 第40講](../../part3/lecture40/) | [第3部 目次](../) | [第42講 →](../../part4/lecture42/)

## この講義の問い

コントラクトをいくつもの部品に分けるとき、分け方によってデプロイと信頼はどう変わるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトから`src`、`test`、`script`のCounterのファイルを消し、下のファイルを入れる。テストにはforge-stdが必要である（`lib/forge-std`）。`src/Modular.sol`は、Solidity公式ドキュメントv0.8.36のSolidity by ExampleにあるModular Contractsの例の原文そのままである。同じトークンを、internalライブラリ（原文）、継承、publicライブラリの3通りで作って比べる。コンパイルできない例は`src`の外の`bad/`に置き、パスを指定して別にビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルド時のlintをオフ |
| [code/src/Modular.sol](code/src/Modular.sol) | 公式ドキュメントの原文。internalライブラリBalancesとToken |
| [code/src/Inherit.sol](code/src/Inherit.sol) | 同じmoveを親コントラクトBalancesBaseに置いて継承したTokenInh |
| [code/src/PublicLib.sol](code/src/PublicLib.sol) | moveをpublicに変えたライブラリBalancesPubとTokenPub |
| [code/src/IToken.sol](code/src/IToken.sol) | インターフェースIToken、それで呼び出すCaller、同じ関数の形だけをそろえたFakeToken |
| [code/bad/NoOverride.sol](code/bad/NoOverride.sol) | virtual・overrideなしで親の関数を上書きしようとするバージョン（コンパイルエラー） |
| [code/test/Modular.t.sol](code/test/Modular.t.sol) | transferと、受け取る側の残高がいっぱいの場合 |

### 実行結果

`forge test`。`test_TransferToFullBob`のFAILは意図した結果である。0.8.30では、moveの2番目のrequireに届く前に、足し算がPanic 0x11でリバートする：

```
[PASS] test_Transfer() (gas: 75958)
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_TransferToFullBob() (gas: 39641)
Suite result: FAILED. 1 passed; 1 failed; 0 skipped
```

`forge build --sizes`（区切り線は省略）：

```
| Contract  | Runtime Size (B) | Initcode Size (B) | Runtime Margin (B) | Initcode Margin (B) |
| Caller    | 769              | 797               | 23,807             | 48,355              |
| FakeToken | 570              | 598               | 24,006             | 48,554              |
| Token     | 2,337            | 2,365             | 22,239             | 46,787              |
| TokenInh  | 2,312            | 2,340             | 22,264             | 46,812              |
| TokenPub  | 2,173            | 2,201             | 22,403             | 46,951              |
```

表にないライブラリBalancesPubは、成果物のJSON基準でランタイム978バイトである。TokenPubが小さいのは、moveの本体が外にあるからである。TokenPubの成果物のlinkReferences：

```
{'src/PublicLib.sol': {'BalancesPub': [{'start': 957, 'length': 20}, {'start': 1204, 'length': 20}]}}
```

Token・TokenInhのlinkReferencesは`{}`、ITokenのバイトコードは`0x`である。

`forge build bad/NoOverride.sol`（出力の一部）：

```
Error (9456): Overriding function is missing "override" specifier.
  --> bad/NoOverride.sol:15:5:
   |
15 |     function move(address from, address to, uint amount) internal {

Error (4334): Trying to override non-virtual function. Did you forget to add "virtual"?
 --> bad/NoOverride.sol:7:5:
  |
7 |     function move(address from, address to, uint amount) internal {
```

ローカルのanvilに3通りをデプロイし（TokenPubはBalancesPubを先にデプロイしてから`--libraries`でリンク）、`cast index address <アカウント> 0`で求めた残高の欄に`cast rpc anvil_setStorageAt`で残高を書き込んだあと、10ずつtransferしたガス：

| バージョン | デプロイのガス | transfer（初めて受け取るアドレス / 2回目） |
|---|---|---|
| internalライブラリ（Token） | 557,979 | 52,988 / 35,888 |
| 継承（TokenInh） | 552,573 | 52,958 / 35,858 |
| publicライブラリ（BalancesPub + TokenPub） | 264,763 + 522,508 = 787,271 | 57,252 / 40,152 |

publicライブラリのバージョンは、別のアドレスのコードにもう一度渡るので、呼び出しのたびに4,264ガス多くかかる。

Caller（Tokenの残高100を書き込んだ）が三つの相手に`send`した結果。コードのないアドレスはリバートされ、FakeTokenは何も移さずにtrueを返す：

```
$ cast call $CALLER "send(address,address,uint256)(bool)" $TOKEN $TO 30
true
$ cast code 0x000000000000000000000000000000000000dEaD
0x
$ cast call $CALLER "send(address,address,uint256)(bool)" 0x...dEaD $TO 30
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call $CALLER "send(address,address,uint256)(bool)" $FAKE $TO 30
true
$ cast call $FAKE "balanceOf(address)(uint256)" $TO
1000000 [1e6]
```

`cast send`で送ったCaller経由のsendのgasUsedは、Token相手が57,693、FakeToken相手が27,094（ログ0個）である。

### 試すときの注意

- 原文のTokenには、残高を最初に満たす関数がない。テストでは`vm.store`、anvilでは`anvil_setStorageAt`で、残高の欄に値を直接書き込む。balancesが0番のスロットなので、欄の番号は`keccak256(abi.encode(アカウント, 0))`である。
- インターフェースは関数の形だけを約束する。相手のアドレスのコードがその約束どおりに動くかどうかは、呼び出す側が別に確かめる必要がある。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidity公式ドキュメントのバージョン | v0.8.36（Solidity by Example、Modular Contracts） | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerオフ（デフォルト） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 (cae51ad) | 2026-10-19 |
| ランタイムコードのサイズの上限 | 24,576バイト（EIP-170） | 2026-10-19 |
| ランタイムのサイズ | Token 2,337 / TokenInh 2,312 / TokenPub 2,173 / BalancesPub 978（バイト） | 2026-10-19 |
| デプロイのガス | Token 557,979 / TokenInh 552,573 / BalancesPub 264,763 / TokenPub 522,508 | 2026-10-19 |
| transferのガス（初めて受け取るアドレス / 2回目） | Token 52,988 / 35,888、TokenInh 52,958 / 35,858、TokenPub 57,252 / 40,152 | 2026-10-19 |
| Caller経由のsendのガス | Token相手57,693、FakeToken相手27,094（ログ0個） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 継承の線形化の規則、super、多重継承のoverride(A, B) | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| ライブラリの文法全体（using for、リンクの方式、委任呼び出しの詳細） | [第116講](../../part6/lecture116/)、[第117講](../../part6/lecture117/)、[第118講](../../part6/lecture118/) |
| コントラクト型、インターフェースの文法 | [第56講](../../part4/lecture56/)、[第115講](../../part6/lecture115/) |
| トークン標準（ERC-20）とapproveの構造 | [第154講](../../part10/lecture154/)、[第155講](../../part10/lecture155/) |
| 外部コントラクト呼び出しの危険と防御 | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| アップグレード可能なコントラクト（差し替える構造） | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| コードを分ける場所を監査で読む順番 | [第188講](../../part12/lecture188/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
