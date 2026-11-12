# 第211講 統合するときの信頼の前提のドキュメント化

第14部 オラクル・クロスチェーン・ガバナンス・第57章 クロスチェーン

[← 第210講](../../part14/lecture210/) | [第14部 目次](../) | [第212講 →](../../part14/lecture212/)

## この講義の問い

自分のプロトコルがほかのチェーンから渡ってきたトークンを受け取ると、自分は何を一緒に信じることになるのか。それをどこに、どんな欄で書くのか。受け取る側が事故の大きさを小さくするには、何をコードに置けるのか。

## 実習資料

### 準備

プロジェクトを二つ使う。

- `code/market/`：通しプロジェクトMarketの第53章の終わりのバージョンのコピー。Marketのコード（`src/`）は変えず、テストのフォルダに、ほかのチェーンから渡ってきた形のテスト用のトークン`test/BridgedToken.sol`とテスト`test/Bridged.t.sol`だけを足した。依存はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`lib/`）である。
- `code/xchain/`：第208〜210講の講義用のクロスチェーンのプロジェクト。この講義では、1日の上限と停止の権限があるミント側（`Minter`）をテスト`test/Guard211.t.sol`で見る。

二つのチェーンの様式の記入は、ローカルのanvil二つ（チェーンの番号57001、57002）に既定のテスト用アカウント0〜4番でデプロイし、取引を送った。1日の上限は150でデプロイした。

