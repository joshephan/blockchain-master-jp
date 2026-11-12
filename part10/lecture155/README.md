# 第155講 ERC-20とapproveの構造的欠陥

第10部 標準とアップグレード・第41章 標準の設計思想

[← 第154講](../../part10/lecture154/) | [第10部 目次](../) | [第156講 →](../../part10/lecture156/)

## この講義の問い

他人に自分のトークンを動かしていくことを許すapproveはどんな形をしていて、その形のせいでどこから漏れるのか。

## 実習資料

### 準備

プロジェクトは二つある。`demo`は、第154講のStdToken・OzTokenに、承認を受け取るコントラクトの二つの形（Puller、SelfPuller）と、第41講の文書の例Tokenのapproveの行を生かしたDocTokenを足したデモ用プロジェクトである。`market`は通しプロジェクトMarketの第155講のバージョンである。承認なしのdepositの巻き戻し二つは、[第154講のcode/demo](../lecture154/code/demo/)のComposeのテストで取り直した。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0である。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。同じブロックの競合は、ローカルのanvil（1.8.3、既定の`--order fees`）で自動採掘を切り、トランザクション二つを入れてから`evm_mine`でブロックを一つ作って再現した。アカウントはanvilの既定のテスト用アカウントをunlockedで使った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/StdToken.sol](code/demo/src/StdToken.sol) | EIP-20の名前どおりに自分で書いたトークン（第154講と同じ） |
| [code/demo/src/OzToken.sol](code/demo/src/OzToken.sol) | OpenZeppelin 5.4.0のERC20を継承しただけのトークン |
| [code/demo/src/Puller.sol](code/demo/src/Puller.sol) | fromを引数で受け取るPullerと、呼んだ人自身のものだけを移すSelfPuller |
| [code/demo/src/DocToken.sol](code/demo/src/DocToken.sol) | 第41講の文書のTokenのapproveの行（上限が0でなければ巻き戻す）をそのまま使い、移す行は展開して書き、最初の発行量のコンストラクタを足したトークン |
| [code/demo/test/Approve.t.sol](code/demo/test/Approve.t.sol) | 上書きの競合、先に0、無限承認、Approvalのログ、Puller・SelfPuller、0の移動、decimalsのテスト九つ |
| [code/demo/test/DocApprove.t.sol](code/demo/test/DocApprove.t.sol) | DocTokenで上限をすぐ変えると巻き戻る、それでも150が出ていく競合 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第155講のバージョンのsrcの五つのファイル。コードは第154講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/Allowance.t.sol](code/market/test/Allowance.t.sol) | 第155講で足したAllowanceTestの二つ（呼んだアカウントの承認だけが使われる、残った承認はそのまま） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

同じブロックに入れたトランザクション二つ。その前に、aliceの残高1000、approve(bob, 100)まで採掘しておいた（StdTokenのデプロイ934,513）：

| 送ったアカウント | 呼び出し | 最大手数料 / チップ | 4番のブロックの中の順番 | 結果 |
|---|---|---|---|---|
| alice（アカウント1番） | approve(bob, 50) | 3 gwei / 1 gwei | 1 | 成功、gasUsed 46,638 |
| bob（アカウント2番） | transferFrom(alice, bob, 100) | 20 gwei / 10 gwei | 0 | 成功、gasUsed 53,776 |

4番のブロックのあとでaliceが読んだ承認は50で、bobがその50をさらに持っていく。aliceの意図は50までだったが、出ていった量は150である：

```
allowance after block 50
bob transferFrom 50 (1, 36676)
bob balance 150
alice balance 850
allowance end 0
```

alice → bobのTransferのログ（`cast logs --from-block 0 --address <StdToken> <Transferのtopic0> <aliceを32バイトに>`、topics・blockHashの行は省略）。4番のブロックに100（0x64）、5番のブロックに50（0x32）が記録された：

```
blockNumber: 4
data: 0x…0064
transactionIndex: 0
blockNumber: 5
data: 0x…0032
transactionIndex: 0
```

`demo`で`forge test --offline --match-test test_zeroFirstLooksSame -vv`。承認を使ったかどうかにかかわらず、0に変えたあとのallowanceは同じく0である：

```
[PASS] test_zeroFirstLooksSame() (gas: 330209)
```

DocToken（第41講の文書のTokenのapproveの行）をanvilにデプロイして実行した結果：上限100が残ったままのapprove(bob, 50)はstatus 0である。bobが先にtransferFrom 100 → 上限0 → aliceがapprove(bob, 50) status 1 → bobがtransferFrom 50の順に進むと、最後はbob 150、alice 850である。

無限承認とApprovalのログ（`forge test --offline --match-test "test_ozMaxAllowance|test_ozSpendNoApprovalEvent|test_stdSpendEvents" -vv`）：

