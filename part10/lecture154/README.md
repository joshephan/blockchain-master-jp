# 第154講 標準の存在理由とコンポーザビリティ

第10部 標準とアップグレード・第41章 標準の設計思想

[← 第153講](../../part9/lecture153/) | [第10部 目次](../) | [第155講 →](../../part10/lecture155/)

## この講義の問い

出会ったことのない二つのコントラクトがお互いを呼べるようにするのは何か。その約束を守っているかは誰が確かめるのか。

## 実習資料

### 準備

プロジェクトは三つある。`demo`は、自分で書いたトークンStdToken、OpenZeppelinのERC20を継承しただけのOzToken、帳簿なしでTransferイベントだけを出力するFakeEmitterを、第152講のバージョンのMarket（`src/market/`、コピー）とかみ合わせてみるデモ用プロジェクトである。`eipsrc`は、EIP-721の原文のインターフェースのかたまりをそのまま切り出してsolc 0.8.30に入れてみるファイル二つである。`market`は通しプロジェクトMarketの第154講のバージョンである。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0（`demo`のOzToken・Composeのテスト）である。`demo/foundry.toml`は依存関係を`demo/lib/`の下（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osaka、`market`はvia-IR・optimizerオン（runs 200）・evm osakaである。ログと同じ名前のトークンのデプロイは、ローカルのanvilで既定のテスト用アカウントから送った。

### コード

| ファイル | 内容 |
|---|---|
| [code/eipsrc/erc721_iface.sol](code/eipsrc/erc721_iface.sol) | EIP-721の原文44〜152行（インターフェースのかたまり）をそのまま切り出したファイル、`pragma solidity ^0.4.20;` |
| [code/eipsrc/erc721_08.sol](code/eipsrc/erc721_08.sol) | 上のファイルから最初の行だけを`^0.8.0`に変えたもの |
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/StdToken.sol](code/demo/src/StdToken.sol) | EIP-20の名前どおりに自分で書いたトークン（48行、理由の文字列二つ） |
| [code/demo/src/OzToken.sol](code/demo/src/OzToken.sol) | OpenZeppelin 5.4.0のERC20を継承しただけのトークン（11行） |
| [code/demo/src/FakeEmitter.sol](code/demo/src/FakeEmitter.sol) | 残高の帳簿なしでTransferイベントだけを出力するコントラクト |
| [code/demo/src/market/](code/demo/src/market/) | 第152講のバージョンのMarketのsrcの五つのファイルのコピー |
| [code/demo/test/Compose.t.sol](code/demo/test/Compose.t.sol) | 二つのトークンとMarketのかみ合わせ、承認なしのdeposit、MockToken、インターフェースIDのテスト六つ |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第154講のバージョンのsrcの五つのファイル。コードは第152講のバージョンと同じで、コメント2行（第111講の古いコメントの修正、第154講のバージョン説明の行）だけが違う |
| [code/market/test/StdToken.sol](code/market/test/StdToken.sol) | 第154講で足したテスト用の標準トークン（承認なしではtransferFromが巻き戻る） |
| [code/market/test/Standard.t.sol](code/market/test/Standard.t.sol) | 第154講で足したStandardTestの四つ（かみ合わせ、承認なしのdeposit、MockToken、インターフェースID） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

EIP-721の原文のインターフェースをそのまま`solc --error-codes erc721_iface.sol`に入れた結果（終了コード1）：

```
Error (5333): Source file requires different compiler version (current compiler is 0.8.30+commit.73712a01.Windows.msvc) - note that nightly builds are considered to be strictly less than the released version
 --> erc721_iface.sol:1:1:
  |
1 | pragma solidity ^0.4.20;
  | ^^^^^^^^^^^^^^^^^^^^^^^^
```

pragmaだけを変えた`erc721_08.sol`（SPDXの警告1878の行は省略、終了コード1）：

```
Error (6651): Data location must be "memory" or "calldata" for parameter in external function, but none was given.
  --> erc721_08.sol:50:77:
   |
50 |     function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
   |                                                                             ^^^^^^^^^^
```

EIP-20の関数九つとイベント二つのセレクタ（`cast sig`、`cast sig-event`）：

| 名前 | 必須かどうか | セレクタ / topic0 |
|---|---|---|
| name() · symbol() · decimals() | OPTIONAL | `0x06fdde03` · `0x95d89b41` · `0x313ce567` |
| totalSupply() · balanceOf(address) | 必須 | `0x18160ddd` · `0x70a08231` |
| transfer(address,uint256) · transferFrom(address,address,uint256) | 必須 | `0xa9059cbb` · `0x23b872dd` |
| approve(address,uint256) · allowance(address,address) | 必須 | `0x095ea7b3` · `0xdd62ed3e` |
| Transfer(address,address,uint256) | イベント | `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef` |
| Approval(address,address,uint256) | イベント | `0x8c5be1e5…200ac8c7c3b925` |

