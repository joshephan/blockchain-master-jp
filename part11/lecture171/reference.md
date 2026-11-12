# 第171講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-20 |
| solc | 0.8.30、optimizerオン（200）・via-IRオン・evm osaka | `code/vulns/foundry.toml`、`code/market/foundry.toml` | 2026-10-20 |
| Market | 第42章の終わりのバージョン（第164講のバージョン）のsrcのまま、テスト`BadTokens44.t.sol`を追加 | 第164講のバージョンと比較 | 2026-10-20 |

付録のガス、トレース、テストの中のアドレスは、すべて上の環境で直接実行した結果である。実行後の`snapshots/Market.json`は基準のバージョンと同じだった。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| OpenZeppelinの行番号 | OpenZeppelin Contracts 5.4.0の原本ファイル | 2026-10-20 |
| EIP-20の行番号 | EIP-20本文（マークダウンの原文） | 2026-10-20 |
| テストのガス（vulns） | 直接実行（`forge test --match-contract Tokens171Test -vvv`） | 2026-10-20 |
| テストのガス（market） | 直接実行（`forge test --match-contract "BadTokens44Test|DonationTest|StandardTest" -vvv`） | 2026-10-20 |
| トイトークンのアドレス | 直接実行（`-vvvv`のトレース） | 2026-10-20 |

## 参考資料

- EIP-20, Token Standard（103行 `function transfer(address _to, uint256 _value) public returns (bool success)`、34行 "Callers MUST handle `false` from `returns (bool success)`. Callers MUST NOT assume that `false` is never returned!"）: https://eips.ethereum.org/EIPS/eip-20
- OpenZeppelin Contracts 5.4.0
  - `contracts/token/ERC20/utils/SafeERC20.sol`：22行`SafeERC20FailedOperation`、33〜35行`safeTransfer`、173〜191行`_callOptionalReturn`
  - `contracts/token/ERC20/extensions/ERC4626.sol` 247行 `SafeERC20.safeTransferFrom(IERC20(asset()), caller, address(this), assets);`
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
