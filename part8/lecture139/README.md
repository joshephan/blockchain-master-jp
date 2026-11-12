# 第139講 オプティマイザの構造とステップごとの動作

第8部 コンパイラと内部構造・第34章 オプティマイザ

[← 第138講](../../part8/lecture138/) | [第8部 目次](../) | [第140講 →](../../part8/lecture140/)

## この講義の問い

`--optimize`という一つのフラグのうしろで、どんなステップがどんな順序で動き、各ステップはバイトコードの何を変えるのか。その変化はソースマップとガスにどう現れるのか。

## 実習資料

### 準備

通しプロジェクトMarketの第139講のバージョン（第138講のバージョンとコードが同じで、バージョンを説明するコメントを1行だけ足したバージョン）、optimizerのプロファイルを四つ置いたデモのプロジェクト（`demo`）、solcを直接呼んでビルドする小さなコントラクト（`solc`）を使う。solc 0.8.30、Foundry 1.8.3で、forge-stdが必要である（`lib/forge-std`）。Marketの設定ごとの比較は、第139講のバージョンをコピーして、foundry.tomlのoptimizerの欄と`[profile.default.optimizer_details]`だけを変えたバージョンでビルドする。ガスは、バージョンごとに新しいanvilを立ち上げてブロック間隔を1秒に固定し、アカウント0番でデプロイしてから同じ順序で送ったレシートのgasUsedである。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | プロファイル四つ: default（optimizerを切る）、opt（入れる）、nodedup（入れる + `deduplicate = false`）、noloop（切る + `simpleCounterForLoopUncheckedIncrement = false`） |
| [code/demo/src/Dedup139.sol](code/demo/src/Dedup139.sol) | 末尾が同じリバート二つ（`Low`、`Paused`） |
| [code/demo/src/Loop139.sol](code/demo/src/Loop139.sol) | `for (uint256 i = 0; i < n; ++i)`の合計 |
| [code/demo/test/Dedup139.t.sol](code/demo/test/Dedup139.t.sol) | `expectRevert`なしでわざと失敗させる`test_low`（Backtraceの行を見るテスト） |
| [code/demo/test/Loop139.t.sol](code/demo/test/Loop139.t.sol) | sum(100)・sum(0)を関数の中の`gasleft()`の差で測るテスト |
| [code/solc/DocOpt139.sol](code/solc/DocOpt139.sol)、[DocOpt139u.sol](code/solc/DocOpt139u.sol) | ドキュメントのopcodeオプティマイザの例を関数一つで包んだバージョンと、`unchecked`のバージョン |
| [code/solc/Runs139.sol](code/solc/Runs139.sol) | 大きな定数一つと関数八つ、runsによって変わるもの |
| [code/solc/Opt124.sol](code/solc/Opt124.sol)、[Deep.sol](code/solc/Deep.sol)、[Store.sol](code/solc/Store.sol) | Yulのステップの順序の文字列を変えてみるファイル |
| [code/fail/test/Fail.t.sol](code/fail/test/Fail.t.sol) | わざと失敗するテスト二つ（deposit 0、withdraw 150）。`code/market/test/`にコピーしてBacktraceを見る |
| [code/market/](code/market/) | Market 第139講のバージョン（foundry.toml、src、test）。テスト60個 |

### 実行結果

MarketのYulの三つのバージョン（`forge inspect src/Market.sol:Market …`を`wc -l`、`grep -c "function "`）。

| 出力 | 行数 | `function`の数 |
|---|---|---|
| `ir` | 3,072 | 297 |
| `irOptimized`、optimizerを切る | 2,367 | 288 |
| `irOptimized`、optimizerを入れる | 881 | 12 |

ドキュメントの例DocOpt139と`unchecked`のバージョンのランタイム（solcのStandard JSON、runs 200）。

