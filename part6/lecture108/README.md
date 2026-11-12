# 第108講 カスタムエラーの宣言とエンコード

第6部 言語の詳細 ③ コントラクト・第24章 カスタムエラー

[← 第107講](../../part6/lecture107/) | [第6部 目次](../) | [第109講 →](../../part6/lecture109/)

## この講義の問い

`error`を宣言して`revert`でリバートすると、呼んだ側には正確にどんなバイトが行き、受け取る側はそのバイトから何がわかり、何は別に持っておかなければならないのか。

## 実習資料

### 準備

第107講の終わりのMarketのプロジェクトから始め、十一個の文字列の理由をカスタムエラーに変え、`IMarket`にエラーの規格を書く。エラーの宣言とリバートデータのデモは、別に作ったデモ用のプロジェクト（`demo`）の`Vault`・`Taker`で行い、ローカルのanvilにデプロイして`cast call`でリバートデータを見る。ビルドが止める場合は、`errors/`の下のフォルダごとに別々にビルドする。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Err.sol](code/demo/src/Err.sol) | エラーを宣言する四つの場所（ファイルレベルの`Unauthorized`、`IVault`、`Lib`、`Vault`）と、受け取る側の`Taker`（`catch (bytes memory)`で受け取ってセレクタを比較、`shortArgs`で引数を解く） |
| [code/demo/test/Err.t.sol](code/demo/test/Err.t.sol) | `tryTakeArgs`で解いた引数、インターフェースとコントラクトの`Short.selector`が同じか |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/errors/](code/errors/) | ビルドエラー・警告の確認用のソース。`noparen`（2314）、`asvalue`（6359）、`emiterr`（9292）、`argcount`（6160）、`mapping`（3448）、`dup`・`sameevent`（2333）、`reserved`（1855）、`catchname`（3542）、`encerr`（9582）、`shadow`（警告2519）、`overevent`（イベント`Set`が二つ、ビルドは通る） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第108講のバージョンのMarket。ファイルレベルのエラーを十一個追加、`require(条件, エラー(引数))`の形に変えた |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | 十二個のエラーの規格（セレクタのコメントを含む）を加えたインターフェース |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン（`setBroken`で止められる） |
| [code/market/test/ErrorData.t.sol](code/market/test/ErrorData.t.sol) | この講義で加えたテスト。InsufficientDepositの68バイト、try/catchでNotAdminを受け取る、トークンが出したリバートが上がってくるか |
| [code/market/test/Selectors.t.sol](code/market/test/Selectors.t.sol) | `test_errorSelectorsMatch`を追加（IMarketとMarketのエラーのセレクタ十二個） |
| [code/market/test/Status.t.sol](code/market/test/Status.t.sol)、[code/market/test/WithdrawAll.t.sol](code/market/test/WithdrawAll.t.sol) | `vm.expectRevert`を文字列からエラーのデータに変えた |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト |

### 実行結果

第107講のバージョンのMarketの二つの失敗（`cast call`）。第90講で入れたカスタムエラーと、`require`の文字列のデータ。

```
$ cast call $M "withdraw(address,uint256)" $TK 150 --from $A0 --rpc-url $R
Error: execution reverted: InsufficientDeposit(100, 150)
... data: "0x25c3f46e00000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000096"

$ cast call $M "setStatus(uint8)" 2 --from $A1 --rpc-url $R
Error: execution reverted: not admin
... data: "0x08c379a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000096e6f742061646d696e0000000000000000000000000000000000000000000000"
```

ビルドが止める場合（`forge build`、変えた行とエラーの行）。

```
revert Closed;            Error (2314): Expected '(' but got ';'
return Short(1, 2);       Error (6359): Return argument type error is not implicitly
                          convertible to expected type (type of first return variable) bytes memory.
emit Short(1, 2);         Error (9292): Expression has to be an event invocation.
revert Short(1);          Error (6160): Wrong argument count for function call:
                          1 arguments given but expected 2.
error Bad(mapping(uint256 => uint256) m);
                          Error (3448): Type containing a (nested) mapping is not allowed
                          as error parameter type.
```

| 同じ名前が二つ | 結果 |
|---|---|
| エラー`Short(uint256)`、エラー`Short(uint256, uint256)` | Error (2333): Identifier already declared. |
| イベント`Short(…)`、エラー`Short(…)` | Error (2333) |
| イベント`Set(uint256)`、イベント`Set(address)` | ビルドは通る |
| ファイルレベルの`Short(uint256)`、コントラクトの中の`Short(uint256, uint256)` | ビルドは通る、Warning (2519): This declaration shadows an existing declaration. |

組み込みの名前を定義し直すと`Error (1855): The built-in errors "Error" and "Panic" cannot be re-defined.`、`abi.encodeError`を使うと0.8.30ではError (9582)である。

`Vault`の`take(5)`のリバートデータは、セレクタ4バイト、have 32バイト、want 32バイトで68バイトである。関数のcalldataと同じ形で、イベントのシグネチャのハッシュの先頭4バイトと同じである（`cast sig`、`cast calldata`、`cast sig-event`）。

