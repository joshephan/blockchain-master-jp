# 第66講 動的配列とpush・pop

第4部 言語の詳細 ① ファイルと型・第14章 参照型

[← 第65講](../../part4/lecture65/) | [第4部 目次](../) | [第67講 →](../../part4/lecture67/)

## この講義の問い

長さがコードに書かれていない配列は長さをどこに置き、`push`1回は何を書き換え、長さを他人が伸ばすと何が変わるのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクト（`demo/`）から、Counterのファイルを消して始める。コンパイルが拒否される例は、別のプロジェクト`bad/`に置く（foundry.tomlとlibはdemoと同じ）。テストにはforge-stdが必要である（`lib/forge-std`）。デプロイと送信は、ローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を使って行い、ビルドはすべて`--offline`である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/demo/src/List.sol](code/demo/src/List.sol) | `uint256[]`へのpush・pop、真ん中の要素の削除（`removeAt`）、長さの分だけ回る`sum` |
| [code/demo/src/Fixed.sol](code/demo/src/Fixed.sol) | 固定配列の後ろに動的配列を置いた、欄の配置の確認用 |
| [code/demo/src/Items.sol](code/demo/src/Items.sol) | 構造体の配列に`push()`で空の要素をつけ、storageの参照で埋める |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しのプロジェクトのMarket。管理者だけが資産を`IERC20[] assets`に追加 |
| [code/demo/test/List.t.sol](code/demo/test/List.t.sol) | 空の配列のpop、範囲外の読み取り（どちらも意図した失敗）、removeAtの結果 |
| [code/demo/test/Items.t.sol](code/demo/test/Items.t.sol) | addItem、管理者・管理者でない人のaddAsset |
| [code/bad/foundry.toml](code/bad/foundry.toml) | demoと同じ設定 |
| [code/bad/src/PopValue.sol](code/bad/src/PopValue.sol) | `pop()`の戻り値を受け取ろうとする行。Error (7364) |
| [code/bad/src/SetLength.sol](code/bad/src/SetLength.sol) | `list.length = 0;`。Error (7567) |
| [code/bad/src/MemPush.sol](code/bad/src/MemPush.sol) | memory配列へのpush。Error (4994) |

### 実行結果

`bad/`で`forge build --offline src/<ファイル>.sol`：

```
Error (7364): Different number of components on the left hand side (1) than on the right hand side (0).
 --> src/PopValue.sol:8:9:
  |
8 |         uint256 x = list.pop();
  |         ^^^^^^^^^^^^^^^^^^^^^^

Error (7567): Member "length" is read-only and cannot be used to resize arrays.
 --> src/SetLength.sol:8:9:
  |
8 |         list.length = 0;
  |         ^^^^^^^^^^^

Error (4994): Member "push" is not available in uint256[] memory outside of storage.
 --> src/MemPush.sol:7:9:
  |
7 |         r.push(1);
  |         ^^^^^^
```

`demo/`で`forge inspect --offline <コントラクト> storageLayout`（見出しの行は省略）。動的配列は、長さに関係なく欄を一つだけ占める：

```
| slots | uint256[10] | 0  | 0 | 320 | src/Fixed.sol:Fixed |
| list  | uint256[]   | 10 | 0 | 32  | src/Fixed.sol:Fixed |
| list | uint256[] | 0 | 0 | 32 | src/List.sol:List |
| items | struct Items.Item[] | 0 | 0 | 32 | src/Items.sol:Items |
| admin  | address           | 0 | 0 | 20 | src/Market.sol:Market |
| assets | contract IERC20[] | 1 | 0 | 32 | src/Market.sol:Market |
```

`forge test --offline`。最初の二つの失敗は意図したものである：

```
[FAIL: panic: array out-of-bounds access (0x32)] test_outOfRange() (gas: 74655)
[FAIL: panic: called `.pop()` on an empty array (0x31)] test_popEmpty() (gas: 28679)
[PASS] test_removeAt() (gas: 288189)
[PASS] test_addAssetAdmin() (gas: 75407)
[PASS] test_addAssetNotAdmin() (gas: 29657)
[PASS] test_addItem() (gas: 101031)
```

anvilにListをデプロイし、10、20、30を`add`したあとに欄を読んだ結果。gasUsedは最初のaddが65925、次のaddが48825、48825である。スロット0には長さ3があり、要素はkeccak256(0)から続く欄にある：

```
$ cast storage <List> 0
0x0000000000000000000000000000000000000000000000000000000000000003
$ cast keccak $(cast to-uint256 0)
0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
$ cast storage <List> 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563   → ...0a
$ cast storage <List> 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e564   → ...14
$ cast storage <List> 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e565   → ...1e
```

`removeLast()`（gasUsed 26570）のあと、スロット0は2、…e565の欄は0になる。もう一度`add(40)`するとgasUsedは48825である。範囲外の`get(5)`：

```
Error: ... execution reverted: panic: array out-of-bounds access (0x32), data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000032"
```

新しくデプロイしたListに10、20、30、40を入れて`removeAt(1)`（gasUsed 32606）を呼ぶと、長さ3で、要素は10、40、30である。順番が変わる。

