# 第42講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge、cast、anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-19 |
| solc | 0.8.30+commit.73712a01 | `solc --version`、foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | 1.17.0 | `lib/forge-std` | 2026-10-19 |
| OpenZeppelin Contracts | v5.4.0 | `lib/openzeppelin-contracts` | 2026-10-19 |

付録の出力と集計は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| SPDXのルール | Solidity公式ドキュメントv0.8.36、Layout of a Solidity Source FileのSPDX License Identifierの節 | 2026-10-19 |
| Foundryが既定で隠す警告 | `forge config`の`ignored_error_codes` | 2026-10-19 |
| SPDXが入ったバージョン | Solidity公式ドキュメントv0.6.7・v0.6.8のLayout of a Solidity Source File、SolidityリポジトリのChangelog.md | 2026-10-19 |
| ライブラリごとのSPDXの値 | `grep -rh`による集計（forge-std 1.17.0、OpenZeppelin v5.4.0） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidity Changelog.md（0.6.8、0.8.9の項目）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- SPDXライセンスリスト: https://spdx.org
- forge-std 1.17.0、OpenZeppelin Contracts v5.4.0
- Foundry公式ドキュメント: https://getfoundry.sh/
