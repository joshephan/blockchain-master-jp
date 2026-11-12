# 第21講 コンパイルパイプラインの全体像

第2部 開発とテスト環境・第5章 ツールチェーンとコンパイラ

[← 第20講](../../part2/lecture20/) | [第2部 目次](../) | [第22講 →](../../part2/lecture22/)

## この講義の問い

ソースファイル一つがチェーンに載るまでにいくつの段階を経て、その間に何が作られるのか。

## 実習資料

### 準備

ライブラリのないFoundryプロジェクト一つにCounterを置き、Foundryが管理するsolc 0.8.30でコンパイルする。間違ったコード二つは、それぞれ別のフォルダ（`err1`、`err2`）でコンパイルする。最適化設定ごとのデプロイガスは、ローカルのanvilに`cast send --create`でデプロイしてレシートから読んだ。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | ライブラリなしの基本設定 |
| [code/src/Counter.sol](code/src/Counter.sol) | `pragma solidity 0.8.30`のCounter（`count`、`increment()`） |
| [code/err1/src/Typo.sol](code/err1/src/Typo.sol) | セミコロンを書き忘れたコード（読み込み段階のエラー） |
| [code/err2/src/WrongType.sol](code/err2/src/WrongType.sol) | `uint256`に文字列を入れるコード（型検査のエラー） |
| [code/err1/foundry.toml](code/err1/foundry.toml)、[code/err2/foundry.toml](code/err2/foundry.toml) | 二つのエラーフォルダの設定 |
| [code/Typo.json](code/Typo.json)、[code/WrongType.json](code/WrongType.json) | 同じ二つのファイルをsolcに直接渡すstandard JSON入力 |

### 実行結果

間違ったコード二つを`forge build --use 0.8.30 --offline`でコンパイル：

```
Error: Compiler run failed:
Error (2314): Expected ';' but got '}'
 --> src/Typo.sol:9:5:
  |
9 |     }
  |     ^
```

```
Error: Compiler run failed:
Error (7407): Type literal_string "zero" is not implicitly convertible to expected type uint256.
 --> src/WrongType.sol:8:17:
  |
8 |         count = "zero";
  |                 ^^^^^^
```

standard JSON入力でsolcを直接実行し、`errors`配列のtype、errorCode、messageだけを取り出すと、二つのエラーが別々の段階で出たことがわかる：

```
ParserError 2314 Expected ';' but got '}'
TypeError 7407 Type literal_string "zero" is not implicitly convertible to expected type uint256.
```

`solc --stop-after parsing`で読み込みまでだけ実行すると、Typo.solは失敗（終了コード1）、WrongType.solは`Compiler run successful. No output generated.`（終了コード0）で終わる。`count += 1`を`cout += 1`に変えると`DeclarationError 7576 Undeclared identifier. Did you mean "count"?`が出る。

`forge inspect Counter bytecode`（生成コード）：

```
0x6080604052348015600e575f5ffd5b5061012f8061001c5f395ff3fe6080604052348015600e575f5ffd5b50600436106030575f3560e01c806306661abd146034578063d09de08a14604e575b5f5ffd5b603a6056565b604051604591906089565b60405180910390f35b6054605b565b005b5f5481565b60015f5f828254606a919060cd565b92505081905550565b5f819050919050565b6083816073565b82525050565b5f602082019050609a5f830184607c565b92915050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f60d5826073565b915060de836073565b925082820190508082111560f35760f260a0565b5b9291505056fea26469706673582212203ca59066c45a6361fafe22134d20e3ffad5399483ca558b8282ad41ab562373f64736f6c634300081e0033
```

`forge inspect Counter deployedBytecode`は、上の値から先頭の28バイト（`5ff3fe`まで）を除いた残りである。生成コードは331バイト、ランタイムコードは303バイト。先頭の28バイトを`cast disassemble`でほどくと、ランタイムコードをメモリにコピーして返す短いコードである：

```
00000000: PUSH1 0x80
00000002: PUSH1 0x40
00000004: MSTORE
00000005: CALLVALUE
00000006: DUP1
00000007: ISZERO
00000008: PUSH1 0x0e
0000000a: JUMPI
0000000b: PUSH0
0000000c: PUSH0
0000000d: REVERT
0000000e: JUMPDEST
0000000f: POP
00000010: PUSH2 0x012f
00000013: DUP1
00000014: PUSH2 0x001c
00000017: PUSH0
00000018: CODECOPY
00000019: PUSH0
0000001a: RETURN
0000001b: INVALID
```

`forge inspect Counter abi`とセレクタの計算：

```
╭----------+--------------------------------+------------╮
| Type     | Signature                      | Selector   |
+========================================================+
| function | count() view returns (uint256) | 0x06661abd |
|----------+--------------------------------+------------|
| function | increment() nonpayable         | 0xd09de08a |
╰----------+--------------------------------+------------╯
$ cast keccak "increment()"
0xd09de08ab1a974aadf0a76e6f99a2ec20e431f22bbc101a6c3f718e53646ed8d
$ cast sig "count()"
0x06661abd
```

`forge inspect Counter metadata`の主な部分：`"compiler": {"version": "0.8.30+commit.73712a01"}`、`"optimizer": {"enabled": false, "runs": 200}`、`"metadata": {"bytecodeHash": "ipfs"}`、`"evmVersion": "osaka"`、`"src/Counter.sol": {"keccak256": "0xea8e4d42ce24af8a4831425ee7da41b835a02bc92e5ae8eac34127d4930646a1", ...}`。

