# 第79講 暗号の関数：keccak256、sha256、ecrecover

第5部 言語の詳細 ② グローバル変数と制御構造・第17章 単位とグローバル変数

[← 第78講](../../part5/lecture78/) | [第5部 目次](../) | [第80講 →](../../part5/lecture80/)

## この講義の問い

ハッシュ関数と署名の復元関数は、受け取ったバイトで何を計算し、何をコードを書いた人に残すのか。

## 実習資料

### 準備

空のFoundryプロジェクト二つから始める。`demo`はビルドが通るバージョン、`errors`はビルドエラーを見るバージョンである。どちらもfoundry.tomlで`solc = "0.8.30"`に固定し、テストにはforge-std（`lib/forge-std`）が必要である。ローカルのanvilに既定のアカウント0番でMarket、Hashes、Gate、SafeGateを順に`forge create`し、管理者が資産`0x000000000000000000000000000000000000AAAA`を比率75で登録したあと、アリス（既定のアカウント1番）が500を預ける。二つの鍵はどちらもanvilの公開されたテスト用の鍵である。署名は`cast wallet sign --no-hash`でアリスの鍵を使って作り、65バイトをr（先頭32バイト）、s（次の32バイト）、v（最後の1バイト）に切って渡す。`errors`のファイルは`forge build --offline --force src/<ファイル>`で一つずつビルドする。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Market.sol](code/demo/src/Market.sol) | 通しプロジェクトのMarketの第72講のバージョン。positionsの欄を計算して突き合わせる対象 |
| [code/demo/src/Hashes.sol](code/demo/src/Hashes.sol) | positionsの欄の計算、keccak256・sha256・ripemd160の比較、encodePackedの衝突、0〜100の当てはめ、`ecrecover`の呼び出し |
| [code/demo/src/Gate.sol](code/demo/src/Gate.sol) | 署名者の欄が空だとでたらめな署名が通るGateと、復元結果が`address(0)`ならリバートするSafeGate |
| [code/demo/src/Voucher.sol](code/demo/src/Voucher.sol) | チェーン番号をハッシュに入れたバージョンと入れないバージョン |
| [code/demo/test/Trace.t.sol](code/demo/test/Trace.t.sol) | プリコンパイルの呼び出しがトレースに出る`test_three`、`test_recover` |
| [code/demo/test/Voucher.t.sol](code/demo/test/Voucher.t.sol) | `vm.chainId(5)`でチェーン番号だけを変えて同じ署名を確かめる`test_chainId` |
| [code/errors/foundry.toml](code/errors/foundry.toml) | solc 0.8.30に固定 |
| [code/errors/src/Sha3.sol](code/errors/src/Sha3.sol) | 古い名前`sha3`、Error 3557 |
| [code/errors/src/Erc.sol](code/errors/src/Erc.sol) | 0.8.30にない`erc7201`、Error 7576 |
| [code/errors/src/Payable.sol](code/errors/src/Payable.sol) | `ecrecover`の結果を`address payable`に代入、Error 9574 |

### 実行結果

Hashesで計算したpositionsの欄、`cast index`で計算した欄、その欄を`cast storage`で読んだ値。0x1f4はアリスが預けた500である。

```
$ cast call $HASHES "positionSlot(address,address)(bytes32)" 0x000000000000000000000000000000000000AAAA $ALICE
0x38bb39d3455c9ab9596b6ddbdd0e9f6d06a6d98609d16fa00df0a9d840121780
$ cast index address $ALICE $(cast index address 0x000000000000000000000000000000000000AAAA 4)
0x38bb39d3455c9ab9596b6ddbdd0e9f6d06a6d98609d16fa00df0a9d840121780
$ cast storage $MARKET 0x38bb39d3455c9ab9596b6ddbdd0e9f6d06a6d98609d16fa00df0a9d840121780
0x00000000000000000000000000000000000000000000000000000000000001f4
```

候補が0〜100しかなければ、ハッシュから入力を当てられる。73を見つけるのに74回ハッシュした。

```
$ cast keccak $(cast abi-encode "f(uint256)" 73)
0x37e472f504e93744df80d87316862f9a8fd41a7bc266c723bf77df7866d75f55
$ cast call $HASHES "guess(bytes32)(uint256,uint256)" 0x37e472f504e93744df80d87316862f9a8fd41a7bc266c723bf77df7866d75f55
73
74
```

`"hello"`一つをkeccak256、sha256、ripemd160に入れた結果。

```
$ cast call $HASHES "three()(bytes32,bytes32,bytes20)"
0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8
0x2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
0x108f07b8382412612c048d07d13f814118445acd
```

