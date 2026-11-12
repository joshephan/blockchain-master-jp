# 第128講 コマンドラインのオプションとStandard JSON

第8部 コンパイラと内部構造・第30章 コンパイラの使い方

[← 第127講](../../part7/lecture127/) | [第8部 目次](../) | [第129講 →](../../part8/lecture129/)

## この講義の問い

solcにコンパイルをさせる二つの方法（コマンドライン、Standard JSON）は何を渡して何を受け取り、forgeはそのうちどちらを使い、渡した設定は結果のバイトコードにどう残るのか。

## 実習資料

### 準備

solc 0.8.30の実行ファイルを直接呼び、同じ`Store.sol`をコマンドライン（`solc --bin`）とStandard JSON（`solc --standard-json < 入力.json`）の二つの入口でコンパイルして、バイトコードのkeccakを比べた。コマンドは`c128`フォルダの中でファイル名だけを渡して実行した。`market`は通しプロジェクトMarketの第128講のバージョンで、forge-stdが必要である。チェーンにはデプロイしなかった（`cast keccak`、`cast create2`でアドレスだけを計算）。

### コード

| ファイル | 内容 |
|---|---|
| [code/c128/Store.sol](code/c128/Store.sol) | 比較に使ったStore（状態変数`v = 7`、get・set） |
| [code/c128/Bad.sol](code/c128/Bad.sol) | ない名前`w`を返す壊れたStore |
| [code/c128/in-content.json](code/c128/in-content.json) | Standard JSONの入力。ソースを`content`の欄にそのまま入れる |
| [code/c128/in-urls.json](code/c128/in-urls.json)、[code/c128/in.json](code/c128/in.json) | Standard JSONの入力。ソースを`urls`の欄にファイル名で入れる |
| [code/c128/bad.json](code/c128/bad.json) | Bad.solを入れたStandard JSONの入力 |
| [code/c128/stop.json](code/c128/stop.json) | `"stopAfter": "parsing"`を与えた入力 |
| [code/c128/market-sji.json](code/c128/market-sji.json) | `forge verify-contract --show-standard-json-input`が出したMarketの入力（srcの四つのファイル、settingsの七つの欄） |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第128講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第128講のバージョン |
| [code/market/test/](code/market/test/) | Marketのテスト55個 |

### 実行結果

二つの入口で同じバイトコード。

```
$ solc --bin Store.sol  -> 401 bytes, keccak 0x42853029af491405daa929b01b815fe2af87f9d265e4ea18760acfebfee7599d
$ solc --standard-json < in-content.json  -> exit 0, 401 bytes, keccak 0x42853029af491405daa929b01b815fe2af87f9d265e4ea18760acfebfee7599d, 一致=True
$ solc --standard-json --allow-paths . < in-urls.json  -> 一致=True
$ solc --standard-json --base-path . < in-urls.json  -> 一致=True
```

`solc --metadata Store.sol`のsettings（コマンドラインの既定値）。

```
{"compilationTarget": {"Store.sol": "Store"}, "evmVersion": "prague", "libraries": {}, "metadata": {"bytecodeHash": "ipfs"}, "optimizer": {"enabled": false, "runs": 200}, "remappings": []}
```

壊れたソース。コマンドラインは終了コード1、Standard JSONは終了コード0で、エラーが`errors`の欄に入る。

```
$ solc --bin Bad.sol
Error: Undeclared identifier.
 --> Bad.sol:8:16:
  |
8 |         return w;
  |                ^
(exit 1)
$ solc --standard-json < bad.json  -> exit 0, keys ['errors', 'sources']
  DeclarationError: Undeclared identifier.
```

settingsの欄の名前を間違えると、終了コード0で`errors`だけができる。

| 入れた欄 | errors |
|---|---|
| `"optimiser": {"enabled": true}` | `Unknown key "optimiser"` |
| `"optimizer": {"enable": true}` | `Unknown key "enable"` |
| `"evmVersion": "osaka2"` | `Invalid EVM version requested.` |

`outputSelection`を抜くと、エラーなしで`{'Store.sol': {'id': 0}}`だけが返る。`stop.json`は`Requested output selection conflicts with "settings.stopAfter".`である。

optimizerの設定を二つの入口で。

| 設定 | サイズ | keccak |
|---|---|---|
| `--optimize` / JSON `{"enabled": true, "runs": 200}` | 213 | 0xafd4ae3e…d08b（二つは同じ） |
| `--optimize --optimize-runs 1` | 213 | 0x773cabbf…c7d0 |
| JSON `{"runs": 1}`（enabledなし） | 401 | 0xa060fa6c…c0f6。既定のビルドとは末尾のメタデータハッシュ32バイトだけが違う |

同じアカウント0番、salt 1で`cast create2`を回すと、既定のビルドは`0x4Cd172F10fb57bCaEd51c3B535e3AfFc1d8Beaf3`、JSON `{"runs": 1}`のビルドは`0x1A8f532F9D7181b7CBd8989d2Ee64a5b5E8cBb5F`である。optimizerを入れなくてもrunsの値がメタデータに入り、アドレスが変わる。

Yulのソース（Store124.yul）もStandard JSONで入れられ、`--strict-assembly --bin`と同じ88バイトが出る。

