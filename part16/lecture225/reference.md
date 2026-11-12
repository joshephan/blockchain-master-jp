# 第225講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `anvil --version` | 2026-10-21 |
| anvilの順番のルール | `--order fees`（チップの大きい順）、`--order fifo`（入ってきた順） | `anvil --help` | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | `foundry.toml` | 2026-10-21 |
| forge-std | 1.17.0 | `lib/forge-std/package.json` | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | `lib/openzeppelin-contracts/package.json` | 2026-10-21 |

付録のアドレス、ハッシュ、ガス、残高、エラーはすべて上の環境で直接実行した結果である。取引はローカルのanvilのデフォルトのテスト用アカウントだけで送った。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 置き換えを拒否する閾値、baseFee、ガス、手数料、アドレス、ハッシュ | 直接実行（anvilでJSON-RPC `evm_setAutomine`・`eth_newPendingTransactionFilter`・`txpool_status`・`eth_getFilterChanges`・`txpool_content`・`evm_mine`、cast `send --async`・`calldata-decode`・`run`） | 2026-10-21 |
| 委任の印があるEOAの保留中の取引 | EIP-7702原文 "Transaction propagation"節（573〜602行目、引用は589〜591行目） | 2026-10-21 |

## 参考資料

- EIP-7702 Set Code for EOAs, "Transaction propagation"節: https://eips.ethereum.org/EIPS/eip-7702
- OpenZeppelin Contracts v5.4.0 `contracts/utils/math/Math.sol`（ToyAmmが使う`Math`）
- Foundry 公式ドキュメント: https://getfoundry.sh/
