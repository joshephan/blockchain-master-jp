# 第83講 外部関数の呼び出しと呼び出しオプション

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第82講](../../part5/lecture82/) | [第5部 目次](../) | [第84講 →](../../part5/lecture84/)

## この講義の問い

ほかのコントラクトを呼ぶ1行で、何が新しく開き、何が誰に渡るのか。

## 実習資料

### 準備

空のFoundryプロジェクト二つから始める。`demo`はビルドが通るバージョン、`errors`はビルドエラーを見るバージョンである。どちらもfoundry.tomlで`solc = "0.8.30"`に固定し、forge-stdを`lib/forge-std`に置く。ほとんどの結果は`forge test --offline -vvvv`のトレースで見る。Marketのトークンの呼び出しは、ローカルのanvilに既定のアカウント0番（デプロイ・管理者）でデプロイし、既定のアカウント1番（アリス）でapprove・depositを送る（どちらもanvilの公開されたテスト用の鍵）。ブロックに載る前と後を比べるときは、ブロックを自動で作らない`anvil --no-mining`を別に立ち上げる。`errors`のファイルは一つずつ`forge build --offline --force src/<ファイル>`でビルドする（`Market.sol`、`Options.sol`はimport用のコピー）。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket。depositに`transferFrom`の呼び出しとboolの確認、withdrawに`transfer`の呼び出しとboolの確認、IERC20に`transfer`の宣言を足したバージョン。状態の欄はそのまま（スロット0〜6） |
| [code/demo/src/Tokens.sol](code/demo/src/Tokens.sol) | 受け取ったcalldata・msg.sender・tx.originを記録しておくテスト用のMockToken、失敗するとfalseを返すFalseToken |
| [code/demo/src/Caller.sol](code/demo/src/Caller.sol) | 同じtransferFromを型つきの呼び出し（`typed`）と低水準のcall（`low`）で呼ぶCaller、リバートするRevertToken |
| [code/demo/src/Options.sol](code/demo/src/Options.sol) | 呼び出しオプション`{value: }`・`{gas: }`と名前つき引数を使うOpt、受け取る側のTarget |
| [code/demo/src/Vault.sol](code/demo/src/Vault.sol) | イーサを先に送るバージョンと欄を先に書き換えるバージョンの二つの引き出しを置いたVault、イーサを受け取った瞬間に金庫を読むだけのPeeker |
| [code/demo/src/Self.sol](code/demo/src/Self.sol) | 第80講の`who()`と`this.who()`の比較コントラクト |
| [code/demo/test/Calls.t.sol](code/demo/test/Calls.t.sol) | リバートするトークン、falseのトークン、コードのないアドレスを二つの系統で呼ぶテスト六つ |
| [code/demo/test/Options.t.sol](code/demo/test/Options.t.sol) | 呼び出しオプションのテスト七つ（受け取ったcalldataの確認を含む） |
| [code/demo/test/Vault.t.sol](code/demo/test/Vault.t.sol) | 二つの引き出しの順番で、受け取る側が見た値 |
| [code/demo/test/Market.t.sol](code/demo/test/Market.t.sol) | deposit、withdraw、falseのトークンのdeposit、IERC20のinterfaceId |
| [code/demo/test/Types.t.sol](code/demo/test/Types.t.sol) | interfaceIdとMarketのコードの長さ |
| [code/demo/test/Self.t.sol](code/demo/test/Self.t.sol) | 第80講のSelfのトレース |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/PayToken.sol](code/errors/src/PayToken.sol) | payableでないtransferFromに`{value: 1}`、Error 7006 |
| [code/errors/src/OldSyntax.sol](code/errors/src/OldSyntax.sol) | 古い文法`.value(7)`、Error 1621 |

`Vault.withdrawSendFirst`は、受け取る側が読む値を見せるためのデモ用の順番である。デプロイ用のコードではない。

### 実行結果

アリスの`deposit(トークン, 500)`を`cast run`で見たトレース。`_credit`には行がなく、トークンの呼び出しが一段字下げした行として出る（`0x5FbD...0aa3`はMarket、`0xe7f1...0512`はテスト用のトークン、`0x7099...79C8`はアリス）。

```
Traces:
  [263971] 0x5FbDB2315678afecb367f032d93F642f64180aa3::deposit(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, 500)
    ├─ [190276] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::transferFrom(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 0x5FbDB2315678afecb367f032d93F642f64180aa3, 500)
    │   └─ ← [Return] true
    └─ ← [Stop]
```

