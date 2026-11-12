# 第236講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | `anvil --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| Python | 3.12、標準ライブラリのみ | `python --version` | 2026-10-21 |
| テスト | 136個が通る | `forge test --offline` | 2026-10-21 |

付録のリクエスト・レスポンス、ハッシュ、高さ、エラーはすべて、ローカルのanvil二台とローカルのプロキシサーバーで直接実行した結果である。メインネットの値は、下の公開RPCに読み取りのリクエストだけを送って一度受け取った値である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 公開RPCのclientVersion・peerCount・syncing、メインネットのタグ、塞がれたメソッド | 直接リクエスト（ethereum-rpc.publicnode.com、読み取りのみ） | 2026-10-20 18:54 UTC |
| 公開ノードのeth_getLogsの区間 | 直接リクエスト（同じノード、WETHのアドレス） | 2026-10-20 19:14 UTC |
| ノードサービスの一覧 | ethereum.org Nodes as a service 54〜403行目（ethereum-org-website devのコミット`30054c46`） | 2026-10-20 |
| gethのデフォルトのポート | geth文書 JSON-RPC Server 33・118行目（go-ethereum websiteブランチ`4537eb54`） | 2026-10-16 |
| 公開ノードのリクエストのヘッダー | 直接リクエスト | 2026-10-20 |

## 参考資料

- EIP-1898 Add `blockHash` to defaultBlock methods（Final、ethereum/EIPs master `cd7b26d2`の版）：18行目、44〜46行目（`blockHash`、なければ`-32001: Resource not found`を推奨）、48行目（`requireCanonical`）、61〜65行目（番号で何回も尋ねると、そのあいだにブロックが変わりうる）: https://eips.ethereum.org/EIPS/eip-1898
- ethereum.org JSON-RPC API：数値（QUANTITY）の表記39行目、バイト（DATA）の表記51行目、ブロックの引数とタグ72〜80行目（devのコミット`30054c46`の版）
- ethereum.org Nodes as a service：ノードサービスは秘密鍵を保管しない（36行目）、ロードバランサーで複数のノードに分ける（30行目）
- geth文書 JSON-RPC Server 15・17・33・39・41・81・87・118行目（名前空間、デフォルトで許可されるeth・net・web3、HTTP・WSでのアカウントのロック解除の禁止、Engine APIはユーザーに開けない）、Security 14行目（go-ethereum websiteブランチ`4537eb54`）
- Foundry 公式ドキュメント: https://getfoundry.sh/