```
$ cast call $V "take(uint256)" 5 --rpc-url $R
Error: execution reverted: Short(3, 5)
... data: "0x994fecf5
       0000000000000000000000000000000000000000000000000000000000000003
       0000000000000000000000000000000000000000000000000000000000000005"
$ cast sig "Short(uint256,uint256)"
0x994fecf5
$ cast calldata "take(uint256)" 5
0x4fd9efc40000000000000000000000000000000000000000000000000000000000000005
$ cast sig-event "Short(uint256,uint256)"
0x994fecf5c8a55c47a0cb50d0d1b2173afb961e1ac46a7ecee84fde8d91e2aa7e
```

`takeReq(5)`（`require(条件, Short(…))`）も同じデータである。`shortSel()`は`0x994fecf5`、`shortEnc()`（`abi.encodeWithSelector(Short.selector, have, 5)`）は`take(5)`のリバートデータと同じバイトである。

| エラー | リバートデータ | 長さ |
|---|---|---|
| `Closed()`（閉じたあとの`take(1)`） | `0x1cdde67b` | 4バイト |
| `Unauthorized(アカウント1番)`（`onlyOwner()`） | `0x8e4a23d6` + 左を0で埋めたアドレスの欄 | 36バイト |
| `LibFail(7)`（`lib(7)`） | `0xf51f4d73` + 7 | 36バイト |
| `Short(3, 5)`（`take(5)`） | `0x994fecf5` + 3 + 5 | 68バイト |
| `Why("closed today")`（`why()`） | `0x16cac8c7` + オフセット + 長さ + 文字 | 100バイト |

```
$ cast call $V "why()" --rpc-url $R
Error: execution reverted: Why("closed today")
... data: "0x16cac8c7
       0000000000000000000000000000000000000000000000000000000000000020
       000000000000000000000000000000000000000000000000000000000000000c
       636c6f73656420746f6461790000000000000000000000000000000000000000"
```

`catch Short(uint256 h, uint256 w)`のように名前を書いたcatchはビルドできない。

```
Error (3542): Invalid catch clause name. Expected either `catch (...)`, `catch Error(...)`, or `catch Panic(...)`.
```

`Taker`が`catch (bytes memory)`で受け取ったもの（`cast send`、`cast call`）。Vaultを閉じたあとの`tryTake($V, 1)`はlastが`0x1cdde67b`（Closed）で、shortCountは1のままである。`tryTakeArgs($V, 5)`のあとはlastHave 3、lastWant 5である。

```
$ cast call $T "last()(bytes)" --rpc-url $R
0x994fecf500000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000005
$ cast call $T "lastSel()(bytes4)" --rpc-url $R
0x994fecf5
$ cast call $T "shortCount()(uint256)" --rpc-url $R
1
```

プロジェクトの外のフォルダから`cast rpc eth_call`で同じ`take(5)`を送ると、ノードは名前なしでセレクタとデータだけを返す。シグネチャを手で与えれば解ける（`cast decode-error --sig`）。

```
$ cast rpc eth_call "{\"to\":\"$V\",\"data\":\"$D\"}" latest --rpc-url $R
Error: server returned an error response: error code 3: execution reverted: custom error 0x994fecf5: ,
data: "0x994fecf500000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000005"
$ cast decode-error --sig "Short(uint256,uint256)" 0x994fecf5…0005
3
5
```

ABIのエラーの欄（`forge inspect … errors`、罫線の行は省略）。Vaultには使っていない`Unused`とライブラリの`LibFail`まで六つがあり、Shortをそのまま上へ送るTakerには一つもない。

```
$ forge inspect --offline src/Err.sol:Vault errors
| Closed()               | 1cdde67b |
| LibFail(uint8)         | f51f4d73 |
| Short(uint256,uint256) | 994fecf5 |
| Unauthorized(address)  | 8e4a23d6 |
| Unused(uint256)        | 1c005222 |
| Why(string)            | 16cac8c7 |
$ forge inspect --offline src/Err.sol:Taker errors
| Error | Selector |
```

第108講のバージョンのMarketを通って上がってきたトークンの二つのエラー。アカウント0番のトークンの残高（900）より多く預け入れるとMockTokenの引き算のPanic 0x11が、トークンを止めるとMockTokenの文字列がそのまま来る。

```
$ cast call $M "deposit(address,uint256)" $TK 1000 --from $A0 --rpc-url $R
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
... data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000011"

$ cast send $TK "setBroken(bool)" true --rpc-url $R --unlocked --from $A0
$ cast call $M "deposit(address,uint256)" $TK 1 --from $A0 --rpc-url $R
Error: execution reverted: token paused
... data: "0x08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000c746f6b656e207061757365640000000000000000000000000000000000000000"
```

enumとユーザー定義型は、シグネチャでは`uint8`である（`forge inspect … errors`、十二行のうち二行）。

```
$ forge inspect --offline src/Market.sol:Market errors
| NotActive(Market.MarketStatus)       | 1d61e8ee |
| RatioAboveCap(Ratio,Ratio)           | 56c44ccc |
$ cast sig "NotActive(uint8)"
0x1d61e8ee
$ cast sig "RatioAboveCap(uint8,uint8)"
0x56c44ccc
```

