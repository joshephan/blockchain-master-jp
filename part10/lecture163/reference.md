# 第163講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka、外部ライブラリなし | `demo/foundry.toml` | 2026-10-20 |
| Market第163講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | `market/foundry.toml` | 2026-10-20 |

付録のガス・アドレス・サイズ・ログの数は、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIPの原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-2535.md`、`ERCS/erc-7201.md`） | 2026-10-19 |
| EIPの状態とファイルの最終更新日 | ファイルの冒頭の行、GitHub API | 2026-10-19 |
| サイズの上限 | EIP-170、通しプロジェクトのci.shのサイズの表のコメント | 2026-10-20 |
| デモのアドレス・サイズ・ガス・ログの数 | 直接実行（ローカルのanvil、`cast send`・`cast call`・`cast storage`・`cast logs`） | 2026-10-20 |
| セレクタ・ハッシュ | `cast sig`、`cast keccak`、`cast to-dec` | 2026-10-20 |
| テストのガス | 直接実行（`.gas-snapshot`、`forge test -vvvv`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法、ローカルのanvil） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode`、`src/Market.sol` | 2026-10-20 |
| 120バイトを超える行 | `LC_ALL=C awk 'length($0)>120'` | 2026-10-20 |

## 参考資料

- ERC-2535 Diamonds, Multi-Facet Proxy（status Final、created 2020-02-22）：17・88〜91行（用語）、24・26・27行（動機）、102・104・112・114行（委任の呼び出しとカット）、121〜138行（fallbackの例）、147・149・153行（ダイヤモンドストレージ）、186行（DiamondCutイベント）、237〜241行（Add・Replace・Removeの規則）、255・270〜285行（ルーペの関数）、304・310・322・331行、408・418行（権限は標準の外）、425行（セレクタの重なり）、429行（変更の監視）：https://eips.ethereum.org/EIPS/eip-2535
- ERC-7201 Namespaced Storage Layout（status Final、created 2023-06-20）、55行（"diamond storage"と名前を分けた理由）：https://eips.ethereum.org/EIPS/eip-7201
- EIP-170 Contract code size limit（ランタイムコード24,576バイト）：https://eips.ethereum.org/EIPS/eip-170
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- Foundry公式ドキュメント（`forge build --sizes`、`cast storage`、`cast logs`）：https://getfoundry.sh/
- Solidity公式ドキュメントv0.8.36：https://docs.soliditylang.org/en/v0.8.36/
