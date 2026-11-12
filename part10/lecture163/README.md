# 第163講 Diamondとセレクタのルーティング

第10部 標準とアップグレード・第42章 アップグレードのパターン

[← 第162講](../../part10/lecture162/) | [第10部 目次](../) | [第164講 →](../../part10/lecture164/)

## この講義の問い

実装のアドレス一つの代わりにセレクタごとに違うアドレスへ送ると何ができるようになり、その表を書き換えることは何と同じなのか。

## 実習資料

### 準備

プロジェクトは二つある。`demo`は、EIP-2535を縮めたデモ用のダイヤモンドMiniDiamond、ファセット（facet）六つ、ガスの比較用に第160講のSlotProxy・CounterV1のコピーを置いたデモ用プロジェクトである。テストファイルはなく、ローカルのanvilにデプロイして`cast`で呼んだ。`market`は通しプロジェクトMarketの第163講のバージョンである。

この講義のデモはOpenZeppelinを使わない。forge-stdはMarketのテストに必要である。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。アカウントはanvilの既定のテスト用アカウント0〜3番をunlockedで使った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka |
| [code/demo/src/MiniDiamond.sol](code/demo/src/MiniDiamond.sol) | セレクタの表と持ち主をハッシュの開始の欄に置いたダイヤモンド（owner、facetAddress、diamondCut、fallback） |
| [code/demo/src/Facets.sol](code/demo/src/Facets.sol) | CounterFacet・CounterFacetV2（ハッシュのスロット）、RateFacet・TreasuryFacet（どちらもスロット0）、BurnFacet・CollateFacet（セレクタ0x42966c68が重なる） |
| [code/demo/src/SlotProxy.sol](code/demo/src/SlotProxy.sol) | 第160講のSlotProxyのコピー（ガスの比較用） |
| [code/demo/src/Counter.sol](code/demo/src/Counter.sol) | 第160講のCounterV1・V2のコピー（ガスの比較用） |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第163講のバージョンのsrcの五つのファイル。コードは第162講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/Size.t.sol](code/market/test/Size.t.sol) | 第163講で足したSizeTestの一つ（ランタイムが24,576バイトの上限の中） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

ブロックの中の日本語の見出し・注記（「（Counterファセット）」「アカウント1番 diamondCut(...)」など）は、実行した操作と相手を示すために付けたもので、値と`Error:`の行が実行結果である。

MiniDiamondをデプロイし、CounterファセットをAddする前とあと。カットの前は表が空なので"no facet"で巻き戻る。Addのあとのinc 3回はダイヤモンドのストレージのハッシュの欄に積もり、Counterファセットのアドレスのcountは0である（inc() 0x371303c0、count() 0x06661abd）：

```
inc()                                   Error: execution reverted: no facet
diamondCut([(Counterファセット, Add, [0x371303c0, 0x06661abd])], 0x0, 0x)   status 1
facetAddress(0x371303c0)                0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512   （Counterファセット）
inc() 3回                               status 1, 1, 1
ダイヤモンドのcount()                   3
Counterファセットのアドレスに直接count()   0
$ cast keccak mini.counter.storage      0xad03d8598dff2d3ccc558516a0bbbd949639f3d952f507c85d428dc7e51b5f48
$ cast storage <ダイヤモンド> 0xad03…5f48  0x…0003
```

持ち主ではないアカウント1番のカットは止められる（持ち主の確認はデモで入れた1行で、権限は標準の外である）：

```
アカウント1番 diamondCut(...)           Error: execution reverted: not owner
```

incの1行だけをCounterFacetV2（同じハッシュのスロット、1回に10）にReplaceすると、countはCounterファセットのまま残り、incだけが変わる：

```
diamondCut([(CounterFacetV2, Replace, [0x371303c0])], 0x0, 0x)   status 1
facetAddress(inc)     0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0   (CounterFacetV2)
facetAddress(count)   0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512   （Counterファセットのまま）
inc()                 status 1
count()               13
```

成功したカットごとにDiamondCutのログが一つずつ残る（topic0 0x8faa7087…b673、diamondCutのセレクタ0x1f931c1c）：

```
$ cast logs --from-block 0 --address <ダイヤモンド> 0x8faa70878671ccd212d20771b795c50af8fd3ff6cf27f4bde57e5d4de0aeb673
ログ六つ（成功したカットの数）
```

同じ4バイトをAdd。burnとcollate_propagate_storageはセレクタが同じなので、先に入ったburnが表に残り、二つ目のAddは止められる。Replaceの前にincをもう一度Addしようとしても同じエラーである：

