# 第29講 cheatcodeを深く

第2部 開発とテスト環境・第7章 ローカルチェーンとテスト

[← 第28講](../../part2/lecture28/) | [第2部 目次](../) | [第30講 →](../../part2/lecture30/)

## この講義の問い

テストの中で送り手と時刻と残高を変える命令とは何であり、それを使うほど、テストは本物のチェーンとどう違っていくのか。

## 実習資料

### 準備

`forge init`のプロジェクトに`solc = "0.8.30"`を入れ、forge-std（`lib/forge-std`）をそのまま使う。テストはforgeの中でだけ動く。vmのアドレスに送った呼び出しが普通のノードではどうなるかを見るときだけ、ローカルのanvilを起動する。`<=`の実験は、TimeLockのコピーを置いた別のフォルダで行う。

### コード

| ファイル | 内容 |
|---|---|
| [code/cheat/foundry.toml](code/cheat/foundry.toml) | solc 0.8.30に固定 |
| [code/cheat/src/Owned.sol](code/cheat/src/Owned.sol) | オーナーだけが手数料を変えられるコントラクト、`NotOwner(address)`エラー |
| [code/cheat/src/OwnedBroken.sol](code/cheat/src/OwnedBroken.sol) | Ownedからオーナー確認の1行を消したもの |
| [code/cheat/src/TimeLock.sol](code/cheat/src/TimeLock.sol) | 預けてから1日たたないと引き出せない金庫、`TooEarly`エラー |
| [code/cheat/src/Token.sol](code/cheat/src/Token.sol) | totalSupplyとbalanceOf、Transferイベントだけがあるトークン |
| [code/cheat/test/Owned.t.sol](code/cheat/test/Owned.t.sol) | `vm.prank`でオーナーと他人を入れ替えながらテスト |
| [code/cheat/test/OwnedBroken.t.sol](code/cheat/test/OwnedBroken.t.sol) | 同じテストをOwnedBrokenで実行 |
| [code/cheat/test/StartPrank.t.sol](code/cheat/test/StartPrank.t.sol) | `prank`が一度しか効かないこと、`startPrank`、`vm.load` |
| [code/cheat/test/TimeLock.t.sol](code/cheat/test/TimeLock.t.sol) | `vm.warp`、`vm.roll`で時刻とブロック番号を動かしたテスト |
| [code/cheat/test/Probe.t.sol](code/cheat/test/Probe.t.sol) | vmのアドレスのコード、テストコントラクトのアドレス、開始時のtimestamp・numberの確認 |
| [code/cheat/test/Indep.t.sol](code/cheat/test/Indep.t.sol) | rollとwarpが互いに別々に動くことの確認 |
| [code/cheat/test/Token.t.sol](code/cheat/test/Token.t.sol) | `vm.expectEmit`、`vm.store`、`vm.deal` |
| [code/cheat/test/EmitWrong.t.sol](code/cheat/test/EmitWrong.t.sol) | イベントの値を間違えて期待したテスト（わざと失敗） |
| [code/cheat/test/RevertWrong.t.sol](code/cheat/test/RevertWrong.t.sol) | 失敗の理由を間違えて期待したテスト（わざと失敗） |
| [code/cheat/test/VmAddr.t.sol](code/cheat/test/VmAddr.t.sol) | `address(vm)`と、`keccak256("hevm cheat code")`で計算したアドレスの比較 |
| [code/buggy/src/TimeLock.sol](code/buggy/src/TimeLock.sol)、[code/buggy/test/TimeLock.t.sol](code/buggy/test/TimeLock.t.sol)、[code/buggy/foundry.toml](code/buggy/foundry.toml) | TimeLockの`<`を`<=`に変えたコピーと同じテスト |

### 実行結果

vmのアドレスは`cast keccak "hevm cheat code"`の後ろ20バイトである：

```
0x885cb69240a935d632d79c317109709ecfa91a80626ff3989d68f67f5b1dd12d
```

VmAddrテストのログは、`0x7109709ECfa91a80626fF3989D68f67F5b1DD12D`の2行と`1`（コードの長さ）である。新しく起動したanvilでの同じアドレスの`cast code`は`0x`（コードなし）で、そのアドレスに`warp(uint256)` 100を送ると何も起きずに成功する。ブロックの時刻は100ではなく実際の現在時刻である：

```
status               1 (success)
logs                 []
1792295754
```

prankなしで他人がsetFeeを呼ぶと、テストコントラクトのアドレスがmsg.senderになって失敗する：

```
[FAIL: NotOwner(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496)] test_NoPrank() (gas: 29451)
```

`vm.prank`でオーナー（alice）と他人（bob）を入れ替えながらテストした結果：

```
[PASS] test_OtherCannotSetFee() (gas: 35842)
[PASS] test_OwnerCanSetFee() (gas: 59738)
```

`prank`はすぐ次の呼び出し一つにだけかかる。2回目の呼び出しでは元のアドレスに戻って失敗する。`startPrank`は止めるまで続く：

```
[FAIL: NotOwner(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496)] test_PrankOnlyOnce() (gas: 81314)
[PASS] test_StartPrank() (gas: 89626)
```

同じテストをオーナー確認を消したOwnedBrokenで実行すると、「他人は変えられない」側が`FAIL: next call did not revert as expected`になる。

