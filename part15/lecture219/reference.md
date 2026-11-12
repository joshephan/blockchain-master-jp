# 第219講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| anvil | チェーンの番号31337、既定のテスト用の鍵 | `anvil`の起動画面 | 2026-10-21 |

付録のテスト結果、アドレス、ハッシュ、ガス、残高は、すべて上の環境で直接実行した結果である。実際のEntryPointのコードはダウンロードしておらず、署名・送信はローカルのanvilの既定のテスト用の鍵と、デモ用の鍵`0xA11CE`だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ERC-4337の原文のバージョン | raw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-4337.md（ファイルの先頭の欄とコミットの記録） | 2026-10-21 |
| 原文の定数 | 同じ原文の249〜250行目、401行目 | 2026-10-21 |
| EntryPoint v0.6〜v0.9のアドレス・日付 | eth-infinitism/account-abstraction GitHubのリリースの記事（v0.9の記事の先頭のWARNINGを含む）。チェーン上のコードは確かめていない | 2026-10-21 |
| まねのドメインの値 | `src/EntryPoint219.sol` | 2026-10-21 |
| バンドラーの実装のリスト | bundlers.erc4337.io（互換性テストの画面のResourcesのリスト。結果の表は閲覧時に読み込みに失敗） | 2026-10-21 |
| サイズ | 直接実行（`forge build --offline --sizes`） | 2026-10-21 |
| テストのガス・テストの中の値 | 直接実行（`forge test --offline --match-contract EntryPoint219Test -vv`） | 2026-10-21 |
| anvilの値 | 直接実行（`forge script` `run219()`、`cast receipt`、`cast run`） | 2026-10-21 |

## 参考資料

- ERC-4337 Account Abstraction Using Alt Mempool（コミットc8d8c210のバージョン）: https://eips.ethereum.org/EIPS/eip-4337 （下の行番号はraw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-4337.mdのファイル基準）
  - 16〜18行目 Abstract
  - 32行目 "Avoid trust assumptions on bundlers"
  - 46〜63行目 Definitions（UserOperation、Sender、EntryPoint、Bundler、Paymaster、Factory、Aggregator、Deposit）
  - 47・49行目 トランザクションに似た欄、`signature`の欄の使い方はアカウントの実装が決める
  - 69〜85行目 UserOperationの欄の表、78行目 preVerificationGas
  - 99〜109行目 PackedUserOperation
  - 132行目、270〜281行目 userOpHashのEIP-712のハッシュの定数
  - 136〜140行目 IAccountの規則とSIG_VALIDATION_FAILED
  - 170〜186行目 ナンスのkey・sequence
  - 210〜225行目 関数セレクタでkeyを分ける例（ADMIN_METHODSIG）
  - 231行目 "It must make two loops, the verification loop and the execution loop"
  - 249〜250行目、401行目 定数
  - 256〜259行目、390〜407行目 バンドラーが検証するタイミングと流れ
  - 572〜576行目 Rationale
  - 613〜630行目 initCode・Factory（関連するテーマ）
  - 638行目 "it will serve as a central trust point for _all_ ERC-4337"
- EIP-712 Typed structured data hashing and signing: https://eips.ethereum.org/EIPS/eip-712
- eth-infinitism/account-abstraction GitHubのリリースの記事（EntryPoint v0.6〜v0.9）
- バンドラーの互換性テストの画面: bundlers.erc4337.io
- ERC-4337の公開ドキュメント: docs.erc4337.io
- Foundry公式ドキュメント: https://getfoundry.sh/
