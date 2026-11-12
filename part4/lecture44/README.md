# 第44講 importの文法と別名

第4部 言語の詳細 ① ファイルと型・第11章 ソースファイルの構造

[← 第43講](../../part4/lecture43/) | [第4部 目次](../) | [第45講 →](../../part4/lecture45/)

## この講義の問い

import一行は正確に何を持ってきて、持ってきたものは自分のバイトコードとどんな関係になるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトから、`src`、`test`、`script`のCounterのファイルを消して始める。外部ライブラリは使わない。コンパイルできない例は`src`の外の`bad/`に置き、パスを指定して別々にビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのlintをオフ |
| [code/src/Shop.sol](code/src/Shop.sol) | ファイルレベルの定数・エラー・構造体・列挙型・関数とインターフェース、ライブラリ、コントラクトを一つのファイルに置いたインポート対象 |
| [code/src/forms/All.sol](code/src/forms/All.sol) | ① `import "../Shop.sol";` |
| [code/src/forms/Star.sol](code/src/forms/Star.sol) | ② `import * as S from "../Shop.sol";` |
| [code/src/forms/As.sol](code/src/forms/As.sol) | ③ `import "../Shop.sol" as S;` |
| [code/src/forms/Pick.sol](code/src/forms/Pick.sol) | ④ `import {feeOf, FEE_BPS as FEE} from "../Shop.sol";` |
| [code/src/chain/Market.sol](code/src/chain/Market.sol)、[Mine.sol](code/src/chain/Mine.sol) | ①の形を2回経由すると、Shop.solの名前までついてくる連鎖 |
| [code/src/own/OwnableOld.sol](code/src/own/OwnableOld.sol)、[OwnableNew.sol](code/src/own/OwnableNew.sol) | 名前が同じ二つのOwnable |
| [code/src/own/Vault.sol](code/src/own/Vault.sol) | 別名で二つのOwnableを一緒に使う版 |
| [code/src/size/](code/src/size/) | Plain、OnlyImport、InheritShop、MakeShop、CallShop：インポートするだけのときと、継承・作成・呼び出しをするときのサイズの比較 |
| [code/bad/StarNoPrefix.sol](code/bad/StarNoPrefix.sol)、[PickOrig.sol](code/bad/PickOrig.sol) | ②の形で`S.`なしで呼ぶ、④の形で別名の代わりに元の名前を呼ぶ |
| [code/bad/chain/MinePick.sol](code/bad/chain/MinePick.sol) | ④の形でMarketだけをインポートしたあとにfeeOfを呼ぶ |
| [code/bad/own/Both.sol](code/bad/own/Both.sol) | 名前が同じ二つのOwnableを①の形で一緒にインポートする |
| [code/bad/InBody.sol](code/bad/InBody.sol) | コントラクトの波かっこの中のimport |
| [code/bad/broken/Tools.sol](code/bad/broken/Tools.sol)、[Mine.sol](code/bad/broken/Mine.sol) | 選んでいないコントラクトに文法エラーがあるファイルを④の形でインポートする |

### 実行結果

`forge build --sizes`（ほかのコントラクトの行、区切り線、Margin列は省略）。インポートしただけのOnlyImportはimportのないPlainとサイズが同じで、Shopを作成するMakeShopだけがShopのコードを丸ごと抱える：

```
| Contract    | Runtime Size (B) | Initcode Size (B) |
| CallShop    | 713              | 741               |
| InheritShop | 755              | 783               |
| MakeShop    | 1,081            | 1,109             |
| OnlyImport  | 303              | 331               |
| Plain       | 303              | 331               |
| Shop        | 541              | 569               |
```

同じ表で、importの四つの形のUseAll・UseStar・UseAs・UsePickはすべて602バイト、Marketは291、Mineは539、Vault・OldVault・二つのOwnableは240バイトである。

エラー六つ（Compiling、Solcの行は省略）：

```
$ forge build --offline bad/StarNoPrefix.sol
Error (7576): Undeclared identifier. Did you mean "fee"?
 --> bad/StarNoPrefix.sol:8:16:
  |
8 |         return feeOf(price);
  |                ^^^^^

$ forge build --offline bad/PickOrig.sol
Error (7576): Undeclared identifier.
 --> bad/PickOrig.sol:8:31:
  |
8 |         return feeOf(price) + FEE_BPS;
  |                               ^^^^^^^

$ forge build --offline bad/chain/MinePick.sol
Error (7576): Undeclared identifier. Did you mean "fee"?
 --> bad/chain/MinePick.sol:8:16:

$ forge build --offline bad/own/Both.sol
Error (2333): Identifier already declared.
 --> bad/own/Both.sol:5:1:
  |
5 | import "../../src/own/OwnableNew.sol";
  | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Note: The previous declaration is here:
 --> src/own/OwnableOld.sol:4:1:

$ forge build --offline bad/InBody.sol
Error (9182): Function, variable, struct or modifier declaration expected.
 --> bad/InBody.sol:5:5:
  |
5 |     import "../src/Shop.sol";
  |     ^^^^^^

$ forge build --offline bad/broken/Mine.sol
Error (2314): Expected ';' but got '}'
  --> bad/broken/Tools.sol:13:5:
```

