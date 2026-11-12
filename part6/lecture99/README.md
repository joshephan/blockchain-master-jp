# 第99講 receiveとfallback

第6部 言語の詳細 ③ コントラクト・第21章 関数の掘り下げ

[← 第98講](../../part6/lecture98/) | [第6部 目次](../) | [第100講 →](../../part6/lecture100/)

## この講義の問い

合う関数の名前なしで入ってきた呼び出しとイーサは、コントラクトのどこへ行き、受け取る場所がなければ何が起きるのか。

## 実習資料

### 準備

通しプロジェクトのMarketはコードを変えない。receive・fallbackを置かないことに決め、それを確かめるテストファイル`test/Receive.t.sol`だけを加える（`market`）。`demo`は`forge init`で作った空のプロジェクトからCounterの例・test・scriptを消して始め、anvilでのデプロイのときは`market`のMarketとMockTokenを一緒に入れて使った。`bad`はエラーのソースを一つずつビルドしたプロジェクトである。どれもforge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した。デモはローカルのanvilで、既定のアカウント0番（デプロイ）・1番（呼び出し、Marketの管理者）を公開されたテスト用の鍵で`--unlocked --from`で使って動かした。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30に固定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | この講義の終わりのバージョンのMarket（変えたコードなし） |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | テスト用のトークン |
| [code/market/test/Market.t.sol](code/market/test/Market.t.sol) | Marketのテスト |
| [code/market/test/Getters.t.sol](code/market/test/Getters.t.sol) | ゲッターのテスト |
| [code/market/test/Receive.t.sol](code/market/test/Receive.t.sol) | イーサを載せた呼び出しの拒否、ないセレクタの拒否、`deposit`を通らないトークンの送金は帳簿に載らない |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Recv.sol](code/demo/src/Recv.sol) | 受け取る関数が違うNone、R、F、FP、RF、呼び出しを渡すFwd、三つの方法で送るSender、何も書かないRQuiet |
| [code/demo/src/Counter.sol](code/demo/src/Counter.sol) | 第98講のCounterと同じソース（Fwdが渡す相手） |
| [code/demo/src/Push.sol](code/demo/src/Push.sol) | コンストラクタで`selfdestruct`によってイーサを渡すコントラクト |
| [code/demo/src/Born.sol](code/demo/src/Born.sol) | コンストラクタの最初の行の残高とコードの長さを記録 |
| [code/bad/foundry.toml](code/bad/foundry.toml) | solc 0.8.30に固定 |
| [code/bad/src/R1.sol](code/bad/src/R1.sol) 〜 [R8.sol](code/bad/src/R8.sol) | 誤って書いたreceive・fallbackが一行ずつ |

`bad`のファイルは一度に一つずつビルドする。

### 実行結果

Marketに1 weiを送ったり、ない関数を呼んだりすると、ガスの見積もりでリバートする。

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

`forge inspect --offline RF abi`と`Fwd abi`。receive・fallbackは名前とセレクタなしで載る。

```
| function | last() view returns (string) | 0x47799da8 |
| fallback | fallback() payable           |            |
| receive  | receive() payable            |            |
```

```
| function    | target() view returns (address) | 0xd4b83992 |
| constructor | constructor(address) nonpayable |            |
| fallback    | fallback() nonpayable           |            |
```

`bad`のR1〜R8のビルド結果（順番どおり）。

```
Error (7793): Receive ether function must be payable, but is "nonpayable".
Error (6857): Receive ether function cannot take parameters.
Error (6899): Receive ether function cannot return values.
Error (4095): Receive ether function must be defined as "external".
Warning (3445): This function is named "receive" but is not the receive function of the contract. If you intend this to be a receive function, use "receive(...) { ... }" without the "function" keyword to define it.
Error (5570): Fallback function either has to have the signature "fallback()" or "fallback(bytes calldata) returns (bytes memory)".
Error (5570): Fallback function either has to have the signature "fallback()" or "fallback(bytes calldata) returns (bytes memory)".
Error (4575): Fallback function must be payable or non-payable, but is "view".
```

五つのコントラクトに四種類の呼び出しを`cast send --gas-limit 100000 --json`で送ったレシートのstatus（成功1、リバート0）。`0xdeadbeef`はどのセレクタとも合わない4バイトである。

| コントラクト | 空のデータ + 1 wei | 空のデータ | `0xdeadbeef` | `0xdeadbeef` + 1 wei |
|---|---|---|---|---|
| None | リバート | リバート | リバート | リバート |
| R | 成功 | 成功 | リバート | リバート |
| F | リバート | 成功 | 成功 | リバート |
| FP | 成功 | 成功 | 成功 | 成功 |
| RF | 成功 | 成功 | 成功 | 成功 |

終わったあとの`hits()`はR 2、F 2、FP 4、残高はR 1、FP 2、RF 2、None・F 0 weiである。RFに送るたびに`last()`を読むと、空のデータは"receive"、`0xdeadbeef`と1バイトの`0x01`は"fallback"である。

FPをビルドするときに出る警告。

```
Warning (3628): This contract has a payable fallback function, but no receive ether function. Consider adding a receive ether function.
```

Senderの`viaTransfer`でRに1 weiを送って失敗したトランザクションの`cast run`。receiveには2300ガスだけが渡り、`hits`を書いている途中でガスが尽きる。

```
Traces:
  [12151] 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6::viaTransfer(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9)
    ├─ [2300] 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9::receive{value: 1}()
    │   └─ ← [OutOfGas] EvmError: OutOfGas
    └─ ← [Revert] EvmError: Revert
```

Bornを1 etherと一緒にデプロイすると、コンストラクタの最初の行で残高はすでに1 etherで、コードの長さは0である（デプロイ後の`cast codesize`は214）。