- test_ozMaxAllowance：承認`type(uint256).max`、bobがtransferFrom 300をしたあともallowanceは最大値のまま、ログ1個（Transfer）。`(gas: 180160)`
- test_ozSpendNoApprovalEvent：承認500、transferFrom 300のあとallowance 200、ログ1個（topic0 `0xddf252ad…b3ef`、Transfer）
- test_stdSpendEvents：StdTokenもtransferFromでログ1個（Transfer）

| トークン | approve | transferFrom |
|---|---|---|
| StdToken | Approval 1 | Transfer 1 |
| OpenZeppelin 5.4.0 | Approval 1 | Transfer 1 |

PullerとSelfPuller（`forge test --offline --match-test "test_pullerTakesOthers|test_selfPullerOnlyCaller" -vvvv`）：

| テスト | aliceの承認 | 呼んだアカウント | 結果 |
|---|---|---|---|
| test_pullerTakesOthers | Pullerに100 | bob、pull(alice) | aliceの100 → bob |
| test_selfPullerOnlyCaller | SelfPullerに100 | bob、pullMine | `insufficient allowance`、aliceの承認100はそのまま |

承認なしでdeposit 100を呼んだときの、トークンごとに違う巻き戻し（第154講のComposeのテスト）。StdTokenは理由の文字列、OpenZeppelinは`ERC20InsufficientAllowance(address,uint256,uint256)`のセレクタ`0xfb8f41b2`と引数三つ96バイト（spender = Market、残りの承認0、必要な量100）である。ブロックの中の「StdToken（Market::depositの下）」「OpenZeppelin（test_ozNoApproveの巻き戻しデータ）」の2行は、どの出力かを示すために付けた見出しである：

```
StdToken（Market::depositの下）
│   │   └─ ← [Revert] insufficient allowance
│   └─ ← [Revert] insufficient allowance

OpenZeppelin（test_ozNoApproveの巻き戻しデータ）
0xfb8f41b2
  0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f
  0000000000000000000000000000000000000000000000000000000000000000
  0000000000000000000000000000000000000000000000000000000000000064
```

桁数（`forge test --offline --match-test test_decimals -vv`）。同じ1個が、decimals 6と18とでは10の12乗倍違う数である：

```
[PASS] test_decimals() (gas: 33247)
Logs:
  6 1000000
  18 1000000000000000000
```

test_zeroTransferEmits：StdToken・OpenZeppelinどちらもtransfer(bob, 0)でTransferのログを出す（ログ2）。

`market`で`forge test --offline --match-contract AllowanceTest -vvvv`。上はbobが呼んだdeposit（test_onlyCallerAllowanceUsed）、下はtest_leftoverAllowanceStaysの最後である。Marketがトークンに送ったfromは呼んだアカウントのbobで、withdrawAllのあとの預けた量は0、残った承認は70である：

```
├─ [98409] Market::deposit(StdToken: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100)
│   ├─ [2722] StdToken::transferFrom(0x0000000000000000000000000000000000000B0b, Market: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 100)
│   │   └─ ← [Revert] insufficient allowance
│   └─ ← [Revert] insufficient allowance
├─ [2738] StdToken::allowance(0x00000000000000000000000000000000000A11cE, Market: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]) [staticcall]
│   └─ ← [Return] 100
├─ [2508] StdToken::balanceOf(0x00000000000000000000000000000000000A11cE) [staticcall]
│   └─ ← [Return] 500
```

```
├─ [2738] StdToken::allowance(0x00000000000000000000000000000000000A11cE, Market: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]) [staticcall]
│   └─ ← [Return] 70
├─ [6970] Market::positions(StdToken: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0x00000000000000000000000000000000000A11cE) [staticcall]
│   └─ ← [Return] 0, 0, 1, false
```

Market第155講のバージョンの点検：`forge build --offline --sizes`でMarket 3,260 / 3,473、`forge test --offline`と`FOUNDRY_PROFILE=debug`・`legacy`はいずれも81個が通過、`.gas-snapshot` 81行、`bash ci.sh`は`ci ok`。

Market第155講のバージョンの標準の対照表に足した行：

| 標準 | Marketが立つ側 | Marketにあるもの | Marketにないもの | 確認するテスト |
|---|---|---|---|---|
| ERC-20の承認 | 承認を受け取る側 | depositのtransferFrom(msg.sender, Market, amount)の一か所、返ってきたboolの確認 | fromを引数で受け取る関数なし、approve・permitは呼ばない | test/Allowance.t.sol、test/ErrorList.t.sol（FalseToken） |

### 試すときの注意

