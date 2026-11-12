# 第122講 低水準の呼び出しのパターン

第7部 アセンブリとYul・第27章 インラインアセンブリ

[← 第121講](../../part7/lecture121/) | [第7部 目次](../) | [第123講 →](../../part7/lecture123/)

## この講義の問い

call・staticcall・delegatecall・create・create2をブロックで直接呼ぶと、欄ごとに何を入れ、Solidityの文法が代わりにやってくれていた確認のうち何が抜けるのか。

## 実習資料

### 準備

Foundryのプロジェクトを二つ使う。`demo`はforge-std（`lib/forge-std`）を置いたプロジェクトに`Calls122.sol`（IEcho、Echo、Boom、Raw、Mini）と確認つきのバージョン`Extra122.sol`（RawChecked）を入れたもので、`market`は通しプロジェクトMarketの第122講のバージョンである。どちらもsolc 0.8.30、optimizerは切った既定値である。ローカルのanvilを新しく立ち上げてアカウント0番がEcho、Raw、Miniの順にデプロイし、状態を変える呼び出しはアカウント1番が`cast send`で送った。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30に固定 |
| [code/demo/src/Calls122.sol](code/demo/src/Calls122.sol) | 呼ばれる側のEcho、コンストラクタがリバートするBoom、手で`staticcall`・`call`・`delegatecall`・`create`・`create2`を呼ぶRaw、fallbackの中でセレクタを`switch`で選ぶMini |
| [code/demo/src/Extra122.sol](code/demo/src/Extra122.sol) | 呼ぶ前に`extcodesize`でコードがあるかを確かめるバージョンと、確かめないバージョン |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第122講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第122講のバージョン。バージョンを説明するコメントを1行だけ足した。src内のアセンブリブロック0個 |
| [code/market/test/Assembly.t.sol](code/market/test/Assembly.t.sol) | 第120講のMarketSlotsに加えて、手で呼んだ`staticcall`・`call`とリバートデータの送り返しを行うテスト用のRawCallerとRawCallTest三つ |
| [code/market/test/](code/market/test/) | Marketのテスト54個 |

### 実行結果

セレクタ（`cast sig`）: value() 0x3fa4f245、two() 0x5fdf05d7、fail() 0xa9cc4718、store(uint256) 0x6057361d、Nope(uint256) 0x63a2a81f。

RawがEchoを呼んだ結果（`cast call`の出力を関数名の横にまとめた）。

```
viaSolidity(Echo)   42
viaAssembly(Echo)   1 / 42
cut(Echo)           1 / 0 / 64
whole(Echo)         1 / 2 / 64
failQuiet(Echo)     0 / 36 / 0x63a2a81f00000000000000000000000000000000000000000000000000000000 / 1
```

`cut`は出力の欄を32バイトに決めておいたので、64バイトの答えのうち先頭の32バイトだけを受け取った。返されたより多くコピーする`overCopy`は、呼び出し全体が失敗する。

```
Error: server returned an error response: error code -32003: EVM error OutOfOffset
```

`failQuiet`は内側の呼び出しが失敗してもリバートしない。送ったあと、Rawの`stored()`が0から99になった（gasUsed 47,699）。`cast call --trace`。

```
  [6367] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::failQuiet(0x5FbDB2315678afecb367f032d93F642f64180aa3)
    ├─ [501] 0x5FbDB2315678afecb367f032d93F642f64180aa3::fail()
    │   └─ ← [Revert] Nope(7)
```

`bubble`は受け取ったリバートデータをそのまま送り返す。`cast calldata "Nope(uint256)" 7`と同じバイトである。

```
Error: execution reverted: Nope(7)

Context:
- server returned an error response: error code 3: execution reverted: custom error 0x63a2a81f: , data: "0x63a2a81f0000000000000000000000000000000000000000000000000000000000000007"
```

コードのないアドレス`0x000000000000000000000000000000000000dEaD`（`cast code`が`0x`）を呼ぶと、`codeless`は1 / trueで終わり、`codelessSolidity`はリバートする。

```
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

確認つきのバージョンRawCheckedは、`viaAssemblyUnchecked`にそのアドレスを渡すと1と見当違いの大きな数（28787144462221680847401787925046340504375377297231814454563058758470628016128）を返し、`viaAssemblyChecked`は`execution reverted, data: "0x"`で止まる。Echoを渡すと、どちらも1と42である。

`delegateStore(Echo, 5)`を送ったあと（gasUsed 30,561）、Rawの`stored()`は5、Echoの`stored()`は0である。

`create2`（salt 1）。Echoのデプロイのコード666バイトのkeccakは`0x64e6a692f8c1f540bc189f83fa6b680ee12371718650468139ba529a4fa4739c`で、`cast create2`があらかじめ計算したアドレスと`deploy2`が返したアドレスが`0xaC670d9EC09d034776DA7FaC6dE869c43B86d667`で一致する。`cast estimate`が出した69,736ガスで送ると、トランザクションは成功（status 1）するのに、そのアドレスのコードは0バイトである。`cast run`。

```
  [48532] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::deploy2(0x0000000000000000000000000000000000000000000000000000000000000001)
    ├─ [169] → new <unknown>@0xaC670d9EC09d034776DA7FaC6dE869c43B86d667
    │   └─ ← [OutOfGas] 0x6080…（作成コード）
    └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
