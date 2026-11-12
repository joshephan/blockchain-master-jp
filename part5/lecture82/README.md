# 第82講 内部関数の呼び出しと名前つき引数

第5部 言語の詳細 ② グローバル変数と制御構造・第18章 式と制御構造

[← 第81講](../../part5/lecture81/) | [第5部 目次](../) | [第83講 →](../../part5/lecture83/)

## この講義の問い

同じコントラクトの中で関数を呼ぶと機械では何が起き、引数はどうやって渡るのか。

## 実習資料

### 準備

空のFoundryプロジェクト三つから始める。`demo`はビルドが通るバージョン、`errors`はビルドエラーを見るバージョン、`ptr`は内部関数の値を確かめるバージョンである。どれもfoundry.tomlで`solc = "0.8.30"`に固定し、forge-stdを`lib/forge-std`に置く。コントラクトはローカルのanvilに既定のアカウント0番（デプロイ・管理者）で`forge create`し、預け入れは既定のアカウント1番で送る（どちらもanvilの公開されたテスト用の鍵）。`jumps.py`はPython 3の標準ライブラリだけを使う。`errors`のファイルは一つずつ`forge build --offline --force src/<ファイル>`でビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Calls.sol](code/demo/src/Calls.sol) | `_who()`・`who()`・`this.who()`でmsg.senderを読む、memory配列を渡す`_bump`・`this.bump`、再帰の`depth(n)` |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarket。depositの本体を`_credit`（名前つき引数）に移し、`withdraw`・`_debit`・`_touch`（storageの引数）を足したバージョン。第81講の`collateralCount`を含み、状態の欄はそのまま（スロット0〜6） |
| [code/demo/src/MarketSwap.sol](code/demo/src/MarketSwap.sol) | 状態の欄をMarketと同じにしたデモ用のバージョン。assetとuserを入れ替えて書いた`deposit`と、名前つき引数で順番だけを入れ替えた`depositNamed` |
| [code/demo/src/Token.sol](code/demo/src/Token.sol) | デモ用の最小限のトークン。この講義ではアドレスとしてだけ使う |
| [code/demo/test/Calls.t.sol](code/demo/test/Calls.t.sol) | 内部・public・thisの呼び出し、memoryの引数の二つのバージョンのトレースの比較 |
| [code/demo/test/Market.t.sol](code/demo/test/Market.t.sol) | deposit 500、withdraw 200のあと、預け入れが300かを確かめる |
| [code/ptr/foundry.toml](code/ptr/foundry.toml) | solc 0.8.30に固定 |
| [code/ptr/src/Ptr.sol](code/ptr/src/Ptr.sol) | 内部関数型の値`_who`を数字として取り出す`ptr()` |
| [code/jumps.py](code/jumps.py) | `debug_traceCall`の結果からJUMP・JUMPDEST・CALLER・STATICCALL・RETURNの行だけを抜き出すスクリプト。引数はファイルと、構造ログの行番号の範囲 |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/ExtCall.sol](code/errors/src/ExtCall.sol) | external関数を名前だけ書いて呼ぶ、Error 7576 |
| [code/errors/src/ExtCallThis.sol](code/errors/src/ExtCallThis.sol) | 同じ呼び出しを`this.ping()`に直したバージョン。ビルドが通る |
| [code/errors/src/ThisInternal.sol](code/errors/src/ThisInternal.sol) | internal関数を`this._who()`で呼ぶ、Error 9582 |
| [code/errors/src/Market.sol](code/errors/src/Market.sol) | `_credit`にない名前`account:`を渡したバージョン、Error 4974 |
| [code/errors/src/ExtStorage.sol](code/errors/src/ExtStorage.sol) | external関数のstorageの引数、Error 6651 |
| [code/errors/src/MapMemory.sol](code/errors/src/MapMemory.sol) | マッピングを含む構造体をmemoryの引数に、Error 4061 |

### 実行結果

`forge test --offline -vvvv --match-contract CallsTest`のトレース（テストの最初の行・最後の行は省略）。内部呼び出しでは行が増えず、`this.who()`では1行増えてmsg.senderがCalls自身になる。

```
[PASS] test_internal() (gas: 5961)
    ├─ [457] Calls::viaInternal() [staticcall]
    │   └─ ← [Return] CallsTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]

[PASS] test_public() (gas: 5985)
    ├─ [458] Calls::viaPublic() [staticcall]
    │   └─ ← [Return] CallsTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]

[PASS] test_this() (gas: 11555)
    ├─ [3863] Calls::viaThis() [staticcall]
    │   ├─ [379] Calls::who() [staticcall]
    │   │   └─ ← [Return] Calls: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]
    │   └─ ← [Return] Calls: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]
```

