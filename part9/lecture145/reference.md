# 第145講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundryの設定の既定値 | `isolate = true`、`gas_snapshot_check = false`、`gas_snapshot_emit = true` | `forge config` | 2026-10-20 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcの設定とプロファイル | `forge config`、foundry.toml | 2026-10-20 |
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36 `docs/ir-breaking-changes.rst` | 2026-10-20 |
| calldataの下限値の式 | EIP-7623、直接計算（calldataのバイトを数える） | 2026-10-20 |
| レシート・実行ガス | 直接実行（バージョンごとに新しいanvilのレシート、`cast run`） | 2026-10-20 |
| テストのガスと記録 | 直接実行（`forge test`、`forge snapshot`） | 2026-10-20 |
| 二つのビルドの照合 | 直接実行（同じ呼び出し300回を二つのビルドに入れ、状態・巻き戻しデータ・ログを比較） | 2026-10-20 |
| フォークの固定 | 直接実行（ローカルのanvilの元チェーンと、`--fork-block-number`で固定したフォークのanvil） | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| アカウント0番 | anvilの既定のアカウント | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Solidity IR-based Codegen Changes（`docs/ir-breaking-changes.rst`、引用21〜23行、項目の見出し35・77・106・161・229行、Internals 258〜288行）：https://docs.soliditylang.org/en/v0.8.36/ir-breaking-changes.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/ir-breaking-changes.rst
- EIP-7623, Increase calldata cost（Prague）：https://eips.ethereum.org/EIPS/eip-7623
- Foundry公式ドキュメント（`forge snapshot`、`vm.snapshotGasLastFrame`、`isolate`、`gas_snapshot_check`）：https://getfoundry.sh/
