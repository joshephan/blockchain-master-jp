# 第138講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| ビルドの設定 | evm_version osaka、optimizerは切る | デモ・通しプロジェクトのfoundry.toml | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| calldataの欄 | `cast calldata`の直接実行 | 2026-10-20 |
| デコーダの動作、dirtyの結果 | anvilにC138をデプロイしてから、手で直したcalldataを`cast call` | 2026-10-20 |
| ブロックの中の値 | デモのプロジェクトで`forge test --match-path test/Bool138.t.sol -vv` | 2026-10-20 |
| コンストラクタの引数 | `cast tx <デプロイのトランザクション> input`、`forge inspect src/Market.sol:Market bytecode`の先頭部分を`cast disassemble` | 2026-10-20 |
| Marketのcalldata四つ | 同じanvilのMarketに`cast send`、レシートのstatus・gasUsed | 2026-10-20 |
| 通しプロジェクトのガス | 新しいanvilにデプロイして順に送ったレシートのgasUsed | 2026-10-20 |
| セレクタ | `cast sig`、`forge inspect src/Market.sol:Market methodIdentifiers` | 2026-10-20 |
| calldataのガスの規則 | EIP-2028 | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Layout of Call Data: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/layout_in_calldata.rst
- Solidity公式ドキュメント v0.8.36、Cleaning Up Variables（クリーンアップの表、JUMPIとbool）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/variable_cleanup.rst
- Solidity公式ドキュメント v0.8.36、Contract ABI Specification: https://docs.soliditylang.org/en/v0.8.36/abi-spec.html
- EIP-2028, Transaction data gas cost reduction: https://eips.ethereum.org/EIPS/eip-2028
- Foundry公式ドキュメント（`cast calldata`、`cast call`、`cast disassemble`）: https://getfoundry.sh/
