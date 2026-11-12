# 第130講 コンパイルの再現性とソースの検証

第8部 コンパイラと内部構造・第30章 コンパイラの使い方

[← 第129講](../../part8/lecture129/) | [第8部 目次](../) | [第131講 →](../../part8/lecture131/)

## この講義の問い

同じ入力から同じバイトコードがもう一度出るかをどう確かめ、一つが違えばどこで分かれ、作り直したコードをチェーンのコードと突き合わせて一致したとき、何がわかって何は別に見なければならないのか。

## 実習資料

### 準備

solc 0.8.30の実行ファイルを直接呼び、Store.solを1か所ずつ変えながらビルドしてkeccakを比べた（コマンドは`c130`フォルダの中でファイル名だけを渡す）。Marketは、第128講で`forge verify-contract --show-standard-json-input`で取り出した入力をsolcに入れ直してビルドし、ローカルのanvilを新しく立ち上げてアカウント0番がコンストラクタの引数だけを変えて2組デプロイしてから、`cast code`・`cast tx`でチェーンのコードと突き合わせた。第129講のA.solの二つのバージョンとStoreも同じチェーンにデプロイした。`market`は通しプロジェクトMarketの第130講のバージョンで、forge-stdが必要である。

### コード

| ファイル | 内容 |
|---|---|
| [code/c130/Store.sol](code/c130/Store.sol) | 基準のStore |
| [code/c130/Space.sol](code/c130/Space.sol) | `return v;`の行末に空白一つ |
| [code/c130/sp/Store.sol](code/c130/sp/Store.sol) | Space.solと同じ内容をStore.solという名前で（ファイル名までそろえた比較用） |
| [code/c130/Comment.sol](code/c130/Comment.sol) | コメントを1行追加 |
| [code/c130/sol/Store.sol](code/c130/sol/Store.sol) | 基準と同じ内容。`sol/Store.sol`のパスで渡した比較用 |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第130講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第130講のバージョン。第129講のバージョンとコードが同じで、バージョンを説明するコメントを1行だけ足した |
| [code/market/test/](code/market/test/) | Marketのテスト55個 |

### 実行結果

同じ入力を2回入れると、同じバイトコードが出る（Marketのruntimeのkeccak 0xa87eacec6e3758bfacbe9e8c69e519425544acba046f0e2b7fe5d7d93d76dc2aが2回）。

Storeを一つずつ変えたデプロイのコード（`solc --bin`）。

| 変えたもの | サイズ | keccak | 末尾の53バイトを除いた前の部分 |
|---|---|---|---|
| 基準 | 401 | 0x42853029…599d | |
| 行末の空白一つ | 401 | 0x74105e6b… | 同じ |
| コメント1行 | 401 | 0x2c5821de… | 同じ |
| 渡したパス`sol/Store.sol` | 401 | 0xd968dd7d… | 同じ |
| 使わないremapping `x/=y/` | 401 | 0xc1405bb1… | 同じ |
| `--evm-version osaka` | 401 | 0x4d0d52b8… | 同じ |
| `--evm-version cancun` | 401 | 0x54a21b74… | 同じ |
| `--optimize` | 213 | 0xafd4ae3e… | |
| `--via-ir` | 805 | 0xa65f6e31… | |
| `--metadata-hash none` | 360 | 0x3645a7f3… | |
| `--no-cbor-metadata` | 347 | 0xdf3a0b97… | |

`--metadata-hash none`か`--no-cbor-metadata`でビルドすると、空白一つのバージョンと基準のバージョンが完全に同じになる。

メタデータのハッシュを自分で計算すると、バイトコードの末尾のハッシュと一致する。

```
metadata JSON 1072バイト、ipfsハッシュ（自分で計算） 12203ab396b3c5e361ed97181003673109c0e57f7b8fa61beb317cec5d48c7e6d87d = QmSHoBh69ifWLarMEpz8UwjYxyDrKoDKNyn3B7mt4tSUTN
Storeのランタイムの末尾のハッシュ 3ab396b3c5e361ed97181003673109c0e57f7b8fa61beb317cec5d48c7e6d87d 一致=True
metadataの最上位の欄 compiler, language, output, settings, sources, version
cast keccak Store.solのファイルの内容 = 0x46ba502c1fac9b599150e78e24d4896494a6d713366c30859b943d02077393a2
```

