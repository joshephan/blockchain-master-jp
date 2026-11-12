# 第79講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |
| Python | 3.12.10 | ほかの言語のハッシュとの比較 | 2026-10-19 |
| Node.js | v24.11.0 | ほかの言語のハッシュとの比較 | 2026-10-19 |

付録の出力とガスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| プリコンパイルのアドレスとガス、ecrecoverの失敗条件 | イーサリアムのイエローペーパー付録E・G、`forge test -vvvv`のトレースでの測定 | 2026-10-19 |
| secp256k1の曲線の位数n | SEC 2 | 2026-10-19 |
| 署名の展性 | EIP-2 | 2026-10-19 |
| OpenZeppelin ECDSA | openzeppelin-contracts v5.4.0 `contracts/utils/cryptography/ECDSA.sol` | 2026-10-19 |
| チェーン番号 | `cast chain-id`、forgeのテストのログ | 2026-10-19 |
| ほかの言語のハッシュ | 直接実行 | 2026-10-19 |
| guessのガス | `cast estimate` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、Units and Globally Available Variablesの節のMathematical and Cryptographic Functions: https://docs.soliditylang.org/en/v0.8.36/units-and-global-variables.html
  - `keccak256(bytes memory) returns (bytes32)`、`sha256(bytes memory) returns (bytes32)`、`ripemd160(bytes memory) returns (bytes20)`、`ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address)`
  - ecrecoverは"recover the address associated with the public key from elliptic curve signature or return zero on error"、結果は`address payable`ではない
  - 別名`sha3`は0.5.0で削除
  - 有効な署名を鍵なしで別の有効な署名に変えられるという警告、OpenZeppelin ECDSAの推奨
  - プライベートチェーンでプリコンパイルを初めて呼ぶとガス不足になることがあるという注記
- 同じドキュメントのrst原文: https://github.com/argotorg/solidity/blob/v0.8.36/docs/units-and-global-variables.rst
- イーサリアムのイエローペーパー: https://ethereum.github.io/yellowpaper/paper.pdf
- EIP-2（Homesteadハードフォークの変更）: https://eips.ethereum.org/EIPS/eip-2
- EIP-191（署名メッセージの前置き）: https://eips.ethereum.org/EIPS/eip-191
- EIP-712（構造化されたメッセージの署名）: https://eips.ethereum.org/EIPS/eip-712
- SEC 2: Recommended Elliptic Curve Domain Parameters (secp256k1)
- OpenZeppelin Contracts v5.4.0、`contracts/utils/cryptography/ECDSA.sol`
- 出来事：PS3の署名鍵の漏えい（2010年12月、ECDSAの乱数の固定）、Androidのビットコインウォレットの乱数の再利用（2013年8月）、イーサリアムの分裂後のリプレイ（2016年7月）
- Foundry公式ドキュメント（`cast wallet sign`、`vm.sign`、`vm.chainId`）: https://getfoundry.sh/
