# 第156講 ERC-721とコールバックの逆説

第10部 標準とアップグレード・第41章 標準の設計思想

[← 第155講](../../part10/lecture155/) | [第10部 目次](../) | [第157講 →](../../part10/lecture157/)

## この講義の問い

受け取る側が受け取れるかを確かめるためにその側の関数を呼ぶと、その確認は受け取る側に何を渡すのか。

## 実習資料

### 準備

プロジェクトは二つある。`demo`は、OpenZeppelinのERC721に誰でも発行できるmintだけを足したDeedトークン、受け取る側のコントラクト五つ（Plain、Rejecter、WrongMagic、Acceptor、Burner）、景品一つをsafeTransferFromで送るPrize、第154講のStdToken、Marketのソースのコピー（`src/market/`）を置いたデモ用プロジェクトである。`market`は通しプロジェクトMarketの第156講のバージョンである。

依存関係はforge-stdとOpenZeppelin Contracts 5.4.0である。`demo/foundry.toml`は依存関係を同じフォルダの`lib/`（`forge-std`、`openzeppelin-contracts`）で探す。コンパイラはsolc 0.8.30、`demo`はoptimizerオフ・evm osakaである。ガスとログは、ローカルのanvil 1.8.3で既定のテスト用アカウントをunlockedで使って測った（alice = アカウント1番）。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/foundry.toml](code/demo/foundry.toml) | solc 0.8.30、evm osaka、OpenZeppelin・forge-stdのremapping |
| [code/demo/src/Nft.sol](code/demo/src/Nft.sol) | OpenZeppelin 5.4.0のERC721にmintだけを足したトークン"Deed"・"DEED" |
| [code/demo/src/Receivers.sol](code/demo/src/Receivers.sol) | 受け取る側の五つ（Plain、Rejecter、WrongMagic、Acceptor、Burner）とPrize |
| [code/demo/src/StdToken.sol](code/demo/src/StdToken.sol) | 第154講のStdToken（Transferのログの形の比較用） |
| [code/demo/src/market/](code/demo/src/market/) | Marketのsrcの五つのファイルのコピー（OpenZeppelinのDeedをMarketに当ててみるテスト用） |
| [code/demo/test/Callback.t.sol](code/demo/test/Callback.t.sol) | 受け取る側の五つ、Prize、セレクタ、Transferのログの形、MarketにDeedを当てるテスト十一 |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定（defaultはvia-IR、legacy・debugプロファイル） |
| [code/market/src/](code/market/src/) | Market第156講のバージョンのsrcの五つのファイル。コードは第155講のバージョンと同じで、バージョン説明のコメントを1行足しただけ |
| [code/market/test/Nft.t.sol](code/market/test/Nft.t.sol) | 第156講で足したテスト用のMiniNftとNftTestの二つ（NFTのdepositの巻き戻し、直接送ったNFTが閉じ込められる） |
| [code/market/test/](code/market/test/) | そのほかのテストは前の講義で足したもののまま |

### 実行結果

移動の三つとセレクタ（`cast sig`、test_selectors）：

| シグネチャ | セレクタ | 受け取る側の確認 |
|---|---|---|
| safeTransferFrom(address,address,uint256,bytes) | 0xb88d4fde | する |
| safeTransferFrom(address,address,uint256) | 0x42842e0e | する（dataは空の値） |
| transferFrom(address,address,uint256) | 0x23b872dd | しない |

`cast send`に関数名だけを書くと送りもせず、引数の型まで書いたシグネチャで送ってはじめてセレクタが決まる（レシートはstatus・gasUsedの2行だけ）：

```
$ cast sig "safeTransferFrom(address,address,uint256)"
0x42842e0e
$ cast send <Deed> safeTransferFrom <alice> <Acceptor> 1 --unlocked --from <alice>
Error: Function signature does not contain parentheses. If you wish to fetch
function data from Etherscan, please provide an API key.
$ cast send <Deed> "safeTransferFrom(address,address,uint256)" <alice> <Acceptor> 1 \
    --unlocked --from <alice>
gasUsed              156348
status               1 (success)
```

`demo`で`forge test --offline -vv`で見た、受け取る側の五つと移動の二つ：

