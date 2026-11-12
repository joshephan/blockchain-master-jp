# 第216講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka | `gov/foundry.toml`、`market/foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | コピーの先頭のコメント"last updated v5.4.0"、`vendor/oz/package.json` | 2026-10-21 |

付録のテスト結果とガスは、すべて上の環境で`forge test --offline`によって直接実行した結果である。anvilと外部への接続は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| タイムロック・ガバナーの設定 | `gov/test/Timelock216.t.sol`、`market/test/GovMarket58.t.sol` | 2026-10-21 |
| Marketのガバナンスの経路（ブロック52個・172,800秒） | 直接実行（`test_addAssetThroughGovernance`のログ） | 2026-10-21 |
| テストのガス（gov、market） | 直接実行（`forge test --offline -vvv`） | 2026-10-21 |
| Marketの基準のバージョン | 第53章の終わりのバージョンとの`diff -r`、コピー全体の`forge test --offline` | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0 `governance/TimelockController.sol`
  - 12〜24行目の先頭のコメント（役割、"multisig or a DAO as the sole proposer"）
  - 103〜138行目のコンストラクタとIMPORTANTのコメント（デプロイの管理者の役割）
  - 140〜151行目`onlyRoleOrOpenRole`
  - 228〜240行目の作業のid（`hashOperation`）
  - 419〜429行目、440〜455行目の先行する作業の検査、`updateDelay`の要件
- OpenZeppelin Contracts 5.4.0 `governance/extensions/GovernorTimelockControl.sol`
  - 10〜23行目の先頭のコメントとWARNING（ガバナー以外の提案者・取り消し役を置く危険）
  - 159〜166行目のタイムロックの作業のsalt
- BIP-65 OP_CHECKLOCKTIMEVERIFY（ビットコインのスクリプトの待ちとの比較）: https://github.com/bitcoin/bips/blob/master/bip-0065.mediawiki
- Foundry公式ドキュメント: https://getfoundry.sh/