anvilにデプロイしたCallsに`cast rpc debug_traceCall`（`disableStorage`、`disableMemory`）で構造ログを取り、`jumps.py`でふるいにかけた結果。各行はコードの位置（pc）、命令、depth、実行直前のスタックの上二つ（右がいちばん上）である。viaInternalはdepth 1の中でジャンプして戻り、viaThisはSTATICCALLの次からdepth 2になる。

```
$ python -I jumps.py tr_internal.json 47 55
  799 JUMP       depth 1  0x320 0x44d
 1101 JUMPDEST   depth 1  0x0 0x320
 1103 CALLER     depth 1  0x320 0x0
 1107 JUMP       depth 1  0x0 0x320
  800 JUMPDEST   depth 1  0x0 0x0
$ python -I jumps.py tr_this.json 75 75
  671 STATICCALL depth 1  0x5fbdb2315678afecb367f032d93f642f64180aa3 0x1c97021
$ python -I jumps.py tr_this.json 111 111
  729 CALLER     depth 2  0x108 0x0
```

Ptrだけを新しいanvilにデプロイして`ptr()`を呼ぶと146が出て、PtrのviaInternalの構造ログでは`140 JUMP`の次の行が`146 JUMPDEST`である。

memory配列を渡す二つのバージョンのトレース。内部呼び出しでは呼んだ側の配列が変わって2になり、`this.bump`はコピーを書き換えるので1である。

```
[PASS] test_memInternal() (gas: 6370)
    ├─ [902] Calls::memInternal() [staticcall]
    │   └─ ← [Return] 2

[PASS] test_memThis() (gas: 10989)
    ├─ [5499] Calls::memThis() [staticcall]
    │   ├─ [1372] Calls::bump([1]) [staticcall]
    │   │   └─ ← [Stop]
    │   └─ ← [Return] 1
```

ビルドエラー。

```
Error (7576): Undeclared identifier. "ping" is not (or not yet) visible at this point.
  --> src/ExtCall.sol:10:16:
   |
10 |         return ping();
   |                ^^^^
Error (4974): Named argument "account" does not match function declaration.
  --> src/Market.sol:54:9:
   |
54 |         _credit({asset: asset, account: msg.sender, amount: amount});
   |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (6651): Data location must be "memory" or "calldata" for parameter in external function, but "storage" was given.
  --> src/ExtStorage.sol:10:20:
   |
10 |     function touch(Position storage p) external {
   |                    ^^^^^^^^^^^^^^^^^^
Error (4061): Type struct Book memory is only valid in storage because it contains a (nested) mapping.
  --> src/MapMemory.sol:12:19:
   |
12 |     function _add(Book memory b) internal pure {
   |                   ^^^^^^^^^^^^^
```

`ThisInternal.sol`はError 9582（Member "_who" not found or not visible after argument-dependent lookup）で止まる。

MarketSwapの、assetとuserを入れ替えて書いた`deposit`は警告なしでビルドされる。1番のアカウントで`deposit(トークン, 500)`を送ったあとに読んだ欄。500はpositions[1番のアカウント][トークン]に入った（`$TK`はデモ用のトークン、`$A1`は1番のアカウント、positionsはスロット4）。

```
$ cast call $MS "positions(address,address)(uint256,uint256,uint64,bool)" $TK $A1
0
0
0
false
$ cast call $MS "positions(address,address)(uint256,uint256,uint64,bool)" $A1 $TK
500
0
1792398269 [1.792e9]
false
$ cast call $MS "totalDeposits(address)(uint256)" $A1
500
$ cast storage $MS $(cast index address $A1 $(cast index address $TK 4))
0x0000000000000000000000000000000000000000000000000000000000000000
$ cast storage $MS $(cast index address $TK $(cast index address $A1 4))
0x00000000000000000000000000000000000000000000000000000000000001f4
```

名前つき引数で順番だけを入れ替えた`depositNamed(トークン, 300)`のあとでは、positions[トークン][1番のアカウント]に300が正しく入る。

Marketの`deposit(トークン, 500)`が11番のブロックに入ったあとの、positions[トークン][1番のアカウント]の欄と、その二つ後ろの欄。二つ後ろの欄のlastUpdateがそのブロックの時刻である。

