# 第170講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30、optimizerオン（200）・via-IRオン・evm osaka | `code/vulns/foundry.toml`、`code/market/foundry.toml` | 2026-10-20 |
| Market | 第42章の終わりのバージョン（第164講のバージョン）のsrcのまま、テスト`BadTokens44.t.sol`を追加 | 第164講のバージョンと比較 | 2026-10-20 |

付録のガス、トレース、ビルド・lintの警告は、すべて上の環境で直接実行した結果である。実行後も`snapshots/Market.json`は変わらなかった。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 2300ガス | Solidityのドキュメント、第99講 | 2026-10-20 |
| vulnsのテストのガスとトレース | 直接実行（`forge test --match-contract "Payout170Test|Checked170Test" -vvvv`） | 2026-10-20 |
| marketのテストのガスとトレース | 直接実行（`forge test --match-contract "PullTest|BadTokens44Test" -vvvv`） | 2026-10-20 |
| 二つの形のガス（アカウント同士） | 第150講の付録（直接実行） | 2026-10-20 |
| vulnsのビルドの警告 | 直接実行（`forge build --offline --force`） | 2026-10-20 |
| Marketのlintの警告 | 直接実行（`forge lint src`） | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Common PatternsのWithdrawal from Contracts（送る形と引き出す形、`common-patterns.rst`）: https://docs.soliditylang.org/en/v0.8.36/common-patterns.html
- 同じドキュメントの原本ファイル: https://github.com/argotorg/solidity/blob/v0.8.36/docs/common-patterns.rst
- Solidity公式ドキュメント v0.8.36（低水準のcall、try/catch）: https://docs.soliditylang.org/en/v0.8.36/