```
balanceAtStart 1000000000000000000 [1e18]
codeLenAtStart 0
```

受け取る関数のないMarketにも、`selfdestruct`でならイーサが入る。Pushを1 weiと一緒にデプロイしたあと、Marketの残高は1になり、コードはそのままで、直接送るイーサは相変わらずリバートする。

```
0
Deployed to: 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0
1
6907
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

コードのないアドレス`0x…bEEF`に`viaTransfer`で送ると成功し（gasUsed 56,068）、残高は1になる。そのアドレスで関数を呼んでも空の値が返ってくる。

```
Warning: Contract code is empty
0x
```

Fwdのfallbackを通してCounterの`bump()`を呼ぶと、Counterの`n`が1から2に上がり（gasUsed 32,034）、Fwdで呼んだ`get()`も2を返す。

`market`で`forge test --offline --mc ReceiveTest`。

```
[PASS] test_directTransferNotCounted() (gas: 74690)
[PASS] test_rejectsEther() (gas: 33300)
[PASS] test_rejectsUnknownSelector() (gas: 30586)
```

### 試すときの注意

- calldataが空でreceiveがあれば、receiveへ行く。それ以外で合う関数がなければfallbackへ、fallbackもなければリバートする。どこへ行ったとしても、イーサが載っていてその関数がpayableでなければリバートする。
- リバートする呼び出しは、`--gas-limit`なしで送るとガスの見積もりで止まり、トランザクションが出ていかない。レシートのstatusを見るには、ガスリミットを与える。
- `forge create`では`--value`を`--constructor-args`の前に置く。後ろに置くとコンストラクタの引数として読まれ、`Constructor argument count mismatch`が出る。
- `transfer`・`send`は、受け取る側に2300ガスだけを渡す。ストレージに書くreceiveは、その中では終わらない。
- 受け取る関数を通らずに入ってくるイーサ（selfdestructの受け取りアドレス、ブロック報酬、バリデーターの引き出し）があるので、`address(this).balance`は自分で数えた合計より大きいことがある。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやハードフォークが変わると、ガスと動作が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Contractsの節のReceive Ether Function、Fallback Function | 2026-10-19 |
| ドキュメントの2300の文 | 最悪の場合、receiveが使えるガスは2300だけ。ストレージへの書き込み・コントラクトの作成・ガスを多く使う外部呼び出し・イーサの送金はその中ではできない。payableのfallbackがreceiveの代わりに使われるときも同じ | 2026-10-19 |
| 受け取る関数なしでイーサを受け取る場合（ドキュメント） | コインベーストランザクション（ブロック報酬）の受け取りアドレス、selfdestructの受け取りアドレス。コントラクトはこのイーサに反応することも拒むこともできない、`address(this).balance`が自分で数えた合計より大きいことがある | 2026-10-19 |
| バリデーターの引き出し | EIP-4895、受け取りアドレスの残高を無条件に増やす別の操作（EVMの実行なし）、有効化のタイムスタンプ1681338455（2023-04-12） | 2026-10-19 |
| 2300 | イーサを載せた呼び出しに機械が上乗せする基本の支給分、transfer・sendが渡すガス | 2026-10-19 |
| 2300で壊れた事例 | 2019年12月のイスタンブールのアップグレードのEIP-1884：SLOAD 200 → 800、BALANCE・EXTCODEHASH 400 → 700。EIPの文書の後方互換性の節が、ストレージを読む既定の関数（受け取る関数）が2300を超えうると書いている | 2026-10-19 |
| selfdestructの動作 | EIP-6780、Cancunハードフォーク（イーサリアムのメインネット 2024年3月）。作ったトランザクションの外ではイーサだけを送り、コード・ストレージを消さない。Pushは作ったトランザクションの中で消えるので`cast code` 0x | 2026-10-19 |
| receive・fallbackの分離 | Solidity 0.6.0で、名前のない関数をfallbackとreceiveに分けた | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| ガス（参考） | 空のデータ1 wei：None 21,043（リバート）、R 43,363 / 空のデータ：None 21,068、R 26,263 / Rへのtransferの失敗33,583 / bEEFへのtransfer 56,068 / Fwdを通したbump 32,034 / Receiveのテスト74,690・33,300・30,586 | 2026-10-19 |
| バイトの長さ | Marketのruntime 6,907（第98講のバージョンと同じ）、Born 214 | 2026-10-19 |
| ローカルのanvilのアドレス | MockToken `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Market `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、None `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、R `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、F `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、FP `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707`、RF `0x0165878A594ca255338adfa4d48449f69242Eb8F`、RQuiet `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853`、Sender `0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6`、Counter `0x8A791620dd6260079BF849Dc5567aDC3F2FdC318`、Fwd `0x610178dA211FEF7D417bC0e6FeD39F05609AD788`、Born `0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e`、Push `0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 関数セレクタの計算と関数を選ぶディスパッチャ | [第101講](../../part6/lecture101/) |
| fallbackで呼び出しを渡す構造、委任呼び出し | [第117講](../../part6/lecture117/)、[第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| ライブラリとイーサ・名前のない呼び出し | [第116講](../../part6/lecture116/) |
| どの送金方法を使うか、受け取る側にお金を取りに来させる設計 | [第150講](../../part9/lecture150/)、[第170講](../../part11/lecture170/) |
| 受け取る関数の中でしてよいこととしてはいけないこと | [第168講](../../part11/lecture168/)、[第170講](../../part11/lecture170/) |
| 帳簿と実際の残高が食い違うときの会計の設計、標準を守らないトークン | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| receive・fallbackが分かれたバージョンの変更 | [第185講](../../part11/lecture185/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
