# 第115講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | 既定の設定、新しく立ち上げてから二つのバージョンを順にデプロイ | 直接実行 | 2026-10-19 |

付録のビルドエラーの原文、サイズ、ガス、セレクタ、トレースは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| `abstract`キーワードの必須化 | Solidity Changelog.md v0.6.0: "Syntax: Abstract contracts need to be marked explicitly as abstract by using the `abstract` keyword." | 2026-10-19 |
| インターフェースの関数での`override`の省略 | Solidity Changelog.md v0.8.8: "Inheritance: A function that overrides only a single interface function does not require the `override` specifier." | 2026-10-19 |
| インターフェースの中のenum・struct、インターフェースどうしの継承 | Solidity Changelog.md（"General: Allow `enum`s in interfaces."、"General: Allow `struct`s in interfaces."、"Allow interfaces to inherit from other interfaces"） | 2026-10-19 |
| サイズ、デプロイのgasUsed、ランタイムコードの比較 | 直接実行（`forge build --sizes`、`forge inspect`、`cast receipt`、`cast code`二回をバイト単位で照合） | 2026-10-19 |
| セレクタ・topic0 | 直接実行（`forge inspect`、`cast keccak`） | 2026-10-19 |
| テスト | 直接実行（`forge test`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Abstract Contractsの節: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/abstract-contracts.rst
  - "Contracts must be marked as abstract when at least one of their functions is not implemented or when they do not provide arguments for all of their base contract constructors."
  - "Such abstract contracts can not be instantiated directly. This is also true, if an abstract contract itself does implement all defined functions."
- Solidity公式ドキュメント v0.8.36 Interfacesの節: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/interfaces.rst
  - 五つの制約（ほかのコントラクトの継承は不可・インターフェースどうしは可、関数はexternal、コンストラクタ不可、状態変数不可、modifier不可）
  - "Interfaces are basically limited to what the Contract ABI can represent"
  - "All functions declared in interfaces are implicitly `virtual` and any functions that override them do not need the `override` keyword."
- Solidity Changelog（v0.6.0、v0.8.8）: https://github.com/argotorg/solidity/blob/v0.8.36/Changelog.md
- Foundry公式ドキュメント: https://getfoundry.sh/
