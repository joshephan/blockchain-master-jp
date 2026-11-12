# 第23講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil・chisel） | 1.8.3 (cae51ad458f6abb64852b7709eb784352429825d) | 各コマンドの`--version` | 2026-10-18 |
| forge-std | v1.17.0 (f3dae6e6ee381f25eb6a246f7da9b85c91a68219) | `forge init`の出力、`foundry.lock` | 2026-10-18 |
| solc | 0.8.30 | `forge build`の出力 | 2026-10-18 |
| ローカルチェーン | anvil、チェーン番号31337 | `cast chain-id` | 2026-10-18 |

付録の出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Foundryのバージョン | 各コマンドの`--version` | 2026-10-18 |
| Foundryのインストールコマンド、最新の安定版 | Foundry公式ドキュメントのインストール案内（getfoundry.sh/introduction/installation）、foundry-rs/foundryのリリース一覧 | 2026-10-20 |
| forge-stdのタグ | `forge init`の出力、`foundry.lock` | 2026-10-18 |
| lib/forge-stdフォルダのサイズ | `du -sh` | 2026-10-18 |
| forgeが選んだsolc、最初のビルドのファイル数、コンパイル時間 | `forge build`の出力 | 2026-10-18 |
| cacheに記録されたデフォルト設定 | `cache/solidity-files-cache.json` | 2026-10-18 |
| initのCounterのランタイムコードのサイズ | `out/Counter.sol/Counter.json`の`deployedBytecode` | 2026-10-18 |
| anvilのデフォルトのチェーン番号 | `cast chain-id` | 2026-10-18 |
| Hardhatのテスト言語 | Hardhat公式ドキュメントのTesting案内（hardhat.org/docs/guides/testing） | 2026-10-20 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Foundryのインストールスクリプト: https://getfoundry.sh/install
- forge-stdリポジトリ: https://github.com/foundry-rs/forge-std
- foundry.tomlの設定項目全体: https://github.com/foundry-rs/foundry/blob/master/crates/config/README.md#all-options
- Hardhat公式ドキュメント（Hardhat 3.20.0）
