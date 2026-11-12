# 第176講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | `guards/foundry.toml`、`market/foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json`のversion | 2026-10-21 |

付録のガスの数字、トレース、lintの出力は、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| テストのガス、テストの中のアドレス | 直接実行（`forge test -vvv`、`-vvvv`のトレース） | 2026-10-21 |
| Marketのlintの警告 | 直接実行（`forge lint --offline src`） | 2026-10-21 |
| 損失が最も大きいセキュリティの領域 | この講座の設計原則（セキュリティパートの時間配分は知名度ではなく実際の損失額が基準、鍵の管理とブリッジが損失額の最も大きい領域） | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Security Considerationsのtx.originの節（`security-considerations.rst` 243行 "Never use tx.origin for authorization."、288〜291行）: https://docs.soliditylang.org/en/v0.8.36/security-considerations.html
- OpenZeppelin Contracts 5.4.0 `access/AccessControl.sol`（63〜66行 onlyRole、85行、92〜94行 _checkRole）、`access/IAccessControl.sol`（13行 AccessControlUnauthorizedAccount）
- OpenZeppelin Contracts 5.4.0 `access/Ownable2Step.sol`（43〜46行 transferOwnership、60〜66行 acceptOwnership）
- Foundryのlintルール missing-zero-check: https://getfoundry.sh/forge/linting/missing-zero-check
- Foundry公式ドキュメント: https://getfoundry.sh/
