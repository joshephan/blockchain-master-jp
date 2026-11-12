# 第32講 トレースの読み方とデバッガー

第2部 開発とテスト環境・第8章 デバッグ・計測・デプロイ

[← 第31講](../../part2/lecture31/) | [第2部 目次](../) | [第33講 →](../../part2/lecture33/)

## この講義の問い

テストが失敗したとき、その中でどんな呼び出しがどんな順番で起きたかはどう読み、それでわからないものは何か。

## 実習資料

### 準備

`forge init`で作ったプロジェクト（forge-std 1.17.0を含む）からCounter関連のファイルを消し、下のソースを入れる。すべてのコマンドに`--offline`をつける。失敗したトランザクションをチェーン上で見直すときは、ローカルのanvilに四つのコントラクトを`forge create`でデプロイし、anvilのデフォルトのテストアカウント0番の鍵で送る。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | `forge init`の基本設定 |
| [code/src/Shop.sol](code/src/Shop.sol) | Shop → Payment → Membershipとつながる注文の流れ。会員でなければ`discount`が`"not a member"`でリバートする。Pointsは常にリバートし、`orderWithPoints`はその失敗を無視する |
| [code/src/Box.sol](code/src/Box.sol) | `delegatecall`でPriceLogicの`set`を呼ぶBox |
| [code/test/Shop.t.sol](code/test/Shop.t.sol) | 会員・非会員の注文、ポイントの失敗の無視、delegatecallのテスト |

### 実行結果

`forge test --offline`：

```
[PASS] test_Delegate() (gas: 61466)
[FAIL: not a member] test_GuestPays() (gas: 69759)
[PASS] test_MemberPays() (gas: 120800)
[PASS] test_PointsIgnored() (gas: 127026)
```

`forge test --offline --match-test test_GuestPays -vvv`。呼び出しがどこまで入り、どこで最初にリバートされたかがツリーで出る：

```
Traces:
  [69759] ShopTest::test_GuestPays()
    ├─ [0] VM::prank(0x00000000000000000000000000000000000A11cE)
    │   └─ ← [Return]
    ├─ [59275] Shop::order(1000)
    │   ├─ [10217] Payment::pay(0x00000000000000000000000000000000000A11cE, 1000)
    │   │   ├─ emit PayRequested(user: 0x00000000000000000000000000000000000A11cE, price: 1000)
    │   │   ├─ [2964] Membership::discount(0x00000000000000000000000000000000000A11cE) [staticcall]
    │   │   │   └─ ← [Revert] not a member
    │   │   └─ ← [Revert] not a member
    │   └─ ← [Revert] not a member
    └─ ← [Revert] not a member

Backtrace:
  at Membership.discount
  at Payment.pay
  at Shop.order
  at ShopTest.test_GuestPays
```

ツリーの`discount(...)`呼び出しに実際に載ったデータは、`cast calldata "discount(address)" 0x...0A11cE`で作れる：

```
0xce06898000000000000000000000000000000000000000000000000000000000000a11ce
```

`-vvvvv`では、リバートされたストレージの変更とソースの行番号まで出る。Shopの`orders`（2番の欄）が0から1に変わってからリバートされた：

```
    │   │   └─ ← [Revert] not a member
    │   ├─  storage changes:
    │   │   @ 2: 0 → 1
    │   └─ ← [Revert] not a member

Backtrace:
  at Membership.discount (src/Shop.sol:12:9)
  at Payment.pay (src/Shop.sol:27:21)
  at Shop.order (src/Shop.sol:50:16)
  at ShopTest.test_GuestPays
```

`test_Delegate -vvvvv`。delegatecallで呼んだPriceLogicの`set`が変えた欄はBoxの側である：

```
    ├─ [47972] Box::setVia(PriceLogic: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 500)
    │   ├─ [22492] PriceLogic::set(500) [delegatecall]
    │   │   ├─  storage changes:
    │   │   │   @ 0: 0 → 500
    │   │   └─ ← [Stop]
    │   └─ ← [Stop]
    ├─ [2402] Box::price() [staticcall]
    │   └─ ← [Return] 500
    ├─ [2424] PriceLogic::price() [staticcall]
    │   └─ ← [Return] 0
    └─ ← [Stop]
```

`test_PointsIgnored -vvvv`。テストは通ったが、ツリーの中に無視された失敗が見える：

```
[PASS] test_PointsIgnored() (gas: 127026)
    ├─ [67006] Shop::orderWithPoints(1000)
    │   ├─ [710] Points::add(0x00000000000000000000000000000000000A11cE)
    │   │   └─ ← [Revert] points closed
    │   ├─ [11212] Payment::pay(0x00000000000000000000000000000000000A11cE, 1000)
    │   │   ├─ emit PayRequested(user: 0x00000000000000000000000000000000000A11cE, price: 1000)
    │   │   ├─ [2872] Membership::discount(0x00000000000000000000000000000000000A11cE) [staticcall]
    │   │   │   └─ ← [Return] 10
    │   │   └─ ← [Return] 900
    │   └─ ← [Return] 900
    └─ ← [Stop]
```

anvilにデプロイしたShopに、非会員のアカウントで`cast send ... "order(uint256)" 1000`を送ると、ガス見積もりの段階で`Error: Failed to estimate gas: ... execution reverted: not a member`で止まる。`--gas-limit 200000`をつけて送ると、失敗したトランザクションがブロックに入る。ナンスとブロック番号は4から5に増え、`orders`は0のままである：

```
blockNumber          5
gasUsed              59275
logs                 []
status               0 (failed)
transactionHash      0x57ca2a8632ac82c9044a203844569a3cc452ba83f77b0aa315e70f392be80ec0
transactionIndex     0
revertReason         not a member, data: "0x08c379a0..."
```