`forge test --offline -vvvv --match-contract TraceTest`。sha256とripemd160はプリコンパイルの呼び出しとして出て、keccak256の行はない（出力の一部を省略）。

```
[PASS] test_three() (gas: 8123)
Traces:
  [8123] TraceTest::test_three()
    ├─ [2380] Hashes::three() [staticcall]
    │   ├─ [72] PRECOMPILES::sha256(0x68656c6c6f) [staticcall]
    │   │   └─ ← [Return] 0x2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
    │   ├─ [720] PRECOMPILES::ripemd(0x68656c6c6f) [staticcall]
    │   │   └─ ← [Return] 0x000000000000000000000000108f07b838241261
    │   └─ ← [Return] 0x1c8aff95…, 0x2cf24dba…, 0x108f07b8…
    └─ ← [Stop]
[PASS] test_recover() (gas: 11358)
    ├─ [4879] Hashes::recover(0xf32adad1…, 28, 0xbc2506ab…, 0x3cf82f6f…) [staticcall]
    │   ├─ [3000] PRECOMPILES::ecrecover(…) [staticcall]
    │   │   └─ ← [Return] 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

アドレス0x02を直接呼ぶと、コードがないのに（`cast code`が`0x`）sha256の値が返ってくる。

```
$ cast call 0x0000000000000000000000000000000000000002 0x68656c6c6f
0x2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

`packed()`：encodePackedで作った`"a"+"bc"`と`"ab"+"c"`は同じハッシュ（`cast keccak abc`とも同じ）になり、encodeで作ると分かれる。

```
$ cast call $HASHES "packed()(bytes32,bytes32,bytes32,bytes32)"
0x4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45
0x4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45
0x68cd083d4c97fcbd081751d5390da5b37f5c485fd0879180d4816c456e8e532c
0x8c98d57214b9f76c3240d1fc677eb9fc1529ec2a4f56949bb6abe31d50b4b7c6
```

`"pay bob 100"`のハッシュにアリスの鍵で署名した結果と、その署名から復元したアドレス。ハッシュだけを`"pay bob 900"`に変えると、リバートせずに別のアドレスが出てくる。

```
$ MSG=$(cast keccak "pay bob 100"); echo $MSG
0xf32adad13244a267869fe7bb8081a1ab51863121d3ff7810216b8187f4f5225a
$ cast wallet sign --no-hash --private-key $PK1 $MSG
0xbc2506ab736f82a3d383b5692f623ba0e487f7a13d2dc1d776b2a68857f004e73cf82f6f5e544ead19fb55e723ebf26df45889c190e465cc3939ecc87af941a71c
$ cast call $HASHES "recover(bytes32,uint8,bytes32,bytes32)(address)" 0xf32adad1…225a 28 0xbc2506ab…04e7 0x3cf82f6f…41a7
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast call $HASHES "recover(bytes32,uint8,bytes32,bytes32)(address)" 0x3291112e…a9cc 28 0xbc2506ab…04e7 0x3cf82f6f…41a7
0xA3353195551E24AaE0240637Fc1dD655D8e2FD21
```

sを曲線の位数nから引いた値にし、vを28から27に変えた二つ目の署名もアリスに復元される（署名の展性）。vを29に、rを0にすると、リバートせずに`address(0)`が出る。

```
$ cast call $HASHES "recover(bytes32,uint8,bytes32,bytes32)(address)" 0xf32adad1…225a 27 0xbc2506ab…04e7 0xc307d090a1abb152e604aa18dc140d90c65653251e643a6f869871c4553cff9a
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast call $HASHES "recover(bytes32,uint8,bytes32,bytes32)(address)" 0xf32adad1…225a 29 0xbc2506ab…04e7 0x3cf82f6f…41a7
0x0000000000000000000000000000000000000000
```

署名者をまだ決めていないGateは、復元の失敗（`address(0)`）と空の署名者の欄（`address(0)`）を同じとみなしてtrueを返す。SafeGateは先にふるい落としてリバートする。

```
$ cast call $GATE "check(bytes32,uint8,bytes32,bytes32)(bool)" 0xf32adad1…225a 29 0x1111111111111111111111111111111111111111111111111111111111111111 0x1111111111111111111111111111111111111111111111111111111111111111
true
$ cast call $SAFEGATE "check(bytes32,uint8,bytes32,bytes32)(bool)" 0xf32adad1…225a 29 0x1111…1111 0x1111…1111
Error: execution reverted: bad signature
$ cast send $SAFEGATE "setSigner(address)" $ALICE --private-key $PK0
$ cast call $SAFEGATE "check(bytes32,uint8,bytes32,bytes32)(bool)" 0xf32adad1…225a 28 0xbc2506ab…04e7 0x3cf82f6f…41a7
true
```

