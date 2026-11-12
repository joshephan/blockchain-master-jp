# 第144講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| anvilのハードフォーク | istanbul、berlin、osaka（既定） | `anvil --hardfork` | 2026-10-20 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcの設定 | `foundry.toml`、`forge build` | 2026-10-20 |
| 公式ドキュメントの版と行番号 | `argotorg/solidity`リポジトリのタグv0.8.36のドキュメント原文 | 2026-10-20 |
| ハードフォーク別の`peek`の結果とSLOADのgasCost | 直接実行（ハードフォークを変えたanvil三つ、`--steps-tracing`トレースのgasCost） | 2026-10-20 |
| ハードフォークの日付とSLOADの規則 | EIP-1884、EIP-2929 | 2026-10-20 |
| Marketのバージョン・コピーのガス | 直接実行（バージョンごとに新しいanvil、レシートのgasUsed） | 2026-10-20 |
| コピーのテスト結果 | 直接実行（`forge test`） | 2026-10-20 |
| サイズ | `forge build --sizes` | 2026-10-20 |
| 第109講・第140講の値 | 各講義の実測値 | 2026-10-19、2026-10-20 |
| アカウント0番 | anvilの既定のアカウント | 2026-10-20 |

## 参考資料

- Solidity公式ドキュメントv0.8.36、Checked or Unchecked Arithmetic（`docs/control-structures.rst` 551〜552行）：https://docs.soliditylang.org/en/v0.8.36/control-structures.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/control-structures.rst
- Solidity公式ドキュメントv0.8.36、Security Considerations（`docs/security-considerations.rst` 156、158行、イーサを受け取る関数に渡される2,300ガスと、ハードフォークで変わりうるという括弧の文）：https://docs.soliditylang.org/en/v0.8.36/security-considerations.html 、原文 https://github.com/argotorg/solidity/blob/v0.8.36/docs/security-considerations.rst
- EIP-1884, Repricing for trie-size-dependent opcodes（Istanbul、2019-12-08、SLOAD 800）：https://eips.ethereum.org/EIPS/eip-1884
- EIP-2929, Gas cost increases for state access opcodes（Berlin、2021-04-15、初回の読み込み2,100・再読100）：https://eips.ethereum.org/EIPS/eip-2929
- Foundry公式ドキュメント：https://getfoundry.sh/
