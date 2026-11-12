# 第90講 例外処理：assert、require、revert

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第89講](../../part5/lecture89/) | [第5部 目次](../) | [第91講 →](../../part5/lecture91/)

## この講義の問い

リバートすると正確に何が消え、リバートさせる三つの文法はそれぞれどんな失敗を表すのか。

## 実習資料

### 準備

`demo`（第90講のバージョンのMarketとデモのコード）、`before`（第89講の終わりのバージョンのMarketとそのテスト）、`errors`（ビルドエラーのバージョン）は、空のFoundryプロジェクトでfoundry.tomlに`solc = "0.8.30"`を固定し、forge-stdを`lib/forge-std`に置く。`old`はforge-stdなしでsolc 0.7.6でビルドし、そのバージョンのsolcがインストールされている必要がある。コントラクトはローカルのanvilに既定のアカウント0番（anvilの公開されたテスト用の鍵）で`forge create`する。MockTokenは`--constructor-args 1000`を、Checksは`--value 1ether`をつけてデプロイする。Marketにはデプロイ後に`addAsset(トークン, 75)`、`approve`、`deposit(トークン, 100)`の順に送る。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 第90講のバージョンの通しプロジェクトのMarket。`zero asset`・`zero amount`の検査、カスタムエラー`InsufficientDeposit(have, want)`、合計の欄の`assert` |
| [code/demo/src/Tokens.sol](code/demo/src/Tokens.sol) | デモ用のMockTokenと、transfer・transferFromでfalseだけを返すFalseToken |
| [code/demo/src/Order.sol](code/demo/src/Order.sol) | 欄を書き換えてイベントを出したあと、数量の検査でリバートする`place`、ガスを使い切る`burn`、内側の呼び出しだけがリバートするOuter |
| [code/demo/src/Errors.sol](code/demo/src/Errors.sol) | `require`・`revert`・`assert`とカスタムエラーの5行（Errors）、初めて見るPanic 0x22・0x41（Panics） |
| [code/demo/src/Checks.sol](code/demo/src/Checks.sol) | スライスの前の長さの確認（Args）、低水準のcall・send・blockhash・ecrecoverの結果を確かめる行（Checks）、受け取りを拒むRefuser |
| [code/demo/src/NewAssert.sol](code/demo/src/NewAssert.sol) | 0.8.30でビルドした`assert`の失敗のガスの比較用 |
| [code/demo/src/Packed.sol](code/demo/src/Packed.sol) | 第73講のMarketPacked（欄を二つに減らしたバージョン） |
| [code/demo/src/PackedSafe.sol](code/demo/src/PackedSafe.sol) | 第73講のMarketPackedSafe（値を縮める前に確かめるバージョン） |
| [code/demo/test/Market.t.sol](code/demo/test/Market.t.sol) | 理由まで書いたexpectRevert六つ |
| [code/before/foundry.toml](code/before/foundry.toml) | solc 0.8.30に固定 |
| [code/before/src/Market.sol](code/before/src/Market.sol) | 第89講の終わりのバージョンのMarket（第90講の行を入れる前） |
| [code/before/src/Tokens.sol](code/before/src/Tokens.sol) | `demo`と同じデモ用のトークン |
| [code/before/test/Withdraw.t.sol](code/before/test/Withdraw.t.sol) | 理由なしのexpectRevertと、理由を書いたexpectRevert |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/Typo.sol](code/errors/src/Typo.sol) | カスタムエラーの名前の打ち間違い、Error 7576 |
| [code/old/foundry.toml](code/old/foundry.toml) | solc 0.7.6、forge-stdなし |
| [code/old/src/OldAssert.sol](code/old/src/OldAssert.sol) | NewAssertと同じコード（pragmaだけ0.7.6） |

### 実行結果

第89講の終わりのバージョン（`before`）で、100を預けたあと150を引き出すと、理由は算術のあふれだけである。

```
$ cast send $M89 "withdraw(address,uint256)" $TK 150 --private-key $PK0
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: panic: arithmetic underflow or overflow (0x11), data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000011": Panic(17)
```

Orderの`place(11)`を、ガスリミットを指定して送った結果。ブロックには入るがstatusは0で、logsは空である。`cast storage $O 0`は0のままで、アカウント0番のナンスは7から8に、残高は18,444,693,048,222 wei（gasUsed × effectiveGasPrice）減った。

