# 第101講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| forge-std | v1.17.0 | foundry.lock | 2026-10-19 |

付録の出力、セレクタ、長さ、アドレスは、すべて上の環境で直接実行した結果である（`cast keccak`、`cast sig`、`cast calldata`、`cast disassemble`、`forge inspect`、`forge test`）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| セレクタはcalldataの先頭4バイト、関数のシグネチャのKeccak-256ハッシュの先頭4バイト、引数の型はコンマだけで区切り空白なし、戻り値の型はシグネチャに入らない | Solidity公式ドキュメント Contract ABI Specification、Function Selectorの節（latestのバージョンで確認、v0.8.36のバージョンと同じかは照合していない） | 2026-10-19 |
| Solidityの型とABIの型の対応 | 同じドキュメント Mapping Solidity to ABI types | 2026-10-19 |
| 重なる組の探索（130,172個、145.2秒） | 直接実行（純粋なPythonのkeccak256で`f_0()`から順にハッシュ） | 2026-10-19 |
| `burn(uint256)`・`collate_propagate_storage(bytes16)`の組 | OpenZeppelinフォーラム "Beware of the proxy: learn how to exploit function clashing"（2019-07-19）。この記事は、関数の衝突を初めてきちんと紹介した記事としてNomic Labs "Malicious backdoors in Ethereum Proxies"を挙げている（その記事にこの組があるかは確認できなかった） | 2026-10-19 |
| 関数のシグネチャの一覧の登録数 | Ethereum Signature Database（4byte.directory） | 2026-10-19 |
| 長さ、アドレス | 直接実行 | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント、Contract ABI Specification: https://docs.soliditylang.org/en/latest/abi-spec.html （v0.8.36のバージョン: https://docs.soliditylang.org/en/v0.8.36/abi-spec.html）
- OpenZeppelinフォーラム、"Beware of the proxy: learn how to exploit function clashing": https://forum.openzeppelin.com/t/1070
- Nomic Labs、"Malicious backdoors in Ethereum Proxies"
- Ethereum Signature Database: https://www.4byte.directory
- Foundry公式ドキュメント: https://getfoundry.sh/
- forge-std v1.17.0
