# 第25講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-18 |
| solc | 0.8.30（最適化オフ） | `forge build`の出力 | 2026-10-18 |
| forge-std | v1.17.0 (f3dae6e6ee381f25eb6a246f7da9b85c91a68219) | `forge init`の出力、foundry.lock | 2026-10-18 |
| OpenZeppelin Contracts（forge install） | v5.4.0 (c64a1edb67b6e3f4a15cca8909c9482ad33a02b0) | `forge install`の出力、foundry.lock | 2026-10-18 |
| @openzeppelin/contracts（npm） | 5.6.1 | package-lock.json | 2026-10-18 |

付録のサイズ、行数、ハッシュは、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Foundryのバージョン | `forge --version` | 2026-10-18 |
| forge-std、OpenZeppelinのタグとコミット | `forge init`・`forge install`の出力、foundry.lock | 2026-10-18 |
| npmのバージョン | package.json、package-lock.json | 2026-10-18 |
| OpenZeppelin v5.4.0の中のサブモジュール | OpenZeppelinリポジトリの.gitmodules、`git submodule status`、package.json | 2026-10-18 |
| ダウンロードした容量 | `du -sh` | 2026-10-18 |
| サイズの比較 | `forge build --sizes` | 2026-10-18 |
| flattenの行数 | `forge flatten`、`wc -l` | 2026-10-18 |
| メタデータハッシュ | `forge inspect MyToken bytecode --offline --force` | 2026-10-18 |

## 参考資料

- OpenZeppelin Contractsリポジトリ: https://github.com/OpenZeppelin/openzeppelin-contracts
- OpenZeppelin Contracts v5.4.0: https://github.com/OpenZeppelin/openzeppelin-contracts/tree/v5.4.0
- npmパッケージ@openzeppelin/contracts 5.6.1: https://registry.npmjs.org/@openzeppelin/contracts/-/contracts-5.6.1.tgz
- forge-stdリポジトリ: https://github.com/foundry-rs/forge-std
- OpenZeppelinの中のサブモジュール: https://github.com/a16z/erc4626-tests.git, https://github.com/a16z/halmos-cheatcodes
- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
