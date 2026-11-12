# 第181講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30+commit.73712a01.Windows.msvc | `solc-0.8.30 --version`、`sha256sum` | 2026-10-21 |
| 秘密鍵 | anvilの既定のテスト用の鍵（アカウント0番）だけ | ローカルのanvil | 2026-10-21 |

付録のアドレス、calldata、テスト結果、ハッシュは、すべて上の環境で直接実行した結果である。外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcのバージョンとハッシュ | 直接実行（`solc-0.8.30 --version`、`sha256sum`）。solc-binの`list.json`との照合はネットワークが必要なので行わなかった | 2026-10-21 |
| Marketのビルド設定 | `foundry.toml` | 2026-10-21 |
| Marketのテスト | 直接実行（`forge test --offline`、`FOUNDRY_PROFILE=debug forge test --offline`） | 2026-10-21 |
| Market・トークンのアドレス | 直接実行（ローカルのanvilに`forge create --offline --broadcast`） | 2026-10-21 |
| 事件の年 | 事件の名前・年、Vyperの問題のバージョン | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Installing the Solidity CompilerのStatic Binariesの節（`installing-solidity.rst` 207行、236〜247行 `list.json`の例、264〜269行 keccak256・sha256の照合 "You can verify the integrity of the binary by comparing its keccak256 hash"）: https://docs.soliditylang.org/en/v0.8.36/installing-solidity.html
- Solidityリポジトリのバージョンごとの既知のバグ一覧 `docs/bugs.json`、`docs/bugs_by_version.json`: https://github.com/argotorg/solidity/blob/v0.8.36/docs/bugs.json
- 事件（名前・年・一行の性格）
  - BadgerDAO（2021）：Web画面に差し込まれたスクリプトが、ユーザーに別のアドレスへの承認を求めたフロントエンド攻撃
  - Curve DNS（2022）：ドメインのDNSレコードが変わり、同じアドレスバーに偽の画面が出た事件
  - Curve Vyper（2023.07.30）：Vyperコンパイラ0.2.15・0.2.16・0.3.0のバージョンが、ソースに書いた再入ロックをバイトコードで正しく作れなかったツールチェーンの事件
- Foundry公式ドキュメント（cast calldata、decode-calldata、forge create）: https://getfoundry.sh/
