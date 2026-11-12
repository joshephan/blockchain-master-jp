# 第179講 ブリッジの乗っ取り

第11部 推奨事項：敵対的環境とバージョン履歴・第46章 軸4・権限と鍵

[← 第178講](../../part11/lecture178/) | [第11部 目次](../) | [第180講 →](../../part11/lecture180/)

## この講義の問い

別のチェーンで起きたことを、こちらのチェーンはどうやって知るのか。署名が正しければ、そのメッセージは本物なのか。署名のしきい値は、いつしきい値でなくなるのか。

## 実習資料

### 準備

二つのプロジェクトを使う。`guards`は別のチェーンから来た出金リストを受け取る側のトイToyInboxを入れたFoundryプロジェクトで、forge-stdとOpenZeppelin Contracts 5.4.0（ECDSA、MessageHashUtils、MerkleProof）が必要である。`market`は通しプロジェクトMarketのこの講義のバージョンである。srcは前のバージョンのままで、テストファイル`test/NoSig.t.sol`を一つだけ足した。forge-stdが必要である。anvilと外部への接続なしに、forgeの中だけで動く。

ToyInboxは受け取る側（守る側）のコントラクトで、本物のトークンなしに処理した金額を`released`に書くだけである。テスト用の鍵はforgeのテストの中の小さな数（0xA11CE、0xB0B、0xC0FFEE、0xBAD）だけである。ブリッジ事件の手口は扱わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/guards/foundry.toml](code/guards/foundry.toml) | solc 0.8.30、optimizer・via-IRオン、OpenZeppelinのremapping、fuzz seedを固定 |
| [code/guards/src/Inbox179.sol](code/guards/src/Inbox179.sol) | ToyInbox：バリデーター三人のうち二人、チェーン番号とコントラクトのアドレスを含めた`rootDigest`、署名者の昇順を確かめる`acceptRoot`、マークル証明で一件ずつ処理する`release` |
| [code/guards/test/Inbox179.t.sol](code/guards/test/Inbox179.t.sol) | Inbox179Testの七つ：しきい値に届かない、バリデーター外の署名、同じ署名者が二回、別のチェーン番号の署名、受け付けていないルート、一度だけ処理、ルートにない金額 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/) | Marketの本体（前のバージョンのまま） |
| [code/market/test/NoSig.t.sol](code/market/test/NoSig.t.sol) | この講義で足したテスト：MarketのランタイムのSTATICCALL命令の数が0 |
| [code/market/test/](code/market/test/) | このバージョンまでに積み重なった残りのテスト（`Keys.t.sol`を含む） |

### 実行結果

`guards`で`forge test --offline --match-contract Inbox179Test -vvv`：

```
Ran 7 tests for test/Inbox179.t.sol:Inbox179Test
[PASS] test_otherChainSigRejected() (gas: 64358)
[PASS] test_outsiderSigRejected() (gas: 58462)
[PASS] test_releaseOnce() (gas: 208496)
[PASS] test_rootNeedsThreshold() (gas: 48951)
[PASS] test_sameSignerTwiceRejected() (gas: 59532)
[PASS] test_unknownRootRejected() (gas: 41799)
[PASS] test_wrongAmountRejected() (gas: 117501)
Suite result: ok. 7 passed; 0 failed; 0 skipped
```

テスト用の鍵四つとアドレス（アドレスの昇順）：

| 鍵（forgeのテストの中でだけ） | アドレス | 役割 |
|---|---|---|
| 0xB0B | 0x0376…473c | バリデーター |
| 0xBAD | 0x63f9…A869 | バリデーター外 |
| 0xA11CE | 0xe05f…cFF7 | バリデーター |
| 0xC0FFEE | 0xF5A5…50a4 | バリデーター |

| テスト | 出した署名またはやること | 結果 |
|---|---|---|
| rootNeedsThreshold | 0xA11CEの一つ | BelowThreshold(1) |
| outsiderSigRejected | 0xA11CE、0xBAD | NotValidator(0x63f9…A869) |
| sameSignerTwiceRejected | 0xA11CEを二回 | SignersNotSorted(0xe05f…cFF7) |
| otherChainSigRejected | チェーン番号1で作った二つ | NotValidator(0xbF64…6CCb) |
| unknownRootRejected | 受け付けていないルートでrelease | UnknownRoot |
| releaseOnce | 同じ件を二回release | released 100、二回目はAlreadyProcessed |
| wrongAmountRejected | ルートにない金額1000 | BadProof |

