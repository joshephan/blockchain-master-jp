# 第186講 0.8のチェック付き算術とunchecked

第11部 推奨事項：敵対的環境とバージョン履歴・第49章 既知のバグとバージョン移行

[← 第185講](../../part11/lecture185/) | [第11部 目次](../) | [第187講 →](../../part12/lecture187/)

## この講義の問い

0.8で算術は何が変わったのか。0.8のコードでオーバーフローはすべて止まるのか。`unchecked`はどこまで外すのか。バージョンを上げるときは何を見るのか。

## 実習資料

### 準備

三つを使う。`old/src/Old.sol`は、0.7.6と0.8.30のどちらでもコンパイルできる小さなコントラクトである。二つのバージョンのビルド成果物（バイトコード）をローカルのanvilにアカウント0番（既定のテスト用の鍵）で順にデプロイし、castで同じ関数を呼ぶ。0.7.6のバージョンは以前に作った成果物をそのまま使い、今回は新しくコンパイルしていない。`bugs`はチェック付き算術の境界をテストする小さなFoundryプロジェクトで、forge-stdが必要である。via-IRの既定のプロファイルと、via-IRを切った`legacy`プロファイルを置く。`market`は通しプロジェクトMarketの第46章の終わりのバージョンに、テスト`test/Cast49.t.sol`を一つだけ足した写しである（基準のバージョンには入れない）。新しいコンパイラは取得せず、外部への接続は使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/old/src/Old.sol](code/old/src/Old.sol) | `pragma solidity >=0.7.6 <0.9.0;`、`add8(uint8, uint8)`と`sub(uint256, uint256)` |
| [code/bugs/foundry.toml](code/bugs/foundry.toml) | solc 0.8.30、optimizerオン、via-IRオン、evm osaka、`legacy`プロファイル |
| [code/bugs/src/Checked186.sol](code/bugs/src/Checked186.sol) | チェック付き算術と`unchecked`版（sub・subWrap、mul・mulWrap、subViaCall、divWrap、narrow、negMin、powChain）と、Panic番号を出す関数 |
| [code/bugs/test/Checked186.t.sol](code/bugs/test/Checked186.t.sol) | Checked186Testの九つ：Panic番号六つ、uncheckedは呼んだ関数に届かない、0での割り算は差し戻し、明示的な変換はチェックなしなど |
| [code/bugs/src/Loop186.sol](code/bugs/src/Loop186.sol) | 同じループをforの`++i`、forの末尾の`unchecked { ++i; }`、whileで書いた三つの関数 |
| [code/bugs/test/Loop186.t.sol](code/bugs/test/Loop186.t.sol) | n = 100で三つの関数のガスをgasleftの差で測る |
| [code/tools/bugs184.py](code/tools/bugs184.py) | `bugs.json`・`bugs_by_version.json`を読み、0.8.30の既知のバグと修正版を出す |
| [code/market/test/Cast49.t.sol](code/market/test/Cast49.t.sol) | Cast49Testの二つ：`uint64(block.timestamp)`は今はそのまま、2^64秒を超えると黙って切り詰められる |
| [code/market/](code/market/) | Market第46章の終わりのバージョン（foundry.toml、src、testそのまま）と上のテスト一つ |

### 実行結果

同じソースOldを0.7.6と0.8.30でビルドしてanvilにデプロイした結果。アカウント0番が順にデプロイしたので、0.7.6のバージョン（$O7）が0x5FbD…0aa3、0.8.30のバージョン（$O8）が0xe7f1…0512である。

```
$ cast call $O7 'sub(uint256,uint256)(uint256)' 5 6
115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]
$ cast call $O8 'sub(uint256,uint256)(uint256)' 5 6
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
... data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000011"
$ cast call $O7 'add8(uint8,uint8)(uint8)' 255 1
0
$ cast call $O8 'add8(uint8,uint8)(uint8)' 255 1
Error: execution reverted: panic: arithmetic underflow or overflow (0x11)
```

`cast code`で見た二つのコードの末尾。メタデータの末尾のsolcのバージョンが`00 07 06`と`00 08 1e`（0x1e = 30）である。

```
$ cast code $O7    ... 430007060033
$ cast code $O8    ... 4300081e0033
```

Panicの巻き戻りデータは、先頭4バイトの`0x4e487b71`（`Panic(uint256)`のセレクタ）と、後ろ32バイトのチェック番号である。`bugs`で`forge test --offline --match-test test_panicCodes -vvvv`（expectRevertの行は省略）：

```
[PASS] test_panicCodes() (gas: 53412)
    │   └─ ← [Revert] panic: assertion failed (0x01)
    │   └─ ← [Revert] panic: failed to convert value into enum type (0x21)
    │   └─ ← [Revert] panic: called `.pop()` on an empty array (0x31)
    │   └─ ← [Revert] panic: array out-of-bounds access (0x32)
```

