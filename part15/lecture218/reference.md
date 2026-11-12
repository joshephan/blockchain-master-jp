# 第218講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| anvil | チェーンの番号31337、既定のテスト用の鍵 | `anvil`の起動画面 | 2026-10-21 |

付録のテスト結果、アドレス、digest、ガス、エラーの文言は、すべて上の環境で直接実行した結果である。署名と送信は、ローカルのanvilの既定のテスト用の鍵と、デモ用の鍵`0xA11CE`だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ERC-4337の原文のバージョン | raw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-4337.md（ファイルの先頭の欄とコミットの記録） | 2026-10-21 |
| コントラクトのサイズ | 直接実行（`forge build --offline --sizes`） | 2026-10-21 |
| anvilのexecuteのgasUsed、デモのアドレス | 直接実行（anvilでcastによりデプロイ・署名・送信） | 2026-10-21 |
| テストのガス | 直接実行（`forge test --offline --match-contract Wallet218Test -vv`） | 2026-10-21 |

## 参考資料

- ERC-4337 Account Abstraction Using Alt Mempool（コミットc8d8c210のバージョン）: https://eips.ethereum.org/EIPS/eip-4337 （下の行番号はraw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-4337.mdのファイル基準）
  - 16行目 Abstract
  - 22〜23行目 "Historically, introducing Account Abstraction has been a long-standing goal …"
  - 27行目、37〜40行目 Motivation（アカウントごとの検証ロジック、ほかの署名方式・マルチシグ・復旧、トークンでの手数料、まとめた呼び出し）
  - 89〜90行目 "the `signature` MUST depend on `chainid` and the `EntryPoint` address"
  - 136行目 IAccountの規則 "MUST validate the caller is a trusted `EntryPoint`"
  - 412〜420行目 Simulation Rationale（EOAのトランザクションの確認五つ、"All of these checks do not rely on EVM state"）
  - 568〜570行目 Rationale（手数料を払うかどうかを知る前に、実行全体を回さなければならない問題）
- EIP-712 Typed structured data hashing and signing: https://eips.ethereum.org/EIPS/eip-712
- Foundry公式ドキュメント: https://getfoundry.sh/
