# 第70講 構造体

第4部 言語の詳細 ① ファイルと型・第14章 参照型

[← 第69講](../../part4/lecture69/) | [第4部 目次](../) | [第71講 →](../../part4/lecture71/)

## この講義の問い

違う型を一つのまとまりにすると、この機械で何が決まり、そのまとまりを直すときにどこで事故が起きるのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクト（`demo/`）から、Counterのファイルを消して始める。コンパイルエラーと警告を見るファイルは、demoをコピーした別のプロジェクト`bad/`に置く（foundry.tomlは同じ）。デプロイと送信はローカルのanvilで既定のアカウント0番（公開されたテスト用の鍵）を使って行い、gasUsedは`cast send ... --json`の`gasUsed`で読む。ビルドはすべて`--offline`である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/demo/src/Loose.sol](code/demo/src/Loose.sol) | フィールドの順番が32・8・32・1バイトのPosition（PosLoose、欄四つ） |
| [code/demo/src/Tight.sol](code/demo/src/Tight.sol) | 同じフィールドを32・32・8・1バイトで置いたPosition（PosTight、欄三つ） |
| [code/demo/src/Types.sol](code/demo/src/Types.sol) | 構造体を宣言する場所：ファイルレベル、インターフェースの中、ライブラリの中 |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | `Position[]`。順番どおり・名前をつけて作る、storageの別名で直す、memoryのコピーで直して書き戻しを忘れた版と書き戻した版、delete |
| [code/demo/src/LendingDraft.sol](code/demo/src/LendingDraft.sol) | レンディングプロトコルの草案。ユーザー1人分のPositionをファイルレベルで宣言 |
| [code/bad/foundry.toml](code/bad/foundry.toml) | demoと同じ設定 |
| [code/bad/src/](code/bad/src/) | 構造体の宣言の場所、マッピングを含む構造体、自己参照の構造体、書き戻しを忘れた関数の警告の例 |

`code/bad/src/`のファイルと結果：

| ファイル | 内容 | 結果 |
|---|---|---|
| InFunc.sol | 関数の中でstructを宣言 | Error (6933) |
| Kinds.sol | 値型・配列・構造体・マッピングをフィールドに置いたAccount | ビルド成功 |
| KindsStore.sol | `Account storage a = acc;` | ビルド成功 |
| KindsMem.sol | `Account memory a = acc;` | Error (4061) |
| MapMem.sol | マッピングを含む構造体をmemoryで | Error (4061) |
| MapStore.sol | MapMemのmemoryの場所にstorage | ビルド成功 |
| SelfRef.sol | フィールドに自分自身`Node child;` | Error (2046) |
| SelfRefFix.sol | 自分自身の配列（TreeArray）、番号で指す（TreeIndex） | ビルド成功 |
| NoEmit.sol | MarketのupdateMemoryForgotからemitの行だけを抜いた版 | Warning (2018) |

### 実行結果

`forge inspect --offline <コントラクト> storageLayout`。同じフィールドでも、順番によって128バイト（欄四つ）と96バイト（欄三つ）に分かれる：

```
| Name | Type                     | Slot | Offset | Bytes | Contract               |
| pos  | struct PosLoose.Position | 0    | 0      | 128   | src/Loose.sol:PosLoose |
| pos  | struct PosTight.Position | 0    | 0      | 96    | src/Tight.sol:PosTight |
```

`--json`の出力のメンバーの位置（欄/offset）だけを抜き出すと：

```
PosLoose: deposited 0/0, lastUpdate 1/0, borrowed 2/0, useAsCollateral 3/0, numberOfBytes 128
PosTight: deposited 0/0, borrowed 1/0, lastUpdate 2/0, useAsCollateral 2/8, numberOfBytes 96
```

MarketとLendingDraft（見出しの行は省略）：

```
| positions | struct Position[] | 0    | 0      | 32    | src/Market.sol:Market |
| status          | enum LendingDraft.MarketStatus | 0    | 0      | 1     | src/LendingDraft.sol:LendingDraft |
| collateralRatio | Ratio                          | 0    | 1      | 1     | src/LendingDraft.sol:LendingDraft |
| admin           | address                        | 0    | 2      | 20    | src/LendingDraft.sol:LendingDraft |
| interestRate    | Rate                           | 1    | 0      | 32    | src/LendingDraft.sol:LendingDraft |
| assets          | contract IERC20[]              | 2    | 0      | 32    | src/LendingDraft.sol:LendingDraft |
```

