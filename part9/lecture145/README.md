# 第145講 ベンチマークと回帰の防止

第9部 最適化と規律・第36章 ガス最適化

[← 第144講](../../part9/lecture144/) | [第9部 目次](../) | [第146講 →](../../part9/lecture146/)

## この講義の問い

ガスの数字は、何をどう測った数字なのか。その数字を基準として残し、コードやビルド設定が変わったときに増えたガスを見逃さないためには、何を固定して何を確認するのか。

## 実習資料

### 準備

通しプロジェクトMarketの第144講のバージョンから始める。第145講のバージョンはコードが第144講のバージョンと同じで、デプロイ用のビルドをvia-IR（optimizerオン、runs 200）に変え、ガスを記録するテストと記録を確認する設定を足した。テストにはforge-stdが必要である（`lib/forge-std`）。記録ファイル`snapshots/Market.json`（テストが残す呼び出し6行）と`.gas-snapshot`（テスト65個）は`forge test`と`forge snapshot`が作るので、ここには入れていない。下の実行結果に中身を書いた。フォークのデモでは、ローカルのanvilを元のチェーンとし、もう一つのanvilがそれをフォークする。外部のチェーンには接続しない。

コミット前の確認は、四つの段階を順に実行し、一つでも失敗すれば止まるシェルスクリプトにまとめた：`forge build --sizes`（サイズの表）、`forge test`（デプロイ用のビルドでテストし、`snapshots/Market.json`を前回の記録と照合）、`FOUNDRY_PROFILE=debug forge test`（optimizerを切ったデフォルトの経路で同じテスト）、`forge snapshot --check`（`.gas-snapshot`と1行でも違えば失敗）。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | defaultはvia-IR + optimizer、`gas_snapshot_check = true`。比較用の`legacy`（デフォルトの経路、optimizerオン）と`debug`（デフォルトの経路、optimizerオフ）のプロファイルは記録を残しも照合もしない |
| [code/market/src/](code/market/src/) | Market第145講のバージョン（第144講のバージョンとコードは同じ） |
| [code/market/test/Gas.t.sol](code/market/test/Gas.t.sol) | アカウント0番でデプロイと六つの呼び出しを行い、呼び出しの間に`vm.warp(vm.getBlockTimestamp() + 1)`、呼び出しごとに`vm.snapshotGasLastFrame("Market", 名前)` |
| [code/market/test/](code/market/test/) | テスト19ファイル（65個のテスト） |
| [code/timestamp/test/Gas.t.sol](code/timestamp/test/Gas.t.sol) | 同じテストを`vm.warp(block.timestamp + 1)`で書いたバージョン（via-IRで時刻が進まない落とし穴） |
| [code/timestamp/test/Warp.t.sol](code/timestamp/test/Warp.t.sol) | 2回の`vm.warp`の間で`block.timestamp`を3回読んで出力するテスト |
| [code/nowarp/test/Gas.t.sol](code/nowarp/test/Gas.t.sol) | 呼び出しの間に時刻を進めないバージョン |
| [code/regression/src/Market.sol](code/regression/src/Market.sol) | 回帰のコピー。withdrawのassertの行が`p.deposited`の代わりに`positions[asset][user].deposited`で欄を読み直す |

`timestamp`、`nowarp`、`regression`にはmarketと違うファイルだけを入れた（`timestamp`・`nowarp`は第144講のバージョンの上で実行した）。

### 実行結果

同じdeposit 100のレシートと、`cast run`のトレースの一番上の行。レシートのgasUsed 128,297は、基本コスト21,572と実行ガス106,725の和である：

```
receipt gasUsed 128297 | calldata 68 bytes zero 43 nonzero 25 | 21000+16*nz+4*z = 21572 | floor 21000+10*(z+4*nz) = 22430
cast run | Traces:
cast run |   [106725] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::deposit(0x5FbDB2315678afecb367f032d93F642f64180aa3, 100)
cast run |     ├─ [30086] 0x5FbDB2315678afecb367f032d93F642f64180aa3::transferFrom(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512, 100)
```

同じ呼び出しでも、測り方によって数字が違う（第144講のバージョン）：

| 測り方 | deposit 100 | withdraw 30 |
|---|---|---|
| レシートのgasUsed（新しいanvil、ブロック間隔1秒） | 128,297 | 57,856 |
| `cast run`の一番上の行（実行ガス） | 106,725 | |
| テストの`vm.snapshotGasLastFrame`（isolateオン） | 128,297 | 57,856 |
| テストの`--no-isolate` | 95,425 | 5,784 |
| テスト、呼び出しの間に時刻を進めない | | 55,056 |

第145講のバージョンの`snapshots/Market.json`（レシートのgasUsedと同じ値）：

```
{
  "addAsset75": "92656",
  "deposit100": "127515",
  "failDeposit0": "26264",
  "setStatus0": "23089",
  "setStatus1": "45001",
  "withdraw30": "57448"
}
```

