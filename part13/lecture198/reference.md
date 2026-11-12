# 第198講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

テスト結果、ガス、サイズ、anvilのブロック内の順番は、上の環境で直接実行した結果である（ローカルのanvil、anvilの既定のテスト用アカウントだけを使用、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 清算の定数 | `src/Market.sol` 338〜341行目 | 2026-10-21 |
| anvilのデモ・並べ方の観察 | ローカルのanvilで自動マイニングを切って二つのトランザクションを送り、ブロックを一つ作って`cast receipt`で読む（直接実行） | 2026-10-21 |
| Marketのサイズ・メタデータハッシュ | CIスクリプトの出力、`forge inspect`（直接実行） | 2026-10-21 |
| ガス記録 | `snapshots/Market.json`（直接実行で生成） | 2026-10-21 |
| テスト結果 | `forge test --offline --match-contract LiquidateTest`・`Econ198Test`（直接実行） | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント（anvil）: https://getfoundry.sh/
- EIP-20 トークン標準: https://eips.ethereum.org/EIPS/eip-20
