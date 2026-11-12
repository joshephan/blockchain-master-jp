# 第34講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `forge --version` | 2026-10-18 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-18 |
| ローカルチェーン | anvil、チェーン番号31337（0x7a69） | run-latest.jsonの`chainId` | 2026-10-18 |

付録の出力とバイトコードの比較は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| シミュレーションの見積もりガス | `forge script`の出力 | 2026-10-18 |
| 実際のデプロイのgasUsed | `broadcast/Counter.s.sol/31337/run-latest.json`のreceipts | 2026-10-18 |
| Counterのランタイムコードのサイズ | `forge inspect`の出力の長さ | 2026-10-18 |
| ブロックエクスプローラーでの検証の手順 | `forge verify-contract --help`の例（実際には実行していない） | 2026-10-18 |
| forge scriptの鍵のオプション | `forge script --help` | 2026-10-18 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-stdリポジトリ: https://github.com/foundry-rs/forge-std（`Script`、`vm.startBroadcast`、`vm.stopBroadcast`）
- Sourcify（Foundryの`--verifier sourcify`）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
