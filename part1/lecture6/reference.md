# 第6講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（cast） | 1.8.3 | `cast --version` | 2026-10-16 |

付録のアドレス、公開鍵、ハッシュ値は、上の環境で実際に実行した出力である。

## 参考資料

- Foundry公式ドキュメント: https://getfoundry.sh/
- EIP-55（大文字小文字によるチェックサムつきアドレス、2016）: https://eips.ethereum.org/EIPS/eip-55
- BIP-39（シードフレーズ、2013）: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
- BIP-32（一つのシードから鍵を階層的に導く方式、2012）: https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
- ジェームズ・ハウエルズのハードディスク事件（2013、イギリス）：ビットコイン8千枚の鍵が入ったハードディスクを誤って捨て、埋立地に埋もれた
- アドレスポイズニング（address poisoning）：前後の数文字だけが同じ偽アドレスを取引履歴に残し、それをコピーさせる手口