Yul中間表現（`forge inspect Counter ir`、258行）のうち、`count += 1`が変換された部分。0.8の基本の算術検査が`checked_add_t_uint256`として入っている：

```
            function checked_add_t_uint256(x, y) -> sum {
                x := cleanup_t_uint256(x)
                y := cleanup_t_uint256(y)
                sum := add(x, y)

                if gt(x, sum) { panic_error_0x11() }

            }
...
            function fun_increment_11() {

                /// @src 0:154:155  "1"
                let expr_7 := 0x01
                /// @src 0:145:155  "count += 1"
                let _1 := convert_t_rational_1_by_1_to_t_uint256(expr_7)
                let _2 := read_from_storage_split_offset_0_t_uint256(0x00)
                let expr_8 := checked_add_t_uint256(_2, _1)
```

`uint256 public count;`の上にコメント`// カウンターの値`を1行入れて再コンパイルすると、ランタイムコードの最後の53バイト（メタデータの尻尾）だけが変わり、その前の250バイトは同じである：

```
前: a26469706673582212203ca59066c45a6361fafe22134d20e3ffad5399483ca558b8282ad41ab562373f64736f6c634300081e0033
後: a264697066735822122092b42e5193abf7bc67c9a69a08e8a8d45eaf5408e01b60e06c9b71f58a69c56764736f6c634300081e0033
```

最適化設定ごとのコードサイズ（バイト）とガス。デプロイ後に`increment()`を2回送った（runs 200はサイズだけを測った）：

| 設定 | 生成コード | ランタイムコード | デプロイガス | incrementの1回目の呼び出し | 2回目の呼び出し |
|---|---|---|---|---|---|
| 最適化オフ | 331 | 303 | 118643 | 43517 | 26417 |
| `--optimize --optimizer-runs 1` | 223 | 197 | 96037 | 43405 | 26305 |
| `--optimize --optimizer-runs 200` | 223 | 197 | | | |
| `--optimize --optimizer-runs 1000000` | 248 | 222 | 101103 | 43405 | 26305 |

デプロイしたアドレスから`cast code`で読んできたコードは`deployedBytecode`と同じで、生成コードとは違う。`cast codesize`は303である。

### 試すときの注意

- メタデータの尻尾にはソースファイルのハッシュが入るため、コメントを1行変えるだけでもバイトコードが変わる。動作する部分はそのままである。
- チェーンに載るのは、生成コードが返したランタイムコードである。`cast code`で見えるのもランタイムコードである。

## 時効性のあるデータ

基準日時点の値。コンパイラ、Foundry、EVMのバージョンが変わると値が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 基本のコンパイルパイプライン | 従来方式（legacy）がデフォルト、via-IRは設定でオン。0.8.37の文書でもviaIRのデフォルトはfalse | 2026-10-20 |
| Foundryのデフォルトの最適化設定 | `optimizer = false`、`optimizer_runs = 200` | 2026-10-17 |
| FoundryのデフォルトのEVMバージョン | `osaka` | 2026-10-17 |
| Counterのランタイムコードのサイズ（solc 0.8.30） | オフ 303 / runs 1 197 / runs 1,000,000 222バイト | 2026-10-17 |
| Counterのデプロイガス（anvil、Foundry 1.8.3） | オフ 118,643 / runs 1 96,037 / runs 1,000,000 101,103 | 2026-10-17 |
| increment()のガス（1回目の呼び出し / 2回目の呼び出し） | オフ 43,517 / 26,417、runs 1とruns 1,000,000はどちらも43,405 / 26,305 | 2026-10-17 |
| 既知のバグ一覧のうち最適化関連の項目数 | 全67項目中、最適化の条件（optimizer・yulOptimizer）がつく項目は14。最新の項目はYulOptimizerKnowledgeBaseStaleBookkeeping（0.8.19で導入、0.8.38で修正） | 2026-10-20 |
| メタデータの尻尾の形式（solc 0.8.30、`bytecode_hash = "ipfs"`） | CBOR、ipfsハッシュ + solcバージョン3バイト + 長さ2バイト | 2026-10-17 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| foundry.tomlでの最適化・via-IR・EVMバージョンの設定 | [第24講](../../part2/lecture24/) |
| ブラウザでコンパイル・デプロイを一度に行うツール | [第22講](../../part2/lecture22/) |
| デプロイスクリプトとブロックエクスプローラーでのソース検証 | [第34講](../../part2/lecture34/)、[第130講](../../part8/lecture130/) |
| Standard JSON入力とコマンドラインオプション | [第128講](../../part8/lecture128/) |
| 構文木とバイトコードの構造、ソースマッピング | [第131講](../../part8/lecture131/)、[第132講](../../part8/lecture132/) |
| Yulのオブジェクト構造、IRコード生成と従来方式の違い | [第124講](../../part7/lecture124/)、[第133講](../../part8/lecture133/) |
| オプティマイザの段階ごとの動作と最適化結果の検証 | [第139講](../../part8/lecture139/)、[第140講](../../part8/lecture140/) |
| セレクタの計算とABIエンコーディングの規則、メタデータの形式 | [第101講](../../part6/lecture101/)、[第141講](../../part8/lecture141/)、[第142講](../../part8/lecture142/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
