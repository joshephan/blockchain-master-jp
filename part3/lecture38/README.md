# 第38講 ブラインドオークション

第3部 Solidity入門・第10章 Solidity by Example

[← 第37講](../../part3/lecture37/) | [第3部 目次](../) | [第39講 →](../../part3/lecture39/)

## この講義の問い

誰もがすべてを見られるチェーンの上で、入札額を締め切りまでどうやって隠すのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトからCounterのファイル三つを消して始める。テストにはforge-stdが必要である（`lib/forge-std`）。`src/SimpleAuction.sol`と`src/BlindAuction.sol`は、Solidity公式ドキュメントv0.8.36のSolidity by Exampleにある二つの例の原文そのままである（pragma `^0.8.4`）。foundry.tomlで`lint_on_build`をオフにしたのは、ビルドのときにドキュメントの例に対するforge lintの警告（block.timestampの比較など）が長くつくからである。コンパイル結果は同じである。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルド時のlintをオフ |
| [code/src/SimpleAuction.sol](code/src/SimpleAuction.sol) | 公式ドキュメントの公開オークションの例の原文 |
| [code/src/BlindAuction.sol](code/src/BlindAuction.sol) | 公式ドキュメントのブラインドオークションの例の原文 |
| [code/src/BlindAuctionFlipped.sol](code/src/BlindAuctionFlipped.sol) | reveal内の`refund += bidToCheck.deposit;`の1行を、すぐ下のifのかたまりの後ろに移したコピー |
| [code/test/BlindAuction.t.sol](code/test/BlindAuction.t.sol) | コミット値の計算、secretなしでのハッシュの当てっこ、間違った・正しいsecretでのreveal、早すぎる終了、順序を逆にしたコピー |

### 実行結果

`forge test -vv`：

```
Ran 7 tests for test/BlindAuction.t.sol:BlindAuctionTest
[PASS] test_Commit() (gas: 3921)
Logs:
  0x1062d3bf99c11a0546b98e3d5293732f3176444a56d354db46551b75c53653a1

[FAIL: TooEarly(172801 [1.728e5])] test_EndTooEarly() (gas: 32194)
[FAIL: panic: arithmetic underflow or overflow (0x11)] test_FlippedOrder() (gas: 192818)
[PASS] test_GuessWithSecret() (gas: 15894)
Logs:
  hits: 0

[PASS] test_GuessWithoutSecret() (gas: 15916)
Logs:
  found ether: 7

[PASS] test_RightSecret() (gas: 214646)
Logs:
  refund (wei): 2000000000000000000
  highestBid: 3000000000000000000

[PASS] test_WrongSecret() (gas: 162532)
Logs:
  refund (wei): 0
  highestBid: 0

Suite result: FAILED. 5 passed; 2 failed; 0 skipped
```

二つのFAILは意図した結果である。`test_EndTooEarly`は入札期間だけを越えて公開期間内に`auctionEnd`を呼んだもの（172801はテスト内のrevealEnd）、`test_FlippedOrder`は引き算の順序を逆にしたコピーのあふれである。

同じコミット値をcastで確かめた結果。`cast format-bytes32-string alice-secret`、`cast to-wei 3`で値を作り、`cast abi-encode --packed "f(uint256,bool,bytes32)"`でつなげたあと`cast keccak`：

```
0x00000000000000000000000000000000000000000000000029a2241af62c000000616c6963652d7365637265740000000000000000000000000000000000000000
0x1062d3bf99c11a0546b98e3d5293732f3176444a56d354db46551b75c53653a1
```

`abi.encodePacked`は、uint256の32バイト、boolの1バイト、bytes32の32バイトをそのままつなげる。真ん中の`00`がfalseである。参考までに、JavaScriptの数値ではweiの単位をそのまま扱えない（`node -e "console.log(2500000000000000001)"`の出力は`2500000000000000000`）。

