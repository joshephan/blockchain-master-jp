# 第159講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0、MIT | `lib/openzeppelin-contracts/package.json`の`"version"`、ERC165Checker.solの冒頭のコメント | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml` | 2026-10-20 |
| Market第159講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | `market/foundry.toml` | 2026-10-20 |

付録のインターフェースID・トレース・テストのガスは、すべて上の環境のforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIPの原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`、ethereum/EIPsのコミット`0ce679f4654ba4d120c97113626f320475e22fa9` | 2026-10-19 |
| ファイルの最終更新日 | GitHub APIのコミットの日付 | 2026-10-19 |
| 大文字の語の数 | 直接数えた（上のEIPの原文のコピー、数える規則は時効性の表） | 2026-10-20 |
| インターフェースID | 直接実行（`type(I).interfaceId`、test_ids・Ids159Test）、`cast sig` | 2026-10-20 |
| GasHogのガス | 直接実行（`forge test -vvvv`、optimizerオフのデモ用ビルド） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法、ローカルのanvil） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode`、`src/Market.sol` | 2026-10-20 |
| 120バイトを超える行 | `LC_ALL=C awk 'length($0)>120'` | 2026-10-20 |

## 参考資料

- ERC-165 Standard Interface Detection（status Final、created 2018-01-23、requires 214）：33・35・53行（インターフェースID）、40〜50行（Solidity101の例）、73・77〜80・82行（supportsInterfaceが返す値と30,000ガス）、88〜92行（確認の手順）：https://eips.ethereum.org/EIPS/eip-165
- EIP-1：86行（Final）、100〜111行（EIPが備えるべき部分）、609〜613行（RFC 2119の語）：https://eips.ethereum.org/EIPS/eip-1
- ERC-20 Token Standard：24・34・98・114行：https://eips.ethereum.org/EIPS/eip-20
- ERC-721 Non-Fungible Token Standard：252・287・295・363行：https://eips.ethereum.org/EIPS/eip-721
- ERC-1155 Multi Token Standard：601〜603・620〜624行（ハイブリッドな実装のsupportsInterfaceの確認）：https://eips.ethereum.org/EIPS/eip-1155
- ERC-4626 Tokenized Vaults：555〜557・587〜605行：https://eips.ethereum.org/EIPS/eip-4626
- RFC 2119、RFC 8174（EIP-1が従うよう勧める語の定義）
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- ethereum/EIPsリポジトリ、引用の基準のコミット：https://github.com/ethereum/EIPs/tree/0ce679f4654ba4d120c97113626f320475e22fa9
- OpenZeppelin Contracts 5.4.0：`utils/introspection/ERC165Checker.sol`（17・22・36・108・117・122行）、IERC165・IERC721・IERC721Receiver・IERC1155・IERC1155Receiver・IERC4626のインターフェース
- Foundry公式ドキュメント：https://getfoundry.sh/
- Solidity公式ドキュメントv0.8.36：https://docs.soliditylang.org/en/v0.8.36/
