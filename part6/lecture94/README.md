# 第94講 CREATEとCREATE2

第6部 言語の詳細 ③ コントラクト・第19章 コントラクトの作成

[← 第93講](../../part6/lecture93/) | [第6部 目次](../) | [第95講 →](../../part6/lecture95/)

## この講義の問い

コントラクトのアドレスはどんなバイトをハッシュして出てくるのか。だから同じアドレスは何を保証し、何を保証しないのか。

## 実習資料

### 準備

`forge init`で作った空のプロジェクトからCounterの例を消して始める（`main`）。forge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した（optimizerは切る）。Child.solは第84講のファイルを一文字も変えずに持ってきた。そのためCREATE2アドレスは第84講と同じである。`comment`は`main`のChild.solにコメントを一行だけ加えたバージョンである。Marketは第92講の終わりのバージョンのままで、この講義ではコードを変えない。二つのチェーンの比較は、ローカルのanvilを二つ（チェーンID 31337、31338）立ち上げ、既定のアカウント0〜3番（公開されたテスト用の鍵）を`--unlocked --from`で使って動かした。

### コード

| ファイル | 内容 |
|---|---|
| [code/main/foundry.toml](code/main/foundry.toml) | solc 0.8.30に固定 |
| [code/main/src/Child.sol](code/main/src/Child.sol) | 第84講のChild、PayChild、Factory |
| [code/main/src/SaltFactory.sol](code/main/src/SaltFactory.sol) | `new Child{salt: …}`で作るファクトリと、アドレスを前もって計算する`predictChild` |
| [code/main/src/Boom.sol](code/main/src/Boom.sol) | 第92講のBoom。引数がtrueならコンストラクタがリバートする |
| [code/main/src/Bomb.sol](code/main/src/Bomb.sol) | `selfdestruct`するBombと、同じsaltでBombを作るBombFactory |
| [code/main/src/Market.sol](code/main/src/Market.sol) | 第92講の終わりのバージョンのMarket |
| [code/main/script/DeployMarket.s.sol](code/main/script/DeployMarket.s.sol) | デプロイするアカウントのナンスでMarketのアドレスを前もって計算し、実際のアドレスと比べる |
| [code/main/test/Create2.t.sol](code/main/test/Create2.t.sol) | `test_threeWays`：チートコード、`predictChild`、実際の`makeSalted(1, 5)`のアドレスの比較 |
| [code/main/test/Market.t.sol](code/main/test/Market.t.sol) | setUpで`vm.computeCreateAddress`で前もって計算したアドレスと、実際のMarketのアドレスの比較 |
| [code/comment/src/Child.sol](code/comment/src/Child.sol) | コメントを一行だけ加えたChild |
| [code/comment/src/SaltFactory.sol](code/comment/src/SaltFactory.sol) | `main`と同じファクトリ |
| [code/comment/test/Create2.t.sol](code/comment/test/Create2.t.sol) | `main`と同じテスト |
| [code/comment/foundry.toml](code/comment/foundry.toml) | `main`と同じ設定 |

### 実行結果

CREATEアドレスの手計算。`cast to-rlp`で[アドレス, ナンス]をRLPにし、`cast keccak`の後ろ20バイトを`cast compute-address`と比べる（ナンス0、1）。

```
0xd694f39fd6e51aad88f6f4ce6ab8827279cfffb9226680
0x14a8157e61feefbde33dcc305fbdb2315678afecb367f032d93f642f64180aa3
0x5FbDB2315678afecb367f032d93F642f64180aa3
0xd694f39fd6e51aad88f6f4ce6ab8827279cfffb9226601
0xde7b0c9e87917902152596afe7f1725e7734ce288f8367e1bb143e90bb3f0512
0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

失敗したデプロイもナンスを使う。アカウント2番のナンス0でBoom(true)のデプロイが失敗したあと、ナンスは1で、失敗したアドレスにコードはない。

```
contractAddress      0x663F3ad617193148711d28f5334eE4Ed07016602
gasUsed              61425
status               0 (failed)
```

コントラクトアカウントのナンスは1から始まる。SaltFactoryをデプロイした直後の`cast nonce`は1、`makeSalted`で一つ作ったあとは2である。

CREATE2アドレスの手計算。`0xff`、作る側のアドレス、salt、デプロイのコードのハッシュをつないだ85バイトのkeccakの後ろ20バイトが、`cast create2`の結果と同じになる。

```
0xe0583115733d4ae3288655060cac4b2f7fe8bbef6cccbecc42c39ee55d717396
0xff5615deb798bb3e4dfa0139dfa1b3d433cc23b72f0000000000000000000000000000000000000000000000000000000000000001e0583115733d4ae3288655060cac4b2f7fe8bbef6cccbecc42c39ee55d717396
0xa9d7f1826ecd5fd70c0716421b2a6e68fb3da4528995d51e8c0cc3d0f12601b8
0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8	0x0000000000000000000000000000000000000000000000000000000000000001
```

`forge test --offline -vv --mt test_threeWays`。三つの方法が同じアドレスを出す。

```
  factory    0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
  cheatcode  0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8
  solidity   0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8
  actual     0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8
  init code length 561