```
$ cast sig "burn(uint256)"                        0x42966c68
$ cast sig "collate_propagate_storage(bytes16)"   0x42966c68

Add (Burnファセット, [0x42966c68])      status 1
Add (Collateファセット, [0x42966c68])   Error: execution reverted: selector exists

（Replaceの前） Add (CounterFacetV2, [inc])   Error: execution reverted: selector exists
```

countをRemoveすると関数が抜ける。帳簿の欄（ハッシュのスロットの13）はダイヤモンドのストレージにそのまま残る：

```
diamondCut([(0x0, Remove, [0x06661abd])], 0x0, 0x)   status 1
count()                                               Error: execution reverted: no facet
```

diamondCut・owner・facetAddressはダイヤモンドに直接書いた関数なので表にない。EIP-2535の304行は、こうした関数のファセットのアドレスをダイヤモンドのアドレスで答えるよう求めているが、縮めたデモのバージョンはその行を守らず0を返す：

```
$ cast sig "diamondCut((address,uint8,bytes4[])[],address,bytes)"   0x1f931c1c
facetAddress(0x1f931c1c)   0x0000000000000000000000000000000000000000
```

普通の状態変数を使ったRateファセットとTreasuryファセットは、どちらもダイヤモンドのスロット0に書く。treasuryにアカウント3番のアドレスを入れると、rateはそのアドレスを数として読んだ値（`cast to-dec`）になり、rateに5を入れるとtreasuryが0x…05になる：

```
Add Rateファセット(setRate, rate)、Add Treasuryファセット(setTreasury, treasury)   status 1, 1
setTreasury(アカウント3番 0x90F79bf6EB2c4f870365E785982E1f101E93b906)
rate()       827616541489050293873067319834814086332722428166
setRate(5)
treasury()   0x0000000000000000000000000000000000000005
$ cast storage <ダイヤモンド> 0   0x…0005
```

ファセットごとに構造体のまとまりの開始の欄を文字列のハッシュで決めると、同じ文字列を使うファセットどうしだけが同じ欄を使う：

```
$ cast keccak mini.counter.storage   0xad03d8598dff2d3ccc558516a0bbbd949639f3d952f507c85d428dc7e51b5f48
$ cast keccak mini.diamond.storage   0xa8da883fb3497c39c4ee3a39ec3b8a36dada8b24fe15b47b4bb46c3547eac05c
```

三つの形のincのガス（同じ欄の書き換え、デモ用ビルド）。ダイヤモンドはSlotProxyより表の読み取り1回分（325）多くかかる：

| 呼ぶ道 | 同じ欄の書き換えのinc |
|---|---|
| ファセットに直接（CounterFacet） | 26,469 |
| SlotProxy → CounterV1（第160講の形） | 31,290 |
| ダイヤモンド → CounterFacet | 31,615 |

ダイヤモンドで分けると一緒に変わるもの：

| 生まれるもの | 守らなければならないもの |
|---|---|
| ファセットのアドレスの一覧 | ファセットごとの検証、変わるたびに読み直す |
| セレクタの表 | Add・Replace・Removeの規則、DiamondCutのログ |
| ファセットごとの保存位置 | ハッシュの開始の欄が重ならないように |
| カットの権限 | 誰がdiamondCutを呼ぶのか |
| 呼ぶときの費用 | 委任1回と表の読み取り1回 |

`market`で`forge test --offline --match-contract SizeTest -vvvv`。defaultのバージョンは3,260、debugのバージョンは7,353なので、テストは数ではなく上限と比べる：

```
[PASS] test_runtimeUnderLimit() (gas: 3698)
    │   ├─ [653084] → new Market@0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
    │   │   └─ ← [Return] 3260 bytes of code
```

Market第163講のバージョンの点検：`forge build --offline --sizes`でMarket 3,260 / 3,473、`forge test --offline`と`FOUNDRY_PROFILE=debug`・`legacy`はいずれも95個が通過、`.gas-snapshot` 95行、`bash ci.sh`は`ci ok`。

Marketのアップグレードの判断記録に足した行：

| 講義 | 検討した形 | Marketで測ったもの | 判断 | 確認するテスト |
|---|---|---|---|---|
| 163 | ダイヤモンド（EIP-2535） | ランタイム3,260バイト、上限24,576の13%。関数十九が一つのコード、分けるファセットなし | 取り入れない | test/Size.t.sol |

### 試すときの注意

