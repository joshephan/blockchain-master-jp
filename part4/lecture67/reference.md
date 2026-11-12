# 第67講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のエラーの原文、ガスの数字、メモリの位置の値は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| memory配列・配列リテラルのルール | Solidityのソースのタグv0.8.36 `docs/types/reference-types.rst`（Allocating Memory Arrays、Array Literals、Array Members） | 2026-10-19 |
| ドキュメントと実際の出力が違う箇所 | `forge build`（直接実行、bad/のLit3、Lit5、Lit6、Lit7、Lit9） | 2026-10-19 |
| フリーメモリポインターの最初の値 | `freePtr`のcast call（直接実行） | 2026-10-19 |
| make(n)のgasUsed | anvilでの`cast send`のレシート（直接実行） | 2026-10-19 |
| テストのガス | `forge test`（直接実行） | 2026-10-19 |

## 参考資料

- Solidityドキュメントのソースv0.8.36、Allocating Memory Arrays・Array Literals・Array Members: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/reference-types.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
