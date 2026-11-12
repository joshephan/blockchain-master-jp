# 第208講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | foundry.toml | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。二つのチェーンのデモは、ローカルのanvil二つに既定のテスト用アカウントで送った。実際の鍵・実際の資金・外部への接続は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| MessageTestのガス、トレースの番号・リバートの理由 | 直接実行（`forge test --offline --match-contract MessageTest -vv`、`-vvvv`） | 2026-10-21 |
| 二つのチェーンのアドレス・ブロック・コードの長さ | 直接実行（ローカルのanvil二つ） | 2026-10-21 |
| try/catchの原文 | Solidityのドキュメント v0.8.36 `control-structures.rst` | 2026-10-21 |
| 五つの枠を呼ぶ名前 | 各プロジェクトの公式ドキュメント（IBCのドキュメントdocs.cosmos.network/ibc、Chainlink CCIPのオンチェーンの構成要素、LayerZero v2のプロトコルの概要、Hyperlane Mailbox、Wormhole VAA、OP Stackのメッセージング） | 2026-10-21 |

## 参考資料

- Solidityのドキュメント v0.8.36 try/catchの節: https://docs.soliditylang.org/en/v0.8.36/control-structures.html、原本 https://github.com/argotorg/solidity/blob/v0.8.36/docs/control-structures.rst （810〜904行目。873〜876行目は`catch (bytes memory lowLevelData)`が実行される場合、902〜904行目はcatchブロックに来たときには外部呼び出しの状態の変更が戻されているという文）
- 五つの位置の公開名（名前のレベルだけ、製品の比較・現状・数値なし）: IBC relayer・light client、Chainlink CCIP Router・OnRamp・OffRamp、LayerZero Endpoint・DVN・Executor、Hyperlane Mailbox・ISM、Wormhole Guardian・VAA、OP Stack CrossDomainMessenger
- Foundry公式ドキュメント（`vm.chainId`、anvil `--chain-id`）: https://getfoundry.sh/
