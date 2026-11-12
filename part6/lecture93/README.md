# 第93講 デプロイのコードとランタイムコード

第6部 言語の詳細 ③ コントラクト・第19章 コントラクトの作成

[← 第92講](../../part6/lecture92/) | [第6部 目次](../) | [第94講 →](../../part6/lecture94/)

## この講義の問い

デプロイのときに送ったバイトと、そのアドレスに残ったバイトはなぜ違い、コンストラクタはどこへ行ったのか。

## 実習資料

### 準備

`forge init`で作った空のプロジェクトからCounterの例を消して始める。forge-std（v1.17.0）が必要で、foundry.tomlでsolc 0.8.30に固定した（optimizerは切る）。Marketは第92講の終わりのバージョンのままで、この講義ではコードを変えない。デプロイのデモはローカルのanvilで、既定のアカウント0番・1番（公開されたテスト用の鍵）を`--unlocked --from`で使って動かした。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Empty.sol](code/src/Empty.sol) | `contract Empty {}` |
| [code/src/Vault.sol](code/src/Vault.sol) | 第92講のVault。コンストラクタの中の残高・`msg.value`・コードの長さを記録 |
| [code/src/SelfCall.sol](code/src/SelfCall.sol) | コンストラクタで`this.f()`を呼ぶコントラクト（デプロイは失敗） |
| [code/src/SelfPing.sol](code/src/SelfPing.sol) | コンストラクタで戻り値のない`this.ping()`を呼ぶバージョン |
| [code/src/Gate.sol](code/src/Gate.sol) | 呼び出し元のコードの長さで人のアカウントを見分けるGateと、コンストラクタの中からGateを呼ぶVisitor |
| [code/src/Imm.sol](code/src/Imm.sol) | `uint256 public immutable k`が一つだけ |
| [code/src/Child.sol](code/src/Child.sol) | 第84講のChild、PayChild、Factory |
| [code/src/Market.sol](code/src/Market.sol) | 第92講の終わりのバージョンのMarket |
| [code/test/Ctor.t.sol](code/test/Ctor.t.sol) | `test_lengths`（creationCode・runtimeCodeの長さ）、`test_selfCall`、`test_selfPing`（リバートすることを見せるテストなのでFAILで終わる） |
| [code/test/Gate.t.sol](code/test/Gate.t.sol) | コンストラクタの中とデプロイ後の`callerHasCode()`の比較 |
| [code/bad/ImmRuntime.sol](code/bad/ImmRuntime.sol) | `type(Imm).runtimeCode`（Error 9274） |
| [code/bad/Me.sol](code/bad/Me.sol) | 自分自身の`creationCode`（Error 7813） |
| [code/bad/MeRuntime.sol](code/bad/MeRuntime.sol) | 自分自身の`runtimeCode`（Error 7813） |

`bad/`のファイルは`forge build --offline --force bad/<ファイル>`で一つずつビルドする。

### 実行結果

第92講のバージョンのMarketをデプロイしたトランザクションのinputの長さと、デプロイ後のコードの長さ（`cast tx … input`、`cast codesize`）。

```
7679
6907
```

空のコントラクトEmptyをデプロイした`cast tx`。`to`が空で、デプロイ後の`cast codesize`は62である。

```
to
input                0x6080604052348015600e575f5ffd5b50603e80601a5f395ff3fe6080...0033
```

`cast disassemble`で解いたEmptyのデプロイのコードの先頭26バイト。`CALLVALUE`でイーサが載っているかを見て、`CODECOPY`・`RETURN`で後ろの62バイトを返す。イーサを1 wei載せてEmptyをデプロイするとstatus 0である。

```
00000000: PUSH1 0x80
00000002: PUSH1 0x40
00000004: MSTORE
00000005: CALLVALUE
00000006: DUP1
00000007: ISZERO
00000008: PUSH1 0x0e
0000000a: JUMPI
0000000b: PUSH0
0000000c: PUSH0
0000000d: REVERT
0000000e: JUMPDEST
0000000f: POP
00000010: PUSH1 0x3e
00000012: DUP1
00000013: PUSH1 0x1a
00000015: PUSH0
00000016: CODECOPY
00000017: PUSH0
00000018: RETURN
00000019: INVALID
0000001a: PUSH1 0x80
```

