# 第151講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-20 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0 | ライブラリの`package.json` | 2026-10-20 |

付録の出力とガスの数字は、すべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcの設定 | foundry.toml | 2026-10-20 |
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36 `docs/common-patterns.rst` | 2026-10-20 |
| OpenZeppelinの行番号 | OpenZeppelin Contracts 5.4.0のソース（`contracts/access/Ownable.sol`、`contracts/access/Ownable2Step.sol`、`contracts/utils/Context.sol`） | 2026-10-20 |
| エラー番号 | 直接実行（`forge build`） | 2026-10-20 |
| テストのガス | 直接実行（`forge test`、`.gas-snapshot`） | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| 末尾のハッシュ | 直接実行（第150講のバージョン・第151講のバージョンの成果物を比較） | 2026-10-20 |
| Marketのガス | 直接実行（新しいanvil、レシートのgasUsed） | 2026-10-20 |
| 行番号 | 第151講のバージョンの`src` | 2026-10-20 |
| アカウント | テストのコード、anvilの既定のアカウント | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Common PatternsのRestricting Access（`docs/common-patterns.rst` 110〜238行、例AccessRestriction 137〜234行）：https://docs.soliditylang.org/en/v0.8.36/common-patterns.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/common-patterns.rst
- OpenZeppelin Contracts 5.4.0：`contracts/access/Ownable.sol`（onlyOwner、`_checkOwner`、renounceOwnership、transferOwnership）、`contracts/access/Ownable2Step.sol`（transferOwnership、acceptOwnership）、`contracts/utils/Context.sol`（`_msgSender`）
- Foundry公式ドキュメント：https://getfoundry.sh/
