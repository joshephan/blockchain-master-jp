# 第55講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | `cast --version` | 2026-10-19 |
| solc | 0.8.30 | foundry.toml `solc = "0.8.30"` | 2026-10-19 |

付録のテストの出力、ガス、トレースは、すべて上の環境とローカルのanvilで直接実行した結果である。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| Solidityドキュメント | solidityリポジトリのタグv0.8.36、Types > Address > Members of Addresses、BlindAuctionの例 | 2026-10-19 |
| transfer・sendの使用への警告 | 0.8.30は直接実行、0.8.31はargotorg/solidityのChangelog.mdの0.8.31の項目 | 2026-10-20 |
| transfer・sendが渡すガス | 直接測定（トレースの`[2300]`、Probeのgasleft 2262） | 2026-10-19 |
| callが渡したガス | 直接測定（anvil、ガスリミット100000） | 2026-10-19 |
| Writerのreceiveのガス | `forge test -vvvv`のトレース | 2026-10-19 |
| テストのガス | `forge test`を直接実行 | 2026-10-19 |
| 価格表の変更履歴 | EIP-150、EIP-1884、EIP-2929の文書、第16講の時効性のあるデータ | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメントv0.8.36: https://docs.soliditylang.org/en/v0.8.36/
  - Types > Address > Members of Addresses（`balance`、`code`、`codehash`、`transfer`、`send`、`call`）
  - 例Blind Auctionの`withdraw`（`call`のあとに`require(success)`）
- Solidity Changelog.mdの0.8.31の項目（addressの`send`・`transfer`の廃止予定の警告）
- EIP-150 Gas cost changes for IO-heavy operations（タンジェリン・ホイッスル、2016年10月）: https://eips.ethereum.org/EIPS/eip-150
- EIP-1884 Repricing for trie-size-dependent opcodes（イスタンブール、2019年12月。SLOAD 200 → 800、BALANCE・EXTCODEHASH 400 → 700）: https://eips.ethereum.org/EIPS/eip-1884
- EIP-2929 Gas cost increases for state access opcodes（ベルリン、2021年4月。SLOADのコールドアクセス2,100）: https://eips.ethereum.org/EIPS/eip-2929
- Foundry公式ドキュメント（`cast run`、`cast codehash`、`cast keccak`）: https://getfoundry.sh/
