# 第269講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version`、`anvil --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka | `foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0（TimelockControllerなどファイル七つ） | `lib/openzeppelin-contracts` | 2026-10-21 |
| anvil | `--hardfork osaka`、chain-id 31337、ブロックヘッダーのminer 0、フォークしたノード一つ（`--fork-url`） | `cast chain-id`、`anvil_nodeInfo` | 2026-10-21 |
| Python | 標準ライブラリだけ（`ops/`、`deploy/check.py`） | | 2026-10-21 |

付録のテスト結果、アドレス、エラー、コードのサイズ、ブロックハッシュ、証明の確認結果は、すべて上の環境で直接実行した結果である（anvilのデモの出力の文字列は日本語に訳した）。署名・送信はローカルのanvilのデフォルトのテスト用アカウントでだけ行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 基準のバージョン（テスト92、コードのサイズ、メタデータハッシュの先頭4バイト） | 直接実行（`forge test --offline`、`cast codesize`） | 2026-10-21 |
| デモのアドレス、実行ごとに変わる値 | 直接実行（anvilでデプロイ・予約・実行・停止・凍結） | 2026-10-21 |
| ノードの比較と証明の確認 | 直接実行（`ops/market_read.py`、`ops/market_verify.py`） | 2026-10-21 |

## 参考資料

- ERC-1967 Proxy Storage Slots: https://eips.ethereum.org/EIPS/eip-1967 （実装スロット`0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`）
- EIP-7702 Set Code for EOAs: https://eips.ethereum.org/EIPS/eip-7702 （`test_delegatedEoaBatch`）
- OpenZeppelin Contracts 5.4.0 `contracts/governance/TimelockController.sol`（getMinDelay、`TimelockUnexpectedOperationState`）
- 事件の欄に置いた事件（年・月と分類は第268講の全事件の表のまま）：BadgerDAO 2021年12月、Curve DNS 2022（コードの外の画面・ドメイン）、Bybit 2025年2月（画面、しきい値、委任呼び出しの三つの欄）
- Foundry公式ドキュメント: https://getfoundry.sh/
