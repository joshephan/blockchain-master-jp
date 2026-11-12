# 第200講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果、ストレージの配置、セレクタ、ローカルのanvilのアドレスとサイズは、上の環境で直接実行した結果である（外部への接続なし、anvilの既定のテスト用の鍵だけを使用）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| おもちゃの値 | `stable/src`、`market/test/StableAsset54.t.sol` | 2026-10-21 |
| ローカルチェーンの値 | ローカルのanvilで`forge create`、`cast call`、`cast storage`、`cast codesize`、`cast sig`（直接実行） | 2026-10-21 |
| テストの数 | `forge test --offline`（直接実行） | 2026-10-21 |
| 種類ごとの例の名前 | 広く知られたトークンの名前（名前だけ） | 2026-10-21 |

## 参考資料

- EIP-20 トークン標準（関数九つ、オプション三つを含む）: https://eips.ethereum.org/EIPS/eip-20
- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
