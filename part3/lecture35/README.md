# 第35講 静的型、継承、ライブラリ

第3部 Solidity入門・第9章 言語の性格と系譜

[← 第34講](../../part2/lecture34/) | [第3部 目次](../) | [第36講 →](../../part3/lecture36/)

## この講義の問い

第2部で道具としてだけ使ってきたSolidityはどんな言語で、その形はEVMのどんな事情から生まれたのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトの`src`、`test`、`script`を空にして始める。テストは書かず、すべての確認はローカルのanvilにデプロイして行う。`Label`にはOpenZeppelin Contracts v5.4.0が必要である（`lib/openzeppelin-contracts`、remappings.txtで`@openzeppelin/contracts/`をつなぐ）。ビルドはsolc 0.8.30、最適化オフである。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/remappings.txt](code/remappings.txt) | OpenZeppelinのパスをつなぐ |
| [code/src/Counter.sol](code/src/Counter.sol) | increment・decrementだけがあるCounter |
| [code/src/Owned.sol](code/src/Owned.sol) | オーナー確認一つ（`onlyOwner`）だけがある親 |
| [code/src/OwnedCounter.sol](code/src/OwnedCounter.sol) | Ownedを`is`で継承したCounter |
| [code/src/MathIn.sol](code/src/MathIn.sol) | internal関数だけがあるライブラリMathInと、それを使うCounterIn |
| [code/src/MathPub.sol](code/src/MathPub.sol) | public関数があるライブラリMathPubと、それを使うCounterPub |
| [code/src/CounterUnchecked.sol](code/src/CounterUnchecked.sol) | `unchecked`ブロックであふれの検査をオフにしたCounter |
| [code/src/Label.sol](code/src/Label.sol) | OpenZeppelinの`Strings.toString`で数字を文字に変えるバージョン |

### 実行結果

Counterに`increment()`を1回送ったあと、`cast storage`で読んだ0番の欄。数字なのかアドレスなのかの表示はない：

```
0x0000000000000000000000000000000000000000000000000000000000000001
```

同じ32バイトを三通りにほどくと、どれもエラーなくほどける。`cast to-dec`は`1`、`cast parse-bytes32-address`は`0x0000000000000000000000000000000000000001`、`cast abi-decode "f()(bool)"`は`true`。OwnedCounterの0番の欄（owner）を`cast to-dec`でほどくと`1390849295786071768276380950238675083608645509734`が出る。

引数の型が一つだけ違う二つのシグネチャのセレクタ（`cast sig`）：

```
transfer(address,uint256)  0xa9059cbb
transfer(address,uint128)  0xfbb001d6
```

型の違う二つの値を足す関数（`uint256 a`、`int256 b`、`return a + b;`）を`forge build`：

```
Error (2271): Built-in binary operator + cannot be applied to types uint256 and int256.
```

Counterを2回デプロイするとアドレスは二つで、countも別々である。最初のアドレスにだけ`increment()`を送ったあとの`count()`は、最初のアドレスが1、2番目のアドレスが0である。

```
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

継承の前後のサイズ（`forge build --sizes`）：

| コントラクト | ランタイムコード | 生成コード |
|---|---|---|
| Counter | 424バイト | 452バイト |
| Owned | 240バイト | 330バイト |
| OwnedCounter | 852バイト | 943バイト |

OwnedCounterのアドレス一つで親の`owner()`が答え、ほかのアカウントが`decrement()`を呼ぶと親のmodifierが止める：

```
$ cast call 0xCf7E… "owner()(address)"
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
$ cast storage 0xCf7E… 0
0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
$ cast send 0xCf7E… "decrement()"   (アカウント1)
Error: ... execution reverted: not owner
```

`forge inspect OwnedCounter storageLayout`では、ownerは0番、countは1番の欄である。

public関数があるライブラリを使うCounterPubの成果物（`out/MathPub.sol/CounterPub.json`）には、アドレスのプレースホルダーと`linkReferences`が残る。CounterInのlinkReferencesは`{}`である：

```
"linkReferences": { "src/MathPub.sol": { "MathPub": [ { "start": 103, "length": 20 } ] } }
ランタイムコードの途中: …5481565b73__$9c4d806a8de1b30f59f0fc84b2e4286087$__63eee97206…
```

ライブラリなしでCounterPubを`forge create`すると拒否される：

```
Error: Dynamic linking not supported in `create` command - deploy the following library contracts first, then provide the address to link at compile time
	MathPub: src/MathPub.sol
