# 第58講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のコンパイルエラー、テストの出力、逆アセンブルの結果は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのRational and Integer Literals、Hexadecimal Literals、Address Literals | docs.soliditylang.org、v0.8.36 | 2026-10-19 |
| エラーコード | solc 0.8.30で直接実行した出力 | 2026-10-19 |
| addHundred(200)の巻き戻し | `forge test -vvvv` | 2026-10-19 |
| Half.half()のバイトコード | `forge inspect Half deployedBytecode`、`cast disassemble` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のRational and Integer Literals、Hexadecimal Literals、Address Literals: https://docs.soliditylang.org/en/v0.8.36/
- solcのエラー9429の案内文に書かれたアドレスリテラルのドキュメント: https://docs.soliditylang.org/en/develop/types.html#address-literals
- EIP-55 Mixed-case checksum address encoding（アドレスのチェックサム）: https://eips.ethereum.org/EIPS/eip-55
- Foundry公式ドキュメント（`cast disassemble`）: https://getfoundry.sh/
