# 第55講 addressのメンバーと送金の3種類

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第54講](../../part4/lecture54/) | [第4部 目次](../) | [第56講 →](../../part4/lecture56/)

## この講義の問い

アドレス一つで何ができ、イーサを送る三つの文法は、受け取る側が拒否したり処理をしようとしたりしたとき、それぞれどうなるのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める。テストにはforge-stdが必要である（`lib/forge-std`）。受け取ったガスとaddressのメンバーはanvilにデプロイして確かめ、既定のアカウント0番（公開されたテスト用の鍵）を使う。solc 0.8.30である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/Receivers.sol](code/src/Receivers.sol) | 受け取る側の四つ：receiveなし（`NoReceive`）、ストレージに1回書く（`Writer`）、無条件に巻き戻す（`Refuser`）、受け取ったガスをイベントに残す（`Probe`） |
| [code/src/Sender.sol](code/src/Sender.sol) | `transfer`、`send`、`call`で1イーサを送り、次の行で`reached`を増やすコントラクト |
| [code/src/Ignored.sol](code/src/Ignored.sol) | `send`と`call`の戻り値を捨てる版 |
| [code/src/Members.sol](code/src/Members.sol) | アドレスの`balance`、`code.length`、`codehash`の読み取り |
| [code/test/Transfer.t.sol](code/test/Transfer.t.sol) | 送り方三つ × 受け取る側三つの表、渡したガス、Writerへのtransferとcall |
| [code/test/Ignored.t.sol](code/test/Ignored.t.sol) | 戻り値を捨てた版が、失敗に気づかずに通り過ぎるかの確認 |

### 実行結果

`forge test --match-test test_Table -vv`。関数全体が巻き戻ったか、返ってきたbool、送る行の次の行が実行されたかを書いた。

```
[PASS] test_Table() (gas: 575677)
Logs:
  NoReceive
    transfer: revert (whole function)
    send    : ok=false, next line ran
    call    : ok=false, next line ran
  Writer
    transfer: revert (whole function)
    send    : ok=false, next line ran
    call    : ok=true, next line ran
  Refuser
    transfer: revert (whole function)
    send    : ok=false, next line ran
    call    : ok=false, next line ran
```

anvilで、ガスリミット100000でSenderの三つの関数をProbeに送った結果。`Gas(left)`はProbeのreceiveの中で測った残りのガスである。

```
== viaTransfer   status 0x1 gasUsed 54814   Gas(left) 2262
== viaSend       status 0x1 gasUsed 37862   Gas(left) 2262
== viaCall       status 0x1 gasUsed 38133   Gas(left) 67482
```

anvilでWriterに`viaTransfer`を送ると、status 0、gasUsed 33583である。`cast run`のトレースでは、receiveは`[2300]`で呼ばれ、`[OutOfGas] EvmError: OutOfGas`で終わる。同じWriterに`viaCall`を送ると、status 1、gasUsed 59276で、receiveは`[22363]`を使う。

Membersの`look`で三つのアドレスを読むと、codehashが三通りに分かれる。

| アドレス | コードの長さ | codehash |
|---|---|---|
| anvilの既定のアカウント0番（EOA） | 0 | `0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470`（`cast keccak 0x`と同じ） |
| Senderコントラクト | 1129 | `0xaef00dd5e264d65ed5b8e03d1b236a0b431fe930dbd9df84fd654404530d1a3c`（`cast codehash`と同じ） |
| 一度も使われていない`0x000000000000000000000000000000000000dEaD` | 0 | 0 |

### 試すときの注意

- 失敗したときにすることが三つとも違う。`transfer`は関数全体を巻き戻し、`send`と`call`はfalseを返して次の行に進む。戻り値を確かめなければ、送金が失敗しても関数は成功で終わる。
- `transfer`と`send`は、受け取る側に2300ガスしか渡さない。receiveでストレージに1回書くだけでも足りないので、Writerはこの二つでは受け取れない。`call`は残りのガスをほぼすべて渡す。
- `forge test`の中でtest_GasGivenを実行すると、call側の`Gas(left)`は1040319668と出る。テストの既定のガスリミットが大きいからで、上の67482はガスリミット100000でanvilから送った値である。
- 公式ドキュメントのBlindAuctionの例のwithdrawは、`call`を使い、`require(success)`で結果を確かめる。
- この実習のsolc 0.8.30は、`transfer`・`send`の行に警告を出さない。`send`の戻り値を捨てると警告5878が出るが、その文言はtransferを勧めている。0.8.31からは、addressの`send`・`transfer`の使用そのものに廃止予定の警告がつく。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンとネットワークのアップグレードによって変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidityドキュメント | v0.8.36、Types > Address > Members of Addresses / BlindAuctionの例のwithdraw（`call` + `require(success)`） | 2026-10-19 |
| solc | 0.8.30 | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| transfer・sendの使用への警告 | solc 0.8.30では`transfer`・`send`を使う行そのものに警告なし。0.8.31からaddressの`send`・`transfer`の使用に廃止予定の警告がつく。`send`の戻り値を捨てると警告5878、文言はtransferを勧める（0.8.30の出力） | 2026-10-20 |
| transfer・sendが渡すガス | 2300（イーサを載せた呼び出しの基本支給分） | 2026-10-19 |
| callが渡したガス | 67482（ガスリミット100000、anvil） | 2026-10-19 |
| Writerのreceiveのガス | callで受け取るとき22363 | 2026-10-19 |
| テストのガス | test_Table 575677、test_Ignored 114251、test_RevertWhen_WriterViaTransfer 43989、test_WriterViaCall 84163、test_GasGiven 141258 | 2026-10-19 |
| 価格表の変更履歴 | 2016.10 タンジェリン・ホイッスル（EIP-150）、2019.12 イスタンブール（EIP-1884、SLOAD 200 → 800、BALANCE・EXTCODEHASH 400 → 700）、2021.04 ベルリン（EIP-2929、SLOADのコールドアクセス2,100） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| delegatecall・staticcallの文法と危険 | [第117講](../../part6/lecture117/) |
| callでガスをすべて渡したときに受け取る側のコードができること、状態を先に変えてから送る順番 | [第83講](../../part5/lecture83/)、[第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| 自分で引き出しに来させる設計の一般的なパターン | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |
| 外部呼び出しの結果の扱い方、try/catch | [第90講](../../part5/lecture90/)、[第91講](../../part5/lecture91/)、[第170講](../../part11/lecture170/) |
| receive・fallback関数 | [第99講](../../part6/lecture99/) |
| 送金の文法をめぐるコンパイラの判定の変更履歴 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| アドレスにコードがあるかを問うことと、コントラクト型 | [第56講](../../part4/lecture56/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