同じトランザクションを`cast run`で再実行したトレース。関数名とイベントは解読されるが、コントラクトはアドレスで出る：

```
Traces:
  [38059] 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9::order(1000)
    ├─ [10217] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::pay(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1000)
    │   ├─ emit PayRequested(user: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, price: 1000)
    │   ├─ [2964] 0x5FbDB2315678afecb367f032d93F642f64180aa3::discount(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) [staticcall]
    │   │   └─ ← [Revert] not a member
    │   └─ ← [Revert] not a member
    └─ ← [Revert] not a member
```

会員登録（`join`）してからもう一度注文すると7番のブロックに成功として入り、ログの最初のトピックは`cast sig-event "PayRequested(address,uint256)"`と同じである：

```
status               1 (success)
logs                 [{"address":"0xe7f1725e...0512","topics":["0x92de15d3394683a7ac5944d4333cb9e38ff6904612a17cb3e45904723919b3e3"], ...}]

0x92de15d3394683a7ac5944d4333cb9e38ff6904612a17cb3e45904723919b3e3
```

`forge test --offline --match-test test_GuestPays --debug --dump dump.json`が書いたファイルの`debug_arena`を呼び出しの欄ごとに数えると、ステップ数は次のとおりである（合計1,259）：

```
0 CALL ShopTest test_GuestPays() steps 152
1 CALL ShopTest test_GuestPays() steps 133
2 CALL Shop order(uint256) steps 308
3 CALL Payment pay(address,uint256) steps 382
4 STATICCALL Membership discount(address) steps 248
5 CALL Payment pay(address,uint256) steps 12
6 CALL Shop order(uint256) steps 12
7 CALL ShopTest test_GuestPays() steps 12
```

Membershipの`discount`呼び出しの中のSLOADからREVERTまで（ステップ番号は0から、スタックは実行前のいちばん上の値）：

| ステップ | PC | opcode | 実行前のスタックのいちばん上 |
|---|---|---|---|
| 152 | 342 | KECCAK256 | 0x0, 0x40 |
| 153 | 343 | SLOAD | 0x9ee87815…f41c298c |
| 154 | 344 | GT | 0x0, 0x0 |
| 156 | 348 | JUMPI | 0x197, 0x0 |
| 157 | 349 | PUSH1 0x40 | 0x0, 0xa11ce |
| 159 | 352 | PUSH32 0x08c379a0… | 0x80, 0x0 |
| 247 | 406 | REVERT | 0x80, 0x64 |

SLOADが読んだ欄`0x9ee87815…f41c298c`は`cast index address 0x...0A11cE 0`（aliceの等級の欄）と同じで、読んだ値は0である。ステップごとのガスは、PUSH1・GT・SWAP1が3、JUMPIが10、KECCAK256が42、SLOAD（その欄の初回の読み取り）が2100だった。SLOAD前後の残りガスは1024127886 → 1024125786である。

### 試すときの注意

- `--debug`に`--dump <ファイル>`をつけると、対話型の画面を出さずにファイルだけを書いて終わった。ファイルは`debug_arena`配列で、欄ごとにkind、address、calldata、returndata、stepsがある。stepごとにpc（10進数）、op（opcodeの番号）、stack（実行前、配列の末尾がいちばん上）、gas_remaining、gas_costがある。
- `--debug`の実行時に、"Detected artifacts built from source files that no longer exist"という警告が`foundry-pp/DeployHelper*.sol`のファイル名とともに出た。`forge clean`のあとでも出るが、結果には影響がなかった。
- テストの`new Membership()`は、1.8.3のトレースでは`VM::deployCode("src/Shop.sol:Membership")`と表示された。
- `console.log`の出力は基本の出力にはなく、`-vv`から`Logs:`の下に出る。
- 残りガスが大きいのは、forgeのテストのデフォルトのガスリミットのためである。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、出力と数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry forge、cast、anvil | 1.8.3 (commit cae51ad) | 2026-10-18 |
| solc | 0.8.30 | 2026-10-18 |
| forge-std | 1.17.0 | 2026-10-18 |
| トレースのガスの値 | test_GuestPays 69759、order 59275、pay 10217、discount 2964 | 2026-10-18 |
| 失敗したトランザクションのgasUsed | 59275 | 2026-10-18 |
| SLOADの初回の読み取りのガス | 2100 | 2026-10-18 |
| テストのデフォルトのガスリミットでの残りガス | 1024127886（SLOAD直前） | 2026-10-18 |
| ローカルチェーン | anvil、チェーンID 31337 | 2026-10-18 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ガスレポート、ガススナップショット | [第33講](../../part2/lecture33/) |
| イベントとエラーの宣言 | [第48講](../../part4/lecture48/) |
| 外部呼び出しの戻り値の確認と呼び出しオプション | [第83講](../../part5/lecture83/) |
| require、revert、assertの違い | [第90講](../../part5/lecture90/) |
| イベントの発行、トピックの構造、チェーンの外での利用 | [第105講](../../part6/lecture105/)、[第106講](../../part6/lecture106/)、[第107講](../../part6/lecture107/) |
| 0x08c379a0のエラーエンコーディングとカスタムエラー | [第108講](../../part6/lecture108/) |
| delegatecallのライブラリ | [第117講](../../part6/lecture117/) |
| バイトコードの位置とソースの行の対応 | [第132講](../../part8/lecture132/) |
| イベントのインデックス化 | [第238講](../../part18/lecture238/) |
| 実際の事件のトランザクションの調査手順 | [第242講](../../part18/lecture242/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