| 番号 | かかったチェック | Checked186 |
|---|---|---|
| 0x01 | assertの失敗 | failAssert |
| 0x11 | 算術のオーバーフロー | sub、mul、negMin |
| 0x12 | 0での割り算 | divWrap |
| 0x21 | 範囲外の数のenum変換 | toKind(5) |
| 0x31 | 空の配列のpop | popEmpty |
| 0x32 | 配列の範囲外の読み取り | at(0) |

`unchecked`の内と外の境界（`forge test --offline --match-contract "Checked186Test|Loop186Test" -vv`、トレースは`-vvvv`から抜粋）：

```
[PASS] test_subWrapWraps() (gas: 12210)
Logs:
  unchecked 5 - 6 115792089237316195423570985008687907853269984665640564039457584007913129639935

[PASS] test_mulPanicsAndWrapIsZero() (gas: 21127)
Logs:
  unchecked 2 * 2**255 0
    │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)

[PASS] test_uncheckedDoesNotReachCalledFunction() (gas: 9018)
    │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)

[PASS] test_divByZeroStillReverts() (gas: 8812)
    │   └─ ← [Revert] panic: division or modulo by zero (0x12)

[PASS] test_conversionNotChecked() (gas: 11747)
Logs:
  uint64(2**64) 0

[PASS] test_powRightAssoc() (gas: 12536)
Logs:
  2 ** 3 ** 2 512

[PASS] test_negMinPanics() (gas: 8958)
    │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
```

| よくある考え | テスト | 結果 |
|---|---|---|
| 0.8からオーバーフローはすべて止まる | narrow(2^64) | 0、差し戻しなし |
| uncheckedはブロックの中をすべて外す | subViaCall(5, 6) | Panic 0x11 |
| uncheckedはブロックの中をすべて外す | divWrap(1, 0) | Panic 0x12 |

ループのカウンタ。`forge inspect --offline src/Loop186.sol:Loop186 ir`で、forLoopとforUncheckedの`++i`はどちらもチェックのない`increment_wrapping_t_uint256`、whileLoopの`++i`はチェックのついた`increment_t_uint256`である。

```
function increment_wrapping_t_uint256(value) -> ret {
    ret := cleanup_t_uint256(add(value, 1))
}
function increment_t_uint256(value) -> ret {
    value := cleanup_t_uint256(value)
    if eq(value, 0xffff…ffff) { panic_error_0x11() }
    ret := add(value, 1)
}
```

n = 100のガス（gasleftの差）は、via-IRでforLoop 11,109 / forUnchecked 9,010 / whileLoop 11,390、legacyで10,836 / 10,877 / 17,056である。二つのビルドで順位が入れ替わるので、チェックが外れたかどうかはIRの関数名で判断する。

`market`でチェックのない行を探した結果（行の内容の一部は省略）。`unchecked`はバージョン説明のコメント一行だけで、コードの行は0か所である。

```
$ grep -rn "unchecked" src
src/Market.sol:39:// … ガスを節約するために外したチェックなし(unchecked・アセンブリ・…)
$ forge lint --only-lint unsafe-typecast
warning[unsafe-typecast]: typecast can truncate values
   ╭▸ src/MarketMath.sol:33:27
33 │         self.lastUpdate = uint64(block.timestamp);
warning[unsafe-typecast]: typecast can truncate values
   ╭▸ src/MarketMath.sol:41:27
41 │         self.lastUpdate = uint64(block.timestamp);
   ├ note: consider disabling this lint if you're certain the cast is safe
```

`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline --match-contract Cast49Test -vv`。2^64 + 5秒に預け入れると、lastUpdateがPanicなしに5に切り詰められ、elapsedOf（`block.timestamp - p.lastUpdate`）が2^64秒にずれる。この写しのテスト全体は41スイート113個が通る。

```
[PASS] test_lastUpdateFitsNow() (gas: 149082)
Logs:
  lastUpdate 1800000000

[PASS] test_lastUpdateTruncatesPast2pow64() (gas: 157697)
Logs:
  lastUpdate 5
  elapsedOf  18446744073709551616
```

`python -I -X utf8 tools/bugs184.py <リポジトリ>/docs`で見た0.8.30の既知のバグと修正版：

| バグ | severity | 修正版 |
|---|---|---|
| InheritanceOrderReversalOnStorageEndWarning | medium | 0.8.36 |
| UnsoundSpillInMutualRecursion | medium | 0.8.36 |
| TransientStorageClearingHelperCollision | high | 0.8.34 |
| LostStorageArrayWriteOnSlotOverflow | low | 0.8.32 |

### 試すときの注意

