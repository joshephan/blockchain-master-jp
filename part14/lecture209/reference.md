# 第209講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | foundry.toml | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。二つのチェーンのデモは、ローカルのanvil二つに既定のテスト用アカウントで送った。実際の鍵・外部への接続は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| VerifyTestのガス、トレースの番号・アドレス | 直接実行（`forge test --offline --match-contract VerifyTest -vv`、`-vvvv`） | 2026-10-21 |
| 二つのチェーンの監視者のデモの値 | 直接実行（ローカルのanvil二つ） | 2026-10-21 |
| MerkleProofの行番号 | OpenZeppelin Contracts 5.4.0 `contracts/utils/cryptography/MerkleProof.sol` | 2026-10-21 |
| 同期委員会512人、256エポック | イーサリアムの合意の仕様`altair/beacon-chain.md`（`SYNC_COMMITTEE_SIZE` 512、`EPOCHS_PER_SYNC_COMMITTEE_PERIOD` 256） | 2026-10-21 |
| ファイナリティ約13分 | 前の講義（第18講）のPoSへの移行とファイナリティ | 2026-10-21 |
| 製品の検証モデルの例 | IBC公式ドキュメント（ライトクライアント）、Wormhole公式ドキュメント（Guardianの3分の2の署名） | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0 `MerkleProof.sol`: verify 45〜47行目、processProof 57〜63行目
- イーサリアムの合意の仕様（Altair）`beacon-chain.md`: 同期委員会の大きさと交代の周期
- 向こうのバリデーターのどの署名がスラッシングの対象かはチェーンごとに違う。イーサリアムの同期委員会の署名がスラッシングの対象かどうかは、この講義では断定していない
- Foundry公式ドキュメント（`cast rpc evm_increaseTime`、`evm_mine`）: https://getfoundry.sh/