| バージョン | ランタイム | 命令 | SLOAD | KECCAK256 | JUMPI |
|---|---|---|---|---|---|
| DocOpt139 切る | 357バイト | 204 | 1 | 2 | 5 |
| DocOpt139 入れる | 247バイト | 126 | 1 | 1 | 5 |
| DocOpt139u 切る | 245バイト | 158 | 1 | 2 | 4 |
| DocOpt139u 入れる | 161バイト | 58 | 0 | 0 | 3 |

コンパイルのときにあらかじめ計算したスロット。

```
$ solc --asm --optimize DocOpt139.sol
      0x09
        /* "DocOpt139.sol":294:301  data[7] */
      0x870253054e3d98b71abec8fff9ebf8a15d167f15909091a800d4acaab9266d2b
        /* "DocOpt139.sol":294:305  data[7] = 9 */
      sstore
$ cast index uint256 7 0
0x870253054e3d98b71abec8fff9ebf8a15d167f15909091a800d4acaab9266d2b
```

DocOpt139uの入れたビルドは、`sstore`のすぐあとに1を返す（SLOAD・比較なし）。

Marketのランタイムの二つのビルドの命令の数（先頭から命令に分けて数える、runs 200）。

| Marketのランタイム（既定の経路） | optimizerを切る | optimizerを入れる |
|---|---|---|
| コードのバイト | 7,300 | 3,702 |
| 命令 / ソースマップの項目 | 3,933 / 3,932 | 2,317 / 2,316 |
| JUMPDEST / JUMP / JUMPI | 367 / 295 / 69 | 152 / 114 / 64 |
| REVERT / SLOAD / SSTORE | 30 / 38 / 11 | 31 / 33 / 10 |
| KECCAK256 / PUSH32 | 26 / 28 | 24 / 11 |

Dedup139のREVERT。

| ビルド | ランタイム | REVERT | `Low`の行（11行目）のREVERT | `Paused`の行（15行目）のREVERT |
|---|---|---|---|---|
| optimizerを切る | 803バイト | 7 | pc 390 | pc 270 |
| optimizerを入れる | 389バイト | 6 | なし | pc 223 |
| 入れる、`deduplicate`を切る | 396バイト | 7 | pc 276 | pc 226 |
| 切る、`deduplicate`だけを入れる | 712バイト | 4 | なし | pc 266 |

`solc --asm --optimize Dedup139.sol`で、二つのエラーが共有する末尾。

```
        /* "Dedup139.sol":321:330  Paused(s) */
    tag_23:
      mload(0x40)
      dup1
      swap2
      sub
      swap1
      revert
  …
        /* "Dedup139.sol":242:252  Low(x, 10) */
      tag_23
      jump
```

デモのプロジェクトでプロファイルごとに`forge test --match-path test/Dedup139.t.sol -vvvvv`。

```
$ forge test --offline --match-path test/Dedup139.t.sol -vvvvv
[FAIL: Low(1, 10)] test_low() (gas: 4982)
  at Dedup139.a (src/Dedup139.sol:11:28)
$ FOUNDRY_PROFILE=opt forge test --offline --match-path test/Dedup139.t.sol -vvvvv
[FAIL: Low(1, 10)] test_low() (gas: 3875)
  at Dedup139.a (src/Dedup139.sol:15:28)
$ FOUNDRY_PROFILE=nodedup forge test --offline --match-path test/Dedup139.t.sol -vvvvv
[FAIL: Low(1, 10)] test_low() (gas: 3863)
  at Dedup139.a (src/Dedup139.sol:11:28)
```

Market 第139講のバージョンのコピーでの、`Fail.t.sol`のwithdraw 150のBacktrace（リバートデータはどれも`InsufficientDeposit(0, 150)`）。

| バージョン | withdraw 150のBacktrace |
|---|---|
| optimizerを切る | `src/MarketMath.sol:38:35` |
| 入れる、runs 1 / 200 / 10000 | `src/Market.sol:67:51` |
| 入れる、cse・inliner・yul・constantOptimizer・peepholeを一つずつ切る | `src/Market.sol:67:51` |
| 入れる、`deduplicate`だけを切る | `src/MarketMath.sol:38:35` |
| 切る、`deduplicate`だけを入れる | `src/Market.sol:67:51` |

