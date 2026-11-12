# 第174講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（200）・via-IRオン・evm osaka | `code/vulns/foundry.toml`、`code/market/foundry.toml` | 2026-10-21 |
| Market | 第42章の終わりのバージョン（第164講のバージョン）のsrcのまま、テスト`Order45.t.sol`を追加 | `diff`で基準のバージョンと比較 | 2026-10-21 |

付録の価格、借りられる量、ガス、トレースは、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| テストのガス（vulns） | 直接実行（`forge test --match-contract Flash174Test`、`Flash174FixTest`、`--match-test test_twapResistsOneBlock`） | 2026-10-21 |
| テストのガス（market） | 直接実行（`forge test --match-contract Order45Test`） | 2026-10-21 |
| TWAPの窓の長さ | `code/vulns/test/Oracle173.t.sol`、直したバージョンのテストの`new TwapLender(tw, 1000)` | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