| 受け取る側 | transferFrom | safeTransferFrom |
|---|---|---|
| Plain（関数なし） | 入る、取り出す関数なし | 巻き戻し ERC721InvalidReceiver |
| Rejecter（巻き戻す） | 入る | 巻き戻し "no thanks" |
| WrongMagic（0x12345678） | テストしない | 巻き戻し ERC721InvalidReceiver |
| Acceptor（決まった値） | 入る | 入る |
| Burner（終わりなく回る） | テストしない | 失敗、上限1,000,000のうち985,719 / 5,000,000のうち4,923,219、持ち主はalice |

巻き戻しデータ三つ。`0x64a0ae92`は`ERC721InvalidReceiver(address)`（引数は受け取るアドレス）、`0x08c379a0`は`Error(string)`で、`6e6f207468616e6b73`は"no thanks"である。テストの中で受け取る側ごとに新しくデプロイするので、アドレスが同じである：

```
Plain       0x64a0ae92 000000000000000000000000d6bbde9174b1cdaa358d2cf4d57d1a9f7178fbff
WrongMagic  0x64a0ae92 000000000000000000000000d6bbde9174b1cdaa358d2cf4d57d1a9f7178fbff
Rejecter    0x08c379a0 …0020 …0009 6e6f207468616e6b73
```

`forge test --offline --match-test test_acceptorSeesNewOwner -vvvv`のsafeTransferFromの部分。受け取る関数の中で読んだownerOf(1)はすでにAcceptor自身で、Transferが受け取る関数より先に記録される：

```
├─ [156144] Nft::safeTransferFrom(0x…A11cE, Acceptor: [0xD6Bb…FBfF], 1)
│   ├─ emit Transfer(from: 0x…A11cE, to: Acceptor: [0xD6Bb…FBfF], tokenId: 1)
│   ├─ [91698] Acceptor::onERC721Received(0x…A11cE, 0x…A11cE, 1, 0x)
│   │   ├─ [1005] Nft::ownerOf(1) [staticcall]
│   │   │   └─ ← [Return] Acceptor: [0xD6Bb…FBfF]
│   │   └─ ← [Return] 0x150b7a02
│   └─ ← [Stop]
```

はじめて受け取るアドレスへ移すときのガス（ローカルのanvil、gasUsed）：

| 受け取るアドレス（はじめて受け取る） | transferFrom | safeTransferFrom |
|---|---|---|
| 新しいアカウント（コードなし） | 60,395 | 63,284 |
| 新しいAcceptor | 60,407 | 156,348 |

止められた移動のガス（持ち主はaliceのまま）：

| 受け取る側 | ガス上限 | 結果 |
|---|---|---|
| Rejecter | 300,000 | status 0、65,734 |
| Burner | 1,000,000 | status 0、985,719 |
| Burner | 5,000,000 | status 0、4,923,219 |

`forge test --offline --match-test test_prizeBlockedByRejecter -vvvv`（デプロイの行は省略）。当選者がRejecterならaward全体が巻き戻ってawardedはfalse、景品はPrizeにそのまま残る。0xB0Bで呼ぶと入る：

```
├─ [91331] Prize::award(Rejecter: [0x15cF…27b9])
│   ├─ [43794] Nft::safeTransferFrom(Prize: [0xD6Bb…FBfF], Rejecter: [0x15cF…27b9], 2)
│   │   ├─ emit Transfer(from: Prize: [0xD6Bb…FBfF], to: Rejecter: [0x15cF…27b9], tokenId: 2)
│   │   ├─ [1329] Rejecter::onERC721Received(Prize: [0xD6Bb…FBfF], Prize: [0xD6Bb…FBfF], 2, 0x)
│   │   │   └─ ← [Revert] no thanks
│   │   └─ ← [Revert] no thanks
│   └─ ← [Revert] no thanks
├─ [2487] Prize::awarded() [staticcall]
│   └─ ← [Return] false
├─ [3005] Nft::ownerOf(2) [staticcall]
│   └─ ← [Return] Prize: [0xD6Bb…FBfF]
├─ [88660] Prize::award(0x0000000000000000000000000000000000000B0b)
```

ERC-20とERC-721とで、同じシグネチャは同じ4バイトである：

| シグネチャ | ERC-20 | ERC-721 |
|---|---|---|
| transferFrom(address,address,uint256) | 0x23b872dd、三つ目の値は金額 | 0x23b872dd、三つ目の値はtokenId |
| approve(address,uint256) | 0x095ea7b3 | 0x095ea7b3 |
| balanceOf(address) | 0x70a08231 | 0x70a08231 |
| Transfer(address,address,uint256) | topic0 0xddf252ad… | topic0 0xddf252ad… |

