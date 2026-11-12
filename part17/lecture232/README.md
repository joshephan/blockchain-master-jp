# 第232講 オプティミスティック対ZKロールアップ

第17部 スケーラビリティ・第63章 ロールアップとZK

[← 第231講](../../part17/lecture231/) | [第17部 目次](../) | [第233講 →](../../part17/lecture233/)

## この講義の問い

チェーンの外で実行した結果を、チェーンは何を根拠に受け入れるのか。間違ったステートルートが上がってきたら、誰がどうやってふるい落とすのか。二つの方式は何を待ち、何に代金を払うのか。

## 実習資料

### 準備

講義用のFoundryプロジェクト`rollup`から始める。アカウント四つの小さなL2 `ToyL2`、そのステートルートを受け取っておくオプティミスティックロールアップ`OptimisticRollup232`、プリコンパイル（0x08 ペアリング、0x0A point evaluation）を呼ぶ`Probe232`が入っている。依存関係はforge-std 1.17.0である。テストはforgeの中だけで動き、同じ流れをanvil（`--hardfork osaka`）にデプロイしてcastでもう一度実行した。anvilではアカウント1番が提案者、アカウント2番が監視者である。アカウントはanvilのデフォルトのテスト用アカウントで、外部のチェーンには接続しない。

最初の状態とバッチ一つ：

| 欄 | 最初 | バッチ実行後 |
|---|---|---|
| 0 alice | 100 | 70 |
| 1 bob | 50 | 60 |
| 2 carol | 0 | 20 |
| 3 dave | 0 | 0 |

バッチはalice → bob 30、bob → carol 20、取引二つで20バイト（`0x0001000000000000001e01020000000000000014`）である。チェーン上のコントラクトは、最初の状態のルート0x17b8e416…cbe5一つだけを持つ。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、ファズのシード固定 |
| [code/src/ToyL2.sol](code/src/ToyL2.sol) | 講義用のL2ライブラリ：取引一つ10バイト（送る欄、受け取る欄、金額8バイト）、`run`（残高が足りないか欄が間違った取引は効果なしで通り過ぎる）、リーフ四つのステートルート`root`、欄一つの残高の証明`verify`・`proofOf` |
| [code/src/OptimisticRollup232.sol](code/src/OptimisticRollup232.sol) | 保証金1イーサを賭けてバッチと新しいルートを上げる`propose`、1時間のウィンドウの中でバッチを再実行する`challenge`（BadBatch、BadPreState、RootMatches）、ウィンドウが過ぎると確定する`finalize`（WindowOpen） |
| [code/src/Probe232.sol](code/src/Probe232.sol) | プリコンパイル0x08（ペアリング）と0x0A（point evaluation）を呼び、使ったガスを返す |
| [code/test/Rollup232.t.sol](code/test/Rollup232.t.sol) | Rollup232Testの9個：バッチの大きさ、保証金、再実行のガス、前の状態・同じデータの確認、正しいルートには異議不可、ウィンドウ後の確定、誰も見なかった間違ったルート、間違ったルートへの異議 |
| [code/test/Probe232.t.sol](code/test/Probe232.t.sol) | Probe232Testの5個：ペアリングのガスと偽、すべて1のblobの一点の確認と、間違った値・間違ったハッシュ |

### 実行結果

`forge test --offline --match-contract "Rollup232Test|Probe232Test" -vv`：

```
Ran 9 tests for test/Rollup232.t.sol:Rollup232Test
[PASS] test_batchBytes() (gas: 1039)
[PASS] test_bondRequired() (gas: 53001)
[PASS] test_challengeGasGrows() (gas: 57160878)
Logs:
  txs 10 challenge gas 94769
  txs 100 challenge gas 354490
  txs 1000 challenge gas 2974040

[PASS] test_challengeNeedsPreState() (gas: 199520)
[PASS] test_challengeNeedsSameData() (gas: 205571)
[PASS] test_honestCannotBeChallenged() (gas: 223496)
[PASS] test_honestFinalizesAfterWindow() (gas: 282906)
[PASS] test_unwatchedWrongRootFinalizes() (gas: 260800)
[PASS] test_wrongRootChallenged() (gas: 261072)
Logs:
  challenge gas (2 tx) 80175

Suite result: ok. 9 passed; 0 failed; 0 skipped

Ran 5 tests for test/Probe232.t.sol:Probe232Test
[PASS] test_pairingCost() (gas: 648717)
Logs:
  pairs 2 gas 113424
  pairs 4 gas 181497
  pairs 8 gas 317645

[PASS] test_pairingFalse() (gas: 121273)
[PASS] test_pointEvalConstantBlob() (gas: 70661)
Logs:
  point eval gas 50373
  returns 4096
  0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
  0x01cf478a431837728dcec3461f4f53b8749cdc4e03496dcaed459dea82b82eb8

[PASS] test_pointEvalWrongHash() (gas: 1040430297)
[PASS] test_pointEvalWrongValue() (gas: 1040430298)
Suite result: ok. 5 passed; 0 failed; 0 skipped
```

| テスト | 確かめたこと |
|---|---|
| test_honestFinalizesAfterWindow | 59分で`WindowOpen`、60分で確定、提案者は保証金を返してもらう |
| test_wrongRootChallenged | 10分で異議、監視者 1 → 2イーサ、提案者 10 → 9イーサ、異議のガス80,175 |
| test_honestCannotBeChallenged | 正しいルートに異議 → `RootMatches` |
| test_challengeNeedsSameData | 取引一つだけを出したバッチ → `BadBatch` |
| test_challengeNeedsPreState | その前の状態を[100, 50, 0, 1]に → `BadPreState` |
| test_unwatchedWrongRootFinalizes | ウィンドウが過ぎたあとに異議 → `WindowClosed(1,000,000 + 3,600)`、finalize → 間違ったルートが確定 |
| test_bondRequired | 保証金なしでpropose → `BondRequired(0)` |

