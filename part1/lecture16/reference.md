# 第16講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Node.js | v24.11.0 | `node -v` | 2026-10-17 |

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| 基本ガス、ADD、MUL、MLOAD、MSTORE | evm.codes（fork=osaka）、ethereum.orgのガスの文書 | 2026-10-20 |
| SLOAD、SSTORE、アカウントへのアクセスのコールド・ウォームの値 | EIP-2200、EIP-2929 | ベルリン（2021.04）以降 |
| アクセスリストの前払い | EIP-2930 | ベルリン（2021.04）以降 |
| EIP-150の前後の値 | EIP-150 | 2016-10-18 |
| ブロックのガス総量 | 公開RPC（ethereum-rpc.publicnode.com）`eth_getBlockByNumber`、直近24時間のブロック300個の標本、EIP-7935 | 2026-10-20 |
| トランザクションのガスの上限 | EIP-7825 | 2026-10-20 |

## 参考資料

- Alan Turing, "On Computable Numbers, with an Application to the Entscheidungsproblem"（1936）。停止問題
- 上海DoS攻撃（2016年9〜10月）：ガスは安いのにディスクを多く読む命令を繰り返し、ネットワークを遅くした攻撃
- EIP-150（タンジェリン・ホイッスル、2016年10月18日）: https://eips.ethereum.org/EIPS/eip-150
- EIP-2200: https://eips.ethereum.org/EIPS/eip-2200
- EIP-2929（コールドアクセスとウォームアクセス、2021年4月 ベルリン）: https://eips.ethereum.org/EIPS/eip-2929
- EIP-2930（アクセスリスト）: https://eips.ethereum.org/EIPS/eip-2930
- EIP-7825（トランザクションのガスの上限）: https://eips.ethereum.org/EIPS/eip-7825
- EIP-7935（ブロックガスリミットの既定値60M）: https://eips.ethereum.org/EIPS/eip-7935
