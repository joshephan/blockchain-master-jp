# 第175講 オンチェーンの乱数と緩和策

第11部 推奨事項：敵対的環境とバージョン履歴・第45章 軸2・順序の操作

[← 第174講](../../part11/lecture174/) | [第11部 目次](../) | [第176講 →](../../part11/lecture176/)

## この講義の問い

コントラクトの中で乱数を引けば、誰にもわからないのか。ブロックの値で引いた当選番号は、なぜ前もってわかるのか。引く前に結果を誰も決められないようにするにはどうするのか。

## 実習資料

### 準備

プロジェクトは二つある。`vulns`はブロックの値で番号を引くトイの抽選と、トイのコミット・リビールを置いた小さなプロジェクトで（本物のサービスではない）、`market`は通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）のsrcをそのまま置き、確認用テスト`test/Order45.t.sol`を足したものである。どちらもforge-stdが必要である（`lib/forge-std`）。anvilと外部への接続はない。当選番号を前もって計算して出す側のコントラクトとそのテストは載せない。

### コード

| ファイル | 内容 |
|---|---|
| [code/vulns/foundry.toml](code/vulns/foundry.toml) | solc 0.8.30、optimizerオン（200）・via-IRオン・evm osaka、fuzz runs 256・seed 0x2a |
| [code/vulns/src/Random175.sol](code/vulns/src/Random175.sol) | ブロックの値（prevrandao、timestamp）で番号を引くBadLottery、秘密をハッシュで封じておいて一緒に開けるCommitReveal |
| [code/vulns/test/Random175.t.sol](code/vulns/test/Random175.t.sol) | 違う番号は差し戻される、まだないブロックのハッシュは0、コミット・リビールの流れ。三つ（番号を前もって計算する側のテストは除いた抜粋） |
| [code/vulns/test/Random175Extra.t.sol](code/vulns/test/Random175Extra.t.sol) | 同じブロックなら誰が読んでも同じ番号、ブロックが変われば違う番号、最後に開ける人が二つの結果を両方知るケース。三つ |
| [code/market/test/Order45.t.sol](code/market/test/Order45.t.sol) | Marketの順番の確認テスト四つ |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 乱数を読む行がない。block.timestampは利息の経過時間にだけ使う |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定 |
| [code/market/src/](code/market/src/)、[code/market/test/](code/market/test/) | Marketのソースとテストすべて |

### 実行結果

ブロックの値で引いた番号は、同じブロックの中では誰にとっても同じである（`forge test --offline --match-contract Random175ExtraTest -vvv`から選んだ行）。同じブロックで抽選と同じ計算を先に走らせると、当選番号217が前もってわかる：

```
[PASS] test_nextBlockNewNumber() (gas: 15874)
Logs:
  this block: 217
  next block: 609
[PASS] test_sameBlockSameNumber() (gas: 23624)
Logs:
  block: 1
  timestamp: 1
  prevrandao: 0
  alice sees: 217
  bob sees: 217
```

違う番号は差し戻されるので、前もって計算する側は負ける回に参加しない（`--match-test test_revertOnMiss -vvvv`から選んだ行）：

```
[PASS] test_revertOnMiss() (gas: 11009)
    ├─ [357] BadLottery::draw() [staticcall]
    │   └─ ← [Return] 217
    ├─ [0] VM::expectRevert(Missed())
    │   └─ ← [Return]
    ├─ [401] BadLottery::play(216) [staticcall]
    │   └─ ← [Revert] Missed()
```

今のブロックのハッシュはまだないので0である（`--match-test test_futureHashZero -vvvv`から選んだ行）：

```
[PASS] test_futureHashZero() (gas: 4377)
    ├─ [208] BadLottery::futureHash() [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
```

コミット・リビール（`--match-test test_commitRevealFlow -vvvv`から選んだ行）。二人がハッシュだけを上げているあいだseedは0で、違う秘密は`BadReveal`で差し戻され、二人とも開けたあとのseedは111 XOR 222 = 177である：

```
[PASS] test_commitRevealFlow() (gas: 293978)
Logs:
  result: 177
    ├─ [46311] CommitReveal::commit(0x4d4832c268fb7ab7ca3c26fe13122ac49a9a754fe65438cbf4232b13c38aedbf)
    ├─ [46311] CommitReveal::commit(0xf656b75608b3688c0aef82cb194726094db5b21ecabb9b4549c5872bce2f4610)
    ├─ [2278] CommitReveal::seed() [staticcall]
    │   └─ ← [Return] 0
    ├─ [23784] CommitReveal::reveal(999)
    │   └─ ← [Revert] BadReveal()
    ├─ [90149] CommitReveal::reveal(111)
    ├─ [55949] CommitReveal::reveal(222)
    ├─ [2300] CommitReveal::revealCount() [staticcall]
    │   └─ ← [Return] 2
    ├─ [2278] CommitReveal::seed() [staticcall]
    │   └─ ← [Return] 177
```

