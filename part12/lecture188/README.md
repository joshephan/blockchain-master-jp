# 第188講 チェックリストの作成とコード精読の順番

第12部 監査の実務・第50章 監査の方法論

[← 第187講](../../part12/lecture187/) | [第12部 目次](../) | [第189講 →](../../part12/lecture189/)

## この講義の問い

範囲が決まったら、どこから読むのか。チェックリストは何を防いでくれて、何を防げないのか。精読からだけ出てくる指摘事項は、どんな姿をしているのか。

## 実習資料

### 準備

通しプロジェクトMarketの監査対象のバージョン（出金からFrozenの確認を外したバージョン）に、監査の再現テスト`Audit50.t.sol`を足した写しから始める。Marketのソースは変えなかった。以前のバージョンで直した項目を確かめるために、直す前のバージョン（Frozenなら出金まで止めていたバージョン）の写しも置く。どちらのプロジェクトもforge-std（1.17.0）が必要である（`lib/forge-std`）。anvilと外部への接続は使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | 監査対象のバージョンのビルド設定（via-IR、optimizerオン、二つのビルドのテスト用の`debug`プロファイル） |
| [code/market/src/](code/market/src/) | 監査対象のMarketのソース（IMarket、Market、MarketMath、MarketTypes、テスト用のMockToken） |
| [code/market/test/](code/market/test/) | 基準のバージョンのテスト111個と再現テスト`Audit50.t.sol` |
| [code/market/test/Audit50.t.sol](code/market/test/Audit50.t.sol) | 指摘事項の候補六つを再現するテスト（I01〜I03、L01〜L03）と、テスト用の1%手数料トークンFeeToken50 |
| [code/market164/foundry.toml](code/market164/foundry.toml) | 直す前のバージョンのビルド設定 |
| [code/market164/src/](code/market164/src/) | 直す前のバージョンのMarketのソース（withdrawに`notFrozen`がついている） |
| [code/market164/test/Audit50.t.sol](code/market164/test/Audit50.t.sol) | 直す前のバージョンで動く再現テスト（`test_M01_frozenLocksWithdraw`を含む） |

### 実行結果

`forge inspect Market methodIdentifiers`のセレクタ19個を分けた結果：

| 種類 | 数 | 関数 |
|---|---|---|
| 状態を変える関数 | 5 | addAsset、deposit、setStatus、withdraw、withdrawAll |
| 自動ゲッター | 10 | status、admin、collateralRatio、interestRate、assets、assetConfig、positions、totalDeposits、totalBorrows、SECONDS_PER_YEAR |
| 自分で書いたview | 3 | assetCount、elapsedOf、collateralCount |
| pure | 1 | interestFor |

`forge inspect Market storageLayout`（Offset・Bytes・Contractの欄は省略、すべてoffset 0）。immutableの三つ（admin、collateralRatio、interestRate）はスロットがないので、この表には出ない。

```
| Name          | Type                                                    | Slot |
| status        | enum IMarket.MarketStatus                               | 0    |
| assets        | contract IERC20[]                                       | 1    |
| assetConfig   | mapping(address => struct AssetConfig)                  | 2    |
| positions     | mapping(address => mapping(address => struct Position)) | 3    |
| totalDeposits | mapping(address => Amount)                              | 4    |
| totalBorrows  | mapping(address => Amount)                              | 5    |
```

範囲内のソース四つからコメントを除き、チェックリストの語をgrepで数えた結果：

```
unchecked : 0          virtual : 3
assembly : 0           super\. : 3
tx.origin : 0          storage  : 4
delegatecall : 0       using  : 2
\.call : 0             for ( : 1
selfdestruct : 0       emit  : 4
payable : 0
block.timestamp : 3
msg.sender : 9
modifier  : 3
```

チェックリストをMarketに回した結果（精読の段階ごと）：

