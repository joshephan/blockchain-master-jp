# 第23講 Foundryのインストールとプロジェクト構成

第2部 開発とテスト環境・第6章 Foundryの基本

[← 第22講](../../part2/lecture22/) | [第2部 目次](../) | [第24講 →](../../part2/lecture24/)

## この講義の問い

第22講で画面にしか残らなかったバージョンと設定を、ファイルとして残すプロジェクトはどんな形をしているのか。

## 実習資料

### 準備

Foundryをインストールし（`curl -L https://getfoundry.sh/install | bash`のあと`foundryup`）、`forge init hello`で新しいプロジェクトを作る。initがforge-std（v1.17.0）を`lib/forge-std`にダウンロードしてくる。別のsolcバージョンをダウンロードしないよう、`forge build`に`--offline`をつけた。オンラインの状態でそのまま`forge build`を実行すると、forgeがsolcを新しくダウンロードしてくることがあるので、出力のバージョンを確認する。デプロイの記録（broadcast）を見るときは、ローカルのanvilを起動する。

### コード

`forge init`が作ったファイルそのままである。

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | init直後の設定（`src`、`out`、`libs`の3行） |
| [code/foundry.lock](code/foundry.lock) | forge-stdのタグとコミットの記録 |
| [code/.gitignore](code/.gitignore) | `cache/`、`out/`、ローカルチェーンのbroadcastの記録、`.env`などを除外する設定 |
| [code/.github/workflows/test.yml](code/.github/workflows/test.yml) | `forge fmt --check`、`forge build --sizes`、`forge test -vvv`を実行するCI |
| [code/src/Counter.sol](code/src/Counter.sol) | initのサンプルCounter（`number`、`setNumber`、`increment`） |
| [code/test/Counter.t.sol](code/test/Counter.t.sol) | initのサンプルテスト |
| [code/script/Counter.s.sol](code/script/Counter.s.sol) | Counterをデプロイするinitのサンプルスクリプト |

### 実行結果

`forge --version`（cast、anvil、chiselも同じVersionとCommit SHA）：

```
forge Version: 1.8.3
Commit SHA: cae51ad458f6abb64852b7709eb784352429825d
Build Timestamp: 2026-09-15T10:30:41.249604900Z (1789468241)
Build Profile: dist
```

`forge init hello`の最後の部分：

```
    Installed forge-std tag=v1.17.0@f3dae6e6ee381f25eb6a246f7da9b85c91a68219
    Initialized forge project
```

init直後のフォルダ（`.git`と`lib/forge-std`の中身は除く）：

```
.
./.github
./.github/workflows
./.github/workflows/test.yml
./.gitignore
./.gitmodules
./README.md
./foundry.lock
./foundry.toml
./lib
./script
./script/Counter.s.sol
./src
./src/Counter.sol
./test
./test/Counter.t.sol
```

`src`の名前だけを`contracts`に変えて`forge build --offline`を実行すると、testとscriptの`import {Counter} from "../src/Counter.sol";`が壊れる：

```
Unable to resolve imports:
      "../src/Counter.sol" in "script\Counter.s.sol"
      "../src/Counter.sol" in "test\Counter.t.sol"
...
Error: Compiler run failed:
Error (6275): Source "src/Counter.sol" not found: File not found.
 --> script/Counter.s.sol:5:1:
  |
5 | import {Counter} from "../src/Counter.sol";
  | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

testとscriptのフォルダを消して`contracts/Counter.sol`だけを残すと、`Nothing to compile`（終了コード0、outフォルダなし）で終わる。`foundry.toml`の`src = "src"`を`src = "contracts"`に変えると、`Compiling 1 files with Solc 0.8.30`でコンパイルされる。

helloフォルダでの最初のビルドと2回目のビルド：

```
$ forge build --offline
Compiling 23 files with Solc 0.8.30
Solc 0.8.30 finished in 633.11ms
Compiler run successful!

