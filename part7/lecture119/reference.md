# 第119講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のサイズ・出力・エラー番号は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Yul119のサイズ | `forge build --offline --sizes` | 2026-10-19 |
| Yul119のIRの行数 | `forge inspect --offline src/Yul119.sol:Yul119 ir`の直接実行 | 2026-10-19 |
| Market 第119講のバージョンのサイズ・テスト | `forge build --offline --force --sizes`、`forge test --offline` | 2026-10-19 |
| デプロイのアドレス | anvilに`forge create`でデプロイした実行の出力 | 2026-10-19 |
| `leave`が入ったバージョン | Solidity Changelog.md 0.6.0（2019-12-17）"Yul: Introduce `leave` statement that exits the current function." | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Inline Assembly（`docs/assembly.rst`）: https://docs.soliditylang.org/en/v0.8.36/assembly.html
  - "An inline assembly block is marked by `assembly { ... }`, where the code inside the curly braces is code in the Yul language."
  - "Different inline assembly blocks share no namespace"
- Solidity公式ドキュメント v0.8.36、Yul（`docs/yul.rst`）: https://docs.soliditylang.org/en/v0.8.36/yul.html
  - SWAP・DUP・JUMPDEST・JUMP・JUMPIを文として置かない、`dup`・`swap`・`jump`・`push`の命令は使えない
  - elseブロックはない（"Consider using "switch" instead"）、関数の中からは外のローカル変数が見えない、`leave`
  - 文字列リテラルは32バイトまで、右側に0を詰める
  - EVMの方言の唯一の型`u256`、`div(x, y)`はyが0なら0、`slt`は2の補数の符号付きの数の比較、組み込み関数の表の`log0`〜`log4`
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/assembly.rst, https://github.com/argotorg/solidity/blob/v0.8.36/docs/yul.rst
- Solidity Changelog: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント: https://getfoundry.sh/
