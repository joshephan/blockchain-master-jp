# 第20講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-17 |
| solc | 0.7.6+commit.7338295f, 0.8.30+commit.73712a01 | コンパイラの実行ファイルの`--version` | 2026-10-17 |
| オペレーティングシステム | Windows | 直接実行 | 2026-10-17 |

付録の出力は、すべて上記の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 現在のSolidityの最新バージョン、1.0リリースの有無 | SolidityのGitHubリリース一覧（github.com/argotorg/solidity releases） | 2026-10-20 |
| 主要ライブラリのpragma範囲の例 | OpenZeppelin Contracts v5.7.0リポジトリのERC20.sol、IERC20.sol | 2026-10-20 |
| 実行環境 | 直接実行 | 2026-10-17 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- Solidityのソースリポジトリ: https://github.com/argotorg/solidity
- OpenZeppelin Contracts 5.7.0: https://github.com/OpenZeppelin/openzeppelin-contracts/tree/v5.7.0
- Solidity 0.8.0（2020年12月）: 2桁目が変わって互換性が壊れた変更の例
- npmのキャレット（`^`）範囲の規則: 先頭の数字が0なら2番目の数字で止まる
- Foundry公式ドキュメント: https://getfoundry.sh/
