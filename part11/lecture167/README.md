# 第167講 攻撃者の考え方

第11部 推奨事項：敵対的環境とバージョン履歴・第43章 敵対的環境の法則と5つの軸

[← 第166講](../../part11/lecture166/) | [第11部 目次](../) | [第168講 →](../../part11/lecture168/)

## この講義の問い

テストがすべて通り、カバレッジが100%のコードは、なぜそれでも盗まれるのか。攻撃する側はコードをどんな順番で見るのか。

## 実習資料

### 準備

プロジェクトは二つある。`p167`は`forge init`で作った小さなプロジェクトに、番号ごとに受け取る分が決まった配布（Airdrop）とそのテストを置いたもので、`market`は通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）をコードもテストもそのまま使ったものである。どちらもforge-stdが必要である（`lib/forge-std`）。anvilと外部への接続はない。

### コード

| ファイル | 内容 |
|---|---|
| [code/p167/foundry.toml](code/p167/foundry.toml) | solc 0.8.30、evm osaka、fuzz runs 256・seed 0x2aに固定 |
| [code/p167/src/Airdrop.sol](code/p167/src/Airdrop.sol) | 番号四つ、一つ100ずつ。確認のループと記録のループが分かれたバージョン |
| [code/p167/src/AirdropOneLoop.sol](code/p167/src/AirdropOneLoop.sol) | 確認と記録を一つのループで行う直したバージョン |
| [code/p167/test/Airdrop.t.sol](code/p167/test/Airdrop.t.sol) | 作った人が考えたケース、AirdropTestの五つ |
| [code/p167/test/Attack.t.sol](code/p167/test/Attack.t.sol) | ルールを一つ書いてランダムな配列でたたくRandomProbeTest（攻撃入力を再現するAttackTestは除いた抜粋） |
| [code/p167/test/AttackOneLoop.t.sol](code/p167/test/AttackOneLoop.t.sol) | 同じ番号を四回書いた入力が、直したバージョンでAlreadyClaimedとして差し戻されるか |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（via-IRオン・optimizerオン、ガスの記録の確認） |
| [code/market/src/](code/market/src/) | Market第42章の終わりのバージョンのソース五つ |
| [code/market/test/](code/market/test/) | Market第42章の終わりのバージョンのテストすべて |

### 実行結果

作った人が考えたケース（`forge test --offline --match-contract AirdropTest`）：

```
[PASS] testFuzz_ownerClaimsOne(uint256) (runs: 256, μ: 97602, ~: 97893)
[PASS] test_everyoneClaims() (gas: 214667)
[PASS] test_notOwnerReverts() (gas: 37389)
[PASS] test_ownerClaimsBoth() (gas: 123382)
[PASS] test_secondClaimReverts() (gas: 142259)
Suite result: ok. 5 passed; 0 failed; 0 skipped
```

そのテストだけで測ったカバレッジ（`forge coverage --offline --match-contract AirdropTest --report summary`）：

```
| File            | % Lines         | % Statements    | % Branches    | % Funcs       |
| src/Airdrop.sol | 100.00% (15/15) | 100.00% (18/18) | 100.00% (2/2) | 100.00% (2/2) |
```

カバレッジが100%でも、同じ番号を四回書いた配列一つでaliceが400を全部受け取り、bobの請求はオーバーフロー（Panic 0x11）で止まる。

ランダムにたたくルール`testFuzz_aliceNeverOverpaid`（`forge test --offline --match-contract RandomProbeTest`、次に`--fuzz-runs 10000`、次に`FOUNDRY_FUZZ_SEED=0x1`）：

```
[PASS] testFuzz_aliceNeverOverpaid(uint256[]) (runs: 256, μ: 115562, ~: 104629)
[PASS] testFuzz_aliceNeverOverpaid(uint256[]) (runs: 10000, μ: 118432, ~: 108268)
[PASS] ... (runs: 10000, μ: 118298, ~: 108473)
```

ランダムな配列10,000個をシード五つ（0x1〜0x5）で回しても、同じ番号が重なった配列を見つけられずに通る。

直したバージョンに同じ入力を入れたテスト（`forge test --offline --match-contract AttackOneLoopTest -vvv`）：

