# 第142講 コントラクトのメタデータ

第8部 コンパイラと内部構造・第35章 ABI仕様とメタデータ

[← 第141講](../../part8/lecture141/) | [第8部 目次](../) | [第143講 →](../../part9/lecture143/)

## この講義の問い

メタデータのJSON1枚には何が入って何が抜けるのか。チェーンに残る末尾のハッシュ一つで、そのJSONとソースファイルをどうやって突き合わせ直すのか。

## 実習資料

### 準備

通しプロジェクトMarketの第141講のバージョンと第142講のバージョン（第141講のバージョンとコードが同じで、foundry.tomlにメタデータの末尾の設定`bytecode_hash = "ipfs"`、`cbor_metadata = true`を書いておいたバージョン）を使う。solc 0.8.30、Foundry 1.8.3で、forge-stdが必要である（`lib/forge-std`）。メタデータは、ビルドの成果物`out/Market.sol/Market.json`の`rawMetadata`の欄から取り出し、Pythonの`json`で読む。設定を変えたビルド（`FOUNDRY_BYTECODE_HASH`、`FOUNDRY_CBOR_METADATA`、`FOUNDRY_USE_LITERAL_CONTENT`、`///`の1行、空行の1行）は、どれもバージョンをコピーして行う。settingsの欄一つずつの効果は、小さなファイルU・Lをsolc `--standard-json`に入れて見る。チェーン側は、ローカルのanvilにアカウント0番がMarketを直接デプロイして確かめる。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | default（optimizerを入れる、runs 200）に第142講の行`bytecode_hash = "ipfs"`、`cbor_metadata = true`、`[profile.ir]`、`[profile.debug]` |
| [code/market/src/Market.sol](code/market/src/Market.sol) | Market 第142講のバージョン（コードは第141講のバージョンと同じ、バージョンを説明するコメント1行） |
| [code/market/src/](code/market/src/) | IMarket・MarketMath・MarketTypes・MockToken |
| [code/market/test/](code/market/test/) | プロジェクトのテスト17ファイル、テスト63個 |
| [code/solc/U.sol](code/solc/U.sol)、[L.sol](code/solc/L.sol) | ライブラリLを呼ぶgと、`require(a > 0, "zero")`があるh。Standard JSONのsettingsの欄を変えてみるファイル |

### 実行結果

第141講のバージョンのrawMetadata（7,936バイト、改行のない文字列一つ）の先頭と末尾。

```
{"compiler":{"version":"0.8.30+commit.73712a01"},"language":"Solidity","output":{"abi":[{"inputs":[{"internalType":"address","name …
… "dweb:/ipfs/QmYFbj7QRK7wC3EWSrZmrpY8svHhnAnmnP8118txPfjc39"]}},"version":1}
```

キーをアルファベット順に、空白なしで書き直すと、バイトまで同じになる。

```python
m = json.loads(raw)
json.dumps(m, sort_keys=True, separators=(",", ":"), ensure_ascii=False) == raw   # True
```

最上位の欄は、compiler（version一つ、ドキュメントの形式の例にあるkeccak256の欄はない）、language、output（abi 36項目、devdoc、userdoc）、settings（六つの欄）、sources（ファイル四つ）、version 1である。output.abiはコンストラクタ → エラー → イベント → 関数の順で、`out/Market.sol/Market.json`のabiはコンストラクタ → 関数 → イベント → エラーの順である（項目は同じ）。Marketのsrcに`///`のコメントがないので、devdoc・userdocは空の形である。

```
"devdoc": {"kind": "dev", "methods": {}, "version": 1}
"userdoc": {"kind": "user", "methods": {}, "version": 1}
```

interestForの上に`/// @notice 元本と利率と経過秒数から利息を計算`の1行を入れたコピーは、ランタイム3,755バイトで前の部分が同じで、末尾のハッシュだけが違い、userdocにその文字がそのまま入る（キーの`Rate`は元の型の`uint256`に）。

```
"userdoc": {"kind": "user", "methods": {"interestFor(uint256,uint256,uint256)":
  {"notice": "元本と利率と経過秒数から利息を計算"}}, "version": 1}
```

メタデータには、bytecode・deployedBytecode、sourceMap、storageLayout、immutableReferences・ast、methodIdentifiers・gasEstimates、コンストラクタの引数の値がない。テスト・forge-stdまで入れたビルドと`src/Market.sol`だけを入れたビルドは、immutableReferencesのキー（ASTのid）が42252・42362・42785 / 256・366・789と違うが、rawMetadataとランタイムは同じである。

