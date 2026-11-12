# 第164講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0、MIT（Initializable、ERC1967Proxy、TransparentUpgradeableProxy、ProxyAdmin）。コードは載せていない | `lib/openzeppelin-contracts/package.json`の`"version"`、Initializable.solの冒頭のコメント | 2026-10-20 |
| デモのビルド | optimizerオフ（Foundryの既定値）・evm osaka | `demo/foundry.toml`、`e7576/foundry.toml` | 2026-10-20 |
| Market第164講のバージョンのビルド | defaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | `market/foundry.toml` | 2026-10-20 |

付録のガス・アドレス・スロットの値は、すべて上の環境のローカルのanvilとforgeで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| EIPの原文と行番号 | raw.githubusercontent.comのethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（`ERCS/erc-1822.md`、`ERCS/erc-2535.md`、`ERCS/erc-7201.md`） | 2026-10-19 |
| EIPの状態とファイルの最終更新日 | ファイルの冒頭の行、GitHub API | 2026-10-19 |
| Solidityの文書の行番号 | argotorg/solidityのタグv0.8.36の`docs/` | 2026-10-20 |
| OpenZeppelinの行番号 | OpenZeppelin Contracts 5.4.0のコピーの`proxy/utils/Initializable.sol`、`proxy/ERC1967/ERC1967Proxy.sol` | 2026-10-20 |
| ERC-7201の値 | 直接計算（`cast keccak`を2回、最後のバイトは00） | 2026-10-20 |
| デモのガス・アドレス・スロットの値 | 直接実行（ローカルのanvil、`cast send`・`cast call`・`cast storage`・`cast code`・`cast implementation`） | 2026-10-20 |
| スロットの配置 | `forge inspect --offline … storageLayout` | 2026-10-20 |
| 委任1回の費用 | 第160〜163講のデモのバージョンでの、同じ欄の書き換えのガスの差 | 2026-10-20 |
| テストのガス | 直接実行（`.gas-snapshot`） | 2026-10-20 |
| 通しプロジェクトのガス | 直接実行（第25章の方法、ローカルのanvil） | 2026-10-20 |
| サイズ・末尾のハッシュ・行番号 | `forge build --sizes`、`forge inspect Market deployedBytecode`、`src/Market.sol` | 2026-10-20 |
| 120バイトを超える行 | `LC_ALL=C awk 'length($0)>120'` | 2026-10-20 |

## 参考資料

- Solidityの文書v0.8.36 Custom Storage Layout、9〜11・26〜29・44〜48・51行（`layout at`、基準スロットの式、継承ツリーの一番上にだけ、transientには影響なし）：https://docs.soliditylang.org/en/v0.8.36/custom-storage-layout.html
- Solidityの文書v0.8.36 Value Types、892〜898行（同じアドレスに別のコードを置く道三つ）：https://docs.soliditylang.org/en/v0.8.36/value-types.html
- Solidityの文書v0.8.36 Units and Globally Available Variables、249〜250行（`erc7201(string memory id) returns (uint)`）：https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
- 文書の元のファイル：https://github.com/argotorg/solidity/blob/v0.8.36/docs/custom-storage-layout.rst、https://github.com/argotorg/solidity/blob/v0.8.36/docs/value-types.rst、https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- ERC-1822 Universal Upgradeable Proxy Standard、152・154行（新しい変数は最後に、変数を集めたbaseコントラクト）：https://eips.ethereum.org/EIPS/eip-1822
- ERC-7201 Namespaced Storage Layout、23・35・39行（公式）・73〜75行（例の値）・95行（`@custom:storage-location`）：https://eips.ethereum.org/EIPS/eip-7201
- ERC-2535 Diamonds、52行（アップグレードできるダイヤモンドが変えられなくなる道）：https://eips.ethereum.org/EIPS/eip-2535
- EIP-7702（value-types.rstが同じアドレスに別のコードを置く道として挙げたアカウント抽象化）：https://eips.ethereum.org/EIPS/eip-7702
- ethereum/ERCsリポジトリ、引用の基準のコミット：https://github.com/ethereum/ERCs/tree/48dc87a2897c1d412d6df688c2d7df1229f2b30c
- OpenZeppelin Contracts 5.4.0：`proxy/utils/Initializable.sol`（8〜10・33〜34・43〜45行のコメント、63・65〜74・76〜77行のERC-7201の欄、156〜158行のreinitializerの確認、185〜202行の`_disableInitializers`）、`proxy/ERC1967/ERC1967Proxy.sol`（19〜20行のコメント、26〜28行のコンストラクタ）
- Foundry公式ドキュメント（`forge inspect`、`cast calldata`）：https://getfoundry.sh/
