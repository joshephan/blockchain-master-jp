# 第109講 requireの文字列との比較、ガスへの影響

第6部 言語の詳細 ③ コントラクト・第24章 カスタムエラー

[← 第108講](../../part6/lecture108/) | [第6部 目次](../) | [第110講 →](../../part6/lecture110/)

## この講義の問い

同じ検査を理由の文字列で書くときとカスタムエラーで書くときで、どこで値が分かれ、どちらかを選ぶ根拠は何か。

## 実習資料

### 準備

第108講の終わりのMarketのプロジェクトから始め、`require(条件, エラー)`の十三か所を`if (逆の条件) revert エラー(引数);`の形に変え、エラーの一覧の行ごとにテストを一つずつ書く。比較は、Marketの第107講のバージョン・第108講のバージョン・第109講のバージョンを同じローカルのanvilに同じ順番でデプロイして呼んで行う。同じ検査を五通りに書いた小さなコントラクトは、別に作ったデモ用のプロジェクト（`demo`）にある。すべてのプロジェクトはsolc 0.8.30、optimizerは切っていて、既定（レガシー）のパイプラインで、テストにはforge-stdが必要である（`lib/forge-std`）。アカウントはanvilの既定のアカウント（公開されたテスト用の鍵）である。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/src/Cmp.sol](code/demo/src/Cmp.sol) | 同じ検査の五つのバージョン（`ReqStr`、`ReqErr`、`IfErr`、`NoArg`、`Bare`）、エラーの引数にカウンタを入れた`Eval`、理由の文字の長さだけが違う`Len5`・`Len31`・`Len32`・`Len33`・`Len64` |
| [code/demo/bad/Typo.sol](code/demo/bad/Typo.sol) | エラー名の打ち間違い`Shrot`、Error 7576 |
| [code/demo/bad/StrTypo.sol](code/demo/bad/StrTypo.sol) | 理由の文字列の打ち間違い`"not admn"`、ビルドは通る |
| [code/demo/bad/EncErr.sol](code/demo/bad/EncErr.sol) | `abi.encodeError`、0.8.30ではError 9582 |
| [code/demo/foundry.toml](code/demo/foundry.toml) | デモ用のプロジェクトの設定 |
| [code/v108active/src/Market.sol](code/v108active/src/Market.sol) | 比較用：第108講のバージョンからwhenActiveの一行だけをifの形に変えたバージョン |
| [code/market/src/Market.sol](code/market/src/Market.sol) | 第109講のバージョンのMarket。十三か所の検査がすべてifの形、ソースに`require`なし（`assert`一つはそのまま） |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol)、[code/market/src/MockToken.sol](code/market/src/MockToken.sol) | インターフェースとテスト用のトークン |
| [code/market/test/ErrorList.t.sol](code/market/test/ErrorList.t.sol) | この講義で加えたテスト。十二個のエラーごとに、そのエラーでリバートする場合を一つ、`vm.expectRevert`にデータ全体。`FalseToken`でTransferFromFailed・TransferFailedまで |
| [code/market/test/](code/market/test/) | 前の講義で積み上げたテスト |

### 実行結果

Marketの三つのバージョンを同じ条件（コンストラクタはアカウント0番・5e16・80、addAsset 75 → deposit 100 → 失敗四つ → withdraw 30 → setStatus 1 → 止めた市場でdeposit 5）で測った値。失敗する呼び出しは`--gas-limit 300000`で送ってstatus 0を受け取り、データの長さは同じ呼び出しを`eth_call`で見る。

| | 第107講のバージョン | 第108講のバージョン | 第109講のバージョン |
|---|---|---|---|
| runtime / creation | 8,173 / 8,869 B | 7,197 / 7,771 B | 7,177 / 7,751 B |
| デプロイのgasUsed | 1,822,259 | 1,611,500 | 1,607,168 |
| 成功：addAsset、deposit、withdraw、setStatus | 93,730、130,240、59,708、45,732 | 93,761、130,398、59,716、45,739 | 93,730、130,240、59,692、45,732 |
| 失敗：deposit 0、withdraw 150、setStatus、止めた市場のdeposit | 27,008、27,153、21,940、24,702 | 26,909、27,153、21,893、24,836 | 26,759、27,147、21,890、24,833 |
| 失敗した呼び出しのデータ | 100、68、100、100 B | 4、68、36、36 B | 4、68、36、36 B |

デプロイの差は六桁、失敗した呼び出しの差は二〜三桁で、止めた市場のdepositは文字列のバージョンのほうが134安い。

理由の文字の長さだけが違うLenの五つのバージョン。文字は32バイトの欄の単位で入る。

| 同じ検査の理由 | ランタイムのサイズ | リバートデータ |
|---|---|---|
| 5文字、31文字、32文字 | 621 B | 100 B |
| 33文字、64文字 | 659 B | 132 B |