$ forge build --offline
No files changed, compilation skipped
```

`out/Counter.sol/Counter.json`の最上位のキーは`abi, bytecode, deployedBytecode, methodIdentifiers, rawMetadata, metadata, id`である。`cache/solidity-files-cache.json`には、パスの設定、ファイルごとの`contentHash`と`imports`、最後に`"optimizer":{"enabled":false,"runs":200}`、`"evmVersion":"osaka"`、`"viaIR":false`が入っている。

`src/Counter.sol`の末尾にコメントを1行足してビルドすると、そのファイルを使う三つのファイルだけを再コンパイルする：

```
Compiling 3 files with Solc 0.8.30
Solc 0.8.30 finished in 598.19ms
Compiler run successful!
```

`out`と`cache`を消して再ビルドしたCounter.jsonを以前のものと比べると、`bytecode`、`deployedBytecode`はどちらも同じである。ランタイムコードは481バイトである。

`git check-ignore -v out cache`：

```
.gitignore:3:out/	out
.gitignore:2:cache/	cache
```

anvilを起動し、`cast chain-id`が31337であることを確認してから`forge script script/Counter.s.sol --broadcast`でデプロイすると、`ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.`と表示され、`broadcast/Counter.s.sol/31337/run-latest.json`に記録が残る。この記録はコミットされない：

```
$ git check-ignore -v broadcast/Counter.s.sol/31337/run-latest.json
.gitignore:11:/broadcast/*/31337/	broadcast/Counter.s.sol/31337/run-latest.json
```

### 試すときの注意

- `forge init`がforge-stdをダウンロードしている途中で`Error: git exited with code 1`で失敗したことがある。一時的なネットワークの問題で、作りかけのフォルダを消してもう一度実行すればよい。
- `tree`がない環境では`find`でフォルダの一覧を見る。
- コンパイル時間（ms）は実行ごとに違う。

## 時効性のあるデータ

基準日時点の値。ツールとライブラリのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil・chisel）のバージョン | 1.8.3、Commit SHA cae51ad458f6abb64852b7709eb784352429825d、四つとも同じ | 2026-10-18 |
| Foundryのインストールコマンド | `curl -L https://getfoundry.sh/install \| bash`のあと`foundryup`。インストール先のアドレスがfoundry.paradigm.xyzから変わった。最新の安定版はv1.8.5 | 2026-10-20 |
| forge initがダウンロードしたforge-std | タグv1.17.0、rev f3dae6e6ee381f25eb6a246f7da9b85c91a68219 | 2026-10-18 |
| lib/forge-stdフォルダのサイズ | 約1.4MB | 2026-10-18 |
| forgeが選んだsolc | 0.8.30（pragma ^0.8.13、インストール済みのバージョンから選択、`--offline`） | 2026-10-18 |
| cacheに記録されたデフォルト設定 | optimizerオフ、runs 200、evmVersion osaka、viaIR false | 2026-10-18 |
| 最初のビルドのファイル数 | 23（自分のファイル3 + forge-std 20）、forge-std v1.17.0基準 | 2026-10-18 |
| initのCounterのランタイムコードのサイズ | 481バイト（solc 0.8.30、最適化オフ） | 2026-10-18 |
| コンパイル時間 | 633.11ms、598.19msなど。実行ごとに違う | 2026-10-18 |
| anvilのデフォルトのチェーン番号 | 31337 | 2026-10-18 |
| Hardhatのテスト言語 | Hardhat 3.20.0。Testingの文書がSolidityのテストとTypeScriptのテスト（viem・ethers.js）をあわせて案内 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| foundry.tomlにsolc・optimizer・evm_versionを書く、プロファイル | [第24講](../../part2/lecture24/) |
| コンパイラの自動選択がファイルに残らない問題 | [第24講](../../part2/lecture24/) |
| lib/forge-std、foundry.lock、.gitmodules、importの名前とパス | [第25講](../../part2/lecture25/) |
| castでのチェーンの照会、署名、送信 | [第26講](../../part2/lecture26/) |
| anvilの運用と状態の操作 | [第27講](../../part2/lecture27/) |
| forge testの実行、テストの書き方、ファズテスト | [第28講](../../part2/lecture28/) |
| forge scriptとbroadcastの記録で行うデプロイ | [第34講](../../part2/lecture34/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
