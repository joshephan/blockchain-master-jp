# 第81講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvilのブロックガスリミット | 30,000,000 | `cast block latest --field gasLimit` | 2026-10-19 |

付録の出力とガスの値は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| イーサリアムメインネットのブロックガスリミット | 公開RPC（ethereum-rpc.publicnode.com）の`eth_getBlockByNumber`で直近24時間のブロック300個を標本に、EIP-7935 | 2026-10-20 |
| gasUsed、トレースのガス | 直接実行（`cast send`、`cast call`、`forge test -vvvv`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Expressions and Control Structuresの節のControl Structures（ある制御文の一覧、条件に整数を使えない理由、try/catchは外部呼び出しとコントラクト作成の呼び出しにだけ使える）: https://docs.soliditylang.org/en/v0.8.36/
- EIP-7935: https://eips.ethereum.org/EIPS/eip-7935
- Foundry公式ドキュメント: https://getfoundry.sh/
