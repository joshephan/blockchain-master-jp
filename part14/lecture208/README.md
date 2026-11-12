# 第208講 メッセージングプロトコルの構造

第14部 オラクル・クロスチェーン・ガバナンス・第57章 クロスチェーン

[← 第207講](../../part14/lecture207/) | [第14部 目次](../) | [第209講 →](../../part14/lecture209/)

## この講義の問い

あるチェーンのコントラクトがほかのチェーンに何かをさせるとき、実際に何が行き来するのか。送った側のトランザクションが成功すれば、受け取る側も成功したことになるのか。受け取る側は、メッセージが誰から来たのかを何で知るのか。

## 実習資料

### 準備

Marketとは関係のない講義用のクロスチェーンのプロジェクト（`xchain`）で行う。送る側のコントラクト、受け取る側のコントラクト、検証の枠、受け取るアプリをいちばん小さく縮めたコードで、実在するプロトコルのコードではない。依存はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`lib/`）である。forgeのテストは一つのEVMの中で、`vm.chainId`でチェーンの番号だけを変えながら二つのチェーンをまねる。二つのチェーンのデモは、ローカルのanvilを二つ（チェーンの番号57001、57002）立ち上げ、既定のテスト用アカウント0〜3番（0がデプロイ、1が確認者、2が中継、3がalice）で取引を送った。二つのチェーンのあいだをつなぐプログラムはなく、中継は手で行う。

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
| [code/test/Message208.t.sol](code/test/Message208.t.sol) | MessageTestの十個 |

### 実行結果

`forge test --offline --match-contract MessageTest -vv`：

```
Ran 10 tests for test/Message208.t.sol:MessageTest
[PASS] test_anyoneRelaysAfterAttest() (gas: 278351)
[PASS] test_deliverNeedsVerification() (gas: 137657)
[PASS] test_deliverOnce() (gas: 291052)
[PASS] test_fieldSwapChangesId() (gas: 187833)
[PASS] test_peerChecksChainAndAddress() (gas: 217908)
[PASS] test_receiverFailureKeepsSent() (gas: 232206)
[PASS] test_sendOnlyLogs() (gas: 117935)
[PASS] test_strangerCannotAttest() (gas: 123633)
[PASS] test_unknownSourceRejected() (gas: 173445)
[PASS] test_wrongDestinationRejected() (gas: 179391)
Suite result: ok. 10 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_sendOnlyLogs | A outbox `sent(id)` true、`nonce()` 1、B PingApp `count()` 0、B endpoint `status(id)` 0（なし） |
| test_deliverNeedsVerification | attestの前のdeliverが`NotVerified(0xbc6a…c645)` |
| test_anyoneRelaysAfterAttest | attestのあと中継のアカウントが入れるとcount 1、last "hello"、status 1 |
| test_strangerCannotAttest | 中継のアカウントがattestすると`NotAttester(0x011f…8DB8)` |
| test_deliverOnce | 2回目のdeliverが`AlreadyDelivered(0xbc6a…c645)`、count 1のまま |
| test_wrongDestinationRejected | チェーン57003でdeliverすると`WrongDestination(57002)` |
| test_unknownSourceRejected | Aに新しくデプロイした別のoutboxが送ったhelloは、確認者がattestしても`UnknownSource(57001, 0x1d14…F211)` |
| test_fieldSwapChangesId | 確認者がattestした"hello"（番号0xbc6a…c645）を中継が"bye"に変えて入れると、番号が0xaf62…e7d1になって`NotVerified(0xaf62…e7d1)` |
| test_receiverFailureKeepsSent | 受け取るアプリが`EmptyText()`でリバートしても、deliverのトランザクションは成功。`DeliveryFailed`の理由0xaf943d03（EmptyTextのセレクタ）、status 2、count 0、A outbox sent true |
| test_peerChecksChainAndAddress | チェーン57003のoutboxから、AのPingSenderと同じアドレスが送ったhelloがendpointの四つの確認を通り、PingAppで`NotPeer(57003, 0x2e23…470b)` |

`test_receiverFailureKeepsSent`のトレース（`-vvvv`）の一部：

```
[PASS] test_receiverFailureKeepsSent() (gas: 232206)
    │   ├─ [850] PingApp::onMessage(57001 [5.7e4], PingSender: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0x…20…00)
    │   │   └─ ← [Revert] EmptyText()
    │   ├─ emit DeliveryFailed(id: 0x51f28f9386895138ba9f677027f221beb9619fb7e680b66f809507f2724f8a3e, reason: 0xaf943d03)
    │   └─ ← [Return]
