# 第256講 標準の統合

第20部 キャップストーンプロジェクト・第70章 設計と実装

[← 第255講](../../part20/lecture255/) | [第20部 目次](../) | [第257講 →](../../part20/lecture257/)

## この講義の問い

ERC-20という名前を付けたトークンは、どれも同じトークンなのか。他人が書いた標準の実装を取り込むとき、何を確かめるのか。どの標準に従い、どの標準に従わないのか、その理由はどこに残すのか。

## 実習資料

### 準備

第255講のバージョン（コアロジックのバージョン）から続ける。まず、コアロジックのバージョンをコードのままにして、テスト用のトークン三つ（返り値のないトークン、手数料をオンにできるトークン、falseを返すトークン）を載せてみたデモが`before256/`である。このフォルダには第255講のバージョンに加えた二つのファイルだけを入れた（残りは[第255講 code](../lecture255/code/)と同じ）。

次に、標準の統合のバージョンでOpenZeppelin Contracts 5.4.0の`SafeERC20`を取り込み、受け取るときに金庫の残高が実際に増えた量を数える。依存関係はforge-std 1.17.0（`lib/forge-std`）とOpenZeppelin Contracts 5.4.0（`lib/openzeppelin-contracts`、contracts・package.json・LICENSE）で、remappingは2行だけを書き、自動検出を切る（`auto_detect_remappings = false`）。anvilは使わない。

設計ドキュメントには9節の標準の対照表（10行）を埋め、信頼の前提T-02（トークン）・T-07（OpenZeppelin 5.4.0のファイル四つ）を直し、T-09（アカウント）、決定記録D-10（取り込んだコード）・D-11（remapping）・D-12（受け取るときの数え方）を加えた。11節の監査範囲にOpenZeppelinのファイル四つを入れた。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、via-IR、remapping 2行（`forge-std/`、`@openzeppelin/contracts/`）、自動検出オフ |
| [code/design/architecture.md](code/design/architecture.md) | 設計ドキュメント（9節の標準の対照表、T-02・T-07・T-09、D-10〜D-12） |
| [code/design/requirements.md](code/design/requirements.md) | 要件 |
| [code/src/Market.sol](code/src/Market.sol) | 標準の統合のバージョンのMarket：`SafeERC20`で移し、`_pull`が金庫の残高の差で受け取った量を数える（`AmountMismatch`）、listAssetがdecimalsを一度読む |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束（`TransferFailed`を抜き、`AmountMismatch(expected, received)`を追加） |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol)、[MarketMath](code/src/MarketMath.sol) | 型、計算の部品 |
| [code/test/Safety.t.sol](code/test/Safety.t.sol) | 安全の要件のテスト8個（S-07 手数料トークン、S-08 返り値のないトークン・falseトークンを埋めた） |
| [code/test/Standards.t.sol](code/test/Standards.t.sol) | 標準のテスト五つ：ERC-721・ERC-1155の拒否、ERC-165なし、コントラクトウォレット、EIP-7702の委任アカウントのまとめ呼び出し、decimalsを一度読む |
| [code/test/Access.t.sol](code/test/Access.t.sol) | 権限のテスト（A-05 変える道なしを埋めた） |
| [code/test/helpers/OddTokens.sol](code/test/helpers/OddTokens.sol) | テスト用トークン：手数料トークン、返り値のないトークン、falseトークン、OpenZeppelinのERC721・ERC1155トークン |
| [code/test/helpers/Accounts.sol](code/test/helpers/Accounts.sol) | テスト用アカウント：持ち主のウォレット（`OwnerWallet`）、まとめ呼び出しのアカウント（`BatchAccount`） |
| [code/test/](code/test/)の残り | Functional、Ops、Layout、Gas、Math、Interfaceのテストとhelpers（Base、StdToken、TwapFeed、HookToken） |
| [code/before256/test/Before256.t.sol](code/before256/test/Before256.t.sol) | コアロジックのバージョンにテスト用トークン三つを載せたテスト三つ |
| [code/before256/test/helpers/OddTokens.sol](code/before256/test/helpers/OddTokens.sol) | そのテストのトークン三つ（OpenZeppelinなし） |

