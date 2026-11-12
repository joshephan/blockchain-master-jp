# 第147講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | `solc --version`、foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |

付録の出力とガスの数字は、すべて上の環境で直接実行した結果である。外部のチェーンには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcの設定 | foundry.toml、`forge config` | 2026-10-20 |
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36 `docs/natspec-format.rst`、`docs/metadata.rst` | 2026-10-20 |
| 取り出す方法ごとの欄 | 直接実行（`solc --userdoc --devdoc`、`forge inspect`、成果物のJSONの`metadata`・`rawMetadata`、Standard JSON outputSelection） | 2026-10-20 |
| forge docの出力の形 | 直接実行（Foundry 1.8.3 `forge doc`） | 2026-10-20 |
| Foundryの既定のfs_permissions | `forge config`（fs_permissionsの行を抜いたコピー） | 2026-10-20 |
| rawMetadataのサイズ・末尾のハッシュ | 直接実行（バージョンごとに成果物を比較） | 2026-10-20 |
| CREATE2アドレス | `cast compute-address --salt --init-code` | 2026-10-20 |
| デプロイデータのバイトの値 | EIP-2028、直接計算 | 2026-10-20 |
| ガス | 直接実行（バージョンごとに新しいanvil、レシートのgasUsed）、`forge test`、`forge snapshot --check` | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| アカウント0番 | anvilの既定のアカウント | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、NatSpec Format（`docs/natspec-format.rst`、二種類の読者18〜20行、ABIのすべてに書くようにという勧告22〜23行、`@custom` 30〜32行、Dynamic expressions 140〜156行、ドキュメントの出力コマンド180〜185行）：https://docs.soliditylang.org/en/v0.8.36/natspec-format.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/natspec-format.rst
- Solidity公式ドキュメントv0.8.36、Contract Metadata（`docs/metadata.rst` 243〜254行）：https://docs.soliditylang.org/en/v0.8.36/metadata.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/metadata.rst
- EIP-2028, Transaction data gas cost reduction（0でないcalldataのバイト16ガス）：https://eips.ethereum.org/EIPS/eip-2028
- Foundry公式ドキュメント（`forge doc`、`forge inspect`、`fs_permissions`、`vm.getArtifactPathByCode`、`vm.pauseGasMetering`）：https://getfoundry.sh/
