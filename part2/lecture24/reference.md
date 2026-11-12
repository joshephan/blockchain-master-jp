# 第24講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-18 |
| forge-std | v1.17.0 (f3dae6e) | `forge init`の出力 | 2026-10-18 |
| solc | 0.8.30 | foundry.tomlの`solc = "0.8.30"` | 2026-10-18 |
| ローカルチェーン | anvil（`--hardfork paris`） | 直接実行 | 2026-10-18 |

付録のサイズ、ハッシュ、出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Foundryのバージョン | `forge --version` | 2026-10-18 |
| forge-stdのバージョン | `forge init`の出力 | 2026-10-18 |
| デフォルトのevm_version、最適化設定、出力の規模 | `forge config` | 2026-10-18 |
| Counterの実行用のコードのサイズ | `forge build --sizes` | 2026-10-18 |
| PUSH0の個数 | `cast disassemble` | 2026-10-18 |
| PUSH0が導入されたハードフォーク、Solidityでデフォルトで使われ始めたバージョン | Solidity v0.8.37の文書、Solidity Changelog 0.8.20 | 2026-10-20 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- foundry.tomlの設定項目全体: https://github.com/foundry-rs/foundry/blob/master/crates/config/README.md#all-options
- forge-stdリポジトリ: https://github.com/foundry-rs/forge-std
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidity Changelog 0.8.20: デフォルトのEVMバージョンをShanghaiに変更（PUSH0の使用開始）
