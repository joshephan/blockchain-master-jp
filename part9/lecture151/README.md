# 第151講 アクセス制限パターン

第9部 最適化と規律・第39章 共通パターン

[← 第150講](../../part9/lecture150/) | [第9部 目次](../) | [第152講 →](../../part9/lecture152/)

## この講義の問い

アクセス制限は何を防ぎ、何を防げないのか。誰で確認し、その座をどう渡したり空けたりするかによって、何が変わるのか。

## 実習資料

### 準備

公式ドキュメントCommon PatternsのRestricting Accessの例AccessRestriction（ドキュメント137〜234行）を空のFoundryプロジェクト（`demo`、evm osaka、optimizerオフ）にそのまま移し、比較用のコントラクト四つとテスト八つを足して`forge test`で見る。anvilは使わない。テストにはforge-stdが必要である（`lib/forge-std`）。OpenZeppelin Contracts 5.4.0の`Ownable.sol`・`Ownable2Step.sol`は読むだけである。

通しプロジェクトMarketは第150講のバージョンから始める。第151講のバージョンはコードが第150講のバージョンと同じで、権限の一覧をテストに移した`test/Access.t.sol`を足した。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka |
| [code/demo/src/AccessRestriction.sol](code/demo/src/AccessRestriction.sol) | ドキュメント137〜234行の例そのまま（onlyBy・onlyAfter・costsのmodifier、changeOwner、disown、forceOwnerChange） |
| [code/demo/src/Extra151.sol](code/demo/src/Extra151.sol) | 受け取ったcalldataを渡すRelay、onlyByを`tx.origin`に変えたOriginGate、本体ですぐreturnするCostsReturn、払い戻しを拒否するNoRefund |
| [code/demo/test/Access151.t.sol](code/demo/test/Access151.t.sol) | テスト八つ |
| [code/market/foundry.toml](code/market/foundry.toml) | 第150講のバージョンと同じ |
| [code/market/src/](code/market/src/) | Market第151講のバージョン（第150講のバージョンとコードは同じ、バージョン説明のコメントを1行追加） |
| [code/market/test/Access.t.sol](code/market/test/Access.t.sol) | 状態を変える関数五つを管理者とbobで呼んでみる`test_permissionTable`、`vm.prank(bob, admin)`でtx.originだけが管理者の呼び出しを見る`test_originIsNotChecked` |
| [code/market/test/](code/market/test/) | テスト22ファイル（71個のテスト） |
| [code/immset/src/Market.sol](code/immset/src/Market.sol) | MarketBaseに`setAdmin(address a) external onlyAdmin { admin = a; }`を足したコピー（ビルドが失敗） |

### 実行結果

デモのテストの`forge test -vv`：

```
Ran 8 tests for test/Access151.t.sol:Access151Test
[PASS] test_changeOwnerBothWays() (gas: 68431)
[PASS] test_conditionAlwaysFalse() (gas: 38698)
[PASS] test_disownLocksForever() (gas: 94746)
[PASS] test_disownThenBuyBack() (gas: 92877)
[PASS] test_forceOwnerChangeRefund() (gas: 72314)
Logs:
  bob balance after 1000000000000000000
  contract balance 200000000000000000000
[PASS] test_refundToRejecterBlocks() (gas: 116190)
[PASS] test_relaySenderAndOrigin() (gas: 87046)
[PASS] test_returnStillRefunds() (gas: 77028)
Logs:
  bob balance after return 2000000000000000000
Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 1.31ms (4.10ms CPU time)
```

- `test_changeOwnerBothWays`：bobは`Unauthorized`で止められ、ownerは通る。
- `test_disownLocksForever`：6週間前のdisownは`TooEarly`、6週間後のdisownはownerを0にし、そのあとのchangeOwnerは誰も通らない。
- `test_disownThenBuyBack`：空けた座も、forceOwnerChangeに200イーサを払えば誰でももう一度手に入れる。
- `test_forceOwnerChangeRefund`：201イーサを払うと、costsのmodifierが余った1イーサを返す。
- `test_conditionAlwaysFalse`：forceOwnerChangeの`return`の行の条件の形`x & 0 == 1`は、`&`が`==`より先に結びついて`0 == 1`になるので、常に偽である。その行は一度も実行されない。
- `test_returnStillRefunds`：本体ですぐreturnしても、costsのmodifierの`_;`のあとの行が実行され、3イーサのうち2イーサが返ってくる。
- `test_refundToRejecterBlocks`：払い戻しを拒否するNoRefundが201イーサで買うと、余ったお金を返すcallが失敗して関数全体が巻き戻り、ちょうど200イーサで買うと通る。

`test_relaySenderAndOrigin`を`-vvvv`で見たトレース（後半）。同じowner（0xA11cE）がRelayを経由して呼ぶと、ドキュメントのバージョンは`Unauthorized`で止められ、`tx.origin`で確認するOriginGateはownerがbobに変わる：

```
    ├─ [28433] Relay::forward(AccessRestriction: [0x6b182f1488E8EfEb2Eb298155ed5Bd7FF8A14042], 0xa6f9dae10000000000000000000000000000000000000000000000000000000000000b0b)
    │   ├─ [2697] AccessRestriction::changeOwner(0x0000000000000000000000000000000000000B0b)
    │   │   └─ ← [Revert] Unauthorized()
    │   └─ ← [Revert] Unauthorized()
    ├─ [0] VM::prank(0x00000000000000000000000000000000000A11cE, 0x00000000000000000000000000000000000A11cE)
    │   └─ ← [Return]
    ├─ [31782] Relay::forward(OriginGate: [0x55EB3F05725579313D96873983F9d1b00196629c], 0xa6f9dae10000000000000000000000000000000000000000000000000000000000000b0b)
    │   ├─ [5687] OriginGate::changeOwner(0x0000000000000000000000000000000000000B0b)
    │   │   └─ ← [Stop]
    │   └─ ← [Return] 0x
    ├─ [2485] OriginGate::owner() [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000B0b
    ├─ [2529] AccessRestriction::owner() [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000000000000000A11cE
```

