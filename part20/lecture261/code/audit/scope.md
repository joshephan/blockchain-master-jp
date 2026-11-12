# 監査範囲

ビルド: このリポジトリのfoundry.tomlそのまま(solc 0.8.30、optimizerはオンでruns 200、via-IR、osaka、remappingは二行)、Foundry 1.8.3
監査したビルド: Marketのランタイム8,739バイト、末尾のメタデータハッシュの先頭4バイト47ac4829(前の版ef24c031と実行コードは同じ、NatSpecだけが違う)
直したビルド(指摘への対応のあと): Marketのランタイム8,921バイト、ハッシュd551e83c。変わったファイルは二つ(IMarket.sol、Market.sol)。直した行とその行を呼ぶ行はresponse.mdの最後の節で読み直す
ファイルリストはMarketの成果物のメタデータのsourcesから抜き出す(手では書かない)

| ファイル | 行 | sha256の先頭16桁 | メタデータkeccak256の先頭4バイト |
|---|---|---|---|
| src/IMarket.sol | 142 → 144 | cd6c25df1f75c710 → e7bc5ac183f0db40 | 5178257c → e4b7aafe |
| src/Market.sol | 421 → 424 | 84cd1be9ce7f760e → 8460b76110cc2afb | 76051f36 → 1bde19a3 |
| src/MarketMath.sol | 39 | 44ebad863771ed74 | d18e811c |
| src/MarketTypes.sol | 35 | c6a1ebe162aded07 | be3dddd5 |
| OpenZeppelin 5.4.0 token/ERC20/utils/SafeERC20.sol | 212 | ee455e7a639484a6 | 982c5cb7 |
| OpenZeppelin 5.4.0 token/ERC20/IERC20.sol | 79 | c88183106683ce7d | 74ed01eb |
| OpenZeppelin 5.4.0 token/ERC20/extensions/IERC20Metadata.sol | 26 | a1ec1fe630f0a297 | d6fa4088 |
| OpenZeppelin 5.4.0 interfaces/IERC1363.sol | 86 | e50076f76fc3383d | d5ea0736 |
| OpenZeppelin 5.4.0 interfaces/IERC20.sol | 6 | 7984ca1e9c81f5ab | 1a622131 |
| OpenZeppelin 5.4.0 interfaces/IERC165.sol | 6 | 50737d8441ba2583 | 0afcb7e7 |
| OpenZeppelin 5.4.0 utils/introspection/IERC165.sol | 25 | ea549ecb4a958b2a | 8891738f |

- 取り込んだファイルは七つ。設計文書D-10・11節は四つ(Market.solがimportする三つとSafeERC20が呼ぶIERC1363)だけを書いている。残りの三つはそれらのファイルがさらにimportするファイル → I-04
- 範囲外: test/、価格の出どころのアダプター、運用ツール、キーを握るアカウントのコード(タイムロック・マルチシグ)、OpenZeppelinの残りのファイル
- 範囲の外で変わったコードはこの監査が見たことのないコード。直した版は新しいビルドで書き直す
