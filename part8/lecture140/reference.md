# 第140講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| EVMのバージョン | osaka | foundry.toml | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| テスト | `forge test`、`forge test --optimize`、`FOUNDRY_PROFILE=debug`・`ir`をつけた同じコマンド | 2026-10-20 |
| Gas140 | デモのプロジェクトで`forge test --match-path test/Gas140.t.sol -vvvv`、`FOUNDRY_PROFILE=opt`で同じコマンド | 2026-10-20 |
| 二つのビルドの突き合わせ、1文字のバージョン | anvil一つ（ブロック間隔1秒、`evm_setAutomine false`、`evm_mine`）に二つのバージョンをデプロイし、`eth_sendTransaction`・`eth_call`・`eth_getStorageAt`で比較 | 2026-10-20 |
| ABI・セレクタ・storageLayout・immutableの位置 | out・out-debugの成果物、`forge inspect src/Market.sol:Market storageLayout` | 2026-10-20 |
| サイズ・ガス | `forge build --sizes`、バージョンごとに新しいanvilにデプロイして同じ順序で送ったレシートのgasUsed | 2026-10-20 |
| スナップショット | `forge snapshot --snap`、`forge snapshot --diff` | 2026-10-20 |
| Backtrace | `forge test --match-path test/Fail.t.sol -vvvvv`、`FOUNDRY_PROFILE=debug`で同じコマンド | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、The Optimizer（Yul-Based Optimizer Moduleの最初の段落とwarning、`docs/internals/optimizer.rst` 282〜290行目、runs 81〜86行目）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/optimizer.rst
- Foundry公式ドキュメント（プロファイル、`forge snapshot`）: https://getfoundry.sh/
