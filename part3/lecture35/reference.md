# 第35講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、最適化オフ | foundry.tomlの`solc = "0.8.30"` | 2026-10-19 |
| OpenZeppelin Contracts | v5.4.0 | `lib/openzeppelin-contracts` | 2026-10-19 |
| ローカルチェーン | anvil、チェーン番号31337 | `anvil` | 2026-10-19 |

付録のサイズ、ガス、アドレス、出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| コントラクトのサイズの上限 | EIP-170、EIP-3860、`forge build --sizes`のRuntime Margin・Initcode Marginの値 | 2026-10-19 |
| ランタイムコードのサイズ | `forge build --sizes` | 2026-10-19 |
| grow・incrementのgasUsed | `cast send`のレシート | 2026-10-19 |
| OpenZeppelinのバージョンとtoStringの可視性 | OpenZeppelin Contracts v5.4.0のソース（`utils/Strings.sol`） | 2026-10-19 |

## 参考資料

- EIP-170 コントラクトのコードサイズの上限: https://eips.ethereum.org/EIPS/eip-170
- EIP-3860 生成コードのサイズの上限: https://eips.ethereum.org/EIPS/eip-3860
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- OpenZeppelin Contracts v5.4.0（`utils/Strings.sol`）
- Foundry公式ドキュメント: https://getfoundry.sh/
