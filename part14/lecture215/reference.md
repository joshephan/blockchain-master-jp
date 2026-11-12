# 第215講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka | `gov/foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `gov/lib/openzeppelin-contracts` | 2026-10-21 |

付録のテスト結果、ガス、castの出力、ビルドのエラーは、すべて上の環境で直接実行した結果である。anvilと外部への接続は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Gov58の設定、トークンの配分 | `gov/test/Gov215.t.sol` setUp | 2026-10-21 |
| 提案のid・アドレス・説明のハッシュ | 直接実行（`forge test`のログ、castでの計算し直し） | 2026-10-21 |
| テストのガス | 直接実行（`forge test --offline --match-contract Gov215Test -vvv`） | 2026-10-21 |
| Expiredを返すモジュール | OZ 5.4.0 `governance/`フォルダの検索 | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0 `governance/Governor.sol`
  - 58〜71行目`onlyGovernance`とコメント、210〜225行目`_checkGovernance`
  - 108〜127行目`hashProposal`とコメント（"chainId and the governor address are not part of the proposal id"）
  - 141行目`state`
  - 271〜297行目`propose`（提案のしきい値の比較）
  - 738〜779行目`_isValidDescriptionForProposer`（提案者の表示、先回りの提案の防止）
  - 781〜788行目`_validateCancel`
- OpenZeppelin Contracts 5.4.0 `governance/extensions/GovernorTimelockControl.sol` 43行目`state`
- OpenZeppelin Contracts 5.4.0 `governance/extensions/GovernorTimelockCompound.sol` `state`（Expired）
- Foundry公式ドキュメント: https://getfoundry.sh/