トークンの中で記録しておいた値。msg.senderはMarket、tx.originはアリスで、受け取ったバイトは`cast calldata`で作ったものと同じである。

```
$ cast call $TK "lastSender()(address)"
0x5FbDB2315678afecb367f032d93F642f64180aa3
$ cast call $TK "lastOrigin()(address)"
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast call $TK "lastData()(bytes)"
0x23b872dd00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c80000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa300000000000000000000000000000000000000000000000000000000000001f4
$ cast calldata "transferFrom(address,address,uint256)" $ALICE $M 500
0x23b872dd00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c80000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa300000000000000000000000000000000000000000000000000000000000001f4
```

そのあと、トークンの`balanceOf(Market)`、`positions`の最初の欄、`totalDeposits`はすべて500である。

リバートするトークンを二つの系統で呼んだトレース（setUp、Tracesの最初の行は省略）。低水準のcallは`(false, リバートデータ)`を受け取って先に進み、型つきの呼び出しは一緒にリバートする。`test_typedRevert`は、リバートを見せるためにわざと失敗させたテストである。

```
[PASS] test_lowRevert() (gas: 45619)
    ├─ [27896] Caller::low(RevertToken: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0x00000000000000000000000000000000000A11cE, 500)
    │   ├─ [1093] RevertToken::transferFrom(0x00000000000000000000000000000000000A11cE, Caller: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 500)
    │   │   └─ ← [Revert] no allowance
    │   └─ ← [Return] false, 0x08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000c6e6f20616c6c6f77616e63650000000000000000000000000000000000000000

[FAIL: no allowance] test_typedRevert() (gas: 36734)
    ├─ [26817] Caller::typed(RevertToken: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0x00000000000000000000000000000000000A11cE, 500)
    │   ├─ [1093] RevertToken::transferFrom(0x00000000000000000000000000000000000A11cE, Caller: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 500)
    │   │   └─ ← [Revert] no allowance
    │   └─ ← [Revert] no allowance
    └─ ← [Revert] no allowance
```

falseを返すトークンは、二つの系統のどちらでもリバートしない。`low`は`true, 0x00...00`（呼び出しは成功、返ってきた32バイトがfalse）、`typed`は`false`をそのまま受け取る。Marketのdepositは、返ってきたboolを確かめる行で全体がリバートする（`test_depositFalseToken`、わざと失敗させたテスト）。

```
[FAIL: transferFrom failed] test_depositFalseToken() (gas: 109476)
    ├─ [96554] Market::deposit(FalseToken: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 500)
    │   ├─ [1009] FalseToken::transferFrom(0x00000000000000000000000000000000000A11cE, Market: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 500)
    │   │   └─ ← [Return] false
    │   └─ ← [Revert] transferFrom failed
    └─ ← [Revert] transferFrom failed
```

コードのないアドレス（`0xdEaD`）を呼ぶと、二つの系統とも呼び出し自体は成功（Stop）する。低水準のcallは`true, 0x`を受け取り、型つきの呼び出しは戻り値の32バイトを読めずにリバートする（`test_typedEmpty`、わざと失敗させたテスト）。

```
[PASS] test_lowEmpty() (gas: 44192)
    ├─ [26473] Caller::low(0x000000000000000000000000000000000000dEaD, 0x00000000000000000000000000000000000A11cE, 500)
    │   ├─ [0] 0x000000000000000000000000000000000000dEaD::transferFrom(0x00000000000000000000000000000000000A11cE, Caller: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 500)
    │   │   └─ ← [Stop]
    │   └─ ← [Return] true, 0x

[FAIL: EvmError: Revert] test_typedEmpty() (gas: 35610)
    ├─ [25617] Caller::typed(0x000000000000000000000000000000000000dEaD, 0x00000000000000000000000000000000000A11cE, 500)
    │   ├─ [0] 0x000000000000000000000000000000000000dEaD::transferFrom(0x00000000000000000000000000000000000A11cE, Caller: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 500)
    │   │   └─ ← [Stop]
    │   └─ ← [Revert] call to non-contract address 0x000000000000000000000000000000000000dEaD
    └─ ← [Revert] EvmError: Revert
```

`forge test --offline --match-contract OptionsTest -vvvv`のhitのトレース。返ってきた値は、x、msg.value、gasleft()の順である。

