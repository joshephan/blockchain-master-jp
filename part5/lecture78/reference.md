# 第78講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力とガスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `abi.encodeCall`の導入バージョン | Solidity Changelog 0.8.11 | 2026-10-19 |
| ABI coder v2の既定値 | Solidity Changelog 0.8.0 | 2026-10-19 |
| test_sameBytesのガス | 直接実行、`forge test`の出力 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variablesの節のABI Encoding and Decoding Functions: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
  - `abi.decode`、`abi.encode`、`abi.encodePacked`、`abi.encodeWithSelector`、`abi.encodeWithSignature`（`abi.encodeWithSelector(bytes4(keccak256(bytes(signature))), ...)`と同じ）、`abi.encodeCall`（型を確認する、結果は`abi.encodeWithSelector(functionPointer.selector, ...)`と同じ）。結果の型は`bytes memory`
- 同じドキュメントのrst原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- Solidityの変更履歴 v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント（`cast abi-encode`、`cast calldata`、`cast sig`、`cast keccak`）: https://getfoundry.sh/
