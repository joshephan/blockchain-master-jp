# 第47講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| ローカルチェーン | anvil、既定のアカウント0・1・2 | 直接実行 | 2026-10-19 |

付録のストレージの欄、ガス、残高、出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| コントラクトの構造の七つの項目 | Solidity公式ドキュメントv0.8.36、Structure of a Contractの節 | 2026-10-19 |
| visit()・preview()のgasUsed、残高の変化 | anvilのレシート、`cast balance`、`cast send`の出力 | 2026-10-19 |
| テストのトレース | `forge test -vvvv` | 2026-10-19 |
| SSTOREの価格 | EIP-2200、EIP-2929（ベルリンアップグレード以降） | 2021-04以降 |
| transient状態変数 | Solidity Changelog 0.8.27・0.8.28、公式ドキュメントv0.8.36 Layout of State Variables in Storage and Transient Storage、solc 0.8.30の出力 | 2026-10-19 |
| エラー番号、デプロイのサイズ | solc 0.8.30の出力、`forge build --sizes` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36（Structure of a Contract、Layout of State Variables in Storage and Transient Storage）: https://docs.soliditylang.org/en/v0.8.36/
- Solidity Changelog（0.8.27、0.8.28の項目）
- EIP-2200 SSTOREのガス計算: https://eips.ethereum.org/EIPS/eip-2200
- EIP-2929 状態アクセスのガスの引き上げ（コールドな欄の追加コスト）: https://eips.ethereum.org/EIPS/eip-2929
- 公式ドキュメントのVotingの例（src/Ballot.solの元）、[第37講](../../part3/lecture37/)を参照
- Foundry公式ドキュメント: https://getfoundry.sh/