ローカルのanvilの`cast logs`の出力から、DeedとStdTokenのTransferを一つずつ（address・data・topicsだけ）。ERC-721はtopics四つ（四つ目がtokenId 1）にdata 0バイト、ERC-20はtopics三つにdata 32バイト（7）である：

```
- address: 0x5FbDB2315678afecb367f032d93F642f64180aa3      (Deed)
  data: 0x
  topics: [
  	0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
  	0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
  	0x0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc
  	0x0000000000000000000000000000000000000000000000000000000000000001
  ]
- address: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9      (StdToken)
  data: 0x0000000000000000000000000000000000000000000000000000000000000007
  topics: [
  	0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
  	0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
  	0x0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc
  ]
```

ERC-721のTransferの空のdataをERC-20の形（金額一つ）で読むとエラーになる：

```
$ cast decode-abi --input "f(uint256)" 0x
Error: ABI decoding failed: buffer overrun while deserializing
```

`market`で`forge test --offline --match-contract NftTest -vvvv`。まずtest_nftDepositRevertsのdepositのトレースである。MiniNftのtransferFromは成功してTransferまで記録されるが、受け取るboolがないので、Marketでデータなしに巻き戻る。持ち主はalice、合計は0である：

```
├─ [108827] Market::deposit(MiniNft: [0x2e23…470b], 1)
│   ├─ [12951] MiniNft::transferFrom(0x…A11cE, Market: [0x5615…b72f], 1)
│   │   ├─ emit Transfer(from: 0x…A11cE, to: Market: [0x5615…b72f], tokenId: 1)
│   │   └─ ← [Stop]
│   └─ ← [Revert] EvmError: Revert
├─ [2445] MiniNft::ownerOf(1) [staticcall]
│   └─ ← [Return] 0x…A11cE
├─ [2714] Market::totalDeposits(MiniNft: [0x2e23…470b]) [staticcall]
│   └─ ← [Return] 0
```

test_nftSentDirectlyStays。safeTransferFromでMarketに送るとonERC721Receivedがないので巻き戻り、transferFromで送ると入って持ち主がMarketになる。Marketには送り出す関数がない：

```
├─ [35164] MiniNft::safeTransferFrom(0x…A11cE, Market: [0x5615…b72f], 2)
│   ├─ emit Transfer(from: 0x…A11cE, to: Market: [0x5615…b72f], tokenId: 2)
│   ├─ [482] Market::onERC721Received(0x…A11cE, 0x…A11cE, 2, 0x)
│   │   └─ ← [Revert] unrecognized function selector 0x150b7a02 for contract
│   │       0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, which has no fallback function.
│   └─ ← [Revert] EvmError: Revert
├─ [31682] MiniNft::transferFrom(0x…A11cE, Market: [0x5615…b72f], 2)
│   ├─ emit Transfer(from: 0x…A11cE, to: Market: [0x5615…b72f], tokenId: 2)
│   └─ ← [Stop]
├─ [2445] MiniNft::ownerOf(2) [staticcall]
│   └─ ← [Return] Market: [0x5615…b72f]
```

OpenZeppelinのDeedでも同じである（`demo`のtest_marketDepositNft：deposit失敗、巻き戻しデータ0バイト、持ち主alice、合計0。test_marketReceivesNft：safeTransferFromは`0x64a0ae92…`で巻き戻る）。

Market第156講のバージョンの点検：`forge build --offline --sizes`でMarket 3,260 / 3,473、`forge test --offline`と`FOUNDRY_PROFILE=debug`・`legacy`はいずれも83個が通過、`.gas-snapshot` 83行、`bash ci.sh`は`ci ok`。

Market第156講のバージョンの標準の対照表に足した行：

| 標準 | Marketが立つ側 | Marketにあるもの | Marketにないもの | 確認するテスト |
|---|---|---|---|---|
| ERC-721 | 該当なし（資産として上場するとdepositが巻き戻る） | なし | onERC721Receivedなし。safeTransferFromは巻き戻り、transferFromで入ってきたNFTは取り出す関数なし | test/Nft.t.sol |

### 試すときの注意

