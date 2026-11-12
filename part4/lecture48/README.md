# 第48講 modifier、イベント、エラー

第4部 言語の詳細 ① ファイルと型・第12章 コントラクトの構造

[← 第47講](../../part4/lecture47/) | [第4部 目次](../) | [第49講 →](../../part4/lecture49/)

## この講義の問い

関数の本体の外に書く三つは、それぞれ何をし、実行が巻き戻ったらそのうち何が残るのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトから、`src`、`test`、`script`のCounterのファイルを消して始める。テストと`Order.sol`の`console.log`にはforge-stdが必要である（`lib/forge-std`）。`src/Ballot.sol`は[第37講](../../part3/lecture37/)の公式ドキュメントのVotingの例の原文で、`src/mod/`、`src/ev/`のBallotの版は、この原文から機械的に変えて作ったものである（原文のコメントは維持、コントラクト名はファイル名と同じにした）。ローカルのanvilの既定のアカウント0が議長、1がアリス、2がキャロルである。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのlintをオフ |
| [code/src/Ballot.sol](code/src/Ballot.sol) | 公式ドキュメントのVotingの例の原文 |
| [code/src/mod/BallotMod.sol](code/src/mod/BallotMod.sol) | giveRightToVoteの議長のrequireを`modifier onlyChairperson()`に移した版 |
| [code/src/mod/Ballot3Inline.sol](code/src/mod/Ballot3Inline.sol) | 議長専用の関数addProposal、setChairpersonを加え、requireを関数ごとに手で書いた版 |
| [code/src/mod/Ballot3Mod.sol](code/src/mod/Ballot3Mod.sol) | 同じ三つの関数に`onlyChairperson`をつけた版 |
| [code/src/mod/Ballot3None.sol](code/src/mod/Ballot3None.sol) | Ballot3Inlineから二つの関数のrequireだけを外した版 |
| [code/src/mod/Order.sol](code/src/mod/Order.sol) | `_;`の前後の実行順を`console.log`で見るmodifier |
| [code/test/Order.t.sol](code/test/Order.t.sol) | Orderの`run()`を1回 |
| [code/src/ev/BallotEv.sol](code/src/ev/BallotEv.sol) | voteで`emit Voted(msg.sender, proposal);`を残す版 |
| [code/src/ev/BallotRec.sol](code/src/ev/BallotRec.sol) | 同じ記録をストレージの配列`history`に積む版 |
| [code/src/err/GateStr.sol](code/src/err/GateStr.sol) | 時刻の条件を`require(条件, "文字列")`でふるいにかける版 |
| [code/src/err/GateErr.sol](code/src/err/GateErr.sol) | 同じ条件をカスタムエラー`TooEarly(uint256)`と`revert`でふるいにかける版 |
| [code/src/err/GateReq.sol](code/src/err/GateReq.sol) | 同じ条件を`require(条件, TooEarly(openAt))`でふるいにかける版 |
| [code/src/err/Caller.sol](code/src/err/Caller.sol) | GateErrをふつうの呼び出しと低水準の`call`で呼ぶコントラクト |
| [code/src/top/BallotDecls.sol](code/src/top/BallotDecls.sol) | ファイルレベルのイベントVotedとエラーNotChairperson |
| [code/src/top/BallotAll.sol](code/src/top/BallotAll.sol) | modifier、イベント、エラーをすべてつけた小さなBallot |

### 実行結果

`forge build --sizes`（Runtime Size、Initcode Sizeの列のみ）：

```
| Ballot        | 4,059 | 4,945 |
| Ballot3Inline | 4,656 | 5,542 |
| Ballot3Mod    | 4,656 | 5,542 |
| Ballot3None   | 4,372 | 5,258 |
| BallotMod     | 4,059 | 4,945 |
```

二つの版の`deployedBytecode`から最後の106文字（メタデータ53バイト）を除いた前の部分を比べると同じである。modifierは関数ごとに本体を差し込むものなので、手で書いた版とバイトコードが同じになる：

```
Ballot        BallotMod      4059 4059  full False  noMeta True
Ballot3Inline Ballot3Mod     4656 4656  full False  noMeta True
```

