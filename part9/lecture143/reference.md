# 第143講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| EVMのバージョン | osaka（anvilの既定のハードフォーク） | foundry.toml `evm_version`、anvilの既定値 | 2026-10-20 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcの設定 | `foundry.toml`、`forge build` | 2026-10-20 |
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36のドキュメント原文 | 2026-10-20 |
| EIPごとのガスの規則とハードフォークの日付 | EIP-2200、EIP-2929、EIP-3529、EIP-1153、EIP-7623 | 2026-10-20 |
| SSTORE・SLOAD・TSTORE・LOG・KECCAK256・呼び出しの実測 | 直接実行（Cost143を`cost`プロファイルでビルドし、`debug_traceTransaction`のgasCostを読む） | 2026-10-20 |
| 呼び出しごとのガスの内訳 | 直接実行（anvilの`debug_traceTransaction`構造化ログを命令の種類別に合算） | 2026-10-20 |
| Marketのバージョン・コピーのガス | 直接実行（バージョンごとに新しいanvil、レシートのgasUsed） | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| calldataの下限値 | 計算（`cast calldata`のバイトを数える） | 2026-10-20 |
| アカウント0番 | anvilの既定のアカウント | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Layout of State Variables in Storage（`docs/internals/layout_in_storage.rst` 141〜162行のwarning）：https://docs.soliditylang.org/en/v0.8.36/internals/layout_in_storage.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/internals/layout_in_storage.rst
- Solidity公式ドキュメントv0.8.36、Security ConsiderationsのGas Limit and Loops（`docs/security-considerations.rst` 133〜145行）：https://docs.soliditylang.org/en/v0.8.36/security-considerations.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/security-considerations.rst
- EIP-2200, Structured Definitions for Net Gas Metering（イスタンブール、2019-12-08）：https://eips.ethereum.org/EIPS/eip-2200
- EIP-2929, Gas cost increases for state access opcodes（ベルリン、2021-04-15）：https://eips.ethereum.org/EIPS/eip-2929
- EIP-3529, Reduction in refunds（ロンドン、2021-08-05）：https://eips.ethereum.org/EIPS/eip-3529
- EIP-1153, Transient storage opcodes（カンクン、2024-03-13）：https://eips.ethereum.org/EIPS/eip-1153
- EIP-7623, Increase calldata cost（プラハ、2025-05-07）：https://eips.ethereum.org/EIPS/eip-7623
- Foundry公式ドキュメント：https://getfoundry.sh/
