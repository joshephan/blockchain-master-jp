# 第261講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts` | 2026-10-21 |

付録のテスト結果、ガス、lint、サイズとハッシュは、すべて上の環境で直接実行した結果である。anvilは使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 二つのビルドのサイズ・ハッシュ・セレクタ・イベント・エラー・STATICCALLの数 | 直接実行（ビルド成果物のバイトコードとrawMetadata） | 2026-10-21 |
| インターフェースID | 直接実行（InterfaceTestの通過） | 2026-10-21 |
| ZeroPriceのセレクタ | 直接実行（`cast sig "ZeroPrice(address)"`） | 2026-10-21 |
| 測った呼び出し | 直接実行（二つのバージョンで`forge test --offline --match-contract GasTest -vv`） | 2026-10-21 |
| forge lint | 直接実行（`forge lint --offline src`） | 2026-10-21 |
| 不変条件の表、テストの合計 | 直接実行（`bash ci.sh`、直した直後の状態と確認の行を消したコピーで`forge test --offline`） | 2026-10-21 |
| 直したビルドの行のsha256・keccak256 | 直接実行（ファイルのsha256とrawMetadataのsourcesを計算し直した） | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/ （`forge test`、`forge lint`、`forge build --sizes`、`cast sig`、`vm.expectRevert`、不変条件テスト）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （ユーザー定義エラーとセレクタ、`Panic(uint256)`コード0x12 0除算）
- OpenZeppelin Contracts 5.4.0 `SafeERC20`（`SafeERC20FailedOperation`エラー、`@dev`だけがある）
