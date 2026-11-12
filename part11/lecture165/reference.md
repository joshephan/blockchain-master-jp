# 第165講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30、via-IRオン・optimizerオン（runs 200）・evm osaka | `code/market/foundry.toml` | 2026-10-20 |
| Market | 第42章の終わりのバージョン（第164講のバージョン）のまま、コード・テストに変えた行なし | 第164講のバージョンと比較 | 2026-10-20 |

付録のアドレス、ガス、stateRoot、ブロックハッシュは、すべて上の環境のローカルanvilで直接実行した結果である。外部への接続はなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| anvilの開始時刻、ブロック間隔 | anvilの実行オプション（`--timestamp`）、`anvil_setBlockTimestampInterval 1` | 2026-10-20 |
| アドレス、Marketのコードの長さとkeccak、ガス | 直接実行（`forge create`、`cast receipt --json`、`cast code`、`cast keccak`） | 2026-10-20 |
| ブロック9 stateRoot・ブロックハッシュ・timestamp | 直接実行（`cast block latest -f stateRoot|hash|timestamp`） | 2026-10-20 |
| positionsのスロット | 直接実行（`cast index`、`cast storage`） | 2026-10-20 |
| エラーのセレクタとNotAdmin | 直接実行（`cast call`） | 2026-10-20 |
| EIP-6780 | EIP-6780本文、第80講の付録 | 2026-10-20 |

## 参考資料

- EIP-6780, SELFDESTRUCT only in same transaction（2024年3月のCancunハードフォークに含まれる）: https://eips.ethereum.org/EIPS/eip-6780
- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
