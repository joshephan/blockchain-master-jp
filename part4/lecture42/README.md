# 第42講 SPDXライセンス識別子

第4部 言語の詳細 ① ファイルと型・第11章 ソースファイルの構造

[← 第41講](../../part3/lecture41/) | [第4部 目次](../) | [第43講 →](../../part4/lecture43/)

## この講義の問い

コメント一行にすぎないのに、なぜコンパイラはその行がなければ警告し、あれば別に取っておくのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトから始める。`MyVault`にはOpenZeppelin Contracts v5.4.0が必要である（`lib/openzeppelin-contracts`）。ライブラリの一行目の比較には、forge-std 1.17.0（`lib/forge-std`）もあわせて見る。公式ドキュメントの例の一行目は、[第37講](../../part3/lecture37/)の`Ballot.sol`で確かめる。solcを直接呼ぶときは、Foundryがダウンロードしておいたsolc 0.8.30の実行ファイルを使う。メタデータから値を取り出すときは、jqの代わりにpythonを使った：

```
forge inspect Hello metadata | python -c "import json,sys; m=json.load(sys.stdin); print(m['sources']['src/Hello.sol'].get('license'))"
```

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのlintをオフ |
| [code/src/Hello.sol](code/src/Hello.sol) | 一行目のSPDXの値だけを変えながらビルドする最小のコントラクト |
| [code/src/MyVault.sol](code/src/MyVault.sol) | UNLICENSEDのファイルがMITであるOpenZeppelinのOwnableを継承 |
| [code/exp/None.sol](code/exp/None.sol) | SPDXの行なし |
| [code/exp/Empty.sol](code/exp/Empty.sol) | 値が空のSPDXの行 |
| [code/exp/Korean.sol](code/exp/Korean.sol) | リストの形式に合わない値（`何でもよい`） |
| [code/exp/Two.sol](code/exp/Two.sol) | SPDXの行が二つ |
| [code/exp/FileMid.sol](code/exp/FileMid.sol) | pragmaのあと、contractの前のSPDXの行 |
| [code/exp/Bottom.sol](code/exp/Bottom.sol) | ファイルの最後のSPDXの行 |
| [code/exp/Middle.sol](code/exp/Middle.sol) | contractの波かっこの中のSPDXの行 |
| [code/exp/TypeErr.sol](code/exp/TypeErr.sol) | SPDXの行は正しく、本体に宣言されていない名前がある版 |

### 実行結果

SPDXの行なしでsolcで直接コンパイルすると、警告が出るだけでバイトコードはそのまま出力される：

```
$ solc-0.8.30 src/Hello.sol --bin
Warning: SPDX license identifier not provided in source file. Before publishing,
consider adding a comment containing "SPDX-License-Identifier: <SPDX-License>"
to each source file. Use "SPDX-License-Identifier: UNLICENSED" for non-open-source
code. Please see https://spdx.org for more information.
--> src/Hello.sol

======= src/Hello.sol:Hello =======
Binary:
608060405260015f553480156012575f5ffd5b50...
```

`forge build`ではこの警告が見えない。Foundryが既定で隠す警告のリスト（`forge config`の`ignored_error_codes`）に`license`が入っているからである。`FOUNDRY_IGNORED_ERROR_CODES='[]' forge build --force`でビルドすると、Warning (1878)が出る。

一行目の値を変えながらビルドしたあとの、メタデータのlicenseの値：

| 一行目の値 | 結果 |
|---|---|
| `MIT`、`MIT OR Apache-2.0`、`Banana-1.0`、`MIT GPL`、`UNLICENSED` | 通過、書いた値のまま |
| `何でもよい` | `Error (1114): Invalid SPDX license identifier.` |
| 空の値、行なし | Foundryの出力は`"license": null`、solcの`--metadata`の出力にはlicenseのキー自体がない |

SPDXの行が二つあると（二つともMITでも）、ビルドが止まる：

```
Error (3716): Multiple SPDX license identifiers found in source file. Use "AND" or
"OR" to combine multiple licenses. Please see https://spdx.org for more information.
--> src/Hello.sol
```

`exp/`のファイルをsolc 0.8.30の`--metadata`で見た結果：

| ファイル | 結果 |
|---|---|
| None.sol | 警告、licenseのキーなし |
| Two.sol | `Error: Multiple SPDX license identifiers found in source file.` |
| FileMid.sol | `"license":"MIT"` |
| Bottom.sol | `"license":"MIT"` |
| Middle.sol | 警告、licenseのキーなし |
| ブロックコメント`/* SPDX-License-Identifier: MIT */` | `"license":"MIT"` |
| TypeErr.sol | `--stop-after parsing`では`Compiler run successful. No output generated.`、最後までコンパイルすると`Error: Undeclared identifier.` |