理由の文字は、ランタイムコードにそのまま入っている（`cast from-utf8`、`forge inspect ReqStr deployedBytecode`）。

```
$ cast from-utf8 "not enough deposit"
0x6e6f7420656e6f756768206465706f736974
$ forge inspect --offline ReqStr deployedBytecode | grep -o 6e6f7420656e6f756768206465706f736974
6e6f7420656e6f756768206465706f736974
```

Cmpの五つのバージョン（have 3）。成功した`take(1)`は、`require`の二つ目の位置に`Short(have, want)`を入れたReqErrだけが違う。

| バージョン | runtime | デプロイのgasUsed | 失敗take(5) | リバートデータ | 成功take(1) |
|---|---|---|---|---|---|
| ReqStr | 621 | 208,812 | 23,990 | 100 B | 26,918 |
| ReqErr | 549 | 193,424 | 24,100 | 68 B | 27,033 |
| IfErr | 545 | 192,548 | 24,094 | 68 B | 26,918 |
| NoArg | 492 | 181,084 | 23,741 | 4 B | 26,918 |
| Bare | 446 | 171,408 | 23,700 | 0 B | 26,918 |

`Eval`に条件が真になる値1を入れて順に呼ぶ（`cast send`、`cast call`）。三つの呼び出しはすべて成功したが、`require`の二つのバージョンではエラーの引数の`count()`が動いた。gasUsedはwithIf 21,649、withReq 44,056、withStr 27,666である。

```
$ cast send --unlocked --from $A --json $E "withIf(uint256)" 1
$ cast call $E "calls()(uint256)"
0
$ cast send --unlocked --from $A --json $E "withReq(uint256)" 1
$ cast call $E "calls()(uint256)"
1
$ cast send --unlocked --from $A --json $E "withStr(uint256)" 1
$ cast call $E "calls()(uint256)"
2
```

名前の打ち間違いはビルドが止め、文字列の打ち間違いはそのままビルドされてデプロイされる（`forge build`）。

```
$ forge build --offline --force bad/Typo.sol
Error (7576): Undeclared identifier. Did you mean "Short"?
 --> bad/Typo.sol:8:27:
  |
8 |         if (a > 3) revert Shrot(3, a);
  |                           ^^^^^
$ forge build --offline --force bad/StrTypo.sol
Compiler run successful!
```

デプロイしたStrTypoをアカウント1番で呼ぶと、`execution reverted: not admn`が来る。

ABIなしでノードが返した原文（`cast rpc eth_call`でアカウント1番が`setStatus(2)`、先頭の`Error: server returned an error response: error code 3:`は省略）。文字列はノードが文字として解き、カスタムエラーはセレクタと引数のバイトだけが来る。

```
第107講のバージョン: execution reverted: not admin, data: "0x08c379a0…096e6f742061646d696e…"
第109講のバージョン: execution reverted: custom error 0x17a84242: 00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
```

第109講のバージョンのプロジェクトのフォルダの中で`cast call`をすると、プロジェクトのABIで`NotAdmin(0x7099…79C8)`がつく。

whenActiveだけを変えたバージョンと比べた、成功したdeposit 100のgasUsed。

| バージョン | gasUsed |
|---|---|
| 第107講のバージョン | 130,240 |
| 第108講のバージョン | 130,398 |
| 第108講のバージョン + whenActiveだけifの形 | 130,256 |
| 第109講のバージョン（十三か所すべてifの形） | 130,240 |

ErrorListのテスト（`forge test --mc ErrorListTest`）。全体の`forge test`は41個が通る。

```
[PASS] test_alreadyListed() (gas: 38942)
[PASS] test_insufficientDeposit() (gas: 38550)
[PASS] test_marketFrozen() (gas: 81786)
[PASS] test_notActive() (gas: 82575)
[PASS] test_notAdmin() (gas: 33688)
[PASS] test_notListed() (gas: 38375)
[PASS] test_ratioAboveCap() (gas: 39058)
[PASS] test_transferFailed() (gas: 203879)
[PASS] test_transferFromFailed() (gas: 159143)
[PASS] test_zeroAdmin() (gas: 4912)
[PASS] test_zeroAmount() (gas: 63599)
[PASS] test_zeroAsset() (gas: 33186)
Suite result: ok. 12 passed; 0 failed; 0 skipped
```

エラーの一覧に加えた欄。

| エラー | リバートデータの長さ | テスト |
|---|---|---|
| InsufficientDeposit | 68 | test_insufficientDeposit |
| ZeroAdmin | 4 | test_zeroAdmin |
| NotAdmin | 36 | test_notAdmin |
| MarketFrozen | 4 | test_marketFrozen |
| NotActive | 36 | test_notActive |
| ZeroAsset | 4 | test_zeroAsset |
| AlreadyListed | 36 | test_alreadyListed |
| RatioAboveCap | 68 | test_ratioAboveCap |
| NotListed | 36 | test_notListed |
| ZeroAmount | 4 | test_zeroAmount |
| TransferFromFailed | 36 | test_transferFromFailed |
| TransferFailed | 36 | test_transferFailed |

