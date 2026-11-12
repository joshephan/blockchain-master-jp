# 第178講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | `guards/foundry.toml`、`market/foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `guards/lib/openzeppelin-contracts` | 2026-10-21 |

付録のガスの数字、サイズ、テストの出力は、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Marketのサイズ | 直接実行（`forge build --offline --sizes`、直す前のバージョンと直したバージョン） | 2026-10-21 |
| Marketの呼び出しのガス | 直接実行（GasTestが残した`snapshots/Market.json`、直す前のバージョンと直したバージョン） | 2026-10-21 |
| テストのガス（guards、KeysTest） | 直接実行（`forge test -vvv`） | 2026-10-21 |
| 実務のマルチシグ・署名の機器 | 該当なし（製品名・現状は載せない） | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント（キーストア、環境変数、ハードウェアウォレットでデプロイの鍵を扱う方法）: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
