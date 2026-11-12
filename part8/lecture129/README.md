# 第129講 importのパスの解決

第8部 コンパイラと内部構造・第30章 コンパイラの使い方

[← 第128講](../../part8/lecture128/) | [第8部 目次](../) | [第130講 →](../../part8/lecture130/)

## この講義の問い

`import "…"`に書いた文字列はどんな規則でコンパイラの中の名前になり、どのファイルに解決され、その名前と規則は結果のバイトコードにどう残るのか。

## 実習資料

### 準備

solc 0.8.30の実行ファイルを直接呼び、どのフォルダでどのパスを渡すかによって、ソースユニット名とバイトコードがどう変わるかを見た。`c129/sol`は第128講のStore.sol一つ、`c129/proj`はimportの事例を集めた小さなフォルダである。`proj`の中にはもう一つ`lib/`フォルダがあるが、このリポジトリには入れていない。試すときは、下の内容で自分で作る。

`proj/lib/m1/M.sol`（`proj/lib/m2/M.sol`は`return 2;`だけが違う）。

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

library M {
    function v() internal pure returns (uint256) {
        return 1;
    }
}
```

`proj/lib/B.sol`。

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract B {}
```

A.solの二つのバージョンは、ローカルのanvilを新しく立ち上げてアカウント0番が`cast send --create`でデプロイした。`market`は通しプロジェクトMarketの第129講のバージョンで、forge-stdが必要である。

### コード

| ファイル | 内容 |
|---|---|
| [code/c129/sol/Store.sol](code/c129/sol/Store.sol) | 渡したパスによって末尾のハッシュが変わることを見たStore |
| [code/c129/proj/src/A.sol](code/c129/proj/src/A.sol) | `import {M} from "@m/M.sol"`。remappingでm1・m2のどちらかを選ぶ |
| [code/c129/proj/src/Out.sol](code/c129/proj/src/Out.sol) | 相対import `../outside/O.sol` |
| [code/c129/proj/outside/O.sol](code/c129/proj/outside/O.sol) | Out.solが呼ぶ空のコントラクト |
| [code/c129/proj/src/Two.sol](code/c129/proj/src/Two.sol) | 同じファイルを`lib/B.sol`と`lib//B.sol`の二つの名前でimport |
| [code/c129/proj/src/Case.sol](code/c129/proj/src/Case.sol) | 同じファイルを`lib/B.sol`と`lib/b.sol`の二つの名前でimport |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第129講のバージョンの設定。`remappings = ["forge-std/=lib/forge-std/src/"]`を書いておく |
| [code/market/src/](code/market/src/) | Market 第129講のバージョン |
| [code/market/test/](code/market/test/) | Marketのテスト55個 |

### 実行結果

同じStore.solで、渡したパスだけを変えた（三つとも401バイト、末尾の53バイトを除いたコードの部分は同じ）。

```
$ (solフォルダで) solc --bin Store.sol  -> 401 bytes, keccak 0x42853029af491405daa929b01b815fe2af87f9d265e4ea18760acfebfee7599d
$ (c129で) solc --bin sol/Store.sol  -> 401 bytes, keccak 0xd968dd7dacc137cbb081c3f5cf4e613735e2f95462d523c30e61c0a27f9c8cf6
cwd c129\sol arg Store.sol -> compilationTarget {"Store.sol": "Store"} sources ['Store.sol']
cwd c129 arg sol/Store.sol -> compilationTarget {"sol/Store.sol": "Store"} sources ['sol/Store.sol']
$ (projで) solc --base-path .. --bin ../sol/Store.sol  -> 401 bytes, keccak 0xd968dd7dacc137cbb081c3f5cf4e613735e2f95462d523c30e61c0a27f9c8cf6
```

`proj`で`--base-path`なしに`../sol/Store.sol`を渡すと、ソースユニット名がそのコンピュータの絶対パスになり、keccakが0x75a1f634…5eb6になる。フォルダのパスが名前に入るので、コンピュータ・フォルダごとに値が違う。

remapping一つが、同じソースを別のファイルに変える。