Market.solの67行目は`if (status != MarketStatus.Active) revert NotActive(status);`である。detailsの欄を一つずつ切ったMarketのサイズ（`forge build --sizes`、バイト、どのバージョンもテスト60個が通る）。

| Market | ランタイム | 作成のコード |
|---|---|---|
| 入れる（runs 200）、欄はそのまま | 3,755 | 4,013 |
| 入れる、`deduplicate`を切る | 4,075 | 4,333 |
| 入れる、`cse`を切る | 4,821 | 5,123 |
| 入れる、`inliner`を切る | 3,917 | 4,175 |
| 入れる、`yul`を切る | 4,284 | 4,626 |
| 入れる、`constantOptimizer`を切る | 4,569 | 4,891 |
| 入れる、`peephole`を切る | 4,797 | 5,082 |
| 切る、欄はそのまま | 7,353 | 7,931 |
| 切る、`peephole`だけを切る | 7,639 | 8,251 |
| 切る、`jumpdestRemover`だけを切る | 7,479 | 8,093 |
| 切る、`simpleCounterForLoopUncheckedIncrement`だけを切る | 7,359 | 7,937 |
| 切る、三つの欄をすべて切る | 7,746 | 8,380 |

欄の名前を間違えて書いたStandard JSON（`solc --standard-json`、Dedup139.sol）。

| 入力の`optimizer` | 終了コード | errors | contractsの欄 |
|---|---|---|---|
| `{"enabled": true, "details": {"deduplicat": false}}` | 0 | `Unknown key "deduplicat"` | なし |
| `{"enabled": true, "details": {"deduplicate": "no"}}` | 0 | `"settings.optimizer.details.deduplicate" must be Boolean` | なし |

欄を一つだけ書いても、メタデータには九つの欄と既定の順序の文字列全体が書かれる。

```
入力のoptimizer {"enabled": true, "runs": 200}
  メタデータのsettings.optimizer {"enabled": true, "runs": 200}
入力のoptimizer {"enabled": true, "runs": 200, "details": {"deduplicate": false}}
  メタデータのsettings.optimizer {"details": {"constantOptimizer": true, "cse": true,
    "deduplicate": false, "inliner": true, "jumpdestRemover": true, "orderLiterals": true,
    "peephole": true, "simpleCounterForLoopUncheckedIncrement": true, "yul": true,
    "yulDetails": {"optimizerSteps": "dhfoDgvulfnTUtnIfxa[r]EscLMVcul …", "stackAllocation": true}},
    "runs": 200}
```

Loop139（デモのプロジェクトのプロファイル、sum(100) = 4950は三つのビルドで同じ）。

| ビルド | ランタイム | sum(100)のガス |
|---|---|---|
| optimizerを切る（default） | 426バイト | 28,282 |
| 切る、カウンタのステップも切る（noloop） | 503バイト | 40,082 |
| optimizerを入れる（opt） | | 15,464 |

Runs139のruns三つ。

| runs | ランタイム | 大きな定数 | PUSH32 | ディスパッチャのGT |
|---|---|---|---|---|
| 1 | 270バイト | `shl(0xfc, 0x01)` | 0 | 0 |
| 200 | 284バイト | `shl(0xfc, 0x01)` | 0 | 1 |
| 10000 | 348バイト | PUSH32 `0x1000…000` | 1 | 2 |

Marketのruns四つ（レシートのgasUsed）。

| Market | 切る | runs 1 | runs 200 | runs 10000 |
|---|---|---|---|---|
| ランタイム（バイト） | 7,353 | 3,676 | 3,755 | 4,795 |
| デプロイ | 1,645,279 | 850,725 | 867,827 | 1,085,347 |
| addAsset 75 | 93,730 | 92,619 | 92,576 | 92,476 |
| deposit 100 | 130,478 | 128,364 | 128,297 | 128,202 |
| withdraw 30 | 59,911 | 58,144 | 57,856 | 57,707 |
| setStatus 1 | 45,732 | 45,178 | 45,224 | 45,209 |
| setStatus 0 | 23,820 | 23,266 | 23,312 | 23,297 |
| 失敗するdeposit 0 | 26,869 | 26,452 | 26,409 | 26,402 |

