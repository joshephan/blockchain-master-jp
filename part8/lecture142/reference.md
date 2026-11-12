# 第142講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01 | `solc --version`、rawMetadataのcompilerの欄 | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| EVMのバージョン | osaka | foundry.toml、メタデータのsettings | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| rawMetadataの欄・並び・サイズ | `out/Market.sol/Market.json`のrawMetadataをPythonの`json`で読んで書き直す | 2026-10-20 |
| sourcesのハッシュ | `cast keccak`、ファイルの内容から自分で計算したipfsハッシュ | 2026-10-20 |
| 設定ごとの末尾・サイズ | バージョンのコピーに`FOUNDRY_BYTECODE_HASH`、`FOUNDRY_CBOR_METADATA`、`FOUNDRY_USE_LITERAL_CONTENT`、`FOUNDRY_PROFILE`を与えて`forge build` | 2026-10-20 |
| settingsの欄ごとの効果 | U.sol・L.solをsolc 0.8.30 `--standard-json`に入れ、欄を一つずつ変える | 2026-10-20 |
| メタデータからの再ビルド | メタデータから作ったStandard JSONをsolc 0.8.30 `--standard-json`に入れ、forgeの成果物と比較 | 2026-10-20 |
| チェーンの末尾・コンストラクタの引数 | anvilに`forge create`でデプロイしてから`cast code`、`cast tx … input`、`forge inspect src/Market.sol:Market metadata` | 2026-10-20 |
| サイズ・テスト・ガス | `forge build --sizes`、`forge test`（default・debug・ir）、新しいanvilにデプロイして順に送ったレシートのgasUsed | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Contract Metadata（`docs/metadata.rst`、引用した行9〜14、16〜19、23〜30、32〜36、128〜131、147〜148、157〜172、187〜190、205〜216、220〜222、230〜232、234〜238、243〜254、261〜275）: https://docs.soliditylang.org/en/v0.8.36/metadata.html
- 同じドキュメントのソース: https://github.com/argotorg/solidity/blob/v0.8.36/docs/metadata.rst
- Sourcify（ドキュメントが"full/perfect verification"に使うと書いている検証サービス）
- Foundry公式ドキュメント（`bytecode_hash`、`cbor_metadata`、`use_literal_content`、`forge inspect`）: https://getfoundry.sh/
