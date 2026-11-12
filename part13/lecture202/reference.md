# 第202講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果、ガス、ローカルのanvilのアドレスとcastの出力は、上の環境で直接実行した結果である（外部への接続なし、anvilの既定のアカウントだけを使用）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| テストの数 | `forge test --offline`（直接実行） | 2026-10-21 |
| パーセント | `src/Yield202.sol`、Marketのデプロイの引数 | 2026-10-21 |
| anvilのデプロイのアドレス | ローカルのanvilで`forge create`（直接実行） | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント（anvil、cast）: https://getfoundry.sh/
- EIP-20 トークン標準: https://eips.ethereum.org/EIPS/eip-20
