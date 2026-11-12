# 第120講 外の変数にアクセスする規則

第7部 アセンブリとYul・第27章 インラインアセンブリ

[← 第119講](../../part7/lecture119/) | [第7部 目次](../) | [第121講 →](../../part7/lecture121/)

## この講義の問い

アセンブリブロックで外のSolidityの変数名を使うと何が入ってきて、ある名前はなぜそのまま使えず、その道でスロットに書いた値はどんなチェックを通らないのか。

## 実習資料

### 準備

Foundryのプロジェクトを二つ使う。`demo`は`Vars120.sol`一つだけを置いたプロジェクトで、`market`は通しプロジェクトMarketの第120講のバージョンである。どちらもsolc 0.8.30、optimizerは切った既定値で、forge-std（`lib/forge-std`）が必要である。`Vars120`は、ローカルのanvilで新しく立ち上げたチェーンでアカウント0番が2回デプロイし（`$V`、`$W`）、アカウント1番が`cast send`で送った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Vars120.sol](code/demo/src/Vars120.sol) | 外の名前がブロックで何になるか。状態変数の`.slot`・`.offset`、memory変数のアドレス、calldataの`.offset`・`.length`、外部関数の値の`.address`・`.selector`、スロットを丸ごと書く`pokeSlot0`と1バイトだけ直す`pokeSmall` |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第120講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第120講のバージョン。第119講のバージョンとコードが同じで、バージョンを説明するコメントを1行だけ足した |
| [code/market/test/Assembly.t.sol](code/market/test/Assembly.t.sol) | テスト用の`MarketSlots`（Marketを継承して`.slot`でスロット番号を取り出す）と、スロットマップを確かめるテスト二つ |
| [code/market/test/](code/market/test/) | Marketのテスト51個 |

`smallLocal`・`smallLocalWide`・`smallLocalRaw`はこの講義では呼ばない（短い型の上位ビットは第121講）。

アクセスエラーの事例は、下のひな形の関数一つに行を入れて`forge build`で確かめた。

```solidity
contract X {
    uint256 big;
    uint256 constant K = 7;
    uint256 immutable IM;
    constructor() { IM = 9; }
    // ここに事例の関数を1行
}
```

| 事例 | ブロックの中の行 | 結果 |
|---|---|---|
| 状態変数の名前 | `r := big` | Error (1408) `Only local variables are supported. To access state variables, use the ".slot" and ".offset" suffixes.` |
| 状態変数の`.slot` | `r := sload(big.slot)` | 通る |
| constant | `r := K` | 通る |
| immutable | `r := IM` | Error (3773) `Assembly access to immutable variables is not supported.` |
| calldataの配列の名前 | `r := d` | Error (1397) |
| calldataの`.offset`・`.length` | `o := d.offset l := d.length` | 通る |
| viewで`sstore`・`call`・`delegatecall`・`log0`・`create`・`tstore` | | Error (8961) |
| viewで`staticcall`・`selfbalance()` | | 通る |
| pureで`sload`・`address()`・`caller()` | | Error (2527) |
| pureで`mload(0x40)` | | 通る |
| 外の名前と同じ`let`（ローカル・状態） | `let x := 2`、`let big := 2` | Error (3859) |
| ブロックの`let`を外で使う | `assembly { let y := 2 } r = y;` | Error (7576) |
| storageのローカル変数の`.slot`に代入 | `a.slot := 5` | 通る |
| 状態変数の`.slot`に代入 | `big.slot := 5` | Error (4713) |
| memory変数にアドレスを代入 | `b := 0x80` | 通る |
| 外部・内部関数の値 | `fp.address`、`fp.selector`、`r := fp` | 通る |

### 実行結果

`slots()`では、small・small2・stageがスロット0のオフセット0・1・2、big・arr・balがスロット1・2・3である。

```
0
0
0
1
0
2
1
2
3
```

名前ごとに入ってくる値（`cast call`の出力）。

```
$ cast call $V "memoryRef()(uint256,uint256,uint256)"
128
5
128
$ cast call $V "calldataRef(bytes)(uint256,uint256,bytes32)" 0x68656c6c6f
68
5
0x68656c6c6f000000000000000000000000000000000000000000000000000000
$ cast call $V "storageRef()(uint256)"
2
$ cast call $V "constantValue()(uint256)"
7
$ cast call $V "fnParts()(address,bytes4,uint256)"
0x5FbDB2315678afecb367f032d93F642f64180aa3
0x00000000
1547088262 [1.547e9]
$ cast call $V "fnSelectorShifted()(bytes4)"
0x5c36b186
$ cast sig "ping()"
0x5c36b186
```