settingsの六つの欄（見やすく行を分けた）。

```json
"settings": {
  "compilationTarget": {"src/Market.sol": "Market"},
  "evmVersion": "osaka",
  "libraries": {},
  "metadata": {"bytecodeHash": "ipfs"},
  "optimizer": {"enabled": true, "runs": 200},
  "remappings": [":forge-std/=lib/forge-std/src/"]
}
```

| foundry.toml | メタデータ |
|---|---|
| `solc = "0.8.30"` | compiler.version `0.8.30+commit.73712a01`（settingsの外） |
| `optimizer = true` | optimizer.enabled `true` |
| `optimizer_runs = 200` | optimizer.runs `200` |
| `via_ir = false` | 欄なし |
| `evm_version = "osaka"` | evmVersion `"osaka"` |
| `remappings = ["forge-std/=lib/forge-std/src/"]` | remappings `[":forge-std/=lib/forge-std/src/"]`（先頭にコロン） |
| 書かない（Foundryの既定値） | metadata.bytecodeHash `"ipfs"` |
| 書かない | compilationTarget（コンパイラが足す） |

settingsの欄を一つずつ変えた結果（UはSolc 0.8.30のStandard JSON、optimizerを入れる）。

| 変えたもの | ランタイム | メタデータのsettings |
|---|---|---|
| Market `--extra-output storageLayout evm.assembly ir` | 3,755バイト、全体が同じ | 同じ |
| UのoutputSelectionにstorageLayout・evm.assembly・irを足す | 404バイト、同じ | 同じ |
| U `debug.debugInfo` `["location", "snippet"]` | 404バイト、同じ | 同じ |
| U `debug.revertStrings` `"strip"` | 350バイト | `"debug": {"revertStrings": "strip"}`を足す |
| U `stopAfter` `"parsing"` + バイトコードを要求 | バイトコードなし（`Requested output selection conflicts with "settings.stopAfter".`） | 該当なし |
| U libraries `{"L.sol": {"L": "0x1234…7890"}}` | | `{"L.sol:L": "0x1234…7890"}` |
| Market `FOUNDRY_PROFILE=ir` | 3,260バイト | `"viaIR": true`を足す |
| Market `FOUNDRY_PROFILE=debug` | 7,353バイト | optimizer `{"enabled": false, "runs": 200}` |

Standard JSONに`settings.experimental`を入れると`Unknown key "experimental"`である。sourcesの四つ（第141講のバージョン）。

| ソースユニット名 | バイト | keccak256 | license | urlsのdweb |
|---|---|---|---|---|
| src/IMarket.sol | 4,270 | `0x9870b1f8…a5b2` | GPL-3.0 | `Qmf5jmJL…bJSmeS` |
| src/Market.sol | 17,838 | `0xaacd681f…51e5` | GPL-3.0 | `QmNYKXRW…K4fR1n` |
| src/MarketMath.sol | 2,594 | `0x30add951…ba51` | GPL-3.0 | `Qmby1LuL…9BTAG4` |
| src/MarketTypes.sol | 1,718 | `0xc9fe03f7…7363` | GPL-3.0 | `QmYFbj7Q…Pfjc39` |

keccak256はファイルを`cast keccak`に入れた値と、dwebはファイルの内容から自分で計算したipfsハッシュと、四つとも一致する。MarketTypes.solの末尾に空行を一つ足したコピーは、その欄だけが変わり、ランタイム3,755バイトで前の部分が同じで、末尾のハッシュが`8375ae65…3026`から`ee0c056d…b4da`に変わる。`FOUNDRY_USE_LITERAL_CONTENT=true`は、sourcesの欄にcontentを入れ（urlsなし）、settings.metadataに`"useLiteralContent": true`を足すので、メタデータが45,957バイトになり、末尾のハッシュが変わる。

末尾の四つのバージョン（第141講のバージョンのコピー）。

