# 第252講 言語選択のトレードオフ

第19部 ほかの実行環境・第69章 EVMの中のほかの言語

[← 第251講](../../part19/lecture251/) | [第19部 目次](../) | [第253講 →](../../part20/lecture253/)

## この講義の問い

同じことを複数の言語で書いて同じ方法で測ると、何が変わり、何が同じなのか。違う言語で書いたコントラクトどうしは、どうやって出会うのか。言語を選ぶとき、ガスの数字以外に何を一緒に選ぶことになるのか。MarketはなぜSolidity一つにしておくのか。

## 実習資料

### 準備

前の二つの講義で測った値（Marketの基準のバージョンと平らなバージョン、SimpleStorageの四つのバージョン）を一つの表に集め、新しく小さなFoundryプロジェクト`tool252`で、Solidityのバージョン`Store251`と手で移したHuffドキュメントのバージョン52バイトを同じインターフェースで呼ぶ。手で移したバージョンは`vm.etch`でテスト内のアドレス`0x…4242`にバイトのまま置く。依存関係はforge-std（`lib/forge-std`）一つで、anvilは使わない。

`err7006`は`tool252`のsrc・foundry.tomlをそのままにしてテストファイル一つだけを替えたフォルダで、ビルドが止まることを確かめる用途である。SMTCheckerは、Market第53章末のバージョンのコピー（srcは[第250講 code/market/src](../lecture250/code/market/src/)と同じ）に`[profile.smt]`を加えた`market-smt`で実行した。この環境にはHornソルバーがない。

### コード

