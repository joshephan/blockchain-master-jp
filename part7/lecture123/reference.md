# 第123講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-19 |
| solc | 0.8.30、既定（レガシー）のパイプライン | 各バージョンのfoundry.toml | 2026-10-19 |
| optimizer | 切ったバージョンは既定値（切る）、入れたバージョンは`optimizer = true`、`optimizer_runs = 200` | 各バージョンのfoundry.toml | 2026-10-19 |
| anvilのハードフォーク | 既定値（latest、Prague以降の規則） | 測定値と手計算が一致 | 2026-10-19 |

付録のサイズ・ガス・出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| calldataの下限値の式 | EIP-7623（Pectraハードフォーク）、もとのcalldataの値はEIP-2028。測定値で確認 | 2026-10-19 |
| 合計の計算・状態変数の読み取り・リバートのガス | `cast call --trace`のいちばん上の行、`cast estimate`、要素100は`cast send`のレシートでも確認 | 2026-10-19 |
| サイズ | `forge build --offline --force --sizes` | 2026-10-19 |
| ランタイムコードの比較 | `forge inspect deployedBytecode` | 2026-10-19 |
| calldataの手計算 | `cast calldata`で作ったバイトを数えて計算 | 2026-10-19 |
| Marketの四つのバージョンのgasUsed | バージョンごとに新しいanvil（ブロック間隔1秒）、MockTokenのあとにMarketをデプロイしてから直接実行 | 2026-10-19 |
| Marketの四つのバージョンの実行ガス、2の200乗 | `cast call --trace`、`cast call` | 2026-10-19 |
| テスト | `forge test --offline` | 2026-10-19 |

## 参考資料

- EIP-7623（calldataの下限値）: https://eips.ethereum.org/EIPS/eip-7623
- EIP-2028（calldataのバイトのガス16）: https://eips.ethereum.org/EIPS/eip-2028
- Foundry公式ドキュメント: https://getfoundry.sh/
