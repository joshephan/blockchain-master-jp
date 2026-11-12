# 第54講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のコンパイルエラー、欄の配置、送金の結果は、すべて上の環境とローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのAddressの節 | solidityリポジトリのタグv0.8.36 `docs/types/value-types.rst` | 2026-10-19 |
| addressとaddress payableが分かれたバージョン | 同じファイル（"The distinction between address and address payable was introduced in version 0.5.0."） | 2026-10-19 |
| msg.sender・tx.originの型 | タグv0.8.36 `docs/080-breaking-changes.rst` | 2026-10-19 |
| `transfer`を使ったときのコンパイラの警告 | 直接実行 | 2026-10-19 |
| イーサだけを送るトランザクションのgasUsed、鍵のないアドレスに送ったトランザクション | ローカルのanvilでの`cast send`のレシート | 2026-10-19 |
| Sameの二つの版の実行コード | `forge inspect Same deployedBytecode` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Value TypesのAddressの節: https://docs.soliditylang.org/en/v0.8.36/types/value-types.html
  - 原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/value-types.rst
- Solidity 0.8.0 Breaking Changes（msg.sender・tx.originがaddressになった変更）: https://docs.soliditylang.org/en/v0.8.36/080-breaking-changes.html
  - 原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/080-breaking-changes.rst
- Foundry公式ドキュメント（`cast wallet address`、`cast to-check-sum-address`）: https://getfoundry.sh/
