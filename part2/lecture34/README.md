# 第34講 デプロイスクリプトとコントラクトの検証

第2部 開発とテスト環境・第8章 デバッグ・計測・デプロイ

[← 第33講](../../part2/lecture33/) | [第2部 目次](../) | [第35講 →](../../part3/lecture35/)

## この講義の問い

テストを終えたコードを本物のチェーンに載せる手順とは何で、載ったバイトコードが自分のソースから出たものだということはどう示せるのか。

## 実習資料

### 準備

`forge init`で作ったプロジェクト（forge-stdを含み、initのサンプルCounterはそのまま）に`solc = "0.8.30"`を入れて始める。すべてのビルドに`--offline`をつける。デプロイ先はローカルのanvil（チェーン番号31337）で、署名にはanvilのデフォルトアカウント0番のテスト用の鍵を使う。実際のネットワークとブロックエクスプローラーには送らない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Counter.sol](code/src/Counter.sol) | initのサンプルCounter（`number`、`setNumber`、`increment`） |
| [code/script/Counter.s.sol](code/script/Counter.s.sol) | Counterをデプロイするinitのサンプルスクリプト |
| [code/script/CounterSet.s.sol](code/script/CounterSet.s.sol) | デプロイのあと`setNumber(10)`までbroadcastの中で送るスクリプト（直したバージョン） |
| [code/buggy/script/CounterSet.s.sol](code/buggy/script/CounterSet.s.sol) | `setNumber(10)`を`vm.stopBroadcast()`のあとに置いたバージョン。チェーンには送られない |
| [code/test/CounterSet.t.sol](code/test/CounterSet.t.sol) | スクリプトの`run()`をテストの中で実行してみるテスト |

`code/buggy/script/CounterSet.s.sol`は、そのフォルダだけではビルドできない。本体のプロジェクトの`script/CounterSet.s.sol`と入れ替えて実行する。

### 実行結果

`--broadcast`なしで`forge script script/Counter.s.sol --rpc-url <anvil> --private-key $K --offline`。シミュレーションだけをして何も送らないので、ナンスは0のままである：

```
Script ran successfully.
Chain 31337
Estimated total gas used for script: 203856
Estimated amount required: 0.000407712000203856 ETH
SIMULATION COMPLETE. To broadcast these transactions, add --broadcast and wallet configuration(s) to the previous command.
Transactions saved to: broadcast\Counter.s.sol\31337\dry-run\run-latest.json
```

`--broadcast`をつけると実際に送る。ナンスとブロック番号が1になる：

```
Script ran successfully.
ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
Transactions saved to: broadcast\Counter.s.sol\31337\run-latest.json
```

`broadcast/Counter.s.sol/31337/run-latest.json`の主な部分：

```
"transactions": [{
  "hash": "0x69605ca6fe400ae597789491530bbbeb70fd81ab8f69ddb140ca57eae7309328",
  "transactionType": "CREATE",
  "contractName": "Counter",
  "contractAddress": "0x5fbdb2315678afecb367f032d93f642f64180aa3",
  "transaction": { "from": "0xf39fd6e5…", "to": null, "nonce": "0x0", "chainId": "0x7a69", "input": "0x608060…" }
}],
"receipts": [{
  "status": "0x1", "blockNumber": "0x1", "gasUsed": "0x2648d",
  "contractAddress": "0x5fbdb2315678afecb367f032d93f642f64180aa3", "logs": []
}]
```

`cache/Counter.s.sol/31337/run-latest.json`には、RPCのアドレスのような機微になりうる値が別に残る。`forge init`が作った.gitignoreは、ローカルチェーン（31337）とdry-runの記録をコミットから除外する：

```
# Ignores development broadcast logs
!/broadcast
/broadcast/*/31337/
/broadcast/**/dry-run/
```

同じスクリプトでもう一度デプロイすると、アドレスが`0xe7f1725e7734ce288f8367e1bb143e90bb3f0512`（nonce 0x1）に変わる。アドレスはデプロイするアカウントとナンスで決まるので、`cast compute-address`で前もって計算できる：

