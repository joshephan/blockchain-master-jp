# 第169講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30、optimizerオン（200）・via-IRオン・evm osaka | `code/vulns/foundry.toml`、`code/market/foundry.toml` | 2026-10-20 |
| Market | 第42章の終わりのバージョン（第164講のバージョン）のsrcのまま | 第164講のバージョンと比較 | 2026-10-20 |

付録のガス、priceの値、トレースは、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| トイの金庫のテストのガス、priceの値 | 直接実行（`forge test --match-contract Vault169Test`、`Fixed169Test`、`-vvvv`のトレース） | 2026-10-20 |
| Marketのテストのガスとトレース | 直接実行（`forge test --match-contract PullTest`、`--match-test test_tokenSeesDebitedLedger -vvvv`） | 2026-10-20 |
| OpenZeppelinの版、transientのロックの条件 | 各ファイルの冒頭コメントとNOTE | 2026-10-20 |
| Solidityのドキュメントの行番号 | Solidity v0.8.36のドキュメント原本（rst） | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Security ConsiderationsのReentrancyの節128〜131行（再入はイーサの送金だけでなく、ほかのコントラクトの関数呼び出しすべてで起き、複数のコントラクトの状況も考えるべきだという段落）: https://docs.soliditylang.org/en/v0.8.36/security-considerations.html
- 同じドキュメントの原本ファイル: https://github.com/argotorg/solidity/blob/v0.8.36/docs/security-considerations.rst
- OpenZeppelin Contracts 5.4.0
  - `contracts/utils/ReentrancyGuard.sol`（v5.1.0で更新）：`nonReentrant`、`_nonReentrantBefore`、`_reentrancyGuardEntered`
  - `contracts/utils/ReentrancyGuardTransient.sol`（v5.3.0で更新）
  - `contracts/token/ERC20/extensions/ERC4626.sol`（v5.4.0で更新）240〜245行の`_deposit`、267〜272行の`_withdraw`のコメント（ERC-777のフックで起きる再入を基準に、移すこととミント・バーンの順番を決めている）
- EIP-1153, Transient storage opcodes: https://eips.ethereum.org/EIPS/eip-1153
- ERC-777, Token Standard: https://eips.ethereum.org/EIPS/eip-777
- ERC-721, Non-Fungible Token Standard: https://eips.ethereum.org/EIPS/eip-721
- ERC-1155, Multi Token Standard: https://eips.ethereum.org/EIPS/eip-1155
