# 第107講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | 既定の設定、Marketのコンストラクタはアカウント0番・5e16・80、addAssetの比率75 | 直接実行 | 2026-10-19 |

付録のアドレス、ハッシュ、ガスの数字と出力は、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| gasUsed | 直接実行（`cast send --json`のレシート） | 2026-10-19 |
| LOGのガス | 第105講・第106講で測った規則の値、Indexed・Anonの差は直接実行 | 2026-10-19 |
| Marketのサイズ | 直接実行（`forge build --sizes`） | 2026-10-19 |
| topic0 | 直接実行（`cast sig-event`、`forge inspect … events`） | 2026-10-19 |
| `vm.recordLogs`の動作 | Foundryのドキュメント cheatcode `recordLogs`の項目（"Tells the VM to start recording all emitted events."）、リバートした呼び出しの部分は直接実行（Rebuild・Recのテスト） | 2026-10-19 |
| `anvil_rollback` | 直接実行。ethereum.orgのJSON-RPCのドキュメントのメソッド一覧にない | 2026-10-19 |
| `cast logs --query-size` | `cast logs --help`（1.8.3） | 2026-10-19 |
| RPCサービスのeth_getLogsの制限 | Alchemyのドキュメント eth_getLogsの項目、Infuraのドキュメント eth_getLogsの項目（2026-06-18更新）、QuickNodeのドキュメント eth_getLogsの項目 | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Contractsの章（Eventsの節、`anonymous`）: https://docs.soliditylang.org/en/v0.8.36/contracts.html
  - "The hash of the signature of the event is one of the topics, except if you declared the event with the `anonymous` specifier."
  - "The Log and its event data are not accessible from within contracts (not even from the contract that created them)."
- Ethereum JSON-RPCの仕様（ethereum.orgの開発者向けドキュメント）：logオブジェクトの`removed`は、チェーンの再編成で消されたログのとき`true`
- Foundry公式ドキュメント（cheatcode `recordLogs`、`cast logs`、anvil）: https://getfoundry.sh/
- forge-std（`Vm.Log`、`vm.recordLogs`、`vm.getRecordedLogs`）