コミット・リビールに残るもの。最後に開ける人は、他人の秘密が開いたあと、自分が開けるときと開けないときの結果を両方知っている（`--match-test test_lastRevealerSeesBoth -vvv`）：

```
[PASS] test_lastRevealerSeesBoth() (gas: 274465)
Logs:
  if bob stays closed: 111
  revealCount: 1
  if bob reveals: 177
  revealCount: 2
```

Marketは乱数を読まない（`grep -rnE "prevrandao|blockhash|difficulty|coinbase|random" src | wc -l`、次に`grep -rn "block\.timestamp" src`）：

```
0
src/Market.sol:210:        return block.timestamp - p.lastUpdate;
src/MarketMath.sol:33:        self.lastUpdate = uint64(block.timestamp);
src/MarketMath.sol:41:        self.lastUpdate = uint64(block.timestamp);
```

`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract Order45Test -vvv`は四つすべてが通り、同じ変数で回した`forge test --offline`全体は101個が通る。

### 試すときの注意

- 抜粋した`Random175.t.sol`はテスト関数が三つなので、同じ環境で`test_revertOnMiss`のガスが11,009ではなく10,970と出る。
- forgeのテストはブロック1、timestamp 1、prevrandao 0から始まる。そのため、上の番号217は毎回同じである。
- `blockhash`は最近の256ブロックだけを返す。今のブロック、これから来るブロック、それより古いブロックは0である。
- EVM Parisから、`block.difficulty`はprevrandaoの古い名前として動く（EIP-4399）。
- テストの中のトイのアドレスは、デプロイの順番によって変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンや合意ルールが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30。vulns・marketともにoptimizerオン（runs 200）・via-IRオン・evm osaka。vulnsは`[fuzz] runs=256 seed=0x2a` | 2026-10-21 |
| Solidityのドキュメント | v0.8.36。`units-and-global-variables.rst` 76（blockhashは256ブロック）・88（prevrandao）・89（timestamp）・109〜117（timestamp・blockhashを乱数として信じないこと）・119〜121（最近の256ブロックの外は0）、`security-considerations.rst` 41〜47（Private Information and Randomness） | 2026-10-21 |
| prevrandao | EIP-4399、EVM Parisから`block.difficulty`がprevrandaoの古い名前として動く | 2026-10-21 |
| blockhashの範囲 | 最近の256ブロック、今のブロック・これから来るブロック・それより古いブロックは0 | 2026-10-21 |
| メインネットのブロックの時刻のルール | プルーフ・オブ・ステーク以降、ブロックの時刻はスロットの時刻で決まる。提案者が動かせる範囲は合意ルールに従う | 2026-10-21 |
| forgeのテストのブロック | ブロック1、timestamp 1、prevrandao 0から始まる | 2026-10-21 |
| テストのガス（vulns） | commitRevealFlow 293,978 / futureHashZero 4,377 / revertOnMiss 11,009 / lastRevealerSeesBoth 274,465 / nextBlockNewNumber 15,874 / sameBlockSameNumber 23,624 | 2026-10-21 |
| テストのガス（market） | depositWithdrawOneToOne 219,780 / elapsedReadsBlockTimestamp 151,799 / freezeBeforeWithdrawBlocks 208,491 / withdrawBeforeFreezePasses 233,010 | 2026-10-21 |
| トイのアドレス（テストの中） | BadLottery・CommitReveal 0x5615dEB7…23b72f。デプロイの順番によって変わる | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| コミット・リビールを使うオークション・抽選の設計（リビールの締め切り、保証金、開けなかった人の扱い） | [第206講](../../part14/lecture206/) |
| チェーンの外から乱数を受け取る道とその信頼の前提 | [第206講](../../part14/lecture206/) |
| ストレージに置いたシードがスロットから読まれること | [第95講](../../part6/lecture95/)・[第97講](../../part6/lecture97/) |
| 提案者がtimestampを動かせる範囲の現在のルール | 付録（時効性のシート） |
| Marketにオラクル・清算をつけるときの価格の設計 | [第194講](../../part13/lecture194/)〜[第199講](../../part13/lecture199/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
