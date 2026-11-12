# 第72講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvilのブロックガスリミット | 30,000,000（既定値） | `cast block latest --field gasLimit` | 2026-10-19 |

付録のエラーの原文、ガスの数字、欄の値、アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Iterable Mappingsの例、マッピングのキーの型 | Solidityのソースのタグv0.8.36 `docs/types/mapping-types.rst` | 2026-10-19 |
| OpenZeppelin ContractsのバージョンとEnumerableSetの構造 | `lib/openzeppelin-contracts/package.json`、`contracts/utils/structs/EnumerableSet.sol` | 2026-10-19 |
| Book・Desk・Members・sumAll・MarketのgasUsed | anvil、`cast send --json`（直接実行） | 2026-10-19 |
| 第66講の配列のsumの要素あたりのガス | 第66講の実習の測定値 | 2026-10-19 |
| メインネットのブロックガスリミット | 第66講の測定値（ブロック26,223,875） | 2026-10-19 |
| メインネットのトランザクション一つのガスの上限 | EIP-7825 | 2026-10-19 |
| sumAllのおおよその最大の長さ | 上の測定値から計算 | 2026-10-19 |
| テストのアドレス | `forge create`の出力（直接実行） | 2026-10-19 |

## 参考資料

- Solidityドキュメントのソースv0.8.36、Mapping TypesとIterable Mappingsの例: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/mapping-types.rst
- OpenZeppelin Contracts 5.4.0、`contracts/utils/structs/EnumerableSet.sol`、EnumerableMap
- EIP-7825 Transaction Gas Limit Cap: https://eips.ethereum.org/EIPS/eip-7825
- Foundry公式ドキュメント: https://getfoundry.sh/
