# 第159講 ERC-165と標準の読み方

第10部 標準とアップグレード・第41章 標準の設計思想

[← 第158講](../../part10/lecture158/) | [第10部 目次](../) | [第160講 →](../../part10/lecture160/)

## この講義の問い

コントラクトに「この標準に従っているか」と尋ねると何がわかり、標準の文書はどんな順番と重みで読むのか。

## 実習資料

### 準備

プロジェクトは二つある。`demo`は、第154〜158講のデモのトークン・金庫（Nft、Multi、OzToken、Vault）と、ERC-165の答えを試すコントラクト三つ（Liar、SelectiveLiar、GasHog）、Marketのソースのコピー（`src/market/`）を置いたデモ用プロジェクトである。`market`は通しプロジェクトMarketの第159講のバージョン（第41章末のバージョン）である。すべての実行はanvilなしでforgeの中で動く（通しプロジェクトのガスだけローカルのanvil）。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0（ERC721、ERC1155、ERC4626、ERC165Checker）である。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/Claims.sol](code/demo/src/Claims.sol) | 何を尋ねてもtrueのLiar、ERC-165・ERC-721にだけtrueのSelectiveLiar、ループでガスを使うGasHog |
| [code/demo/src/Nft.sol](code/demo/src/Nft.sol) | OpenZeppelinのERC721のデモ用トークン（第156講） |
| [code/demo/src/Multi.sol](code/demo/src/Multi.sol) | OpenZeppelinのERC1155のデモ用トークン（第157講） |
| [code/demo/src/OzToken.sol](code/demo/src/OzToken.sol) | OpenZeppelinのERC20のデモ用トークン（第154講） |
| [code/demo/src/Vault.sol](code/demo/src/Vault.sol) | OpenZeppelinのERC4626のデモ用金庫（第158講） |
| [code/demo/src/market/](code/demo/src/market/) | Marketのsrcの五つのファイルのコピー |
| [code/demo/test/Introspect.t.sol](code/demo/test/Introspect.t.sol) | インターフェースID九つ、ERC165Checkerで尋ねる、生の答え、SelectiveLiarのテスト四つ |
| [code/demo/test/Ids159.t.sol](code/demo/test/Ids159.t.sol) | EIP-165の原文の例Solidity101、IDに入らないものを見るShapeA・B・C |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第159講のバージョンのsrcの五つのファイル。コードは第158講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/Introspection.t.sol](code/market/test/Introspection.t.sol) | 第159講で足したIntrospectionTestの二つ（IMarketのID 0xab691738、ERC-165の答えなし） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

`demo`で`forge test --offline --match-contract Ids159Test -vv`。EIP-165の原文の例（原文はpragma ^0.4.20、0.8.30の文法に移した）の二つのセレクタをXORするとIDになる（0x19ff1d21 XOR 0xdf419679 = 0xc6be8b58）：

```
  0x19ff1d21   hello()
  0xdf419679   world(int256)
  0xc6be8b58   type(Solidity101).interfaceId
```

戻り値の型・イベント・エラー・viewが違ってもIDは同じで（ShapeA・B）、関数名が一つ違うとIDが変わる（ShapeC、owed → debt）：

```
  A 0x1b1f8831   B 0x1b1f8831   C 0x5f6b3e9a
```

この章の標準のインターフェースID（test_ids、OpenZeppelin 5.4.0のインターフェースとsolc 0.8.30の`type(I).interfaceId`）：

| インターフェース | ID |
|---|---|
| IERC165 | 0x01ffc9a7 |
| ERC-20の必須の六つ（OpenZeppelinのIERC20） | 0x36372b07 |
| IERC721 / 721の受け取る側（IERC721Receiver） | 0x80ac58cd / 0x150b7a02 |
| IERC1155 / 1155の受け取る側（IERC1155Receiver） | 0xd9b67a26 / 0x4e2312e0 |
| IERC4626（継承したERC-20の関数を除く） | 0x87dfe5a0 |
| MarketのIERC20 / IMarket | 0xfa1d6c57 / 0xab691738 |

IMarketのIDには、直接書いた関数九つと自動ゲッター十がすべて入る。列挙型の引数はABIの型uint8としてシグネチャに入るので、IMarketのIDに入る値は`0x2e49d78b`である：

```
$ cast sig "setStatus(uint8)"
0x2e49d78b
$ cast sig "setStatus(MarketStatus)"
0xcd2f32d3
```

OpenZeppelinのERC165Checkerで尋ねた結果（test_detect）：

| 相手 | ERC-165 | ERC-721 | ERC-1155 |
|---|---|---|---|
| Nft（OpenZeppelinのERC721） | true | true | false |
| Multi（OpenZeppelinのERC1155） | true | false | true |
| OzToken、Vault、Market、EOA | false | false | false |
| Liar（何を尋ねてもtrue） | false | false | false |
| GasHog（ループ2,000回） | false | false | false |
| SelectiveLiar | true | true | false |

