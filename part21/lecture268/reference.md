# 第268講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（cast） | 1.8.3 | `cast --version` | 2026-10-21 |
| 実行のシグネチャ | `execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)` → 0x6a761202 | `cast sig` | 2026-10-21 |

付録のcalldataの出力は、チェーンなしで上の環境で直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 2023年以降の事件の日付 | 報道・分析記事の2か所以上が一致する値、Ledgerの事故報告書 | 2026-10-21 |
| Ledgerの事故報告書 | ledger.com/blog/security-incident-report（2023-12-20の記事） | 2026-10-21 |
| KyberSwap Elastic | BlockSecの分析 | 2026-10-21 |
| Bybit | Sygniaの調査記事（sygnia.co/blog/sygnia-investigation-bybit-hack）、DL Newsの報道 | 2026-10-21 |
| Safeの原文 | https://github.com/safe-global/safe-smart-account mainブランチ：`contracts/Safe.sol`、`contracts/interfaces/Enum.sol`、`contracts/base/Executor.sol` | 2026-10-21 |
| 全事件の表 | 第265〜268講の事件カード | 2026-10-21 |
| Marketとの突き合わせ | 通しプロジェクトMarket第53章末のバージョン`src/Market.sol` | 2026-10-21 |

## 参考資料

- 事件（この講義の新しいカード。損失額と攻撃の主体は載せない）
  - Curve Vyper：2023-07-30。Vyperコンパイラの一部のバージョンが、ソースに書いた再入ロックをバイトコードで正しく作れなかった。再入の事例ではなく、ツールチェーンの欄に分類
  - KyberSwap Elastic：2023年11月。集中流動性プールの価格区間の境界の計算で丸めの方向が間違い、流動性が二重に数えられた（BlockSecの分析）
  - Ledger Connect Kit：2023-12-14。複数のアプリの画面が取り込んで使っていたウォレット接続ライブラリのnpmのバージョン三つ（1.1.5〜1.1.7）に悪意あるコードが入り、ユーザーに別のアドレスへの署名を求めた。修正バージョン1.1.8、ハードウェアウォレットは影響なし（Ledgerの事故報告書）
  - Penpie：2024-09-03。誰でもマーケットを上げられるようにした機能と、再入ロックのない報酬精算の関数
  - Bybit：2025年2月。取引所のコールドウォレット（マルチシグウォレットのコントラクト）の署名者たちが、ふだんの送金に見える取引を承認したが、実際に署名した取引は委任呼び出しでウォレットの実装を悪意あるバージョンに替える取引だった。原因はマルチシグウォレットのサービス側のインフラの悪意あるコード（Sygniaの調査記事）。欄は画面、しきい値（署名の経路が一つ）、委任呼び出しの三つ
- 全事件の表三十行の欄ごとの数（主な欄で数えた）
  - 制御の移転三つ（The DAO、Lendf.Me、Penpie）
  - 順番の操作四つ（Fomo3D、bZx、Harvest、Cream）
  - 資源と精度三つ（上海DoS、BEC、KyberSwap Elastic）
  - 中央の点五つ（Parity二つ、Poly Network、Ronin、Harmony Horizon）
  - 暗号の材料の組み違い六つ（リプレイ、pNetwork、Wormhole、Wintermute OP、Nomad、BNB Chainのブリッジ）
  - コードの外の経済・ガバナンス三つ（Beanstalk、Terra UST、Mango）
  - コードの外の画面・ドメイン三つ（BadgerDAO、Curve DNS、Bybit）
  - コードの外のツールチェーン二つ（Curve Vyper、Ledger Connect Kit）
  - 直した場所一つ（DAOフォーク）
- Safeのコントラクトのリポジトリ: https://github.com/safe-global/safe-smart-account （main、Safe.sol VERSION "1.5.0"）
- EIP-7702 Set Code for EOAs: https://eips.ethereum.org/EIPS/eip-7702
- ERC-4626 Tokenized Vaults: https://eips.ethereum.org/EIPS/eip-4626
- Foundry公式ドキュメント: https://getfoundry.sh/