ローカルのanvilでの公開オークション（SimpleAuction、入札期間60秒）。二つのアカウントが2 ether、2.5 etherを賭けたあと、`cast tx <ハッシュ> value`と`highestBid()`で金額がそのまま見え、3番目のアカウントが1 weiだけ上乗せして勝つ：

```
2500000000000000000
2500000000000000000 [2.5e18]
2500000000000000001 [2.5e18]
```

ブラインドオークション（BlindAuction、入札60秒、公開60秒）。3 etherのコミットを5 etherの保証金と一緒に送ったトランザクションは、金額とハッシュがそのまま見える（`cast tx <ハッシュ> value`、`input`）：

```
5000000000000000000
0x957bb1e01062d3bf99c11a0546b98e3d5293732f3176444a56d354db46551b75c53653a1
```

入札期間内に`auctionEnd`と`reveal`を呼ぶと、どちらも`TooEarly`でリバートされる：

```
execution reverted: custom error 0x2a35a324: ...: TooEarly(1792374122 [1.792e9])
execution reverted: custom error 0x2a35a324: ...: TooEarly(1792374062 [1.792e9])
```

`cast rpc evm_increaseTime 61`、`cast rpc evm_mine`で時間を進めたあと二つのアカウントがrevealすると（3 ether、4 ether）、最高額は4 ether、最高入札者は2番のアカウントである。押し出された1番のアカウントの`pendingReturns`の欄（`forge inspect BlindAuction storageLayout`のSlot 7、`cast index address <1番のアカウント> 7`）には3 etherが入っていて、`withdraw()`のあとは0になる：

```
0x00000000000000000000000000000000000000000000000029a2241af62c0000
0x0000000000000000000000000000000000000000000000000000000000000000
```

公開期間が終わったあとに`auctionEnd()`を呼ぶと受益者の残高が10000から10004 etherになり、もう一度呼ぶとリバートされる：

```
execution reverted: custom error 0x61cfdcf8, data: "0x61cfdcf8": AuctionEndAlreadyCalled
```

### 試すときの注意

- `biddingEnd`、`revealEnd`はデプロイ時刻から決まるので、もう一度実行すると値が変わる。
- `evm_increaseTime`の出力は、それまでに累積で進めた秒数である（61、次は121）。
- 公開オークションで押し出された金額は、`withdraw`を呼ぶまでコントラクトに残る。アカウントの残高を比べるときは、この分を引いて見る。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidity公式ドキュメントのバージョン | v0.8.36（Solidity by Example、Blind Auctionの節） | 2026-10-19 |
| solcのバージョン | 0.8.30 | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| メインネットのブロック時刻の規則 | マージ以降はスロットの時刻で決まる、スロットは12秒間隔 | 2026-10-19 |
| 実行例のブロック時刻 | biddingEnd 1792374062、revealEnd 1792374122（anvilの実行時刻基準、再実行すると変わる） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 整数型のサイズごとの範囲、uncheckedを使ってよい場面 | [第51講](../../part4/lecture51/)、[第52講](../../part4/lecture52/)、[第88講](../../part5/lecture88/)、[第89講](../../part5/lecture89/) |
| 金額の単位と丸め、固定小数点の計算 | [第53講](../../part4/lecture53/) |
| modifierの文法全体 | [第48講](../../part4/lecture48/) |
| withdrawが帳簿を先に0にしてから送る理由 | [第83講](../../part5/lecture83/)、[第150講](../../part9/lecture150/)、[第168講](../../part11/lecture168/) |
| お金を引き出しに来させる設計の一般的なパターン | [第55講](../../part4/lecture55/)、[第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |
| ブロック時刻と、ブロックを作る側の権限 | [第76講](../../part5/lecture76/)、[第175講](../../part11/lecture175/) |
| コミット・リビールを使うほかの設計 | [第175講](../../part11/lecture175/)、[第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/)、[第215講](../../part14/lecture215/)、[第216講](../../part14/lecture216/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
