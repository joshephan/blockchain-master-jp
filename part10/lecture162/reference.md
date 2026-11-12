# 第162講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0、MIT（UUPSUpgradeable、Initializable、ERC1967Proxy、ERC1967Utils）。コードは載せていない | `lib/openzeppelin-contracts/package.json`の`"version"`、UUPSUpgradeable.solの冒頭のコメント | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml` | 2026-10-20 |
| Market第162講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | `market/foundry.toml` | 2026-10-20 |

付録のガス・アドレス・サイズ・巻き戻しは、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIPの原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-1822.md`、`ERCS/erc-1967.md`） | 2026-10-19 |
| EIPの状態とファイルの最終更新日 | ファイルの冒頭の行、GitHub API | 2026-10-19 |
| OpenZeppelinの行番号 | OpenZeppelin Contracts 5.4.0のコピーの`proxy/utils/UUPSUpgradeable.sol`、`proxy/ERC1967/ERC1967Utils.sol`、`proxy/ERC1967/ERC1967Proxy.sol` | 2026-10-20 |
| デモのアドレス・サイズ・ガス | 直接実行（ローカルのanvil、`cast send`・`cast call`・`cast code`・`cast implementation`・`cast admin`） | 2026-10-20 |
| エラー・セレクタ・スロットの値 | `cast sig`、`cast keccak`、`cast calldata` | 2026-10-20 |
| テストのガス | 直接実行（`.gas-snapshot`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法、ローカルのanvil） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode`、`src/Market.sol` | 2026-10-20 |
| 120バイトを超える行 | `LC_ALL=C awk 'length($0)>120'` | 2026-10-20 |

## 参考資料

- ERC-1822 Universal Upgradeable Proxy Standard（UUPS、status Stagnant、created 2019-03-04）：14・28〜31行（三つのコントラクト）、47・52行（`keccak256("PROXIABLE")`のスロット）、111・113行（Proxiableが実装に入る、抜けるとアップグレードが止まる）：https://eips.ethereum.org/EIPS/eip-1822
- ERC-1967 Proxy Storage Slots（Final、created 2019-04-24）、23行（ブロックエクスプローラーが実装のABIを表示する）：https://eips.ethereum.org/EIPS/eip-1967
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- OpenZeppelin Contracts 5.4.0：`proxy/utils/UUPSUpgradeable.sol`（13〜15・20〜21・31・50・59・68〜70・84・86〜89・95〜113・122・125・135〜145行）、`proxy/ERC1967/ERC1967Utils.sol`（53〜58行 コードの長さの確認）、`proxy/ERC1967/ERC1967Proxy.sol`（26〜28行 コンストラクタ）
- Foundry公式ドキュメント（`cast implementation`、`cast admin`、`cast calldata`）：https://getfoundry.sh/
- Solidity公式ドキュメントv0.8.36：https://docs.soliditylang.org/en/v0.8.36/