長さごとの`sum()`（fillとsumは、それぞれ`--gas-limit 29000000`の別のトランザクション）：

```
fill(10)   gasUsed 270166    → sum (len 10)     gasUsed 49863      cast call sum = 55
fill(90)   gasUsed 2065866   → sum (len 100)    gasUsed 286833     cast call sum = 4150
fill(900)  gasUsed 20420478  → sum (len 1000)   gasUsed 2656533    cast call sum = 409600
fill(1000) × 9 (それぞれgasUsed 22686478) → sum (len 10000)  gasUsed 26353533
```

`fill(1000)`をさらに2回して長さ12000になると、`sum()`はanvilのブロックガスリミットの中で終わらない：

```
$ cast send <List> "sum()" --gas-limit 30000000 ... --json
"status":"0x0", "cumulativeGasUsed":"0x1c9c380", "gasUsed":"0x1c9c380"
$ cast send <List> "sum()" --gas-limit 30000001 ...
Error: server returned an error response: error code -32000: intrinsic gas too high -- tx.gas_limit > env.block.gas_limit
$ cast estimate <List> "sum()"
Error: server returned an error response: error code -32003: Out of gas: gas required exceeds allowance: 30000000
```

### 試すときの注意

- 自動生成されたgetterの`list(5)`で範囲外を読むと、Panicコードなしで`EvmError: Revert`として巻き戻る。Panic 0x32を見るには、`list[i]`をそのまま返す`get`を別に置く。
- ストレージの動的配列がスロットpに宣言されると、スロットpには長さが、i番目の要素はkeccak256（pを32バイトに埋めた値）+ i番目の欄に置かれる。要素が16バイト以下なら、一つの欄に複数がまとめられる（公式ドキュメントのLayout of State Variables in Storage）。
- `sum()`のように長さの分だけ回る関数は、要素一つに約2,633ガスかかる。配列が伸びれば、いつかブロックやトランザクションのガスリミットを超える。

## 時効性のあるデータ

基準日時点の値。ハードフォークとツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Types、Reference TypesのArrays・Array Members、v0.8.36（push・popはストレージの動的配列と`bytes`だけで、`string`にはない / `push()`は0にした要素をつけ、その要素の参照を返す / `push(x)`と`pop()`は返す値がない / popは消した要素にdeleteを呼ぶ / 長さを変える方法はpushとpopだけ） | 2026-10-19 |
| lengthへの代入が禁止されたバージョン | 0.6.0（"Member-access to length of arrays is now always read-only, even for storage arrays." / 理由："to prevent storage collisions of gigantic storage arrays"） | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| pushのgasUsed | 空の配列への最初のadd 65,925 / 次のadd 48,825 / popで0になった欄にもう一度add 48,825 | 2026-10-19 |
| popのgasUsed | removeLast 26,570 / removeAt(1) 32,606 | 2026-10-19 |
| sumのgasUsed | 長さ10：49,863 / 100：286,833 / 1,000：2,656,533 / 10,000：26,353,533（要素一つに2,633、固定分は約23,533） | 2026-10-19 |
| fillのgasUsed | fill(10) 270,166 / fill(90) 2,065,866 / fill(900) 20,420,478 / fill(1000) 22,686,478 | 2026-10-19 |
| anvilのブロックガスリミット | 30,000,000（既定値）。長さ12,000でsumが失敗（status 0、gasUsed 30,000,000） | 2026-10-19 |
| メインネットのブロックガスリミット | 60,000,000（ブロック26,223,875） | 2026-10-19 |
| メインネットのトランザクション一つのガスの上限 | 16,777,216（2の24乗、EIP-7825、フサカ・アップグレード2025-12-03から）。ブロックのリミットより低いので、トランザクション一つが使えるガスはこの値まで。anvilの既定の設定は、ガス30,000,000のトランザクションを受け付ける（この上限はかからない） | 2026-10-19 |
| その上限で割ったsumのおおよその最大の長さ | メインネットで約6,360（(16,777,216 - 23,533) ÷ 2,633）。ブロックのリミット60,000,000だけで割ると約22,780。同じ計算でanvilの3千万は約11,380 | 2026-10-19 |
| SLOAD・SSTOREの価格 | SLOADコールド2,100 / ウォーム100、SSTORE 0から新しい値へ20,000 / 0でない値を別の値へ2,900、コールドな欄なら + 2,100（ベルリン以降） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ストレージの欄の番号の計算のルール全体（小さな要素をまとめる、入れ子の配列、マッピング） | [第135講](../../part8/lecture135/) |
| memory配列の作成と長さ | [第67講](../../part4/lecture67/) |
| `bytes`のpush・popと欄の形 | [第68講](../../part4/lecture68/) |
| 長さが伸びる配列を回る関数の設計判断（分けて処理、引き出し方式） | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |
| 繰り返し文の文法と繰り返しの中のガス | [第81講](../../part5/lecture81/) |
| pushのガスを減らす設計 | [第143講](../../part9/lecture143/) |
| deleteのルール全般 | [第74講](../../part4/lecture74/) |
| 空の配列のpopのようなPanicコード全体 | [第90講](../../part5/lecture90/) |
| 別名を通じた状態の変更の判定 | [第72講](../../part4/lecture72/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
