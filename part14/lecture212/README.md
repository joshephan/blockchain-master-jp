# 第212講 クロスチェーン事故のポストモーテム

第14部 オラクル・クロスチェーン・ガバナンス・第57章 クロスチェーン

[← 第211講](../../part14/lecture211/) | [第14部 目次](../) | [第213講 →](../../part14/lecture213/)

## この講義の問い

クロスチェーンの事故は、メッセージの道のどの位置で起きたのか。鍵を奪われた事故と、確認の行が間違っていた事故はどう違うのか。受け取る側はどんな既定値を持つべきなのか。

## 実習資料

### 準備

第211講と同じプロジェクト二つを使う。この講義で足したファイルは、xchainの確認テスト`test/Defaults212.t.sol`一つである。

- `code/xchain/`：第208〜211講の講義用のクロスチェーンのプロジェクト。受け取る側の欄（受け取ったルート、上がった番号、処理の状態）に何も書かれていないとき「受け取っていない」と読まれるかと、endpointが受け取るアプリのonMessageだけを呼ぶかを確かめる。
- `code/market/`：通しプロジェクトMarketの第53章の終わりのバージョンのコピー（第211講でテスト用のBridgedTokenとBridgedTestを足したもの）。Marketのコードは変えない。

依存は、二つのプロジェクトともforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`lib/`）である。anvilも外部への接続も使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/xchain/foundry.toml](code/xchain/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka、fuzz runs 256・seed 0x2a |
| [code/xchain/src/Msg57.sol](code/xchain/src/Msg57.sol) | メッセージの7欄`Message`、番号`Msg.idOf`（7欄すべてのkeccak256）、検証の枠`IVerifier`、受け取るアプリ`IReceiver` |
| [code/xchain/src/Outbox57.sol](code/xchain/src/Outbox57.sol) | 送る側のコントラクト`ToyOutbox`。メッセージを書いてログを1行残すところで終わる |
| [code/xchain/src/Endpoint57.sol](code/xchain/src/Endpoint57.sol) | 受け取る側のコントラクト`ToyEndpoint`。到着チェーン → 出発のoutbox → 受け取り済み → 検証の順に確かめ、受け取るアプリをtryで呼ぶ |
| [code/xchain/src/Verifiers57.sol](code/xchain/src/Verifiers57.sol) | 検証の枠三つ：`AttesterVerifier`（確認者の鍵一つ）、`OptimisticVerifier`（異議申し立ての期間）、`HeaderLightClient`（バリデーターの3分の2が署名したヘッダーとマークル証明） |
| [code/xchain/src/Ping57.sol](code/xchain/src/Ping57.sol) | 送るアプリ`PingSender`、受け取るアプリ`PingApp`（endpointと（チェーンの番号、アドレス）のペアだけを受け付ける） |
| [code/xchain/src/Assets57.sol](code/xchain/src/Assets57.sol) | 資産モデル`TestToken`、`LockBox`、`WrappedToken`、`Minter`、`PoolBridge` |
| [code/xchain/test/Base57.sol](code/xchain/test/Base57.sol) | テスト共通：チェーンの番号三つ、outboxのログからメッセージを取り出す関数 |
| [code/xchain/test/Defaults212.t.sol](code/xchain/test/Defaults212.t.sol) | DefaultsTestの四つ |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketの基準のバージョンの設定 |
| [code/market/src/Market.sol](code/market/src/Market.sol) | Marketの本体（第53章の終わりのバージョン、変えない） |
| [code/market/test/NoSig.t.sol](code/market/test/NoSig.t.sol) | NoSigTest。Marketに署名・証明を確かめる行がないことを確かめる |
| [code/market/test/Bridged.t.sol](code/market/test/Bridged.t.sol)、[code/market/test/BridgedToken.sol](code/market/test/BridgedToken.sol) | 第211講のBridgedTestと、テスト用のブリッジのトークン |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/)の残り | Marketの残りのソースと、基準のバージョンのテスト |

### 実行結果

xchainで`forge test --offline --match-contract DefaultsTest -vv`：