`forge test --offline -vv --match-test test_chainId`。チェーン番号を入れないバージョンは、チェーン5でも同じ署名が通る。

```
[PASS] test_chainId() (gas: 100522)
Logs:
  chainid 31337
  noChain   true
  withChain true
  chainid 5
  noChain   true
  withChain false
```

古い名前`sha3`のビルドエラー。

```
Error (3557): "sha3" has been deprecated in favour of "keccak256".
```

### 試すときの注意

- `…`で省略したハッシュ・r・sには、上の署名の出力の値をすべて入れる。
- `ecrecover`は署名を検証せず、アドレスを一つ計算して返すだけである。復元に失敗してもリバートせずに`address(0)`を返すので、結果が0でないことを先に確かめてから、期待したアドレスと比べる。
- 署名のバイトを「使用済み」の印に使ってはいけない。同じメッセージに別の有効な署名が作れる。印は番号（nonce）につける。
- ハッシュに入れなかった値（チェーン番号、コントラクトのアドレス、番号）には、署名は結びつかない。
- ハッシュの材料は`abi.encode`で作る。`encodePacked`は固定サイズの値だけをつなぐときに使う。
- `keccak256("hello")`のようなリテラルの入力は、コンパイラが先に計算して定数として入れる（`forge inspect --offline Hashes assembly`）。
- Marketは第72講のバージョンをそのまま使った。第75講〜第78講で足した行は欄を増やさないので、positionsの欄の番号と値は同じである。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| プリコンパイルのアドレスとガス | 0x01 ecrecover 3,000 / 0x02 sha256 60 + 32バイトごとに12 / 0x03 ripemd160 600 + 32バイトごとに120 / KECCAK256命令 30 + 32バイトごとに6。トレースでの測定：ecrecover 3000、sha256（5バイト）72、ripemd（5バイト）720 | 2026-10-19 |
| ecrecoverの失敗条件 | vが27・28でない、rまたはsが0か曲線の位数n以上、復元される点がない → 空の出力、Solidityでは`address(0)` | 2026-10-19 |
| secp256k1の曲線の位数n | `0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141` | 2026-10-19 |
| 署名の展性 | EIP-2（Homestead、2016年3月）：トランザクションの署名のsをn/2以下に制限。ecrecoverプリコンパイルには制限なし | 2026-10-19 |
| OpenZeppelin ECDSA | v5.4.0 `ECDSA.sol`：sが`0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0`を超えると`InvalidSignatureS`、復元結果が`address(0)`なら`InvalidSignature` | 2026-10-19 |
| チェーン番号 | anvilの既定 31337、テストでは`vm.chainId(5)`で変更 | 2026-10-19 |
| ほかの言語のハッシュ | Python 3.12.10 `hashlib.sha256(b'hello')` = `2cf24dba…8b9824`、`hashlib.new('ripemd160', b'hello')` = `108f07b8…118445acd`、Node.js v24.11.0 `sha3-256('hello')` = `3338be69…398f392` | 2026-10-19 |
| guessのガス | `cast estimate` 55,379（基本の21,000を含む、74回目で見つかる） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| `ecrecover`の`address(0)`と失敗処理の規則全体（require、revert、try/catch） | [第90講](../../part5/lecture90/)、[第91講](../../part5/lecture91/) |
| saltでアドレスを先に計算する作成（`keccak256`が入るアドレスの計算） | [第84講](../../part5/lecture84/) |
| 関数セレクタの計算（シグネチャのkeccak256の先頭4バイト） | [第101講](../../part6/lecture101/) |
| イベントのindexedの値がハッシュで残る場合と、元の値を探すこと | [第106講](../../part6/lecture106/) |
| グローバル関数の総覧（`addmod`、`mulmod`を含む） | [第126講](../../part7/lecture126/) |
| マッピング・動的配列の欄の計算規則全体 | [第135講](../../part8/lecture135/) |
| リプレイ攻撃の手順、署名の再利用 | [第172講](../../part11/lecture172/)、[第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/)、[第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| マークルルートを検査しなかったブリッジの乗っ取り | [第179講](../../part11/lecture179/)、[第212講](../../part14/lecture212/) |
| 投票でハッシュで隠した値 | [第213講](../../part14/lecture213/)、[第214講](../../part14/lecture214/)、[第215講](../../part14/lecture215/)、[第216講](../../part14/lecture216/) |
| 署名の展性への対応、EIP-712のメッセージ設計、ウォレットとアカウント抽象化の署名検証 | [第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
