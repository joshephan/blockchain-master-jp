# 第175講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（200）・via-IRオン・evm osaka | `code/vulns/foundry.toml`、`code/market/foundry.toml` | 2026-10-21 |
| Market | 第42章の終わりのバージョン（第164講のバージョン）のsrcのまま、テスト`Order45.t.sol`を追加 | 基準のバージョンと比較 | 2026-10-21 |

付録の番号、seed、ガス、トレースは、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Solidityのドキュメントの行番号 | Solidity v0.8.36のドキュメント原本（rst） | 2026-10-21 |
| prevrandao | EIP-4399、Solidityのドキュメント85・88行 | 2026-10-21 |
| blockhashの範囲 | Solidityのドキュメント76・119〜121行、直接実行（`test_futureHashZero`） | 2026-10-21 |
| メインネットのブロックの時刻のルール | イーサリアムの合意仕様 | 2026-10-21 |
| forgeのテストのブロック | 直接実行（`Random175ExtraTest`のログ） | 2026-10-21 |
| テストのガス（vulns・market） | 直接実行（`forge test --match-contract Random175Test`、`Random175ExtraTest`、`Order45Test`） | 2026-10-21 |
| トイのアドレス | 直接実行（`-vvvv`のトレース） | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variables: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
  - 76行 blockhash（"hash of the given block when `blocknumber` is one of the 256 most recent blocks; otherwise returns zero"）
  - 88行 prevrandao、89行 timestamp
  - 109〜117行 "Do not rely on `block.timestamp` or `blockhash` as a source of randomness, unless you know what you are doing."
  - 119〜121行 最近の256ブロックの外は0
- Solidity公式ドキュメント v0.8.36、Security ConsiderationsのPrivate Information and Randomness（`security-considerations.rst` 41〜47行）: https://docs.soliditylang.org/en/v0.8.36/security-considerations.html
- 同じドキュメントの原本ファイル: https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst, https://github.com/argotorg/solidity/blob/v0.8.36/docs/security-considerations.rst
- EIP-4399, Supplant DIFFICULTY opcode with PREVRANDAO: https://eips.ethereum.org/EIPS/eip-4399
