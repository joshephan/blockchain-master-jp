# 第189講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

付録のテスト結果とガスは、すべて上の環境で直接実行した結果である（anvilなし、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Foundry・solcのバージョン、ビルド設定 | `forge --version`、`foundry.toml` | 2026-10-21 |
| 再現テストのガス、collateralCountのガス | 監査対象のバージョンで`forge test --match-contract Audit50Test -vv`（直接実行） | 2026-10-21 |
| 直す前のバージョンのテストのガス | 直す前のバージョンの写しで`forge test --match-test test_M01`（直接実行） | 2026-10-21 |
| 前の章のテストのガス | 前の章のバージョンの写しの`test_depositWithdrawOneToOne`、監査対象のバージョンの`KeysTest`（直接実行） | 2026-10-21 |
| 等級の名前と段階の数 | この講義の基準（特定の会社の等級定義の文言は載せない） | 2026-10-21 |
| コンストラクタの引数 | 監査の範囲の表のローカルanvilでのデプロイの値 | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- EIP-20トークン標準（信頼の前提のトークンの行）: https://eips.ethereum.org/EIPS/eip-20
