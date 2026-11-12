# 第122講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| ローカルのチェーン | anvilの既定のハードフォーク | anvil | 2026-10-19 |

付録の出力・ガス・アドレスは、すべて上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 渡せるガスの割合 | EIP-150 | 2026-10-19 |
| 例のコントラクトのサイズ | `forge build --offline --sizes` | 2026-10-19 |
| セレクタ | `cast sig` | 2026-10-19 |
| ガス | anvilに送ったトランザクションのレシート（`cast send --json`）、`cast estimate` | 2026-10-19 |
| トレース | `cast call --trace`、`cast run` | 2026-10-19 |
| デプロイのアドレス | 直接実行の出力、`cast create2` | 2026-10-19 |
| Market 第122講のバージョン | `forge build --offline --force --sizes`、`forge test --offline` | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、YulのEVMの方言の表（`docs/yul.rst`）: https://docs.soliditylang.org/en/v0.8.36/yul.html
  - `call(g, a, v, in, insize, out, outsize)`: 失敗すると0（例: ガス不足）、成功すると1
  - `staticcall`は状態の変更を許さない`call`。`delegatecall`、`create(v, p, n)`・`create2(v, p, n, s)`は失敗すると0、create2のアドレスはkeccak256(0xff . this . s . keccak256(mem[p...(p+n))))
  - `returndatasize()`、`returndatacopy(t, f, s)`、`extcodesize(a)`、`return(p, s)`、`revert(p, s)`
  - 出力の欄の注釈（`yul-call-return-area`の節）: 答えが長いと先頭のoutsizeバイトだけを書き、短いと残りの欄には触れない。どの部分が答えかは`returndatasize`で確かめる
- Solidity公式ドキュメント v0.8.36、Inline Assembly: https://docs.soliditylang.org/en/v0.8.36/assembly.html
- Solidityのソースリポジトリ v0.8.36: https://github.com/argotorg/solidity/blob/v0.8.36/docs/yul.rst
- EIP-150（渡せるガスを残りのガスの64分の63に制限）: https://eips.ethereum.org/EIPS/eip-150
- Foundry公式ドキュメント: https://getfoundry.sh/
