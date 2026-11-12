# 第211講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | 二つのプロジェクトのfoundry.toml | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。二つのチェーンの様式の記入は、ローカルのanvil二つに既定のテスト用アカウントで送った。外部への接続は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| BridgedTestのガスとトレース | 直接実行（Marketのコピー、`forge test --offline --match-contract BridgedTest -vv`、`-vvvv`） | 2026-10-21 |
| Marketのコピーのテストの数とサイズ | 直接実行（Marketのコピーで、CIと同じ検査） | 2026-10-21 |
| GuardTestのガスとトレース | 直接実行（xchain、`forge test --offline --match-contract GuardTest -vv`、`-vvvv`） | 2026-10-21 |
| 二つのチェーンのアドレスと様式の欄の値 | 直接実行（ローカルのanvil二つ、`cast call`・`cast storage`） | 2026-10-21 |

実在するブリッジの様式の値は、この講義では埋めていない。上場を決める日に、そのブリッジのチェーンの値と公開ドキュメントで別に埋める。

## 参考資料

- EIP-1967 プロキシの保存の欄（実装の欄0x3608…2bbc、管理者の欄0xb531…6103）: https://eips.ethereum.org/EIPS/eip-1967
- ERC-20 トークン標準: https://eips.ethereum.org/EIPS/eip-20
- ブリッジのトークンの様式の8欄は、第208〜210講の五つの位置（送る側のコントラクト、中継、検証、受け取る側のコントラクト、受け取るアプリ）と資産モデルから出た欄である
- Foundry公式ドキュメント（`cast call`、`cast storage`、`cast rpc evm_increaseTime`）: https://getfoundry.sh/
