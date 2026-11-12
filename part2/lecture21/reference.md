# 第21講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `forge --version` | 2026-10-17 |
| solc | 0.8.30+commit.73712a01 | `forge inspect Counter metadata` | 2026-10-17 |
| Foundryのデフォルト設定 | `via_ir = false`、`optimizer = false`、`optimizer_runs = 200`、`evm_version = "osaka"` | `forge config` | 2026-10-17 |

付録のバイトコード、サイズ、ガスは、すべて上記の環境で直接実行した結果である。ガスはanvilにデプロイしたトランザクションのレシートの値である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 基本のコンパイルパイプライン | Solidity v0.8.37の文書using-the-compiler.rst、`forge config` | 2026-10-20 |
| Foundryのデフォルトの最適化設定、EVMバージョン | `forge config` | 2026-10-17 |
| コードサイズ | `forge inspect`を直接実行 | 2026-10-17 |
| デプロイガス、increment()のガス | anvilにデプロイしたあとの`cast send`のレシート | 2026-10-17 |
| 既知のバグ一覧のうち最適化関連の項目数 | argotorg/solidityリポジトリのdevelopブランチ`docs/bugs.json` | 2026-10-20 |
| メタデータの尻尾の形式 | Solidity公式ドキュメント"Contract Metadata" | 2026-10-17 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidity公式ドキュメント"List of Known Bugs"（バージョンごとの既知のバグ一覧）
- Solidity公式ドキュメント"Contract Metadata"
- Solidityのソースリポジトリ: https://github.com/argotorg/solidity
- Vyperコンパイラのバグとカーブ（Curve）のプールの事件（2023年7月30日）
- Foundry公式ドキュメント: https://getfoundry.sh/
