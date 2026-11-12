# 第209講 検証モデルの分類：外部・楽観的・ライトクライアント・ZK

第14部 オラクル・クロスチェーン・ガバナンス・第57章 クロスチェーン

[← 第208講](../../part14/lecture208/) | [第14部 目次](../) | [第210講 →](../../part14/lecture210/)

## この講義の問い

受け取る側は「このメッセージは本当に向こうから出た」を何で信じるのか。確認を減らすと、信じなければならないものはどこへ行くのか。同じ受け取る側のコードで検証の枠だけを変えると、何が変わるのか。

## 実習資料

### 準備

第208講と同じ講義用のクロスチェーンのプロジェクト（`xchain`）で行う。送る側のコントラクト、受け取る側のコントラクト、受け取るアプリはそのままにして、検証の枠だけを差し替える。この講義で使う検証の枠は、`src/Verifiers57.sol`の`OptimisticVerifier`と`HeaderLightClient`である。依存はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`lib/`、ECDSA・MerkleProof）である。テストの中の署名の鍵は小さな数（0xA11CE・0xB0B・0xC0FFEE・0xD00D、新しい集合0xE1〜0xE4）である。二つのチェーンのデモは、ローカルのanvil二つ（チェーンの番号57001、57002）に既定のテスト用アカウント（1番が提案者、4番が監視者）で送った。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka、fuzz runs 256・seed 0x2a |
| [code/src/Msg57.sol](code/src/Msg57.sol) | メッセージの7欄`Message`、番号`Msg.idOf`（7欄すべてのkeccak256）、検証の枠`IVerifier`、受け取るアプリ`IReceiver` |
| [code/src/Outbox57.sol](code/src/Outbox57.sol) | 送る側のコントラクト`ToyOutbox`。メッセージを書いてログを1行残すところで終わる |
| [code/src/Endpoint57.sol](code/src/Endpoint57.sol) | 受け取る側のコントラクト`ToyEndpoint`。到着チェーン → 出発のoutbox → 受け取り済み → 検証の順に確かめ、受け取るアプリをtryで呼ぶ |
| [code/src/Verifiers57.sol](code/src/Verifiers57.sol) | 検証の枠三つ：`AttesterVerifier`（確認者の鍵一つ）、`OptimisticVerifier`（異議申し立ての期間）、`HeaderLightClient`（バリデーターの3分の2が署名したヘッダーとマークル証明） |
| [code/src/Ping57.sol](code/src/Ping57.sol) | 送るアプリ`PingSender`、受け取るアプリ`PingApp`（endpointと（チェーンの番号、アドレス）のペアだけを受け付ける） |
| [code/src/Assets57.sol](code/src/Assets57.sol) | 資産モデル`TestToken`、`LockBox`、`WrappedToken`、`Minter`、`PoolBridge` |
| [code/test/Base57.sol](code/test/Base57.sol) | テスト共通：チェーンの番号三つ、outboxのログからメッセージを取り出す関数 |
| [code/test/Verify209.t.sol](code/test/Verify209.t.sol) | VerifyTestの十個 |

### 実行結果

`forge test --offline --match-contract VerifyTest -vv`：

```
Ran 10 tests for test/Verify209.t.sol:VerifyTest
[PASS] test_afterWindowVerified() (gas: 260607)
[PASS] test_challengeClosedAfterWindow() (gas: 176474)
[PASS] test_headerNeedsQuorum() (gas: 232630)
[PASS] test_headerNotSubmittedRejected() (gas: 217869)
[PASS] test_messageUnderHeaderDelivered() (gas: 399981)
[PASS] test_rotationByCurrentSet() (gas: 565394)
[PASS] test_sameHeaderTwoClients() (gas: 372825)
[PASS] test_strangerCannotChallenge() (gas: 175322)
[PASS] test_tooEarlyNotVerified() (gas: 188282)
[PASS] test_watcherChallengeBlocks() (gas: 238637)
Suite result: ok. 10 passed; 0 failed; 0 skipped
```

楽観的検証（異議申し立ての期間30分）：

| テスト | 結果 |
|---|---|
| test_tooEarlyNotVerified | 提案の29分後にdeliverすると`NotVerified` |
| test_afterWindowVerified | 提案の30分後にdeliverするとcount 1 |
| test_watcherChallengeBlocks | 10分で監視者がchallengeすると、1日後も`NotVerified` |
| test_challengeClosedAfterWindow | 30分後のchallengeは`ChallengeClosed` |
| test_strangerCannotChallenge | 登録されていないアカウントのchallengeは`NotWatcher(0x4905…A5dC)` |

ライトクライアント（向こうのバリデーター四人、定足数3）。ヘッダー100のルート0x34d9…c0dfは、メッセージの番号hello 0x0f16…c43cとworld 0xcf60…2938で作ったマークルルートで、helloを入れるときの証明は(100, [worldの葉のハッシュ])である：

| テスト | 結果 |
|---|---|
| test_headerNeedsQuorum | 署名二つなら`BelowQuorum(2, 3)` |
| test_messageUnderHeaderDelivered | 署名三つでヘッダー100を上げ、helloを証明1欄で入れるとcount 1、last "hello" |
| test_headerNotSubmittedRejected | ヘッダー100を上げずに同じ証明を入れると`NotVerified(0x0f16…c43c)` |
| test_sameHeaderTwoClients | チェーンBとチェーン57003のライトクライアントが同じダイジェスト0x3a9c…cfeaを出し、同じ署名三つで両方ともヘッダー100を受け付ける |
| test_rotationByCurrentSet | 今の集合の三つ（0xA11CE・0xB0B・0xC0FFEE）が新しい集合（0xE1〜0xE4）に署名してrotateするとepoch 1。そのあと古い鍵三つのヘッダー101の署名は`NotValidator(0x0376…473c)`（0xB0B）、新しい鍵三つの署名は受け付ける |

