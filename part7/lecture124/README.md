# 第124講 Yulのオブジェクトの構造と最適化のステップ

第7部 アセンブリとYul・第28章 独立した言語としてのYul

[← 第123講](../../part7/lecture123/) | [第7部 目次](../) | [第125講 →](../../part7/lecture125/)

## この講義の問い

Yulのファイル一式はどんな形をしていて、Solidityのソースはコンパイラの中でどんなYulになり、最適化のステップはそのYulの何を変えて何を残すのか。

## 実習資料

### 準備

YulのファイルとSolidityのファイルは、Foundryを通さずにsolc 0.8.30の実行ファイルを直接呼んでコンパイルした（`solc --strict-assembly`、`--bin`、`--ir`、`--ir-optimized`、`--optimize`）。Solidityのファイルは、そのファイルがあるフォルダに入ってファイル名だけを渡した。渡したパスがメタデータに入り、バイトコードの末尾が変わるからである。デプロイは、ローカルのanvilでアカウント0番が`cast send --create`で行った。`market`は通しプロジェクトMarketの第124講のバージョンで、forge-stdが必要である。

### コード

| ファイル | 内容 |
|---|---|
| [code/yul/Store124.yul](code/yul/Store124.yul) | 手で書いたYulのオブジェクト。外のオブジェクト`Store`（デプロイのコード）と内側のオブジェクト`Store_deployed`（ランタイムコード、get・set・noteのディスパッチャ、dataの欄"Store124"） |
| [code/bad/wrongname.yul](code/bad/wrongname.yul) | ない内側のオブジェクト名`A_runtime`を呼ぶ |
| [code/bad/outer_from_inner.yul](code/bad/outer_from_inner.yul) | 内側のcodeから外のオブジェクト名`A`を呼ぶ |
| [code/bad/twocode.yul](code/bad/twocode.yul) | 一つのオブジェクトに`code`の欄が二つ |
| [code/bad/bare.yul](code/bad/bare.yul) | オブジェクトなしで`sstore(0, 7)`の1行 |
| [code/sol/Store.sol](code/sol/Store.sol) | Store124.yulと同じことをするSolidityのバージョン。`--ir`のオブジェクトの比較用 |
| [code/sol/Opt124.sol](code/sol/Opt124.sol) | `add`と、定数どうしを足す`seven`。最適化のステップの前後のIRの比較用 |
| [code/deep/lie.sol](code/deep/lie.sol) | 第121講のDeepに表示をつけて、0x80に書くブロックを入れたバージョン |
| [code/deep/noann.sol](code/deep/noann.sol) | 第121講のDeepに、表示なしでメモリに触らないブロックを入れたバージョン |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第124講のバージョンの設定。Foundryの既定値と同じビルド設定4行（`optimizer = false`、`optimizer_runs = 200`、`via_ir = false`、`evm_version = "osaka"`）を書いておく |
| [code/market/src/](code/market/src/) | Market 第124講のバージョン |
| [code/market/test/](code/market/test/) | Marketのテスト55個 |

### 実行結果

`solc --strict-assembly Store124.yul --bin`は88バイトである。先頭の14バイト`60075f55604a80600e5f395ff3fe`が外のcode、その次の74バイトが内側のオブジェクトで、いちばん最後の8バイト`53746f7265313234`が"Store124"である（`604a` = 74、`600e` = 14）。

```
60075f55604a80600e5f395ff3fe5f3560e01c80636d4ce63c14603857806360fe47b114602f576326d111f5146025575f80fd5b60088060425f395ff35b6004355f555f80f35b5f545f5260205ff3fe53746f7265313234
```

デプロイして呼んだ結果。デプロイのgasUsedは91,353、チェーンに残ったコードは74バイトである。

