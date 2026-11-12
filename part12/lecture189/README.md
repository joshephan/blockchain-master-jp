# 第189講 深刻度の判定基準

第12部 監査の実務・第50章 監査の方法論

[← 第188講](../../part12/lecture188/) | [第12部 目次](../) | [第190講 →](../../part12/lecture190/)

## この講義の問い

指摘事項の候補のうち、どれがより急ぐのか。深刻度は何で決めるのか。同じバグが、なぜプロジェクトごと、バージョンごとに違う等級を受けるのか。

## 実習資料

### 準備

三つのプロジェクトを使う。監査対象のバージョンのMarketに再現テスト`Audit50.t.sol`を足した写し、直す前のバージョン（Frozenなら出金まで止めていたバージョン）の写し、順番・時間のテストが入った前の章のバージョンの写しである。srcはどれも手を入れていない。三つともforge-std（1.17.0）が必要である（`lib/forge-std`）。anvilと外部への接続は使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | 監査対象のバージョンのビルド設定 |
| [code/market/src/](code/market/src/) | 監査対象のMarketのソース |
| [code/market/test/Audit50.t.sol](code/market/test/Audit50.t.sol) | 指摘事項六つ（L-01〜L-03、I-01〜I-03）を再現するテストと、テスト用の1%手数料トークン |
| [code/market/test/](code/market/test/) | 基準のバージョンのテスト全体（Keys、StatusTableを含む） |
| [code/market164/src/](code/market164/src/) | 直す前のバージョンのMarketのソース（withdrawに`notFrozen`） |
| [code/market164/test/Audit50.t.sol](code/market164/test/Audit50.t.sol) | 直す前のバージョンの再現テスト（`test_M01_frozenLocksWithdraw`を含む） |
| [code/market164/foundry.toml](code/market164/foundry.toml) | 直す前のバージョンのビルド設定 |
| [code/m45/src/](code/m45/src/) | 順番・時間のテストを回した前の章のバージョンのMarketのソース |
| [code/m45/test/Order45.t.sol](code/m45/test/Order45.t.sol) | 同じブロックの中の順番と、1対1の帳簿のテスト（`test_depositWithdrawOneToOne`など） |
| [code/m45/foundry.toml](code/m45/foundry.toml) | 前の章のバージョンのビルド設定 |

### 実行結果

この講義が使う深刻度の表。影響と可能性を別々に評価してから組み合わせる。

| 影響 \ 可能性 | 高 | 中 | 低 |
|---|---|---|---|
| 高 | 致命的 | 高 | 中 |
| 中 | 高 | 中 | 低 |
| 低 | 低 | 低 | 低 |
| なし | 情報 | 情報 | 情報 |

- 影響：高は預けたお金の全部、中は預けたお金の一部、低はお金はそのままで機能だけが止まるか本人のミスの分、なしはお金・機能と関係ない
- 可能性：高は誰でも今すぐ、中は条件が合うとき（特定のトークンの上場、ユーザーのミス）、低は管理者だけか特定の設定でだけ
- 等級の頭文字：致命的C、高H、中M、低L、情報I。番号はM-01、L-02の形

直す前のバージョンの写しで`forge test --offline --match-test test_M01 -vv`。aliceが100を預けたあと管理者がFrozenをかけると、withdrawとwithdrawAllがどちらも`MarketFrozen`で止まり、帳簿100とMarketのトークン残高100がそのまま残る。

```
[PASS] test_M01_frozenLocksWithdraw() (gas: 253663)
```

監査対象のバージョンで`forge test --offline --match-contract Audit50Test -vv`の三行：

```
[PASS] test_L03_lostKeyFrozenStopsDeposit() (gas: 293120)
[PASS] test_L01_feeTokenLastWithdrawReverts() (gas: 722614)
[PASS] test_L02_directTransferStuck() (gas: 110573)
```

- L03：Frozenのあと、bobのdepositは`NotActive(2)`、aliceのwithdrawAllは成功（aliceの残高200）、aliceのsetStatus(Active)は`NotAdmin(alice)`。
- L01：1%手数料トークンにalice・bobが100ずつ預けると、帳簿の合計200、実際の残高198。aliceが100を取り出したあと実際の残高が98なので、bobのwithdraw 100はトークン側のpanic 0x11（残高不足）で差し戻される。
- L02：depositなしでMarketのアドレスに送った50は、残高50、帳簿0。withdraw 50は`InsufficientDeposit(0, 50)`。

直す前のバージョンと直したバージョンの判定：

| 項目 | 影響、可能性 | 深刻度 |
|---|---|---|
| 直す前のバージョンのM-01 | 影響は高：預けたお金の全部が縛られる / 可能性は低：管理者の鍵一つ | 中 |
| 直したバージョンのL-03 | 影響は低：預け入れ・資産の追加だけが止まる / 可能性は低：管理者、マルチシグでのデプロイ | 低 |

同じコードでも、頼る前提が違えば深刻度が変わる（L-01）：