```
$ cast send $O "place(uint256)" 11 --gas-limit 100000 --private-key $PK0
blockNumber          8
effectiveGasPrice    402467718
gasUsed              45829
logs                 []
status               0 (failed)
```

Outerで`tryPlace($O, 11)`はstatus 1（success、gasUsed 74802）で終わり、triesは1、lastOkはfalse、Orderのcountは0が残る。

Errorsを`cast call`で呼んだ結果（Contextの行の前半は省略）。

```
$ cast call $E "reqMsg(uint256)" 0
Error: execution reverted: zero
... data: "0x08c379a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000047a65726f00000000000000000000000000000000000000000000000000000000"
$ cast call $E "reqErr(uint256)" 0
Error: execution reverted: Zero
... data: "0xf4560403"
$ cast call $E "revErr(uint256)" 5
Error: execution reverted: TooSmall(5, 10)
... data: "0xe94fe3af0000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000a"
$ cast call $E "asrt(uint256)" 0
Error: execution reverted: panic: assertion failed (0x01)
... data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000001"
```

リバートデータの先頭4バイトは`cast sig`で確かめる：`Error(string)` 0x08c379a0、`Panic(uint256)` 0x4e487b71、`Zero()` 0xf4560403、`TooSmall(uint256,uint256)` 0xe94fe3af。

Panicsとガスの使い切り。

```
$ cast call $P "p22()(uint256)"
Error: execution reverted: panic: storage byte array incorrectly encoded (0x22)
$ cast call $P "p41()(uint256)"
Error: execution reverted: panic: memory allocation error (0x41)
$ cast send $O "burn(uint256)" 1000000 --gas-limit 100000 --private-key $PK0
gasUsed              100000
logs                 []
status               0 (failed)
```

同じ上限100,000で`asrt(0)`を送ると、0.7.6のビルド（OldAssert）はgasUsed 100,000、0.8.30のビルド（NewAssert）は23,853である。

エラー名の打ち間違いは、ビルドで止まる（`errors`）。

```
Error (7576): Undeclared identifier. Did you mean "TooSmall"?
 --> src/Typo.sol:8:28:
  |
8 |         if (x < 10) revert TooSmal(x, 10);
  |                            ^^^^^^^
```

MarketPackedSafeに2の128乗 + 5を入れると、理由を書いた検査でリバートする。Argsは3バイトの入力に対して、確認の行がないバージョンは空のリバートデータを、あるバージョンは受け取った長さを返す。

```
$ cast call $PS "deposit(address,uint256)" 0x000000000000000000000000000000000000aaaa 340282366920938463463374607431768211461
Error: execution reverted: amount too large
$ cast call $AR "firstArgRaw(bytes)(uint256)" 0x010203
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call $AR "firstArg(bytes)(uint256)" 0x010203
Error: execution reverted: ShortInput(3)
$ cast call $AR "firstArg(bytes)(uint256)" 0xa9059cbb0000000000000000000000000000000000000000000000000000000000000b0b
2827
```

`before`での`forge test --offline`。引数なしのexpectRevertはPanic 0x11でも通り、理由を書いたexpectRevertは失敗しながら、いま止めている理由をあらわにする。

```
Ran 2 tests for test/Withdraw.t.sol:WithdrawTest
[PASS] test_anyRevert() (gas: 38053)
[FAIL: Error != expected error: panic: arithmetic underflow or overflow (0x11) != custom error 0x25c3f46e: 00000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000096] test_reason() (gas: 39155)
```

Checksの確認の行が止めた実行（今のブロック番号が20のときに呼んだ。25番はこれから来るブロックである。`$RF`はRefuser、`$ONE`は最後の桁だけが1の32バイト）。

```
$ cast call $CK "lowCall(address)" $RF
Error: execution reverted: call failed
$ cast call $CK "sendIt(address)" $RF
Error: execution reverted: send failed
$ cast call $CK "hashOf(uint256)(bytes32)" 25
Error: execution reverted: no blockhash
$ cast call $CK "signerOf(bytes32,uint8,bytes32,bytes32)(address)" $ONE 29 $ONE $ONE
Error: execution reverted: bad signature
```

第90講のバージョンのMarket（`demo`）での同じ150の引き出しと、`forge test --offline --match-contract MarketTest`。0x64は100、0x96は150である。

