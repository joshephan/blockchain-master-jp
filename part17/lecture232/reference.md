# 第232講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| anvil | `--hardfork osaka`、チェーン番号31337、デフォルトのテスト用アカウント | `anvil`の起動画面 | 2026-10-21 |

付録のテスト結果、ガス、ルート、エラーはすべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| オプティミスティックの異議申し立てのウィンドウ、不正証明の実装の名前、ZKロールアップの名前 | 各実装の公開文書（名前のみ） | 2026-10-21 |
| EIP-1108のペアリングのガス | EIP-1108、測定値は直接実行（`test_pairingCost`） | 2026-10-21 |
| 0x0Aのガス | EIP-4844原文47〜48行目 | 2026-10-21 |
| テストのガス・anvilの値 | 直接実行（`forge test --offline --match-contract "Rollup232Test\|Probe232Test" -vv`、anvilでcast `send`・`call`・`estimate`） | 2026-10-21 |

EIPの原文は、ethereum/EIPs masterのコミットcd7b26d2cf39d2eb071a26e1890e331f58767079のもの（2026-10-20）である。

## 参考資料

- EIP-4844 Shard Blob Transactions（プリコンパイル47〜48行目、`point_evaluation_precompile` 203〜223行目、オプティミスティック・ZKロールアップのデータ363〜371行目）: https://eips.ethereum.org/EIPS/eip-4844
- EIP-1108 Reduce alt_bn128 precompile gas costs: https://eips.ethereum.org/EIPS/eip-1108
- Solidity 公式ドキュメント v0.8.36 `introduction-to-smart-contracts.rst` 638〜643行目（アドレス1から0x0aまでのプリコンパイル）: https://docs.soliditylang.org/en/v0.8.36/introduction-to-smart-contracts.html
- 不正証明の実装：OP Stackの不正証明（Cannon）、Arbitrum BoLD（名前のみ）
- ZKロールアップ：zkSync、Starknet、Scroll、Linea、Polygon zkEVM（名前のみ）
- Foundry 公式ドキュメント: https://getfoundry.sh/
