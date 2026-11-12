# 第113講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | 既定の設定、バージョンごとに新しく立ち上げる | 直接実行 | 2026-10-19 |

付録のログ、線形化の順番、ビルドエラーの原文、サイズ、ガスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| modifierのオーバーライド | Solidity公式ドキュメント v0.8.36 Inheritanceの節 Modifier Overriding（"`virtual` modifiers are deprecated and scheduled for removal."）、第111講で直接ビルド | 2026-10-19 |
| 線形化の順番のフィールド | 直接ビルド（`forge build --ast`） | 2026-10-19 |
| Super.sol・Marketのサイズ | 直接実行（`forge build --sizes`） | 2026-10-19 |
| MarketのgasUsed | 直接実行（`forge create --json`、`cast send --json`） | 2026-10-19 |
| Marketの三つの変形、テスト | 直接実行（`forge build --sizes`、`forge test`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Contractsの章（Inheritanceの節）: https://docs.soliditylang.org/en/v0.8.36/contracts.html
  - "it calls this function on the next base contract in the final inheritance graph"
  - "The actual function that is called when using super is not known in the context of the class where it is used"
  - "`super.f(..)` will use JUMP and not a message call"
- SolidityのInheritanceの節の原文（Modifier Overridingを含む）: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/inheritance.rst
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std（`console.log`、`vm.expectRevert`）