```
    ├─ [28212] Opt::plain()
    │   ├─ [813] Target::hit(3)
    │   │   └─ ← [Return] 3, 0, 1040418622 [1.04e9]

    ├─ [34883] Opt::withOptions()
    │   ├─ [813] Target::hit{value: 7}(3)
    │   │   └─ ← [Return] 3, 7, 51899 [5.189e4]

    ├─ [34896] Opt::named()
    │   ├─ [813] Target::hit{value: 7}(3)
    │   │   └─ ← [Return] 3, 7, 1040412144 [1.04e9]
```

hitの中のgasleft()は、オプションなしで1,040,418,622、`{gas: 50000}`で49,599、`{value: 7, gas: 50000}`で51,899である（イーサを載せた呼び出しに機械が2300を上乗せする）。`test_optionsCalldata`は`vm.expectCall(address(t), 7, ...)`で、hitが受け取ったcalldataが`cast calldata "hit(uint256)" 3`の`0xebf6e91d...03`だけであることを確かめる。7と50000はcalldataにない。

`{gas: 5000}`で呼んだbumpはストレージへの書き込みに足りずOutOfGasになり、オプションなしで呼んだbumpは22453を使って終わる。

```
    ├─ [31221] Opt::bumpLimited()
    │   ├─ [5000] Target::bump()
    │   │   └─ ← [OutOfGas] EvmError: OutOfGas
    │   └─ ← [Revert] EvmError: Revert

    ├─ [48631] Opt::bumpFull()
    │   ├─ [22453] Target::bump()
    │   │   └─ ← [Stop]
```

呼び出しオプションのビルドエラー。

```
Error (7006): Cannot set option "value" on a non-payable function type.
 --> src/PayToken.sol:8:9:
  |
8 |         token.transferFrom{value: 1}(msg.sender, address(this), amount);
  |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (1621): Using ".value(...)" is deprecated. Use "{value: ...}" instead.
 --> src/OldSyntax.sol:8:9:
  |
8 |         t.hit.value(7)(3);
  |         ^^^^^^^^^^^
```

`forge test --offline --match-contract VaultTest -vvvv`。イーサを先に送るバージョンでは、受け取る側がまだ書き換えられていない欄（1イーサ）を読む（トレースの前後の行は省略）。

```
[PASS] test_sendFirst() (gas: 96573)
Logs:
  seenEntry    1000000000000000000
  seenVaultEth 0
  entry after  0
    ├─ [38669] Vault::withdrawSendFirst()
    │   ├─ [26248] Peeker::receive{value: 1000000000000000000}()
    │   │   ├─ [801] Vault::balances(Peeker: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]) [staticcall]
    │   │   │   └─ ← [Return] 1000000000000000000 [1e18]

[PASS] test_stateFirst() (gas: 76738)
Logs:
  seenEntry    0
  seenVaultEth 0
  entry after  0
    ├─ [18813] Vault::withdrawStateFirst()
    │   ├─ [6348] Peeker::receive{value: 1000000000000000000}()
    │   │   ├─ [801] Vault::balances(Peeker: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]) [staticcall]
    │   │   │   └─ ← [Return] 0
```

`--no-mining`のanvilでのVaultのdeposit。`cast call`はノードが一人で実行してみた結果なので欄は変わらず、`cast send --async`はハッシュだけを返す。`cast rpc evm_mine`でブロックを作ってはじめてレシートができ、欄が変わる。

```
$ cast call $V "deposit()(uint256)" --value 1ether --from $A0
1000000000000000000 [1e18]
$ cast call $V "balances(address)(uint256)" $A0
0
$ cast send $V "deposit()" --value 1ether --private-key $PK0 --async
0xcdaed99216f5e8e5cb1a9491e3b0bbda78a1ff337392c3866430c5453565c3c7
$ cast receipt 0xcdaed99216f5e8e5cb1a9491e3b0bbda78a1ff337392c3866430c5453565c3c7 --async
Error: tx not found: 0xcdaed99216f5e8e5cb1a9491e3b0bbda78a1ff337392c3866430c5453565c3c7
$ cast rpc evm_mine
"0x0"
$ cast receipt 0xcdaed99216f5e8e5cb1a9491e3b0bbda78a1ff337392c3866430c5453565c3c7
blockNumber          2
gasUsed              43998
status               1 (success)
$ cast call $V "balances(address)(uint256)" $A0
1000000000000000000 [1e18]
```

Marketのwithdrawのトレースと、IERC20のinterfaceId。`transfer`を足したので、interfaceIdが`0x5318f0ec`（関数二つ）から`0xfa1d6c57`に変わった（`0x5318f0ec` XOR `0xa9059cbb`）。