| 段階 | 確かめること | Marketの結果 |
|---|---|---|
| 範囲・ビルド | ファイル一覧とimport、ソースユニット名 | srcの四つ、import 6行 |
| 範囲・ビルド | pragma、0.8より前の算術、バージョンの既知のバグ | 0.8.30に固定した4ファイル、SafeMathなし、0.8.30の既知のバグのソースの条件0か所 |
| 範囲・ビルド | リンクしたアドレス、ライブラリ | linkReferencesは空、InterestMath・PositionLibはinternal |
| 範囲・ビルド | ビルド設定、二つのビルドで同じテスト | via-IR・optimizerのビルドと、optimizerを切った`debug`ビルドで同じテスト |
| 状態 | スロットマップとstorageLayout | 0〜5が同じ |
| 状態 | 継承に散らばった状態、線形化の順番 | 親が三つ、Market・Ledger・AssetRegistry・MarketBase |
| 状態 | プロキシ、アップグレード・初期化の関数 | プロキシなし、アップグレード関数なし、初期化関数なし |
| 状態 | ランタイムのDELEGATECALL・SELFDESTRUCT・ORIGIN | 0個 |
| 変える側 | 権限一覧 | 管理者が二つ（setStatus・addAsset）、誰でもが三つ |
| 変える側 | storageの別名で直す行 | `Position storage` 4か所（Market 206・214、MarketMath 31・37） |
| 変える側 | キーの一覧とマッピング、delete | assetsとassetConfigを一緒に書く（136・137）、delete 0 |
| 変える側 | 一行に二つの副作用、計算の順番 | 0か所 |
| 変える側 | 名前と宣言、引数の順番、オーバーロード | 名前付き引数（170・186）、オーバーロード0 |
| 変える側 | modifierと`_;`、virtual・super、using | modifier三つ、それぞれ`_;`が一回、`_checkDeposit`の三つすべてがsuper、usingが2か所 |
| 防ぐ側 | unchecked・アセンブリのブロック・Yulのファイル | 0か所 |
| 防ぐ側 | 明示的な変換（切り詰め） | `uint64(block.timestamp)` 2か所（MarketMath 33・41） |
| 防ぐ側 | 可視性と読み取りの経路 | セレクタ19 = 状態を変える5 + 自動ゲッター10 + view 3 + pure 1 |
| 防ぐ側 | 権限のチェック（msg.sender、tx.origin、コードの長さ） | msg.senderの確認1か所（106）、tx.origin 0、コードの長さのチェック0 |
| 防ぐ側 | 外部呼び出しの結果、巻き戻りデータ | boolの確認二行（172・188）、低水準のcall 0 |
| 防ぐ側 | 理由文字列とエラー名 | 理由文字列0、エラー12 |
| 防ぐ側 | 標準関数の呼び出し、fromを受け取る関数 | 呼ぶ行はtransferFrom・transferの二つ、from引数の関数0 |
| 防げない側 | 抜けたチェック、積み重なったチェック | InsufficientDeposit・オーバーフローの両方がある |
| 防げない側 | 状態表、時間の段階 | 時間で変わる状態なし、Frozenの行で出金成功 |
| 防げない側 | 管理者関数と空けた席 | 譲る・空にする関数なし |
| 防げない側 | ドキュメントとコードの照合 | elapsedOfの@noticeと空の欄の動作が違う。出金を直す前の文言がIMarket 54・89の@notice、Market 96・152・193のコメントに残っている |

状態の欄ごとに、書く行と読む行を組み合わせた結果。書く行のない欄が三つ出てくる。

| 欄 | 書く行 | 読む行 |
|---|---|---|
| status | Market 101 | 92、100、110 |
| assets、assetConfig | 136、137 | 134、142、148、261 |
| positions（deposited・lastUpdate） | MarketMath 32・33、40・41 | 38、196、209、215 |
| totalDeposits | 202、208 | 202、208、209 |
| totalBorrows | なし | 自動ゲッター |
| Position.borrowed、useAsCollateral | なし | 262（useAsCollateral） |

```
== 書く場所のない欄
src/IMarket.sol:152:  returns (Amount deposited, Amount borrowed, uint64 lastUpdate, bool useAsCollateral);
src/IMarket.sol:160:  function totalBorrows(address asset) external view returns (Amount);
src/Market.sol:162:   mapping(address asset => Amount) public totalBorrows;
src/Market.sol:262:   if (positions[address(assets[i])][user].useAsCollateral) {
src/MarketTypes.sol:32:  Amount borrowed;
src/MarketTypes.sol:34:  bool useAsCollateral;
```

指摘事項の候補六つと再現テスト：