Marketのエラーの一覧。

| エラー | シグネチャ | セレクタ | かける場所 | 引数 | 第107講のバージョンの理由 |
|---|---|---|---|---|---|
| InsufficientDeposit | `(uint256,uint256)` | 0x25c3f46e | `_debit`（withdraw、withdrawAll） | 預け入れの額、要求額 | 第90講からエラー |
| ZeroAdmin | `()` | 0x7289db0e | コンストラクタ | なし | admin is zero |
| NotAdmin | `(address)` | 0x17a84242 | `_checkAdmin`（setStatus、addAsset） | 呼んだアカウント | not admin |
| MarketFrozen | `()` | 0xb2ce2a93 | `_checkNotFrozen`（addAsset、withdraw、withdrawAll） | なし | frozen |
| NotActive | `(uint8)` | 0x1d61e8ee | whenActive（deposit） | 今の状態 | not active |
| ZeroAsset | `()` | 0x7cde9b72 | addAsset | なし | zero asset |
| AlreadyListed | `(address)` | 0x19cd4595 | addAsset | 資産のアドレス | already listed |
| RatioAboveCap | `(uint8,uint8)` | 0x56c44ccc | addAsset | 入れた比率、上限 | ratio above cap |
| NotListed | `(address)` | 0x5d35c429 | deposit | 資産のアドレス | not listed |
| ZeroAmount | `()` | 0x1f2a2005 | deposit、withdraw | なし | zero amount |
| TransferFromFailed | `(address)` | 0x6e1c8d15 | deposit | 資産のアドレス | transferFrom failed |
| TransferFailed | `(address)` | 0x39f1c8d9 | withdraw | 資産のアドレス | transfer failed |

Marketのソースには理由の文字列が残らない。トークンが出したリバートは、この一覧になくそのまま上がってくる。

```
$ forge build --offline
Compiler run successful!
$ forge test --offline
Ran 10 test suites: 29 tests passed, 0 failed, 0 skipped (29 total tests)
```

### 試すときの注意

- エラーは`revert`のあとか、`require`の二つ目の欄にだけ来る。値として返したり`emit`したりはできない。
- イベントは名前が同じで引数の型が違うものを二つ置けるが、エラーは一つの名前に宣言一つである。
- memoryの`bytes`は`data[4:]`で切れない。受け取ったデータから引数を解くには、`this.shortArgs(data)`のようにexternal関数に渡してcalldataで切る。
- プロジェクトの外で打った`cast call`でも、castのローカルのシグネチャのキャッシュで名前がつくことがある。ノードが渡したそのままを見るには`cast rpc eth_call`を使う。
- `--sig`なしで`cast decode-error`を呼ぶと、ローカルのキャッシュか外部のシグネチャの一覧サービスに問い合わせる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3、anvilは既定の設定（ハードフォークは既定値） | 2026-10-19 |
| カスタムエラーの導入バージョン | 0.8.4（2021-04-21） | 2026-10-19 |
| `require(条件, カスタムエラー)` | 0.8.26はvia-IR、0.8.27から既定（レガシー）のパイプライン。0.8.30の既定の設定でビルド・動作 | 2026-10-19 |
| `abi.encodeError` | 0.8.30にはない：Error (9582) `Member "encodeError" not found or not visible after argument-dependent lookup in abi.` | 2026-10-19 |
| `cast decode-error`の既定の照会先 | `--sig`がなければローカルのキャッシュか https://api.openchain.xyz | 2026-10-19 |
| Marketのサイズ（runtime / creation） | 第107講のバージョン8,173 / 8,869、第108講のバージョン7,197 / 7,771 | 2026-10-19 |
| デモのgasUsed | Taker tryTake(5) 164,957、tryTakeArgs(5) 77,507、Vault close() 26,318、閉じたあとのtryTake(1) 45,178 | 2026-10-19 |
| テストのgas | ErrorData：test_catchBytesCompare 34,553、test_insufficientDepositBytes 39,805、test_tokenRevertBubbles 155,173 / Selectors test_errorSelectorsMatch 1,334 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 文字列の理由とカスタムエラーのサイズ・ガスの比較、`require`の二つ目の引数の計算のタイミング | [第109講](../../part6/lecture109/) |
| 継承とエラー、インターフェースを継承したコントラクトのエラー | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| アセンブリでのリバートデータの書き込み・投げ直し | [第122講](../../part7/lecture122/)、[第123講](../../part7/lecture123/) |
| 動的な引数のエンコードの規則の全体、セレクタの衝突 | [第141講](../../part8/lecture141/) |
| エラーのドキュメントコメント（NatSpecの`@param`） | [第146講](../../part9/lecture146/) |
| 受け取ったデータで次の処理を決める設計 | [第170講](../../part11/lecture170/) |
| 標準が決めたエラーの名前 | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| 受け取ったデータをどこまで信じるか、わからないエラーの扱い | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