`.selector`は右寄せの4バイトなので、`bytes4`の欄にそのまま入れると0x00000000になり、`shl(224, …)`でずらしてはじめて`ping()`のセレクタが出る。

Solidityの行で書いたあとのスロット0（`setSmall(5)`、`setStage(1)`）、範囲外のenumの値（`setStage(7)`）、アセンブリでスロット0を丸ごと書いたあと（`pokeSlot0(300)`）。

```
$ cast call $V "rawSlot(uint256)(bytes32)" 0
0x0000000000000000000000000000000000000000000000000000000000010005
$ cast send setStage(uint8) 7
... execution reverted: panic: failed to convert value into enum type (0x21) ...
$ cast call $V "rawSlot(uint256)(bytes32)" 0
0x000000000000000000000000000000000000000000000000000000000000012c
small() 44 / small2() 1 / stage() 0
```

2回目のデプロイで`.offset`を使って1バイトだけ直した`pokeSmall(300)`と、続けて`pokeSlot0(0x070005)`でstageの位置に7を入れたあと。

```
$ cast call $W "rawSlot(uint256)(bytes32)" 0
0x000000000000000000000000000000000000000000000000000000000001002c
small() 44 / small2() 0 / stage() 1
$ cast call $W "rawSlot(uint256)(bytes32)" 0
0x0000000000000000000000000000000000000000000000000000000000070005
$ cast call $W "stage()(uint8)"
Error: execution reverted: panic: failed to convert value into enum type (0x21)
```

gasUsed: `setSmall(5)` 43,800、`setStage(1)` 26,868、`pokeSlot0(300)` 26,699、`pokeSmall(300)` 26,797。

Market 第120講のバージョンは、`forge build --sizes`でMarketがruntime 7,353 / initcode 7,931、MarketSlotsが7,744 / 8,016で、`forge test`は51個（AssemblyTestの2個を含む）がすべて通る。

### 試すときの注意

- 状態変数は名前だけでは使えず、`.slot`・`.offset`をつけなければならない。状態変数の`.slot`には代入できないが、storageのローカル変数の`.slot`には代入できる。
- immutableはブロックで読めない（3773）。Marketを継承したテスト用のコントラクトで`admin`を読んでも同じエラーが出る。
- ブロックで`sstore`で書いた値は、enumの範囲チェックを通らない。書く側は通り、その値をSolidityで読む側でPanic 0x21が出る。
- view関数で`staticcall`はでき、`call`・`delegatecall`・`tstore`はできない。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| Vars120のgasUsed | アカウント1番のsetSmall(5) 43,800 / setStage(1) 26,868 / pokeSlot0(300) 26,699 / pokeSmall(300) 26,797 / pokeSlot0(0x070005) 26,699（2番目のVars120でもsetSmall・setStageは43,800 / 26,868） | 2026-10-19 |
| デプロイのアドレス | anvilを新しく立ち上げてからアカウント0番がVars120を2回: `0x5FbDB2315678afecb367f032d93F642f64180aa3`（`$V`）、`0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`（`$W`） / アカウント1番 `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`（公開されたテスト用の鍵） | 2026-10-19 |
| 第120講のバージョンのサイズ | Market runtime 7,353 / initcode 7,931、MarketSlots 7,744 / 8,016 | 2026-10-19 |
| 第120講のバージョンのテスト | 51個が通る（AssemblyTestの2個を含む） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| メモリの先頭の欄（scratch・ゼロの欄）、フリーメモリポインタを動かす規則、`memory-safe` | [第121講](../../part7/lecture121/) |
| 短い型の変数にアセンブリで入れた値の上位ビット | [第121講](../../part7/lecture121/) |
| ブロックで`call`・`staticcall`・`delegatecall`を呼ぶ形 | [第122講](../../part7/lecture122/) |
| アセンブリでストレージの読み書きを減らしてガスを節約する場合 | [第123講](../../part7/lecture123/) |
| スロット番号を決める規則の全体（マッピング・配列の欄の計算、一つのスロットに一緒に入る条件） | [第135講](../../part8/lecture135/) |
| transient storage（`tstore`・`tload`） | [第136講](../../part8/lecture136/) |
| calldataの配置とABIエンコード（位置の欄・長さの欄の規則） | [第138講](../../part8/lecture138/)、[第141講](../../part8/lecture141/) |
| 監査でブロックの中の状態変更を探す | [第188講](../../part12/lecture188/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
