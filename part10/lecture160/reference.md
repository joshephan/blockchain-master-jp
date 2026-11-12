# 第160講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（CloneMakerが使う`proxy/Clones.sol`、比較のために読んだ`proxy/Proxy.sol`）。コードは載せていない | `lib/openzeppelin-contracts/package.json`の`"version"` | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml` | 2026-10-20 |
| Market第160講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | `market/foundry.toml` | 2026-10-20 |

付録のガス・アドレス・スロットの値・ログは、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Solidityの文書の行番号 | argotorg/solidityのタグv0.8.36の`docs/` | 2026-10-20 |
| EIPの原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-1967.md`、`ERCS/erc-1167.md`） | 2026-10-20 |
| OpenZeppelinの行番号 | OpenZeppelin Contracts 5.4.0のコピーの`contracts/proxy/Proxy.sol`、`contracts/proxy/Clones.sol` | 2026-10-20 |
| デモのガス・アドレス・コードのハッシュ・ログ | 直接実行（ローカルのanvil、`cast send`・`cast call`・`cast code`・`cast keccak`・`cast logs`） | 2026-10-20 |
| スロットの配置 | `forge inspect … storageLayout` | 2026-10-20 |
| テストのガス | 直接実行（`.gas-snapshot`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法、ローカルのanvil） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode` | 2026-10-20 |

## 参考資料

- Solidityの文書v0.8.36 Introduction to Smart Contracts、547〜554行（delegatecall）：https://docs.soliditylang.org/en/v0.8.36/introduction-to-smart-contracts.html
- Solidityの文書v0.8.36 Units and Globally Available Variables、286〜288行（`<address>.delegatecall`）、320〜324行（delegatecallで状態変数を使うとき、二つのコントラクトの配置が合っていなければならない）：https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
- 文書の元のファイル：https://github.com/argotorg/solidity/blob/v0.8.36/docs/introduction-to-smart-contracts.rst、https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- ERC-1967 Proxy Storage Slots（Final、created 2019-04-24）：14・16・21・23・30・36〜37・42・71〜74・94・102行：https://eips.ethereum.org/EIPS/eip-1967
- ERC-1167 Minimal Proxy Contract（Final、created 2018-06-22）：14・22・31・32行：https://eips.ethereum.org/EIPS/eip-1167
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- OpenZeppelin Contracts 5.4.0：`contracts/proxy/Proxy.sol` 22〜45行（`_delegate`）、`contracts/proxy/Clones.sol`（clone、cloneDeterministic、predictDeterministicAddress）
- Foundry公式ドキュメント（`cast implementation`、`cast admin`、`forge inspect`）：https://getfoundry.sh/