anvilにデプロイ（604,247ガス）し、正しいルートを上げた流れ：

```
propose(バッチ20バイト, 0x8cedabf4…fb11)  1 ether   → gasUsed 138,690
evm_increaseTime 3500 → finalize()
  → execution reverted: WindowOpen(1792526799)
evm_increaseTime 100  → finalize()                → gasUsed 49,660
finalizedRoot() → 0x8cedabf4…fb11  （正しいルート）
```

`WindowOpen`の時刻はanvilを立ち上げた時刻によるので、実行するたびに違う。間違ったルート（bobの欄を60ではなく300と書いたルート）に異議を申し立てた流れ：

```
propose(バッチ20バイト, 0xa0c9c468…1114)  1 ether   → gasUsed 138,690
challenge([100,50,0,0], バッチ)   アカウント2番（監視者）  → gasUsed 53,864
監視者の残高の変化 → +0.999958468266757520 ether （1 ether − 手数料）
hasPending() → false
finalizedRoot() → 0x17b8e416…cbe5  （最初のまま）
```

正しいルートにchallengeを送ると、ガス見積もりで`RootMatches`によりリバートする。

| バッチに入った取引 | challengeのガス |
|---|---|
| 10個 | 94,769 |
| 100個 | 354,490 |
| 1,000個 | 2,974,040 |

0x0Aの入力は192バイト（versioned hash 32 | z 32 | y 32 | コミットメント48 | 証明48）である。4,096マスがすべて1のblobは多項式が定数1なので、どのzでも値が1である。コミットメントはBLS12-381のG1生成点（圧縮形式`0x97f1d3a7…22c6bb`）、証明は無限遠点（`0xc000…00`）、versioned hash 0x01cf478a…2eb8、z = 5、y = 1で確かめた：

```
anvil: cast call 0x0A (y = 1) → 0x…1000 73eda753…00000001
       cast estimate (y = 1)  → 72764
       cast call 0x0A (y = 2) → EVM error PrecompileError
```

返す値はFIELD_ELEMENTS_PER_BLOB（4096）とBLS_MODULUSである。プリコンパイルが失敗すると、渡したガスを全部使う（失敗のテストのガス1,040,430,297）。

| ペアの数 | 0x08のガス | 結果 |
|---|---|---|
| 2 | 113,424 | 1 |
| 4 | 181,497 | 1 |
| 8 | 317,645 | 1 |

同じペアを二つ入れると結果は0である（`test_pairingFalse`）。ペア一つは、alt_bn128曲線のG1点とG2点で192バイトである。

### 試すときの注意

- テストのガスの値（challenge、ペアリング、0x0A）は、テストの中で`gasleft`の差で測った値である。
- おもちゃの`OptimisticRollup232`は、実際の設計の分割した争いを省き、バッチ全体を一度に再実行する。1,000個で2,974,040ガスなので、バッチが数千個を超えると、取引一つのガス上限16,777,216の中では再実行できない。実際の設計は、実行のステップを半分ずつ絞り込み（100万ステップなら約20回）、意見が分かれた一ステップだけを再実行する。
- `ToyL2.run`は、残高が足りない取引をリバートせずに通り過ぎる。取引一つでバッチ全体を止められないようにするためである。
- 異議を申し立てるには、バッチのデータとその前の状態がなければならない。コントラクトはバッチのハッシュだけを保存する。
- 講義用のウィンドウは1時間、保証金は1イーサである。
- ペアリングの測定値の差（ペアが2個増えると68,073、4個増えると136,148）は、ペア一つあたり約34,000で、EIP-1108の式45,000 + 34,000 × ペアの数と合う。測定値には呼び出しのコストが入っている。

## 時効性のあるデータ

基準日時点の値。実装の名前は名前だけを書き、数値・シェア・手数料・トークンは載せない。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30 | 2026-10-21 |
| オプティミスティック側の大きな実装の異議申し立てのウィンドウ | 約7日前後と知られている。実装ごとの値は各実装の公開文書で確認 | 2026-10-21 |
| 不正証明の実装の名前（例） | OP Stackの不正証明（Cannon）、Arbitrum BoLD | 2026-10-21 |
| ZKロールアップの公開文書の名前（例） | zkSync、Starknet、Scroll、Linea、Polygon zkEVM | 2026-10-21 |
| EIP-1108のペアリングのガス | 45,000 + 34,000 × ペアの数（測定値113,424 / 181,497 / 317,645には呼び出しのコストを含む） | 2026-10-21 |
| 二つの系統を混ぜる設計 | ある（オプティミスティックで受け取り、異議をZK証明で判定する形など） | 2026-10-21 |
| 0x0Aのガス | 50000 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 実行のステップを半分ずつ分けて一ステップだけを再実行する手順（実際の実装） | 時効性のあるデータ（実装の名前） |
| シーケンサーが決める順番と強制的な取り込み | [第233講](../../part17/lecture233/) |
| 運営者が止まったときに引き出す道 | [第233講](../../part17/lecture233/) |
| 証明が短く確かめられる原理 | [第234講](../../part17/lecture234/) |
| 自分がデプロイするL2の確認方式・ウィンドウ・鍵を信頼の前提に書く | [第237講](../../part18/lecture237/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