modifierの実行順（`forge test --match-contract OrderTest -vv`）：

```
[PASS] test_Run() (gas: 55294)
Logs:
  modifier: before _
  body
  modifier: after _
```

同じ`run()`をanvilに`cast send`で送ると、gasUsed 48,526で`logs []`である。`console.log`はチェーンに何も残さない。

BallotEvでのアリスの`vote(1)`のレシート。最初のトピックはイベントのシグネチャのkeccak256（`cast keccak "Voted(address,uint256)"`）、二つ目のトピックはindexedであるvoter、dataはproposalである：

```
logs     [{"address":"0x9fe4...a6e0",
           "topics":["0x4d99b957a2bc29a30ebd96a7be8e68fe50a3c701db28a91436490b7d53870ca4",
                     "0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8"],
           "data":"0x0000000000000000000000000000000000000000000000000000000000000001",
           "blockNumber":"0x6", ...}]
status   1 (success)
```

`vote(1)`のgasUsedは、Ballotが92,896、BallotEvが94,467、BallotRecが159,491である。

キャロルの`vote(5)`（存在しない議案）。そのまま送るとガスの見積もりで`panic: array out-of-bounds access (0x32)`として止まり、`--gas-limit 200000`でブロックに入れると、失敗したトランザクションにはログが残らない。`cast run`で再実行するとemitの行が見えるが、巻き戻しとともに消える：

```
blockNumber          11
gasUsed              72116
logs                 []
status               0 (failed)

$ cast run 0x1385...647e
  [50912] 0x9fE4...a6e0::vote(5)
    ├─ emit Voted(voter: 0x3C44...93BC, proposal: 5)
    └─ ← [Revert] panic: array out-of-bounds access (0x32)

$ cast call $E "voters(address)(uint256,bool,address,uint256)" <キャロル>
1  false  0x0000000000000000000000000000000000000000  0
```

文字列のエラーとカスタムエラーの巻き戻しデータ（`cast call ... "open()"`）。Error(string)の版は100バイト、TooEarlyの版は36バイトである：

```
$ cast call $GS "open()"
Error: execution reverted: Too early to open.
data: "0x08c379a0
       0000000000000000000000000000000000000000000000000000000000000020
       0000000000000000000000000000000000000000000000000000000000000012
       546f6f206561726c7920746f206f70656e2e0000000000000000000000000000"

$ cast call $GE "open()"
Error: execution reverted: TooEarly(1792379368 [1.792e9])
data: "0x2a35a324
       000000000000000000000000000000000000000000000000000000006ad589e8"

$ cast sig "Error(string)"        0x08c379a0
$ cast sig "TooEarly(uint256)"    0x2a35a324
```

GateReqの`cast call`の出力は、GateErrと一文字も違わない。

Callerからのふつうの呼び出しでは、エラーがそのまま上がってきて全体が巻き戻される：

```
$ cast send $K "callNormal(address)" $GE
Error: Failed to estimate gas: ... execution reverted: custom error 0x2a35a324: ...
TooEarly(1792379368 [1.792e9])
```

低水準の`call`には、ビルドのときに戻り値を使っていないという警告がつき、実行すると相手が巻き戻されても呼び出した側は成功で終わる：

```
Warning (9302): Return value of low-level calls not used.
  --> src/err/Caller.sol:15:9:
   |
15 |         gate.call(abi.encodeWithSignature("open()"));
   |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

$ cast send $K "callLow(address)" $GE
status               1 (success)

$ cast run 0xe14c...ca4
  [28506] 0xA51c...91C0::callLow(0x6101...D788)
    ├─ [2572] 0x6101...D788::open()
    │   └─ ← [Revert] TooEarly(1792379368 [1.792e9])
    └─ ← [Stop]

$ cast call $K "reached()(uint256)"     1
$ cast call $GE "opened()(uint256)"     0
```