- `cast send`には関数名ではなく、引数の型まで書いたシグネチャを使う。safeTransferFromは同じ名前の関数が二つあるので、名前だけではどちらか決まらない。
- OpenZeppelinのERC721のsafeTransferFromは、帳簿の書き換え（`_update`）をすべて終えてから受け取る側の関数を呼ぶ。受け取る関数の中で見る持ち主と残高は、すでに変わった値である。
- 受け取る側が終わりなく回るBurnerなら、ガス上限を上げてもほぼ使い切って失敗する。同じ関数を呼んでも、払うガスは受け取る側のコードが決める。
- Marketのdepositは、トークンが返すboolを読む。戻り値のないERC-721のtransferFromを呼ぶと、セレクタは同じでも読む段階でデータなしに巻き戻る。
- forgeのトレースのアドレスは短くして載せた（`0x…A11cE`、`0xD6Bb…FBfF`など）。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツール・文書のバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| EIP-721の原文 | ethereum/ERCsのコミット`48dc87a2897c1d412d6df688c2d7df1229f2b30c`の`ERCS/erc-721.md`（447行、status Final、created 2018-01-24、requires 165）。ファイルの最終更新2025-05-13。引用した行27・55・81〜88・95〜101・103〜105・155・158・161〜165・176・273・295・363 | 2026-10-20 |
| OpenZeppelin Contracts | 5.4.0（MIT）。`ERC721.sol` 115・128・133〜136・216〜245、`utils/ERC721Utils.sol` 16・25〜49（32〜45を引用） | 2026-10-20 |
| solc | 0.8.30。デモ用プロジェクトはoptimizerオフ（Foundryの既定値）・evm osaka。Market第156講のバージョンはdefaultがvia-IR + optimizerオン runs 200、legacy・debugプロファイル | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| セレクタ・トピック | transferFrom 0x23b872dd、safeTransferFrom 引数三つ 0x42842e0e、引数四つ 0xb88d4fde、onERC721Received 0x150b7a02、approve 0x095ea7b3、balanceOf 0x70a08231、ERC721InvalidReceiver 0x64a0ae92、Transferのtopic0 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef | 2026-10-20 |
| 移動のガス（anvil、受け取るアドレスははじめて受け取るアドレス） | transferFrom → 新しいアカウント 60,395、safeTransferFrom → 新しいアカウント 63,284、transferFrom → Acceptor 60,407、safeTransferFrom → 新しいAcceptor 156,348、safe → Rejecter 上限300,000 status 0・65,734、safe → Burner 上限1,000,000 status 0・985,719、5,000,000 status 0・4,923,219、StdTokenのtransfer 7 52,302 | 2026-10-20 |
| デプロイのガス（anvil） | Deed 1,710,353、Acceptor 376,883、Burner 239,602、Rejecter 222,684、StdToken 934,513 | 2026-10-20 |
| テストのガス（forge） | Callbackの十一：acceptorSeesNewOwner 192,527、burner 18,528、marketDepositNft 322,244、marketReceivesNft 156,479、plainSafeReverts 90,573、plainTransferFromStuck 76,240、prizeBlockedByRejecter 273,807、rejecter 156,220、selectors 21,551、transferLogShape 89,111、wrongMagic 81,404 / NftTest 277,732・100,279 | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第156講のバージョン：デプロイ760,316、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ | 第156講のバージョンdefault 3,260 / 3,473（legacy 3,755 / 4,013、debug 7,353 / 7,931） | 2026-10-20 |
| 末尾のハッシュの先頭4バイト | 第156講のバージョンdefault `892e2436` | 2026-10-20 |
| 行番号 | 第156講のバージョンdebugのdeposit 0 src/Market.sol 168:33、NotActive 83行、`contract Market` 212行、deposit 157〜163行。バージョン説明のコメントが変わると変わる | 2026-10-20 |
| アカウント | アカウント0番`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`、alice = アカウント1番`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`、アカウント2番`0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`（anvilの既定のテスト用アカウント、unlockedのアカウントで送る）。forgeのテストのaliceは`0xA11CE` | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 受け取る関数の中でトークンや元のコントラクトをもう一度呼ぶとき | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/) |
| 受け取る側の関数を置いたほかのトークン標準（ERC-20に付けた形、OpenZeppelin 5.4.0のERC1363） | [第171講](../../part11/lecture171/) |
| 処理の中のsafeな移動を引き出す形に変える判断、受け取る側の呼び出しのガス上限 | [第170講](../../part11/lecture170/) |
| ERC-1155の受け取る側の関数とまとめての送信 | [第157講](../../part10/lecture157/) |
| 同じイベントのシグネチャを違う配置で記録する標準をまとめて読むインデクサー | [第238講](../../part18/lecture238/) |
| コントラクトに閉じ込められたNFT・トークンと標準の統合 | [第171講](../../part11/lecture171/)、[第256講](../../part20/lecture256/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
