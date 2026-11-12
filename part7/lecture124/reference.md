# 第124講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version` | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| evm_versionの既定値 | solc 0.8.30はprague、forge 1.8.3はosaka | `solc --help`、メタデータの`"evmVersion"` | 2026-10-19 |
| optimizer runs | 200 | `solc --metadata`のsettings | 2026-10-19 |

付録のバイトコード・サイズ・ガス・IRの行数は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Store124.yul、オブジェクトのないブロック | anvilに`cast send --create`でデプロイした直接実行の出力 | 2026-10-19 |
| IRの行数 | `solc --ir`・`--ir-optimized`、`forge inspect ir`の出力を`wc -l`、`grep -c "function "`で数える | 2026-10-19 |
| サイズ | `solc --bin-runtime`・`--bin`、`forge build --sizes` | 2026-10-19 |
| CREATE2 | `cast keccak`、`cast create2` | 2026-10-19 |
| prague / osaka、Marketの末尾 | `solc --evm-version osaka`、`forge inspect deployedBytecode`・`bytecode`、`cast keccak` | 2026-10-19 |
| メタデータの末尾の長さ | 公式ドキュメント v0.8.36 Contract Metadata、実際の出力 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Yulの節のSpecification of Yul Object
  - `Object = 'object' StringLiteral '{' Code ( Object | Data )* '}'`、`Code = 'code' Block`、`Data = 'data' StringLiteral ( HexLiteral | StringLiteral )`
  - 今のオブジェクトと、その中のオブジェクトとdataの項目だけを呼べる。EVMでは`datacopy`は`codecopy`と同じ。名前が`_deployed`で終わるオブジェクトは、Yulのオプティマイザがランタイムコードとして扱う
- Solidity公式ドキュメント v0.8.36、The Optimizerの節
  - いくつものステップが同じ意味を保ったままASTを変える。略号の例: i FullInliner、F FunctionSpecializer、u UnusedPruner、s ExpressionSimplifier、e ExpressionInliner。optimizerを切ってもUnusedPrunerは動く
- Solidity公式ドキュメント v0.8.36、Contract Metadataの節
  - バイトコードの最後の2バイトがCBORの情報の長さ、バージョンは3バイト（major、minor、patch）
- Foundry公式ドキュメント: https://getfoundry.sh/
