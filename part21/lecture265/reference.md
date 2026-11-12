# 第265講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（anvil・cast） | 1.8.3 | `anvil --version`、`cast --version` | 2026-10-21 |
| anvilのノード二つ | chain-id 31337、31338 | `cast chain-id` | 2026-10-21 |
| 署名のキー | anvilの0番アカウントのデフォルトのテスト用キー | `anvil`の起動画面 | 2026-10-21 |

付録の署名の値、ハッシュ、レシート、nonce、残高は、すべて上の環境で直接実行した結果である。同じvの値とハッシュは、anvilなしで`cast mktx`・`cast decode-transaction`だけで出し直しても同じになる。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| DAOフォーク、Tangerine Whistle、Spurious Dragonの日付・ブロック番号・引用文 | ethereum.org/en/history | 2026-10-21 |
| 事件の日付（年・月） | 報道・分析記事の2か所以上が一致する値 | 2026-10-21 |
| Parity 2017年11月の事件 | parity.io（旧paritytech.ioのアドレスは301のあと404で、事後報告書の原文を開けなかった） | 2026-10-21 |
| vの値、ハッシュ、レシート、残高 | 直接実行（anvilの二つのノードでcastで署名・送信） | 2026-10-21 |

## 参考資料

- ethereum.orgのイーサリアムの歴史のページ（ethereum.org/en/history）：DAOフォーク（2016-07-20、ブロック1,920,000）、Tangerine Whistle（2016-10-18、ブロック2,463,000）、Spurious Dragon（2016-11-22、ブロック2,675,000）
- EIP-150 Gas cost changes for IO-heavy operations: https://eips.ethereum.org/EIPS/eip-150
- EIP-155 Simple replay attack protection: https://eips.ethereum.org/EIPS/eip-155
- 事件（日付は年・月まで）
  - The DAO：2016年6月。再入で大金が抜け出た。2016-07-20のハードフォークでそのお金を移し、チェーンがイーサリアムとイーサリアムクラシックに分かれた（ethereum.org: "drained of over 3.6 million ETH"）
  - 上海DoS：2016年9〜10月。実際のコストより安く値付けされた命令でノードを遅くした攻撃。EIP-150（Tangerine Whistle）がガスを付け直した
  - リプレイとチェーン番号：2016-11-22のSpurious DragonでEIP-155により取引の署名にチェーン番号を入れた
  - Parityマルチシグの最初の事件：2017年7月（ウォレットが委任呼び出しで借りて使っていたライブラリのウォレット初期化関数を、誰でも呼べた）
  - Parityマルチシグの二つ目の事件：2017年11月（ウォレットが頼っていたライブラリのコントラクトが止まり、お金が凍結された）。凍結された量・ウォレット数は原文を確認できなかったので載せない
  - BEC：2018年4月（掛け算1行があふれて残高の検査をそのまま通過した。0.8からデフォルトのオーバーフロー検査が防ぐ、`unchecked`の行は例外）
  - Fomo3D：2018年8月（最後の購入者が手数料の高い自分の取引でブロックを埋め、ほかの購入が入れないようにした）
- Foundry公式ドキュメント: https://getfoundry.sh/