最後の行の値は、メタデータの`sources["Store.sol"].keccak256`と同じである。

Marketの2組（Market 1: adminはアカウント0番、rate 5e16、ratio 80 / Market 2: adminはアカウント1番、rate 3e16、ratio 70）をデプロイして突き合わせた結果。

```
成果物のdeployedBytecode 7353バイト vs Market 1のcast code 7353バイト: 違う区間 [(2405, 1), (2452, 1), (2870, 5), (2954, 1), (3501, 20), (3672, 20)]
Market 1 vs Market 2のcast code: 違う区間 [(2405, 1), (2452, 1), (2870, 5), (2954, 1), (3501, 20), (3672, 20)]
immutableの区間を0で埋めると Market 1 = 成果物: True, Market 2 = 成果物: True
  Market 1の3489番目のバイトから32バイト = 0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
  Market 1の2374番目のバイトから32バイト = 0x0000000000000000000000000000000000000000000000000000000000000050
  Market 1の2845番目のバイトから32バイト = 0x00000000000000000000000000000000000000000000000000b1a2bc2ec50000
Market 1の作成トランザクションのinput 8027バイト = 成果物のbytecode 7931バイト + うしろの96バイト、前の部分の一致=True
Market 1のcast codeの末尾の53バイト a26469706673582212200bb08b53c21f87551938790c4f7234f9b63c9ed582f4fe134659dec4df23f94864736f6c634300081e0033
```

immutableの六つの区間（admin、interestRate、collateralRatio）だけが違い、作成トランザクションのinputのうしろの96バイトがコンストラクタの引数である。第128・129・130講のバージョンの成果物とMarket 1を比べると、0から数えて7,310番目のバイトから32バイト（メタデータハッシュ）だけが違う。

同じチェーンにデプロイしたStoreの`cast code` 369バイトは、`solc --bin-runtime Store.sol`と同じである。行末の空白一つのバージョンは、先頭の316バイトが同じで、326番目のバイトから違う。

Market 第130講のバージョンはruntime 7,353 / creation 7,931、`forge test`の55個が通り、linkReferences `{}`、`grep -n assembly src/*.sol`は0行である。第128〜130講のバージョンはどれも、`--show-standard-json-input`で取り出した入力をsolcに入れると、forgeの成果物とruntime・creationが同じになる。

### 試すときの注意