PosLooseとPosTightに`save(5000, 2000)`。gasUsedは110634と88785で、2回目の`save(6000, 3000)`は39434と37485である。最初の保存のあとの欄：

```
(PosLooseの0〜3番の欄)
0x0000000000000000000000000000000000000000000000000000000000001388
0x000000000000000000000000000000000000000000000000000000006ad5b841
0x00000000000000000000000000000000000000000000000000000000000007d0
0x0000000000000000000000000000000000000000000000000000000000000001
(PosTightの0〜3番の欄)
0x0000000000000000000000000000000000000000000000000000000000001388
0x00000000000000000000000000000000000000000000000000000000000007d0
0x000000000000000000000000000000000000000000000001000000006ad5b841
0x0000000000000000000000000000000000000000000000000000000000000000
```

新しいPosLooseをデプロイし、PosTightの0〜2番の欄の値を`cast rpc anvil_setStorageAt`（ローカルのanvil専用）でそのまま入れてから読むと、同じ欄が違うフィールドの順番で読まれる：

```
$ cast call <新しいPosLoose> "pos()(uint256,uint64,uint256,bool)"
6000
3000
18446744075501942850 [1.844e19]
false
```

18446744075501942850は、2の64乗（担保かどうかの01が置かれたoffset 8）に時刻1792391234を足した値である。

Marketの二つの作り方。`openSwapped(1000, 400)`（gasUsed 111096）は、順番どおりに渡しながら預けた量と借りた量を入れ替えて書いた版なので、0番目の要素が400、1000として保存される。`openNamed(1000, 400)`（gasUsed 93929）は、1番目の要素に1000、400として保存される。最初のpushには長さの欄を初めて書くコストが混ざっているので、二つの作り方のガスの比較には使わない。

`openNamed(1000, 400)`で2・3・4番目の要素をさらに作り、三つの関数で（1500, 600）を入れた結果：

```
updateStorage(2, 1500, 600)          gasUsed 40810   → positions(2): 1500 / 600 / 1792391270 / true
updateMemoryForgot(3, 1500, 600)     gasUsed 32434   → positions(3): 1000 / 400 / 1792391269 / true
updateMemoryWriteBack(4, 1500, 600)  gasUsed 41889   → positions(4): 1500 / 600 / 1792391270 / true
```

三つの関数ともstatus 1で成功するが、updateMemoryForgotは保存されない。要素iの最初の欄は、keccak256(0) + 3 × iである（`0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563` + 3 × i）。

`close(1)`（gasUsed 31358）のあと、`positions(1)`は`0 0 0 false`、`count()`は5のままで、要素1の三つの欄はすべて0である。

`bad/`で`forge build --offline --force src/<ファイル>.sol`（位置の行は一部省略）：

```
$ forge build --offline --force src/InFunc.sol
Error (6933): Expected primary expression.
 --> src/InFunc.sol:6:9:
  |
6 |         struct Pair { uint256 a; uint256 b; }
  |         ^^^^^^
$ forge build --offline --force src/KindsMem.sol
Error (4061): Type struct Account memory is only valid in storage because it contains a (nested) mapping.
  --> src/KindsMem.sol:10:9:
   |
10 |         Account memory a = acc;
   |         ^^^^^^^^^^^^^^^^
$ forge build --offline --force src/MapMem.sol
Error (4061): Type struct MapMem.Account memory is only valid in storage because it contains a (nested) mapping.
$ forge build --offline --force src/SelfRef.sol
Error (2046): Recursive struct definition.
 --> src/SelfRef.sol:5:5:
$ forge build --offline --force src/NoEmit.sol
Compiler run successful with warnings:
Warning (2018): Function state mutability can be restricted to view
  --> src/NoEmit.sol:16:5:
   |
16 |     function updateMemoryForgot(uint256 i, uint256 d, uint256 b) external {
   |     ^ (Relevant source part starts here and spans across multiple lines).
```