`demo`で`forge test --offline -vv`。alice 1000 → approve(Market, 100) → deposit 100 → withdraw 30を二つのトークンに同じように実行した結果である（残りのPASSの4行は省略）：

```
[PASS] test_oz() (gas: 431947)
Logs:
  deposited 70
  market balance 70
  allowance left 0

[PASS] test_std() (gas: 433300)
Logs:
  deposited 70
  market balance 70
  allowance left 0
Ran 1 test suite …: 6 tests passed, 0 failed, 0 skipped (6 total tests)
```

インターフェースID（test_interfaceIds）：MarketのIERC20（関数三つ）`0xfa1d6c57`、EIP-20の必須の六つを書いたインターフェース`0x36372b07`、OpenZeppelinの`IERC20` `0x36372b07`。`forge inspect … methodIdentifiers`で見たStdTokenとOzTokenのセレクタ九つはすべて同じである。

MockTokenは承認なしで移す（test_mockMovesWithoutApproval、bobがaliceの500をtransferFrom）：

```
[PASS] test_mockMovesWithoutApproval() (gas: 122130)
```

ローカルのanvilで、同じStdTokenのコードを別のアカウントが同じ名前でデプロイした結果：

```
StdToken 0x5FbDB2315678afecb367f032d93F642f64180aa3   (アカウント0番)
name "Std Token"  symbol "STD"
copycat  0x261D8c5e9742e6f7f1076Fa1F560894524e19cad   (アカウント3番)
name "Std Token"  symbol "STD"  totalSupply 1000000
```

FakeEmitterの`fire(アカウント2番, アカウント1番, 1000000)`は成功し、ない`balanceOf`を`cast call`で呼ぶと巻き戻る：

```
fake fire (1, 24720)
fake balanceOf? Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

`cast logs --from-block 0 0xddf252ad…523b3ef`（topic0一つ）で集めたログ5行：

| ブロック | アドレス | data |
|---|---|---|
| 1 | StdToken `0x5FbD…0aa3` | `0x…03e8`（作成時の1000） |
| 2 | OzToken `0xe7f1…0512` | `0x…03e8`（作成時の1000） |
| 4 | StdToken | `0x…000a`（transfer 10） |
| 5 | OzToken | `0x…000a`（transfer 10） |
| 6 | FakeEmitter `0x9fE4…a6e0` | `0x…0f4240`（1,000,000） |

`--address`でStdTokenだけに絞ると2行が残る（blockHash・topics・transactionHashの行は省略）：

```
$ cast logs --from-block 0 --address 0x5FbDB2315678afecb367f032d93F642f64180aa3 0xddf252ad…523b3ef
- address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  blockNumber: 1
  data: 0x00000000000000000000000000000000000000000000000000000000000003e8
- address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  blockNumber: 4
  data: 0x000000000000000000000000000000000000000000000000000000000000000a
```

`market`で`forge test --offline --match-contract StandardTest -vvvv`の、承認なしのdepositのトレース（`← [Return]`の2行は省略）。巻き戻しを出したのはStdTokenで、Marketはそのまま上に返す：

```
[PASS] test_noApproveBubbles() (gas: 111918)
Traces:
  [111918] StandardTest::test_noApproveBubbles()
    ├─ [0] VM::prank(0x00000000000000000000000000000000000A11cE)
    ├─ [0] VM::expectRevert(insufficient allowance)
    ├─ [98409] Market::deposit(StdToken: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100)
    │   ├─ [2722] StdToken::transferFrom(0x00000000000000000000000000000000000A11cE, Market: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 100)
    │   │   └─ ← [Revert] insufficient allowance
    │   └─ ← [Revert] insufficient allowance
    └─ ← [Return]
```

同じ失敗をOzTokenで起こしたtest_ozNoApproveのログ。`0xfb8f41b2`は`ERC20InsufficientAllowance(address,uint256,uint256)`で、引数はMarketのアドレス、現在の承認0、必要な量100（0x64）である：

```
[PASS] test_ozNoApprove() (gas: 260195)
Logs:
  0xfb8f41b20000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064
```

`market`で`forge test --offline --match-contract StandardTest`：

```
Ran 4 tests for test/Standard.t.sol:StandardTest
[PASS] test_interfaceIds() (gas: 448)
[PASS] test_mockTokenMovesWithoutApproval() (gas: 107642)
[PASS] test_noApproveBubbles() (gas: 111918)
[PASS] test_stdTokenRoundTrip() (gas: 270047)
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

Market第154講のバージョンの全体の点検（サイズの行と三つのプロファイルのテスト、テストは75個から79個に）：

```
| Market        | 3,260            | 3,473             | 21,316             | 45,679              |
Ran 26 test suites …: 79 tests passed, 0 failed, 0 skipped (79 total tests)
Ran 26 test suites …: 79 tests passed, 0 failed, 0 skipped (79 total tests)
Ran 26 test suites …: 79 tests passed, 0 failed, 0 skipped (79 total tests)
ci ok
```