| 設定 | ランタイム | 末尾2バイト | 末尾 |
|---|---|---|---|
| 基準（`bytecode_hash` ipfs） | 3,755 | `0033` = 51 | `a2 64 69706673 58 22 1220… 64 736f6c63 43 00081e` |
| `FOUNDRY_BYTECODE_HASH=bzzr1` | 3,754 | `0032` = 50 | `a2 65 627a7a7231 58 20 … 64 736f6c63 43 00081e` |
| `FOUNDRY_BYTECODE_HASH=none` | 3,714 | `000a` = 10 | `a1 64 736f6c63 43 00081e` |
| `FOUNDRY_CBOR_METADATA=false` + `FOUNDRY_BYTECODE_HASH=none` | 3,701 | 末尾なし | なし |

最初の三つのバージョンは、末尾2バイトで末尾を切り離すと、先頭の3,702バイトが同じである。CBORだけを切ると次のとおり。

```
$ FOUNDRY_CBOR_METADATA=false forge build --offline --force
Error: Compiler run failed:
Error: When the parameter "appendCBOR" is set to false, the parameter "bytecodeHash" cannot be set to "ipfs". The parameter "bytecodeHash" should either be skipped, or set to "none".
```

メタデータだけでStandard JSON（language、ファイル四つのcontent、メタデータのsettingsからcompilationTargetを除いてoutputSelectionを足したsettings）を作り、solc 0.8.30に入れた結果。

```
$ solc --standard-json < input.json
終了コード0、errorsなし
ランタイム = forgeの成果物のランタイム: True
作成のコード = forgeの成果物の作成のコード: True
metadata = rawMetadata: True
```

anvilにアカウント0番が直接デプロイした第142講のバージョンのMarketの末尾。

```
Market 0x5FbDB2315678afecb367f032d93F642f64180aa3
cast code → 3,755バイト、末尾2バイト 0033 = 51
CBOR a2 64 69706673 58 22 122027c45916…c24f6c 64 736f6c63 43 00081e
ipfsの欄 = QmR1tG5yGizViaVAr3A7eQqbg5G8CR7f3wXhp65kkcPMwZ
solcの欄 00081e = 0.8.30
```

| ファイル | サイズ | ipfsハッシュ | チェーンの末尾と |
|---|---|---|---|
| 保管したrawMetadata（out/Market.sol/Market.json） | 7,936バイト | `QmR1tG5y…kcPMwZ` | 一致 |
| `forge inspect src/Market.sol:Market metadata`の出力 | 14,687バイト | `QmYibFyg…JmTFZu` | 不一致 |
| 同じ内容を2文字ずつ字下げした形 | 14,803バイト | `QmbKE28d…43d2L1` | 不一致 |

デプロイのトランザクションの入力（`cast tx <デプロイのトランザクション> input`）は、4,109バイト = 作成のコード4,013 + コンストラクタの引数96である。

```
  欄0: 000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266   （admin、アカウント0番）
  欄1: 00000000000000000000000000000000000000000000000000b1a2bc2ec50000   （interestRate、5e16）
  欄2: 0000000000000000000000000000000000000000000000000000000000000050   （collateralRatio、80）
```

三つの欄の値は、rawMetadataの中にない。Market 第142講のバージョンのビルドとテスト。

```
$ forge build --offline --force --sizes
| Market      | 3,755            | 4,013             | 20,821             | 45,139              |
$ forge test --offline
Ran 19 test suites …: 63 tests passed, 0 failed, 0 skipped (63 total tests)
$ FOUNDRY_PROFILE=debug forge test --offline
Ran 19 test suites …: 63 tests passed, 0 failed, 0 skipped (63 total tests)
$ FOUNDRY_PROFILE=ir forge test --offline
Ran 19 test suites …: 63 tests passed, 0 failed, 0 skipped (63 total tests)
```

foundry.tomlの第142講の2行を抜いたバージョンも、ランタイム・作成のコード・rawMetadataが同じである（Foundryの既定値と同じ値を書いておいたもの）。

### 試すときの注意

