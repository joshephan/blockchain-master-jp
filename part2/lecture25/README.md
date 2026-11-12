# 第25講 依存関係の管理とremappings

第2部 開発とテスト環境・第6章 Foundryの基本

[← 第24講](../../part2/lecture24/) | [第2部 目次](../) | [第26講 →](../../part2/lecture26/)

## この講義の問い

他人が書いたコードはどんな経路で自分のプロジェクトに入り、入ったあとは自分のバイトコードとどんな関係になるのか。

## 実習資料

### 準備

`forge init`で作ったFoundryプロジェクト（forge-std v1.17.0）に、`forge install OpenZeppelin/openzeppelin-contracts@v5.4.0`でOpenZeppelin Contractsをタグで固定してダウンロードする。比較用に、空のフォルダで`npm init -y`のあと`npm install --ignore-scripts @openzeppelin/contracts`を実行し、同じライブラリをnpmでもダウンロードする。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry/foundry.toml](code/foundry/foundry.toml) | `forge init`の基本設定 |
| [code/foundry/foundry.lock](code/foundry/foundry.lock) | forge-std v1.17.0とOpenZeppelin v5.4.0のタグ・コミットの記録 |
| [code/foundry/remappings.txt](code/foundry/remappings.txt) | `@openzeppelin/contracts/`を`lib/openzeppelin-contracts/contracts/`につなぐ規則 |
| [code/foundry/src/Plain.sol](code/foundry/src/Plain.sol) | ライブラリなしで名前を一つだけ持つ比較用のコントラクト |
| [code/foundry/src/MyToken.sol](code/foundry/src/MyToken.sol) | OpenZeppelinのERC20を継承した10行のトークン |
| [code/foundry/extra/PermitToken.sol](code/foundry/extra/PermitToken.sol) | ERC20Permitまで継承したトークン（flatten比較用） |
| [code/npm/package.json](code/npm/package.json) | npmでダウンロードした`@openzeppelin/contracts` `^5.6.1` |
| [code/npm/package-lock.json](code/npm/package-lock.json) | 実際にダウンロードした5.6.1と完全性ハッシュ |

### 実行結果

`forge install OpenZeppelin/openzeppelin-contracts@v5.4.0`の出力。OpenZeppelinの中にもサブモジュールが三つ別にある：

```
Installing openzeppelin-contracts in lib\openzeppelin-contracts (url: https://github.com/OpenZeppelin/openzeppelin-contracts, tag: v5.4.0)
Submodule 'lib/erc4626-tests' (https://github.com/a16z/erc4626-tests.git) registered for path 'lib/erc4626-tests'
Submodule 'lib/forge-std' (https://github.com/foundry-rs/forge-std) registered for path 'lib/forge-std'
Submodule 'lib/halmos-cheatcodes' (https://github.com/a16z/halmos-cheatcodes) registered for path 'lib/halmos-cheatcodes'
    Installed openzeppelin-contracts tag=v5.4.0@c64a1edb67b6e3f4a15cca8909c9482ad33a02b0
```

`.gitmodules`：

```
[submodule "lib/forge-std"]
	path = lib/forge-std
	url = https://github.com/foundry-rs/forge-std
[submodule "lib/openzeppelin-contracts"]
	path = lib/openzeppelin-contracts
	url = https://github.com/OpenZeppelin/openzeppelin-contracts
```

コミットしたあとにgitが保存したサブモジュールのハッシュ（`git ls-files -s lib`）。foundry.lockのrevと同じである：

```
160000 f3dae6e6ee381f25eb6a246f7da9b85c91a68219 0	lib/forge-std
160000 c64a1edb67b6e3f4a15cca8909c9482ad33a02b0 0	lib/openzeppelin-contracts
```

npmのほうは`added 1 package, and audited 2 packages in 2s`で、package.jsonに`"@openzeppelin/contracts": "^5.6.1"`と書かれる。

`forge build --offline --sizes`：

```
| Contract | Runtime Size (B) | Initcode Size (B) | Runtime Margin (B) | Initcode Margin (B) |
| MyToken  | 3,554            | 5,973             | 21,022             | 43,179              |
| Plain    | 505              | 1,387             | 24,071             | 47,765              |
```

`forge flatten`で一つのファイルに展開した行数。MyTokenは604行（OpenZeppelinのファイル5個：Context.sol、IERC20.sol、draft-IERC6093.sol、IERC20Metadata.sol、ERC20.sol）、PermitTokenは4053行（OpenZeppelinのファイル19個）である。

`forge remappings`：

```
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
lib/openzeppelin-contracts/:forge-std/=lib/openzeppelin-contracts/lib/forge-std/src/
forge-std/=lib/forge-std/src/
```

OpenZeppelinリポジトリ自体のremappings.txtには`@openzeppelin/contracts/=contracts/`と書かれている。

`lib/openzeppelin-contracts`をプロジェクトの外に移して`forge build --offline`を実行すると、importが見つからない：