`test_sameHeaderTwoClients`と`test_rotationByCurrentSet`のトレース（`-vvvv`）の一部：

```
[PASS] test_sameHeaderTwoClients() (gas: 372825)
    ├─ [553] HeaderLightClient::headerDigest(100, 0x34d9436571d533699f535ac4e236d2301dc7169fbaac05abcccb09f5a799c0df) [staticcall]
    │   └─ ← [Return] 0x3a9ca57b18b601d05d5fbba33c74caee780fd50f8fc104ebf39dd1bc5d10cfea
[PASS] test_rotationByCurrentSet() (gas: 565394)
    │   └─ ← [Revert] NotValidator(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c)
```

二つのチェーンの監視者のデモの出力。提案者がチェーンAで本当に送った"real"の番号（0xeed1…）と、そのメッセージの連番を99に・中身を"fake"に変えてハッシュした、Aにない番号（0xce57…）を、チェーンBのOptimisticVerifierに上げた。監視者はチェーンAのoutboxの`sent(id)`を`cast call`で読み、Aにない番号だけを止めた：

```
== 第209講：楽観的検証と監視者 ==
  上がった番号二つ：本物 0xeed18293…、Aにない番号 0xce57372f…
  監視者：A sent(本物) = true → そのまま
  監視者：A sent(ない番号) = false → challenge成功
  期間内の本物の中継：リバート
```

チェーンBの時間だけを`evm_increaseTime 1800`、`evm_mine`で30分進めたあと：

```
  30分後の本物の中継：成功、count 1
  30分後のない番号の中継：リバート、verify false
```

### 試すときの注意

- OptimisticVerifierで番号が通るには、上がった番号で、止められたことがなく、期間が過ぎていなければならない。監視者が期間内に動いても、そのchallengeのトランザクションが期間内に受け取る側のチェーンのブロックに入らなければならない。
- HeaderLightClientは署名者のアドレスを昇順で受け取り、今の集合のバリデーターかを見る。最初の集合はデプロイのときに一度信じ、そのあとは今の集合の署名でだけ変わる。
- ブリッジの署名は「このコントラクトでこのルートを受け取れ」のように受け取る側のアドレスを含むが、ライトクライアントが受け取る署名は「向こうのチェーンの100番ブロックはこれ」という事実なので、同じヘッダーをほかのクライアントにも入れられる。
- おもちゃは、メッセージの番号で作ったマークルルートをヘッダーに置く。実際のチェーンは、ヘッダーのステートルート・レシートルートと、そのツリーの証明を使う。
- 異議申し立ての期間30分は講義用の値である。実際のシステムの期間はこれより長い。

| モデル | 信じるもの | 待ち時間 / 受け取る側のコスト / 破られるのに必要なもの |
|---|---|---|
| 外部 | 署名者のしきい値と鍵の分布 | ほとんどなし / 署名いくつか / しきい値分の鍵 |
| 楽観的 | 監視者一人が期間内に動くこと | 異議申し立ての期間 / 小さい / 期間中に誰も見ていない |
| ライトクライアント | 向こうのチェーンの合意、最初の集合 | ファイナリティ / ヘッダーごとの署名の確認 / 向こうのバリデーターの多数 |
| ZK | 証明システム・回路、確認コントラクトの鍵 | 証明を作る時間 / 証明の確認 / 回路や確認のコードの欠陥 |

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョン、仕様、各プロジェクトのドキュメントが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka、fuzz runs 256・seed 0x2a | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0、`utils/cryptography/MerkleProof.sol` 45〜47行目（verify）、57〜63行目（processProof） | 2026-10-21 |
| イーサリアムの同期委員会 | 512人、256エポック（約27時間）ごとに交代 | 2026-10-21 |
| イーサリアムのファイナリティ | 約2エポック（約13分） | 2026-10-21 |
| 実際の製品の検証モデルの例 | IBCのライトクライアント、WormholeのGuardian署名者（外部）。名前のレベルだけ | 2026-10-21 |
| VerifyTestのガス | afterWindowVerified 260,607 / challengeClosedAfterWindow 176,474 / headerNeedsQuorum 232,630 / headerNotSubmittedRejected 217,869 / messageUnderHeaderDelivered 399,981 / rotationByCurrentSet 565,394 / sameHeaderTwoClients 372,825 / strangerCannotChallenge 175,322 / tooEarlyNotVerified 188,282 / watcherChallengeBlocks 238,637 | 2026-10-21 |
| テスト・デモの値 | テスト用の鍵0xA11CE・0xB0B・0xC0FFEE・0xD00D → 0xe05f…cFF7・0x0376…473c・0xF5A5…50a4・0x813e…005b、新しい集合0xE1〜0xE4。ヘッダー100のルート0x34d9…c0df、ダイジェスト0x3a9c…cfea。二つのチェーンの本物の番号0xeed1…、ない番号0xce57… | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ZK証明が大きな計算を短く確かめる原理 | [第234講](../../part17/lecture234/) |
| ロールアップの異議申し立ての期間と脱出 | [第232講](../../part17/lecture232/)、[第233講](../../part17/lecture233/) |
| 受け取る側が向こうのチェーンのステートツリーの証明を直接解くコード（RLP・ツリーの経路） | 扱わない |
| 検証モデルを二つ重ねる設計 | [第211講](../../part14/lecture211/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
