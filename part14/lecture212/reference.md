# 第212講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3、commit cae51ad4 | `forge --version` | 2026-10-21 |
| solc | 0.8.30 | 二つのプロジェクトのfoundry.toml | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。anvilと外部への接続は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| DefaultsTestのガスとトレース、xchain全体のテストの数 | 直接実行（`forge test --offline --match-contract DefaultsTest -vv`、`-vvvv`、`forge test --offline`） | 2026-10-21 |
| BridgedTest・NoSigTestのガス、Marketのコピー全体のテストの数 | 直接実行（Marketのコピー） | 2026-10-21 |
| MerkleProofの行番号 | OpenZeppelin Contracts 5.4.0 `contracts/utils/cryptography/MerkleProof.sol` 45〜47行目（verify = processProof(proof, leaf) == root） | 2026-10-21 |
| 事件の名前・年・1行の性格 | 講義の事件カード | 2026-10-21 |

## 参考資料

事件（名前、年、1行の性格だけ。損失額・アドレス・経緯は載せない）：

| 事件 | 年 | 1行 |
|---|---|---|
| Poly Network | 2021 | 権限のデータの改ざん |
| Wormhole | 2022 | 署名の確認の迂回 |
| Ronin | 2022 | バリデーターの鍵の多数の奪取 |
| Harmony Horizon | 2022 | マルチシグの鍵の奪取 |
| Wintermute OP | 2022 | ほかのチェーンにまだないマルチシグのアドレスにトークンが行った |
| Nomad | 2022 | アップグレードのときに入れた初期値のせいで、証明のないメッセージが通った |
| BNB Chainのブリッジ | 2022 | 証明を確かめるコードの欠陥で、偽造した証明が通った |

- OpenZeppelin Contracts 5.4.0 `MerkleProof.sol` verify
- Foundry公式ドキュメント: https://getfoundry.sh/
