# 第179講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | `guards/foundry.toml`、`market/foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `guards/lib/openzeppelin-contracts` | 2026-10-21 |

付録のガスの数字、トレース、テストのアドレスは、すべて上の環境で直接実行した結果である。anvilと外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| テストのガス（guards、market） | 直接実行（`forge test -vvv`） | 2026-10-21 |
| テストのアドレス、チェーン番号、ダイジェスト | 直接実行（`forge test -vvvv`のトレース、`cast wallet address`で鍵のアドレスを確認） | 2026-10-21 |
| 事件の年 | 事件の名前・年（損失額・アドレス・経緯は扱わない） | 2026-10-21 |

## 参考資料

- OpenZeppelin Contracts 5.4.0 `utils/cryptography/ECDSA.sol`（23行 ECDSAInvalidSignature、91行 recover、143〜144行 大きいsの拒否、148〜150行 address(0)の復元の拒否）
- OpenZeppelin Contracts 5.4.0 `utils/cryptography/MessageHashUtils.sol`（30行 toEthSignedMessageHash）
- OpenZeppelin Contracts 5.4.0 `utils/cryptography/MerkleProof.sol`（16〜19行 64バイトのリーフの警告、110行 verifyCalldata）
- ブリッジ事件（名前・年・一行の性格）
  - Poly Network（2021）：誰が署名者かを書いた権限データの改ざん
  - Ronin（2022）：バリデーターの鍵の多数の奪取
  - Wormhole（2022）：署名確認の迂回
- Foundry公式ドキュメント: https://getfoundry.sh/
