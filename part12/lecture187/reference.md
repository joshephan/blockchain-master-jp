# 第187講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30+commit.73712a01 | foundry.tomlの`solc = "0.8.30"`、rawMetadataの`compiler` | 2026-10-21 |
| solcの実行ファイルのハッシュ | `ccbd3ed4...` | svmが取得したsolc-0.8.30に`sha256sum` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

付録の行数、セレクタ、バイトコードのサイズとハッシュ、デプロイのトランザクションの値は、すべて上の環境で直接実行した結果である（ローカルのanvil、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Foundry・solcのバージョン、実行ファイルのハッシュ | `forge --version`、`sha256sum`、rawMetadataのcompiler | 2026-10-21 |
| ビルドの設定 | `foundry.toml`、rawMetadataのsettings | 2026-10-21 |
| 0.8.30の既知のバグの数 | solcリポジトリv0.8.36の`docs/bugs_by_version.json` | 2026-10-21 |
| Marketのランタイムのサイズ・メタデータのハッシュ・生成コードのサイズ | `cast code`、`forge inspect deployedBytecode`・`bytecode`（直接実行） | 2026-10-21 |
| 前のバージョンのサイズ・ハッシュ | 前のバージョンのMarketで`forge inspect deployedBytecode`（直接実行） | 2026-10-21 |
| immutableの欄 | 成果物の`immutableReferences` | 2026-10-21 |
| テストの数 | `forge test --offline`（直接実行） | 2026-10-21 |
| 監査報告書の公開場所の例 | Trail of Bits、OpenZeppelinの各社の公開ページ | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidityの既知のバグ一覧`docs/bugs_by_version.json`（v0.8.36）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/bugs_by_version.json
- EIP-20トークン標準（Marketが上場するトークンの前提）: https://eips.ethereum.org/EIPS/eip-20
- 監査報告書を公開している場所の例：Trail of Bits（公開リポジトリpublications）、OpenZeppelin（監査記事）