`FOUNDRY_PROFILE=debug`で記録を残すようにしておくと、1回実行しただけで記録がoptimizerを切った値（93,730 / 130,478 / 26,869 / 23,820 / 45,732 / 59,911）で上書きされる。第145講のバージョンの`debug`・`legacy`プロファイルに`gas_snapshot_emit = false`を書いた理由である。

回帰のコピーで`forge test`（記録の確認オン）：

```
[Market] Failed to match snapshots:
- [withdraw30] 57448 → 57576

Error: Snapshots differ from previous run
```

同じコピーでの`forge snapshot --diff`の末尾：

```
↑ GuardsTest::test_withdrawOverDepositKeepsOthersFunds() (gas: 73013 → 73019 | 6 0.008%)
↑ ErrorDataTest::test_insufficientDepositBytes() (gas: 37842 → 37848 | 6 0.016%)
↑ ErrorListTest::test_insufficientDeposit() (gas: 37745 → 37751 | 6 0.016%)
↑ GasTest::test_marketSixCalls() (gas: 388781 → 388909 | 128 0.033%)
↑ RebuildTest::test_rebuildMatchesPositions() (gas: 354526 → 354654 | 128 0.036%)
↑ EventsTest::test_depositWithdrawAllEmit() (gas: 280303 → 280405 | 102 0.036%)
↑ RebuildTest::test_withoutEmitterCheck() (gas: 330465 → 330593 | 128 0.039%)
↑ WithdrawAllTest::test_withdrawAll() (gas: 192688 → 192790 | 102 0.053%)
↑ ErrorListTest::test_transferFailed() (gas: 198388 → 198516 | 128 0.065%)
↑ MarketTest::test_depositWithdraw() (gas: 193798 → 193926 | 128 0.066%)
↑ StatusTest::test_depositPaused() (gas: 139230 → 139358 | 128 0.092%)
↑ AbiShapeTest::test_eventDataBytes() (gas: 116146 → 116274 | 128 0.110%)

--------------------------------------------------------------------------------
Total tests: 65, ↑ 12, ↓ 0, ━ 53
Overall gas change: 1118 (0.020%)
```

`forge snapshot --check`は終了コード1、`--check --tolerance 1`は終了コード0である。行ごとに最も大きく増えたものが0.110%なので1%以内に収まる。同じ変更が積み重なると9回（+1,152、0.99%）まで通り、10回目（1.10%）でようやく引っかかる。

フォークのデモ。元のanvilでaddAsset（ブロック3）、deposit 100（ブロック4）、withdrawAll（ブロック5）を行ったあと、フォークしたanvilで同じアカウントがdeposit 100をもう一度送る：

```
source addAsset (1, 92656, 3)
source deposit 100 (1, 127515, 4)
source withdrawAll (1, 46066, 5)
source latest block 5
pinned N=4 fork block 4 deposited before 100 deposit 100 again (1, 59115, 5)
latest fork block 5 deposited before 0 deposit 100 again (1, 110415, 6)
```

デフォルトの経路（off）とvia-IR（opt）の二つのビルドに同じ呼び出しを300回入れて照合した結果。300回とも同じ答えで、ガスだけが違う：

```
{"ops": 300, "same": 300, "diff": 0, "reverts": 195, "gas_off": 11398123, "gas_opt": 11319294, "kinds": {"deposit": 114, "broken": 29, "withdraw": 68, "setStatus": 21, "addAsset": 23, "deposit0": 22, "withdrawAll": 23}, "why": {"0x25c3f46e": 33, "0x08c379a0": 30, "0x5d35c429": 8, "0x4e487b71": 8, "0x1f2a2005": 18, "0x19cd4595": 12, "0x": 4, "0x17a84242": 5, "0x1d61e8ee": 49, "0x7cde9b72": 2, "0xb2ce2a93": 26}} interestFor 200 mismatches 0
```

レシートのgasUsed（バージョンごとに新しいanvil）：

| 呼び出し | 第144講のバージョン（デフォルトの経路） | 第145講のバージョン（via-IR） |
|---|---|---|
| デプロイ | 867,827 | 760,316 |
| addAsset 75 | 92,576 | 92,656 |
| deposit 100 | 128,297 | 127,515 |
| withdraw 30 | 57,856 | 57,448 |
| setStatus 1 | 45,224 | 45,001 |
| setStatus 0 | 23,312 | 23,089 |
| 失敗するdeposit 0 | 26,409 | 26,264 |

`Warp.t.sol`の出力は、デフォルトの経路（`FOUNDRY_PROFILE=legacy`）では`1 2 3`と3、via-IRでは`2 2 2`と2である。via-IRのビルドはテスト関数の中の`block.timestamp`の読み込みを一つにまとめ、`vm.warp`のあとでも同じ値を使う。そのため`block.timestamp + 1`で書いたGasのテストはvia-IRでwithdraw30が54,648になり、`vm.getBlockTimestamp()`に直すと57,448になる。