ビルドされる版の欄の配置。マッピングのフィールドも、欄の番号を一つ占める：

```
$ forge inspect --offline KindsStore storageLayout --json   (Accountのメンバーだけを抜き出し)
Account: limit 0/0, used 1/0, pos 2/0, perAsset 5/0, numberOfBytes 192
$ forge inspect --offline TreeArray storageLayout
| root  | struct TreeArray.Node   | 0    | 0      | 64    | src/SelfRefFix.sol:TreeArray |
$ forge inspect --offline TreeIndex storageLayout
| nodes | struct TreeIndex.Node[] | 0    | 0      | 32    | src/SelfRefFix.sol:TreeIndex |
```

### 試すときの注意

- 新しいanvilでPosLoose、PosTight、Market、PosLooseの順にデプロイすると、アドレスは`0x5FbDB2315678afecb367f032d93F642f64180aa3`、`0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、`0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、`0xa513E6E4b8f2a923D98304ec87F64353C4D5C853`である。
- `lastUpdate`に入る時刻はanvilを立ち上げた時刻に従うので、実行するたびに違う。
- MarketのupdateMemoryForgotは、emitの行のおかげで警告なしにビルドされる。emitを抜くと、viewに変えるようにというWarning (2018)が出る。警告がないからといって、書き戻しを忘れていないわけではない。

## 時効性のあるデータ

基準日時点の値。ハードフォークとツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Types、Reference TypesのStructsの節、v0.8.36（この講義の説明はsolc 0.8.30の実際の出力が基準） | 2026-10-19 |
| ファイルレベルの構造体の導入 | 0.6.0（2019-12-17）"Allow global enums and structs." | 2026-10-19 |
| マッピングを含む構造体・配列をmemory・calldataで禁止 | 0.7.0（2020-07-28）"Disallow structs and arrays in memory or calldata if they contain nested mappings." | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| Positionの二つの版のsaveのgasUsed | 1回目（5000, 2000）：PosLoose 110,634 / PosTight 88,785、2回目（6000, 3000）：39,434 / 37,485 | 2026-10-19 |
| Marketの作成のgasUsed（参考） | openSwapped（最初のpush、長さの欄が0から1へ）111,096、openNamed 93,929。長さの欄の初回書き込みが混ざっているので、二つの作り方の比較には使わない | 2026-10-19 |
| Marketの直す三つの関数のgasUsed | updateStorage 40,810 / updateMemoryForgot 32,434 / updateMemoryWriteBack 41,889 | 2026-10-19 |
| deleteのgasUsed | close(1) 31,358 | 2026-10-19 |
| anvilのブロックの時刻（lastUpdateの値） | 1792391233など、anvilを立ち上げた時刻が基準 | 2026-10-19 |
| テストのアドレス | PosLoose `0x5FbDB2315678afecb367f032d93F642f64180aa3`、PosTight `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Market `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、欄を移し入れた新しいPosLoose `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853`、デプロイのアカウントはanvilの既定のアカウント0 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（公開されたテスト用の鍵） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ストレージの欄の配置のルール全体（構造体・配列が新しい欄から始まるルールを含む） | [第135講](../../part8/lecture135/) |
| フィールドの順番とガス最適化の優先順位 | [第143講](../../part9/lecture143/) |
| デプロイ後にコードを差し替えるときのスロットの衝突 | [第164講](../../part10/lecture164/) |
| 名前をつけて渡す引数（関数の呼び出し） | [第82講](../../part5/lecture82/) |
| マッピングの保存の仕組みと走査できないこと | [第71講](../../part4/lecture71/) |
| ユーザーごとにPositionを一つ置く欄 | [第71講](../../part4/lecture71/)、[第72講](../../part4/lecture72/) |
| deleteのルール全体（マッピングのフィールド、入れ子の構造体） | [第74講](../../part4/lecture74/) |
| 構造体の状態変数の自動ゲッター | [第96講](../../part6/lecture96/) |
| 別名で直す行を監査で見つける方法と深刻度 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/) |
| 宣言の場所と名前が見える範囲 | [第87講](../../part5/lecture87/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
