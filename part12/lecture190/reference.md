# 第190講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30+commit.73712a01.Windows.msvc | `solc-0.8.30 --version`、実行ファイルの`sha256sum` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

付録のテスト結果、ガス、トレース、バイトコードのサイズとハッシュは、すべて上の環境で直接実行した結果である（anvilなし、外部への接続なし）。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Foundry・solcのバージョン、solcのハッシュ | `forge --version`、`solc-0.8.30 --version`、`sha256sum` | 2026-10-21 |
| Marketのビルドのサイズ・メタデータのハッシュ | `foundry.toml`、`forge inspect --offline Market deployedBytecode`（直接実行） | 2026-10-21 |
| 範囲の行数 | 範囲内のファイル四つの行数を数える（直接実行） | 2026-10-21 |
| 再現テストのガス、テストの数 | 三つの写しで`forge test --offline`（直接実行） | 2026-10-21 |
| 公開監査報告書を出しているところ | Trail of Bits、OpenZeppelinの各社の公開ページ | 2026-10-21 |

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- Solidity公式ドキュメント v0.8.36: https://docs.soliditylang.org/en/v0.8.36/
- EIP-20トークン標準（L-01が頼った前提）: https://eips.ethereum.org/EIPS/eip-20
- 公開監査報告書の例：Trail of Bits（公開リポジトリpublications）、OpenZeppelin（監査記事）
