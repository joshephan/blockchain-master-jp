# 第262講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| anvil | チェーン番号31337、デフォルトのテスト用キー | `anvil`の起動画面 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka、bytecodeHash ipfs | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts` | 2026-10-21 |
| Python | 標準ライブラリだけ（`deploy/check.py`） | - | 2026-10-21 |

付録のアドレス、ブロック、ガス、ハッシュ、確認結果は、すべて上の環境のローカルのanvilで直接実行した結果である。署名・送信はanvilのデフォルトのテスト用キーでだけ行い、公開ネットワークには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| デプロイしたビルドのサイズ・ハッシュ・コードハッシュ | 直接実行（`deploy/check.py`、ビルド成果物） | 2026-10-21 |
| デプロイのガス、アドレス、ブロック | 直接実行（`forge script --broadcast --slow`のbroadcastの記録、`cast receipt`） | 2026-10-21 |
| 標準JSON入力の変形 | 直接実行（`forge verify-contract --show-standard-json-input`の出力をsolc 0.8.30の`--standard-json`にもう一度入れた） | 2026-10-21 |
| エクスプローラー・署名方式の名前 | `forge verify-contract --help`、`forge script --help`（Foundry 1.8.3） | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/ （`forge script`の`--broadcast`・`--slow`・`--keystore`・`--password-file`、`forge verify-contract`、`cast wallet import`、`cast compute-address`、`cast calldata-decode`、`cast decode-abi`）
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （immutable、コントラクトのメタデータと末尾のCBORの尾、Standard JSON入力）
- OpenZeppelin Contracts 5.4.0 `TimelockController`（最小待機、提案・取り消し・実行のロール、コンストラクターのadmin引数）
- イーサリアムのイエローペーパー（デプロイ先アドレスがデプロイするアカウントとナンスで決まる規則）: https://ethereum.github.io/yellowpaper/paper.pdf