Market第154講のバージョンに照らした標準の対照表の最初の行：

| 標準 | Marketが立つ側 | Marketにあるもの | Marketにないもの | 確認するテスト |
|---|---|---|---|---|
| ERC-20 | 呼ぶ側（資産のトークン） | IERC20の三つ：balanceOf・transferFrom・transfer（ID 0xfa1d6c57、標準の必須の六つは0x36372b07） | totalSupply・approve・allowance・イベント二つは呼びも読みもしない。Market自身はトークンではない | test/Standard.t.sol |

### 試すときの注意

- EIPの文書のコードブロックは、当時の文法（Solidity 0.4.x）で書いた形の説明である。そのまま切り出してコンパイルするとpragmaで、pragmaを直すと`bytes data`のデータの場所で引っかかる。
- 同じ名前と引数の型ならセレクタが同じなので、StdToken・OzToken・MarketのIERC20は、お互いのコードを知らなくてもかみ合う。Marketが呼ぶのは九つのうちbalanceOf・transferFrom・transferの三つである。
- MarketのテストのMockTokenは承認なしで移すテスト用のトークンで、標準ではない。標準のトークンに変えなかったのは、預け入れるテストのたびにapproveの行が付き、第25章から測ってきたdepositのガスの記録が途切れるからである。標準のトークンとのかみ合わせは`test/StdToken.sol`で別に確認する。
- `RebuildTest:test_recordedLogsIncludeReverted`のガスは、第152講のバージョンが155,232、第154講のバージョンが155,244である。テストの中でデプロイするThrowerのメタデータには`src/Market.sol`が入っていて、バージョン説明のコメントを直すとThrowerの末尾のハッシュが変わり、ハッシュの中の00のバイトの数が変わるとガスが12ずれる。`PullTest:test_refusedWithdrawStaysWithCaller`も同じ理由で、第152講のバージョンの780,522から第154講のバージョンの780,510へ12変わる。第152講のバージョンからある75行のうち、残りの73行は同じである。
- copycatのデプロイのガス934,525は、StdTokenの934,513と12違う。コードは同じで、供給量の引数だけが違う。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30（`0.8.30+commit.73712a01.Windows.msvc`）。デモ用プロジェクトはoptimizerオフ・evm osaka。Market第154講のバージョンはdefaultがvia-IR + optimizerオン runs 200・evm osaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| EIPの原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`：`erc-20.md` 193行（最終更新2023-12-13）、`erc-721.md` 447行（2025-05-13）。ethereum/EIPsのコミット`0ce679f4654ba4d120c97113626f320475e22fa9`：`eip-1.md` 621行（status Living） | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（package.json）、MIT | 2026-10-20 |
| デプロイのガス（デモ、ローカルのanvil） | StdToken 934,513、OzToken 941,801、FakeEmitter 160,955、copycat 934,525。transfer 10：StdToken 52,314、OzToken 52,117。fire 24,720 | 2026-10-20 |
| anvilのアドレス | StdToken `0x5FbDB2315678afecb367f032d93F642f64180aa3`、OzToken `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、FakeEmitter `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、copycat `0x261D8c5e9742e6f7f1076Fa1F560894524e19cad`。既定のテスト用アカウント、unlockedのアカウントで送る | 2026-10-20 |
| テストのガス（forge） | Compose：test_std 433,300、test_oz 431,947、test_stdNoApprove 258,139、test_ozNoApprove 260,195、test_mockMovesWithoutApproval 122,130、test_interfaceIds 9,332。StandardTest：448 / 107,642 / 111,918 / 270,047。RebuildTest:test_recordedLogsIncludeReverted 155,244（第152講のバージョンは155,232）、PullTest:test_refusedWithdrawStaysWithCaller 780,510（第152講のバージョンは780,522） | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第154講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ・ハッシュ・行番号 | 第154講のバージョンdefault 3,260 / 3,473（legacy 3,755 / 4,013、debug 7,353 / 7,931）、末尾のハッシュの先頭4バイト`a517d853`、`.gas-snapshot` 79行。debugの行番号deposit 0 166:33、NotActive 81、`contract Market` 210。バージョン説明のコメントが変わると変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| approveの上書きの競合と承認の流れ、巻き戻しのバイトを読む | [第155講](../../part10/lecture155/) |
| 標準に従うと言いながら違う動きをするトークン（戻り値なし、移すときに引かれる手数料、勝手に変わる残高） | [第171講](../../part11/lecture171/) |
| キャップストーンで標準の実装を選んで取り込むこと | [第256講](../../part20/lecture256/) |
| イベントでトークンの帳簿を組み立て直すインデクサー | [第238講](../../part18/lecture238/) |
| 名前と記号が同じトークンを見分けること（チェーンの外） | [第181講](../../part11/lecture181/) |
| インターフェースIDで相手に対応の有無を尋ねる標準 | [第159講](../../part10/lecture159/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
