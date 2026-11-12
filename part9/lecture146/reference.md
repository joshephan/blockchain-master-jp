# 第146講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | `solc --version`、foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-20 |

付録のドキュメントの出力とエラーの文は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36 `docs/natspec-format.rst` | 2026-10-20 |
| solcの設定 | `forge config`、foundry.toml | 2026-10-20 |
| エラー番号 | 直接実行（`forge build`の出力） | 2026-10-20 |
| 出力にないドキュメント | 直接実行（`solc --userdoc --devdoc`） | 2026-10-20 |
| forgeの整形版とrawMetadata | 直接実行（`forge inspect Market userdoc|devdoc`、`out/Market.sol/Market.json`） | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| 末尾のハッシュ | 第145講のバージョン・第146講のバージョンのdeployedBytecodeの比較 | 2026-10-20 |
| 行番号 | `grep -n` | 2026-10-20 |
| ガス | `forge test`（記録の確認）、`forge snapshot --check` | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、NatSpec Format（`docs/natspec-format.rst`、タグの表116〜127行、継承163〜168行、例61〜104行と出力204〜262行）：https://docs.soliditylang.org/en/v0.8.36/natspec-format.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/natspec-format.rst
- Foundry公式ドキュメント（`forge inspect`）：https://getfoundry.sh/