第107講のバージョンの理由の文字列はすべて32文字以下なので、リバートデータは100バイトだった。

### 試すときの注意

- `require(条件, 二つ目の位置)`は、二つの引数を先に計算してから条件を見る。エラーの引数に状態の読み取りや関数の呼び出しが入ると、成功した呼び出しもそのガスを払う。`if (逆の条件) revert …`は、条件が合うときだけ引数を計算する。
- `abi.encodeWithSelector`は引数の型を確かめない。`vm.expectRevert`にはリバートデータ全体を書いて合わせる。
- 失敗した呼び出しのgasUsedは、`--gas-limit`を与えて送り、status 0のレシートから読んだ。リバートデータは、同じ呼び出しを`eth_call`で送って確かめる。
- バージョン同士を比べるときは、同じanvil、同じコンストラクタの引数、同じ呼び出しの順番を守る。
- solc 0.8.30には`abi.encodeError`がない（Error 9582）。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンや実行環境が変わると、数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30、optimizerは切る（既定値）、既定のEVMバージョン、既定（レガシー）のパイプライン | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-19 |
| anvilのハードフォーク | `anvil_nodeInfo`のhardFork `Bpo1`（既定値）、chainId 31337 | 2026-10-19 |
| `require(条件, カスタムエラー)` | 0.8.26（2024-05-21）はvia-IRのパイプラインでだけ、0.8.27（2024-09-04）からレガシーのパイプラインでも | 2026-10-19 |
| カスタムエラーの導入 | 0.8.4 | 2026-10-19 |
| `abi.encodeError` | solc 0.8.30にはない、Error (9582) | 2026-10-19 |
| 実測の条件 | anvil 1.8.3の既定の設定、送るアカウントは0番、Marketのコンストラクタの引数はアカウント0番・5e16・80、MockToken（アカウント0番に1000）。順番はaddAsset 75 → deposit 100 → deposit 0・withdraw 150・アカウント1番のsetStatus 2（失敗、`--gas-limit 300000`） → withdraw 30 → setStatus 1 → deposit 5（失敗）。Cmpの五つのバージョンはhave 3、失敗`take(5)` `--gas-limit 100000`、成功`take(1)` | 2026-10-19 |
| Marketの三つのバージョン（107 / 108 / 109） | runtime / creation 8,173 / 8,869、7,197 / 7,771、7,177 / 7,751。デプロイのgasUsed 1,822,259 / 1,611,500 / 1,607,168。成功addAsset 93,730 / 93,761 / 93,730、deposit 100 130,240 / 130,398 / 130,240、withdraw 30 59,708 / 59,716 / 59,692、setStatus 1 45,732 / 45,739 / 45,732。失敗deposit 0 27,008 / 26,909 / 26,759、withdraw 150 27,153 / 27,153 / 27,147、アカウント1番のsetStatus 2 21,940 / 21,893 / 21,890、止めた市場のdeposit 5 24,702 / 24,836 / 24,833 | 2026-10-19 |
| whenActiveだけを変えたバージョン | runtime 7,195 / creation 7,769、デプロイ1,611,056、deposit 100 130,256 | 2026-10-19 |
| Cmpの五つのバージョン（ReqStr / ReqErr / IfErr / NoArg / Bare） | runtime 621 / 549 / 545 / 492 / 446。デプロイのgasUsed 208,812 / 193,424 / 192,548 / 181,084 / 171,408。失敗take(5) 23,990 / 24,100 / 24,094 / 23,741 / 23,700。リバートデータ100 / 68 / 68 / 4 / 0バイト。成功take(1) 26,918 / 27,033 / 26,918 / 26,918 / 26,918 | 2026-10-19 |
| Lenの五つのバージョン | 5・31・32文字はruntime 621、リバート100バイト、失敗23,990、デプロイ208,656 / 208,968 / 208,980。33・64文字はruntime 659、132バイト、失敗24,008、デプロイ216,824 / 217,196 | 2026-10-19 |
| Eval | withIf(1) 21,649 calls 0、withReq(1) 44,056 calls 1、withStr(1) 27,666 calls 2（前の呼び出しから続けて数える） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| アセンブリでリバートデータを書いて減らす | [第123講](../../part7/lecture123/) |
| 何から減らすかと、ガスの記録・回帰の確認（`forge snapshot`） | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 受け取ったエラーで次の処理を決める | [第170講](../../part11/lecture170/) |
| 標準と実装が使うエラー | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| 受け取ったデータをどこまで信じるか、わからないエラーの扱い | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| 失敗の経路を性質で検査する | [第183講](../../part11/lecture183/) |
| コンパイラのバージョンごとの違い | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| コードの精読で理由の文字列の比較を探すこと | [第188講](../../part12/lecture188/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