### 実行結果

コアロジックのバージョンにトークン三つを載せた結果（`before256`で`forge test --offline --match-contract Before256Test -vvvv`、3通過）：

| トークン | コアロジックのバージョンのdeposit | 帳簿と金庫 |
|---|---|---|
| 返り値なし | 空の巻き戻し（`EvmError: Revert`） | 受け取れない |
| 手数料1% | 成功 | 帳簿の預けた合計200e18、金庫199e18。手数料を切ってbobが100を引き出したあと、最後のdaveの引き出しは`panic: arithmetic underflow or overflow (0x11)` |
| false | `TransferFailed(token)` | そのまま |

標準の統合のバージョンで`forge test --offline --match-contract "SafetyTest|StandardsTest" -vv`：

```
Ran 5 tests for test/Standards.t.sol:StandardsTest
[PASS] test_contractWallet() (gas: 901438)
[PASS] test_decimalsReadOnce() (gas: 23802)
[PASS] test_delegatedEoaBatch() (gas: 775525)
[PASS] test_noErc165() (gas: 27529)
[PASS] test_nonErc20Rejected() (gas: 1661033)
Ran 8 tests for test/Safety.t.sol:SafetyTest
[PASS] test_S01_exitPathsNeverPaused() (gas: 1225042)
[PASS] test_S02_ledgerBeforeTransfer() (gas: 1928961)
[PASS] test_S03_vaultCoversPromises() (gas: 4661084)
[PASS] test_S04_roundingFavorsMarket() (gas: 3818525)
Logs:
  dust: 2
[PASS] test_S05_assetCountCap() (gas: 12105474)
[PASS] test_S06_zeroShareDepositReverts() (gas: 3618784)
[PASS] test_S07_creditsReceivedAmount() (gas: 1521481)
[PASS] test_S08_noReturnToken() (gas: 1824965)
13 tests passed, 0 failed, 0 skipped (13 total tests)
```

- S-07：手数料1%をオンにしたあとで100を預け入れ → `AmountMismatch(100e18, 99e18)`、帳簿と金庫はどちらも100e18のまま、全部引き出したあと金庫0
- S-08：返り値のないトークンで1000e6を預けて400e6を引き出す → ウォレット400e6、預けた量600e6。falseトークン → `SafeERC20FailedOperation(token)`
- test_nonErc20Rejected：OpenZeppelinのERC721・ERC1155で作ったテスト用トークンは、どちらもdecimalsがないのでlistAssetで巻き戻り、資産数はそのまま
- test_noErc165：`supportsInterface(0x01ffc9a7)`の呼び出しが失敗

`forge test --offline --match-test A05 -vvvv`は、`upgradeToAndCall`（0x4f1ef286）と`proxiableUUID`（0x52d1902d）が "unrecognized function selector" で巻き戻り、ERC-1967の実装スロット（0x3608…2bbc）が0であることを示す。

取り込んだOpenZeppelinのファイル四つの`sha256sum`（`lib/openzeppelin-contracts/contracts/`の下）：

```
ee455e7a639484a69aca4fe45a099c7d3428ba3c71670d9f033140844208fc98  token/ERC20/utils/SafeERC20.sol
c88183106683ce7dc24449994ab64fc525e45d0efb8f969159c27f7f7dc19341  token/ERC20/IERC20.sol
a1ec1fe630f0a2972c11ed94485d84c021e1b717ab78c9b3238a6a34ca6b6fa8  token/ERC20/extensions/IERC20Metadata.sol
e50076f76fc3383d41939755d0b2e0aa67b3aa240478775459d4248f3e59c619  interfaces/IERC1363.sol
```