TimeLock。預けた直後に引き出すと`TooEarly`でリバートされ、1日warpしたあとは引き出せる。失敗を期待せずにそのまま呼んだバージョンは、失敗の理由をそのまま見せる：

```
[FAIL: TooEarly(86400 [8.64e4], 86401 [8.64e4])] test_TooEarlyNoExpect() (gas: 101590)
[PASS] test_AfterOneDay() (gas: 42056)
[PASS] test_TooEarly() (gas: 35474)
```

`<`を`<=`に変えたコピーでは、ちょうど1日たった時点で引き出せない：

```
[FAIL: TooEarly(86401 [8.64e4], 86401 [8.64e4])] test_AfterOneDay() (gas: 34935)
[PASS] test_TooEarly() (gas: 35471)
```

rollとwarpは互いに別々に動く（Indepテスト、`block.number block.timestamp`の順）：

```
Logs:
  1 1
  7201 1
  7201 86401
```

`vm.load`でOwnedの0番の欄（owner）を読むと、aliceのアドレスが出る：

```
Logs:
  0x00000000000000000000000000000000000000000000000000000000000a11ce
```

Tokenのストレージの欄の配置（`forge inspect Token storageLayout --offline`）と、bobの残高が入る欄の番号（`cast index address 0x...0B0B 1`）：

```
| Name        | Type                        | Slot |
| totalSupply | uint256                     | 0    |
| balanceOf   | mapping(address => uint256) | 1    |

0x89d389afd974c1027fb0142f999a77333c2f0557f3c8ddf9672539b882e1f72c
```

`vm.store`でその欄に500を書くと、totalSupplyは1,000、aliceは1,000、bobは500になり、残高の合計（1,500）が供給量と合わなくなる。関数の呼び出しだけでは作れない状態である。その状態でbobがトークンを送るテストも通る：

```
[PASS] test_StoreBalance() (gas: 41583)
[PASS] test_BobSendsStoredTokens() (gas: 45525)
[PASS] test_Deal() (gas: 8662)
[PASS] test_TransferEmits() (gas: 67716)
```

期待を間違えて書いた二つのテスト。失敗の理由が違うとき、そしてイベントの値が違うときに失敗する：

```
[FAIL: Error != expected error: NotOwner(0x0000000000000000000000000000000000000B0b) != NotOwner(0x00000000000000000000000000000000000A11cE)] test_WrongReason() (gas: 37883)
[FAIL: Transfer param mismatch at amount: expected=99, got=100] test_WrongAmount() (gas: 67722)
```

`cast sig`で見たcheatcodeのセレクタは、`warp(uint256)` = `0xe5d6bf02`、`prank(address)` = `0xca669fa7`である。

### 試すときの注意

- cheatcodeは、forgeの中のEVMがvmのアドレスへ向かう呼び出しを横取りして処理するものである。普通のノードでは、コードのないアドレスへの呼び出しにすぎない。ノードで同じことをするには、anvil専用のコマンド（`anvil_impersonateAccount`、`evm_increaseTime`、`anvil_setStorageAt`など）を使う。
- forgeのテストはblock.timestamp 1、block.number 1から始まる。
- 1日は86,400秒、12秒のスロットで7,200個である。warpだけしてrollをしなければ、ブロック番号はそのままである。

## 時効性のあるデータ

基準日時点の値。forgeのバージョンによって変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 実行環境 | Foundry 1.8.3（forge、cast、anvil、Commit cae51ad）、solc 0.8.30 | 2026-10-18 |
| vmのアドレス | `0x7109709ECfa91a80626fF3989D68f67F5b1DD12D`（keccak256("hevm cheat code")の後ろ20バイト） | 2026-10-18 |
| forgeの中のvmのアドレスのコード | `0x00`（1バイト） | 2026-10-18 |
| 新しく起動したanvilのvmのアドレスのコード | `0x`（なし） | 2026-10-18 |
| anvilに送ったwarp(100) | status 1、gasUsed 21,510、logs []、そのときできた最初のブロックのtimestampは1792295754 | 2026-10-18 |
| forgeのテストのデフォルト値 | 開始時のblock.timestamp 1、block.number 1、テストコントラクトのアドレス`0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496` | 2026-10-18 |
| テストのガスの値 | 実行結果の出力そのまま。コンパイラ・forgeのバージョンによって変わる | 2026-10-18 |
| セレクタ | `warp(uint256)` = `0xe5d6bf02`、`prank(address)` = `0xca669fa7` | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| mappingの欄の番号の規則とストレージの配置 | [第135講](../../part8/lecture135/) |
| errorの宣言、require・revert・assertの違い | [第90講](../../part5/lecture90/)、[第91講](../../part5/lecture91/) |
| イベントの宣言、indexedとトピックの構造、チェーンの外での読み取り | [第105講](../../part6/lecture105/)、[第106講](../../part6/lecture106/)、[第107講](../../part6/lecture107/) |
| 本物のチェーンの状態を持ってきたテスト | [第30講](../../part2/lecture30/) |
| 常に成り立つべき規則（残高の合計 = 供給量）をランダムな入力でテスト | [第31講](../../part2/lecture31/) |
| 失敗出力の呼び出しツリーを詳しく読む | [第32講](../../part2/lecture32/) |
| アクセス制限のパターン、tx.origin | [第151講](../../part9/lecture151/)、[第176講](../../part11/lecture176/) |
| テストスイート全体の構成 | [第258講](../../part20/lecture258/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
