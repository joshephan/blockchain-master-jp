# 第148講 コードのレイアウト

第9部 最適化と規律・第38章 スタイルガイド

[← 第147講](../../part9/lecture147/) | [第9部 目次](../) | [第149講 →](../../part9/lecture149/)

## この講義の問い

スタイルガイドのコードのレイアウトの規則のうち、forge fmtがそろえてくれるものと、そろえられない、あるいは違う形にそろえるものは何か。書式と宣言の順番を変えると、デプロイ物の何が変わるのか。

## 実習資料

### 準備

通しプロジェクトMarketの第147講のバージョンから始める。第147講のバージョンに初めて`forge fmt --check`をかけると、終了コード1で十個のファイルに`Diff in`が出る。第148講のバージョンは、プロジェクトのルートで`forge fmt`を一度かけてsrcの三つのファイルとtestの七つのファイルの空白・改行だけを直し（手では直していない）、foundry.tomlに`[fmt]`の4行（Foundry 1.8.3の既定値と同じ値）を書き、コミット前の確認スクリプトの先頭に`forge fmt --check`の段階を足した。テストにはforge-stdが必要である（`lib/forge-std`）。スタイルガイドの例のデモは、空のFoundryプロジェクト（`demo/p148`）で`forge fmt --check -r ファイル`で直した結果だけを出力する（`--check`なしで`-r`だけを使うとファイルを直す）。NatSpecの位置の確認は、solc 0.8.30を直接呼んで`solc --userdoc Place.sol`で見る。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | 第147講のバージョンに`[fmt]`（line_length 120、tab_width 4、style space、quote_style double）を足す |
| [code/market/src/](code/market/src/) | Market第148講のバージョン（forge fmtを適用、コードは第147講のバージョンと同じ） |
| [code/market/test/](code/market/test/) | テスト20ファイル（67個のテスト） |
| [code/order/src/Market.sol](code/order/src/Market.sol) | 関数・modifier・定数の宣言の五つのかたまりをドキュメントの順番に移したコピー |
| [code/slot/src/Market.sol](code/slot/src/Market.sol) | 状態変数totalDeposits・totalBorrowsの宣言の順番だけを変えたコピー |
| [code/fmtbad/src/Market.sol](code/fmtbad/src/Market.sol) | assetCountの戻り値の型だけを`uint`と書いたコピー（書式の確認の段階で止まる） |
| [code/demo/p148/src/Bad.sol](code/demo/p148/src/Bad.sol) | スタイルガイドのNoの例を一つのファイルに集めたもの |
| [code/demo/p148/src/More.sol](code/demo/p148/src/More.sol) | 長い宣言、コントラクトのあとのimport、関数のあとのerror |
| [code/demo/p148/src/Width.sol](code/demo/p148/src/Width.sol)、[Width2.sol](code/demo/p148/src/Width2.sol)、[Width3.sol](code/demo/p148/src/Width3.sol) | 1行の長さを測るファイル（かなの行、コメントの行） |
| [code/demo/p148/src/Place.sol](code/demo/p148/src/Place.sol) | NatSpecの`///`を五つの位置に付けてみたファイル |
| [code/demo/p148opt/foundry.toml](code/demo/p148opt/foundry.toml)、[code/demo/p148opt/src/Pow.sol](code/demo/p148opt/src/Pow.sol) | `[fmt]`の設定四つ（int_types preserve、pow_no_space、single_line_statement_blocks single、contract_new_lines）を変えたプロジェクト |
| [code/demo/powdef/](code/demo/powdef/) | 同じPow.solを`[fmt]`なしで（既定値） |
| [code/demo/wrap/foundry.toml](code/demo/wrap/foundry.toml) | `wrap_comments = true`。srcにはmarketと同じファイルを入れて実行 |
| [code/demo/p148/foundry.toml](code/demo/p148/foundry.toml) | デモ用プロジェクトの設定 |

コピーのフォルダにはmarketと違うファイルだけを入れた。

### 実行結果

第147講のバージョンに`forge fmt --check`（前半）：

```
Diff in src\IMarket.sol:
13  13   | interface IMarket {
14  14   |     // 第115講: Marketから移した市場の状態。ABIではuint8
15  15   |     /// @notice 市場の状態。Activeはすべて許可、DepositPausedは預け入れだけ止める、Frozenは資産の追加と引き出しまで止める
16       |-    enum MarketStatus { Active, DepositPaused, Frozen }
    16   |+    enum MarketStatus {
    17   |+        Active,
    18   |+        DepositPaused,
    19   |+        Frozen
    20   |+    }
17  21   | 
18  22   |     // 第107講: 読む側に渡すイベントの規格
19  23   |     // 第115講: Marketはこの宣言を継承して出力する
20  24   |     /// @notice 管理者が資産を上場する
21  25   |     /// @param asset 上場したトークンのアドレス
22  26   |     /// @param ratio その資産の担保比率(パーセント)
23       |-    event AssetAdded(address indexed asset, Ratio ratio);           // topic0 = keccak256("AssetAdded(address,uint8)")
    27   |+    event AssetAdded(address indexed asset, Ratio ratio); // topic0 = keccak256("AssetAdded(address,uint8)")
```

