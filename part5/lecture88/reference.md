# 第88講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| solc（比較用） | 0.7.6 | `forge build --use 0.7.6`の出力 | 2026-10-19 |

付録の出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| あふれの検査の導入 | Solidityの変更履歴 0.8.0 | 2026-10-19 |
| SafeMathの削除 | OpenZeppelin Contracts 5.4.0のCHANGELOG.md（5.0.0の項目） | 2026-10-19 |
| Panicの番号とセレクタ | castの出力、`cast sig "Panic(uint256)"` | 2026-10-19 |
| 検査コードのガス | CounterとCounterUncheckedの`increment()`の直接測定（第35講） | 2026-10-19 |
| リバートしたbump | `cast send`、`cast balance`、`cast nonce`を直接実行した出力 | 2026-10-19 |
| テストのガス | `forge test`を直接実行した出力 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control StructuresのChecked or Unchecked Arithmeticの節（0.8.0から算術は既定であふれを検査、ゼロ除算の検査はuncheckedでも切れない、明示的な変換とシフト・ビット演算にはあふれの検査がない）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidityの変更履歴 v0.8.36（0.8.0の項目）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- OpenZeppelin Contracts 5.4.0 CHANGELOG.md（5.0.0でSafeMathを削除）
- Foundry公式ドキュメント: https://getfoundry.sh/