```
$ solc --bin @m/=lib/m1/ src/A.sol  -> 213 bytes, keccak 0x954bbc1a9274e98cd16e7f4bed1881bdaa74b0047598c275f0ec57c06945c9e0
$ solc --bin @m/=lib/m2/ src/A.sol  -> 213 bytes, keccak 0xcb5a5120231d448cf2f2f02e481910f00d3aede23120c0bb7655fdb86f5647dd
@m/=lib/m1/ -> remappings [':@m/=lib/m1/'] sources ['lib/m1/M.sol', 'src/A.sol']
@m/=lib/m2/ -> remappings [':@m/=lib/m2/'] sources ['lib/m2/M.sol', 'src/A.sol']
```

デプロイした二つのAの`v()`は、m1のバージョンが1、m2のバージョンが2である。remappingなしで、またはimportのコールバックを切ってビルドすると次のとおり。

```
$ solc --bin src/A.sol
Error: Source "@m/M.sol" not found: File not found. Searched the following locations: "".
$ solc --no-import-callback --bin @m/=lib/m1/ src/A.sol
Error: Source "lib/m1/M.sol" not found: No import callback.
```

使わないremappingもメタデータに入る。`solc --bin x/=y/ Store.sol`は、コードの部分は同じで、全体のkeccakだけが0xc1405bb10a880071796205a366d66cc3586f21560ca064c675e02543c634997aに変わる（`remappings [":x/=y/"]`）。

相対importは、ディスクの位置ではなくソースユニット名を基準に解決される。`proj`で`solc --bin src/Out.sol`は`outside/O.sol:O`と`src/Out.sol:UsesO`を作り、`proj/src`で`solc --bin Out.sol`は失敗する。

```
Error: Source "outside/O.sol" not found: File not found. Searched the following locations: "".
 --> Out.sol:4:1:
  |
4 | import {O} from "../outside/O.sol";
```

Standard JSONでも同じである。sourcesに`x/A.sol`（`import "./B.sol"`）と`B.sol`を入れると`ParserError: Source "x/B.sol" not found`、`import "B.sol"`に変えるとエラーはない。

ディスクの一つのファイルが二つの名前で入ってくると、2回宣言される。

```
$ solc --bin src/Two.sol
Error: Identifier already declared.
 --> src/Two.sol:5:1:
  |
5 | import "lib//B.sol";
$ solc --bin src/Case.sol
Error: Identifier already declared.
 --> src/Case.sol:5:1:
  |
5 | import "lib/b.sol";
```

Standard JSONで`lib/B.sol`と`lib//B.sol`に違う内容を入れると、エラーなしで両方がコンパイルされる（`{"lib//B.sol": ["B2"], "lib/B.sol": ["B"]}`）。

Marketで使わないforge-stdのremapping。Marketのコピー4組のruntimeのkeccak。

| lib/forge-std | foundry.tomlのremappings | forge remappings | runtimeのkeccak |
|---|---|---|---|
| ある | 書かない | `forge-std/=lib/forge-std/src/` | 0xa87eacec6e3758bfacbe9e8c69e519425544acba046f0e2b7fe5d7d93d76dc2a |
| ない | 書かない | なし | 0x4198b29703ad291a7c749a5cf1dab196751a5fcf6b86a450bf2357471b0f709e |
| ある | 書く | `forge-std/=lib/forge-std/src/` | 0xa87eacec…dc2a |
| ない | 書く | `forge-std/=lib/forge-std/src/` | 0xa87eacec…dc2a |

そのためMarket 第129講のバージョンは、foundry.tomlにremappingを1行書いておいた。runtime 7,353 / creation 7,931、`forge test`の55個が通り、メタデータのremappingsは`[":forge-std/=lib/forge-std/src/"]`で、前のバージョンとはメタデータハッシュの32バイトだけが違う。

### 試すときの注意