`forge fmt --check -r src/Bad.sol`が直した結果（前半）。コントラクトの間の空行が一つに減り、`uint`は`uint256`になり、`2*y + 3*x`は`2 * y + 3 * x`とすべて空け、`modifier onlyOwner {`には`()`が付く：

```
contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Coin {
    struct Bank {
        address owner;
        uint256 balance;
    }
    mapping(uint256 => uint256) map;
    mapping(address => bool) registered;
    uint256[] xs;
    ...
    function align() public {
        x = 1;
        y = 2;
        longVariable = 3;
        str = "bar";
        x = 3;
        x = 100 / 10;
        x = 2 * y + 3 * x;
        x = (y + x) * (y - x);
    }
```

`Width3.sol`を`forge fmt --check -r`で見た結果。U2は文字数では100字に届かない行だが、かなが3バイトずつなので120バイトを超えて分かれる。英字だけのU3・U4はバイト数がそのまま文字数なので、120を超えるU4だけが分かれる：

```
contract Width3 {
    string constant U1 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaああああああああああ";
    string constant U2 =
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaああああああああああ";
    string constant U3 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    string constant U4 =
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
}
```

`solc --userdoc Place.sol`（`\uXXXX`のエスケープは文字に戻して載せた）。五つの関数すべてにnoticeが付くが、eは`///`の二つのまとまりの間に`//`が挟まっていて、下のまとまり（「Eの二つ目のまとまり」）だけが残る：

```
======= Place.sol:Place =======
User Documentation
{"kind":"user","methods":{"a()":{"notice":"Aのすぐ上"},"b()":{"notice":"Bの上、間に普通のコメント"},"c()":{"notice":"Cのすぐ上、普通のコメントはその上"},"d()":{"notice":"Dの上、間に空行"},"e()":{"notice":"Eの二つ目のまとまり"}},"version":1}
```

バージョンどうしでバイトコードを比べた結果（defaultプロファイル）。第147講のバージョン（base）と比べて、forge fmtを適用したバージョンと宣言の順番を移したバージョンは末尾より前の部分が同じで、状態変数の順番を変えたバージョンは違う：

```
out base runtime 3260 creation 3473 hash4 29d59302 runtime前の部分が同じ True creation前の部分が同じ True 末尾の0バイト 2 rawMetadata 16973
out s148 runtime 3260 creation 3473 hash4 edd3401a runtime前の部分が同じ True creation前の部分が同じ True 末尾の0バイト 2 rawMetadata 16973
out var/order runtime 3260 creation 3473 hash4 c86cf4f9 runtime前の部分が同じ True creation前の部分が同じ True 末尾の0バイト 2 rawMetadata 16973
out var/slot runtime 3260 creation 3473 hash4 0f228990 runtime前の部分が同じ False creation前の部分が同じ False 末尾の0バイト 2 rawMetadata 16973
```

legacy・debugプロファイルも同じ結果である。状態変数の順番を変えたコピーの`forge test`は64個通過、3個失敗である：

```
[FAIL: assertion failed: 5 != 4] test_slotsMatchSlotMap() (gas: 8868)
[FAIL: assertion failed: 0 != 100] test_slotOrder() (gas: 232645)
[FAIL: assertion failed: 0 != 100] test_positionWords() (gas: 30795)
```

宣言の順番を移したコピーは、テスト67個がすべて通る。

レシートのgasUsed（バージョンごとに新しいanvil）：第147講のバージョン、宣言の順番を移したバージョン、第148講のバージョンのどれもデプロイは760,316である。末尾のハッシュの中の0のバイトの数が同じなので、デプロイのガスも変わらない。六つの呼び出しは三つとも同じである（addAsset 92,656、deposit 127,515、withdraw 57,448、setStatus 45,001 / 23,089、失敗26,264）。

第148講のバージョンは`forge fmt --check`が通り、サイズ（runtime / creation）はdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931、三つのプロファイルでテスト67個が通り、`forge snapshot --check`も通る。コミット前の確認は`ci ok`で終わる。戻り値の型だけを`uint`と書いたコピーは、最初の段階でこの差分を見せて終了コード1で止まる：

```
Diff in src\Market.sol:
121 121  |         emit AssetAdded(address(asset), ratio); // 第105講
122 122  |     }
123 123  | 
124      |-    function assetCount() external view returns (uint) {
    124  |+    function assetCount() external view returns (uint256) {
125 125  |         return assets.length;
126 126  |     }
```

`solc --ast-compact-json`で見ると、位置（`src`）の欄を除けば、forge fmtの前後で四つのファイルのASTは同じである。IMarketのdepositのドキュメントの節は`5388:219:0`から`5125:219:0`に変わる。

### 試すときの注意

