# 第210講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | foundry.toml | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。二つのチェーンのデモは、ローカルのanvil二つに既定のテスト用アカウントで送った。実際の鍵・実際の資金・外部への接続は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| AssetsTestのガス、トレースの番号・リバートの理由 | 直接実行（`forge test --offline --match-contract AssetsTest -vv`、`-vvvv`） | 2026-10-21 |
| 二つのチェーンのアドレスと突き合わせの値 | 直接実行（ローカルのanvil二つ） | 2026-10-21 |
| ERC20の残高のマッピング | OpenZeppelin Contracts 5.4.0 `contracts/token/ERC20/ERC20.sol` | 2026-10-21 |
| 発行体が直接発行して燃やす例 | Circle公式ドキュメント developers.circle.com/cctp（"burn-and-mint"の文言） | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0 `ERC20.sol`: `_balances`のマッピング、`_mint`、`_burn`
- Circle CCTP公式ドキュメント（developers.circle.com/cctp）：発行体があるチェーンで燃やし、ほかのチェーンで発行する方式の例
- ステーブルコインを見るときに問う三つ（裏に何があるか、それがチェーンの中にあるか、償還すると誰が何を払い出すか）は第200講で扱う
- Foundry公式ドキュメント（`cast call`）: https://getfoundry.sh/
