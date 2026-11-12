# 第137講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| ビルドの設定 | evm_version osaka、optimizerは切る | デモ・通しプロジェクトのfoundry.toml | 2026-10-20 |

付録の数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Mem137・Mem137xの値、expandのガス | デモのプロジェクトで`forge test --match-path test/Mem137.t.sol -vv`、`test/Mem137x.t.sol -vv` | 2026-10-20 |
| storageLayout | `forge inspect src/Mem137.sol:Mem137 storageLayout`、`forge inspect test/Mem137x.t.sol:Mem137x storageLayout` | 2026-10-20 |
| メモリを広げるガスの式 | イーサリアムのイエローペーパーのG_memoryの式、nごとに計算 | 2026-10-20 |
| Marketの最初の命令とimmutableの位置 | `forge inspect src/Market.sol:Market bytecode`・`deployedBytecode`・`assembly` | 2026-10-20 |
| Marketのメモリ | anvil（`--steps-tracing`）にデプロイしてから`debug_traceTransaction`（enableMemory）、深さ1の0x40の欄・CALL・LOG・REVERTの引数と終わりのメモリ | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Layout in Memory（先頭の四つの欄、never freed、要素32バイト、多次元配列、一時メモリの警告、msize、Differences to Layout in Storage）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/layout_in_memory.rst
- イーサリアムのイエローペーパー（メモリの拡張のコストG_memory）: https://ethereum.github.io/yellowpaper/paper.pdf
- Foundry公式ドキュメント（`forge inspect`）: https://getfoundry.sh/
