# 第173講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（200）・via-IRオン・evm osaka | `code/vulns/foundry.toml`、`code/market/foundry.toml` | 2026-10-21 |
| Market | 第42章の終わりのバージョン（第164講のバージョン）のsrcのまま、テスト`Order45.t.sol`を追加 | `diff`で基準のバージョンと比較 | 2026-10-21 |

付録の価格、借りられる量、ガス、lintの警告は、すべて上の環境で直接実行した結果である。実行後も`snapshots/Market.json`は変わらなかった。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| TWAPの窓の長さ | `code/vulns/test/Oracle173.t.sol`、`code/vulns/test/Fixed173.t.sol` | 2026-10-21 |
| ブロックの時刻の保証 | Solidity v0.8.36のドキュメント`units-and-global-variables.rst`のblock.timestampの説明 | 2026-10-21 |
| 事件の年 | 公開された事件の記録 | 2026-10-21 |
| vulns・marketのテストのガス | 直接実行（`forge test --match-contract Oracle173Test`、`Fixed173Test`、`"Order45Test|DonationTest"`） | 2026-10-21 |
| vulnsのlintの警告 | 直接実行（`forge build --offline --force`） | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variablesのblock.timestampの説明（"The current block timestamp must be strictly larger than the timestamp of the last block, but the only guarantee is that it will be somewhere between the timestamps of two consecutive blocks in the canonical chain."）: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
- 同じドキュメントの原本ファイル: https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- bZx（2020年）：チェーン上の価格を揺らして担保の価値を膨らませ、その担保で借りていった事件
- Mango Markets（2022年）：同じ手口でチェーン上の価格を揺らして担保の価値を膨らませ、その担保で借りていった事件