| 候補 | 出てきた場所 | 再現テスト |
|---|---|---|
| 手数料トークンを上場すると帳簿と実際の残高が分かれる | 信頼の前提の上場トークンの行 | test_L01_feeTokenLastWithdrawReverts |
| depositなしで送ったトークンは取り出せない | 信頼の前提の直接送ったトークンの行 | test_L02_directTransferStuck |
| 鍵一つの管理者がFrozenのあと鍵をなくすと、預け入れが永遠に止まる | 信頼の前提の管理者の行、攻撃マップの中央の点の行 | test_L03_lostKeyFrozenStopsDeposit |
| 書く行のない欄が三つ、collateralCountは常に0 | 精読 | test_I01_collateralCountAlwaysZero |
| 空の欄のelapsedOf（ドキュメントと違う） | 精読 | test_I02_elapsedOfEmptyPosition |
| collateralCountが資産の数だけ回る | 攻撃マップの資源と精度の行の問い | test_I03_collateralCountGas |

`forge test --offline --match-contract Audit50Test -vv`：

```
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

- L01：1%手数料トークンにalice・bobが100ずつ預けると、帳簿200、実際の残高198。aliceが100を取り出したあと98が残り、bobの100の出金が差し戻される。
- L02：depositなしで直接送った50は、残高50、帳簿0。withdraw 50は`InsufficientDeposit(0, 50)`で差し戻される。
- L03：Frozenのあと、bobのdepositは`NotActive(2)`、aliceのwithdrawAllは成功、管理者でない側のsetStatusは`NotAdmin`。

直す前のバージョンの写しで`forge test --offline --match-test test_M01 -vv`。Frozenならwithdraw・withdrawAllがどちらも`MarketFrozen`で止まり、預けたお金が縛られる。今のバージョンでは直したので、「以前のバージョンで直した項目」として別に書く。

```
[PASS] test_M01_frozenLocksWithdraw() (gas: 253663)
Suite result: ok. 1 passed; 0 failed; 0 skipped
```

### 試すときの注意

- テストを回す前に、`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`でガスの記録の照合と記録の書き出しを切る。`snapshots/`は添付していない。
- 監査対象のバージョンで`forge test --offline`全体は、41スイート117個が通る（基準のバージョン111 + Audit50 6）。
- storageLayoutにはimmutableが出ない。状態の一覧をstorageLayoutだけで作ると、管理者のアドレスが抜ける。
- grepでは、ない行を数えられない。書く行のない欄は、欄ごとに書く行と読む行を組み合わせてはじめて見えてくる。
- カバレッジは、collateralCountが動いたと数える。その中の条件が常に偽であることは、カバレッジの表には出ない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンやコードが変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge） | 1.8.3 | 2026-10-21 |
| solc | 0.8.30、実行ファイルのsha256 `ccbd3ed44d5fbd26fe039702d403421f1212d2e8752e3cbe3bfd074986911586`。optimizerオン（runs 200）・via-IRオン・evm osaka・bytecode_hash ipfs | 2026-10-21 |
| 0.8.30の既知のバグ | 四つ、ソースの条件はMarketで0か所 | 2026-10-21 |
| テストの数 | 基準のバージョン111個 + Audit50 6個 = 117個が通過（41スイート） | 2026-10-21 |
| Audit50のガス | I01 165,591 / I02 15,297 / I03 8,018,040 / L01 722,614 / L02 110,573 / L03 293,120 | 2026-10-21 |
| collateralCountのガス | 資産1個14,198 / 100個469,049 | 2026-10-21 |
| 直す前のバージョンのM01のガス | 253,663 | 2026-10-21 |
| カバレッジ | src/Market.sol 関数22/23（直す前のバージョン、テスト97個のときに測った値） | 2026-10-21 |
| 公開された弱点分類の一覧 | SWCなど。保守の有無と最新版は基準日に確認が必要 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 候補ごとに深刻度をつける（影響 × 可能性） | [第189講](../../part12/lecture189/) |
| 候補を報告書の形に移す（位置・原因・影響・修正の提案・状態） | [第190講](../../part12/lecture190/) |
| 静的解析ツールでチェックリストの行を自動で回す | 付録 |
| 他人の大きなコードベースに同じ順番を当てはめる | [第192講](../../part12/lecture192/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