runs 1000000はランタイム4,795バイトで、10000と同じである。solc 0.8.30の既定のYulのステップの順序の文字列（メタデータの`yulDetails.optimizerSteps`）。

```
dhfoDgvulfnTUtnIfxa[r]EscLMVcul [j]Trpeulxa[r]cLgvifMCTUca[r]LSsTFOtfDnca[r]IulcscCTUtgvifMx[scCTUt] TOntnfDIulgvifMjmul[jul] VcTOcul jmul:fDnTOcmuO
```

Opt124を`solc --ir-optimized --optimize --yul-optimizations '…'`でビルドした出力（`wc -l`、`function`の数）: 既定55・0、`:` 192・30、`u:` 187・28、`i:` 261・30、`iTs:` 265・30、`dhfoDgvulfnTUtnIf:` 174・23。順序の文字列のエラー三つ（三つとも終了コード1）。

```
$ solc --ir-optimized --optimize --yul-optimizations 'Z' Opt124.sol
Error: Invalid optimizer step sequence in --yul-optimizations: 'Z' is not a valid step abbreviation
$ solc --ir-optimized --optimize --yul-optimizations 'a]' Opt124.sol
Error: Invalid optimizer step sequence in --yul-optimizations: Unbalanced brackets
$ solc --ir-optimized --yul-optimizations 'u' Opt124.sol
Error: --yul-optimizations is invalid with a non-empty sequence if Yul optimizer is disabled. Note that the empty optimizer sequence is properly denoted by ":".
```

順序ごとのランタイムは、Store（via-IR + optimizer）が既定186 / `:` 364、Market（via-IR + optimizer）が3,260 / 5,179、Market（既定の経路 + optimizer）が3,755 / 4,276バイトである。Deep（via-IR）のランタイムのmemoryguardは、optimizerを切ると`0x0380`（2,465バイト）、`--optimize`で`0x0360`（1,198バイト）、`--optimize --yul-optimizations ':'`で`0x0380`（1,457バイト）である。

Market 第139講のバージョンのビルドとテスト。

```
$ forge build --offline --force --sizes
| Market      | 7,353            | 7,931             | 17,223             | 41,221              |
$ forge test --offline
Ran 18 test suites …: 60 tests passed, 0 failed, 0 skipped (60 total tests)
$ FOUNDRY_PROFILE=ir forge test --offline
Ran 18 test suites …: 60 tests passed, 0 failed, 0 skipped (60 total tests)
```

### 試すときの注意

- 最適化は、コード生成、Yul、opcodeの三つの層で動く。既定の経路（legacy）のビルドは仕事がopcodeの層に集まり、via-IRはコントラクト全体をYulの層で直す。`--optimize`のフラグ一つが、opcodeオプティマイザとYulオプティマイザを一緒にオンにする。
- optimizerを入れると、末尾が同じリバートの尾を一つにまとめるステップ（`deduplicate`）のために、別の行から始まったリバートが同じREVERTで終わり、ソースマップが別の行を指す。リバートデータのエラーと行が合わなければ、optimizerを切ったビルドか、`deduplicate`だけを切ったビルドでもう一度回す。
- optimizerを切っても、peephole、jumpdestRemover、ループのカウンタのステップは動く。この三つまで切るには、detailsの欄に一つずつfalseを書く。
- Standard JSONは、欄の名前が間違っていても終了コード0で終わる。出力のJSONのerrorsの欄を確かめる。
- runsは最適化を何回回すかではなく、デプロイしたコードの命令一つが生涯で何回くらい実行されるかを見積もった値である。小さければコードを短く、大きければ呼び出しのガスを減らす方向に直す。
- ドキュメントとsolc 0.8.30が違うところ: ドキュメントは角かっこの入れ子はできないとしているが、0.8.30は`a[s[c]]`を受け付ける。ドキュメントはループのカウンタのステップをIRの経路の側に書いているが、既定の経路でもバイトが変わる（Loop139 426 / 503）。Standard JSONの注釈の順序の文字列の例`"dfDvulfnTUtnIf..."`は縮めた形である。