ふつうのコメントはメタデータに残らない。メタデータ全体のkeccak256は、SPDXの行なしで`0x5e7b97b0…0304`、MITで`0x031ad160…4c79`であり、MITの下に`// hello`を一行足してもlicenseは`"MIT"`のままである。

一行目だけをMIT / GPL-3.0に変えた二つのランタイムコード（`forge inspect Hello deployedBytecode`）は、どちらも172バイトで、129番目のバイト（0から数える、メタデータのハッシュの始まり）から違う。末尾：

```
MIT:     a2646970667358221220 85909949db647f68b44902832fcbf0bea83d741645075b21876439996f1325b7 64736f6c634300081e0033
GPL-3.0: a2646970667358221220 3b8b4888c81fae67908ddf6b2501cbb03ae32f8c66c51d708fe5a2516bececf2 64736f6c634300081e0033
```

MyVaultをビルドしたあとの`forge inspect MyVault metadata`のsourcesごとのlicenseは、Ownable.solがMIT、Context.solがMIT、MyVault.solがUNLICENSEDである。`forge flatten src/MyVault.sol`でまとめたファイルは135行で、SPDXの行は1行目の`// SPDX-License-Identifier: UNLICENSED`一つだけが残り、pragmaは`=0.8.30 ^0.8.20`にまとめられる。

ライブラリごとのSPDXの値（`grep -rh "SPDX-License-Identifier" ... | sort | uniq -c`）。forge-stdのsrcの32ファイルはすべて`MIT OR Apache-2.0`で、OpenZeppelin contractsは：

```
      1 // SPDX-License-Identifier: BSD-3-Clause
    318 // SPDX-License-Identifier: MIT
```

BSD-3-Clauseのファイルは`mocks/compound/CompTimelock.sol`一つである。

### 試すときの注意

- Foundry 1.8.3の`forge flatten`は`--offline`引数を受け付けない。
- SPDXの値がリストにある名前かどうかは、コンパイラは確かめない（`Banana-1.0`も通過）。形式だけを見る。

## 時効性のあるデータ

基準日時点の値。ツールとライブラリのバージョンが変わると違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidity公式ドキュメントのバージョン | v0.8.36（Layout of a Solidity Source File、SPDX License Identifier） | 2026-10-19 |
| solcのバージョン | 0.8.30+commit.73712a01、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 (cae51ad) | 2026-10-19 |
| Foundryが既定で隠す警告 | license、code-size、init-code-size、transient-storage、transfer-deprecated、natspec-memory-safe-assembly-deprecated（リストには番号ではなく名前`license`で書かれている。`FOUNDRY_IGNORED_ERROR_CODES='[]'`ならWarning (1878)が出て、`'[1878]'`ならふたたび隠れる） | 2026-10-19 |
| SPDX識別子が言語に入ったバージョン | 0.6.8（2020-05-14リリース）。公式ドキュメントv0.6.7のLayout of a Solidity Source FileにはSPDXの節がなく、v0.6.8からある。Changelog.mdの0.6.8の項目にはSPDXの言及がなく、0.8.9の項目に"Parser: Properly check for multiple SPDX license identifiers next to each other and validate them."（0.6.8のコンパイラでの実行確認はしていない） | 2026-10-19 |
| forge-stdのSPDXの値 | srcの32ファイルすべてMIT OR Apache-2.0（1.17.0） | 2026-10-19 |
| OpenZeppelinのSPDXの値 | contracts 319個のうちMIT 318、BSD-3-Clause 1（v5.4.0） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| バージョン条件以外のpragma（abicoder、experimental） | [第43講](../../part4/lecture43/) |
| メタデータのoutputの欄のuserdoc・devdoc | [第45講](../../part4/lecture45/) |
| メタデータの中身全体 | [第142講](../../part8/lecture142/) |
| importの文法とインポートしたファイルの名前 | [第44講](../../part4/lecture44/) |
| ソースの公開と検証済みソースの再利用 | [第130講](../../part8/lecture130/)、[第153講](../../part9/lecture153/) |
| ライセンスごとの法的効果とGPLコードの再利用条件 | なし |

出典と参考資料は[reference.md](reference.md)にまとめた。
