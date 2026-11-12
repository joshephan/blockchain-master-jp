# 第259講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| ファズ・不変条件の設定 | `[fuzz] runs 256 seed "0x103"`、`[invariant] runs 128 depth 200 fail_on_revert false show_metrics true` | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts` | 2026-10-21 |

付録のテスト結果、縮めた手順、跡、不変条件の表は、すべて上の環境で直接実行した結果である。最初のハンドラーの実行だけ、環境変数`FOUNDRY_INVARIANT_RUNS=64`、`FOUNDRY_INVARIANT_DEPTH=100`を与えた。anvilは使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 不変条件のバージョンのテストの合計・サイズ・ハッシュ | 直接実行（`bash ci.sh`を3回、ビルド成果物） | 2026-10-21 |
| 最初のハンドラーの表 | 直接実行（最初のハンドラーのコピー、64 × 100） | 2026-10-21 |
| 最後のバージョンの表、巻き戻し数の揺れ | 直接実行（`bash ci.sh` 3回の不変条件の段階） | 2026-10-21 |
| 変えたバージョンの結果 | 直接実行（変えたバージョンのコピー、fuzzキャッシュを消した新しいコピーで7回再実行） | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/ （ファズテスト、不変条件テストとハンドラー、`targetSelector`、`vm.assume`、`bound`、縮めた手順と保存された失敗の再実行）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （`Panic(uint256)`コード0x11 算術のあふれ、SMTChecker）
- forge-std 1.17.0