```
[PASS] test_sameIdFourTimesReverts() (gas: 64591)
```

Market全体のカバレッジ（`forge build --offline`のあと`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge coverage --offline --report summary`）：

```
97 tests passed, 0 failed, 0 skipped (97 total tests)
| src/Market.sol      | 95.71% (67/70)  | 95.38% (62/65)  | 100.00% (13/13) | 95.65% (22/23) |
| src/MarketMath.sol  | 100.00% (10/10) | 100.00% (14/14) | 100.00% (1/1)   | 100.00% (3/3)  |
| src/MarketTypes.sol | 100.00% (4/4)   | 100.00% (4/4)   | N/A (0/0)       | 100.00% (2/2)  |
```

`--report lcov`で実行されなかった行は`elapsedOf`一つである：

```
SF:src/Market.sol
DA:208,0
FNDA:0,Ledger.elapsedOf
DA:209,0
DA:210,0
```

### 試すときの注意

- `forge build --offline --force`を行うと、lintが`require-revert-in-loop`の警告をAirdrop.sol 26:48・27:34（AirdropOneLoop.sol 27:48・28:34）に出す。
- Marketで`forge coverage`はoptimizerとvia-IRを切ってビルドするので、ガスが記録と変わる。二つの環境変数（`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`）を渡さないと`Snapshots differ`で失敗し、`snapshots/Market.json`を書き換える。
- coverageの前に`forge build --offline`を先に行わないと、DocsTestの二つが`out/Market.sol/Market.json`を読めずに失敗する（95通過、2失敗）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンやシードが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-20 |
| solc | 0.8.30。p167はevm osaka、optimizerは既定値でオフ。coverageはoptimizer・via-IRを切ってビルド | 2026-10-20 |
| fuzzの設定 | `[fuzz] runs = 256`、`seed = "0x2a"`。`--fuzz-runs 10000`、`FOUNDRY_FUZZ_SEED=0x1〜0x5` | 2026-10-20 |
| lintの警告 | require-revert-in-loop：Airdrop.sol 26:48・27:34、AirdropOneLoop.sol 27:48・28:34 | 2026-10-20 |
| Airdropのカバレッジ | src/Airdrop.sol 行15/15・文18/18・分岐2/2・関数2/2（AirdropTestだけ） | 2026-10-20 |
| テストのガス | AirdropTest testFuzz μ 97,602・~97,893、everyone 214,667、notOwner 37,389、ownerBoth 123,382、second 142,259 / RandomProbe 256回 μ 115,562、10,000回 μ 118,432 / AttackOneLoopTest 64,591 | 2026-10-20 |
| Marketのカバレッジ | テスト97個。Market.sol 行95.71%（67/70）・文95.38%（62/65）・分岐100.00%（13/13）・関数95.65%（22/23）、MarketMath.sol 10/10・14/14・1/1・3/3、MarketTypes.sol 4/4・4/4・2/2、全体226/234。実行されなかった行はMarket.sol 208〜210（elapsedOf） | 2026-10-20 |
| 二つの環境変数 | `FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`：渡さないとcoverageビルドのガスが記録と違って`Snapshots differ`で失敗し、snapshots/Market.jsonを書き換える。渡して回したあとのdiffは同じ | 2026-10-20 |
| coverageの前のビルド | `forge build --offline`なしでcoverageだけを回すと、DocsTestの二つがout/Market.sol/Market.jsonを読めずに失敗（95通過2失敗） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 攻撃の問いの行ごとのMarketへの攻撃デモと修正 | [第168講](../../part11/lecture168/)〜[第179講](../../part11/lecture179/) |
| トークンが受け取ったより少なく移したり、偽りを返したりするケース | [第171講](../../part11/lecture171/) |
| ルールを書いて状態を変えながらたたくファジングと不変条件 | [第183講](../../part11/lecture183/) |
| 静的解析・形式検証のツール | [第182講](../../part11/lecture182/) |
| 監査の範囲と精読の順番、チェックリスト | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/) |
| 害するために書かれた相手のコードをMarketにつないでみる | [第168講](../../part11/lecture168/) |
| 継承したコントラクトでアクセスチェックを変えるケース | [第176講](../../part11/lecture176/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