確認を加えた値（測った呼び出しは`test/Gas.t.sol`、折れ点5%のマーケット、呼び出し一つ・コールドアクセスを含む）：

| 項目 | コアロジックのバージョン | 標準の統合のバージョン |
|---|---|---|
| deposit / repay / liquidate | 137,297 / 61,481 / 233,854 | 139,164 / 63,348 / 235,727 |
| borrow / withdraw | 160,226 / 64,704 | 160,174 / 64,652 |
| ランタイムのCALL / STATICCALL | 2 / 4 | 1 / 6 |
| ランタイム / creationのバイト | 8,232 / 8,423 | 8,470 / 8,661 |
| テスト（通過 / スキップ / 全体） | 26 / 7 / 33 | 34 / 4 / 38 |

ランタイムの本体にDELEGATECALL・CALLCODE・SELFDESTRUCT・ORIGIN・TSTOREは0個、TIMESTAMPは3個である。

### 試すときの注意

- 標準は呼ぶ側と受ける側が前もって合わせた約束にすぎず、チェーンが強制するものではない。上場したときに問題のなかったトークンも、あとで手数料をオンにできるので、受け取るたびに金庫の残高が増えた量を数える。
- `SafeERC20._callOptionalReturn`は、トークンが巻き戻ればそのデータをそのまま上げ、返りデータが0バイトならアドレスにコードがあるときに通過、それ以外は最初の32バイトが1のときだけ通過する。取り込んだコードの中のアセンブリブロック1個（176〜186行）も監査範囲である。
- importの行には名前だけが書かれる。その名前がどのファイルかはremappingが決めるので、remappingを2行に固定し、メタデータにもその2行だけが入るようにした。
- 取り込んだファイルはバージョンとsha256を書いておき、ハッシュがそのままのときだけ監査範囲とみなす。メタデータのsourcesにはOpenZeppelinのファイルが七つ（四つと、それらのファイルが取り込むインターフェース）入る。
- EIP-20では`decimals`はOPTIONALである。キャップストーンはdecimalsを要求し、なければlistAssetで巻き戻す。

## 時効性のあるデータ

基準日時点の値。ツール・ライブラリのバージョンとコードが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry・solc | forge 1.8.3（commit cae51ad4）、solc 0.8.30 | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0（package.jsonのversion）、ファイル四つのsha256は実行結果の値 | 2026-10-21 |
| Marketのサイズ | コアロジックのバージョン8,232 / 8,423、標準の統合のバージョン8,470 / 8,661バイト、メタデータハッシュの先頭4バイト`2940c095` → `13394016` | 2026-10-21 |
| 測った呼び出し五つ | コアロジックのバージョンdeposit 137,297・borrow 160,226・repay 61,481・withdraw 64,704・liquidate 233,854 / 標準の統合のバージョン139,164・160,174・63,348・64,652・235,727 | 2026-10-21 |
| ランタイムの命令数 | CALL 2 → 1、STATICCALL 4 → 6、DELEGATECALL・CALLCODE・SELFDESTRUCT・ORIGIN・TSTORE 0、TIMESTAMP 3 | 2026-10-21 |
| テスト数 | コアロジックのバージョン26 / 7 / 33、標準の統合のバージョン34 / 4 / 38 | 2026-10-21 |
| EIP-20の原文 | OPTIONAL三つ（name、symbol、decimals）の文 | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| OpenZeppelinのバージョンを上げるときに変わった行の照合 | [第261講](../../part20/lecture261/) |
| 残高がひとりでに変わるトークン（リベース）と送る側の手数料の処理 | 扱わない（N-05） |
| 署名で承認する標準（EIP-2612）を受け入れる設計 | 付録 |
| アカウント側のセッションキーの範囲の設計 | アカウント抽象化の部のまま |
| 権限の要件A-01〜A-04 | [第257講](../../part20/lecture257/) |
| 手数料トークンをランダムな順番に混ぜる不変条件のテスト | [第259講](../../part20/lecture259/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