`forge test --offline --match-test "test_selectiveLiarCall|test_rawAnswers" -vvvv`の生の答え。Liarは二つ目の質問0xffffffffにもtrueなので、ERC-165ではないと判定される。GasHogはガス30,000の中で終われず、そのまま呼ぶと90万ガス以上を使う：

```
├─ [583] Liar::supportsInterface(0xffffffff) [staticcall]
│   └─ ← [Return] true
├─ [30000] GasHog::supportsInterface(0x01ffc9a7) [staticcall]
│   └─ ← [OutOfGas] EvmError: OutOfGas
├─ [937092] GasHog::supportsInterface(0x01ffc9a7) [staticcall]
│   └─ ← [Return] true
```

SelectiveLiarは三つの質問を通るが、ERC-721の関数が一つもないので、ownerOf(1)がデータなしに失敗する：

```
[PASS] test_selectiveLiarCall() (gas: 40680)
Logs:
  ownerOf ok false 0
  ├─ [621] SelectiveLiar::supportsInterface(0x01ffc9a7) [staticcall]
  │   └─ ← [Return] true
  ├─ [647] SelectiveLiar::supportsInterface(0xffffffff) [staticcall]
  │   └─ ← [Return] false
  ├─ [647] SelectiveLiar::supportsInterface(0x80ac58cd) [staticcall]
  │   └─ ← [Return] true
  ├─ [21510] SelectiveLiar::ownerOf(1)
  │   └─ ← [Revert] unrecognized function selector 0x6352211e for contract 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, which has no fallback function.
```

`market`で`forge test --offline --match-contract IntrospectionTest -vvvv`。MarketにはsupportsInterfaceもfallbackもないのでガス30,000のstaticcallが失敗し、返ってきたデータは0バイトである：

```
[PASS] test_noErc165() (gas: 4660)
    ├─ [482] Market::supportsInterface(0x01ffc9a7) [staticcall]
    │   └─ ← [Revert] unrecognized function selector 0x01ffc9a7 for contract 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, which has no fallback function.
```

```
[PASS] test_iMarketInterfaceId() (gas: 222)
[PASS] test_noErc165() (gas: 4660)
```

五つの標準の文書の冒頭の行：

| 文書 | status | created | requires |
|---|---|---|---|
| ERC-20 | Final | 2015-11-19 | なし |
| ERC-721 | Final | 2018-01-24 | 165 |
| ERC-1155 | Final | 2018-06-17 | 165 |
| ERC-4626 | Final | 2021-12-22 | 20, 2612 |
| ERC-165 | Final | 2018-01-23 | 214 |

五つの文書の大文字の語の数。文書全体で数え、MUST NOT・SHOULD NOTは別に数えてMUST・SHOULDから引いた。4626の`_NOT_`の形はNOTとして、721・1155は語の一覧の行（39・31行）を含めた：

| 文書 | MUST | MUST NOT | SHOULD | そのほか |
|---|---|---|---|---|
| ERC-20 | 7 | 4 | 4 | OPTIONAL 3 |
| ERC-721 | 8 | 1 | 1 | SHOULD NOT 1、MAY 8、SHALL 5、OPTIONAL 3、REQUIRED 1、RECOMMENDED 1 |
| ERC-1155 | 160 | 5 | 19 | SHOULD NOT 2、MAY 37、SHALL 2、RECOMMENDED 3、OPTIONAL 1、REQUIRED 1 |
| ERC-4626 | 45 | 28 | 8 | MAY 12 |
| ERC-165 | 0 | 0 | 0 | なし（82行も小文字のmust） |

Market第159講のバージョンの点検：`forge build --offline --sizes`でMarket 3,260 / 3,473、`forge test --offline`と`FOUNDRY_PROFILE=debug`・`legacy`はいずれも88個が通過、`.gas-snapshot` 88行、`bash ci.sh`は七つの段階のあとで`ci ok`。

第41章末のMarketの標準の対照表：

| 標準 | Marketが立つ側 | Marketにあるもの | Marketにないもの | 確認するテスト |
|---|---|---|---|---|
| ERC-20 | 呼ぶ側（資産のトークン） | IERC20の三つ：balanceOf・transferFrom・transfer（ID 0xfa1d6c57、標準の必須の六つは0x36372b07） | totalSupply・approve・allowance・イベント二つは呼びも読みもしない。Market自身はトークンではない | test/Standard.t.sol |
| ERC-20の承認 | 承認を受け取る側 | depositのtransferFrom(msg.sender, Market, amount)の一か所、返ってきたboolの確認 | fromを引数で受け取る関数なし、approve・permitは呼ばない | test/Allowance.t.sol、test/ErrorList.t.sol（FalseToken） |
| ERC-721 | 該当なし（資産として上場するとdepositが巻き戻る） | なし | onERC721Receivedなし。safeTransferFromは巻き戻り、transferFromで入ってきたNFTは取り出す関数なし | test/Nft.t.sol |
| ERC-1155 | 該当なし | 資産の欄はアドレス一つにトークン一つ | idの欄なし、onERC1155Received・onERC1155BatchReceivedなし。ERC-1155のアドレスはdepositが巻き戻る | test/Multi.t.sol |
| ERC-4626 | 従わない（形の対照だけ） | deposit(address,uint256)・withdraw(address,uint256)、帳簿totalDeposits・positions | 持ち分のトークン・receiver・owner引数・convert・preview・maxの関数なし、直接送ったトークンは数えない | test/Donation.t.sol、test/Receive.t.sol |
| ERC-165 | 答えない | IMarketのインターフェースID 0xab691738 | supportsInterfaceなし（確認の最初の質問で失敗） | test/Introspection.t.sol |

