# 第24講 foundry.tomlの設定とプロファイル

第2部 開発とテスト環境・第6章 Foundryの基本

[← 第23講](../../part2/lecture23/) | [第2部 目次](../) | [第25講 →](../../part2/lecture25/)

## この講義の問い

pragmaが拒否するだけなら、実際に使うコンパイラと最適化はどこで決め、チーム全体が同じ値を使うようにするにはどうすればよいのか。

## 実習資料

### 準備

`forge init demo`で新しいプロジェクトを作る（forge-std v1.17.0が一緒に入る）。デフォルトの設定を見たあと`foundry.toml`に`solc = "0.8.30"`を入れ、その状態から1行ずつ変えながらビルドする。ハードフォークの比較には、ローカルのanvilを`--hardfork paris`で起動する。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | `solc = "0.8.30"`を固定し、optimizerをオンにした`ci`プロファイルを足した最終設定 |
| [code/src/Counter.sol](code/src/Counter.sol) | `forge init`が作ったCounterそのまま |
| [code/.gitignore](code/.gitignore) | `forge init`が作った.gitignore（`.env`を除外する） |

### 実行結果

`forge config`の抜粋（デフォルトのfoundry.toml、全276行）。`solc`の行は出力にない：

```
[profile.default]
src = "src"
test = "test"
script = "script"
out = "out"
libs = ["lib"]
remappings = ["forge-std/=lib/forge-std/src/"]
...
evm_version = "osaka"
...
auto_detect_solc = true
offline = false
optimizer = false
optimizer_runs = 200
...
via_ir = false
...
bytecode_hash = "ipfs"
cbor_metadata = true
```

1行だけを変えてビルドした結果。サイズは`forge build --sizes`のRuntime Size、ハッシュは`forge inspect Counter deployedBytecode | cast keccak`：

```
追加した行なし                  481  0xe83f6304215ec3e78661dc1b14562ee1a0b5be7375159e065f33553ab6642ee3
optimizer = true                236  0x1dd59ca01d257807681dcfe58539af7d43addb2c4e5640c4f7f1f23ae9de16af
via_ir = true                   709  0x95ef94011ec8942d3a1cbee053bca23b83a7ca265eaff590fee8959c2f551af2
optimizer = true, via_ir = true 210  0x5a7885b647f86bec2b2af218f564e958a999fc23bd9ed92f56b5c62323d6cc42
evm_version = "paris"           498  0x61085c29b97330a13386790ec9b5b24f711e526862a8e8dfb70b07b4e70780d6
```

実行用のコードの末尾には設定を含むメタデータハッシュがつくため、ハッシュの違いの一部はメタデータの違いである。サイズの違いはコードそのものの違いである。

`cast disassemble`で見た実行用のコードの先頭。デフォルト（osaka）はPUSH0を使い（全297行、PUSH0は23回）、parisは使わない（全284行、PUSH0は0回）：

```
# osaka
00000008: PUSH2 0x000f
0000000b: JUMPI
0000000c: PUSH0
0000000d: PUSH0
0000000e: REVERT
0000000f: JUMPDEST

# paris
00000008: PUSH2 0x0010
0000000b: JUMPI
0000000c: PUSH1 0x00
0000000e: DUP1
0000000f: REVERT
00000010: JUMPDEST
```

`anvil --hardfork paris`で起動したチェーンに、デフォルトでビルドしたコードを`cast send --create`でデプロイすると拒否される：

```
Error: Failed to estimate gas: server returned an error response: error code -32003: EVM error NotActivated
```

`evm_version = "paris"`で再ビルドして同じコマンドを送ると成功する：

```
contractAddress      0x5FbDB2315678afecb367f032d93F642f64180aa3
status               1 (success)
```

`ci`プロファイルとデフォルトプロファイルの`forge config`の差分（`diff <(forge config) <(FOUNDRY_PROFILE=ci forge config)`）：

```
1c1
< [profile.default]
---
> [profile.ci]
28,29c28,29
< optimizer = false
< optimizer_runs = 200
---
> optimizer = true
> optimizer_runs = 10000
95c95
< [profile.default.rpc_storage_caching]
---
> [profile.ci.rpc_storage_caching]
99c99
< [[profile.default.fs_permissions]]
---
> [[profile.ci.fs_permissions]]
```

`ci`プロファイルに書かなかった`src`、`evm_version`、`solc`は、デフォルトプロファイルの値をそのまま引き継ぐ。`FOUNDRY_PROFILE=ci forge build --sizes`のCounterのRuntime Sizeは292である。

環境変数`FOUNDRY_OPTIMIZER=true`をつけると、ファイルを直さなくても`optimizer = true`になり、実行用のコードのハッシュはファイルに`optimizer = true`を書いたビルドと同じになる（`0x1dd59ca0...`）。同じ行を`.env`に書いても`forge config`は`optimizer = true`を表示し、`.env`を消すと`false`に戻る。`.env`は.gitignoreで除外されている：

```
$ git check-ignore -v .env
.gitignore:18:.env	.env
```

### 試すときの注意

- この環境では、`forge init`はgitリポジトリを作るだけで、最初のコミットは残さなかった。Foundry 1.8.3の`forge init --help`には`--commit`（インストール後にコミットを作成）というオプションが別にある。バージョンによってデフォルトの動作が違うことがある。
- 最初に作った`foundry.toml`は、まだgitに載っていない状態（`??`）である。設定をチームメンバーとCIに伝えるには、`git add`で載せる必要がある。
- デフォルトでビルドしたコードはPUSH0を使うため、shanghaiより前の規則のチェーンに載せるには`evm_version`を合わせる必要がある。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、デフォルト値と数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundryのバージョン | forge 1.8.3 (commit cae51ad) | 2026-10-18 |
| forge-stdのバージョン | v1.17.0 (f3dae6e) | 2026-10-18 |
| Foundryのデフォルトのevm_version | `osaka` | 2026-10-18 |
| Foundryのデフォルトの最適化設定 | `optimizer = false`、`optimizer_runs = 200`、`via_ir = false` | 2026-10-18 |
| `forge config`の出力の規模 | 276行、`[profile.default]`節の設定84個（Foundry 1.8.3） | 2026-10-18 |
| Counterの実行用のコードのサイズ（solc 0.8.30、Foundry 1.8.3） | デフォルト481 / optimizer 236 / via_ir 709 / 両方210 / paris 498 / ciプロファイル（runs 10000）292バイト | 2026-10-18 |
| PUSH0の個数（実行用のコードのdisassemble、solc 0.8.30） | デフォルト（osaka）23 / paris 0 | 2026-10-18 |
| PUSH0が導入されたハードフォーク、Solidityでデフォルトで使われ始めたバージョン | shanghai、0.8.20（Changelog "Set default EVM version to Shanghai"） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| remappingsとlibフォルダの他人のコード | [第25講](../../part2/lecture25/) |
| 依存関係のバージョン固定（コミットハッシュ、lockファイル） | [第25講](../../part2/lecture25/) |
| テストの作成と実行（forge test） | [第28講](../../part2/lecture28/) |
| デプロイスクリプトとデプロイしたバイトコードの確認の実務 | [第34講](../../part2/lecture34/) |
| オプティマイザとvia-IRの内部、Yulの最適化段階 | [第124講](../../part7/lecture124/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
