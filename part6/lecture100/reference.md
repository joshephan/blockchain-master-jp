# 第100講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、セレクタ、長さ、ガス、アドレスは、すべて上の環境で直接実行した結果である（`forge build`、`forge inspect`、`cast calldata`、`cast call`、`forge test`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| オーバーロードの解決の規則（`f(50)`は型エラー、`f(256)`は`uint256`のほう、戻り値の引数は解決に考慮しない、外部の型が同じになるオーバーロードはエラー） | Solidity公式ドキュメント v0.8.36、Contractsの節 Function Overloading、Overload resolution and Argument matching | 2026-10-19 |
| ERC-721の`safeTransferFrom`の二つのシグネチャ | OpenZeppelin Contracts v5.4.0 `contracts/token/ERC721/IERC721.sol` | 2026-10-19 |
| castでのオーバーロード関数の呼び出し、長さ、ガス、アドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/ （Contractsの節 Function Overloading）
- ERC-721 Non-Fungible Token Standard: https://eips.ethereum.org/EIPS/eip-721
- OpenZeppelin Contracts v5.4.0、`contracts/token/ERC721/IERC721.sol`
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
