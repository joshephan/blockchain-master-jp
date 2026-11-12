# 第210講 ブリッジの資産モデル：ロックアップ・ミント・流動性

第14部 オラクル・クロスチェーン・ガバナンス・第57章 クロスチェーン

[← 第209講](../../part14/lecture209/) | [第14部 目次](../) | [第211講 →](../../part14/lecture211/)

## この講義の問い

トークンをほかのチェーンに「送る」とは、実際にはどの帳簿のどの数字が変わることなのか。受け取る側で受け取ったトークンの値は、何が支えているのか。受け取る側のお金が足りないと、どうなるのか。

## 実習資料

### 準備

第208講・第209講と同じ講義用のクロスチェーンのプロジェクト（`xchain`）で行う。メッセージの道（outbox、endpoint、確認者の検証）はそのままにし、その上にお金を載せる受け取るアプリ`src/Assets57.sol`を使う。依存はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（`lib/`、ERC20）である。二つのチェーンのデモは、ローカルのanvil二つ（チェーンの番号57001、57002）に既定のテスト用アカウント（0がデプロイ、1が確認者、2が中継、3がalice）で送った。aliceはチェーンAでTKAを300受け取っておいてから始める。

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
| [code/test/Assets210.t.sol](code/test/Assets210.t.sol) | AssetsTestの六つ |

`Assets57.sol`の中のコントラクト：

| コントラクト | 内容 |
|---|---|
| TestToken | デモ用の元のトークン（TKA）。作ったアカウントが1000個を持つ |
| PeerApp | outbox・endpointのアドレスと、相手の（チェーンの番号、アドレス）の確認をまとめた共通部分。相手はデプロイしたアカウントが一度だけ決める |
| LockBox | ロックアップ側の金庫。元のトークンを固定し、向こうで発行してほしいというメッセージを送る、燃やしたというメッセージが来たら解放する |
| WrappedToken | 向こうのチェーンのラップトークン（wTKA）。発行して燃やす関数はMinterだけが呼ぶ |
| Minter | ミント側。固定したというメッセージが来たらラップトークンを発行する。1日の上限と一時停止がある |
| PoolBridge | 流動性の方式。両方のチェーンに本物のトークンのプール、受け取る側のプールが持つお金から払い出す |

### 実行結果

`forge test --offline --match-contract AssetsTest -vv`：

```
Ran 6 tests for test/Assets210.t.sol:AssetsTest
[PASS] test_burnThenUnlock() (gas: 698846)
[PASS] test_lockThenMint() (gas: 445385)
[PASS] test_onlyMinterMints() (gas: 33955)
[PASS] test_peerSetOnce() (gas: 64037)
[PASS] test_poolPaysFromLiquidity() (gas: 553069)
[PASS] test_poolShortFailsThenRetry() (gas: 656929)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```

| テスト | 結果 |
|---|---|
| test_lockThenMint | aliceがbobに100を固定 → locked 100、金庫のTKA残高100、供給0 → 中継 → bob 100、供給 = locked |
| test_burnThenUnlock | bobがaliceに40を燃やす → 供給60、locked 100 → 中継 → locked 60、alice TKA 240、供給 = locked |
| test_onlyMinterMints | bobがwTKA.mintを呼ぶと`NotMinter(0x1D96…1d3e)`（bob） |
| test_peerSetOnce | 2回目のsetPeerは`PeerAlreadySet()`、bobがsetPeerを呼ぶと`NotDeployer(bob)` |
| test_poolPaysFromLiquidity | Bのプール500から始める。aliceがAのプールに100を入れて中継すると、Aのプール100、Bのプール400、bob 100 |
| test_poolShortFailsThenRetry | Bのプール60で100送ったメッセージを入れると`DeliveryFailed(InsufficientLiquidity(60, 100))`、status 2。Bのプールに100を足して160にしてから同じメッセージをもう一度入れると、status 1、bob 100、Bのプール60 |

`test_poolShortFailsThenRetry`のトレース（`-vvvv`）の一部：

```
[PASS] test_poolShortFailsThenRetry() (gas: 656929)
    │   │   └─ ← [Revert] InsufficientLiquidity(60, 100)
    │   ├─ emit DeliveryFailed(id: 0x86e7f039ea6eea8ccce2b523c51d709ad1ada0b23d6bc1d40abcba33eea76390, reason: 0xa17e11d5…)
```

二つのチェーンのデモの出力。aliceが自分自身に固定して発行したあと、燃やして解放した：

