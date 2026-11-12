# 第61講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のコンパイルエラー、欄の配置、トレースは、すべて上の環境で`forge`により直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのFunction Typesの節 | solidityリポジトリのタグv0.8.36 `docs/types/value-types.rst` | 2026-10-19 |
| ABIのfunctionのエンコード | タグv0.8.36 `docs/abi-spec.rst` | 2026-10-19 |
| 関数型の保存サイズ | `forge inspect storageLayout` | 2026-10-19 |
| テストのガス | `forge test -vvvv` | 2026-10-19 |
| テストのアドレス | forge testの既定のデプロイアドレス | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Value TypesのFunction Typesの節: https://docs.soliditylang.org/en/v0.8.36/types/value-types.html
  - 原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/types/value-types.rst
- Solidity公式ドキュメントv0.8.36、Contract ABI Specification（`function`型はアドレス20バイト + セレクター4バイト、bytes24と同じエンコード）: https://docs.soliditylang.org/en/v0.8.36/abi-spec.html
  - 原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/abi-spec.rst
- Foundry公式ドキュメント（`forge test -vvvv`のトレース、`vm.prank`、`vm.load`）: https://getfoundry.sh/
