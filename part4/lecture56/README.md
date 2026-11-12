# 第56講 コントラクト型

第4部 言語の詳細 ① ファイルと型・第13章 値型

[← 第55講](../../part4/lecture55/) | [第4部 目次](../) | [第57講 →](../../part4/lecture57/)

## この講義の問い

アドレスにコントラクト型をかぶせると何が生まれ、何は相変わらず確かめられないのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトをコピーし、Counterのファイルを消してから始める。テストにはforge-stdが必要である（`lib/forge-std`）。コンパイルできない例はsrcの外の`bad/`に置き、`forge build bad/<ファイル>`で一つずつビルドする。anvilにToken、FakeToken、Prober、Pool（コンストラクターの引数はTokenのアドレス）を順にデプロイし、既定のアカウント0番（公開されたテスト用の鍵）を使う。solc 0.8.30、optimizerはオフの既定値である。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/Types.sol](code/src/Types.sol) | `IERC20`、`INotify`、本物の`Token`、常にtrueだけを返す`FakeToken`、`IERC20`型の欄を持つ`Pool`、コードのないアドレスを三つの方法で呼ぶ`Prober` |
| [code/test/Types.t.sol](code/test/Types.t.sol) | Pool.payのトレース、コードのないアドレスへの三つの呼び出し、`code.length`、FakeTokenの通過 |
| [code/bad/Typo.sol](code/bad/Typo.sol) | 関数名の打ち間違い`t.transfr(...)`（コンパイルエラー） |
| [code/bad/WrongArg.sol](code/bad/WrongArg.sol) | 金額の場所に`true`（コンパイルエラー） |
| [code/bad/WrongRet.sol](code/bad/WrongRet.sol) | boolの戻り値をuint256の変数に（コンパイルエラー） |
| [code/bad/Implicit.sol](code/bad/Implicit.sol) | addressを`IERC20`の変数に直接代入（コンパイルエラー） |

### 実行結果

Poolの欄の配置（`forge inspect Pool storageLayout`）と、デプロイしたPoolの0番の欄。コントラクト型の欄も20バイトで、欄にはTokenのアドレスだけが入っている。

```
| Name  | Type            | Slot | Offset | Bytes | Contract           |
| asset | contract IERC20 | 0    | 0      | 20    | src/Types.sol:Pool |

$ cast storage <Pool> 0
0x0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3
```

ABI（`forge inspect Pool abi --json`、一行ずつ整理、一部省略）では、assetのtypeはaddressで、internalTypeにだけコントラクト名が残る。

```
{"type": "function", "name": "asset", "inputs": [],
 "outputs": [{"name": "", "type": "address", "internalType": "contract IERC20"}], ...}
{"type": "constructor",
 "inputs": [{"name": "a", "type": "address", "internalType": "contract IERC20"}], ...}
```

コンパイラが捕まえるもの（`forge build bad/Typo.sol`、`bad/WrongArg.sol`、`bad/WrongRet.sol`、`bad/Implicit.sol`）：

```
Error (9582): Member "transfr" not found or not visible after argument-dependent lookup in contract IERC20.
 --> bad/Typo.sol:8:9:
  |
8 |         t.transfr(to, 100);
  |         ^^^^^^^^^

Error (9553): Invalid type for argument in function call. Invalid implicit conversion from bool to uint256 requested.
 --> bad/WrongArg.sol:8:24:
  |
8 |         t.transfer(to, true);
  |                        ^^^^

Error (9574): Type bool is not implicitly convertible to expected type uint256.
 --> bad/WrongRet.sol:8:9:
  |
8 |         uint256 r = t.transfer(to, 100);
  |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Error (9574): Type address is not implicitly convertible to expected type contract IERC20.
 --> bad/Implicit.sol:8:9:
  |
8 |         IERC20 t = a;
  |         ^^^^^^^^^^^^
```

`IERC20(a).transfer(...)`のように明示的にかぶせればビルドされる。

PoolにTokenを100送ったあと、`pay(0xB0b, 30)`を呼んだトランザクションの内側の呼び出し（`cast rpc debug_traceTransaction <ハッシュ> '{"tracer":"callTracer"}'`、inputは32バイト単位で改行）。0x1eは30である。

```
  "calls": [{
    "from": "0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9",
    "to": "0x5fbdb2315678afecb367f032d93f642f64180aa3",
    "input": "0xa9059cbb
              0000000000000000000000000000000000000000000000000000000000000b0b
              000000000000000000000000000000000000000000000000000000000000001e",
    "type": "CALL" }]

$ cast sig "transfer(address,uint256)"
0xa9059cbb
```

コードのないアドレス`0x000000000000000000000000000000000000dEaD`を、Proberの三つの関数で呼んだ結果：