`--json`をつけると、`errors[].type`はBoth.solがDeclarationError、InBody.solがParserErrorである。最後のエラーは、選んでいないUnusedコントラクトのセミコロン抜けである。名前を一つだけ選んでも、ファイル全体を読む。

`forge inspect UsePick metadata`のsourcesには、`src/Shop.sol`、`src/forms/Pick.sol`の二つの項目が、それぞれkeccak256とlicense "MIT"つきで入っている。`forge flatten src/forms/Pick.sol`は47行で、まとめたUsePickの本体では、別名FEEが元の名前に戻る（`return feeOf(price) + FEE_BPS;`）。

関数のリスト（`forge inspect ... methodIdentifiers`）。継承したInheritShopには、Shopの関数が合わさる：

```
InheritShop  buy(uint256) d96a094a / count() 06661abd / poke() 18178358 / sold(uint256) 9c03facb
OnlyImport   count() 06661abd / poke() 18178358
```

成果物のJSONで、Shopの作成コードとランタイムコードの16進文字列が、各コントラクトのランタイムコードの中にそのまま入っているかを検索した結果：

```
MakeShop 1081 shop init in it: True shop runtime in it: True
CallShop 713 shop init in it: False shop runtime in it: False
InheritShop 755 shop init in it: False shop runtime in it: False
OnlyImport 303 shop init in it: False shop runtime in it: False
```

InheritShopでは、Shopのコードが関数の分岐と合わさってコンパイルし直されるので、文字列検索には引っかからない。合わさったことは上の関数のリストで確かめる。

PlainとOnlyImportは303バイトのうち先頭260バイトが同じで、メタデータの末尾のIPFSハッシュ32バイトだけが違う：

```
Plain      ...a2646970667358221220 8a75a9a99e4c27b2758b840b2df56911d1e476db042599696b379e8aa16c1767 64736f6c634300081e 0033
OnlyImport ...a2646970667358221220 c0078b7becde26bed8cf05734a55108a00d6551142ca16515173cb596c688156 64736f6c634300081e 0033
```

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidity公式ドキュメントのバージョン | v0.8.36（Layout of a Solidity Source File、Importing other Source Files） | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge）のバージョン | 1.8.3 (cae51ad) | 2026-10-19 |
| ランタイムのサイズ | Plain 303 / OnlyImport 303 / InheritShop 755 / MakeShop 1,081 / CallShop 713 / Shop 541（バイト） | 2026-10-19 |
| Shopの作成コードのサイズ | 569バイト | 2026-10-19 |
| importの四つの形のコントラクトのサイズ | UseAll・UseStar・UseAs・UsePickそれぞれ602バイト | 2026-10-19 |
| Ownable・Vault・OldVaultのサイズ | それぞれ240バイト | 2026-10-19 |
| flattenの行数 | Pick.sol 47行 | 2026-10-19 |
| OpenZeppelinを使った前の講義の数値 | Plain 500バイトほど、MyToken 3,500バイト超、flatten 604行（OpenZeppelin v5.4.0） | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| importのパスが実際のファイルに決まるルール（相対パス、コロンの範囲、remappingsの優先順位、基準パス） | [第129講](../../part8/lecture129/) |
| ファイルレベルの定義それぞれの文法（カスタムエラー、構造体、列挙型） | [第48講](../../part4/lecture48/)、[第49講](../../part4/lecture49/)、[第70講](../../part4/lecture70/)、[第108講](../../part6/lecture108/) |
| newでコントラクトを作る | [第84講](../../part5/lecture84/) |
| 継承のルール、抽象コントラクトとインターフェースの文法 | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| ライブラリのリンクの方式 | [第116講](../../part6/lecture116/)、[第117講](../../part6/lecture117/)、[第118講](../../part6/lecture118/) |
| メタデータのsourcesの欄の内容全体 | [第142講](../../part8/lecture142/) |
| 外部呼び出しの引数のエンコード | [第141講](../../part8/lecture141/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