- 空白一つ、コメント1行、渡したパス、使わないremapping、evm_versionは、コードの部分はそのままにして、末尾のメタデータハッシュだけを変える。ハッシュまで一致すればソースファイルまで同じということで、前の部分だけが一致すればコードが同じということである。
- デプロイされたコードと比べるときは、immutableの区間を0で埋めて突き合わせる。位置は成果物の`immutableReferences`にある。
- コンストラクタの引数はランタイムコードになく、作成トランザクションのinputの末尾についている（`cast tx <ハッシュ> input`）。
- チェーン上のコードとソースを突き合わせる外部サービス（Sourcify、Etherscanなど）も、同じ原理で比べる。サービスごとの呼び名とAPIは変わることがある。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンや外部サービスが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメントのバージョン | Contract Metadata（Encoding of the Metadata Hash in the Bytecode、Usage for Source Code Verification）、Using the Compiler（Library Linking、Metadata Options）、Installing the Solidity Compiler（Static Binaries）はv0.8.36タグ | 2026-10-20 |
| solc | 0.8.30+commit.73712a01（直接呼ぶとevm_versionはprague）、0.7.6（第127講のPowの結果を引用し直したもので、実行し直してはいない） | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3、forgeのビルドのevm_versionはosaka | 2026-10-20 |
| forgeの検証のコマンド | `forge verify-contract`の1行目"Verify smart contracts on Etherscan and Sourcify"、`--verifier`の値はetherscan・sourcify・blockscout・oklink・custom、`--show-standard-json-input`、`--constructor-args`（"Only for Etherscan"）、`--guess-constructor-args`、`forge verify-bytecode`の1行目"Verify the deployed bytecode against its source on Etherscan" | 2026-10-20 |
| 外部の検証サービス | Sourcify: "Exact Match"（以前のperfect match） / "Match"（以前のpartial match）、Server API v2（v1は段階的に終了）・Etherscan: 検証済みのコントラクトの画面の表記"Source Code Verified (Exact Match)"、API V2（`api.etherscan.io/v2/api?chainid=1`） | 2026-10-20 |
| Storeの11行 | 基準401バイト 0x42853029…599d / 空白0x74105e6b… / コメント0x2c5821de… / `sol/Store.sol` 0xd968dd7d… / `x/=y/` 0xc1405bb1… / osaka 0x4d0d52b8… / cancun 0x54a21b74…（6行は401バイト、前の部分は同じ） / `--optimize` 213 0xafd4ae3e… / `--via-ir` 805 0xa65f6e31… / `--metadata-hash none` 360 0x3645a7f3… / `--no-cbor-metadata` 347 0xdf3a0b97… | 2026-10-20 |
| メタデータのハッシュ | Storeのメタデータ1,072バイト、ipfs `12203ab396b3…d87d` = `QmSHoBh69ifWLarMEpz8UwjYxyDrKoDKNyn3B7mt4tSUTN`、sourcesのkeccak256 0x46ba502c…93a2 = Store.sol 245バイトのkeccak | 2026-10-20 |
| Marketの入力を2回 | 第128講のバージョンのStandard JSONの入力のruntimeのkeccak 0x966122b4a45ed886fb56c8f22e101867a8e51241d9a3daf8318944a97bde039dが2回とも同じ | 2026-10-20 |
| anvilでのデプロイ | 新しいanvil、アカウント0番がデプロイした順に: Market 1 0x5FbD…0aa3（adminはアカウント0番、5e16、80）、Market 2 0xe7f1…0512（adminはアカウント1番、3e16、70）、A(m1) 0x9fE4…a6e0、A(m2) 0xCf7E…0Fc9、Store 0xDc64…C6C9（ブロック5） / 第130講のバージョンだけを別にデプロイしたときのMarket 0x5FbD…0aa3 | 2026-10-20 |
| Marketの突き合わせ | runtime 7,353 / creation 7,931、immutableReferences `{"42252": [3489, 3660], "42362": [2374, 2421, 2923], "42785": [2845]}`（それぞれ32バイト）、違う区間 (2405, 1) (2452, 1) (2870, 5) (2954, 1) (3501, 20) (3672, 20)、input 8,027 = 7,931 + 96、Market 1の末尾の53バイト`a2646970667358221220 0bb08b53…f948 64736f6c63 4300081e 0033`、第128〜130講のバージョンとは0から数えて7,310番目のバイトから32バイトが違う、第130講のバージョンの末尾のハッシュd31ef40a…6929 | 2026-10-20 |
| Market 第130講のバージョン | テスト55個、linkReferences {}、`grep -n assembly src/*.sol` 0行、initcodeの余裕41,221 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| バイトコードの構造（コードの部分と末尾を分ける方法） | [第131講](../../part8/lecture131/) |
| ソースマップ | [第132講](../../part8/lecture132/) |
| 二つのコード生成の経路を切り替えるときの記録 | [第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| immutableとスロットの配置 | [第135講](../../part8/lecture135/) |
| optimizerの結果の検証 | [第140講](../../part8/lecture140/) |
| メタデータの欄の一つひとつ（output、sourcesのurls、settings） | [第142講](../../part8/lecture142/) |
| ドキュメントコメントとメタデータ | [第146講](../../part9/lecture146/)、[第147講](../../part9/lecture147/) |
| 検証されたソースと標準の実装の再利用 | [第153講](../../part9/lecture153/)〜[第159講](../../part10/lecture159/) |
| 一つのアドレスでコードを入れ替える構造 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| ツールチェーンの事件 | [第181講](../../part11/lecture181/) |
| コンパイラのバグの一覧とバージョンの変更履歴 | [第184講](../../part11/lecture184/)、[第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 監査でデプロイ物とソースを確定する | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
