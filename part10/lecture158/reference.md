# 第158講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0、MIT | `lib/openzeppelin-contracts/package.json`の`"version"` | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml` | 2026-10-20 |
| Market第158講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200、legacy・debugプロファイル | `market/foundry.toml` | 2026-10-20 |

付録の金庫の値とテストのガスは、すべて上の環境のforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIP-4626の原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-4626.md`）。ファイルの最終更新日はGitHub API | 2026-10-20 |
| OpenZeppelinの行番号 | OpenZeppelin Contracts 5.4.0のコピーの`token/ERC20/extensions/ERC4626.sol`、`interfaces/IERC4626.sol` | 2026-10-20 |
| Vaultの値・テストのガス | 直接実行（`forge test --offline -vv`） | 2026-10-20 |
| セレクタ・トピック | test_selectorsAndEvents、`cast sig` | 2026-10-20 |
| Marketのテストのガス | 直接実行（`.gas-snapshot`、`forge test`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法、ローカルのanvil） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode`、`src/Market.sol` | 2026-10-20 |
| 120バイトを超える行 | `LC_ALL=C awk 'length($0)>120'` | 2026-10-20 |

## 参考資料

- ERC-4626 Tokenized Vaults（status Final、created 2021-12-22、requires 20, 2612）：4行（タイトル）、16〜19行（Abstract）、23〜27行（Motivation）、31〜34行（持ち分はEIP-20）、43〜46行（asset・shareの定義）、74〜82行（totalAssets）、555〜557行（計算と配分を空けておく）、587〜588行（実装の検討の勧め）、599〜605行（丸めの方向）：https://eips.ethereum.org/EIPS/eip-4626
- ERC-20 Token Standard（持ち分のトークンが従う標準）：https://eips.ethereum.org/EIPS/eip-20
- ERC-2612（EIP-4626の冒頭のrequires）：https://eips.ethereum.org/EIPS/eip-2612
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- OpenZeppelin Contracts 5.4.0：`token/ERC20/extensions/ERC4626.sol`（48行 継承、49行 `using Math for uint256`、115〜118行 totalAssets、121〜167行 換算・プレビュー、225〜234行 `_convertToShares`・`_convertToAssets`、247行 `SafeERC20.safeTransferFrom`、263〜265行 `_spendAllowance`、279行 `_decimalsOffset`）、`interfaces/IERC4626.sol`
- Foundry公式ドキュメント：https://getfoundry.sh/
- Solidity公式ドキュメントv0.8.36：https://docs.soliditylang.org/en/v0.8.36/
