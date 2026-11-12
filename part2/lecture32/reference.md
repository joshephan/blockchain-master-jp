# 第32講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-18 |
| solc | 0.8.30 | `forge build --offline`の出力 | 2026-10-18 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-18 |
| ローカルチェーン | anvil、チェーンID 31337 | 直接実行 | 2026-10-18 |

付録のトレースとガスの数字は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| -vの段階ごとの出力内容 | `forge test --help`と実際の出力 | 2026-10-18 |
| トレースのガスの値 | `forge test -vvv`を直接実行 | 2026-10-18 |
| 失敗したトランザクションのgasUsed | anvilに`cast send` | 2026-10-18 |
| SLOADの初回の読み取りのガス、残りガス | `forge test --debug --dump`が書いたファイルの`gas_cost`、`gas_remaining` | 2026-10-18 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-stdリポジトリ: https://github.com/foundry-rs/forge-std
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