- anvil 1.8.3の既定の`--order fees`では、最大手数料の高いトランザクションが同じブロックの前に入る。二つのトランザクションの最大手数料とチップを同じ（20 gwei・10 gwei）にすると入ってきた順に入り、aliceのapproveが0番で先に実行され、bobのtransferFrom 100は1番でstatus 0となって失敗する。そのあとbobは50だけを持っていく。
- 同じブロックの再現は、自動採掘を切り（`evm_setAutomine false`）、二つのトランザクションを`--async`で入れてから`evm_mine`でブロックを一つ作る。ブロックの中の位置は`cast receipt`の`transactionIndex`で見る。
- OpenZeppelin 5.4.0のERC20.solにはincreaseAllowance・decreaseAllowanceがない。似た仕事はSafeERC20ライブラリのsafeIncreaseAllowance・safeDecreaseAllowance・forceApproveがする。
- OpenZeppelinのERC20のtransferFromは、承認を減らしてもApprovalイベントを出さない（ERC20.solの256〜260行のコメント）。残った承認はログではなく`allowance()`の呼び出しで読む。
- Marketはdecimalsを呼ばない。金額の型Amountの中の数は、トークンごとに違う倍率のままである。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| EIPの原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`。`ERCS/erc-20.md`（193行、最終更新2023-12-13）34・65・67〜68・100・112・114・126・128〜130・139・164行、`ERCS/erc-721.md`（447行、最終更新2025-05-13）295行 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（MIT、package.jsonのversion）。`token/ERC20/ERC20.sol` 120 approve、142〜147 transferFrom、176〜204 `_update`（203 `emit Transfer`）、256〜260 コメント、294〜304 `_spendAllowance`。ERC20.solにincreaseAllowance・decreaseAllowanceなし、`utils/SafeERC20.sol` 68 safeIncreaseAllowance・82 safeDecreaseAllowance・101 forceApprove | 2026-10-20 |
| solc・Foundry | solc 0.8.30、forge・cast・anvil 1.8.3。デモ用プロジェクトはoptimizerオフ（Foundryの既定値）・evm osaka | 2026-10-20 |
| anvilの順番の規則 | `--order fees`（anvil 1.8.3の既定）：最大手数料が違えば高い方が先。両方20 gwei・チップ10 gweiで同じにすると入ってきた順（aliceのapproveが0番でstatus 1・29,538、bobのtransferFromが1番でstatus 0・25,410、ブロックのあとのallowance 50、bobはその次に50だけを持っていく） | 2026-10-20 |
| 競合のデモの値 | StdToken 0x5FbDB2315678afecb367f032d93F642f64180aa3 デプロイ934,513、aliceへ1000 47,526、approve(bob, 100) 46,638。ブロック4：bobのtransferFrom 100 0番 status 1・53,776（最大20 gwei・チップ10 gwei）、aliceのapprove(bob, 50) 1番 status 1・46,638（最大3 gwei・チップ1 gwei）。ブロックのあとのallowance 50、bobのtransferFrom 50 status 1・36,676、bob 150・alice 850・allowance 0。Transfer alice → bob ブロック4 0x64・ブロック5 0x32 | 2026-10-20 |
| デモのテストのガス（optimizerオフ） | test_decimals 33,247、test_overwriteRace 251,501、test_ozMaxAllowance 180,160、test_ozSpendNoApprovalEvent 189,788、test_pullerTakesOthers 170,255、test_selfPullerOnlyCaller 164,557、test_stdSpendEvents 173,466、test_zeroFirstLooksSame 330,209、test_zeroTransferEmits 79,522 | 2026-10-20 |
| 文書のTokenのapproveの行 | DocToken 0x5FbD…0aa3 デプロイ539,540、aliceへ1000 45,552、approve(bob, 100) 44,841、上限100が残ったままのapprove(bob, 50) status 0・24,717（ガス上限100,000で送る）、bobのtransferFrom 100 51,756、approve(bob, 50) status 1・44,841、bobのtransferFrom 50 34,656、bob 150・alice 850 | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第155講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| Allowanceのテストのガス | test_leftoverAllowanceStays 253,121、test_onlyCallerAllowanceUsed 172,482 | 2026-10-20 |
| サイズ | 第155講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第155講のバージョンdefault `a1c443a4` | 2026-10-20 |
| 行番号 | 第155講のバージョンdebugのdeposit 0 src/Market.sol 167:33、NotActiveの行82、`contract Market` 211行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`、aliceはアカウント1番`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`、bobはアカウント2番`0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`（anvilの既定のテスト用アカウント、unlockedのアカウントで送る） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ブロックの順番を選ぶ側が承認の上書きのすきを使うこと | [第172講](../../part11/lecture172/)、[第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/) |
| 戻り値のないトークンとSafeERC20 | [第171講](../../part11/lecture171/) |
| 承認なしで署名で預ける形（permit、EIP-2612）と、承認の範囲を狭めるウォレットの設計 | [第222講](../../part15/lecture222/)、[第223講](../../part15/lecture223/) |
| 他人が移せるように書いた関数（fromを引数で受け取る関数）を監査で探すこと | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/) |
| Approvalのログなしで残った承認をチェーンの外で追跡すること | [第238講](../../part18/lecture238/) |
| トークンごとに違うdecimalsを金額の計算に入れること | [第197講](../../part13/lecture197/)、[第204講](../../part14/lecture204/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
