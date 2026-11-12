# 第20講 pragmaとバージョン選択の戦略

第2部 開発とテスト環境・第5章 ツールチェーンとコンパイラ

[← 第19講](../../part2/lecture19/) | [第2部 目次](../) | [第21講 →](../../part2/lecture21/)

## この講義の問い

第19講でバージョンを固定すべきだと言った。ソースファイルの中ではそれをどう書き、どこまで狭く書くべきか。

## 実習資料

### 準備

プロジェクトを二つ使う。Counterが一つだけある`counter`と、ライブラリとそれを呼ぶコントラクトがある`vault`。どちらもライブラリなしでオフラインでビルドする（`libs = []`、`offline = true`）。コンパイラは、Foundryがインストールしておいたsolc 0.7.6と0.8.30の二つだけがある状態で実行した。solcを直接呼ぶときも、Foundryのsvmフォルダにある実行ファイルを使った。

### コード

| ファイル | 内容 |
|---|---|
| [code/counter/foundry.toml](code/counter/foundry.toml) | ライブラリなしのオフライン基本設定 |
| [code/counter/src/Counter.sol](code/counter/src/Counter.sol) | `pragma solidity ^0.8.20`のCounter。2行目だけを変えながら実行 |
| [code/vault/foundry.toml](code/vault/foundry.toml) | `solc = "0.8.30"`でコンパイラを選んだ設定 |
| [code/vault/src/MathLib.sol](code/vault/src/MathLib.sol) | `pragma solidity 0.8.24`で正確なバージョンを書いたライブラリ |
| [code/vault/src/Vault.sol](code/vault/src/Vault.sol) | `pragma solidity 0.8.30`、MathLibをimportするVault |
| [code/nopragma/NoPragma.sol](code/nopragma/NoPragma.sol) | pragmaの行がないファイル |

### 実行結果

`^0.8.20`のCounterを`forge build --use 0.7.6 --offline`でビルド：

```
Error: Encountered invalid compiler version in src\Counter.sol: No compiler version installed that matches the version requirement: ^0.8.20
exit=1
```

同じファイルをsolc 0.7.6に直接渡すと、コンパイラがpragmaの行を指して拒否する：

```
Error: Source file requires different compiler version (current compiler is 0.7.6+commit.7338295f.Windows.msvc) - note that nightly builds are considered to be strictly less than the released version
 --> src/Counter.sol:2:1:
  |
2 | pragma solidity ^0.8.20;
  | ^^^^^^^^^^^^^^^^^^^^^^^^

exit=1
```

`forge build --use 0.8.30`では通る：

```
Compiling 1 files with Solc 0.8.30
Compiler run successful!
exit=0
```

pragmaとコンパイラの組み合わせごとの結果：

| pragma | 0.7.6 | 0.8.30 |
|---|---|---|
| `^0.8.20` | 失敗 | 成功 |
| `0.8.24` | 失敗 | 失敗 |
| `^0.7.0` | 成功 | 失敗 |
| `>=0.7.0 <0.9.0` | 成功 | 成功 |
| `>=0.8.20 <0.9.0` | 失敗 | 成功 |

0.7.6で成功した場合は、`Warning: unable to lint. Solar only supports Solidity versions >=0.8.0`もあわせて表示される。forgeのリンターが0.8未満をサポートしていないという案内で、コンパイル結果とは関係ない。

`--use`なしで`forge build --offline --force`を実行すると、`>=0.7.0 <0.9.0`と`^0.8.20`のどちらも、インストール済みのもののうち高い0.8.30を選ぶ。

`vault`でMathLibを`0.8.24`、Vaultを`0.8.30`と書き、solc 0.8.30でVaultをコンパイル：

```
Error: Source file requires different compiler version (current compiler is 0.8.30+commit.73712a01.Windows.msvc) - note that nightly builds are considered to be strictly less than the released version
 --> src/MathLib.sol:2:1:
  |
2 | pragma solidity 0.8.24;
  | ^^^^^^^^^^^^^^^^^^^^^^^

exit=1
```

MathLibを`^0.8.20`に変えると、二つのファイルが0.8.30一つでコンパイルされる（`forge build --offline --force`）：

```
Compiling 2 files with Solc 0.8.30
Compiler run successful!
exit=0
```

`foundry.toml`に`solc = "0.8.30"`を入れると、`--use`なしでもそのバージョンでコンパイルする。Counterを`>=0.7.0 <0.9.0`にして`solc = "0.7.6"`を入れると`Compiling 1 files with Solc 0.7.6`と表示され、設定ファイルが実際にコンパイラを選んでいることを確認できる。

pragmaのないファイルをsolc 0.8.30でコンパイルすると、警告が出るだけでバイトコードは作られる：

```
Warning: Source file does not specify required compiler version! Consider adding "pragma solidity ^0.8.30;"
--> NoPragma.sol

======= NoPragma.sol:Counter =======
Binary:
6080604052348015600e575f5ffd5b5060ac80601a5f395ff3fe6080604052348015600e575f5ffd5b50600436106026575f3560e01c806306661abd14602a575b5f5ffd5b60306044565b604051603b9190605f565b60405180910390f35b5f5481565b5f819050919050565b6059816049565b82525050565b5f60208201905060705f8301846052565b9291505056fea26469706673582212201cda40d3885170e0445ba30330c58243eee7fca4f7c0289eae49e77fd768684264736f6c634300081e0033
exit=0
```

### 試すときの注意

- forgeは`--offline`のとき、インストール済みのコンパイラの中からだけ選ぶ。`0.8.24`のように正確なバージョンを書くと、そのバージョンがないというメッセージで終わる。solcを直接呼ぶと、同じ状況が"requires different compiler version"として出る。
- 所要時間（ms）は実行ごとに変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 現在のSolidityの最新バージョン、1.0リリースの有無 | 0.8.37（2026-09-10リリース）。講義の基準文書はv0.8.36。1.0は未リリース | 2026-10-20 |
| 主要ライブラリのpragma範囲の例 | OpenZeppelin Contracts 5.7.0（2026-07-29）：ERC20.sol `^0.8.20`、IERC20.sol `>=0.4.16` | 2026-10-20 |
| 実行環境 | forge 1.8.3 (cae51ad)、solc 0.7.6+commit.7338295f、solc 0.8.30+commit.73712a01、Windows | 2026-10-17 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| コンパイラの中でソースがバイトコードになる段階 | [第21講](../../part2/lecture21/) |
| Remixのコンパイラバージョン選択欄 | [第22講](../../part2/lecture22/) |
| foundry.tomlのsolc以外の設定とプロファイル | [第24講](../../part2/lecture24/) |
| ライブラリ依存関係のバージョンとremappings | [第25講](../../part2/lecture25/) |
| ブロックエクスプローラーでのソース検証の実際の手順 | [第34講](../../part2/lecture34/) |
| SPDXライセンス識別子 | [第42講](../../part4/lecture42/) |
| バージョン以外のpragma（abicoder、experimental） | [第43講](../../part4/lecture43/) |
| importの文法 | [第44講](../../part4/lecture44/) |
| コンパイルの再現性とメタデータ | [第130講](../../part8/lecture130/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