| 上場する側 | 影響 × 可能性 | 深刻度 |
|---|---|---|
| 管理者だけ、標準トークンだけ | 中 × 低 | 低 |
| 誰でも（addAssetからonlyAdminを外した場合） | 中 × 高 | 高 |

同じブロックの中の順番を入れ替えてみた結果。直したバージョンは、順番に関係なく出金できる。前の章のバージョンの`test_depositWithdrawOneToOne`（gas: 219780）は、100を入れて100を出すと帳簿0、トークンの残高が最初と同じであることを確かめる。

| 同じブロックの中の順番 | 直す前のバージョン | 直したバージョン |
|---|---|---|
| setStatus(Frozen)が先、withdrawが後 | MarketFrozen | 出金成功 |
| withdrawが先、setStatus(Frozen)が後 | 出金成功 | 出金成功 |

まとめた指摘事項の表：

| ID | タイトル | 位置 | 影響 × 可能性 → 深刻度 | 頼った前提 |
|---|---|---|---|---|
| L-01 | 手数料を引くトークンを上場すると、最後の出金が差し戻される | Market.sol 170・171、186・187 | 中 × 低 → 低 | 管理者がboolの標準トークンだけを上場 |
| L-02 | depositなしで送ったトークンは取り出す道がない | Market.sol 160〜161、184〜190 | 低 × 中 → 低 | 帳簿で数える |
| L-03 | 鍵一つの管理者がFrozenをかけて鍵をなくすと、預け入れ・資産の追加が永遠に止まる | Market.sol 68、91〜92、99、132 | 低 × 低 → 低 | 管理者はマルチシグ、出金は状態に関係ない |
| I-01 | totalBorrows・borrowed・useAsCollateralを書く行がなく、collateralCountは常に0 | Market.sol 162、260〜266、MarketTypes.sol 32・34 | なし → 情報 | 借り入れ・担保の機能なし |
| I-02 | 預けたことのないアカウントのelapsedOfがblock.timestampを返し、NatSpecと違う | Market.sol 213〜216、IMarket.solのelapsedOfのドキュメント | なし → 情報 | この値でお金を決める行なし |
| I-03 | collateralCountが上場した資産をすべて回る（ガス：資産1個14,198、100個469,049） | Market.sol 261 | なし → 情報 | 資産は管理者だけが上げる、view |

別に書く二行：

| 欄 | 以前のバージョンで直した項目M-01 | 受け入れたリスク |
|---|---|---|
| タイトル | 管理者がFrozenをかけると、預けたお金を誰も取り出せない（直す前のバージョン） | 同じブロックの順番とblock.timestamp、ガバナンスなし |
| 位置 | 直す前のバージョンのMarket.sol 180 | MarketMath 33・41、Market 215 |
| 影響 × 可能性 → 深刻度 | 高 × 低 → 中 | 等級なし |
| 頼った前提 | 直したバージョンで修正 | 信頼の前提の順番・価格の行、ガバナンス・経済の行 |

### 試すときの注意

- テストを回す前に、`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガスの記録の照合を切る。`snapshots/`は添付していない。
- L01でbobの出金が差し戻される理由は、`forge test --offline --match-test test_L01 -vvvv`の呼び出しのトレースで確かめる。
- 監査対象のバージョンの`KeysTest`と`StatusTable`は、`--match-contract "KeysTest|StatusTable"`で10個が通る。全体は117個が通る。
- 等級の名前と段階の数は、報告書ごとに違う。他人の報告書を読むときは、その報告書が書いた基準から見る。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わるとガスの値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka | 2026-10-21 |
| 再現テストのガス（監査対象のバージョン） | L-01 722,614 / L-02 110,573 / L-03 293,120 / I-01 165,591 / I-02 15,297 / I-03 8,018,040 | 2026-10-21 |
| collateralCountのガス | 資産1個14,198、100個469,049 | 2026-10-21 |
| 直す前のバージョンのテストのガス | test_M01_frozenLocksWithdraw 253,663 | 2026-10-21 |
| 前の章のテストのガス | test_depositWithdrawOneToOne 219,780、KeysのテストfrozenStillWithdraws 428,326 / lostKeyFrozenStillWithdraws 433,327 | 2026-10-21 |
| 等級の名前と段階の数 | 監査報告書ごとに違う。この講義は致命的・高・中・低・情報（C・H・M・L・I）と影響 × 可能性の表を使う | 2026-10-21 |
| コンストラクタの引数 | admin 0x70997970C51812dc3A010C7d01B50e44Ef1D4f8c、interestRate 50000000000000000、collateralRatio 80（anvilの既定のテスト用アカウント1番） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 指摘事項を報告書の形に移す（位置・原因・影響・再現テスト・修正の提案・状態） | [第190講](../../part12/lecture190/) |
| コンテストのプラットフォームごとに違う等級のルール | [第191講](../../part12/lecture191/) |
| 審査で等級をめぐって争うこと | [第193講](../../part12/lecture193/) |
| レンディングの担保・清算が入ったあとの判定（I-01・I-03の再評価） | [第197講](../../part13/lecture197/)、[第198講](../../part13/lecture198/)、[第199講](../../part13/lecture199/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
