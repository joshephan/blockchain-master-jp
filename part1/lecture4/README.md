# 第4講 システムの全体図

第1部 基盤：ブロックチェーンとEVM・第1章 本質

[← 第3講](../../part1/lecture3/) | [第1部 目次](../) | [第5講 →](../../part1/lecture5/)

## この講義の問い

第3講のフィルターを通過したなら、そのコストを受け取る機械はどういう形をしているのか。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| go-ethereumのルートフォルダー構成とcoreの下位フォルダー | ルートフォルダー accounts beacon build cmd common consensus console core crypto docs eth ethclient ethdb ethstats event graphql internal log metrics miner node p2p params rlp rpc signer tests trie triedb version / coreの下位 filtermaps forkid history overlay rawdb state stateless tracing txpool types vm（最新リリース v1.17.8） | 2026-10-20 |
| go-ethereumのライセンス | cmdの外のライブラリはLGPL v3（COPYING.LESSER）、cmdの中の実行ファイルはGPL v3（COPYING） | 2026-10-20 |
| フルノードの規模 | ビットコイン25,155台（bitnodesの到達可能ノード） / イーサリアム11,955台（Etherscan Node Tracker、直近24時間に検出）。「1万台前後」の桁 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ハッシュとデジタル署名の動作 | [第5講](../../part1/lecture5/) |
| ウォレットアドレスの生成 | [第6講](../../part1/lecture6/) |
| マークルツリーの構造 | [第7講](../../part1/lecture7/) |
| ビットコインのマイニングとプルーフ・オブ・ワークの経済 | [第10講](../../part1/lecture10/) |
| トランザクションの一生、メンプール、ナンスの詳細 | [第11講](../../part1/lecture11/) |
| ステートツリーとMPT | [第13講](../../part1/lecture13/) |
| EVMの命令処理 | [第14講](../../part1/lecture14/) |
| 失敗の伝播と巻き戻しの範囲 | [第15講](../../part1/lecture15/) |
| ガスの価格表 | [第16講](../../part1/lecture16/) |
| プルーフ・オブ・ステークへの移行とファイナリティ | [第18講](../../part1/lecture18/) |
| イベントの発行とログの消費 | 第105講、第106講、第107講 |
| MEVの原理と事例 | 第172講、第224講、第225講、第226講、第227講、第228講 |
| オラクル操作 | 第173講、第204講、第205講、第206講、第207講 |
| ノード運用とクライアントへの信頼 | 第235講、第236講、第237講 |

出典と参考資料は[reference.md](reference.md)にまとめた。
