# 第180講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | `gov/foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `gov/lib/openzeppelin-contracts/package.json`のversion | 2026-10-21 |

付録のガスの数字、トレース、grepの出力は、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Govの設定 | `gov/src/Gov.sol`、`gov/test/Gov180.t.sol`（トイの値） | 2026-10-21 |
| テストのガス、トレース | 直接実行（`forge test -vvv`、テストごとの`-vvvv`） | 2026-10-21 |
| Marketのバージョンとimmutableの行 | 直接実行（第46章の終わりのバージョンのsrcにgrep） | 2026-10-21 |
| 事件の年 | 事件の名前・年 | 2026-10-21 |
| selfdestructの動作の変更 | EIP-6780 | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0 `token/ERC20/extensions/ERC20Votes.sol`の冒頭コメント（残高は票ではなく、委任してはじめてチェックポイントができる）
- OpenZeppelin Contracts 5.4.0 `governance/utils/Votes.sol`（77〜81行 getPastVotes、90〜100行 _validateTimepointとERC5805FutureLookup）
- OpenZeppelin Contracts 5.4.0 `governance/IGovernor.sol`のproposalSnapshotのコメント（ブロック番号の時計ならそのブロックの終わりで記録し、投票は次のブロックから）
- OpenZeppelin Contracts 5.4.0 `governance/TimelockController.sol`の冒頭コメント（"This gives time for users of the controlled contract to exit before a potentially dangerous maintenance operation is applied."）、onlyRoleOrOpenRoleの上のコメント（address(0)に役割を与えると全員に開く）
- OpenZeppelin Contracts 5.4.0のGovernorモジュール：`Governor`、`GovernorSettings`、`GovernorCountingSimple`、`GovernorVotes`、`GovernorVotesQuorumFraction`、`GovernorTimelockControl`
- EIP-6780 SELFDESTRUCT only in same transaction（Cancunハードフォーク）: https://eips.ethereum.org/EIPS/eip-6780
- EIP-2535 Diamonds（420〜421行 "Use of `selfdestruct` in a facet is heavily discouraged."）: https://eips.ethereum.org/EIPS/eip-2535
- Beanstalk（2022）：投票権を実行する瞬間の保有量で数えていて、借りた票で即時実行のしきい値を越えたガバナンスの乗っ取り。この講義は名前・年・一行の性格だけを扱う