BallotAll（`--constructor-args 2`でデプロイ）。アリスが`giveRightToVote`を呼ぶと`custom error 0x79f43844: ... NotChairperson(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)`で止められ、議長が権限を与えたあとのアリスの`vote(0)`は成功して、topics[0]が0x4d99...0ca4であるログを一つ残す。`forge inspect BallotAll abi`にはevent Voted(address,uint256)とerror NotChairperson(address)が一緒に書かれ、ファイルレベルのイベントにつけたNatSpecはuserdocに入る：

```
$ forge inspect --offline BallotAll userdoc
"events": {
  "Voted(address,uint256)": {
    "notice": "投票が一回終わると記録"
  }
}
```

### 試すときの注意

- 巻き戻される呼び出しは、`cast send`のガス見積もりの段階で止まる。失敗したトランザクションをブロックに入れてレシートを見るには、`--gas-limit`を指定する。
- GateErrの開く時刻は、デプロイするときのブロックの時刻 + 3600秒で入れた（`cast block latest -f timestamp`）。再実行すると値が変わる。
- 上のアドレスは、新しく立ち上げたanvilでBallot、BallotEv、BallotRec、Orderの順にデプロイしたときの値である（Ballot 0x5FbDB2315678afecb367f032d93F642f64180aa3、BallotEv 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0、BallotRec 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9、Order 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853）。

## 時効性のあるデータ

基準日時点の値。ツールとコンパイラのバージョンが変わると違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| ドキュメントのバージョン | Solidity v0.8.36（Structure of a Contract、Contracts、Control Structures） | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値）、既定のパイプライン（via-IRはオフ） | 2026-10-19 |
| Foundryのバージョン | forge・cast・anvil 1.8.3 (cae51ad) | 2026-10-19 |
| Ballotの五つの版のランタイムのサイズ | Ballot 4,059 / BallotMod 4,059 / Ballot3None 4,372 / Ballot3Mod 4,656 / Ballot3Inline 4,656（バイト） | 2026-10-19 |
| イベントの版のランタイムのサイズ | BallotEv 4,137 / BallotRec 4,400（バイト） | 2026-10-19 |
| vote(1)のgasUsed | Ballot 92,896 / BallotEv 94,467 / BallotRec 159,491 | 2026-10-19 |
| 失敗したvote(5) | 11番ブロック、status 0、gasUsed 72,116、logs [] | 2026-10-19 |
| Order.run() | gasUsed 48,526、logs [] / forge testのgas 55,294 | 2026-10-19 |
| Gateの三つの版のランタイムのサイズ | GateStr 560 / GateErr 443 / GateReq 445 / Caller 1,077（バイト） | 2026-10-19 |
| 巻き戻しデータの長さ | Error(string)の版100バイト / TooEarlyの版36バイト | 2026-10-19 |
| カスタムエラーが導入されたバージョン | 0.8.4（`error`キーワードと`revert`文の導入） | 2026-10-19 |
| ファイルレベルのイベントを受け付けるバージョン | 0.8.22（ファイルレベルのエラーは0.8.4から） | 2026-10-19 |
| require(条件, カスタムエラー) | 0.8.26からvia-IRパイプラインでのみ、0.8.27から既定（レガシー）パイプラインでも。0.8.30の既定パイプラインでコンパイル・動作する | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| modifierを複数つけたときの順番、引数を受け取るmodifier、継承と再定義 | [第103講](../../part6/lecture103/)、[第104講](../../part6/lecture104/) |
| イベントのindexedのルール、topicの個数の上限、anonymousイベント、ログデータのエンコード | [第105講](../../part6/lecture105/)、[第106講](../../part6/lecture106/)、[第107講](../../part6/lecture107/) |
| カスタムエラーの設計、巻き戻しデータのサイズとガスの比較の詳細 | [第108講](../../part6/lecture108/)、[第109講](../../part6/lecture109/) |
| try/catchの文法と失敗データの受け取り方 | [第90講](../../part5/lecture90/)、[第91講](../../part5/lecture91/) |
| 外部呼び出しの結果の処理 | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| 状態変数の可視性とゲッター | [第95講](../../part6/lecture95/)、[第96講](../../part6/lecture96/)、[第97講](../../part6/lecture97/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
