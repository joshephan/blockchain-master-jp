# 第268講 2023年以降、そして全事件の5軸での再分類

第21部 事件アーカイブと終章・第73章 事件アーカイブ

[← 第267講](../../part21/lecture267/) | [第21部 目次](../) | [第269講 →](../../part21/lecture269/)

## この講義の問い

2023年以降の事件は新しい種類なのか。これまで見た事件すべてを五つの軸で分けると、何が残るのか。一つの事件が複数の欄にまたがるなら、何がわかるのか。

## 実習資料

### 準備

マルチシグウォレットの実行calldataから、operationの欄（0 = Call、1 = DelegateCall）を署名の前に自分で読む確認である。チェーンなしで、Foundryのcastだけを使う。公開されているSafeのコントラクト（safe-global/safe-smart-account）の`execTransaction`のシグネチャどおりに、calldataを二つ作る。受け取るアドレス`0x…bEEF`、値0、データは空、残りの欄0まで同じで、四つ目の欄のoperationだけが0と1で違う。`cast calldata`で作り、`cast decode-calldata`で先頭の五つの欄を読んだあと、二つのhex文字列で違う文字の位置を探す。セレクタは`cast sig 'execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)'`で0x6a761202である。

### 実行結果

operation 0と1で作ったcalldataをそれぞれdecodeした先頭の五つの欄と、二つのcalldataの違い。「operation 0:」の行と最後の行は、castの出力をまとめたシェルが付けた見出しと集計（このシェルは付録に入れていない）である：

```
operation 0: selector 0x6a761202 長さ 778
0x000000000000000000000000000000000000bEEF
0
0x
0
0
operation 1: selector 0x6a761202 長さ 778
0x000000000000000000000000000000000000bEEF
0
0x
1
0
違う文字の数 1 位置(0xを除いたhexの桁) [263] バイト [127]
```

セレクタと長さ（778文字）が同じで、違う文字は一つだけである。0から数えた127番目のバイト、つまりセレクタのあとの128番目のバイトで、四つ目の欄（operation）の最後のバイトである。

### 試すときの注意

- Safeの原文では、operationは`enum Operation { Call, DelegateCall }`で、`Executor.sol`は`operation == Enum.Operation.DelegateCall`ならdelegatecallで呼ぶ。1なら、ウォレットのアドレスで他人のコードが動く。
- 画面に「ふだんの送金」と書かれていても、署名するのはcalldataである。人の目では1バイトの違いは見えないが、`cast decode-calldata`で解くと四つ目の欄がすぐ見える。
- マルチシグの運用の署名手順に書いておく3行：calldataを画面とは別に解くツール、署名者ごとに違う機械、operationが1の取引は別に止めてもう一度確かめる規則。

## 時効性のあるデータ

基準日時点の値。原文とツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 2023年以降の事件の日付 | Curve Vyper 2023-07-30、KyberSwap Elastic 2023年11月、Ledger Connect Kit 2023-12-14、Penpie 2024-09-03、Bybit 2025年2月 | 2026-10-21 |
| Ledgerの事故報告書 | npmの悪意あるバージョン1.1.5・1.1.6・1.1.7、修正バージョン1.1.8、ハードウェアウォレットへの影響なし | 2026-10-21 |
| KyberSwap Elastic | 丸めの方向の誤りで区間の境界の計算が狂った | 2026-10-21 |
| Bybit | 原因はマルチシグウォレットのサービス側のインフラから出た悪意あるコード、Bybitのインフラへの侵害は見つからなかった / 委任呼び出しでウォレットの実装を悪意あるバージョンに替えた / 実行された取引のoperationの値は一次の原文で確認できなかったので載せない | 2026-10-21 |
| Safeの原文 | `execTransaction(address to, uint256 value, bytes calldata data, Enum.Operation operation, uint256 safeTxGas, uint256 baseGas, uint256 gasPrice, address gasToken, address payable refundReceiver, bytes memory signatures)`、`enum Operation { Call, DelegateCall }`、VERSION "1.5.0" | 2026-10-21 |
| 実行条件 | Foundry（cast）1.8.3、チェーンなし、セレクタ0x6a761202 | 2026-10-21 |
| 全事件の表 | 三十行、2022年の行の順番は仮（月は未確認） | 2026-10-21 |
| Marketとの突き合わせ | 第53章末のバージョン（借り入れ・価格の出どころ・清算）基準。TWAP_WINDOW 30 minutes、setPriceFeedは一度だけ、borrow・withdraw・liquidateは帳簿が先 | 2026-10-21 |
| 損失額・攻撃の主体 | 載せない | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 2023年以降の事件の損失額と攻撃の主体 | 扱わない（付録のデータシート） |
| マルチシグの署名者の装置と署名前の確認の運用 | [第222講](../../part15/lecture222/)、[第223講](../../part15/lecture223/)（扱い済み）、[第270講](../../part21/lecture270/) |
| 表の欄と七つの層の突き合わせ | [第269講](../../part21/lecture269/) |
| 全事件の表を増やし続けること | 付録（時効性） |
| Curve Vyperの攻撃の過程 | 扱わない |
| Marketの攻撃の地図と事件の表の突き合わせ | 第70〜72章のバージョンが確定したあとで照合 |

出典と参考資料は[reference.md](reference.md)にまとめた。
