# 第197講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果、ガス、サイズ、lintの警告は、上の環境で直接実行した結果である（anvilなし、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 利率の曲線・平均の窓の値 | `src/MarketMath.sol`（KINK、JUMP_RATE）、`src/Market.sol`（TWAP_WINDOW） | 2026-10-21 |
| Marketのサイズ・メタデータハッシュ | CIスクリプトの出力、`forge inspect`（直接実行） | 2026-10-21 |
| ガス記録 | `snapshots/Market.json`（直接実行で生成） | 2026-10-21 |
| テストのガス | `forge test --offline -vv`（直接実行） | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- EIP-20 トークン標準（`decimals`を読んで桁数を合わせる）: https://eips.ethereum.org/EIPS/eip-20