- 0.8.0の算術の変更は、080のドキュメントの"Silent Changes of the Semantics"の節にある。0.7.6の`a - b`は0.8.30で警告なしにコンパイルされ、答えだけが変わる。
- 0.8より前にデプロイされたコントラクトを0.8.30のコードから呼んでも、向こうのコードの中の算術のルールは向こうのバージョンが決める。古いバージョンのデプロイ済みのコードは、今も一周する。
- `unchecked`は、そのブロックに直接書いた算術のオーバーフローチェックだけを外す。ブロックの中で呼んだ関数の中はチェックのままで、0での割り算は相変わらずPanic 0x12で差し戻す（EVMのDIVは0で割ると0を返す）。
- 明示的な変換（`uint64(a)`）は、`unchecked`の外でもチェックがない。Marketの`uint64(block.timestamp)`の二行は、block.timestampが2^64秒（約5,845億年）より小さいとみなしてそのままにした。
- 0.8.22から、条件に合うforのカウンタのオーバーフローチェックをコンパイラが外す（条件：`for (uint i = X; i < Y; ++i)`の形、組み込みの`<`、組み込みの整数のローカル変数、本体と条件式でカウンタを変えない）。この段階はoptimizerを切っても動く。
- 0.8.0から`a ** b ** c`は`a ** (b ** c)`とまとめる（2 ** 3 ** 2 = 512、それ以前は64）。古い意味を守るには括弧をつける。int8の-128の符号を反転するとPanic 0x11で、符号なし整数の前の`-`はコンパイルが止まる。
- 0.8.0からABI coder v2が既定である。型に合わないデータなら、v1で差し戻されなかった呼び出しも差し戻されることがある。
- 同じ`pragma solidity ^0.8.0`でも、バージョンごとに通る文法と警告が違う。0.8.31は既定のEVMをosakaに変え、`send`・`transfer`とvirtual modifierに非推奨の警告を足し、0.8.36はイベントのNatSpecの`@return`を禁止した。バージョンを上げたら、ガスの記録も新しいバージョンで作り直し、新しいsolcは受け取ったファイルのハッシュをまず書き留める。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンとデプロイの順番によって値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | 2026-10-21 |
| solc | 0.8.30（新しく取得していない）。bugs・marketともにoptimizerオン（runs 200）、via-IRオン、evm osaka、bugsの`legacy`プロファイルはvia_ir = false | 2026-10-21 |
| 0.7.6のビルド成果物 | 以前に作ったもの、新しくコンパイルしていない。コードの末尾`430007060033` | 2026-10-21 |
| anvilへのデプロイ | アカウント0番、0.7.6のバージョン0x5FbDB2315678afecb367f032d93F642f64180aa3 / 0.8.30のバージョン0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512。デプロイの順番によって変わる | 2026-10-21 |
| Changelogのバージョンの日付 | 0.8.0 2020-12-16、0.8.4 2021-04-21、0.8.22 2023-10-25、0.8.30 2025-05-07、0.8.31 2025-12-03、0.8.32 2025-12-18、0.8.34 2026-02-18、0.8.35 2026-04-29、0.8.36 2026-07-09 | 2026-10-21 |
| 0.8.30の既知のバグ | 四つ：InheritanceOrderReversalOnStorageEndWarning（medium、0.8.36で修正）、UnsoundSpillInMutualRecursion（medium、0.8.36）、TransientStorageClearingHelperCollision（high、0.8.34）、LostStorageArrayWriteOnSlotOverflow（low、0.8.32） | 2026-10-21 |
| ループのガス | n = 100、テストの中のgasleftの差。via-IRでforLoop 11,109 / forUnchecked 9,010 / whileLoop 11,390。既定の経路で10,836 / 10,877 / 17,056。via-IRでforLoop・forUncheckedが違う理由は確認できていない | 2026-10-21 |
| テストのガス（bugs） | Checked186Test：conversionNotChecked 11,747 / divByZeroStillReverts 8,812 / mulPanicsAndWrapIsZero 21,127 / negMinPanics 8,958 / panicCodes 53,412 / powRightAssoc 12,536 / subPanics 9,216 / subWrapWraps 12,210 / uncheckedDoesNotReachCalledFunction 9,018 | 2026-10-21 |
| テストのガス（market） | Cast49Test：lastUpdateFitsNow 149,082 / lastUpdateTruncatesPast2pow64 157,697。全体41スイート113個が通過 | 2026-10-21 |
| 2^64秒 | 18,446,744,073,709,551,616秒 ≈ 5,845億年 | 2026-10-21 |
| BEC事件 | BeautyChain（BEC）、2018。掛け算一行のオーバーフロー | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| バージョンを実際に上げる判断と手順 | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| 倍率のある値の掛け算・割り算とオーバーフロー | [第194講](../../part13/lecture194/)、[第195講](../../part13/lecture195/)、[第196講](../../part13/lecture196/) |
| uncheckedを使った標準実装の行を読む | [第188講](../../part12/lecture188/) |
| リポジトリのサーバーでのバージョンの固定とバグ一覧の照合 | [第258講](../../part20/lecture258/) |
| BEC事件の経緯 | [第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/) |
| via-IRでforLoop・forUncheckedのガスが違う理由 | 付録（時効性のシート） |

出典と参考資料は[reference.md](reference.md)にまとめた。