```

`if iszero(a) { revert(0, 0) }`をつけた`deploy2Checked`はestimate 183,877、gasUsed 182,111で、638バイトのコードができた。`deploy2`（salt 2）に`--gas-limit 300000`を与えると、gasUsed 182,070、コード638バイトである。

コンストラクタがリバートするBoomを作ると、`deployBoom()`は`0x0000000000000000000000000000000000000000`を返し、`deployBoomSolidity()`は`execution reverted: no`でリバートする。

Miniは`value()`で42、`two()`で1 / 2を返し、`fail()`は`execution reverted, data: "0x"`である。`forge inspect Mini methodIdentifiers`は空の表で、abiには`fallback() nonpayable`一つだけがある。`cast disassemble`の先頭部分。

```
00000010: PUSH0
00000011: CALLDATALOAD
00000012: PUSH1 0xe0
00000014: SHR
00000015: DUP1
00000016: PUSH4 0x3fa4f245
0000001b: DUP2
0000001c: EQ
0000001d: PUSH1 0x2d
0000001f: JUMPI
00000020: PUSH4 0x5fdf05d7
00000025: DUP2
00000026: EQ
00000027: PUSH1 0x36
00000029: JUMPI
0000002a: PUSH0
0000002b: PUSH0
0000002c: REVERT
```

Market 第122講のバージョンは、`forge build --sizes`でMarketがruntime 7,353 / initcode 7,931、RawCallerが1,217 / 1,245で、`forge test`は54個がすべて通る（RawCallTest三つのガス 44,586 / 42,036 / 13,972）。

### 試すときの注意

- 手で呼んだ`call`は、失敗しても0を返すだけでリバートしない。返された値を確かめる行を自分で書かなければならない。
- コードのないアドレスを呼ぶと、アセンブリの`call`と低水準の`.call`は成功（1、true）で終わる。インターフェースで呼んだSolidityの呼び出しだけが、コードがあるかを確かめてリバートする。
- `create2`も失敗すると0を返す。確認の行がないと、`cast estimate`が出したガスで送ったトランザクションが成功で終わっても、コードができないことがある。
- 出力の欄の長さより長い答えは切られる。残りは`returndatasize`・`returndatacopy`で持ってくる。あるより多くコピーすると、呼び出し全体が失敗する。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 渡せるガスの割合 | 残りのガスの64分の63（EIP-150） | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| 例のコントラクトのサイズ（runtime / initcode） | Echo 638 / 666、Raw 3,904 / 3,932、Mini 122 / 148、Boom 62 / 187 | 2026-10-19 |
| セレクタ | value() 0x3fa4f245、two() 0x5fdf05d7、fail() 0xa9cc4718、store(uint256) 0x6057361d、status() 0x200d2ed2、deposit(address,uint256) 0x47e7ef24、Nope(uint256) 0x63a2a81f、ZeroAmount() 0x1f2a2005 | 2026-10-19 |
| ガス（アカウント1番が送る） | failQuiet status 1・gasUsed 47,699 / delegateStore(Echo, 5) 30,561 / deploy2(salt 1) estimate 69,736、gasUsed 69,736（コード0バイト） / deploy2Checked(salt 1) estimate 183,877、gasUsed 182,111（コード638バイト） / deploy2(salt 2、`--gas-limit 300000`) gasUsed 182,070（コード638バイト） | 2026-10-19 |
| トレース | failQuietの`cast call --trace`のいちばん上の行 6,367、内側のfail() 501 / deploy2の`cast run`のいちばん上の行 48,532、作成のフレーム169・OutOfGas / deploy2Checked(salt 3)のいちばん上の行 160,907、作成のフレーム127,769・638 bytes of code | 2026-10-19 |
| デプロイのアドレス | アカウント0番の順にEcho `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Raw `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Mini `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`、RawChecked（確認つきのバージョンを実行したときの4番目） `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` / create2 salt 1 `0xaC670d9EC09d034776DA7FaC6dE869c43B86d667`、salt 2 `0x7283D75DaE2D36B2848c3317163512Fa066Ca4E4` / Echoのデプロイのコードのkeccak `0x64e6a692f8c1f540bc189f83fa6b680ee12371718650468139ba529a4fa4739c` / アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`、アカウント1番 `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`（公開されたテスト用の鍵） | 2026-10-19 |
| Market 第122講のバージョン | runtime 7,353 / initcode 7,931、linkReferences `{}`、RawCaller 1,217 / 1,245、テスト54個が通る（RawCallTest三つ: 44,586 / 42,036 / 13,972） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| アセンブリで減らすガスと測り方 | [第123講](../../part7/lecture123/) |
| 返ってきたデータの長さを制限する理由と、結果の処理の設計 | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| ファクトリー・プロキシの構造と、delegatecallでコードを入れ替えること | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| ABIエンコードの規則（動的な型の形） | [第141講](../../part8/lecture141/) |
| ディスパッチャの比較の順序とガス | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 渡すガスの64分の63の規則とその危険 | [第170講](../../part11/lecture170/) |
| Yulでコントラクト全体を書く | [第124講](../../part7/lecture124/)、[第125講](../../part7/lecture125/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