```

MathPubを先にデプロイし、`--libraries src/MathPub.sol:MathPub:<アドレス>`でリンクしてCounterPubをデプロイしたあと、`grow()`のトランザクションを`cast run`で見たトレース。ライブラリの呼び出しがdelegatecallで行われる：

```
  [9097] 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853::grow()
    ├─ [803] 0x0165878A594ca255338adfa4d48449f69242Eb8F::double(1) [delegatecall]
```

`grow()`1回（1から2へ）のgasUsedは、CounterInが26,509、CounterPubが30,161である。

`uint256`を`string`に直接入れると（`string memory s = count;`）コンパイルできない：

```
Error (9574): Type uint256 is not implicitly convertible to expected type string memory.
```

`Strings.toString`を使ったLabelの`label()`（`cast call`）：

```
"count: 42"
```

あふれの検査のガス（incrementのgasUsed）：

| increment | 0から1へ（初回の書き込み） | 1から2へ |
|---|---|---|
| Counter（`count += 1`、0.8のデフォルトの検査） | 43,539 | 26,439 |
| CounterUnchecked（`unchecked { count += 1; }`） | 43,338 | 26,238 |

呼ぶたびに201ガスの差である。

### 試すときの注意

- デプロイ先のアドレスは、デプロイするアカウントのナンスで決まる。anvilを新しく起動して同じ順番でデプロイしないと、上のアドレスはそのとおりに出ない。
- publicのライブラリを使うコントラクトは、`forge create`1回ではデプロイできない。ライブラリを先にデプロイし、`--libraries`でアドレスを埋める。
- `Strings.toString`はinternal関数なので、Labelはライブラリを別にデプロイせず一度にデプロイできる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 実行環境 | Foundry 1.8.3（forge、cast、anvil）、solc 0.8.30、最適化オフ | 2026-10-19 |
| コントラクトのサイズの上限 | ランタイムコード24,576バイト（EIP-170）、生成コード49,152バイト（EIP-3860） | 2026-10-19 |
| ランタイムコードのサイズ | Counter 424、Owned 240、OwnedCounter 852、CounterIn 352、CounterPub 459、MathPub 427、CounterUnchecked 207、Label（Strings使用）1,178バイト | 2026-10-19 |
| grow 1回のgasUsed | CounterIn 26,509 / CounterPub 30,161（1から2へ） | 2026-10-19 |
| incrementのgasUsed | Counter 43,539・26,439 / CounterUnchecked 43,338・26,238 | 2026-10-19 |
| OpenZeppelin Contracts | v5.4.0（`Strings.toString`はinternal） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 見た目は同じで意味が違う文法（可視性、数字、失敗、継承） | [第36講](../../part3/lecture36/) |
| 整数型と範囲、暗黙的・明示的な変換の規則 | [第51講](../../part4/lecture51/)、[第73講](../../part4/lecture73/) |
| コントラクトの中のnewとsalt付きの生成 | [第84講](../../part5/lecture84/) |
| checked算術とuncheckedブロック | [第88講](../../part5/lecture88/)、[第89講](../../part5/lecture89/) |
| コンストラクタと初期化、デプロイ用のコードとランタイムコード | [第92講](../../part6/lecture92/)、[第93講](../../part6/lecture93/) |
| 関数セレクタの計算とABIエンコーディングの規則 | [第101講](../../part6/lecture101/)、[第141講](../../part8/lecture141/) |
| modifierの文法と実行順序 | [第103講](../../part6/lecture103/) |
| 継承の詳細（オーバーライド、virtualとoverride、多重継承とC3線形化、super、コンストラクタ引数の順序、抽象コントラクトとインターフェース） | [第110講](../../part6/lecture110/)〜[第115講](../../part6/lecture115/) |
| ライブラリの詳細（internalリンク、externalライブラリとdelegatecall、using for） | [第116講](../../part6/lecture116/)、[第117講](../../part6/lecture117/)、[第118講](../../part6/lecture118/) |
| ストレージの欄の配置規則 | [第135講](../../part8/lecture135/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
