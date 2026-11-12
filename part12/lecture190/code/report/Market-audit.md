# Market監査報告書

## 1. 要約
- 対象: 通しプロジェクトMarket(第46章末の版)
- 範囲: srcのファイル四つ(IMarket.sol、Market.sol、MarketMath.sol、MarketTypes.sol)、515行 / 空行・コメントを除いて217行
- ビルド: solc 0.8.30(実行ファイルのsha256 `ccbd3ed44d5fbd26fe039702d403421f1212d2e8752e3cbe3bfd074986911586`)、optimizerオン runs 200、via-IRオン、evm osaka、bytecode_hash ipfs。ランタイム2,990バイト、メタデータのハッシュ `de70fa9e1585f2dae1720ff3231bcf64fa6532a535aa3488b797d723f0176fba`
- 方法: 五つの順番での精読、チェックリスト(grep)、発見事項ごとの再現テスト(test/Audit50.t.sol)
- 結果: 低3、情報4。以前の版で修正した項目1(修正の確認)。受け入れたリスク1
- 限界: この報告書は決めた範囲と上のビルド一つで見つけたものの記録。バグがこれ以上ないことの証明ではない。範囲外で変わったコードは監査が見たことのないコード

## 2. 範囲と範囲外
- 範囲内: 上の四つのファイル、上のビルド一つ、デプロイ設定(コンストラクタ引数admin・interestRate 5e16・collateralRatio 80)
- 範囲外: lib/forge-std、src/MockToken.sol、test/、上場されるトークンのコード、コンパイラ自体、デプロイツール

## 3. 深刻度の基準
- 影響(起きたら失うもの) × 可能性(起きる条件)を別々に評価してから合わせる
- 高 × 高 = 致命、高 × 中 = 高、高 × 低 = 中、中 × 高 = 高、中 × 中 = 中、中 × 低 = 低、影響が低 = 低、お金・機能への影響なし = 情報
- 等級の名前と区分は報告書ごとに違う。この報告書の基準

## 4. 発見事項の表
| ID | タイトル | 深刻度 | 依存する前提 | 修正の提案 | 状態 |
|---|---|---|---|---|---|
| L-01 | 手数料を引くトークンを上場すると最後の引き出しが巻き戻る | 低 | 管理者がboolを返す標準トークンだけを上場 | 上場前の確認手順(代案: 受け取った量を残高の差で数える) | 提案 |
| L-02 | depositなしで送ったトークンは取り出す道なし | 低 | 帳簿で数える | ドキュメント化 | 承認 |
| L-03 | 鍵が一つだけの管理者がFrozenをかけて鍵を失くすと、預け入れ・資産の追加が永久に止まる | 低 | 管理者の席はマルチシグ、引き出しは状態と関係なし | マルチシグのデプロイの決定どおり | 承認 |
| I-01 | totalBorrows・borrowed・useAsCollateralを書く行なし、collateralCountは常に0 | 情報 | 借り入れ・担保の機能なし | 借り入れ機能のときに再確認 | 承認 |
| I-02 | 空の欄のelapsedOfがblock.timestampを返す、NatSpecと違う | 情報 | この値でお金を決める行なし | NatSpecに一行、または空の欄で0を返す | 提案 |
| I-03 | collateralCountが上場した資産すべてを回る(ガス) | 情報 | 資産は管理者だけが上場、view | ドキュメント化 | 承認 |
| I-04 | Market.sol 193行目のコメントが修正前の動作を書いている | 情報 | コメントはバイトコードに入らない | 古い行を今の動作に直す | 提案 |

## 5. 発見事項の本文

### L-01 手数料を引くトークンを上場すると最後の引き出しが巻き戻る
- 深刻度: 低(影響 中 × 可能性 低)
- 依存する前提: 管理者がboolを返す標準トークンだけを上場する(信頼の前提のトークンの行)。誰でも上場できるなら高
- 位置: src/Market.sol 170 `_credit`(要求されたamountを帳簿に書く)、171 `transferFrom`(実際に入ってきた量は見ない)、186・187 `withdraw`
- 説明: depositは要求された量を帳簿に先に書いてからトークンを受け取る。移すときに手数料を引くトークンなら、帳簿の合計が実際の残高より大きくなる
- 影響: 前の人たちが全部引き出した後、最後の人のwithdrawがトークン残高不足で巻き戻る。テストでは帳簿の合計200、実際の残高198、aliceが100を引き出した後の実際の残高98、bobのwithdraw 100が巻き戻る(トークン側のpanic 0x11)
- 再現: test/Audit50.t.sol `test_L01_feeTokenLastWithdrawReverts`
  ```
  $ FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-test test_L01 -vv
  Ran 1 test for test/Audit50.t.sol:Audit50Test
  [PASS] test_L01_feeTokenLastWithdrawReverts() (gas: 722614)
  ```
