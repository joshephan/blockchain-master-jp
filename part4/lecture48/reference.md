# 第48講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値）、既定のパイプライン（via-IRはオフ） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| ローカルチェーン | anvil、既定のアカウント0・1・2 | 直接実行 | 2026-10-19 |

付録のサイズ、ガス、ログ、巻き戻しデータは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| modifier、イベント、エラーの文法 | Solidity公式ドキュメントv0.8.36、Structure of a Contract、Contracts、Control Structuresの節 | 2026-10-19 |
| ランタイムのサイズ | `forge build --sizes` | 2026-10-19 |
| gasUsed、失敗したvote(5)、Order.run() | anvilのレシート、`forge test` | 2026-10-19 |
| 巻き戻しデータの長さ | `cast call`の出力 | 2026-10-19 |
| カスタムエラーが導入されたバージョン | Solidityブログ"Custom Errors in Solidity"（2021-04-21）、GitHubリリースv0.8.4の変更記録 | 2026-10-19 |
| ファイルレベルのイベント | Solidityブログの0.8.22リリース告知、GitHubリリースv0.8.22の変更記録"Allow defining events at file level"、0.8.30での直接実行 | 2026-10-19 |
| require(条件, カスタムエラー) | Solidityブログの0.8.26・0.8.27リリース告知、GitHubリリースv0.8.27の変更記録"Make require(bool, Error) available when using the legacy pipeline"、直接実行（GateReq） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidityブログ"Custom Errors in Solidity"（2021-04-21）、0.8.22・0.8.26・0.8.27のリリース告知
- 公式ドキュメントのVotingの例（src/Ballot.solの元）、[第37講](../../part3/lecture37/)を参照
- Foundry公式ドキュメント: https://getfoundry.sh/