```
Unable to resolve imports:
      "@openzeppelin/contracts/token/ERC20/ERC20.sol" in "src\MyToken.sol"
...
Error: Compiler run failed:
Error (6275): Source "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol" not found: File not found.
 --> src/MyToken.sol:4:1:
  |
4 | import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
  | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

フォルダを戻すと、またビルドできる。

同じMyToken.solに対し、同じフォルダの位置（`lib/openzeppelin-contracts/contracts`）にv5.4.0とnpm 5.6.1のファイルを順に入れて`forge inspect MyToken bytecode --offline --force`で比べると、長さ（11,948文字）とサイズ（ランタイム3,554B、生成5,973B）は同じで、末尾のメタデータハッシュだけが違う：

```
タグ v5.4.0: ...a2646970667358221220cc76569504cc990a2cb88bf4c0f41e525d3d7ac082638f46adc69db04128ecd064736f6c634300081e0033
npm 5.6.1:   ...a2646970667358221220bb2b62a05dcb5745416b8ab52ba55bd4cc4d05fe1dafffe1d3012b0e30dd13e064736f6c634300081e0033
```

二つのバージョンのソースの違いは、ERC20.solの冒頭のコメント（"last updated"のバージョン）とコメント2行、draft-IERC6093.solの冒頭のコメントとコメント1行だけである。IERC20.sol、IERC20Metadata.sol、Context.solは同じである。

### 試すときの注意

- メタデータにはソースのパスとremappingsの設定も入る。ファイルの中身が同じでも、`lib/...`と`node_modules/...`のようにパスだけを変えるとハッシュが変わる（a776141160caa0791c6623ba46f3e99d3450b34045a8040aabc1c47265286cb6）。プロジェクトの絶対パスを含むremappingがあれば、フォルダの位置によってもハッシュが変わる。
- forge 1.8.3では、OpenZeppelinのファイルの改行だけをCRLFとLFに変えた二つのビルドはハッシュが同じだった。コメントを1行足すと変わる。
- `--offline`なしで`forge build`を実行すると、gitに登録されたサブモジュールのフォルダが空のとき（`git submodule status`の行頭に`-`）、"Missing dependencies found. Installing now..."と表示してそのコミットをもう一度ダウンロードしてビルドする。フォルダがないとビルドが壊れることを見るには`--offline`をつける。
- Windowsで作業フォルダのパスが長いと、OpenZeppelinの中のサブモジュールをダウンロードするときにパスの長さの制限にかかることがある。短いパスで行うか、gitの`core.longpaths`をオンにする。

## 時効性のあるデータ

基準日時点の値。ライブラリとツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge）のバージョン | 1.8.3 | 2026-10-18 |
| forge initがダウンロードしたforge-std | タグv1.17.0、コミットf3dae6e6ee381f25eb6a246f7da9b85c91a68219 | 2026-10-18 |
| forge installで固定したOpenZeppelin Contracts | タグv5.4.0、コミットc64a1edb67b6e3f4a15cca8909c9482ad33a02b0 | 2026-10-18 |
| npmがダウンロードした@openzeppelin/contracts | 5.6.1（package.jsonには`^5.6.1`） | 2026-10-18 |
| OpenZeppelin v5.4.0の中のforge-std | v1.9.6、コミット3b20d60d14b343ee4f908cb8079495c07f5e8981 | 2026-10-18 |
| OpenZeppelin v5.4.0の中のほかのサブモジュール | lib/erc4626-tests、lib/halmos-cheatcodes | 2026-10-18 |
| ダウンロードした容量 | lib/openzeppelin-contractsの作業フォルダ約14MB、プロジェクトの.git約58MB（forge-stdを含む）、npmのnode_modules約4.1MB | 2026-10-18 |
| サイズの比較（solc 0.8.30、最適化オフ） | Plain ランタイム505B / 生成1,387B、MyToken ランタイム3,554B / 生成5,973B | 2026-10-18 |
| flattenの行数（OpenZeppelin v5.4.0） | MyToken 604行（OZのファイル5個）、PermitToken 4,053行（OZのファイル19個） | 2026-10-18 |
| 二つのバージョンのビルドのメタデータハッシュ（同じフォルダの位置） | v5.4.0: cc76569504cc990a2cb88bf4c0f41e525d3d7ac082638f46adc69db04128ecd0、5.6.1: bb2b62a05dcb5745416b8ab52ba55bd4cc4d05fe1dafffe1d3012b0e30dd13e0 | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| フォークチェーンで実際にデプロイされたライブラリのコードと組み合わせてテストする | [第30講](../../part2/lecture30/) |
| デプロイしたバイトコードとソースを照らし合わせるコントラクトの検証 | [第34講](../../part2/lecture34/) |
| 継承とライブラリの文法 | [第35講](../../part3/lecture35/) |
| 他人のコントラクトを組み立てるモジュール式の設計 | [第41講](../../part3/lecture41/) |
| 持ってきたコードのライセンス（SPDX） | [第42講](../../part4/lecture42/) |
| importの文法と別名 | [第44講](../../part4/lecture44/) |
| Solidityのライブラリ（library）の文法とinternalリンク（internal関数は自分のバイトコードに入り、public・external関数は別にデプロイしたライブラリをアドレスで呼ぶ） | [第116講](../../part6/lecture116/) |
| コンパイラのインポートパス解決の全規則（コロンの前の範囲、重なる規則の優先順位） | [第129講](../../part8/lecture129/) |
| ソースのパス・フォルダの位置まで含めたコンパイルの再現性 | [第130講](../../part8/lecture130/) |
| ERC-20のapproveの構造とその欠陥 | [第155講](../../part10/lecture155/) |
| デプロイ後にコードを変えるアップグレードパターン（プロキシ） | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