- 渡したパスがソースユニット名になり、その名前がメタデータに入って、バイトコードの末尾のハッシュを変える。同じバイトコードを作り直すには、同じフォルダで同じパスを渡すか、`--base-path`をそろえる。
- forgeは`lib/forge-std`があるとremappingを自動で検出し、メタデータに入れる。使わなくても入る。foundry.tomlに書いておけば、libフォルダの有無にかかわらず同じになる。
- Windowsのように大文字と小文字を区別しないファイルシステムでは、`lib/b.sol`で`lib/B.sol`を読む。ほかのOSでは結果が違うことがある。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンや実行したコンピュータが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメントのバージョン | v0.8.36 Import Path Resolution（Virtual Filesystem、Import Callback、Imports、Relative Imports、Base Path and Include Paths、CLI Path Normalization and Stripping、Allowed Paths、Import Remapping）、Using the Compiler（Base Path and Import Remapping） | 2026-10-20 |
| パスの切り詰めの注記 | "Prior to version 0.8.8, CLI path stripping was not performed"（0.8.8より前のバージョンはパスの切り詰めなし） | 2026-10-20 |
| solc | 0.8.30 | 2026-10-20 |
| Foundry | forge・cast・anvil 1.8.3、`auto_detect_remappings = true`が既定 | 2026-10-20 |
| OS | Windows 11、大文字と小文字を区別しないファイルシステム（`lib/b.sol`で`lib/B.sol`を読む） | 2026-10-20 |
| 絶対パスの名前 | `(projで) solc --bin ../sol/Store.sol`はソースユニット名がそのコンピュータの絶対パスになり、keccak 0x75a1f634…5eb6。フォルダのパスが名前に入り、コンピュータ・フォルダごとに値が違う | 2026-10-20 |
| Storeのkeccak | `Store.sol` 0x42853029…599d、`sol/Store.sol`・`--base-path ..` 0xd968dd7d…8cf6、`x/=y/` 0xc1405bb1…997a（三つとも401バイト、先頭の348バイトは同じ） | 2026-10-20 |
| A.sol | m1 213バイト 0x954bbc1a…c9e0、m2 213バイト 0xcb5a5120…47dd / anvilの新しいチェーン、アカウント0番がデプロイ A(m1) 0x5FbDB2315678afecb367f032d93F642f64180aa3 `v()` 1、A(m2) 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 `v()` 2 | 2026-10-20 |
| エラーの文言 | `Source "…" not found: File not found. Searched the following locations: "".`、`Source "lib/m1/M.sol" not found: No import callback.`、`ParserError: Source "x/B.sol" not found`、`Identifier already declared.` | 2026-10-20 |
| Marketのコピー4組 | libあり・書かない / あり・書く / なし・書く 0xa87eacec6e3758bfacbe9e8c69e519425544acba046f0e2b7fe5d7d93d76dc2a、なし・書かない 0x4198b29703ad291a7c749a5cf1dab196751a5fcf6b86a450bf2357471b0f709e（runtimeのkeccak） | 2026-10-20 |
| Market 第129講のバージョン | runtime 7,353 / creation 7,931、initcodeの余裕41,221、テスト55個、linkReferences {}、`grep -n assembly src/*.sol` 0行、`forge remappings` `forge-std/=lib/forge-std/src/`、メタデータのremappings `[":forge-std/=lib/forge-std/src/"]`、build-infoのbasePath = プロジェクトのフォルダ。第29章の終わりのバージョンとは、0から数えて7,310番目のバイトからメタデータハッシュの32バイトだけが違う | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 同じ入力で作り直すことと、チェーンのコードとの突き合わせ | [第130講](../../part8/lecture130/) |
| メタデータのsourcesの欄（keccak256、urls） | [第130講](../../part8/lecture130/)、[第142講](../../part8/lecture142/) |
| ASTのノードのソース番号 | [第131講](../../part8/lecture131/) |
| ソースマップのファイル番号 | [第132講](../../part8/lecture132/) |
| ファイルの分け方・名前のつけ方の慣例 | [第148講](../../part9/lecture148/)、[第149講](../../part9/lecture149/) |
| 依存関係を選んでバージョンを固定する判断 | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| 監査でビルドに入ったファイルの一覧を確定する | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