Vaultのデプロイのコードを解いた結果の一部。コンストラクタ本体の`SSTORE`四つが終わったあとで、ようやく`CODECOPY`と`RETURN`が出てくる（0x01bb = 443、0x012c = 300）。

```
00000026: SELFBALANCE
0000002b: SSTORE
0000002d: CALLVALUE
00000032: SSTORE
00000034: ADDRESS
0000004b: EXTCODESIZE
00000050: SSTORE
0000008f: SSTORE
...
00000120: PUSH2 0x01bb
00000123: DUP1
00000124: PUSH2 0x012c
00000127: PUSH0
00000128: CODECOPY
00000129: PUSH0
0000012a: RETURN
0000012b: INVALID
```

デプロイされたVaultの`cast selectors`と`cast sig "constructor(address)"`。コンストラクタの名前で作った4バイトは一覧になく、その名前で送ったトランザクションは失敗する。

```
0x173dfd98		view
0x52174f5c		view
0xb1e4f367		view
0xf851a440		view
0xf8a6c595
gasUsed              21540
status               0 (failed)
```

コンストラクタの中の`this.f()`。ビルドの警告と、デプロイに失敗したトランザクションの`cast run`のトレース。

```
Warning (5805): "this" used in constructor. Note that external functions of a contract cannot be called while it is being constructed.
```

```
  [374] → new <unknown>@0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
    ├─ [0] 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9::f() [staticcall]
    │   └─ ← [Stop]
    └─ ← [Revert] call to non-contract address 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
```

`forge test --offline -vv --mc GateTest`。コンストラクタの中からかけた呼び出しでは、呼び出し元のコードの長さが0である。

```
  in constructor  false
  after deploy    true
```

Vaultのデプロイのinputの長さと、最後の32バイトを`cast abi-decode`で解いた結果。

```
775
0x000000000000000000000000000000000000000000000000000000000000cafe
0x000000000000000000000000000000000000cafE
```

Immをk=7、k=9で二回デプロイしたあとの`cast codesize`、`cast disassemble … | grep PUSH32`、`cast storage … 0`。長さは同じでPUSH32のあとの32バイトだけが違い、スロット0は空である。

```
203
203
00000045: PUSH32 0x0000000000000000000000000000000000000000000000000000000000000007
00000045: PUSH32 0x0000000000000000000000000000000000000000000000000000000000000009
0x0000000000000000000000000000000000000000000000000000000000000000
```

ビルド成果物のdeployedBytecodeではその位置が0で、成果物のJSONの`immutableReferences`が位置を記録している。

```
00000045: PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
"immutableReferences":{"3":[{"start":70,"length":32}
```

`bad/ImmRuntime.sol`、`bad/Me.sol`のビルドエラー。

```
Error (9274): "runtimeCode" is not available for contracts containing immutable variables.
Error (7813): Circular reference to contract bytecode either via "new" or "type(...).creationCode" / "type(...).runtimeCode".
```

Emptyをデプロイしたアドレスの`cast code`。ランタイムコードの最後にメタデータの尻尾がつく。

```
0x60806040525f5ffdfea26469706673582212209fae9d4f38d00261a74ee2cf97594e8e5c5f7abd2df727ac29c75e1ee5604b3d64736f6c634300081e0033
```

Marketの`test_lengths`の出力の一部、デプロイのinputの最後の96バイトのデコード、チェーン上のコードと成果物のdeployedBytecodeの比較。

```
  Market creationCode 7583
  Market runtimeCode  6907
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
50000000000000000 [5e16]
80
SAME
```

### 試すときの注意

