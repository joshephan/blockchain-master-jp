# 第203講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"`、svmが取得したsolc-0.8.30 | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果とガスは、上の環境で直接実行した結果である（anvilなし、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| おもちゃのテスト | `forge test --offline --match-contract Judge203Test -vv`（直接実行） | 2026-10-21 |
| Marketのテスト | `forge test --offline --match-test "test_owedNeverAboveCash|test_solvencyTable"`、全体の`forge test --offline`（直接実行） | 2026-10-21 |
| パーセント | `src/Yield202.sol`、`test/Judge203.t.sol`、Marketのデプロイの引数 | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- EIP-20 トークン標準: https://eips.ethereum.org/EIPS/eip-20
