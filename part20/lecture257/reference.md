# 第257講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・anvil・cast） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |
| anvil | デフォルトのテスト用キー、0番アカウントがデプロイ | `anvil`の起動画面 | 2026-10-21 |

付録のテスト結果、アドレス、ブロック、ガス、エラーは、すべて上の環境で直接実行した結果である。署名・送信はローカルのanvilのデフォルトのテスト用キーでだけ行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| TimelockControllerの行番号 | OpenZeppelin Contracts 5.4.0 `contracts/governance/TimelockController.sol` | 2026-10-21 |
| 講義用の設計値 | `design/architecture.md` 3節 | 2026-10-21 |
| anvilのデモ | 直接実行（anvilにデプロイ、castで予約・実行・停止） | 2026-10-21 |
| 権限のバージョンのテスト・サイズ | 直接実行（`forge test --offline`、`forge build --offline --sizes`） | 2026-10-21 |
| セレクタ・イベント・エラーの数、メタデータハッシュ | 直接実行（ビルド成果物から数えた） | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0 `contracts/governance/TimelockController.sol`（コンストラクターとロール116〜136行、`updateDelay`はタイムロック自身だけ448〜455行、`TimelockUnexpectedOperationState`、`CallScheduled`イベント）
- 前の章の判断：管理者の席が一つなので、タイムロックに座らせると設定も停止も一緒に遅れ、マルチシグに置くと両方すぐにできる。設定はタイムロック、停止はマルチシグがすぐにするには、管理者ロールを二つに分けるソースの変更が必要である
- 第3講の判別ワークシートの反証の項目（「最終決定権の行き着く先が結局一つの主体の鍵か？」）
- Foundry公式ドキュメント（anvil、cast）: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36（immutable）: https://docs.soliditylang.org/en/v0.8.36/