## 時効性のあるデータ

基準日時点の値。コンパイラ・ツールのバージョンやソースのコメントが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30（forgeが呼ぶときのevm_versionはosaka） | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| 既定のステップの順序の文字列（0.8.30） | `dhfoDgvulfnTUtnIfxa[r]EscLMVcul [j]Trpeulxa[r]cLgvifMCTUca[r]LSsTFOtfDnca[r]IulcscCTUtgvifMx[scCTUt] TOntnfDIulgvifMjmul[jul] VcTOcul jmul:fDnTOcmuO` | 2026-10-20 |
| ドキュメントと0.8.30が違うところ | 角かっこの入れ子（ドキュメントは不可、0.8.30は`a[s[c]]`を受け付ける）、ループのカウンタのステップ（ドキュメントはIRの経路の側、0.8.30では既定の経路でもバイトが変わる）、Standard JSONの注釈の順序の文字列の例は縮めた形、ドキュメントの誤記"an can only" | 2026-10-20 |
| runs | 既定200、最大値2**32-1、角かっこの繰り返しは最大12回、unchecked loop incrementは0.8.22から（ドキュメント） | 2026-10-20 |
| detailsの欄 | peephole・inliner・jumpdestRemover・orderLiterals・deduplicate・cse・constantOptimizer・simpleCounterForLoopUncheckedIncrement・yulの九つの欄とyulDetails（stackAllocation・optimizerSteps）。常に動く欄はpeephole・jumpdestRemover・simpleCounterForLoopUncheckedIncrement | 2026-10-20 |
| Marketのサイズ（ランタイム / 作成のコード） | 切る7,353 / 7,931、入れるruns 1 3,676 / 3,934、200 3,755 / 4,013、10000・1000000 4,795 / 5,053、入れる + 順序`:` 4,276 / 4,618、切る + deduplicateだけを入れる6,574 / 7,113、via-IRで入れる3,260 / 3,473、via-IRで入れる + `:` 5,179 / 5,636（欄ごとの値は上の表） | 2026-10-20 |
| Marketのwithdraw 150のBacktrace | 切る・deduplicateだけを切る`src/MarketMath.sol:38:35` / 入れる・切る + deduplicateだけを入れる`src/Market.sol:67:51`。deposit 0はどのバージョンも`src/Market.sol:149:33` | 2026-10-20 |
| Marketのガス | 上のruns四つの表。入れる + deduplicateを切る: デプロイ936,984、addAsset 75 92,576、deposit 100 128,295、withdraw 30 57,839、setStatus 1 45,224、setStatus 0 23,312、失敗するdeposit 0 26,409 | 2026-10-20 |
| デモのプロジェクトのテストの値 | Dedup139 test_lowのBacktrace default 11:28 / opt 15:28 / nodedup 11:28 / noloop 11:28、Loop139 sum(100)のガス28,282 / 15,464 / 15,464 / 40,082、sum(0) 3,879 / 3,158 / 3,158 / 3,879 | 2026-10-20 |
| Market 第139講のバージョン | runtime 7,353 / creation 7,931、テスト60個（default・ir）、srcに`assembly`なし、deposit 0 149:33、NotActiveの行67 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| Marketにoptimizerを入れるかどうかと、入れたあとに確かめる手順 | [第140講](../../part8/lecture140/) |
| runsとステップの設定をガスで選ぶ判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| via-IRとoptimizerを一緒に入れるかどうか | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| メタデータのsettingsの欄の一つひとつ（optimizer details） | [第142講](../../part8/lecture142/) |
| オプティマイザの欠陥の事例とバージョンごとのバグの一覧 | [第184講](../../part11/lecture184/) |
| 監査でデプロイのビルドの設定と行を確かめる | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
