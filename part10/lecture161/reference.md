# 第161講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（TransparentUpgradeableProxy、ProxyAdmin、ERC1967Proxy、Ownable）。コードは載せていない | `lib/openzeppelin-contracts/package.json`の`"version"`、ファイルの冒頭のコメント | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml` | 2026-10-20 |
| Market第161講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | `market/foundry.toml` | 2026-10-20 |

付録のガス・アドレス・サイズ・ログは、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIPの原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-1967.md`） | 2026-10-20 |
| OpenZeppelinの行番号 | OpenZeppelin Contracts 5.4.0のコピーの`proxy/transparent/TransparentUpgradeableProxy.sol`、`proxy/transparent/ProxyAdmin.sol`、`proxy/ERC1967/ERC1967Proxy.sol`、`access/Ownable.sol` | 2026-10-20 |
| エラー・セレクタ・トピック | `cast sig`、`cast keccak` | 2026-10-20 |
| デモのガス・アドレス・サイズ・ログ | 直接実行（ローカルのanvil、`forge create`・`cast send`・`cast call`・`cast estimate`・`cast code`） | 2026-10-20 |
| テストのガス | 直接実行（`.gas-snapshot`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法、ローカルのanvil） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode` | 2026-10-20 |

## 参考資料

- ERC-1967 Proxy Storage Slots、82・84行（プロキシの関数と実装の関数の重なり）、86・88行（Nomic Labsの引用）：https://eips.ethereum.org/EIPS/eip-1967
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- Nomic Labs, "Malicious backdoors in Ethereum proxies"（ERC-1967の86行が引用した記事、名前だけを記す）
- OpenZeppelin Contracts 5.4.0：`proxy/transparent/TransparentUpgradeableProxy.sol`（30〜34・36〜40・42〜46・51〜55・57〜60・63〜67・72・79〜83・95〜105行）、`proxy/transparent/ProxyAdmin.sol`（13・18〜19・22・38〜44行）、`proxy/ERC1967/ERC1967Proxy.sol`（26〜28行）、`access/Ownable.sol`（76・84行）
- Foundry公式ドキュメント（`forge create`、`cast admin`、`cast implementation`）：https://getfoundry.sh/
- Solidity公式ドキュメントv0.8.36：https://docs.soliditylang.org/en/v0.8.36/