```
$ cast storage $M 0x8a383a8ba0e749950ebedf3c30150e4bc6644d4772adfadb2940b492cc689bab
0x00000000000000000000000000000000000000000000000000000000000001f4
$ cast storage $M 0x8a383a8ba0e749950ebedf3c30150e4bc6644d4772adfadb2940b492cc689bad
0x000000000000000000000000000000000000000000000000000000006ad5d3be
$ cast block 11 --field timestamp
1792398270
$ cast to-dec 0x6ad5d3be
1792398270
```

再帰の`depth(n)`。253まではそのまま返し、254からスタックがあふれる。

```
$ cast call $C "depth(uint256)(uint256)" 253
253
$ cast call $C "depth(uint256)(uint256)" 254
Error: server returned an error response: error code -32003: EVM error StackOverflow
```

`cast send`で`--gas-limit 1000000`を指定すると、253はgasUsed 131906、status 1で、254はgasUsed 1000000（上限すべて）、status 0である。

Marketのdepositトランザクションの`cast run`のトレースは、depositの1行だけである（`_credit`、`_touch`は内部呼び出し）。withdraw 200のあと、預け入れは300である。

```
Traces:
  [70215] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::deposit(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9, 500)
    └─ ← [Stop]
```

`forge inspect --offline Market methodIdentifiers`には`deposit(address,uint256)`（47e7ef24）、`withdraw(address,uint256)`（f3fef3a3）だけがあり、`_credit`・`_debit`・`_touch`はない。

### 試すときの注意

- 同じコントラクトの関数でも、`this.f()`で呼ぶと外部呼び出しになる。msg.senderがこのコントラクトに変わり、memoryの引数はエンコードしたコピーとして渡る。
- 位置引数の順番を入れ替えて書いても、型が同じならエラーも警告も出ない。同じ型の引数が複数あるときは`f({名前: 値})`の形で渡す。
- storageの引数はinternal・private関数にしか渡せない。マッピングを含む構造体を関数に渡す方法もこれしかない。
- 再帰の限界253は、このコードをsolc 0.8.30の既定の設定（optimizerは切る、via-IRではない）でビルドしたバージョンでの値である。バージョン・設定・関数の形によって変わる。
- ブロックの時刻（`1792398269`など）はanvilを立ち上げた時刻に従うので、実行し直すと変わる。
- このバージョンのMarketの`withdraw`はトークンを動かさず、欄だけを書き換える。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のコード生成（via-IRではない） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 再帰のdepthの最大 | 253で成功、254でStackOverflow（Calls、solc 0.8.30 optimizerは切る）。コンパイラのバージョン・設定・関数の形によって変わる | 2026-10-19 |
| トレースのガス | viaInternal 457、viaPublic 458、viaThis 3,863（内側のwho 379）、memInternal 902、memThis 5,499（内側のbump 1,372） | 2026-10-19 |
| gasUsed（参考） | depth(253) 131,906 / depth(254) 1,000,000（上限すべて） / MarketSwap deposit 91,703、depositNamed 91,791 / Market deposit 91,799、withdraw 38,189 | 2026-10-19 |
| 内部関数の値 | Ptrの`_who`の値146、viaInternalがジャンプしたJUMPDEST 146（既定のコード生成） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 外部呼び出しが渡す制御権、呼び出しオプション（`{value: }`・`{gas: }`）、外部呼び出しの引数の残りの規則 | [第83講](../../part5/lecture83/) |
| 可視性の4段階の規則 | [第95講](../../part6/lecture95/) |
| 状態変数のgetterを中で呼ぶ形と読み取りのコスト | [第97講](../../part6/lecture97/) |
| 同じ名前の関数が複数あるとき（オーバーロード）と名前つき引数 | [第100講](../../part6/lecture100/) |
| modifierと内部呼び出しの関係 | [第103講](../../part6/lecture103/) |
| 継承した関数を呼ぶ順番（super） | [第113講](../../part6/lecture113/) |
| ライブラリのinternal関数とstorageの引数 | [第116講](../../part6/lecture116/) |
| ストレージの欄の配置規則 | [第135講](../../part8/lecture135/) |
| コードの精読で引数の順番・storageの別名を確かめること | [第188講](../../part12/lecture188/) |
| 同じ名前が指す欄と宣言の位置 | [第87講](../../part5/lecture87/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