| ファイル | 内容 |
|---|---|
| [code/tool252/foundry.toml](code/tool252/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka |
| [code/tool252/src/Store251.sol](code/tool252/src/Store251.sol) | SolidityのバージョンのSimpleStorage（setValue・getValue、スロット0） |
| [code/tool252/test/Tools252.t.sol](code/tool252/test/Tools252.t.sol) | `IStore`インターフェース、手で移したバージョンを`vm.etch`で置き、テスト三つ |
| [code/err7006/test/Value252.t.sol](code/err7006/test/Value252.t.sol) | non-payableな関数に`{value: 0}`を付けた1行（ビルドがError 7006で止まる） |
| [code/market-smt/foundry.toml](code/market-smt/foundry.toml) | Marketのビルド設定に`[profile.smt]`・`[profile.smt.model_checker]`（CHC、目標五つ）を加えたバージョン |

### 実行結果

`tool252`で`forge test --offline -vvvv`。同じインターフェースで二つのバージョンを呼んだトレース：

```
[PASS] test_sameAbiBothPass() (gas: 105704)
  ├─ [43461] Store251::setValue(5)
  │   └─ ← [Stop]
  ├─ [43467] 0x0000000000000000000000000000000000004242::setValue(5)
  │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000005
  ├─ [2247] Store251::getValue() [staticcall]
  │   └─ ← [Return] 5
  ├─ [2175] 0x0000000000000000000000000000000000004242::getValue() [staticcall]
  │   └─ ← [Return] 5
```

同じ`0xdeadbeef`呼び出しの二つのトレース：

```
[PASS] test_unknownSelectorSolidity() (gas: 25185)
  ├─ [21510] Store251::deadbeef(0000000000000000000000000000000000000000000000000000000000000009)
  │   └─ ← [Revert] unrecognized function selector 0xdeadbeef for contract 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, which has no fallback function.
[PASS] test_unknownSelectorHand() (gas: 51521)
  ├─ [43489] 0x0000000000000000000000000000000000004242::deadbeef(0000000000000000000000000000000000000000000000000000000000000009)
  │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000009
  ├─ [2175] 0x0000000000000000000000000000000000004242::getValue() [staticcall]
  │   └─ ← [Return] 9
```

Solidityのバージョンは同じプロジェクトのビルド成果物（ABI、ソースマップ）があるので、コントラクト名と巻き戻しの理由が出る。手で移したバージョンは成果物がないので、アドレスと生のバイトだけが出る。

`err7006`で`forge build --offline`：

```
Error (7006): Cannot set option "value" on a non-payable function type.
  --> test/Value252.t.sol:14:9:
   |
14 |         s.setValue{value: 0}(1);
   |         ^^^^^^^^^^^^^^^^^^^^
```

インターフェースにpayableがなければ、呼ぶSolidity側はイーサを付けられない。受ける側が防ぐかどうかは、受ける側のバイトコードが決める。

ドキュメントのバージョンがインターフェースに書いた約束と実際の動作：

| ドキュメントのバージョンのインターフェースの行 | 書いた約束 | 実際の動作 |
|---|---|---|
| `setValue(uint256) nonpayable returns ()` | 返す値なし | `0x00…05`を返す |
| `setValue(uint256) nonpayable returns ()` | イーサを受け取らない | 1 weiを受け取って成功 |
| ディスパッチャー | 知らないセレクタは巻き戻す（最後のrevert） | 0xdeadbeefで保存値が変わる |

`market-smt`で`FOUNDRY_PROFILE=smt forge build --offline --force`は終了コード0で終わり、検証目標の警告83個がすべて "might happen" である（6328 Assertion violation 1、6368 Out of bounds 2、4281 Division by zero 24、4984 Overflow 47、3944 Underflow 9）。そのほかに下の1行と、サポートしていない文法38個を知らせる5724の警告が48行出る。

```
Warning (3996): CHC analysis was not possible. No Horn solver was available. None of the installed solvers was enabled.
```

一つの表に集めた値（測った方法は表ごとに違う）：

| Marketの二つのバージョン | 基準のバージョン | 平らなバージョン |
|---|---|---|
| テスト | 136通過 | 136通過 |
| ランタイム（デプロイ用 / debugビルド） | 9,006 / 19,285バイト | 9,043 / 19,296バイト |
| addAsset / deposit / withdraw | 92,861 / 136,902 / 66,415 | 92,813 / 136,902 / 66,415 |
| setStatus 1 / setStatus 0 / 失敗するdeposit | 45,059 / 23,147 / 26,356 | 45,035 / 23,123 / 26,356 |

| SimpleStorageのバージョン | ランタイム | デプロイ | 最初のsetValue | もう一度setValue | getValue |
|---|---|---|---|---|---|
| Solidity | 150 | 85,847 | 43,461 | 26,361 | 23,311 |
| Yul | 43 | 62,468 | 43,346 | 26,246 | 23,232 |
| ドキュメントのバージョン（手で移した） | 52 | 64,300 | 43,467 | 26,367 | 23,239 |
| 直したバージョン（手で移した） | 53 | 64,504 | 43,348 | 26,248 | 23,239 |

Marketの二つのバージョンはforgeのテストのガス記録、SimpleStorageの四つのバージョンはanvilのレシートのgasUsed（デプロイ・setValue）と`cast estimate`（getValue）で測った。同じgetValueが`cast estimate`では23,311、forgeのトレースでは2,247である（トレースの数字は呼び出し一つの内側だけ）。

### 試すときの注意

- ガスの数字は測った方法と一緒に書いておく。forgeのテストのガス、anvilのレシートのgasUsed（基本の21,000を含む）、`cast estimate`、forgeのトレースの数字は、同じ呼び出しでも互いに違う。
- コントラクトどうしはABIでだけ出会う。セレクタと引数の形が合えば、どの言語で書いたコードでも呼べるが、インターフェースに書いた約束を受ける側が守るかどうかは、受ける側のバイトコードが決める。
- SMTCheckerが警告なしで終わったからといって証明されたわけではない。ソルバーがなければ、3996の警告1行だけを残して終了コード0で終わる。
- MarketはSolidity 0.8.30の一つの言語で書き（アセンブリブロック・Yul・Vyper・Huffのファイル0個）、言語を変えない。平らなバージョンは同じテスト136個を通り、ランタイムが37バイト大きく、測った呼び出し六つのガスの差は48以下（平らなバージョンが同じか少ない）である。

## 時効性のあるデータ

基準日時点の値。ドキュメントとツールのバージョンが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry・solc | forge 1.8.3（commit cae51ad4）、solc 0.8.30 | 2026-10-21 |
| tool252のテストのガス | test_sameAbiBothPass 105,704 / test_unknownSelectorHand 51,521 / test_unknownSelectorSolidity 25,185、トレースsetValue 43,461 / 43,467、getValue 2,247 / 2,175、deadbeef 21,510 / 43,489 | 2026-10-21 |
| Marketの二つのバージョン | 第53章末のバージョン基準、テスト136、ランタイム9,006 / 9,043、GasTest六つ（第250講の時効性のあるデータ） | 2026-10-21 |
| SMTChecker（Market） | 目標の警告83（6328 1、6368 2、4281 24、4984 47、3944 9）、3996 1、5724 48（サポートしない文法38）、終了コード0 | 2026-10-21 |
| SimpleStorageの四つのバージョン | ランタイム150 / 43 / 52 / 53、デプロイ・setValue・getValueは第251講の値 | 2026-10-21 |
| 前の章の表 | Marketのアセンブリ変形版interestFor 725 → 391、setStatus 24,020 → 24,007 / Tally 146、877、467、380バイト、デプロイ106,897、265,389、176,676、157,848 | 2026-10-21 |
| Vyperのセキュリティ勧告 | 54件（low 24、medium 21、high 8、critical 1） | 2026-10-21 |
| Vyperドキュメント | v0.4.3 `compiling-a-contract.rst` | 2026-10-21 |
| Solidityの既知のバグ | 0.8.30は四つ（InheritanceOrderReversalOnStorageEndWarning、UnsoundSpillInMutualRecursion、TransientStorageClearingHelperCollision、LostStorageArrayWriteOnSlotOverflow） | 2026-10-21 |
| huff-rs | アーカイブ済み、最後のバージョン0.3.2（2023-07-08） | 2026-10-21 |
| huff-neo | v1.6.2（2026-10-17） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| キャップストーンで言語・コンパイラのバージョンを選び直すこと | [第253講](../../part20/lecture253/)、[第254講](../../part20/lecture254/) |
| 違う言語で書いたコントラクトとかみ合うテスト（インターフェースのテスト） | [第258講](../../part20/lecture258/) |
| ほかの言語のコンパイラのバグ告知を追う | 付録 |
| EVMの外の実行環境との比較 | 扱わない（前の章） |

出典と参考資料は[reference.md](reference.md)にまとめた。