| アカウント | アドレス | 役割 |
|---|---|---|
| 0 | 0xf39F…2266 | デプロイ |
| 1 | 0x7099…79C8 | 確認者（attester） |
| 2 | 0x3C44…93BC | 中継 |
| 3 | 0x90F7…b906 | alice |
| 4 | 0x15d3…6A65 | 停止の権限（guardian） |

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | Marketの基準のバージョンの設定（solc 0.8.30、optimizerオン、via-IRオン、evm osaka） |
| [code/market/src/Market.sol](code/market/src/Market.sol) | Marketの本体（第53章の終わりのバージョン、変えない）。`addAsset`は0アドレス、上場済み、比率の上限だけを確かめる |
| [code/market/test/BridgedToken.sol](code/market/test/BridgedToken.sol) | ほかのチェーンから渡ってきた形のテスト用のトークン。発行する側（minter）と止める側（guardian）がデプロイのときに決まり、止めるとtransfer・transferFromが`TokenPaused`でリバートする |
| [code/market/test/Bridged.t.sol](code/market/test/Bridged.t.sol) | BridgedTestの二つ |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/)の残り | Marketの残りのソースと、基準のバージョンのテスト |
| [code/xchain/foundry.toml](code/xchain/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka、fuzz runs 256・seed 0x2a |
| [code/xchain/src/Msg57.sol](code/xchain/src/Msg57.sol) | メッセージの7欄`Message`、番号`Msg.idOf`（7欄すべてのkeccak256）、検証の枠`IVerifier`、受け取るアプリ`IReceiver` |
| [code/xchain/src/Outbox57.sol](code/xchain/src/Outbox57.sol) | 送る側のコントラクト`ToyOutbox`。メッセージを書いてログを1行残すところで終わる |
| [code/xchain/src/Endpoint57.sol](code/xchain/src/Endpoint57.sol) | 受け取る側のコントラクト`ToyEndpoint`。到着チェーン → 出発のoutbox → 受け取り済み → 検証の順に確かめ、受け取るアプリをtryで呼ぶ |
| [code/xchain/src/Verifiers57.sol](code/xchain/src/Verifiers57.sol) | 検証の枠三つ：`AttesterVerifier`（確認者の鍵一つ）、`OptimisticVerifier`（異議申し立ての期間）、`HeaderLightClient`（バリデーターの3分の2が署名したヘッダーとマークル証明） |
| [code/xchain/src/Ping57.sol](code/xchain/src/Ping57.sol) | 送るアプリ`PingSender`、受け取るアプリ`PingApp`（endpointと（チェーンの番号、アドレス）のペアだけを受け付ける） |
| [code/xchain/src/Assets57.sol](code/xchain/src/Assets57.sol) | 資産モデル`TestToken`、`LockBox`、`WrappedToken`、`Minter`、`PoolBridge` |
| [code/xchain/test/Base57.sol](code/xchain/test/Base57.sol) | テスト共通：チェーンの番号三つ、outboxのログからメッセージを取り出す関数 |
| [code/xchain/test/Guard211.t.sol](code/xchain/test/Guard211.t.sol) | GuardTestの三つ |

### 実行結果

Marketのコピーで`forge test --offline --match-contract BridgedTest -vv`（ガス記録の比較を切った状態）：

```
Ran 2 tests for test/Bridged.t.sol:BridgedTest
[PASS] test_bridgedTokenListedLikeAny() (gas: 112659)
[PASS] test_tokenPauseBlocksWithdraw() (gas: 299882)
Suite result: ok. 2 passed; 0 failed; 0 skipped
```

setUpでBridgedTokenを担保率75で上場し、bobが100を発行して受け取って預ける。価格の出どころは付けないので、担保としてオンにすると`NoPriceFeed`で、個数だけを数える。`test_bridgedTokenListedLikeAny`で30を引き出すと、帳簿のbob 70、bobのウォレット30、Marketの残高70で、ほかのトークンと同じである。

`test_tokenPauseBlocksWithdraw`のトレース（`-vvvv`）の一部（アドレスは省略）：

```
├─ [43584] BridgedToken::setPaused(true)
├─ [51386] Market::withdraw(BridgedToken: [0x2e23…470b], 30)
│   ├─ [2551] BridgedToken::transfer(0x…0B0b, 30)
│   │   └─ ← [Revert] TokenPaused()
│   └─ ← [Revert] TokenPaused()
├─ [52483] Market::withdrawAll(BridgedToken: [0x2e23…470b])
│   ├─ [2551] BridgedToken::transfer(0x…0B0b, 100)
│   │   └─ ← [Revert] TokenPaused()
│   └─ ← [Revert] TokenPaused()
├─ [7072] Market::positions(BridgedToken: [0x2e23…470b], 0x…0B0b) [staticcall]
│   └─ ← [Return] 100, 0, 1, false
├─ [26472] BridgedToken::setPaused(false)
├─ [80807] Market::withdraw(BridgedToken: [0x2e23…470b], 30)
```

guardianが止めると、withdraw 30とwithdrawAllの両方が`TokenPaused`で、帳簿のbob 100はそのままである。リバートしたのはwithdrawの中のtransferの1行、つまりトークン側である。guardianが解除すると、withdraw 30が成功する。

xchainで`forge test --offline --match-contract GuardTest -vv`：

```
Ran 3 tests for test/Guard211.t.sol:GuardTest
[PASS] test_dailyCapDefers() (gas: 789630)
[PASS] test_pauseDefersMint() (gas: 548499)
[PASS] test_strangerCannotPause() (gas: 32957)
Suite result: ok. 3 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_dailyCapDefers | 2回目の100が`DeliveryFailed(id, MintCapExceeded(200, 150))`、供給100・locked 200。1日後に同じメッセージをもう一度入れるとstatus 1、供給 = locked |
| test_pauseDefersMint | 止めたまま入れると`DeliveryFailed(id, Paused())`、供給0。解除してもう一度入れるとbob 100 |
| test_strangerCannotPause | bobが止めると`NotGuardian(bob)` |

`test_dailyCapDefers`のトレース（`-vvvv`）の一部（縮めてアドレスは省略）。理由のバイトは、セレクタ0xf85c5656 + 200（0xc8） + 150（0x96）である：

```
├─ [69326] ToyEndpoint::deliver(Message({ srcChainId: 57001, …, nonce: 2, … }), 0x)
│   ├─ [2468] AttesterVerifier::verify(0x4558…f03a, 0x) [staticcall]
│   │   └─ ← [Return] true
│   ├─ [7179] Minter::onMessage(57001, LockBox: [0x1d14…F211], …)
│   │   └─ ← [Revert] MintCapExceeded(200, 150)
│   ├─ emit DeliveryFailed(id: 0x4558…f03a, reason: 0xf85c5656…00c8…0096)
│   └─ ← [Return]
├─ WrappedToken::totalSupply() → 100
├─ LockBox::locked() → 200
├─ [0] VM::warp(86401)
├─ [86033] ToyEndpoint::deliver(…同じメッセージ…)
│   ├─ emit Delivered(id: 0x4558…f03a)
├─ ToyEndpoint::status(0x4558…f03a) → 1
├─ WrappedToken::totalSupply() → 200
├─ LockBox::locked() → 200
```

二つのチェーンに載せたおもちゃのブリッジの欄を、`cast call`・`cast storage`で読んだ値。aliceが同じ日に100を2回固定し、2回目はBの中継のトランザクションがstatus 1でも、endpointのstatusは2（理由`MintCapExceeded(200, 150)`）で、A locked 200 / B 供給100になった。`evm_increaseTime 86400`、`evm_mine`のあとに同じメッセージをもう一度入れてstatus 1、200 / 200になった。下はそのあとに読んだ値である（`<A>`、`<B>`は二つのチェーンのRPCのアドレス）：

```
$ cast call --rpc-url <B> 0xe7f1…0512 "verifier()(address)"
    0x5FbDB2315678afecb367f032d93F642f64180aa3
$ cast call --rpc-url <B> 0x5FbD…0aa3 "attester()(address)"
    0x70997970C51812dc3A010C7d01b50e0d17dc79C8
$ cast call --rpc-url <B> 0xCf7E…0Fc9 "peerChainId()(uint256)"
    57001
$ cast call --rpc-url <B> 0xCf7E…0Fc9 "peer()(address)"
    0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
$ cast call --rpc-url <A> 0xDc64…F6C9 "locked()(uint256)"
    200
$ cast call --rpc-url <B> 0xd805…1F81 "totalSupply()(uint256)"
    200
$ cast call --rpc-url <B> 0xd805…1F81 "minter()(address)"
    0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
$ cast call --rpc-url <B> 0xCf7E…0Fc9 "endpoint()(address)"
    0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
$ cast call --rpc-url <B> 0xe7f1…0512 "outboxOf(uint256)(address)" 57001
    0x5FbDB2315678afecb367f032d93F642f64180aa3
$ cast storage --rpc-url <B> 0xCf7E…0Fc9 <EIP-1967の実装の欄>
    0x0000000000000000000000000000000000000000000000000000000000000000
$ cast storage --rpc-url <B> 0xCf7E…0Fc9 <EIP-1967の管理者の欄>
    0x0000000000000000000000000000000000000000000000000000000000000000
$ cast call --rpc-url <B> 0xCf7E…0Fc9 "deployer()(address)"
    0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
$ cast call --rpc-url <B> 0xCf7E…0Fc9 "guardian()(address)"
    0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
$ cast call --rpc-url <B> 0xCf7E…0Fc9 "paused()(bool)"
    false
$ cast call --rpc-url <B> 0xCf7E…0Fc9 "dailyCap()(uint256)"
    150
```

EIP-1967の実装の欄は0x3608…2bbc、管理者の欄は0xb531…6103である。読んだ値で埋めた、おもちゃのブリッジの様式：

| 欄 | おもちゃのブリッジ | 読んだところ |
|---|---|---|
| ① 検証モデルと信じる対象 | 外部検証、確認者の鍵一つ | endpoint.verifier、attester |
| ② 署名者・監視者の数としきい値 | 確認者一人、しきい値なし | AttesterVerifierのコード |
| ③ 資産モデルと担保の場所 | ロックアップ・ミント、金庫は57001の0xDc64…F6C9、locked ↔ wTKAの供給 | peerChainId、peer、locked、totalSupply |
| ④ 発行の権限 | ミントのコントラクト ← endpoint ← 確認者 | minter、endpoint、outboxOf |
| ⑤ アップグレード・管理者の鍵 | プロキシの欄は0、アップグレードの関数なし、deployerはsetPeerを一度（決定済み） | cast storage、deployer |
| ⑥ 一時停止の権限とMarketの引き出し | アカウント4、発行だけを止める | guardian、paused |
| ⑦ 上限 | 1日150 | dailyCap |
| ⑧ ファイナリティの待ち時間と、失敗・入れ直し | 待つ行なし（確認者が決める）、status 2の入れ直し | status |

Marketのコピー全体（`ci.sh`と同じ検査）は44スイート138個が通過する（基準のバージョン136個 + BridgedTestの二つ）。

### 試すときの注意

- Marketの`addAsset`はトークンのアドレス一つだけを受け取る。トークンの裏の金庫や、誰が発行するかは問わない。
- トークン側の停止の権限はMarketのコードにない鍵だが、Marketの引き出しの行まで届く。リバートはMarketの中のtransferの1行で起きる。
- guardianのアドレス、1日の上限、確認者のような値は、ソースではなくデプロイされたチェーンから読む。実在するブリッジの様式の値は、上場する日にそのチェーンで読み直して埋める。
- 上限を置くと、検証が破られた日に発行される量がその日の上限までに減り、残りはstatus 2として積まれる。そのかわり、正常な利用者も大きな金額なら1日以上待つ。停止の権限は、鍵がもう一つ増えることである。
- Marketの`foundry.toml`はガス記録の比較をオンにしてある。リポジトリにガス記録のファイルを入れていないので、`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`をつけて実行する。
- この講義の二つのチェーンのアドレスは、第210講のデモとデプロイの順番が違うので異なる（今回の金庫0xDc64…F6C9は第210講のTKAのアドレス）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30。xchain：optimizerオン（runs 200）、via-IRオン、evm osaka、fuzz runs 256・seed 0x2a。market：基準のバージョンのfoundry.tomlのまま | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0（xchainのERC20・ECDSA・MerkleProof） | 2026-10-21 |
| テストの数 | Marketのコピー44スイート138個（基準のバージョン136個 + BridgedTestの二つ）、xchainのGuardTest三つ | 2026-10-21 |
| Marketのサイズ | runtime 9,006 / creation 9,233（基準のバージョンと同じ） | 2026-10-21 |
| テストのガス | bridgedTokenListedLikeAny 112,659 / tokenPauseBlocksWithdraw 299,882 / dailyCapDefers 789,630 / pauseDefersMint 548,499 / strangerCannotPause 32,957 | 2026-10-21 |
| 二つのチェーンのアドレス | A outbox 0x5FbD…0aa3・確認者の検証0xe7f1…0512・endpoint 0x9fE4…a6e0・TKA 0xCf7E…0Fc9・金庫0xDc64…F6C9 / B 確認者の検証0x5FbD…0aa3・endpoint 0xe7f1…0512・outbox 0x9fE4…a6e0・ミント0xCf7E…0Fc9・wTKA 0xd805…1F81 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| トークンの上場の基準全般（価格・流動性・担保のリスト） | [第197講](../../part13/lecture197/)、[第198講](../../part13/lecture198/)、[第199講](../../part13/lecture199/) |
| オラクルの信頼の前提の欄 | [第204講](../../part14/lecture204/)、[第205講](../../part14/lecture205/)、[第206講](../../part14/lecture206/)、[第207講](../../part14/lecture207/) |
| 監査で信頼の前提のドキュメントを読む方法 | [第254講](../../part20/lecture254/)〜[第260講](../../part20/lecture260/) |
| イベントで金庫・供給を見張るプログラム | [第238講](../../part18/lecture238/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
