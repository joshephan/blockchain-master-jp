# 第240講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `anvil --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| anvil | `--no-mining`、[7]だけ`--hardfork osaka --enable-tx-gas-limit` | 実行オプション | 2026-10-21 |
| Python | 3.12、標準ライブラリ + `cast` | `python --version` | 2026-10-21 |
| テスト | 136個が通る | `forge test --offline` | 2026-10-21 |

付録の見積もりの値、ガス、手数料、トレース、エラーはすべてローカルのanvilで直接実行した結果である。2回実行して出力が同じだった。署名はanvilのデフォルトのテスト用の鍵だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| gethの置き換えのルールのデフォルト値 | geth文書 Command-line Options 660行目（go-ethereum websiteのコミット`4537eb54`） | 2026-10-16 |
| anvilの置き換えの幅 | 直接実行（第239講と同じ測定） | 2026-10-21 |
| osakaの取引一つのガス上限 | EIP-7825、第229講のデータそのまま | 2026-10-21 |

## 参考資料

- EIP-7825 Transaction Gas Limit Cap: https://eips.ethereum.org/EIPS/eip-7825
- geth文書 Command-line Options（`--txpool.pricebump`）
- Foundry 公式ドキュメント（`cast estimate`、`cast run`、anvil `anvil_dropTransaction`・`anvil_reorg`）: https://getfoundry.sh/