```
== 第210講：固定して発行、燃やして解放 ==
  A 元のトークン 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9、A 金庫 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
  B ミント 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853、B ラップトークン 0x9bd03768a7DCc129555dE410FF8E85528A4F88b5
  [開始] A 金庫 locked 0 / B ラップトークンの供給 0
  [Aで100を固定、メッセージ送信中] A 金庫 locked 100 / B ラップトークンの供給 0
  発行のメッセージ：中継成功、status 1
  [Bで100を発行] A 金庫 locked 100 / B ラップトークンの供給 100
  alice B 残高 100
  [Bで40を燃やす、メッセージ送信中] A 金庫 locked 100 / B ラップトークンの供給 60
  解放のメッセージ：中継成功、status 1
  [Aで40を解放] A 金庫 locked 60 / B ラップトークンの供給 60
  alice A 残高 240
```

| とき | A 金庫のlocked | B ラップトークンの供給 |
|---|---|---|
| 開始 | 0 | 0 |
| Aで100を固定（送信中） | 100 | 0 |
| Bで100を発行 | 100 | 100 |
| Bで40を燃やす（送信中） | 100 | 60 |
| Aで40を解放 | 60 | 60 |

突き合わせの式は、受け取る側の供給 ≤ 送る側のlockedで、差は送信中のメッセージである。lockedはチェーンAで、totalSupplyはチェーンBで、`cast call`1回で誰でも読める。

### 試すときの注意

- lockの前に、aliceが`TKA.approve(金庫, 100)`をする。lockの中のtransferFromは、msg.sender（alice）のお金だけを金庫自身に移す。燃やすときはWrappedTokenのburnFromをMinterだけが呼ぶので、承認はいらない。
- 金庫の相手は（57002、Minter）、Minterの相手は（57001、金庫）で、setPeerは一度だけできる。相手をあとで変えられると、その鍵がもう一つの鍵になる。
- ラップトークンを発行する道はWrappedToken.mint ← Minter ← endpoint ← 検証の枠で、元のトークンを解放する道はLockBox ← endpoint ← 検証の枠である。発行する側の検証が破られると金庫にないラップトークンが発行され（供給 > locked）、解放する側の検証が破られると金庫が空になる。
- Minterのコードには1日の上限と停止の行がある。この実習では1日の上限を1000と多めに与えたので、引っかからない。
- 二つのチェーンのデモはaliceが自分自身に、テストはaliceがbobに固定し、bobがaliceに燃やす。
- デモのアドレスは、デプロイの順番を変えると変わる。

| | 受け取る側で受け取るもの | 値を支えるもの | 破られると残るもの | 遅れる場合 |
|---|---|---|---|---|
| ロックアップ・ミント | ラップトークン | 送る側の金庫に固定されたトークン | 空の金庫、裏づけのないラップトークン | 中継・検証が動かないとき |
| 発行体が直接 | 発行体の元のトークン | 発行体 | 発行体の鍵で発行されたトークン | 中継・検証が動かないとき |
| 流動性のプール | 受け取る側のプールの本物のトークン | プールに入れておいたお金 | 空になっていくプール | 受け取る側のプールが足りないとき |

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンや公式ドキュメントが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka、fuzz runs 256・seed 0x2a | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0、`token/ERC20/ERC20.sol`（`_balances`、`_mint`、`_burn`） | 2026-10-21 |
| 発行体が直接発行して燃やす公開ドキュメントの例 | Circle CCTP（"burn-and-mint"）。名前だけ、対応チェーン・上限・手数料なし | 2026-10-21 |
| デモのアドレス | A TKA 0xDc64…F6C9、A 金庫0x5FC8…5707、B Minter 0xa513…C853、B wTKA 0x9bd0…88b5 | 2026-10-21 |
| デモ・テストの1日の上限 | Minter dailyCap 1000 | 2026-10-21 |
| AssetsTestのガス | burnThenUnlock 698,846 / lockThenMint 445,385 / onlyMinterMints 33,955 / peerSetOnce 64,037 / poolPaysFromLiquidity 553,069 / poolShortFailsThenRetry 656,929 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ステーブルコインの発行体がチェーンごとに発行する方式の種類の分類 | [第200講](../../part13/lecture200/) |
| プールの価格・手数料の曲線 | [第194講](../../part13/lecture194/)、[第195講](../../part13/lecture195/)、[第196講](../../part13/lecture196/) |
| ラップトークンを担保として受け取るとき | [第211講](../../part14/lecture211/) |
| 流動性の提供者の報酬の設計 | 扱わない |

出典と参考資料は[reference.md](reference.md)にまとめた。