- デプロイのトランザクションのinputは、デプロイのコードのあとにコンストラクタの引数をABIエンコードでつけたものである。`type(C).creationCode`には引数が入っていない。
- コンストラクタの中では、自分のアドレスのコードの長さが0である。そのため`this.f()`のような外部呼び出しはコードのないアドレスを呼ぶ形になってリバートし、呼び出し元のコードの長さで人のアカウントを見分ける検査は、コンストラクタの中からかけた呼び出しをはじけない。
- `immutable`があると、チェーン上のコードと成果物のdeployedBytecodeはその32バイトの分だけ違う。Marketのように`immutable`がなければ、二つはバイトまで同じである。
- コードサイズの上限は、anvilで実際に超えて確かめた。`0x6160005ff3`（`PUSH2 0x6000`、`PUSH0`、`RETURN`）は24,576バイトを返すデプロイのコードである。49,153バイトのデプロイのコードは、コマンドラインの長さの制限のため`cast`の代わりにJSON-RPCの`eth_sendTransaction`で送った。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやハードフォークが変わると、長さ・ガス・上限が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Solidity v0.8.36、Type Information（`type(C).creationCode`、`type(C).runtimeCode`）、Constant and Immutable State Variables、Creating Contracts | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3、anvilのハードフォーク`Bpo1`（既定値latest） | 2026-10-19 |
| `type(C).creationCode`・`runtimeCode`の導入 | solc 0.5.3 | 2026-10-19 |
| `immutable`の導入 | solc 0.6.5 | 2026-10-19 |
| コードの欄のサイズの上限 | 24,576バイト（EIP-170）。anvilで24,576バイトを返すデプロイはstatus 1（gasUsed 4,971,731）、24,577バイトはstatus 0（gasUsed 10,000,000 = ガスリミットすべて） | 2026-10-19 |
| デプロイのコードのサイズの上限 | 49,152バイト（EIP-3860）。anvilで49,152バイトのデプロイのコードはstatus 1、49,153バイトはノードが受け付けない`max initcode size exceeded` | 2026-10-19 |
| コード1バイトあたりの保存のガス | 200（24,576バイトのデプロイのgasUsedが24,576 × 200 = 4,915,200より大きい） | 2026-10-19 |
| バイトの長さ（デプロイのコード / ランタイムコード） | Empty 88 / 62、Vault 743 / 443（デプロイのinput 775）、Child 529 / 172、Immのランタイム203、SelfCall 446 / 216、第92講のバージョンのMarket 7,583 / 6,907（デプロイのinput 7,679） | 2026-10-19 |
| 前の講義の測定値 | 第21講のCounter 331 / 303、第80講の第17章のバージョンのMarket + heldBalance 4,785 / 4,693、第84講のChild 529 / 172 | 2026-10-19 |
| ローカルのanvilでのデプロイアドレス | Empty `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Vault `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、SelfCall（失敗、コードなし）`0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、Imm k=7 `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、Imm k=9 `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707`、Market `0x0165878A594ca255338adfa4d48449f69242Eb8F` | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `CREATE`と`CREATE2`のアドレスの計算式 | [第94講](../../part6/lecture94/) |
| `immutable`の文法、規則、ガス | [第102講](../../part6/lecture102/) |
| 継承が絡むときのコンストラクタの引数と初期化の順番 | [第114講](../../part6/lecture114/) |
| アセンブリの`create`と低水準の呼び出しのパターン | [第122講](../../part7/lecture122/) |
| Yulのオブジェクトの構造と、デプロイのコード・ランタイムコードを分けるコンパイラの出力 | [第124講](../../part7/lecture124/) |
| コンパイルの再現性とソースの検証の手順、コンストラクタの引数の入力 | [第130講](../../part8/lecture130/) |
| ASTとバイトコードの構造 | [第131講](../../part8/lecture131/) |
| ソースマッピング | [第132講](../../part8/lecture132/) |
| メタデータの形式とメタデータハッシュ | [第142講](../../part8/lecture142/) |
| コードの長さの検査を迂回する攻撃とアクセス制御 | [第176講](../../part11/lecture176/) |
| デプロイのコードを別に置くプロキシと初期化関数 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
