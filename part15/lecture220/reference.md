# 第220講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| anvil | チェーンの番号31337、既定のテスト用の鍵 | `anvil`の起動画面 | 2026-10-21 |

付録のテスト結果、アドレス、ガス、残高は、すべて上の環境で直接実行した結果である。テストのガス価格はbasefee 1 gwei + チップ1 gwei、anvilの値はそのチェーンのbasefee基準なので、チェーンの状態ごとに違う。署名・送信は、ローカルのanvilの既定のテスト用の鍵とデモ用の鍵だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ERC-4337の原文のバージョン | raw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-4337.md | 2026-10-21 |
| paymasterSignature | eth-infinitism/account-abstraction v0.9.0のリリースの記事、ERC-4337の原文327〜332行目、docs.erc4337.io/paymasters/paymaster-signature.html | 2026-10-21 |
| トークンのペイマスターのpostOpの分 | eth-infinitism/account-abstraction v0.7.0 `contracts/samples/TokenPaymaster.sol` 38・130〜132・171行目 | 2026-10-21 |
| トークンのペイマスターの価格の扱い | 同じファイルの18・19・40・147行目 | 2026-10-21 |
| ペイマスターのサービスのリスト | docs.erc4337.io/paymasters/examples-and-sdks.html | 2026-10-21 |
| コントラクトのサイズ | 直接実行（`forge build --offline --sizes`） | 2026-10-21 |
| テストのガス・値 | 直接実行（`forge test --offline --match-contract Paymaster220Test -vv`） | 2026-10-21 |
| anvilの値 | 直接実行（`forge script` `run220()`、`cast receipt`） | 2026-10-21 |
| デモの値 | `script/Demo.s.sol`、`test/Paymaster220.t.sol` | 2026-10-21 |

## 参考資料

- ERC-4337 Account Abstraction Using Alt Mempool（コミットc8d8c210のバージョン）: https://eips.ethereum.org/EIPS/eip-4337 （下の行番号はraw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-4337.mdのファイル基準）
  - 58行目 DefinitionsのPaymaster
  - 142〜147行目 validationDataの形
  - 306〜316行目 Extension: paymasters
  - 321〜325行目 paymasterAndDataの欄の配置（アドレス20バイト、検証のガス16バイト、postOpのガス16バイト、paymasterData）
  - 327〜332行目 paymasterSignature、PAYMASTER_SIG_MAGIC
  - 337〜348行目 IPaymasterとPostOpMode（"paymaster still has to pay for gas"）
  - 353〜384行目 預けたお金とステーク、593行目 "Note that this stake is never slashed"
  - 526行目 "AA3"のエラーコード、534行目 "Paymasters contracts MUST check that all calls … originate from the EntryPoint"
  - 602〜607行目 Rationale "pre-charge, and later refund"
- eth-infinitism/account-abstraction v0.7.0 `contracts/samples/TokenPaymaster.sol`: https://github.com/eth-infinitism/account-abstraction/tree/v0.7.0
- eth-infinitism/account-abstraction v0.9.0のリリースの記事（2025-11-16）
- ERC-4337の公開ドキュメント: docs.erc4337.io/paymasters/paymaster-signature.html、docs.erc4337.io/paymasters/examples-and-sdks.html
- Foundry公式ドキュメント: https://getfoundry.sh/
