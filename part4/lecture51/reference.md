# 第51講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerはオフ（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のテストの出力、ガス、欄の配置、命令数は、すべて上の環境とローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公式ドキュメントのIntegers | docs.soliditylang.org/en/v0.8.36/types.html | 2026-10-19 |
| 算術チェックの既定化（0.8.0）、`type(T).min`・`max`の導入（0.6.8） | solidityリポジトリのChangelog.mdの0.8.0、0.6.8の項目 | 2026-10-19 |
| incrementのgasUsed | anvilでの`cast send`のレシート | 2026-10-19 |
| 逆アセンブルの命令数 | `cast disassemble` | 2026-10-19 |
| チェックのコードのガス | 第35講の時効性のあるデータ | 2026-10-19 |
| 欄の数 | `forge inspect storageLayout` | 2026-10-19 |
| 欄を一つ余分に初めて書き込む | 第49講の時効性のあるデータ | 2026-10-19 |
| テストのガス | `forge test`の出力 | 2026-10-19 |
| デプロイのサイズ | `forge build --sizes` | 2026-10-19 |
| Panicコード | 直接実行した出力 | 2026-10-19 |
| BEC事件 | CVE-2018-10299、PeckShieldのbatchOverflow分析（2018-04-22） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Typesの節のIntegers: https://docs.soliditylang.org/en/v0.8.36/types.html
- Solidity Changelog.md、0.8.0（2020-12-16、"All arithmetic is checked by default"）、0.6.8（2020-05-14）
- BeautyChain（BEC）トークンのbatchTransferの掛け算のあふれ、2018年4月（2018-04-22の攻撃）。受取人2人 × 1人あたりの分2^255が一周して0になり、残高チェックを通過した。足し算・引き算はSafeMathを使っていて、総額の掛け算の一行だけがふつうの`*`だった
  - CVE-2018-10299
  - PeckShield、batchOverflow分析（2018-04-22）
- Foundry公式ドキュメント: https://getfoundry.sh/
