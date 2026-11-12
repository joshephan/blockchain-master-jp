# 第148講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-20 |
| solc | 0.8.30 | `solc --version`、foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| forge fmtの既定値 | 二十の項目（時効性の表） | `forge config`の`[fmt]`の節 | 2026-10-20 |

付録の出力とガスの数字は、すべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcの設定 | foundry.toml、`forge config` | 2026-10-20 |
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36 `docs/style-guide.rst`（1,345行） | 2026-10-20 |
| forge fmtの既定値 | `forge config`（Foundry 1.8.3） | 2026-10-20 |
| 1行の長さの数え方、120バイトを超える行 | 直接実行（Width2・Width3、第148講のバージョンのsrc） | 2026-10-20 |
| wrap_commentsの結果 | 直接実行（`wrap_comments = true`のプロジェクト） | 2026-10-20 |
| 末尾のハッシュ・末尾より前の部分の比較 | 直接実行（バージョンごとに三つのプロファイルの成果物を比較） | 2026-10-20 |
| ASTの位置の欄 | 直接実行（`solc --ast-compact-json`） | 2026-10-20 |
| ガス | 直接実行（バージョンごとに新しいanvil、レシートのgasUsed） | 2026-10-20 |
| デプロイデータのバイトの値 | EIP-2028 | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| 行番号 | 第148講のバージョンの`src/Market.sol` | 2026-10-20 |
| アカウント0番 | anvilの既定のアカウント | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Style Guide（`docs/style-guide.rst`、Code LayoutとOrder of Layout 1049〜1071行、Order of Functions 310〜322行、関数宣言の属性の順番649〜655行、NatSpecの位置1311〜1313行）：https://docs.soliditylang.org/en/v0.8.36/style-guide.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/style-guide.rst
- EIP-2028, Transaction data gas cost reduction：https://eips.ethereum.org/EIPS/eip-2028
- Foundry公式ドキュメント（`forge fmt`と`[fmt]`の設定）：https://getfoundry.sh/
