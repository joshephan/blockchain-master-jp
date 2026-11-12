# 第235講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil・cast・forge） | 1.8.3 (cae51ad4) | `anvil --version` | 2026-10-21 |
| anvilのハードフォーク | Bpo1、チェーン番号31337 | `anvil_nodeInfo` | 2026-10-21 |
| Market | 第53章の最終バージョン（第199講のバージョン）、この講義では直していない | 第199講の付録のcode/ | 2026-10-21 |

付録のステートルート、ブロックハッシュ、残高、エラーはすべて上の環境のローカルのanvilで直接実行した結果である。外部のノードには接続していない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Foundryのバージョン、hardFork | 直接実行（`anvil --version`、`anvil_nodeInfo`） | 2026-10-21 |
| 実行クライアントの名前 | ethereum.org Nodes and clients 139〜145行目（ethereum-org-website devのコミット`30054c46`） | 2026-10-20 |
| 合意クライアントの名前 | 同じ文書の207〜212行目 | 2026-10-20 |
| ハードウェアの仕様 | ethereum.org Run a node（Spin up your own Ethereum node）81〜82・90〜91行目 | 2026-10-20 |
| クライアントごとのディスク | 同じ文書の96〜106行目 | 2026-10-20 |
| gethのアーカイブ | geth文書 Archive mode 12・27・32行目（go-ethereum websiteブランチ`4537eb54`） | 2026-10-16 |
| gethのデフォルトのポート | geth文書（同じ版） | 2026-10-16 |
| イーサリアムのノード数 | Etherscan Node Tracker | 2026-10-20 |
| クライアントのシェア | ethereum.org Client diversity 74・80行目（文書が引用したsupermajority.info 2025-10-26、blockprint） | 2026-10-20 |

## 参考資料

- ethereum.org Node architecture 7・9・17・23・36行目、実行・合意・バリデータークライアントの比較表46〜53行目（devのコミット`30054c46`の版）
- ethereum.org Nodes and clients：フル同期264行目、スナップ同期280行目、チェックポイント同期308行目、アーカイブノード69〜74行目
- ethereum.org Run a node：ボトルネックはディスク（68行目）、二つのクライアントが同じjwtsecretを使う接続（218行目）
- ethereum.org Client diversity 24・32・34行目（33%を超える合意クライアントのバグはファイナリティを妨げ、3分の2を超えると間違ったチェーンを確定させうる）
- geth文書 Sync modes 6・14・19・35・51・65行目（直近128ブロックの状態だけを置くフルノード、スナップ同期、チェックポイントを信じて始めること）、Archive mode 12・27・32行目、History Pruning（go-ethereum websiteブランチ`4537eb54`）
- gethの事後報告 "Minority split 2021-08-27 post mortem" 1〜3行目：2021-08-27、修正前のバージョンを動かしていたgethノードが、イーサリアムのメインネットのブロック13107518を違うように処理し、少数派のチェーンとして分岐した。ブロック: https://etherscan.io/block/13107518
- Foundry 公式ドキュメント: https://getfoundry.sh/