```
    ├─ [50176] Market::withdraw(MockToken: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 200)
    │   ├─ [11456] MockToken::transfer(0x00000000000000000000000000000000000A11cE, 200)
    │   │   └─ ← [Return] true
    │   └─ ← [Stop]
$ forge test --offline --match-test test_interfaceId -vv
Logs:
  0xfa1d6c57
$ cast sig "transfer(address,uint256)"
0xa9059cbb
```

### 試すときの注意

- デモ用のMockTokenはcalldataをストレージに書き込むので、transferFromのガスが大きい（190,276）。
- 三つのテスト（`test_typedRevert`、`test_typedEmpty`、`test_depositFalseToken`）は、リバートを見せるためにわざと失敗させてある。`forge test`が失敗を三つ報告するのが正常である。
- 戻り値を受け取る外部呼び出しは、呼び出し前のコードの存在確認をせず、戻り値をほどけずにリバートする。戻り値のない呼び出しは、呼び出し前に確認する（solc 0.8.10から）。
- forgeのテストの既定のガスリミットは1,073,741,824なので、オプションなしの呼び出しのgasleft()は10億台で出る。
- `--no-mining`のanvilでは、Vaultをデプロイするときだけ`cast rpc evm_setAutomine true`で自動のブロック生成をオンにし、デプロイ後に`false`でオフにする。
- Marketでは、トークンの呼び出しの間、そのトークンのコードが動く。そのときpositionsと合計の欄は、呼び出しの行より上で変えた分だけが変わっている。返ってきたboolは`require`で確かめる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| コードの存在確認の規則 | solc 0.8.10から、戻りデータを受け取る外部呼び出しは呼び出し前のコードの存在確認（extcodesize）を省き、戻り値のデコードの失敗でリバートする。戻り値のない呼び出しは従来どおり呼び出し前に確認する | 2026-10-19 |
| 呼び出しオプションの文法 | `{value: ..., gas: ...}`はsolc 0.6.2から、`.value(...)`・`.gas(...)`は0.7.0で削除（0.8.30ではError 1621） | 2026-10-19 |
| イーサを載せた呼び出しのガス2300 | 値が0でないCALLに機械が上乗せするガス。gas 50000のバージョンの49,599と、value 7のバージョンの51,899の差が2,300 | 2026-10-19 |
| forgeのテストの既定のガスリミット | 1,073,741,824 | 2026-10-19 |
| MarketのinterfaceId | `type(IERC20).interfaceId` = `0xfa1d6c57`（balanceOf・transferFrom・transferの三つ）。第80講の値`0x5318f0ec`から変わった | 2026-10-19 |
| Marketのバイト長 | creationCode 6,113バイト、runtimeCode 6,021バイト | 2026-10-19 |
| トレースのガス | deposit 263,971（内側のtransferFrom 190,276、テスト用のトークンがcalldataをストレージに書くので大きい）、gasUsed 280,755 / hit 813 / bump 22,453 / receive 26,248・6,348 / 金庫のdepositのgasUsed 43,998 | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `new`でコントラクトを作るときの呼び出しオプション（`{value: }`、`{salt: }`） | [第84講](../../part5/lecture84/) |
| リバートの文法と理由、Panicのコード | [第90講](../../part5/lecture90/) |
| `try`/`catch`で外部呼び出しの失敗を受け取る、リバートデータをほどく | [第91講](../../part5/lecture91/) |
| 可視性の4段階と、`external`・`public`関数の呼び出しの形 | [第95講](../../part6/lecture95/) |
| 委任呼び出し（delegatecall）とライブラリ | [第117講](../../part6/lecture117/) |
| 低水準の呼び出しのパターン全般（staticcall、戻りデータの処理） | [第122講](../../part7/lecture122/) |
| 受け取る側にイーサを先に送る順番から生まれる攻撃、順番の規則の名前、もう一度呼んで抜き取るデモ | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/) |
| 外部呼び出しの結果を扱う実務の基準、送らずに取りに来させる方式 | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |
| 標準を守らないトークン（boolを返さないトークンなど）と組み合わせの危険 | [第171講](../../part11/lecture171/) |
| ERC-165とインターフェースの確認 | [第159講](../../part10/lecture159/) |
| 害を与えるために書かれた相手のコードについて何を確かめるべきか | [第167講](../../part11/lecture167/) |
| メンプールで順番を選んで得をすること | [第172講](../../part11/lecture172/) |
| プロキシが渡す制御権と、初期化されていないプロキシ | [第177講](../../part11/lecture177/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