- MiniDiamondはEIP-2535を縮めたデモのバージョンである。ルーペの関数はfacetAddress一つだけで、直接書いた関数のファセットのアドレスをダイヤモンドのアドレスで答える規則（304行）を守らない。
- ファセットたちはダイヤモンドのストレージ一つを共有する。普通の状態変数を置いたファセット二つはどちらも0番のスロットに書くので、ファセットごとに文字列のハッシュで開始の欄を決める。
- Addはすでに表にあるセレクタを止めるので、名前が違っても4バイトが同じ関数は二つ目のAddで引っかかる。
- SizeTestのガス3,698にはデプロイの費用が入らない。forgeがテストの中の`new Market`を別に数えるからで、`-vvvv`のトレースには653,084と出る。
- Market第163講のバージョンはランタイムが上限の中なので、関数をファセットに分けない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ用プロジェクトはoptimizerオフ（Foundryの既定値）・evm osaka。Market第163講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| EIPの原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`。erc-2535.md 435行（17・24・26・27・88〜91・102・104・112・114・121〜138・147・149・153・186・237〜241・255・270〜285・304・310・322・331・408・418・425・429行を引用）、erc-7201.md 99行（55行を引用）。最後の行はCC0 | 2026-10-19 |
| EIPの状態 | 2535 Final（created 2020-02-22）、7201 Final（created 2023-06-20）。ファイルの最終更新のコミットの日付 2535 2023-10-25、7201 2024-04-23 | 2026-10-19 |
| サイズの上限 | EIP-170 ランタイムコード24,576バイト | 2026-10-20 |
| デモのアドレス（ローカルのanvil） | MiniDiamond `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Counterファセット`0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、CounterFacetV2 `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、Rate `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`、Treasury `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、Burn `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707`、Collate `0x0165878A594ca255338adfa4d48449f69242Eb8F` | 2026-10-20 |
| デモのサイズ・ガス | MiniDiamond 5,018バイト・デプロイ1,161,206。カットの前のinc 23,841（巻き戻し）、Add Counter 81,728、inc 48,715 / 31,615 / 31,615、アカウント1番のカット26,250（巻き戻し）、incをもう一度Add 29,789（巻き戻し）、Replace 40,442、Replaceのあとのinc 31,593、Add Burn 56,892、Add Collate 29,789（巻き戻し）、Add Rate 81,728、Add Treasury 81,716、setTreasury 49,195、setRate 31,767、Remove 34,716。同じ欄の書き換えのinc：ファセットに直接26,469 / SlotProxy → CounterV1 31,290 / ダイヤモンド → CounterFacet 31,615 | 2026-10-20 |
| セレクタ・ハッシュ | inc 0x371303c0、count 0x06661abd、setRate 0x34fcf437、rate 0x2c4e722e、setTreasury 0xf0f44260、treasury 0x61d027b3、burn・collate_propagate_storage 0x42966c68、diamondCut 0x1f931c1c、facetAddress 0xcdffacc6、owner 0x8da5cb5b。DiamondCutのtopic0 0x8faa7087…b673、keccak mini.counter.storage 0xad03d859…5f48、mini.diamond.storage 0xa8da883f…c05c | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第163講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ | 第163講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第163講のバージョンdefault `1459bfd7` | 2026-10-20 |
| テストのガス | SizeTest test_runtimeUnderLimit 3,698（forgeが`new Market`をdeployCodeとして回すのでデプロイの費用が入らない、-vvvvのトレースは653,084）。`.gas-snapshot` 95行（既存の94行のうち、RebuildTest:test_recordedLogsIncludeReverted 155,232 → 155,244とtest_tokenSeesDebitedLedger 714,633 → 714,657の2行が第162講のバージョンから変わり、ほかは同じ） | 2026-10-20 |
| 120バイトを超える行（src） | 第163講のバージョン96（バージョン説明のコメントが1行増えた） | 2026-10-20 |
| 行番号 | 第163講のバージョンdebugのdeposit 0 src/Market.sol 175:33、NotActiveの行90、`contract Market` 219行。バージョン説明のコメントが変わると変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ダイヤモンドのカットの履歴をDiamondCutイベントで組み立て直すインデクサー | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| カットの権限をガバナンスに置くこと（EIP-2535の47行） | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |
| 監査でファセットごとの保存位置が重ならないかを確認すること | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| バージョン間の変数の配置とERC-7201の公式 | [第164講](../../part10/lecture164/) |
| ダイヤモンドのselfdestruct禁止（EIP-2535の420〜421行） | [第164講](../../part10/lecture164/)、[第180講](../../part11/lecture180/) |
| 三つの形の呼ぶときの費用を手数料で計算すること | [第229講](../../part17/lecture229/)〜[第234講](../../part17/lecture234/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