```
--nonce 0   0x5FbDB2315678afecb367f032d93F642f64180aa3
--nonce 1   0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
--nonce 2   0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

バグのあるCounterSetスクリプトを`--broadcast`で実行すると、ログには`number: 10`と表示されるが、記録にはCREATEが1件（`0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0`）だけで、チェーンから読んだ`number()`は0である。`setNumber(10)`を`vm.stopBroadcast()`の上に移した直したバージョンは、CREATE（`0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9`、nonce 0x3）と`setNumber(uint256)`のCALL（nonce 0x4）の2件を送り、`number()`は10である。

スクリプトをテストの中で実行するテスト（`forge test --match-contract CounterSetScriptTest --offline`）：

```
[PASS] test_Run() (gas: 801646)
```

バグのあるスクリプトに入れ替えて実行しても`[PASS] test_Run() (gas: 801634)`である。テストの中では、broadcastの外の呼び出しもそのまま実行されるからである。

ローカルでやってみた検証。チェーンに載ったコード（`cast code`）と、同じソースを同じ設定でビルドしたコード（`forge inspect Counter deployedBytecode`）を`cmp`で比べると、出力がない（同じファイル）。ハッシュも同じである：

```
cast keccak (チェーン)   0xe83f6304215ec3e78661dc1b14562ee1a0b5be7375159e065f33553ab6642ee3
cast keccak (ローカル)   0xe83f6304215ec3e78661dc1b14562ee1a0b5be7375159e065f33553ab6642ee3
cast codehash             0xe83f6304215ec3e78661dc1b14562ee1a0b5be7375159e065f33553ab6642ee3
cast codesize             481
```

ランタイムコードの最後の53バイト（メタデータの尻尾）：

```
a264697066735822122097fceab4aea324c565cb782c819e2aa13e455f88904b0b9df2bc68db8fc4b37564736f6c634300081e0033
```

設定やソースが少しでも違うと一致しない。

| 変えたもの | ランタイムコード | チェーンのコードとの比較 |
|---|---|---|
| `--optimize` | 236バイト | 違う |
| `--evm-version paris` | 498バイト | 違う |
| `uint256 public number;`の上にコメント`// 現在の数字`を1行 | 481バイト | 438バイト目（0から）から違う、メタデータの尻尾だけが違う |
| ソースを`src/core/Counter.sol`に移動 | 481バイト | 尻尾の前の428バイトは同じで、尻尾が違う |

```
チェーン:   a2646970667358221220 97fceab4aea324c565cb782c819e2aa13e455f88904b0b9df2bc68db8fc4b375 64736f6c634300081e0033
コメント後: a2646970667358221220 61ee5eae2b0dbe18d4d399ec65e0940060d80b462ad189acff03ddd98bc5aa66 64736f6c634300081e0033
パス:       a264697066735822122080abab857d2df92fd36fe601703007c043ab246b0b7b9a25f959e9885be93b4464736f6c634300081e0033
```

コメントを消して再ビルドすると、チェーンのコードと同じになる。

### 試すときの注意

- ブロックエクスプローラーでの検証は実行していない。`forge verify-contract --help`の例に基づく手順は、APIキーの発行、`forge verify-contract <アドレス> <パス:名前> --chain <チェーン>`（または`forge script --broadcast --verify`）、エクスプローラーでのコンパイル・比較、アドレスのページでのソース表示の順である。Sourcifyは`--verifier sourcify`で使う。
- 鍵をコマンドにそのまま書く`--private-key`は、ローカルのテスト用の鍵にだけ使う。`forge script`には`--account`、`--keystore`、`--ledger`、`--interactive`のようなオプションもある。
- シミュレーションの見積もりガス（203856）と実際のgasUsed（156,813）は違う。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、数字とオプションが変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 実行環境 | Foundry 1.8.3（forge、cast、anvil）、solc 0.8.30、すべてのビルドで`--offline` | 2026-10-18 |
| anvilのチェーン番号 | 31337（0x7a69） | 2026-10-18 |
| シミュレーションの見積もりガス（Counterのデプロイ） | 203856、0.000407712000203856 ETH（anvilの最初のブロック基準） | 2026-10-18 |
| 実際のデプロイのgasUsed | 0x2648d（156,813） | 2026-10-18 |
| Counterのランタイムコードのサイズ | デフォルト481バイト、`--optimize` 236バイト、`--evm-version paris` 498バイト | 2026-10-18 |
| ブロックエクスプローラーでの検証の手順 | APIキーの発行 → `forge verify-contract <アドレス> <パス:名前> --chain <チェーン>`または`forge script --broadcast --verify` → エクスプローラーでのコンパイル・比較 → アドレスのページでのソース表示。Sourcifyは`--verifier sourcify` | 2026-10-18 |
| forge scriptの鍵のオプション | `--private-key`、`--account`、`--keystore`、`--ledger`、`--interactive`など | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Solidityの静的型、継承、ライブラリ | [第35講](../../part3/lecture35/) |
| デプロイ用のコード（生成コード）とランタイムコードの構造 | [第93講](../../part6/lecture93/) |
| CREATE2と前もって決めるアドレス | [第94講](../../part6/lecture94/) |
| Standard JSON入力とコンパイルの再現性、ソース検証の実務 | [第128講](../../part8/lecture128/)、[第130講](../../part8/lecture130/) |
| メタデータJSONの構造 | [第142講](../../part8/lecture142/) |
| アップグレード可能なコントラクト（プロキシ） | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 鍵の管理とマルチシグ | [第178講](../../part11/lecture178/) |
| 実際のネットワークへのデプロイスクリプトとエクスプローラーでの検証の運用 | [第262講](../../part20/lecture262/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
