# 第221講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| anvil | `--hardfork osaka`、チェーンの番号31337、既定のテスト用の鍵 | `anvil`の起動画面 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |

付録のテスト結果、アドレス、コード、ストレージの値、ガス、castの文言は、すべて上の環境で直接実行した結果である。署名・送信は、ローカルのanvilの既定のテスト用の鍵と、デモ用の鍵`0xA11CE`だけで行った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIP-7702の原文 | raw.githubusercontent.com/ethereum/EIPs/master/EIPS/eip-7702.md（ファイルの先頭の欄とコミットの記録） | 2026-10-21 |
| Pectraのメインネットでの有効化 | EIP-7600（ethereum/EIPs master `cd7b26d2`） | 2026-10-21 |
| ERC-4337の原文 | raw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-4337.md | 2026-10-21 |
| コントラクトのサイズ | 直接実行（`forge build --offline --sizes`） | 2026-10-21 |
| anvilのgasUsed、デモのアドレス | 直接実行（anvilでcastにより12の段階） | 2026-10-21 |
| テストのガス | 直接実行（`forge test --offline --match-contract Delegate221Test -vv`） | 2026-10-21 |
| castの確認の文言 | Foundry 1.8.3の`cast`の出力 | 2026-10-21 |

## 参考資料

- EIP-7702 Set Code for EOAs（コミットbbc3f958のバージョン）: https://eips.ethereum.org/EIPS/eip-7702 （下の行番号はraw.githubusercontent.com/ethereum/EIPs/master/EIPS/eip-7702.mdのファイル基準）
  - 1〜22行目 先頭の欄とAbstract、32〜44行目 Motivation
  - 52行目、63〜66行目 取引の欄（`authorization_list`）、68行目 `[chain_id, address, nonce, y_parity, r, s]`
  - 101〜124行目 Behavior（許可の処理、署名者の復元、`0xef0100 || address`の委任の表示）、107行目 "0 or the ID of the current chain"、126〜128行目 間違った許可を飛ばす
  - 136〜155行目 委任の表示23バイト、54〜55行目・176〜183行目 許可一つのガス
  - 193〜196行目 委任の表示があるEOAも取引を始められる
  - 208〜226行目 永続的な委任、228〜235行目 Rationale "No initcode"
  - 262〜277行目 アプリとウォレット、299〜319行目 tx.originの確認の使い道
  - 408〜412行目 チェーンの番号0の許可
  - 483〜494行目 崩れる前提、498〜514行目 委任のコードが縛るべきもの、516〜532行目 初期化の横取り、534〜552行目 Storage management
- EIP-7600 Hardfork Meta - Pectra: https://eips.ethereum.org/EIPS/eip-7600
- ERC-4337 Account Abstraction Using Alt Mempool（コミットc8d8c210のバージョン）: https://eips.ethereum.org/EIPS/eip-4337 （rawファイルの73〜74・284〜302・540〜546行目、EIP-7702のアカウントと出会うところ）
- Solidity公式ドキュメント v0.8.36 `value-types.rst` 892〜898行目（同じアドレスに違うコード）: https://docs.soliditylang.org/en/v0.8.36/
- Foundry公式ドキュメント: https://getfoundry.sh/
