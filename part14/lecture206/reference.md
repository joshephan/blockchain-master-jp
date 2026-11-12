# 第206講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `forge --version` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、evm osaka | foundry.toml | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |

付録のガスの数字と出力は、すべて上の環境で直接実行した結果である。二つの取引のデモは、ローカルのanvil一つに既定のテスト用アカウントで送った。外部のサービスへの要求・サブスクリプション・鍵は使っていない。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Vrf206Testのガスと結果 | 直接実行（`forge test --offline -vv`） | 2026-10-21 |
| anvilのアドレス・ブロック・ガス・当選者 | 直接実行（ローカルのanvil、デプロイするアカウントと順番を変えるとアドレスが変わる） | 2026-10-21 |
| VRFのセキュリティの考慮事項の原文 | Chainlink VRF v2.5 セキュリティの考慮事項: https://docs.chain.link/vrf/v2-5/security | 2026-10-21 |

## 参考資料

- Chainlink VRF v2.5のセキュリティの考慮事項の見出し六つ: "Use requestId to match randomness requests with their fulfillment in order", "Choose a safe block confirmation time, which will vary between blockchains", "Do not allow re-requesting or cancellation of randomness", "Don't accept bids/bets/inputs after you have made a randomness request", "fulfillRandomWords must not revert", "Use VRFConsumerBaseV2Plus in your contract, to interact with the VRF service"
- 同じドキュメントの、受け取る関数の失敗についての文: "If your fulfillRandomWords() implementation reverts, the VRF service will not attempt to call it a second time."
- VRF（Verifiable Random Function）の証明の計算（楕円曲線上の証明）: この講義では扱わない
- Foundry公式ドキュメント（`cast wallet sign`、anvil）: https://getfoundry.sh/
