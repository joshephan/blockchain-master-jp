# 第239講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `anvil --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| Python | 3.12、標準ライブラリ + `cast mktx`・`cast calldata`・`cast keccak` | `python --version` | 2026-10-21 |
| テスト | 136個が通る | `forge test --offline` | 2026-10-21 |

付録のナンス、取引のハッシュ、待ち行列の状態、ガス、残高はすべて、ローカルのanvil（`--no-mining`）で直接実行した結果である。署名はanvilのデフォルトのテスト用の鍵だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| anvilの同じナンスの置き換え | 直接実行（同じ手数料、5%・10%上げた置き換え） | 2026-10-21 |
| gethの置き換えのルールのデフォルト値 | geth文書 Command-line Options 660・630行目（go-ethereum websiteのコミット`4537eb54`） | 2026-10-16 |
| ethersのナンス管理 | ethers v6文書 providers（6.17.0）、`NonceManager` | 2026-10-21 |
| viemのナンス管理 | viem文書 accounts/local/createNonceManager | 2026-10-21 |

## 参考資料

- geth文書 Command-line Options（`--txpool.pricebump`、`--blobpool.pricebump`）
- ethers v6.17.0 `NonceManager`
- viem `nonceManager`、`createNonceManager`
- Foundry 公式ドキュメント（`cast mktx`、`cast calldata`、anvil `--no-mining`、`txpool_status`）: https://getfoundry.sh/
