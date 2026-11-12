# 第120講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録の出力・ガス・エラー番号は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Vars120のgasUsed | anvilの既定の設定、`cast send --json`のレシート | 2026-10-19 |
| デプロイのアドレス | anvilに`forge create`でデプロイした実行の出力 | 2026-10-19 |
| 第120講のバージョンのサイズ | `forge build --offline --force --sizes` | 2026-10-19 |
| 第120講のバージョンのテスト | `forge test --offline` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Inline AssemblyのAccess to External Variables, Functions and Libraries（`docs/assembly.rst`）: https://docs.soliditylang.org/en/v0.8.36/assembly.html
  - memoryを指すローカル変数は、値ではなくメモリのアドレスとして評価される
  - 外部関数の値は`x.address`・`x.selector`、セレクタは右寄せの4バイト
  - 動的なcalldataの配列は`x.offset`（バイト）・`x.length`（要素の数）
  - storageの変数は`x.slot`・`x.offset`、`x`だけを使うとエラー。状態変数の`.slot`・`.offset`には代入できない
  - 0.6.0から、ブロックの中の変数名はブロックの外から見える宣言を隠せない
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/assembly.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
