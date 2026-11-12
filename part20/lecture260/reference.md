# 第260講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml`、`solc --version` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts`、ビルドのメタデータのsources | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std` | 2026-10-21 |

付録の範囲表、lintの警告、テスト結果、跡、カバレッジは、すべて上の環境で直接実行した結果である。anvilは使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 監査したビルドのサイズ・ハッシュ・セレクタ・イベント・エラーの数 | 直接実行（ビルド成果物のバイトコードとrawMetadata） | 2026-10-21 |
| 範囲表のファイルとkeccak256 | 直接実行（rawMetadataのsources） | 2026-10-21 |
| コンパイラのバグ一覧 | Solidityリポジトリ`docs/bugs.json`（リポジトリのコピー コミット8a079791、2026-07-09）をバージョン0.8.30で絞り込んだ | 2026-07-09 |
| 関数の輪 | 直接実行（`solc --combined-json ast`の出力から関数・呼び出しの辺を数えた） | 2026-10-21 |
| forge lint | 直接実行（`forge lint --offline src`） | 2026-10-21 |
| カバレッジ | 直接実行（`forge coverage --offline --ir-minimum --report summary`） | 2026-10-21 |
| 広げたコピーの結果 | 直接実行（`forge test --offline --match-contract InvariantTest`、`-vvvv`） | 2026-10-21 |
| テストの合計 | 直接実行（`bash ci.sh`） | 2026-10-21 |

## 参考資料

- Solidityリポジトリ`docs/bugs.json`（コミット8a079791、63項目・バージョン120）：バージョンごとの既知のコンパイラのバグの名前と条件。この講義で当てた0.8.30のバグ四つは、SOL-2026-3 InheritanceOrderReversalOnStorageEndWarning、SOL-2026-2 UnsoundSpillInMutualRecursion、SOL-2026-1 TransientStorageClearingHelperCollision、SOL-2025-1 LostStorageArrayWriteOnSlotOverflow
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （メタデータのsources、Changelog）
- OpenZeppelin Contracts 5.4.0：`token/ERC20/utils/SafeERC20.sol`、`token/ERC20/IERC20.sol`、`token/ERC20/extensions/IERC20Metadata.sol`、`interfaces/IERC1363.sol`、`interfaces/IERC20.sol`、`interfaces/IERC165.sol`、`utils/introspection/IERC165.sol`
- Foundry公式ドキュメント: https://getfoundry.sh/ （`forge lint`、`forge coverage`、不変条件テスト、`vm.skip`）