```
$ cast send $M "withdraw(address,uint256)" $TK 150 --private-key $PK0
Error: Failed to estimate gas: ... data: "0x25c3f46e00000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000096": InsufficientDeposit(100, 150)

Ran 6 tests for test/Market.t.sol:MarketTest
[PASS] test_falseToken() (gas: 110301)
[PASS] test_notAdmin() (gas: 36333)
[PASS] test_notListed() (gas: 36264)
[PASS] test_withdrawTooMuch() (gas: 39249)
[PASS] test_zeroAmount() (gas: 38560)
[PASS] test_zeroAsset() (gas: 33700)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

### 試すときの注意

- リバートすると、状態の変更とイベントのログが一緒に消える。ブロックに入ったという記録と払った手数料、ナンスの増加は残る。トレース（`cast run`）は、実行し直した自分の画面にしかない。
- ガスリミットを指定しないと、castはガスの見積もり中にリバートを見て送らない。リバートしたトランザクションを実際に残すには`--gas-limit`を指定する。
- リバートデータの先頭4バイトで分類する。`require`・`revert`の文字列は`Error(string)`、`assert`と言語の検査は`Panic(uint256)`、カスタムエラーはそのエラーのセレクタである。ガスの使い切りにはリバートデータがない。
- 文字列の理由の打ち間違いはビルドを通るが、カスタムエラーの名前の打ち間違いはビルドで止まる。
- `require`の中にカスタムエラーを書く形は、0.8.30の既定のコード生成でビルド・動作を確認した。
- 低水準の`call`、`send`、`blockhash`、`ecrecover`は、失敗をリバートではなく値で返す。受け取った値を名前に入れ、すぐ次の行で`require`で確かめる。
- テストの`vm.expectRevert`には理由まで書く。引数なしで使うと、見当違いの理由でリバートしても通ってしまう。
- カスタムエラーはストレージの欄を使わない。Marketのスロットマップはそのままである。
- ガス価格と残高はローカルのanvilの値なので、実行し直すと変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン。`old`だけ0.7.6 | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| カスタムエラー | solc 0.8.4から | 2026-10-19 |
| `require`の中のカスタムエラー | 0.8.26からvia-IR、0.8.27から既定のコード生成 | 2026-10-19 |
| 0.8.0より前の`assert` | 失敗するとINVALIDで残りのガスをすべて使う。上限100,000で`asrt(0)`: 0.7.6のビルドのgasUsed 100,000、0.8.30のビルド 23,853 | 2026-10-19 |
| セレクタ | `Error(string)` `0x08c379a0`、`Panic(uint256)` `0x4e487b71`、`Zero()` `0xf4560403`、`TooSmall(uint256,uint256)` `0xe94fe3af`、`ShortInput(uint256)` `0x0c7522bb`、`InsufficientDeposit(uint256,uint256)` `0x25c3f46e` | 2026-10-19 |
| Panicのコード | 0x01、0x11、0x12、0x21、0x22、0x31、0x32、0x41、0x51（0x00はコンパイラが入れる一般的なPanic） | 2026-10-19 |
| gasUsed | place(11) 45,829、tryPlace 74,802、burn(1000000) 100,000（上限すべて） | 2026-10-19 |
| 手数料 | place(11): effectiveGasPrice 402,467,718、残高の減少 18,444,693,048,222 wei、ナンス 7 → 8（ローカルのanvil） | 2026-10-19 |
| テストのガス | WithdrawTest test_anyRevert 38,053、test_reason 39,155 / MarketTest 110,301・36,333・36,264・39,249・38,560・33,700 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `try`/`catch`で他人の失敗を受け取る、`catch`節の分岐、受け取ったバイトのセレクタの比較 | [第91講](../../part5/lecture91/) |
| カスタムエラーの宣言の位置とエンコードの詳細 | [第108講](../../part6/lecture108/) |
| `require`の文字列とカスタムエラーのデプロイサイズ・ガスの比較 | [第109講](../../part6/lecture109/) |
| modifierに入れた`require`の検査 | [第104講](../../part6/lecture104/) |
| イベントの宣言と発行、ログの構造、チェーンの外でログを読むこと | [第105講](../../part6/lecture105/)、[第106講](../../part6/lecture106/)、[第107講](../../part6/lecture107/) |
| `Error(string)`のリバートデータのABIエンコードの規則（オフセット、長さ） | [第141講](../../part8/lecture141/) |
| 失敗した送金を扱う引き出しパターン | [第150講](../../part9/lecture150/) |
| 外部呼び出しの結果を扱う実務の基準、falseを返したり何も返さなかったりするトークン | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| `assert`で書く不変条件の設計とファジング | [第183講](../../part11/lecture183/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
