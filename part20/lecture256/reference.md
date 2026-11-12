# 第256講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` `"version"` | 2026-10-21 |

付録のテスト結果、トレース、ハッシュ、サイズ、ガスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| OpenZeppelinのファイル四つのハッシュ | 直接実行（`sha256sum`） | 2026-10-21 |
| Marketのサイズ、メタデータハッシュ | 直接実行（`forge build --offline --sizes`、ビルド成果物のメタデータの尾） | 2026-10-21 |
| 測った呼び出し五つ | 直接実行（`test/Gas.t.sol`、`vm.lastFrameGas().gasTotalUsed`） | 2026-10-21 |
| ランタイムの命令数 | 直接実行（メタデータを除いたランタイムの本体を、PUSHのデータを飛ばしながら数えた） | 2026-10-21 |
| テスト数 | 直接実行（`forge test --offline`） | 2026-10-21 |
| EIP-20の原文 | EIP-20 | 2026-10-21 |

## 参考資料

- EIP-20 Token Standard（OPTIONAL: name, symbol, decimals, "interfaces and other contracts MUST NOT expect these values to be present."）: https://eips.ethereum.org/EIPS/eip-20
- ERC-165 Standard Interface Detection: https://eips.ethereum.org/EIPS/eip-165
- ERC-721 Non-Fungible Token Standard: https://eips.ethereum.org/EIPS/eip-721
- ERC-1155 Multi Token Standard: https://eips.ethereum.org/EIPS/eip-1155
- ERC-4626 Tokenized Vaults: https://eips.ethereum.org/EIPS/eip-4626
- ERC-1967 Proxy Storage Slots: https://eips.ethereum.org/EIPS/eip-1967
- EIP-2612 Permit Extension for EIP-20 Signed Approvals: https://eips.ethereum.org/EIPS/eip-2612
- EIP-7702 Set Code for EOAs: https://eips.ethereum.org/EIPS/eip-7702
- ERC-1271 Standard Signature Validation Method for Contracts: https://eips.ethereum.org/EIPS/eip-1271
- OpenZeppelin Contracts 5.4.0 `contracts/token/ERC20/utils/SafeERC20.sol`（`safeTransfer` 33行、`safeTransferFrom` 41行、`_callOptionalReturn` 173〜191行、アセンブリブロック176〜186行）、`token/ERC20/IERC20.sol`、`token/ERC20/extensions/IERC20Metadata.sol`、`interfaces/IERC1363.sol`、テストで使った`token/ERC721/ERC721.sol`、`token/ERC1155/ERC1155.sol`
- 第50章の自己監査の指摘事項L-01（手数料を差し引くトークンを上場すると最後の引き出しが巻き戻る）と修正の提案
- Foundry公式ドキュメント（remapping、`auto_detect_remappings`）: https://getfoundry.sh/
