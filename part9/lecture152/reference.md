# 第152講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |

付録の出力とガスの数字は、すべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcの設定 | デモ用プロジェクトとMarketのfoundry.toml | 2026-10-20 |
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36 `docs/common-patterns.rst` | 2026-10-20 |
| 時刻を進める | anvil 1.8.3（`evm_increaseTime`、`evm_mine`） | 2026-10-20 |
| ドキュメントのStateMachineのガス | 直接実行（anvil、`cast send`、`cast run`）、`forge test` | 2026-10-20 |
| テストのガス | `.gas-snapshot` | 2026-10-20 |
| Marketのガス | 直接実行（新しいanvil、レシートのgasUsed） | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| 末尾のハッシュ | `forge inspect Market deployedBytecode` | 2026-10-20 |
| 120バイトを超える行 | `LC_ALL=C awk 'length($0)>120'` | 2026-10-20 |
| 行番号 | 第152講のバージョンの`src/Market.sol` | 2026-10-20 |
| アカウント0番 | anvilの既定のアカウント | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Common PatternsのState Machine（`docs/common-patterns.rst` 246〜393行、例StateMachine 303〜393行、modifierの順番のnote 277〜282行、0.4.0より前の動作のnote 288〜298行）：https://docs.soliditylang.org/en/v0.8.36/common-patterns.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/common-patterns.rst
- Foundry公式ドキュメント：https://getfoundry.sh/
