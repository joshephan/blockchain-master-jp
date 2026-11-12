# 第271講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0（`contracts/`を`vendor/oz/`に置いた） | `vendor/oz/package.json` | 2026-10-21 |
| テスト数 | この講義のテスト11個、コピー全体160個（46スイート） | `forge test --offline` | 2026-10-21 |

付録のテスト結果とガスは、すべて上の環境で直接実行した結果である。anvilは使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| OpenZeppelin Contractsのバージョン | テスト用のコピー`vendor/oz` | 2026-10-21 |
| テストの設定値 | `test/Politics271.t.sol` | 2026-10-21 |
| Marketの基準のバージョン（判断） | 通しプロジェクトのキャップストーンの最後のバージョン`design/requirements.md`（N-03、A-03、S-01）、`design/architecture.md`（D-13、権限リスト） | 2026-10-21 |
| Beanstalk | 前の講義の事件カード（名前・年） | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0：`contracts/governance/Governor.sol`、`extensions/GovernorSettings.sol`、`extensions/GovernorCountingSimple.sol`、`extensions/GovernorVotes.sol`、`extensions/GovernorVotesQuorumFraction.sol`、`extensions/GovernorTimelockControl.sol`、`TimelockController.sol`、`contracts/token/ERC20/extensions/ERC20Votes.sol`、`ERC20Permit.sol`
- ERC-20 Token Standard: https://eips.ethereum.org/EIPS/eip-20
- EIP-2612 Permit Extension for EIP-20 Signed Approvals: https://eips.ethereum.org/EIPS/eip-2612
- 事件：Beanstalk（2022）。票を一時的に借りてガバナンスの提案を通過させて実行した。防ぐ側はスナップショット時点の投票権
- Foundry公式ドキュメント: https://getfoundry.sh/