`test_otherChainSigRejected`の`-vvvv`のトレース。本物のバリデーターの鍵二つ（0xA11CE、0xB0B）でチェーン番号1のダイジェストに署名したが、受け取る側は31337を入れてダイジェストを計算するので、復元されたアドレスはバリデーター外である。

```
├─ [0] VM::chainId(1)
├─ [464] ToyInbox::rootDigest(0x91bf1a9a…0c15433) [staticcall]
│   └─ ← [Return] 0x5a729cf6fcbb5817bdc65b267ffe643e7effa3d5102f6533c5faa569e7196ad7
├─ [0] VM::chainId(31337 [3.133e4])
├─ [31658] ToyInbox::acceptRoot(0x91bf1a9a…0c15433, [0x3ba3a53d…, 0xa7c22233…])
│   ├─ [3000] PRECOMPILES::ecrecover(0x3ef287429b10137fa7b6f3234bb0e1a084da0a9c64eaee8e8135233dc8a20bfd, 27, …)
│   │   └─ ← [Return] 0xbF641676Aa941109CF5AD5f62ab3c82CFA526CCb
│   └─ ← [Revert] NotValidator(0xbF641676Aa941109CF5AD5f62ab3c82CFA526CCb)
├─ [2391] ToyInbox::acceptedRoot(0x91bf1a9a…0c15433) [staticcall]
│   └─ ← [Return] false
```

ルート・証明のテスト三つのトレース（上からunknownRootRejected、releaseOnce、wrongAmountRejected）。リーフA（alice、100、nonce 1）は0xdd8c…91a2、リーフB（bob、50、nonce 2）は0xc988…05b9、ルートは0x91bf…5433である。

```
├─ [26040] ToyInbox::release(alice: [0x328809Bc…aFdac6], 100, 1, 0x91bf1a9a…0c15433, [0xc98879ac…1705b9])
│   └─ ← [Revert] UnknownRoot(0x91bf1a9a6c1d61d2d79e66398663752e09689634f19486ef482f5079f0c15433)

├─ [70932] ToyInbox::release(alice: [0x328809Bc…aFdac6], 100, 1, 0x91bf1a9a…0c15433, [0xc98879ac…1705b9])
├─ [2508] ToyInbox::released(alice: [0x328809Bc…aFdac6]) [staticcall]
│   └─ ← [Return] 100
├─ [28563] ToyInbox::release(alice: [0x328809Bc…aFdac6], 100, 1, 0x91bf1a9a…0c15433, [0xc98879ac…1705b9])
│   └─ ← [Revert] AlreadyProcessed(0xdd8c628a2de33acc08cd7afea047b0cd97c168d677c7b1393e51e3eee32791a2)

├─ [26371] ToyInbox::release(alice: [0x328809Bc…aFdac6], 1000, 1, 0x91bf1a9a…0c15433, [0xc98879ac…1705b9])
│   └─ ← [Revert] BadProof()
```

`market`のsrcで署名・証明に使う言葉を探した`grep -rnE "ecrecover|ECDSA|Merkle|signature|chainid|staticcall" src | wc -l`の結果は`0`である。続いて`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract "NoSigTest|KeysTest" -vvv`：

```
Ran 6 tests for test/Keys.t.sol:KeysTest
[PASS] test_adminIsMultisig() (gas: 21922)
[PASS] test_frozenStillWithdraws() (gas: 428326)
[PASS] test_lostKeyFrozenStillWithdraws() (gas: 433327)
[PASS] test_multisigFreezes() (gas: 355083)
[PASS] test_oneKeyCannotFreeze() (gas: 246223)
[PASS] test_signerAloneNotAdmin() (gas: 33118)
Ran 1 test for test/NoSig.t.sol:NoSigTest
[PASS] test_noStaticcall() (gas: 505539)
Ran 2 test suites: 7 tests passed, 0 failed, 0 skipped (7 total tests)
```

