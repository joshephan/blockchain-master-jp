# 第19講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-17 |
| solc | 0.7.6+commit.7338295f, 0.8.30+commit.73712a01 | コンパイラの実行ファイルの`--version` | 2026-10-17 |
| ローカルチェーン | anvil（デフォルトアカウントでデプロイ） | 直接実行 | 2026-10-17 |

付録のバイト数、ハッシュ、ガス使用量は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 現在のSolidityの最新バージョン | SolidityのGitHubリリース一覧（github.com/argotorg/solidity releases） | 2026-10-20 |
| Foundry（forge）のバージョン | `forge --version` | 2026-10-17 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidity公式ドキュメントの既知のバグ一覧（バグ名、条件、最初に入ったバージョンと修正されたバージョン、深刻度）。バージョンごとにまとめた一覧も別にある
- Solidityのソースリポジトリ: https://github.com/argotorg/solidity
- Solidity 0.8.0（2020年12月）: 算術のオーバーフロー・アンダーフローがデフォルトでリバートになった
- Vyperコンパイラのバグとカーブ（Curve）のプールの事件（2023年7月30日）: Vyper 0.2.15、0.2.16、0.3.0でコンパイルした複数のプールから資金が抜き取られた
- npmパッケージsolc（solc-js）
- Foundry公式ドキュメント: https://getfoundry.sh/