Market。forgeが渡した入力（`forge verify-contract --show-standard-json-input`）をsolcにそのまま入れると、forgeの成果物と同じになる。

```
欄: language, sources, settings / sources src/Market.sol, src/MarketTypes.sol, src/IMarket.sol, src/MarketMath.sol
solc --standard-json < sji -> exit 0, errors [], runtime 7353 / creation 7931, forgeとruntime一致=True, creation一致=True
```

一方、build-infoの`input`をそのまま入れると、forgeが付け足した欄のせいで`Unknown key "allowPaths"`が出る。outputSelectionにabi・gasEstimates・storageLayoutを足しても、バイトコードは同じである。MarketのimmutableReferencesは六つの区間（3489・3660、2374・2421・2923、2845、それぞれ32バイト）である。

Market 第128講のバージョンはruntime 7,353 / creation 7,931（initcodeの余裕41,221）、`forge test`の55個が通り、linkReferences `{}`、runtimeのkeccak 0x966122b4…039dである。

### 試すときの注意

- Standard JSONは、コンパイルが失敗しても終了コードが0である。`errors`の欄を自分で確かめなければならない。欄の名前の打ち間違いも、エラーではなく`errors`の項目として出るだけである。
- `urls`の欄でファイルを渡すときは、`--allow-paths`か`--base-path`を与える。
- solcをそのまま呼ぶとevm_versionの既定値はpragueで、forge 1.8.3はosakaを渡す。同じ結果がほしければ、evm_versionを書いて渡す。
- forgeのbuild-infoの`input`は、solcの入力そのままではない。solcに入れ直す入力は`forge verify-contract --show-standard-json-input`で取り出す。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやドキュメントのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメントのバージョン | Using the Compiler（Using the Commandline Compiler、Setting the EVM Version to Target、Compiler Input and Output JSON Description）v0.8.36タグ。evm_versionの一覧でosakaが`(**default**)`、amsterdamが`(**experimental**)` | 2026-10-20 |
| solc | 0.8.30+commit.73712a01。コマンドラインの既定のevm_versionはprague、`--help`に"prague or osaka (experimental)."、オプションの行72個・節12 | 2026-10-20 |
| Foundry（forge・cast） | 1.8.3、forgeの既定のevm_versionはosaka、`forge config`の既定値`auto_detect_remappings = true`、`bytecode_hash = "ipfs"`、`cbor_metadata = true`、`build_info = false` | 2026-10-20 |
| forgeのbuild-infoの形式 | `_format` ethers-rs-sol-build-info-1、inputの欄にforgeが付け足した`version`・`allowPaths`・`basePath`・`includePaths`（絶対パス） | 2026-10-20 |
| `forge verify-contract` | ヘルプの1行目"Verify smart contracts on Etherscan and Sourcify"、`--show-standard-json-input` "Prints the standard json compiler input." RPC・APIキーなしで出力される。外部への接続の有無は確かめていない | 2026-10-20 |
| エラーの文言 | `Error: Undeclared identifier.`（7576）、`Unknown key "optimiser"`、`Unknown key "enable"`、`Invalid EVM version requested.`、`Unknown key "allowPaths"`、`Requested output selection conflicts with "settings.stopAfter".` | 2026-10-20 |
| Storeの値 | 既定 401バイト 0x42853029…599d（runtime 369、末尾のハッシュ3ab396b3…d87d） / `--optimize` 213 0xafd4ae3e…d08b / `--optimize-runs 1` 213 0x773cabbf…c7d0 / JSON `{"runs":1}` creation 0xa060fa6c…c0f6（runtimeの末尾のハッシュd763113c…a34d3、0から数えて326番目から32バイトだけが違う） / CREATE2（アカウント0番、salt 1）0x4Cd172F10fb57bCaEd51c3B535e3AfFc1d8Beaf3・0x1A8f532F9D7181b7CBd8989d2Ee64a5b5E8cBb5F / Store124.yul 88バイト | 2026-10-20 |
| Marketの値 | runtime 7,353 / creation 7,931、initcodeの余裕41,221、テスト55個、linkReferences {}、immutableReferences 六つの区間（3489・3660、2374・2421・2923、2845、それぞれ32バイト）、runtimeのkeccak 0x966122b4…039d（第128講のバージョン） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| importの文字列がファイルに変わる規則、remapping・基準のパス | [第129講](../../part8/lecture129/) |
| 同じ入力で作り直すことと、チェーンのコードとの突き合わせ | [第130講](../../part8/lecture130/) |
| ASTとバイトコードの構造 | [第131講](../../part8/lecture131/) |
| ソースマップ | [第132講](../../part8/lecture132/) |
| 二つのコード生成の経路（viaIR） | [第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| storageLayoutの出力とスロットの配置 | [第135講](../../part8/lecture135/) |
| optimizerのステップとdetailsの欄 | [第139講](../../part8/lecture139/)、[第140講](../../part8/lecture140/) |
| メタデータの欄の一つひとつ | [第142講](../../part8/lecture142/) |
| ドキュメントコメントの出力（devdoc・userdoc） | [第146講](../../part9/lecture146/)、[第147講](../../part9/lecture147/) |
| modelCheckerの欄 | [第182講](../../part11/lecture182/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
