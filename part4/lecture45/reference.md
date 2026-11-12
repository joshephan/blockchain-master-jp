# 第45講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、最適化オフ | foundry.toml `solc = "0.8.30"`、コンパイルの出力 | 2026-10-19 |
| ローカルチェーン | anvil、既定のアカウント0番 | 直接実行 | 2026-10-19 |

付録のドキュメント出力、バイトコード、残高は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| コメントの文法とNatSpecタグ | Solidity公式ドキュメントv0.8.36、Layout of a Solidity Source FileのCommentsの節、NatSpec Formatの節 | 2026-10-19 |
| Vaultのサイズ、エラーコード | 直接ビルドした出力（最適化オフ） | 2026-10-19 |
| forgefmtの指示コメント | `forge fmt --check`の実行出力 | 2026-10-19 |
| solhint、slitherの指示コメント | 各ツールのドキュメントの表記 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36（Comments、NatSpec Format、Contract Metadata）: https://docs.soliditylang.org/en/v0.8.36/
- 公式ドキュメントのVotingの例（src/Ballot.solの元）、[第37講](../../part3/lecture37/)を参照
- solhint、slither（指示コメントの表記のみ参照）
- Foundry公式ドキュメント: https://getfoundry.sh/