```
$ cast code $Y
0x5f3560e01c80636d4ce63c14603857806360fe47b114602f576326d111f5146025575f80fd5b60088060425f395ff35b6004355f555f80f35b5f545f5260205ff3fe53746f7265313234
$ cast call $Y "get()(uint256)"
7
$ cast send $Y "set(uint256)" 5
status 1, gasUsed 26273
$ cast call $Y "get()(uint256)"
5
$ cast call $Y "note()"
0x53746f7265313234
$ cast call $Y "note()(string)"
Error: could not decode output; did you specify the wrong function return data type?
Context:
- ABI decoding failed: buffer overrun while deserializing
$ cast call $Y "v()"
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

オブジェクトなしで書いた`bare.yul`からは5バイトの`60075f5500`が出て、デプロイ（gasUsed 75,175）するとスロット0は7なのにコードは0バイト（`cast code`が`0x`）である。

Yulのオブジェクトのエラー三つ（`solc --strict-assembly`）。

| ファイル | エラー |
|---|---|
| wrongname.yul | `Error: Unknown data object "A_runtime".` |
| outer_from_inner.yul | `Error: Unknown data object "A".` |
| twocode.yul | `Error: Expected keyword "data" or "object" or "}".` |

`solc --ir Store.sol`が作ったオブジェクト（抜粋）。手で書いたStore124.yulと同じ形である。

```
object "Store_23" {
    code {
        mstore(64, memoryguard(128))
        if callvalue() { revert_error_ca66f745…() }
        constructor_Store_23()
        let _1 := allocate_unbounded()
        codecopy(_1, dataoffset("Store_23_deployed"), datasize("Store_23_deployed"))
        return(_1, datasize("Store_23_deployed"))
        …
    }
    object "Store_23_deployed" {
        code { … switch selector … }
        data ".metadata" hex"a264…0033"
    }
}
```

IRの行数: Storeは`--ir`で341行・関数47個、`--ir-optimized --optimize`で54行・関数0個。Opt124は`--ir`で261行・30個（checked_addが3か所）、`--ir-optimized`で187行・28個、`--ir-optimized --optimize`で55行・0個。Marketは`forge inspect ir`で3,072行・297個。

`--optimize`でコンパイルし直したStore124.yulは86バイト（内側72バイト）、デプロイのgasUsed 90,909、setのgasUsed 26,268である。

Deepの二つのバージョンのIR。表示をつけて0x80に書いたバージョンで、`--ir-optimized`は`memoryguard(0x0380)`を入れ、ブロックの`mstore(0x80, 5)`はそのまま残る。第121講で、このバージョンのdeep(0)は256（正しい答えは253）だった。

Market 第124講のバージョンは、`forge build --sizes`で7,353 / 7,931、`forge test`の55個が通り、`grep -n assembly src/*.sol`は0行である。foundry.tomlに4行を書く前のバージョンとランタイムコードは同じ長さで、末尾のメタデータハッシュだけが違う。

### 試すときの注意

- 内側のオブジェクト名は`_deployed`で終わってはじめて、Yulのオプティマイザがランタイムコードとして扱う。外のcodeからは内側のオブジェクトとdataだけを呼べ、内側から外の名前は呼べない。
- `--strict-assembly`には`--abi`がなく（`Error: The following outputs are not supported in assembler mode: --abi.`）、メタデータの末尾もつかない。
- `solc --bin sol/Store.sol`のようにパスをつけて呼ぶと、メタデータのcompilationTargetが変わり、initcodeのkeccakが変わる。CREATE2のアドレスもそれにつれて変わる。
- solc 0.8.30をそのまま呼ぶとevm_versionの既定値はpragueで、forge 1.8.3はosakaを渡す。両者のStoreのランタイムは長さが同じで、末尾のハッシュだけが違う。
- `cast send --create`は、ほかのオプションのうしろのいちばん最後に置く。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| ツール | solc 0.8.30+commit.73712a01（svmのキャッシュを直接呼ぶ）、Foundry 1.8.3（forge・cast・anvil） | 2026-10-19 |
| evm_versionの既定値 | solc 0.8.30をそのまま呼ぶとprague（`--help`の`--evm-version version (=prague)`）、forge 1.8.3はosakaを渡す（メタデータ`"evmVersion": "osaka"`） | 2026-10-19 |
| optimizer runs | 200（solc・Foundryの既定） | 2026-10-19 |
| メタデータの末尾 | ランタイムの末尾53バイト = CBOR 51 + 長さ2、`00081e` = 0.8.30 | 2026-10-19 |
| Store124.yul | `--bin` 88バイト（外14 + 内側74）、`--optimize` 86バイト（内側72）。デプロイのgasUsed 91,353 / 90,909、setのgasUsed 26,273 / 26,268。`--abi`: `Error: The following outputs are not supported in assembler mode: --abi.`、メタデータの末尾なし | 2026-10-19 |
| オブジェクトのないブロック | `60075f5500` 5バイト、デプロイのgasUsed 75,175、コード0バイト、スロット0 = 7 | 2026-10-19 |
| IRの行数（ファイル名だけを渡して実行） | Store `--ir` 341行・関数47個 / `--ir-optimized --optimize` 54行・0個。Opt124 `--ir` 261・30（checked_addが3か所） / `--ir-optimized` 187・28 / `--ir-optimized --optimize` 55・0。Market `forge inspect ir` 3,072行・297個 | 2026-10-19 |
| サイズ（runtime / initcode） | Store 369 / 401、183 / 213、660 / 805、186 / 214。Market 7,353 / 7,931、3,755 / 4,013、7,615 / 8,209、3,260 / 3,473（既定で切る / 既定で入れる / via-IRで切る / via-IRで入れる） | 2026-10-19 |
| CREATE2 | Storeの切ったバージョンのinitcodeのkeccak 0x42853029…599d → 0x4Cd172F10fb57bCaEd51c3B535e3AfFc1d8Beaf3、入れたバージョン0xafd4ae3e…d08b → 0xE1409D5b74EaCEa2E9C21b960654e8e4dD1E16Cb（deployerはアカウント0番、salt 1）。`solc --bin sol/Store.sol`のようにパスをつけて呼ぶと、メタデータのcompilationTargetが変わってinitcodeのkeccakが0xd968dd7d…8cf6に変わる | 2026-10-19 |
| prague / osaka | Storeのランタイムはどちらも369バイト、0から数えて326番目のバイト（末尾のipfsハッシュの始まり）から違う。末尾のハッシュはprague `3ab396b3…`、osaka `10ea71a5…`。forgeのビルド（src/Store.sol）はパスまで違うので`aea22d65…` | 2026-10-19 |
| Marketの末尾 | 第27章の終わりのバージョンと第124講のバージョンはruntime 7,353バイト、0から数えて7,310番目のバイト（末尾のハッシュの始まり）から違う。第27章の終わりのバージョンのMarket.solに4行だけを足したバージョンはruntimeのkeccak 0xd126254c…9c3a、creation 0x6ac2ff20…8c3eで、第27章の終わりのバージョンと同じ | 2026-10-19 |
| Deep | `--ir` `memoryguard(128)`（7・38行目）、`--ir-optimized` `memoryguard(0x80)`（7行目）・`memoryguard(0x0380)`（26行目）、270行目`mstore(0x80, expr_5)`、452行目`mstore(0x80, 5)`。第121講の結果 deep(0) 256 / 正しい答え253 | 2026-10-19 |
| アカウント0番 | anvilの既定のアカウント（公開されたテスト用の鍵）、`--unlocked --from` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Yulだけでコントラクトを書く場合と、抜けるチェック | [第125講](../../part7/lecture125/) |
| コマンドラインのオプションとStandard JSON | [第128講](../../part8/lecture128/) |
| メタデータの末尾とソースの検証の手順 | [第130講](../../part8/lecture130/) |
| 逆アセンブルの画面の読み方 | [第131講](../../part8/lecture131/) |
| ソースのファイル名（渡したパス）がメタデータのcompilationTargetとバイトコードに与える影響 | [第129講](../../part8/lecture129/)、[第130講](../../part8/lecture130/) |
| 既定の経路とvia-IRの経路の違い | [第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| 最適化のステップの名前と順序、`--yul-optimizations` | [第139講](../../part8/lecture139/)、[第140講](../../part8/lecture140/) |
| ディスパッチャの比較の順序とガス、最適化の設定の選び方 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| コンパイラのバグの履歴 | [第184講](../../part11/lecture184/) |
| デプロイされたバイトコードを読むツール | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