```

二つのチェーンのデモの出力。チェーンA（57001）でhelloを送り、チェーンB（57002）に手で中継した：

```
== 第208講：ping ==
  A outbox 0x5FbDB2315678afecb367f032d93F642f64180aa3、A 送るアプリ 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  B 確認者の検証 0x5FbDB2315678afecb367f032d93F642f64180aa3、B endpoint 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512、B 受け取るアプリ 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  A 送信：tx status 1、ブロック 3、ログ 1 個、id 0x9c2cee8fa516a13b3006a576eeb515681a7f89610873729622146d9897d8500f
  A sent(id) true、B count 0
  確認者の確認の前の中継：リバート … NotVerified(0x9c2cee8fa516a13b3006a576eeb515681a7f89610873729622146d9897d8500f)
  確認者の確認のあとの中継：中継成功、status 1
  B count 1、last "hello"
  空の文を送信：A tx status 1
  空の文の中継：中継成功、status 2
  B count 1、A sent(id) true
  同じアドレスの確認：A 0x5FbDB2315678afecb367f032d93F642f64180aa3 コードの長さ 811、B 同じアドレスのコードの長さ 459
```

helloメッセージの7欄：

| 欄 | 意味 | hello |
|---|---|---|
| srcChainId | 出発チェーンの番号 | 57001 |
| srcOutbox | 送ったoutbox | 0x5FbD…0aa3 |
| nonce | outboxがつける連番 | 1 |
| sender | outboxを呼んだアプリ | PingSender 0xe7f1…0512 |
| dstChainId | 到着チェーンの番号 | 57002 |
| receiver | 受け取るアプリ | PingApp 0x9fE4…a6e0 |
| payload | 中身 | abi.encode("hello") |

### 試すときの注意

- 送る側は、自分のチェーンにログを1行残すところで終わる。EVMのCALL・STATICCALL・DELEGATECALLは、どれも同じチェーンのアドレスしか受け取らない。誰かがそのログを受け取る側のチェーンにトランザクションとして入れて、はじめて受け取る側のコードが動く。
- 送るトランザクションがリバートすると、ログも残らず、中継するメッセージがない。
- endpointは`msg.sender`を見ない。入れる人は誰でもよく、メッセージが本物かどうかは検証の枠が決める。
- メッセージの番号は7欄すべてのハッシュである。番号から抜けた欄があれば、その欄は差し替えて入れても同じ番号になる。
- 受け取るアプリが失敗すると、受け取るアプリの中の変更だけが戻り、deliverのトランザクションは成功する（status 2）。送った側は戻らない。中継が動かなければ、メッセージはstatus 0のまま残る。nonceは番号にすぎず、受け取る側が順番を強制しない。
- 同じデプロイ用のアカウントで二つのチェーンに最初のデプロイをすると、アドレスが同じになる（0x5FbD…0aa3）。チェーンAではToyOutbox 811バイト、チェーンBではAttesterVerifier 459バイトである。受け取るアプリは、送ったチェーンの番号とアドレスを一緒に確かめる。
- デモのアドレスは、デプロイするアカウント・順番を変えると変わる。チェーンの番号57001・57002はデモ用に選んだ値である。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョン、ドキュメントのバージョン、各プロジェクトのドキュメントが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka、fuzz runs 256・seed 0x2a | 2026-10-21 |
| Solidityのドキュメント | v0.8.36 `control-structures.rst` try/catchの節810〜904行目（873〜876 catch bytes、902〜904 戻された変更） | 2026-10-21 |
| デモのチェーンの番号 | 57001、57002。forgeのテストの中では57001・57002・57003を`vm.chainId`で変えて使う | 2026-10-21 |
| デモのアドレス | A outbox・B 確認者の検証0x5FbD…0aa3（コード811 / 459バイト）、A PingSender・B endpoint 0xe7f1…0512、B PingApp 0x9fE4…a6e0 | 2026-10-21 |
| MessageTestのガス | anyoneRelaysAfterAttest 278,351 / deliverNeedsVerification 137,657 / deliverOnce 291,052 / fieldSwapChangesId 187,833 / peerChecksChainAndAddress 217,908 / receiverFailureKeepsSent 232,206 / sendOnlyLogs 117,935 / strangerCannotAttest 123,633 / unknownSourceRejected 173,445 / wrongDestinationRejected 179,391 | 2026-10-21 |
| 公開ドキュメントが五つの枠を呼ぶ名前 | IBC relayer・light client / Chainlink CCIP Router・OnRamp・OffRamp / LayerZero Endpoint・DVN・Executor / Hyperlane Mailbox・ISM / Wormhole Guardian・VAA / OP Stack CrossDomainMessenger（名前のレベルだけ） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 検証の枠のモデルの比較（外部・楽観的・ライトクライアント・ZK） | [第209講](../../part14/lecture209/) |
| メッセージにお金を載せるとき（ロックアップ・ミント・流動性） | [第210講](../../part14/lecture210/) |
| ロールアップ固有のメッセージの道（入出金、やり直しの表） | [第232講](../../part17/lecture232/)、[第233講](../../part17/lecture233/) |
| チェーンの外の中継プログラムの運用 | [第238講](../../part18/lecture238/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
