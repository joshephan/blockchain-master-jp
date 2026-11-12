# 第154講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 (`0.8.30+commit.73712a01.Windows.msvc`) | `solc --version`、foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0、MIT | `lib/openzeppelin-contracts/package.json`の`"version"`、`contracts/token/ERC20/ERC20.sol` 2行目`(last updated v5.4.0)` | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml` | 2026-10-20 |
| Market第154講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200・evm osaka、legacy・debugプロファイル | `market/foundry.toml` | 2026-10-20 |

付録のガス・アドレス・ログは、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIPの原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-20.md`、`ERCS/erc-721.md`）、ethereum/EIPsのコミット`0ce679f4654ba4d120c97113626f320475e22fa9`（`EIPS/eip-1.md`）。ファイルの最終更新日はGitHub APIのコミットの日付 | 2026-10-20 |
| デプロイのガス・anvilのアドレス・ログ | 直接実行（ローカルのanvil、既定のテスト用アカウント） | 2026-10-20 |
| テストのガス | 直接実行（`forge test`、`.gas-snapshot`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法：ローカルのanvilにMockToken・Marketをデプロイしたあと六つの呼び出し） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode` | 2026-10-20 |

## 参考資料

- EIP-1 (EIP Purpose and Guidelines)、28行のERCの定義、605行の`ERC-X`の表記：https://eips.ethereum.org/EIPS/eip-1
- ERC-20 Token Standard（status Final、created 2015-11-19）、13・18〜19・24・33行、関数九つとイベント二つ（27〜168行）、OPTIONAL 42・55・68行、イベント157・167行、最後の行のCC0：https://eips.ethereum.org/EIPS/eip-20
- ERC-721 Non-Fungible Token Standard、インターフェース44〜152行、329行（同じ名前と記号）：https://eips.ethereum.org/EIPS/eip-721
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- ethereum/EIPsリポジトリ、引用の基準のコミット：https://github.com/ethereum/EIPs/tree/0ce679f4654ba4d120c97113626f320475e22fa9
- OpenZeppelin Contracts 5.4.0：`token/ERC20/ERC20.sol`、`token/ERC20/IERC20.sol`、`LICENSE`（MIT）。エラー`ERC20InsufficientAllowance(address,uint256,uint256)`のセレクタ`0xfb8f41b2`
- Foundry公式ドキュメント：https://getfoundry.sh/
- Solidity公式ドキュメントv0.8.36：https://docs.soliditylang.org/en/v0.8.36/