- 修正の提案: (ア) 上場前の確認手順をドキュメントに書く(移すときに手数料を引くか、残高がひとりでに変わるか) (イ) 代案: depositで受け取った量をtransferFrom前後の残高の差で数える(ガスとCEIの順番を一緒に検討)。確認: 同じテストを直した版で回し、最後の引き出しが成功
- 状態: 提案

### I-02 空の欄のelapsedOfがblock.timestampを返す
- ドキュメント(IMarket.sol 110): 「そのアカウントの欄を最後に直してから経過した秒数」
- 動作(Market.sol 213~216): 一度も預けたことのない欄はlastUpdateが0なので、block.timestampそのまま
- 再現: `test_I02_elapsedOfEmptyPosition`(vm.warp(1,000,000)の後、bobのelapsedOf = 1,000,000)
- ドキュメントのテスト: test/Docs.t.solの二つのテストが合格(ドキュメントがあるかだけを確認)
- 修正の提案: NatSpecに「預けたことのない欄はblock.timestamp」と一行、または空の欄で0を返す。どちらにするかは開発チームが決める
- 状態: 提案

### I-04 Market.sol 193行目のコメントが修正前の動作を書いている
- ドキュメント(Market.sol 193): 「第103講: modifierを別に付けない。内部で呼ぶwithdrawのnotFrozenが実行される」
- 動作(Market.sol 184): withdrawにnotFrozenなし。すぐ下の194行目が修正を書いている。同じ形(古い行 + すぐ下に直した行)は96・152行目
- 再現: 修正版のtest/Keys.t.sol `test_frozenStillWithdraws` 合格(Frozenの後にwithdrawAllが成功)
- 修正の提案: 古い行を今の動作に直す(コメントだけ、バイトコードはメタデータのハッシュが変わる)
- 状態: 提案

### I-03 collateralCountが上場した資産すべてを回る(ガスの項目)
- 位置: Market.sol 261
- 測った値: 資産1個で14,198ガス、100個で469,049ガス(`test_I03_collateralCountGas`、gasleftの差)
- 測ったバージョン: Foundry 1.8.3、solc 0.8.30、via-IR・optimizer runs 200
- 状態: 承認(ドキュメント化)

(L-02、L-03、I-01の本文も同じ形式で)

## 6. 以前の版で修正した項目
### M-01 管理者がFrozenをかけると預けたお金を誰も引き出せない(修正前の版)
- 位置: 修正前の版のMarket.sol 180(withdrawのnotFrozen)
- 深刻度: 中(影響 高 × 可能性 低)
- 再現: `test_M01_frozenLocksWithdraw`
  - 修正前の版: `[PASS] test_M01_frozenLocksWithdraw() (gas: 253663)`
  - 修正版(同じテストを文字どおり): `[FAIL: next call did not revert as expected] test_M01_frozenLocksWithdraw() (gas: 240033)` = 再現せず
  - 修正版のtest/Keys.t.sol: `test_frozenStillWithdraws`、`test_lostKeyFrozenStillWithdraws` 合格
- 修正: withdrawからnotFrozenを外す
- 状態: 修正を確認

## 7. 信頼の前提と受け入れたリスク
- 同じブロック内の順番とblock.timestamp(MarketMath 33・41、Market 215)、ガバナンスなし: 信頼の前提の順番・価格の行とガバナンスの行に書いた項目。確認済みで、等級なしで受け入れたリスク

## 8. 付録(コマンドと出力)
```
$ FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract Audit50Test -vv
Ran 6 tests for test/Audit50.t.sol:Audit50Test
[PASS] test_I01_collateralCountAlwaysZero() (gas: 165591)
[PASS] test_I02_elapsedOfEmptyPosition() (gas: 15297)
[PASS] test_I03_collateralCountGas() (gas: 8018040)
Logs:
  assets 1 gas: 14198
  assets 100 gas: 469049

[PASS] test_L01_feeTokenLastWithdrawReverts() (gas: 722614)
[PASS] test_L02_directTransferStuck() (gas: 110573)
[PASS] test_L03_lostKeyFrozenStopsDeposit() (gas: 293120)
Suite result: ok. 6 passed; 0 failed; 0 skipped
```
- 全体の `forge test --offline`: 41スイート117個が合格(元の111 + 再現6)
