# 第238講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `anvil --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| Python | 3.12、標準ライブラリのみ | `python --version` | 2026-10-21 |
| テスト | 136個が通る | `forge test --offline` | 2026-10-21 |

付録の取引、ガス、帳簿の値、再編成の結果、購読の出力、エラーはすべてローカルのanvilで直接実行した結果である。ブロックハッシュは実行するたびに違う。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| メインネットのsafe・finalizedの距離 | 直接リクエスト（ethereum-rpc.publicnode.com、読み取りのみ） | 2026-10-20 18:54 UTC |
| 公開RPCの`eth_getLogs`の区間 | 直接リクエスト（同じノード、WETHのアドレス） | 2026-10-20 19:14 UTC |
| インデクサーサービスの名前 | 名前だけを書いた、各サービスの文書は確かめていない | 2026-10-21 |

## 参考資料

- ethereum.org JSON-RPC API（ethereum-org-website devのコミット`30054c46`の版）：block parameterの`safe`・`finalized` 78〜79行目、eth_getLogsの`blockHash` 1726行目、ログの`removed` 1654行目
- EIP-234 Add `blockHash` to JSON-RPC filter options: https://eips.ethereum.org/EIPS/eip-234
- EIP-1898 Add `blockHash` to defaultBlock methods、44行目と66行目（コントラクトが適切なイベントを出さなければ、ログで状態を組み立て直せない）: https://eips.ethereum.org/EIPS/eip-1898
- Foundry lint `reentrancy-events`: https://getfoundry.sh/forge/linting/reentrancy-events
- Foundry 公式ドキュメント: https://getfoundry.sh/