```
Ran 4 tests for test/Defaults212.t.sol:DefaultsTest
[PASS] test_defaultStatusNotDelivered() (gas: 21789)
[PASS] test_endpointCallsOnlyOnMessage() (gas: 202335)
[PASS] test_unsubmittedHeaderNeverVerified() (gas: 20942)
[PASS] test_zeroIdNeverVerified() (gas: 43787)
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_zeroIdNeverVerified | 番号0はverify false、1年後もfalse、`propose(0)`は`ZeroId` |
| test_unsubmittedHeaderNeverVerified | 上げていないヘッダー999のルートは0、適当な番号と番号0のどちらもverify false |
| test_defaultStatusNotDelivered | 送っていない番号はstatus 0、attested false、verify false |
| test_endpointCallsOnlyOnMessage | 受け取るアプリの欄に確認者の検証コントラクトのアドレスを、中身の欄にattestの呼び出しのバイトを入れても、endpointはonMessageだけを呼ぶ。存在しない関数なのでリバートしてstatus 2、そのattestは起きない |

`test_endpointCallsOnlyOnMessage`のトレース（`-vvvv`）の一部（ガス・アドレスは省略）：

```
├─ ToyEndpoint::deliver(Message({ srcChainId: 57001, …, receiver: AttesterVerifier, … }), 0x)
│   ├─ AttesterVerifier::verify(0xbffe…bc87, 0x) [staticcall]
│   │   └─ ← [Return] true
│   ├─ AttesterVerifier::onMessage(57001, …, 0x23c3617f…)
│   │   └─ ← [Revert] unrecognized function selector 0x04f97bb4 … no fallback function.
│   ├─ emit DeliveryFailed(id: 0xbffe…bc87, reason: 0x)
├─ ToyEndpoint::status(0xbffe…bc87) → 2
├─ AttesterVerifier::attested(0x7521…7a83) → false
```

xchain全体の`forge test --offline`は5スイート33個が通過する。

Marketのコピーで`forge test --offline --match-contract "BridgedTest|NoSigTest" -vv`（ガス記録の比較を切った状態）：

```
[PASS] test_bridgedTokenListedLikeAny() (gas: 112659)
[PASS] test_tokenPauseBlocksWithdraw() (gas: 299882)
[PASS] test_borrowNeverCallsEcrecover() (gas: 1510280)
[PASS] test_staticcallsArePriceReads() (gas: 1552126)
Ran 2 test suites: 4 tests passed, 0 failed, 0 skipped (4 total tests)
```

NoSigTestは、Marketのランタイムのコードの三つのSTATICCALLが価格の出どころの合計二つとdecimals一つを読むものであり、借りる流れでecrecover（アドレス1）を呼ぶことが0回であることを確かめる。Marketのコピー全体は44スイート138個が通過する。

七つの事件を五つの位置に置いた地図：

| 五つの位置 | 事件 | 何が破られたか |
|---|---|---|
| 送る側 | なし | |
| 中継 | なし | |
| 検証 | Ronin、Harmony Horizon / Wormhole / Nomad / BNB Chainのブリッジ | 鍵 / 確認の行 / 既定値 / 証明を確かめるコード |
| 受け取る側 | Poly Network | 呼ぶ対象と権限のデータ |
| 受け取るアプリ | Wintermute OP | アドレスの前提 |

### 試すときの注意

- マッピングは存在しないキーを0として読む。受け取る側の空の欄（受け取ったルート、上がった番号、処理の状態）は「受け取っていない」と読まれなければならない。OptimisticVerifierが番号0をそもそも上げられないようにしたのも、0が空の欄と同じ形だからである。
- マークル証明が言うのは、この葉がこのルートの下にあるという包含の事実までである。そのルートを信じるかどうかは、呼ぶ側が別に決める。
- endpointがメッセージの中身のとおりに何でも関数を呼ぶと、権限のあるコントラクトも呼ぶことになる。このコードのendpointは、受け取るアプリのonMessage一つだけを呼び、中身の欄は引数として渡すだけである。
- endpointは、`outboxOf[出発チェーン]`とメッセージの出発のoutboxを先に比べる。同じ形のログを出したほかのコントラクトは、登録されたアドレスでなければはじかれる。
- 1日の上限を置くと、鍵が破られた日に失う大きさがその上限までに減る（第211講のGuardTest）。鍵を守ることと、破られた日の大きさを決めることは別である。
- 事件は、名前・年・1行の性格と五つの位置への対応までだけを書いた。損失額と経緯は載せていない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| 事件の年 | Poly Network 2021、Wormhole 2022、Ronin 2022、Harmony Horizon 2022、Wintermute OP 2022、Nomad 2022、BNB Chainのブリッジ2022 | 2026-10-21 |
| Foundry（forge） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30。xchain：optimizerオン（runs 200）、via-IRオン、evm osaka、fuzz runs 256・seed 0x2a。market：基準のバージョンのfoundry.tomlのまま | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0、`utils/cryptography/MerkleProof.sol` 45〜47行目（verify） | 2026-10-21 |
| テストの数 | xchain 5スイート33個（DefaultsTestの四つ）、Marketのコピー44スイート138個（基準のバージョン136個 + BridgedTestの二つ） | 2026-10-21 |
| テストのガス | defaultStatusNotDelivered 21,789 / endpointCallsOnlyOnMessage 202,335 / unsubmittedHeaderNeverVerified 20,942 / zeroIdNeverVerified 43,787 / borrowNeverCallsEcrecover 1,510,280 / staticcallsArePriceReads 1,552,126 / bridgedTokenListedLikeAny 112,659 / tokenPauseBlocksWithdraw 299,882 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 事件の経緯と年表 | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| 同じ形のログを信じた事件（事件の名前が確かめられれば） | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| 署名メッセージの設計全般 | [第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| 層ごとに見直す | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
