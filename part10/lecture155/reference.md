# 第155講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| anvilのトランザクションの順番 | `--order fees`（1.8.3の既定値） | `anvil --help`、直接実行 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0、MIT | `lib/openzeppelin-contracts/package.json`の`"version"` | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml` | 2026-10-20 |
| Market第155講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200、legacy・debugプロファイル | `market/foundry.toml` | 2026-10-20 |

付録のガス・ログ・ブロックの中の順番は、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIPの原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-20.md`、`ERCS/erc-721.md`）。ファイルの最終更新日はGitHub API | 2026-10-20 |
| OpenZeppelinの行番号 | OpenZeppelin Contracts 5.4.0のコピーの`token/ERC20/ERC20.sol`、`token/ERC20/utils/SafeERC20.sol` | 2026-10-20 |
| 競合のデモ・DocTokenの値 | 直接実行（ローカルのanvil、`cast send`・`cast receipt`・`cast logs`） | 2026-10-20 |
| テストのガス | 直接実行（`forge test --offline -vv`、`.gas-snapshot`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode` | 2026-10-20 |

## 参考資料

- ERC-20 Token Standard：34行（falseの扱い）、65・67〜68行（decimals）、100行（0の移動）、112・114行（transferFrom）、126・128〜130行（approveの上書きと先に0）、139行（allowance）、164行（Approval）：https://eips.ethereum.org/EIPS/eip-20
- ERC-721 Non-Fungible Token Standard、295行（ERC-20のallowanceの問題とOpenZeppelin issue #438への言及）：https://eips.ethereum.org/EIPS/eip-721
- ERC-2612 permit（承認のトランザクションなしで署名で預ける形、Marketに入れなかった根拠としてだけ言及）：https://eips.ethereum.org/EIPS/eip-2612
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- OpenZeppelin Contracts 5.4.0：`token/ERC20/ERC20.sol`（approve、transferFrom、`_update`、`_spendAllowance`、256〜260行のコメント）、`token/ERC20/utils/SafeERC20.sol`（safeIncreaseAllowance、safeDecreaseAllowance、forceApprove）。エラー`ERC20InsufficientAllowance(address,uint256,uint256)`のセレクタ`0xfb8f41b2`
- Foundry公式ドキュメント：https://getfoundry.sh/
- Solidity公式ドキュメントv0.8.36：https://docs.soliditylang.org/en/v0.8.36/