第145講のバージョンのサイズ（runtime / creation）はdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931で、三つのプロファイルともテスト65個が通る。四段階の確認は最後に`ci ok`を出力し、終了コード0で終わる。

### 試すときの注意

- Foundry 1.8.3の既定値は`isolate = true`、`gas_snapshot_check = false`、`gas_snapshot_emit = true`である（`forge config`）。`--no-isolate`で実行したテストも`snapshots/Market.json`を上書きする。
- プロファイルは、書かなかった項目をdefaultから受け継ぐ。defaultがvia-IRなら、`debug`プロファイルに`via_ir = false`を書かないとデフォルトの経路にならない（抜くと`FOUNDRY_PROFILE=debug forge config`が`via_ir = true`）。
- defaultに`gas_snapshot_check = true`があると、回帰のバージョンで`forge snapshot --diff`・`--check`を打ったときにテスト側の記録の確認が先に失敗する。`.gas-snapshot`の比較だけを見るには`--gas-snapshot-check false`を付ける。こうして実行すると`snapshots/Market.json`がそのバージョンの値で上書きされるので、基準の記録に戻す。
- `--gas-snapshot-check true`の失敗行の矢印は`記録 → 現在`の順である。
- 四段階の確認はテスト65個を3回実行する（`forge test`、debugの`forge test`、`forge snapshot --check`）。
- `.gas-snapshot`は65行だが、末尾に改行がないので`wc -l`は64と数える。
- 回帰のコピーのサイズは3,297 / 3,510である。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると既定値と数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。第145講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyがデフォルトの経路 + optimizerオン、debugがデフォルトの経路でoptimizerオフ、evm_version osaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| Foundryの設定の既定値 | `isolate = true`、`gas_snapshot_check = false`、`gas_snapshot_emit = true`。プロファイルに書かなかった項目はdefaultの値を受け継ぐ | 2026-10-20 |
| 公式ドキュメントの版 | Solidity IR-based Codegen Changes v0.8.36。引用21〜23行、項目の見出し35・77・106・161・229行、Internals 258〜288行 | 2026-10-20 |
| calldataの下限値 | EIP-7623（Prague）：下限値 = 21,000 + 10 × （0のバイト数 + 4 × 0でないバイト数）、計算したgasUsedのほうが小さければ下限値。基本コストのcalldataの値は0のバイト4、0でないバイト16 | 2026-10-20 |
| 測定条件 | バージョンごとに新しいanvil、ブロック間隔1秒（`anvil_setBlockTimestampInterval 1`）、アカウント0番がMockToken 0x5FbD…0aa3 → Market 0xe7f1…0512、六つの手順。実行ガスは`cast run`の一番上の行（`--steps-tracing`のanvil）。テストは`vm.snapshotGasLastFrame`、isolateオン | 2026-10-20 |
| 通しプロジェクトのガス | 第144講のバージョン：デプロイ867,827、addAsset 75 92,576、deposit 100 128,297、withdraw 30 57,856、setStatus 1 45,224、setStatus 0 23,312、失敗するdeposit 0 26,409。第145講のバージョン（第146講以降の基準）：760,316、92,656、127,515、57,448、45,001、23,089、26,264 | 2026-10-20 |
| サイズ（runtime / creation） | 第144講のバージョンdefault 3,755 / 4,013。第145講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931。回帰のコピー3,297 / 3,510 | 2026-10-20 |
| テストのガス | `--no-isolate` 71,004 / 95,425 / 5,784 / 22,020 / 2,120 / 849、debugのバージョンの記録93,730 / 130,478 / 26,869 / 23,820 / 45,732 / 59,911、`test_marketSixCalls` 387,071（第144講のバージョン）・388,781（第145講のバージョン）・401,345（debug） | 2026-10-20 |
| 二つのビルドの照合 | seed 140、300回同じ、巻き戻り195回（理由11種類）、interestFor 200回同じ、ガスの合計11,398,123 / 11,319,294 | 2026-10-20 |
| フォーク | 元のanvilと、それをフォークしたanvil。ブロック3 addAsset 75、ブロック4 deposit 100、ブロック5 withdrawAll。固定4：59,115 / 固定しない（5）：110,415 | 2026-10-20 |
| 行番号 | 第145講のバージョンdebug deposit 0 src/Market.sol 155:33、NotActive 73行、`contract Market` 196行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（anvilの既定のアカウント、公開されたテスト用の鍵） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| リポジトリのサーバーでci.shを実行する設定（GitHub Actionsなど） | [第258講](../../part20/lecture258/) |
| 本物のチェーンのフォークでガスを測る | [第258講](../../part20/lecture258/) |
| バージョンを上げるときに記録を作り直す | [第184講](../../part11/lecture184/)、[第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 失敗した呼び出しのデバッグとdebugプロファイル | [第183講](../../part11/lecture183/) |
| 監査報告書のガスの項目 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| ブロックガスリミットと手数料 | [第229講](../../part17/lecture229/)〜[第234講](../../part17/lecture234/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