```

コメント一行のバージョンと元のバージョンのChildのデプロイのコードの比較。長さは同じで、メタデータの尻尾の中のハッシュ32バイトだけが違う。

```
元のバージョン 529バイト / コメントのバージョン 529バイト
違うバイト：487〜518番目、32個
元のバージョンの尻尾：a2646970667358221220 f39e773df89d27bf6a3590c5a178737848b71baa9382ef95300a98281f0499c9 64736f6c634300081e0033
コメントのバージョンの尻尾：a2646970667358221220 65dfec61064bc17e9ee933d69906408802c32fc4b000be185b2843bfef357454 64736f6c634300081e0033
```

同じ作る側、salt 1、引数5で作った三つのバージョンのCREATE2アドレス。

| Childのバージョン | デプロイのコード | CREATE2アドレス |
|---|---|---|
| 元のバージョン | 529バイト | `0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8` |
| コメント一行のバージョン | 529バイト | `0x5eDCf0586516D60F0EF1707Bb23Cd74615911635` |
| optimizerのバージョン（`--optimize true`） | 266バイト | `0x317eF1a02747A1b17213f629bFA792f04a37407F` |

二つのチェーンでCREATE。同じアカウント、同じナンス0で、チェーンAにはMarket、チェーンBにはChildをデプロイすると、アドレスは同じでコードは違う（`cast codesize` 6907と172）。チェーンBのそのアドレスで`admin()`を呼ぶとリバートする。

```
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

二つのチェーンでCREATE2。二つのチェーンに同じアカウント・ナンスでSaltFactoryをデプロイし、`makeSalted(1, 5)`を呼ぶと、アドレスもコードハッシュも同じになる。

```
0xedd83412e7aefaa49435ae7dd51d1a00a5cf0d79c9b7e77422fea8b8f1cec5ef
0xedd83412e7aefaa49435ae7dd51d1a00a5cf0d79c9b7e77422fea8b8f1cec5ef
```

同じsaltで二回`makeSalted`。ガスの見積もりが先に失敗し、ガスリミットを直接与えるとstatus 0でブロックに入る。

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
gasUsed              985268
status               0 (failed)
```

Bombを作ったあと、別のトランザクションで`boom()`を呼んでも、コード（215バイト）とスロット0（42）が残る。同じsaltでもう一度`make`すると失敗し、`cast run`のトレースに衝突が出力される。

```
    ├─ [0] → new <unknown>@0xa364Ad5776953e9BF8272772e3D4A6605fAFD1e0
    │   └─ ← [CreateCollision]
```

作ったトランザクションの中ですぐ消した`makeAndBoom`は、コードの長さとナンスが0のまま残り、同じsaltで`make`すると、また215バイトのコードができる。

`forge script script/DeployMarket.s.sol --broadcast`と`forge test --offline -vv --mc MarketTest`。前もって計算したアドレスと実際のアドレスが同じである。

```
  deployer nonce 0
  predicted 0x5FbDB2315678afecb367f032d93F642f64180aa3
  actual    0x5FbDB2315678afecb367f032d93F642f64180aa3
ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
```

```
  nonce before     1
  predicted Market 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
  actual Market    0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
