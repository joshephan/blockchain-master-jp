# 第106講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のアドレス、ハッシュ、ガスの数字と出力は、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| LOGのガスの規則と測った値 | 直接実行（`code/gas/test/LogGas.t.sol`の`forge test -vv`の出力） | 2026-10-19 |
| Plain・Indexed・LabelのgasUsed | 直接実行（`cast send --json`のレシート） | 2026-10-19 |
| Marketのサイズ | 直接実行（`forge build --sizes`） | 2026-10-19 |
| Marketのガス | 直接実行（`forge test --gas-report --match-contract StatusTest`、`cast send --json`） | 2026-10-19 |
| シグネチャの一覧を照会するコマンド | `cast 4byte-event --help`の出力（外部サービスなので実行していない） | 2026-10-19 |
| 公式ドキュメントのEventsの節 | Solidity公式ドキュメント Contractsの章 Eventsの節（v0.8.30のバージョンで確認） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidity公式ドキュメント Contractsの章（Eventsの節を含む）: https://docs.soliditylang.org/en/v0.8.36/contracts.html
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std（`Vm.Log`、`vm.recordLogs`、`vm.getRecordedLogs`、`vm.expectEmit`）
