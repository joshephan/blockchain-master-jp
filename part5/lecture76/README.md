# 第76講 blockとtxの属性

第5部 言語の詳細 ② グローバル変数と制御構造・第17章 単位とグローバル変数

[← 第75講](../../part5/lecture75/) | [第5部 目次](../) | [第77講 →](../../part5/lecture77/)

## この講義の問い

コントラクトが実行中に読むブロックとトランザクションの値は、誰が書いたものなのか。

## 実習資料

### 準備

第75講のMarketプロジェクトから始める。`demo`はビルドが通るバージョン、`errors`はエラー・警告を見るバージョンである。どちらもfoundry.tomlで`solc = "0.8.30"`に固定し、テストにはforge-std（`lib/forge-std`）が必要である。コントラクトはローカルのanvilに既定のアカウント0番で`forge create`し、アリスは既定のアカウント1番（anvilの公開されたテスト用の鍵）である。チェーン番号を見る実習では、anvilを`--chain-id 5`で立ち上げ直す。`errors`のファイルは`forge build --offline --force src/<ファイル>`で一つずつビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/BlockInfo.sol](code/demo/src/BlockInfo.sol) | ヘッダーの値を返す`header()`、`chain()`、blockhashを呼ぶ`hashOf`・`checkedHash`・`hashes()`、`gasLeft()`。txの値を記録するTxRecorder |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket（第72講のバージョン + 第75講の利息の下書き）に、最後の更新から経過した秒を返す`elapsedOf`を足したバージョン |
| [code/demo/test/Header.t.sol](code/demo/test/Header.t.sol) | チートコードでヘッダーの値を入れる`test_cheats`、0を返す`test_blockhash`、`vm.warp`で1日進める`test_elapsed` |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/Now.sol](code/errors/src/Now.sol) | 古い別名`now`、Error 7359 |
| [code/errors/src/Difficulty.sol](code/errors/src/Difficulty.sol) | `block.difficulty`と`block.prevrandao`を並べて読む、Warning 8417 |

### 実行結果

同じブロックでの`cast block`のヘッダーの欄と、`header()`が返した値。prevrandaoを`cast to-hex`で変換するとmixHashと同じになる。

| ヘッダーの欄 | グローバルの名前 | 値 |
|---|---|---|
| number | `block.number` | 2 |
| timestamp | `block.timestamp` | 1792394508 |
| baseFeePerGas | `block.basefee` | 877086267 |
| gasLimit | `block.gaslimit` | 30000000 |
| miner | `block.coinbase` | 0x0000000000000000000000000000000000000000 |
| mixHash | `block.prevrandao` | 0xc2dcadf9...5a39 |

`evm_setNextBlockTimestamp`、`anvil_setCoinbase`、`evm_mine`で次のブロックの時刻と手数料の受け取りアドレスを決めたあと、`header()`を呼んだ結果。コントラクトはそのままで、読んだ値だけが変わる。

```
$ cast rpc evm_setNextBlockTimestamp 1900000000
$ cast rpc anvil_setCoinbase 0x000000000000000000000000000000000000c0DE
$ cast rpc evm_mine
$ cast call $INFO "header()(uint256,uint256,uint256,uint256,address,uint256)"
3
1900000000 [1.9e9]
768623755 [7.686e8]
30000000 [3e7]
0x000000000000000000000000000000000000c0DE
92620279922791941653146174633661333912143795306636592812392980905716649614123 [9.262e76]
```

`forge test --offline -vv`:

```
[PASS] test_blockhash() (gas: 21763)
[PASS] test_cheats() (gas: 19116)
[PASS] test_elapsed() (gas: 203730)
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

`anvil_mine 300`で一度に作ったブロックは、時刻がすべて同じである（ブロック5、47、304はどれも1900000050）。

`now`と`block.difficulty`のビルド結果と、Difficultyをデプロイして`both()`を呼んだ結果。二つの値は同じである。

```
Error (7359): "now" has been deprecated. Use "block.timestamp" instead.
Warning (8417): Since the VM version paris, "difficulty" was replaced by "prevrandao", which now returns a random number based on the beacon chain.
$ cast call $DIFF "both()(uint256,uint256)"
5820517227755462595945514055521143202317446683799627573037419596267148525619 [5.82e75]
5820517227755462595945514055521143202317446683799627573037419596267148525619 [5.82e75]
```

新しいanvilでブロック301まで作ったあとに呼んだ`blockhash`。今のブロックと257ブロック前は、リバートせずに0になる。

```
$ cast call $INFO "hashes()(bytes32,bytes32,bytes32)"
0x0000000000000000000000000000000000000000000000000000000000000000
0x0f25c119c7f602aa39df0813adfe72c37da2a9faedc10a641bdcbe71ce70a0cd
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast call $INFO "hashOf(uint256)(bytes32)" 45
0x2ac0bf7c36726e77ddad1b74438b50f3279bbf04f7e8931742d3320ec18a0739
$ cast call $INFO "hashOf(uint256)(bytes32)" 44
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast call $INFO "checkedHash(uint256)(bytes32)" 44
Error: execution reverted: no hash
```

アリスが`record()`を`--gas-price 5gwei --priority-gas-price 2gwei`で送った結果。`tx.gasprice`は、ベースフィー672,545,786に優先手数料2,000,000,000を足した値である。

```
$ cast call $REC "gasPrice()(uint256)"
2672545786 [2.672e9]
$ cast call $REC "basefee()(uint256)"
672545786 [6.725e8]
$ cast call $REC "origin()(address)"
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

