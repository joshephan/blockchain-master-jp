# 第77講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| Foundryのテストの既定の送信元アドレス | `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38` | `forge test`の出力 | 2026-10-19 |

付録の出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `msg.gas`の非推奨化・削除 | Solidity公式ドキュメント v0.8.36 Units and Globally Available Variables | 2026-10-19 |
| `msg.sender`の型の変更 | Solidity公式ドキュメント v0.8.36 Solidity v0.8.0 Breaking Changes（`080-breaking-changes.rst`） | 2026-10-19 |
| pure・viewの規則 | Solidity公式ドキュメント v0.8.36 Functions（`contracts/functions.rst`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variablesの節のBlock and Transaction Properties: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
  - `msg.data`(bytes calldata) complete calldata, `msg.sender`(address) sender of the message (current call), `msg.sig`(bytes4) first four bytes of the calldata, `msg.value`(uint) number of wei sent with the message, `tx.origin` sender of the transaction (full call chain)
  - msgのメンバーはすべてexternal関数の呼び出しごとに変わりうるという注意の文言（ライブラリ関数の呼び出しを含む）
- 同じドキュメントのrst原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- Solidity v0.8.0 Breaking Changes: https://docs.soliditylang.org/en/v0.8.36/080-breaking-changes.html
- Functions（pure・viewの規則）: https://docs.soliditylang.org/en/v0.8.36/contracts/functions.html
- Foundry公式ドキュメント（`vm.prank`、`forge inspect`）: https://getfoundry.sh/