immutableのadminを渡す関数を足したコピーはビルドされない：

```
Error (1581): Cannot write to immutable here: Immutable variables can only be initialized inline or assigned directly in the constructor.
  --> src/Market.sol:92:9:
   |
92 |         admin = a;
   |         ^^^^^
```

Market第151講のバージョンの`forge test --match-contract AccessTest`：

```
[PASS] test_originIsNotChecked() (gas: 35962)
[PASS] test_permissionTable() (gas: 436538)
```

bobで呼ぶと、addAsset・setStatusの二つだけが`NotAdmin(bob)`で止められ、deposit・withdraw・withdrawAllの三つは通る。管理者は五つすべて通る。tx.originだけが管理者の呼び出しも`NotAdmin(bob)`である。

第151講のバージョンのサイズ（runtime / creation）はdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931、テスト71個が通り、コミット前の確認は`ci ok`である。レシートのgasUsedはデプロイ760,316、addAsset 92,656、deposit 127,515、withdraw 57,448、setStatus 45,001 / 23,089、失敗26,264で、第150講のバージョンと同じである。

### 試すときの注意

- `private`やアクセス制限は、ほかのコントラクトのコードが名前で呼べないようにするだけである。ストレージの欄の値は`cast storage`で誰でも読める。
- ドキュメントのforceOwnerChangeの条件`uint160(owner) & 0 == 1`は、`&`が先に結びつくので常に偽である。
- modifierの`_;`のあとの行は、本体がreturnしても実行される。本体が巻き戻るときだけ実行されない。0.4.0より前は飛ばされることがあった（ドキュメント204〜209行）。
- OpenZeppelin 5.4.0のOwnableのonlyOwnerは`_checkOwner()`の1行を呼び、`_checkOwner`はvirtualである。Marketの`_checkAdmin`はvirtualではない。
- Marketのadminはimmutableなので、渡したり空けたりする関数を置けない。入れるにはストレージの欄に変える必要があり、スロットマップも一緒に変わる。
- Marketのソースでは、権限のチェックはすべて`msg.sender`で行い、`tx.origin`は使わない（`grep`で確認）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。コンパイラとライブラリのバージョンが変わると、数字と行番号が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ用プロジェクトはevm_version osaka、optimizerは既定値（オフ）。Market第151講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyがデフォルトの経路 + optimizerオン、debugがデフォルトの経路でoptimizerオフ | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3（Commit `cae51ad`） | 2026-10-20 |
| 公式ドキュメントの版 | v0.8.36 common-patterns.rst。110〜132（Restricting Accessの冒頭）、137〜234（AccessRestriction）、204〜209（costsのコメント、0.4.0より前の動作）、236〜238（次の例に移る行） | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0。`contracts/access/Ownable.sol` 38〜43 コンストラクタ、48〜51 onlyOwner、63〜67 `_checkOwner`、76〜78 renounceOwnership、84〜89 transferOwnership、95〜99 `_transferOwnership` / `contracts/access/Ownable2Step.sol` 14〜17 説明、37〜42 コメント、43〜46 transferOwnership、60〜66 acceptOwnership / `contracts/utils/Context.sol` 17〜19 `_msgSender` | 2026-10-20 |
| 0.4.0より前のmodifierの動作 | ドキュメントの原文：`_;`のあとを飛ばすことができ、本体が`return`すると返金しなかった | 2026-10-20 |
| エラー番号（solc 0.8.30） | 1581 Cannot write to immutable here | 2026-10-20 |
| デモのテストのガス | changeOwnerBothWays 68431、conditionAlwaysFalse 38698、disownLocksForever 94746、disownThenBuyBack 92877、forceOwnerChangeRefund 72314、refundToRejecterBlocks 116190、relaySenderAndOrigin 87046、returnStillRefunds 77028 | 2026-10-20 |
| サイズ（runtime / creation） | 第151講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第151講のバージョンdefault `9a75390f`、legacy `2da12a2c`、debug `9b351dc3`（第150講のバージョン`5a115f7a`、`1b0111a3`、`3bff1a01`） | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第151講のバージョンのデプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264。MockToken `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Market `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` | 2026-10-20 |
| テストのガス（.gas-snapshot） | `AccessTest:test_originIsNotChecked() (gas: 35962)`、`AccessTest:test_permissionTable() (gas: 436538)`、71行 | 2026-10-20 |
| 行番号 | 第151講のバージョンdebug deposit 0 src/Market.sol 164:33、NotActive 79行、`contract Market` 208行、`_checkAdmin` 91〜93行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | テストのアドレスbob `0x…0B0b`、0xA11CE、テストコントラクト`0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496`。ガスの測定はanvilのアカウント0番`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（公開されたテスト用の鍵） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| tx.originで確認するコードを狙う方法 | [第176講](../../part11/lecture176/) |
| 役割を複数に分けるアクセス制御（AccessControl） | [第176講](../../part11/lecture176/) |
| 管理者の鍵を複数人で分けて持つ（マルチシグのアドレスをadminに） | [第178講](../../part11/lecture178/) |
| 渡せる管理者の座とアップグレード | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 監査で管理者の関数と、空けた座を再び埋める道を見つける | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| 返金のcallを受け取る側のコードがすること | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/) |
| 常に偽の条件のようなデッドコードを見つける | [第183講](../../part11/lecture183/)、[第188講](../../part12/lecture188/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
