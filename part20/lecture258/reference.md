# 第258講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts` | 2026-10-21 |

付録のテスト結果、ガス、カバレッジ、ハッシュは、すべて上の環境で直接実行した結果である。anvilは使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 二つのバージョンのサイズ・ハッシュ・セレクタ・イベント・エラーの数 | 直接実行（ビルド成果物のバイトコードとrawMetadataを読んだ） | 2026-10-21 |
| テストの合計 | 直接実行（`bash ci.sh`を3回、3回とも`ci ok`） | 2026-10-21 |
| カバレッジ | 直接実行（`forge coverage --offline --ir-minimum --report summary --report lcov`） | 2026-10-21 |
| 測った呼び出し五つ | 直接実行（`forge test --offline --match-contract GasTest -vv`） | 2026-10-21 |
| ABIファイル・インターフェースID | 直接実行（`forge inspect --offline src/IMarket.sol:IMarket abi --json`、InterfaceTest） | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/ （`forge test`、`forge coverage --ir-minimum`、`forge inspect`、cheatcode `vm.expectEmit`・`vm.recordLogs`・`vm.getRecordedLogs`・`vm.warp`・`vm.parseJsonKeys`）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （NatSpec `@notice`・`@dev`・`@inheritdoc`、メタデータハッシュ）
- forge-std 1.17.0
- OpenZeppelin Contracts 5.4.0 `SafeERC20`（`SafeERC20FailedOperation`エラー）
