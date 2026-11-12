# 第188講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

付録のセレクタ、ストレージの配置、grepの数、テスト結果とガスは、すべて上の環境で直接実行した結果である（anvilなし、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Foundry・solcのバージョン、ビルド設定 | `forge --version`、`foundry.toml` | 2026-10-21 |
| 0.8.30の既知のバグの数 | solcリポジトリv0.8.36の`docs/bugs_by_version.json` | 2026-10-21 |
| テストの数、Audit50のガス、collateralCountのガス | `forge test --offline`（直接実行） | 2026-10-21 |
| 直す前のバージョンのM01のガス | 直す前のバージョンの写しで`forge test --match-test test_M01`（直接実行） | 2026-10-21 |
| カバレッジ | `forge coverage`で測った直す前のバージョンの値（テスト97個のとき） | 2026-10-21 |
| 公開された弱点分類の一覧 | SWCなどの公開された一覧 | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidityの既知のバグ一覧`docs/bugs_by_version.json`（v0.8.36）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/bugs_by_version.json
- SolidityのChangelog（solcリポジトリ、バージョンごとに変わった行）
- EIP-20トークン標準: https://eips.ethereum.org/EIPS/eip-20
- 公開された弱点分類の一覧：SWC（Smart Contract Weakness Classification）など。名前だけを書く
