# 第168講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（200）・via-IRオン・evm osaka | `code/vulns/foundry.toml`、`code/market/foundry.toml` | 2026-10-21 |
| Market | 第42章の終わりのバージョン（第164講のバージョン）のsrcのまま、テスト`Reentrancy44.t.sol`を追加 | 第164講のバージョンと比較 | 2026-10-21 |

付録のガス、トレース、lintの警告は、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| トイの金庫のテストのガスとトレース | 直接実行（`forge test --match-test test_goodVaultBlocks -vvvv`） | 2026-10-21 |
| Marketのテストのガスとトレース | 直接実行（`forge test --match-contract Reentrancy44Test -vvvv`） | 2026-10-21 |
| Marketのlintの警告 | 直接実行（`forge lint --offline`） | 2026-10-21 |
| OpenZeppelinの版、transientのロックの条件 | ReentrancyGuardTransient.solの冒頭コメントとNOTE | 2026-10-21 |
| Solidityのドキュメントの行番号 | Solidity v0.8.36のドキュメント原本（rst） | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Security ConsiderationsのReentrancyの節（`security-considerations.rst` 49〜131行。52〜54行は制御が渡るという説明、103〜116行は送る前に取り分を0にするFundの例、118〜122行はChecks-Effects-Interactionsの説明）: https://docs.soliditylang.org/en/v0.8.36/security-considerations.html
- Solidity公式ドキュメント v0.8.36、Common PatternsのWithdrawal from Contracts（`common-patterns.rst` 57〜58行 "Remember to zero the pending refund before sending to prevent reentrancy attacks"）: https://docs.soliditylang.org/en/v0.8.36/common-patterns.html
- 同じドキュメントの原本ファイル: https://github.com/argotorg/solidity/blob/v0.8.36/docs/security-considerations.rst, https://github.com/argotorg/solidity/blob/v0.8.36/docs/common-patterns.rst
- OpenZeppelin Contracts 5.4.0、`contracts/utils/ReentrancyGuardTransient.sol`（v5.3.0で更新、34〜52行は`nonReentrant`と`_nonReentrantBefore`・`_nonReentrantAfter`、NOTE "This variant only works on networks where EIP-1153 is available."）
- EIP-1153, Transient storage opcodes: https://eips.ethereum.org/EIPS/eip-1153
- The DAO（2016年）：再入のバグで大金が抜け出し、イーサリアムはハードフォークでそのお金を移した。ハードフォークに従ったチェーン（イーサリアム）と従わなかったチェーン（イーサリアムクラシック）に分かれた。
