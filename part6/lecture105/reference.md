# 第105講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、レシート、サイズ、ガス、アドレスは、すべて上の環境のローカルのanvilで直接実行した結果である（`cast send --json`、`cast receipt`、`cast run`、`cast proof`、`forge build --sizes`、`forge test --gas-report`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ファイルレベルか継承されるメンバーとして宣言、引数はトランザクションのログに保存、ログとイベントのデータはコントラクトの中では読めない、`indexed`は三つまで（`anonymous`なら四つ）、シグネチャのハッシュがトピック一つ（`anonymous`ならなし）、参照型の`indexed`は値のKeccak-256ハッシュがトピック、`event.selector` | Solidity公式ドキュメント Contractsの節 Events（latestのバージョンで確認。v0.8.36のバージョンのページとは照合できなかった） | 2026-10-19 |
| ファイルレベルのイベント（0.8.22、2023-10-25）、イベントの`.selector`（0.8.15、2022-06-15）、ほかのコントラクトのイベントを名前つきで出す（0.8.21、2023-07-19） | Solidity Changelog.md | 2026-10-19 |
| ログのガス（G_log、G_logtopic、G_logdata） | イーサリアムのイエローペーパー 付録G | 2026-10-19 |
| ガス、サイズ、アドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント、Contracts: https://docs.soliditylang.org/en/latest/contracts.html （Eventsの節）
- Solidity Changelog（0.8.15、0.8.21、0.8.22）
- イーサリアムのイエローペーパー: https://ethereum.github.io/yellowpaper/paper.pdf
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