このバージョン全体の`forge test --offline`は40スイート111個が通る。

### 試すときの注意

- 受け取る側が確かめるのは署名だけである。署名はその鍵で署名したことだけを語り、鍵を誰が握っていたかと、向こうのチェーンで本当に起きたかは語らない。
- `rootDigest`に入れた値ごとに防ぐものがある。`block.chainid`は別のチェーンの同じコントラクトでの使用を、`address(this)`は同じチェーンの別のコントラクトでの使用を、`root`は別の出金リストを防ぐ。
- 署名者のアドレスを昇順で受け取れば、直前の署名者一人（`last`）と比べるだけで、同じ署名者を二回数えない。すでに数えた署名者をマッピングに書くと、署名ごとにストレージの書き込みと消去がかかる。
- OpenZeppelinのECDSAの`recover`は、大きい側の半分のs値とaddress(0)の復元を拒否する。`ecrecover`は失敗しても差し戻さず、address(0)を返す。
- `leafOf`はハッシュを二回かけて、リーフと内側のノードを区別する。MerkleProofの原文が64バイトのリーフ値を避けるよう警告している。リーフにnonceがないと、同じ人の同じ金額の二件が同じリーフになり、二件目は永遠に受け取れない。
- 確認の順番は、受け付けたルートか、証明がルートまで上がるか、処理済みの件か、の順である。ルートに何が入っているかは署名のしきい値が決めるので、UnknownRootの確認が証明の確認より先である。
- 確認の行で防げないもの：しきい値分の鍵が一か所にあって一緒に奪われること（七つのうち四つが一台のサーバーにあれば鍵一つと同じ）、署名者がまだひっくり返りうるブロックを見て署名すること、バリデーターの鍵をなくしたときの差し替え（ToyInboxは新しくデプロイしなければならない）。
- `test_noStaticcall`がSTATICCALLを数える理由は、ecrecoverのようなプリコンパイルをSTATICCALLで呼ぶからである。Marketが外へ呼ぶtransfer・transferFromはCALLなので、この数には入らない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| 事件の年 | Poly Network 2021、Ronin 2022、Wormhole 2022 | 2026-10-21 |
| Foundry（forge・cast） | 1.8.3 (cae51ad4) | 2026-10-21 |
| solc | 0.8.30。guards・marketともにoptimizerオン（runs 200）、via-IRオン、evm osaka。guardsはfuzz runs 256、seed 0x2a | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0 | 2026-10-21 |
| forgeのテストのチェーン番号 | 31337（テストの中でvm.chainId(1)に変えてから戻す） | 2026-10-21 |
| テストのガス（guards） | otherChainSigRejected 64,358 / outsiderSigRejected 58,462 / releaseOnce 208,496 / rootNeedsThreshold 48,951 / sameSignerTwiceRejected 59,532 / unknownRootRejected 41,799 / wrongAmountRejected 117,501 | 2026-10-21 |
| テストのガス（market） | adminIsMultisig 21,922 / frozenStillWithdraws 428,326 / lostKeyFrozenStillWithdraws 433,327 / multisigFreezes 355,083 / oneKeyCannotFreeze 246,223 / signerAloneNotAdmin 33,118 / noStaticcall 505,539 | 2026-10-21 |
| テストのアドレス | 鍵0xA11CE・0xB0B・0xC0FFEE・0xBAD → 0xe05f…cFF7・0x0376…473c・0xF5A5…50a4・0x63f9…A869、チェーン番号1で作った署名の復元アドレス0xbF64…6CCb。テスト用の鍵を変えると変わる | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 証明の検証を組み立てる場所（ライトクライアント、ルートを誰が上げるか） | [第212講](../../part14/lecture212/) |
| 署名メッセージに入れる値一般（使用番号、締め切り、ドメイン） | [第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| 同じ形のログを信じた事件 | [第212講](../../part14/lecture212/) |
| 事件の経緯 | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| ブリッジで渡ってきたトークンを上場するときに検討すること | [第194講](../../part13/lecture194/)〜[第199講](../../part13/lecture199/) |
| 中央の点の行の四つの欄をまとめて層ごとに見る | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