```
$ cast code 0x000000000000000000000000000000000000dEaD
0x
$ cast call $PROBER "withReturn(address)(bool)" 0x...dEaD
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call $PROBER "noReturn(address)" 0x...dEaD
Error: server returned an error response: error code 3: execution reverted, data: "0x"
$ cast call $PROBER "lowLevel(address)(bool,bytes)" 0x...dEaD
true
0x
```

同じ三つの呼び出しのトレース（`forge test -vvvv`、アドレスは短縮、ガスの表記は一部省略）。test_WithReturnとtest_NoReturnは巻き戻しを見せるためのテストなので、FAILと表示される。

```
Prober::withReturn(0x...dEaD)
  ├─ [0] 0x...dEaD::transfer(0x...0B0b, 1)
  │   └─ ← [Stop]
  └─ ← [Revert] call to non-contract address 0x...dEaD

Prober::noReturn(0x...dEaD)
  └─ ← [Revert] call to non-contract address 0x...dEaD

Prober::lowLevel(0x...dEaD)
  ├─ [0] 0x...dEaD::transfer(0x...0B0b, 1)
  │   └─ ← [Stop]
  └─ ← [Return] true, 0x
```

| 方法 | dEaDに対する結果 | 止めたもの |
|---|---|---|
| 戻り値のある高水準の呼び出し | 巻き戻し | 戻り値の読み取り（空のデータ） |
| 戻り値のない高水準の呼び出し | 巻き戻し | 呼ぶ前のコードの確認 |
| 低水準のcall | true、0x | なし |

`codeLength`で問うたコードの長さは、Tokenが889、FakeTokenが570、dEaDのアドレスが0、anvilの1番のアカウント（EOA）が0である。

FakeTokenのアドレスで作ったPoolは、コードの長さの確認も`pay`も通過する（`forge test -vvvv --mt test_FakePasses`）。移ったトークンはない。

```
Logs:
  code length 570
  pay true

  ├─ [28465] Pool::pay(0x...0B0b, 30)
  │   ├─ [817] FakeToken::transfer(0x...0B0b, 30)
  │   │   └─ ← [Return] true
  │   └─ ← [Return] true
```

### 試すときの注意

- `IERC20(addr)`は、Javaのキャストと違って実行中に何も確かめない。コンパイラが作るのは、関数名、引数と戻り値の型、送るバイトだけである。すべて自分の側のコードである。
- コードのないアカウントへのCALLは、EVMでは成功する。高水準の呼び出しが巻き戻るのはコンパイラが付け加えた確認のためで、戻り値があれば空の戻りデータをデコーダーが、戻り値がなければ呼ぶ前のコードの確認が止める。
- 低水準の`call`にはその確認がない。存在しないアカウントを呼んでもtrueが来る。必要なら呼び出しの前に`code.length`を自分で確かめる。
- `code.length > 0`が教えてくれるのは、コードがあることだけである。FakeTokenのように形だけ合わせたコントラクトは通過する。
- トレースの`call to non-contract address`はforgeがつけた説明である。実際の巻き戻しデータは0xである。

## 時効性のあるデータ

基準日時点の値。コンパイラが付け加える確認は、バージョンによって変わってきた。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidity公式ドキュメントのバージョン | v0.8.36（Types: Contract Types、Control Structures: External Function Calls） | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 (cae51ad) | 2026-10-19 |
| 高水準の呼び出しのコード存在確認 | 0.8.10から、戻り値を受け取る高水準の外部呼び出しではextcodesizeの確認を省略し、空の戻りデータをABIデコーダーが巻き戻す。戻り値のない呼び出しは、呼ぶ前にextcodesizeを確認 | 2026-10-19 |
| 低水準の呼び出しと存在しないアカウント | call・delegatecall・staticcallは、存在しないアカウントを呼んでも最初の戻り値がtrue。必要なら呼び出しの前に自分で確認 | 2026-10-19 |
| ランタイムのサイズ | Token 889 / FakeToken 570 / Prober 1,619 / Pool 1,069（バイト） | 2026-10-19 |
| Pool.payのガス | 56,160（内側のToken.transfer 28,512） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| newでコントラクトを作る | [第84講](../../part5/lecture84/) |
| 相手にサポートしているインターフェースを問う標準 | [第159講](../../part10/lecture159/) |
| コントラクト型が間違っていたときに生じる攻撃の形 | [第171講](../../part11/lecture171/) |
| インターフェースの文法全般、インターフェースと抽象コントラクト | [第115講](../../part6/lecture115/) |
| アドレスとコントラクト型のあいだの変換のルール全般 | [第73講](../../part4/lecture73/) |
| コードのないアドレスの呼び出しが実際の事故につながる場合 | [第99講](../../part6/lecture99/)、[第122講](../../part7/lecture122/)、[第170講](../../part11/lecture170/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