- チェーンには、メタデータのハッシュだけがランタイムの末尾に残る。メタデータのファイルとソースファイルは、誰かが別にアップロードしておかなければ、そのハッシュで見つけられない。
- 末尾のハッシュと一致するメタデータは、コンパイラが出した1行のJSON（rawMetadata）そのものである。`forge inspect … metadata`や`--extra-output-files metadata`のファイルは、改行・字下げがあり、remappingsの先頭のコロンと空のoutputsの欄が抜けるので、ハッシュが一致しない（Foundry 1.8.3）。
- ソースマップとコンストラクタの引数は、メタデータにない。ソースマップはビルドの成果物から、コンストラクタの引数はデプロイのトランザクションの入力の末尾から取り出す。
- コメント1行、空行1行を変えるだけでも、sourcesのkeccak256が変わって末尾のハッシュが変わる。デプロイしたあとにコメントを直したソースは、チェーンのバイトコードと完全には一致しない。
- `debug.debugInfo`、`outputSelection`、`stopAfter`はメタデータのsettingsに入らず、`debug.revertStrings`は入る。librariesの欄は、入力（二重）とメタデータ（`ファイル:名前`の一重）で形が違う。
- 末尾を読むとき、`0xa264`で始まると期待しない。bzzr1は`a265…`、noneは`a164…`で始まる。末尾2バイトの長さで末尾を切り離し、CBORとしてほどく。
- forgeでCBORを切るには、`bytecode_hash`も一緒にnoneに変えてはじめてビルドできる。
- 同じメタデータで作ったStandard JSONを同じバージョンのsolcに入れると、同じバイトコードと同じrawMetadataが出る。バージョンはcompiler.versionの欄から読む。
- ドキュメントの形式の例にあるcompiler.keccak256の欄はsolc 0.8.30の出力になく、experimentalの欄は0.8.30では作れない。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンやソースのコメントが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30+commit.73712a01。第142講のバージョンのdefaultはoptimizerを入れるruns 200、debugは切る、irはvia-IR + 入れる、evm_version osaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| ドキュメントと0.8.30が違う欄 | 形式の例のcompiler.keccak256が0.8.30の出力にない。experimentalの欄は0.8.30では作れない（Standard JSONの`settings.experimental`は`Unknown key "experimental"`） | 2026-10-20 |
| CBORの末尾の長さ（末尾2バイトを含む） | ipfs 53、bzzr1 52、none 12バイト、CBORを切ると0 | 2026-10-20 |
| メタデータのサイズ | Market 第141講・第142講のバージョンのrawMetadata 7,936バイト、use_literal_contentの第141講のバージョン45,957バイト、forge inspect metadataの出力14,687バイト（末尾の改行を含めて14,688）、2文字ずつ字下げした形14,803バイト | 2026-10-20 |
| forgeのメタデータのファイルの形 | `forge inspect … metadata`・`--extra-output-files metadata`: 改行・字下げあり、remappingsの先頭のコロンなし、空のoutputsの欄なし | 2026-10-20 |
| バージョンごとに変わるハッシュ | src/Market.solのkeccak256は第141講のバージョン`0xaacd681f…51e5`、第142講のバージョン`0xed169b90…ae43`。rawMetadataのipfsハッシュは第141講のバージョン`QmXBpCK1CPATfbkbsdQnhz53N1UrzpCD3DrddL7e4zFAgm`、第142講のバージョン`QmR1tG5yGizViaVAr3A7eQqbg5G8CR7f3wXhp65kkcPMwZ`。バージョンを説明するコメントが変わると変わる | 2026-10-20 |
| 検証サービス | Sourcify（"full/perfect verification"、ドキュメントv0.8.36の時点） | 2026-10-20 |
| デプロイのアドレス | 新しいanvilでアカウント0番が直接デプロイしたMarket `0x5FbDB2315678afecb367f032d93F642f64180aa3` | 2026-10-20 |
| 通しプロジェクトのガス | 第141講・第142講のバージョンで同じ値: デプロイ867,827、addAsset 75 92,576、deposit 100 128,297、withdraw 30 57,856、setStatus 1 45,224、setStatus 0 23,312、失敗するdeposit 0 26,409 | 2026-10-20 |
| サイズ | 第141講・第142講のバージョンのdefault 3,755 / 4,013、debug 7,353 / 7,931、ir 3,260 / 3,473 | 2026-10-20 |
| 行番号 | 第142講のバージョンのdeposit 0はsrc/Market.sol 152:33、NotActiveの行は70。バージョンを説明するコメントが変わると変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 検証サービスにメタデータとソースを出す手順 | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| デプロイされたほかの人のコントラクトからメタデータを探してソースを読む | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| NatSpecのタグの全体と継承 | [第146講](../../part9/lecture146/)、[第147講](../../part9/lecture147/) |
| ソースの公開とライセンス | [第153講](../../part9/lecture153/) |
| プロキシのうしろの実装コントラクトの検証 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| バージョンごとに変わるメタデータの欄 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
