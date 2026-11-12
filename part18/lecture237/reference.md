# 第237講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `anvil --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| Python | 3.12、標準ライブラリのみ（keccakの値は`cast keccak`と照合） | `python --version` | 2026-10-21 |
| テスト | 136個が通る | `forge test --offline` | 2026-10-21 |
| totalDepositsの欄の番号 | 4（totalBorrows 5、reserves 6、priceConfig 7） | `forge inspect src/Market.sol:Market storageLayout` | 2026-10-21 |

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公開RPCのclientVersion、メインネットのブロック・ヘッダーの欄、WETHの証明、証明のウィンドウでの拒否 | 直接リクエスト（ethereum-rpc.publicnode.com、読み取りのみ） | 2026-10-20 18:59 UTC |
| gethの過去のブロックの証明 | geth文書 Archive mode 32行目（go-ethereum websiteブランチ`4537eb54`） | 2026-10-16 |
| ライトクライアントの名前 | ethereum.org Light clients 45〜48行目（ethereum-org-website devのコミット`30054c46`） | 2026-10-20 |
| 同期委員会 | ethereum.org Light clients 15・21行目 | 2026-10-20 |

## 参考資料

- ethereum.org Light clients 21・27行目（受け取ったデータを、同期委員会が署名したブロックヘッダーに当てて証明で確かめる）
- ethereum.org Weak subjectivity 19・27行目（チェックポイントを正しいと信じてそこから確かめる、信じる出典を独立した出典と照合する）
- geth文書 Sync modes 65行目（"the node trusts that the checkpoint is correct"）、Archive mode 32行目
- EIP-1898 Add `blockHash` to defaultBlock methods: https://eips.ethereum.org/EIPS/eip-1898
- Foundry 公式ドキュメント: https://getfoundry.sh/
