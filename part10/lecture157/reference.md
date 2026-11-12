# 第157講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 (`0.8.30+commit.73712a01.Windows.msvc`) | `solc --version`、foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0、MIT | `lib/openzeppelin-contracts/package.json`の`"version"` | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml` | 2026-10-20 |
| Market第157講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200・evm osaka、legacy・debugプロファイル | `market/foundry.toml` | 2026-10-20 |

付録のガス・レシート・ログは、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIPの原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-1155.md`）。ファイルの最終更新日はGitHub APIのコミットの日付 | 2026-10-20 |
| まとめての送信のガス、巻き戻ったまとまりのレシート | 直接実行（ローカルのanvil、`cast send --json`のgasUsed、`cast receipt`） | 2026-10-20 |
| セレクタ・エラー | `cast sig`、forgeのテストのログ | 2026-10-20 |
| テストのガス | 直接実行（`forge test`、`.gas-snapshot`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode` | 2026-10-20 |

## 参考資料

- ERC-1155 Multi Token Standard（status Final、created 2018-06-17、requires 165）：15・19・25・27行（動機）、33・35行（関数はすべてMUST、ERC-165 `0xd9b67a26`）、56・68行（TransferSingle・TransferBatch）、103・266・269行（まとまりの規則）、122・130行（balanceOf・balanceOfBatch）、165〜168・180〜183行（受け取る関数）、201〜209行（受け取る側の三つの場合）、580・599・601・603・607・611・613・636・644・648行（設計の根拠）：https://eips.ethereum.org/EIPS/eip-1155
- ERC-20 Token Standard（balanceOfの比較）：https://eips.ethereum.org/EIPS/eip-20
- ERC-721 Non-Fungible Token Standard（受け取る側の確認の比較）：https://eips.ethereum.org/EIPS/eip-721
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- OpenZeppelin Contracts 5.4.0：`token/ERC1155/ERC1155.sol`、`token/ERC1155/utils/ERC1155Holder.sol`。エラー`ERC1155InsufficientBalance(address,uint256,uint256,uint256)` `0x03dee4c5`、`ERC1155InvalidReceiver(address)` `0x57f447ce`
- Foundry公式ドキュメント：https://getfoundry.sh/
- Solidity公式ドキュメントv0.8.36：https://docs.soliditylang.org/en/v0.8.36/
