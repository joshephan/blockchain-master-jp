# 第156講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0、MIT | `lib/openzeppelin-contracts/package.json`の`"version"` | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml` | 2026-10-20 |
| Market第156講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200、legacy・debugプロファイル | `market/foundry.toml` | 2026-10-20 |

付録のガス・ログ・トレースは、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIP-721の原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-721.md`）。ファイルの最終更新日はGitHub API | 2026-10-20 |
| OpenZeppelinの行番号 | OpenZeppelin Contracts 5.4.0のコピーの`token/ERC721/ERC721.sol`、`token/ERC721/utils/ERC721Utils.sol` | 2026-10-20 |
| セレクタ・トピック | `cast sig`、forgeのテストのログ | 2026-10-20 |
| 移動・デプロイのガス、ログ | 直接実行（ローカルのanvil、`cast send`・`cast logs`） | 2026-10-20 |
| テストのガス | 直接実行（`forge test`、`.gas-snapshot`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode`、`src/Market.sol` | 2026-10-20 |

## 参考資料

- ERC-721 Non-Fungible Token Standard（status Final、created 2018-01-24、requires 165）：27行（NFTの区別）、55行（Transferイベントのindexed三つ）、81〜88行（safeTransferFrom）、95〜101行（dataのないsafeTransferFrom）、103〜105行（transferFrom）、155行（wallet interface）、158行（ERC721TokenReceiverのID 0x150b7a02）、161〜165行（onERC721Received）、273行（tokenId）、295行（allowanceなし）、363行（決まった4バイト）：https://eips.ethereum.org/EIPS/eip-721
- ERC-20 Token Standard（Transferイベントとセレクタの比較）：https://eips.ethereum.org/EIPS/eip-20
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- OpenZeppelin Contracts 5.4.0：`token/ERC721/ERC721.sol`（safeTransferFrom 133〜136行、`_update` 216〜245行）、`token/ERC721/utils/ERC721Utils.sol`（checkOnERC721Received 32〜45行）、`IERC721Errors.ERC721InvalidReceiver`
- Foundry公式ドキュメント：https://getfoundry.sh/
- Solidity公式ドキュメントv0.8.36：https://docs.soliditylang.org/en/v0.8.36/
