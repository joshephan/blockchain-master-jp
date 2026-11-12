# 第177講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | `guards/foundry.toml`、`market/foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts` | 2026-10-21 |

付録のガスの数字、サイズ、トレースは、すべて上の環境で直接実行した結果である。anvilは使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Init177Testのガス、デプロイのガスとサイズ | 直接実行（`forge test --offline --match-contract Init177Test -vvvv`） | 2026-10-21 |
| NoInitTestのガス | 直接実行（`forge test --offline --match-contract "NoInitTest\|UpgradeTest" -vvv`） | 2026-10-21 |
| Marketのサイズ | 直接実行（`forge build --offline --sizes`） | 2026-10-21 |
| Marketのテストの数 | 直接実行（`forge test --offline`） | 2026-10-21 |
| selfdestructのルール | Solidityのドキュメント v0.8.36 `introduction-to-smart-contracts.rst` 599〜601行、EIP-6780 | 2026-10-21 |
| Parityのマルチシグの年 | 事件の名前・年 | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0 `proxy/utils/Initializable.sol`（39〜45行 CAUTION "Avoid leaving a contract uninitialized."、49〜52行 コンストラクタの例、82行 `InvalidInitialization`、104行 `initializer`、192行 `_disableInitializers`）
- OpenZeppelin Contracts 5.4.0 `proxy/ERC1967/ERC1967Proxy.sol`（19〜20行 生成データの説明、26行 コンストラクタ）
- OpenZeppelin Contracts 5.4.0 `proxy/utils/UUPSUpgradeable.sol`（122行 例、125行 `_authorizeUpgrade`の宣言）
- Solidity公式ドキュメント v0.8.36、Introduction to Smart Contractsのselfdestructの節（`introduction-to-smart-contracts.rst` 599〜601行）: https://docs.soliditylang.org/en/v0.8.36/introduction-to-smart-contracts.html
- EIP-6780 SELFDESTRUCT only in same transaction: https://eips.ethereum.org/EIPS/eip-6780
- Parityのマルチシグ事件（2017）：複数のウォレットが頼っていたライブラリコントラクトが、初期化されないまま残っていた事件。この講義は名前・年・一行の性格だけを扱う