`gasLeft()`は`--gas-limit 100000`のとき78798、指定しないと29978798である。`chain()`は既定のanvilで31337、`--chain-id 5`のanvilで5である。

Marketにアリスが500を預けたあと`elapsedOf`を読み、次のブロックの時刻を86400秒後に決めてからもう一度読んだ結果。

```
$ cast call $MARKET "elapsedOf(address,address)(uint256)" 0x000000000000000000000000000000000000AAAA $ALICE
0
$ cast rpc evm_setNextBlockTimestamp 1900086529
$ cast rpc evm_mine
$ cast call $MARKET "elapsedOf(address,address)(uint256)" 0x000000000000000000000000000000000000AAAA $ALICE
86400 [8.64e4]
```

### 試すときの注意

- ブロックの時刻、ベースフィー、prevrandao、ブロックハッシュは、anvilを立ち上げた時刻によって変わる。実行し直すと別の値が出る。
- `blockhash(n)`は直近256ブロックにしか答えない。今のブロック、257ブロック前、まだ来ていないブロックは失敗せずに0を返すので、`require(h != bytes32(0))`のように呼ぶ側でふるい落とす。
- 期限はブロック番号ではなく秒で書く（`block.timestamp + 1 days`）。空のスロットがあると、7,200ブロックは1日より長くなる。
- 関数名を`elapsed`にすると、第75講の`interestFor`の引数名と重なってWarning 8760が出る。そのため`elapsedOf`と名づけた。
- `elapsedOf`の経過秒は、ブロックを作った側が書いた`block.timestamp`で決まる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidityのバージョンごとの導入・削除 | `block.chainid` 0.8.0、`block.basefee` 0.8.7、`block.prevrandao`の導入と`block.difficulty`の非推奨化 0.8.18、`block.blobbasefee`・`blobhash` 0.8.24、`now`の削除 0.7.0 | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3、anvilの既定のハードフォーク Bpo1、既定のチェーン番号 31337、既定のガスリミット 30,000,000 | 2026-10-19 |
| メインネットのブロック時刻の規則 | The Merge以降はそのスロットの時刻で決まる、スロットは12秒間隔（ブロック26224960〜26225110の151個はすべて12秒間隔） | 2026-10-19 |
| メインネットのブロックの例 | 26225110: gasLimit 60,000,000、baseFeePerGas 40,543,785、miner 0x396343362be2A4dA1cE0C1C210945346fb82Aa49、difficulty 0 | 2026-10-19 |
| EIP-2935 | 直近8191ブロックのハッシュをシステムコントラクト0x0000F90827F1C53a10cb7A02335B175320002935に置く。`blockhash`の範囲は256ブロックのまま | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `msg.sender`と`tx.origin`が分かれる場合 | [第77講](../../part5/lecture77/) |
| チェーン番号を署名メッセージに入れて使う方法 | [第79講](../../part5/lecture79/) |
| `require`とエラーの文法全般 | [第90講](../../part5/lecture90/) |
| 経過秒で利息を積み上げる計算とガス | [第143講](../../part9/lecture143/) |
| ブロックの時刻を動かして得をする場合 | [第172講](../../part11/lecture172/)、[第175講](../../part11/lecture175/) |
| `prevrandao`・`blockhash`を乱数に使うときの問題と代替案 | [第175講](../../part11/lecture175/) |
| 権限チェックに`tx.origin`を使ってよいか | [第151講](../../part9/lecture151/)、[第176講](../../part11/lecture176/) |
| blob関連の値（`block.blobbasefee`、`blobhash`） | [第230講](../../part17/lecture230/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