- forge fmt 1.8.3は1行の120をUTF-8のバイトで数える（かな・漢字1文字は3バイト）。コメントの行と行末のコメントは長さに入れず、分けもしない。第148講のバージョンのsrcで120バイトを超える行は82行で、そのうちコードの行10行はすべて行末のコメントのせいである。
- スタイルガイドとforge fmtの既定値が違うところ：トップレベルの宣言の間の空行二つ（ドキュメント）→ 一つ、例の`uint` → `uint256`、優先順位による空白`2*y + 3*z` → すべて空ける、1行の関数と波かっこのない一文のif → 展開、120に収まる複数行のイベント → 1行。`int_types = "preserve"`、`pow_no_space`、`single_line_statement_blocks`で一部を変えられ、空行二つと優先順位による空白は設定がない。
- forge fmtは宣言の順番（コントラクトのあとのimport、関数のあとのerror）を移さず、コメントも直さない。`///`のまとまりの位置もそのままにする（Place.solは`--check`が通る）。
- `wrap_comments = true`をオンにしても、コメントは空白の位置でしか切れない。空白の少ない日本語のバージョン説明のコメントは、切ったあとも120バイトを超える行が46行残る（最長326バイト）。
- 関数の宣言の順番を移しても末尾より前の部分とガスは同じだが、状態変数の順番を変えるとスロットが変わり、バイトコードとテストの結果が変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると既定値と数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。第148講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyがデフォルトの経路 + optimizerオン、debugがデフォルトの経路でoptimizerオフ、evm_version osaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 (Commit `cae51ad`) | 2026-10-20 |
| 公式ドキュメントの版 | Solidity Style Guide v0.8.36（`docs/style-guide.rst` 1,345行）。引用11〜13、15〜16、18〜20、22〜23、29、31、42、47、49、54、149〜156、263、268、310〜322、397〜451、481〜524、553〜561、573〜575、638、642〜644、649〜655、682〜685、732〜733、835〜837、864〜874、927、935〜937、942〜980、986、1002、1024〜1035、1049〜1071、1092〜1095、1146〜1147、1162、1311〜1313、1343行 | 2026-10-20 |
| forge fmtの既定値 | line_length 120、tab_width 4、style space、bracket_spacing false、int_types long、multiline_func_header attributes_first、quote_style double、number_underscore preserve、hex_underscore remove、single_line_statement_blocks preserve、override_spacing false、wrap_comments false、docs_style preserve、ignore []、contract_new_lines false、sort_imports false、namespace_import_style prefer_plain、pow_no_space false、prefer_compact all、single_line_imports false | 2026-10-20 |
| forge fmtの1行の長さ | 120をUTF-8のバイトで数える（かな・漢字1文字は3バイト）、コメントの行と行末のコメントは長さに入れず分けない | 2026-10-20 |
| 120バイトを超える行 | 第148講のバージョンのsrc 82（IMarket 10、Market 63、MarketMath 5、MarketTypes 4）、コードの行10（すべて行末のコメント） | 2026-10-20 |
| wrap_commentsをオンにしたとき | コメントは空白の位置でだけ切れる。Market.solのコメントの行93 → 161、120バイトを超えるコメントの行58 → 46（最長326バイト） | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | default 第147講のバージョン`29d59302` / 第148講のバージョン`edd3401a` / 宣言の順番を移したコピー`c86cf4f9` / 状態変数を変えたコピー`0f228990`。legacy `ac6ec7be` / `2db8a714` / `f2c07e82` / `34daf516`。debug `07dd09eb` / `8d2b6100` / `d1b70d3e` / `00368d20`。どのバージョンもdefaultの末尾53バイトの中の0のバイトは2 | 2026-10-20 |
| ASTの位置の欄 | 第147講のバージョンのIMarketのdeposit関数の節`5612:57:0`、ドキュメントの節`5388:219:0` → 第148講のバージョン`5349:57:0`、`5125:219:0`。位置の欄の数IMarket 395、Market 878、MarketMath 160、MarketTypes 166 | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第147講のバージョン・宣言の順番を移したコピー・第148講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264。アドレスはMockToken `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Market `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` | 2026-10-20 |
| デプロイデータのバイトの値 | 0のバイト4、0でないバイト16 | 2026-10-20 |
| サイズ（runtime / creation） | 第148講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 行番号 | 第148講のバージョンdebug deposit 0 src/Market.sol 161:33、NotActive 76行、`contract Market` 205行、コンストラクタ215〜218行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`（anvilの既定のアカウント、公開されたテスト用の鍵） | 2026-10-20 |
| ドキュメントのOrder of Layoutの版の履歴 | v0.8.36のドキュメントだけを確認（ファイル：Pragma、Import、Events、Errors、Interfaces、Libraries、Contracts）。以前の版でのErrorsの位置など、変わった履歴は確認できていない | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 命名規則（名前の形、アンダースコア、ファイル名）とforge lint | [第149講](../../part9/lecture149/) |
| 状態変数の順番とアップグレードのスロットの衝突 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 監査でレイアウトがドキュメントと違う場所を読む順番 | [第188講](../../part12/lecture188/) |
| リポジトリのサーバーで書式の確認を実行する | [第258講](../../part20/lecture258/) |
| ドキュメントのOrder of Layoutがバージョンごとに変わった履歴（Errorsの位置など） | 付録の時効性データシート |

出典と参考資料は[reference.md](reference.md)にまとめた。