第41章でMarketに足したテストは75 + 13 = 88個である（Standardの四つ、Allowanceの二つ、Nftの二つ、Multiの一つ、Donationの二つ、Introspectionの二つ）。srcのコードは第39章末のバージョンのままで、Market.solではバージョン説明のコメント6行と、第111講の古いコメントの修正1行だけが変わった。

### 試すときの注意

- インターフェースIDは関数セレクタのXORなので、関数名と引数の型だけを含む。戻り値、イベント、エラー、viewかどうか、動作は含まない。
- ERC-165の確認は質問二つである。0x01ffc9a7にtrue、0xffffffffにfalseでなければならず、それぞれの質問はガス30,000のstaticcallである。OpenZeppelinのERC165Checkerの関数はすべてinternalなので、使うコントラクトのデプロイ物の中にコードごと入る。
- supportsInterfaceのtrueは、コントラクトが自分でする答えである。SelectiveLiarのように答えだけ合わせて関数がないこともあるので、関数を呼んでみないとわからない。
- ERC-20とERC-4626はERC-165を求めない。OzTokenとVaultはERC-165で尋ねるとfalseと読まれる。
- GasHogをそのまま呼んだガス940,443は`gasleft()`の差で測った値で、トレースの数937,092とは違う（optimizerオフのデモ用ビルド）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30。デモ用プロジェクトはoptimizerオフ（Foundryの既定値）・evm osaka。Market第159講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacyが既定の経路 + optimizerオン、debugが既定の経路でoptimizerオフ | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| EIPの原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`（erc-20 193行、erc-721 447行、erc-1155 710行、erc-4626 612行、erc-165 235行）、ethereum/EIPsのコミット`0ce679f4654ba4d120c97113626f320475e22fa9`（eip-1 621行、status Living）。五つのERCの最後の行はCC0 | 2026-10-19 |
| ファイルの最終更新のコミットの日付 | erc-20 2023-12-13、erc-721 2025-05-13、erc-1155 2023-10-25、erc-4626 2024-09-25、erc-165 2023-10-25 | 2026-10-19 |
| 大文字の語の数 | 数える規則：文書全体、語の境界、MUST NOT・SHOULD NOTは別に数えてMUST・SHOULDから引く、4626の`_NOT_`の形はNOTとして、721・1155は語の一覧の行（39・31行）を含める。値は上の実行結果の表 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（package.json）、MIT。ERC165Checker.solの冒頭のコメント"last updated v5.1.0" | 2026-10-20 |
| インターフェースID | IERC165 0x01ffc9a7、IERC20（OZ） 0x36372b07、IERC721 0x80ac58cd、IERC721Receiver 0x150b7a02、IERC1155 0xd9b67a26、IERC1155Receiver 0x4e2312e0、IERC4626 0x87dfe5a0、MarketのIERC20 0xfa1d6c57、IMarket 0xab691738、Solidity101 0xc6be8b58、ShapeA・B 0x1b1f8831、ShapeC 0x5f6b3e9a | 2026-10-20 |
| GasHogのガス | そのまま呼ぶと940,443（`gasleft()`の差、トレースは937,092）、30,000のstaticcallはOutOfGas | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第159講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ | 第159講のバージョンdefault 3,260 / 3,473、legacy 3,755 / 4,013、debug 7,353 / 7,931 | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第159講のバージョンdefault `1322ba3a` | 2026-10-20 |
| テストのガス | IntrospectionTest test_iMarketInterfaceId 222、test_noErc165 4,660。既存の75行は第39章末のバージョンの値と同じ（RebuildTest:test_recordedLogsIncludeReverted 155,232、第154〜158講のバージョンだけ155,244） | 2026-10-20 |
| 120バイトを超える行（src） | 第152講のバージョン87、第154講のバージョン87、第159講のバージョン92 | 2026-10-20 |
| 行番号 | 第159講のバージョンdebugのdeposit 0 src/Market.sol 171:33、NotActiveの行86、`contract Market` 215行。バージョン説明のコメントが変わると変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 標準の答えを信じて呼ぶコードが、見当違いのコントラクトに出会ったとき | [第171講](../../part11/lecture171/) |
| アップグレードされたコントラクトが同じアドレスで違う答えをするとき | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 監査で標準のSHOULDの行ごとに対応を確認するチェックリスト | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/) |
| キャップストーンで取り入れる標準を選んで対照表に残すこと | [第256講](../../part20/lecture256/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