```

### 試すときの注意

- `cast send`のオプションは`--create`の前に置く。後ろに置くと`error: unexpected argument '--unlocked' found`が出る。
- CREATE2アドレスの材料になるデプロイのコードには、コンストラクタの引数がつく。`type(Child).creationCode`のあとに`abi.encode(5)`をつないだ561バイトが材料である。
- コメント一行、optimizerの設定一つでもデプロイのコードが変わり、CREATE2アドレスが変わる。アドレスを前もって知らせたデプロイでは、コンパイラのバージョンと設定を固定する。
- Bombをビルドすると、`selfdestruct`の使用中止の警告（Warning 5159）が出る。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやハードフォークが変わると、長さ・ガスが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Expressions and Control Structuresの節のSalted contract creations / create2 | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| anvilのハードフォーク | 既定値`latest`、`anvil_nodeInfo`のhardForkの値`Bpo1` | 2026-10-19 |
| コントラクトアカウントのナンスの初期値 | 1（EIP-161）。SaltFactoryの`cast nonce` 1、作ったChildの`cast nonce` 1 | 2026-10-19 |
| CREATE2 | EIP-1014（Constantinopleハードフォーク）。アドレス = `keccak256(0xff ++ address ++ salt ++ keccak256(init_code))[12:]` | 2026-10-19 |
| `{salt: }`の文法 | Solidity 0.6.2で導入 | 2026-10-19 |
| アドレスの衝突の規則 | 対象のアドレスのナンスが0でないか、コードの長さが0でなければ作成は失敗（EIP-684） | 2026-10-19 |
| selfdestructの動作 | EIP-6780、Cancunハードフォーク（イーサリアムのメインネット 2024年3月）。作ったトランザクションの外ではイーサだけを送り、コード・ストレージを消さない | 2026-10-19 |
| バイトの長さ | ChildのcreationCode 529 / runtimeCode 172 / デプロイのコード + 引数561、コメントのバージョン529、optimizerのバージョン266（+引数298）、Market（第92講のバージョン）のcreationCode 7,583 / runtimeCode 6,907、Boomのランタイム172、Bombのランタイム215 | 2026-10-19 |
| ガス（参考） | Boom(true)のデプロイ失敗のgasUsed 61,425、同じsaltでの二回目のmakeSalted 985,268（ガスリミット1,000,000）、同じsaltでのBombの再make 985,259 | 2026-10-19 |
| forge testのアドレス | 最初に作ったコントラクト`0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f`、salt 1 x 5 `0x1B2A6e68Fb3Da4528995D51e8C0CC3D0F12601B8`、コメントのバージョン`0x5eDCf0586516D60F0EF1707Bb23Cd74615911635`、optimizerのバージョン`0x317eF1a02747A1b17213f629bFA792f04a37407F` | 2026-10-19 |
| ローカルのanvilのアドレス | アカウント0番のナンス0 `0x5FbDB2315678afecb367f032d93F642f64180aa3`（チェーンAのMarket / チェーンBのChild）、SaltFactory `0x8464135c8F25Da09e49BC8782676a84730C318bC`、salt 1 x 5 `0x8d9bd22792E5d29E5d4130595A6a5113251Ee272`、Boomの失敗`0x663F3ad617193148711d28f5334eE4Ed07016602`、Boomの成功`0x2E983A1Ba5e8b38AAAeC4B440B9dDcFBf72E15d1`、BombFactory `0x057ef64E23666F000b34aE31332854aCBd1c8544`、Bomb salt 1 `0xa364Ad5776953e9BF8272772e3D4A6605fAFD1e0`、salt 2 `0xC0C6cCF877E965a90D9F2583c686Fa1655FB0dE9` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `immutable`の値とデプロイのコード | [第102講](../../part6/lecture102/) |
| アセンブリの`create2`と低水準の作成のパターン | [第122講](../../part7/lecture122/) |
| デプロイのコードの構造と最適化の段階 | [第124講](../../part7/lecture124/) |
| コンパイラのオプションとStandard JSON | [第128講](../../part8/lecture128/) |
| コンパイルの再現性とソースの検証の手順 | [第130講](../../part8/lecture130/) |
| IRのコード生成とレガシーの違い、移行 | [第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| ストレージのスロットの配置の規則 | [第135講](../../part8/lecture135/) |
| 前もって計算したアドレスを使う設計（プロキシ、同じアドレスに載せ直すコード） | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| コンストラクタの中の呼び出しとコードの長さの検査の迂回 | [第176講](../../part11/lecture176/) |
| 同じアドレスに別のコードを載せ直す攻撃 | [第164講](../../part10/lecture164/)、[第180講](../../part11/lecture180/) |
| ほかのチェーンの同じアドレスを使うクロスチェーンの設計と事故 | [第208講](../../part14/lecture208/)、[第209講](../../part14/lecture209/)、[第210講](../../part14/lecture210/)、[第211講](../../part14/lecture211/)、[第212講](../../part14/lecture212/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
