# 第217講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | `anvil`の起動画面、`forge --version` | 2026-10-21 |
| solc | 0.8.30 | `foundry.toml` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `vendor/oz/package.json` | 2026-10-21 |
| anvil | チェーンの番号31337、既定のテスト用の鍵 | `anvil`の起動画面 | 2026-10-21 |

付録のテスト結果、アドレス、ハッシュ、ガス、リバートの値は、すべて上の環境で直接実行した結果である。署名はanvilの既定のテスト用の鍵だけで行い、実際のSafeのコントラクトと実際の秘密鍵は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| デモのアドレス、署名するハッシュ、実行のガス | 直接実行（anvilでのデプロイと`cast send`の出力） | 2026-10-21 |
| テストのガス | 直接実行（`forge test --offline --match-contract Safe58Test -vvv`） | 2026-10-21 |
| Safeの公開ドキュメント：しきい値の範囲、ハッシュに署名 | docs.safe.global/advanced/smart-account-concepts | 2026-10-21 |
| Safeの公開ドキュメント：署名の並べ方（"All the signatures are sorted by the signer address"） | docs.safe.global/advanced/smart-account-signatures | 2026-10-21 |
| Safe Knowledge Base "Transaction queue"：使用番号の定義、最後の番号 + 1だけを実行 | help.safe.global/articles/5444195122-transaction-queue | 2026-10-21 |

## 参考資料

- EIP-712 Typed structured data hashing and signing: https://eips.ethereum.org/EIPS/eip-712
- EIP-1271 Standard Signature Validation Method for Contracts（コントラクトの署名、関連するテーマ）: https://eips.ethereum.org/EIPS/eip-1271
- Safeの公開ドキュメント Smart Account concepts: docs.safe.global/advanced/smart-account-concepts
- Safeの公開ドキュメント Smart Account signatures: docs.safe.global/advanced/smart-account-signatures
- Safe Knowledge Base "Transaction queue": help.safe.global/articles/5444195122-transaction-queue
- OpenZeppelin Contracts 5.4.0 `utils/cryptography/EIP712.sol`、`utils/cryptography/ECDSA.sol`
- Foundry公式ドキュメント: https://getfoundry.sh/
