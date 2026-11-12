# 第262講 デプロイスクリプトと検証

第20部 キャップストーンプロジェクト・第72章 デプロイと運用

[← 第261講](../../part20/lecture261/) | [第20部 目次](../) | [第263講 →](../../part20/lecture263/)

## この講義の問い

監査したビルドをチェーンに載せるとき、何を送る前に、何を送ったあとに確かめるのか。チェーンにあるコードが自分のビルドと同じであることは、何で示すのか。

## 実習資料

### 準備

通しプロジェクトMarketの第261講のバージョン（直したビルド`d551e83c`、第71章末のバージョン）から始める。この講義でデプロイスクリプト`script/Deploy.s.sol`、そのテスト`test/Deploy.t.sol`（DeployTest 5）、デプロイ後の確認ツール`deploy/check.py`を加える。srcは直したバージョンとdiffがない。依存関係はforge-std 1.17.0とOpenZeppelin Contracts 5.4.0（TimelockControllerを含む）で、`deploy/check.py`はPythonの標準ライブラリと`cast`だけを使う。

デプロイはローカルのanvil（チェーン番号31337）でだけ行った。マルチシグ（署名者a・b・c = anvilのアカウント1・2・3、三人のうち二人）、トークンCOL（18桁）・USD（6桁）、価格の出どころ二つは、テスト用の代役として8番アカウントが先に載せた。デプロイするアカウントはanvilの0番アカウントで、キーは`cast wallet import`で作ったキーファイルとパスワードファイルで渡す。このキーとパスワードはデモ用の公開された値なので、実際の資産には使わない。エクスプローラーへの提出と公開ネットワークへの接続はしていない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）、via-IR、evm osaka、`fs_permissions`、debugプロファイル、`[fuzz]`・`[invariant]`の設定 |
| [code/abi/IMarket.json](code/abi/IMarket.json) | リポジトリに置いたABIファイル。ciがビルドとdiff |
| [code/src/IMarket.sol](code/src/IMarket.sol) | 外側の約束（ABI）：関数・イベント・エラー（ZeroPriceを含む）とNatSpec |
| [code/src/Market.sol](code/src/Market.sol) | レンディングマーケットの本体（直したビルド`d551e83c`） |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息の曲線・丸めの計算ライブラリ |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | 共有する型、価格の出どころのインターフェース |
| [code/script/Deploy.s.sol](code/script/Deploy.s.sol) | デプロイスクリプト：タイムロック → Market、デプロイするアカウントはロールを受け取らない |
| [code/deploy/check.py](code/deploy/check.py) | デプロイ後の確認（サイズ、メタデータハッシュ、コードハッシュ、sources、コンストラクター引数）。読み取りのリクエストだけ |
| [code/test/Access.t.sol](code/test/Access.t.sol) | 権限の要件A-01〜A-05 |
| [code/test/Deploy.t.sol](code/test/Deploy.t.sol) | デプロイスクリプトのdeploy・checkをそのまま呼ぶDeployTest 5 |
| [code/test/Docs.t.sol](code/test/Docs.t.sol) | ABIの項目ごとにnoticeがあるか |
| [code/test/Errors.t.sol](code/test/Errors.t.sol) | エラー23ごとに、そのエラーで巻き戻るテスト一つ（巻き戻しデータ全体） |
| [code/test/Events.t.sol](code/test/Events.t.sol) | イベント11の引数すべて |
| [code/test/Findings.t.sol](code/test/Findings.t.sol) | 自己監査の指摘事項の確認テスト五つ |
| [code/test/Functional.t.sol](code/test/Functional.t.sol) | 機能要件F-01〜F-10 |
| [code/test/Fuzz.t.sol](code/test/Fuzz.t.sol) | ファズテスト五つ |
| [code/test/Gas.t.sol](code/test/Gas.t.sol) | 測った呼び出し五つのガス |
| [code/test/Interface.t.sol](code/test/Interface.t.sol) | 関数の数とインターフェースID |
| [code/test/Invariant.t.sol](code/test/Invariant.t.sol) | 不変条件テスト（I-1〜I-5、一覧にない失敗0） |
| [code/test/Layout.t.sol](code/test/Layout.t.sol) | ストレージの欄の地図どおりに置かれているか |
| [code/test/Math.t.sol](code/test/Math.t.sol) | 計算の部品の曲線の値と丸めの方向 |
| [code/test/Ops.t.sol](code/test/Ops.t.sol) | 運用の要件O-01〜O-02 |
| [code/test/Rebuild.t.sol](code/test/Rebuild.t.sol) | ログだけで数え直した合計と状態の比較 |
| [code/test/Safety.t.sol](code/test/Safety.t.sol) | 安全の要件S-01〜S-08 |
| [code/test/Standards.t.sol](code/test/Standards.t.sol) | 標準の対照表の行ごとの確認 |
| [code/test/Trust.t.sol](code/test/Trust.t.sol) | 信頼の前提のテスト（T-01 出どころの停止・平均の遅れ、T-03 同じブロック） |
| [code/test/helpers/Accounts.sol](code/test/helpers/Accounts.sol) | テスト用のアカウントのコード二つ |
| [code/test/helpers/Base.sol](code/test/helpers/Base.sol) | テスト共用の土台（COL・USD、価格の出どころ二つ、前のバージョンと同じ場面） |
| [code/test/helpers/Handler.sol](code/test/helpers/Handler.sol) | 不変条件のハンドラー（価格0〜2.0、正常な失敗の一覧） |
| [code/test/helpers/HookToken.sol](code/test/helpers/HookToken.sol) | 移される瞬間にMarketの帳簿を読んで書き留めるテスト用トークン |
| [code/test/helpers/MultiSigAdmin.sol](code/test/helpers/MultiSigAdmin.sol) | テスト用のマルチシグ |
| [code/test/helpers/OddTokens.sol](code/test/helpers/OddTokens.sol) | 標準と違う動きをするテスト用トークン（手数料トークンなど） |
| [code/test/helpers/StdToken.sol](code/test/helpers/StdToken.sol) | テスト用の標準トークン |
| [code/test/helpers/TwapFeed.sol](code/test/helpers/TwapFeed.sol) | テスト用の価格の出どころ（積み上がった価格の合計、`stop()`、権限のない`setPrice`） |

### 実行結果

`forge test --offline --match-contract DeployTest -vv`：

```
[PASS] test_O03_addressesFromNonce() (gas: 3123936)
[PASS] test_O03_deployLeavesNoDeployerRole() (gas: 3192507)
[PASS] test_O03_firstListingWaitsTwoDays() (gas: 5754577)
[PASS] test_O03_rejectsCouncilWithoutCode() (gas: 20445)
[PASS] test_O03_wrongCouncilFailsCheck() (gas: 3136590)
Ran 1 test suite in 4.46ms (1.50ms CPU time): 5 tests passed, 0 failed, 0 skipped (5 total tests)
```

デプロイ後にロールなし（スロット4まで）、ナンスで数えたアドレス、コードのないマルチシグのアドレスは`CheckFailed("council has no code")`、間違えて入れたマルチシグは`CheckFailed("market guardian")`、2日前の実行は`CallFailed`で、2日後にassetCount 1を見る。`bash ci.sh`は86通過（前のバージョンの81 + 5）である。

送る前に、デプロイするアカウントのナンスとアドレスを数える：

```
$ cast nonce 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url <RPC_URL>
0
$ cast compute-address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --nonce 0
Computed Address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
$ cast compute-address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --nonce 1
Computed Address: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

ナンス0がタイムロック、ナンス1がMarketである。マルチシグの席にコードのないアドレス（4番アカウント）を入れたシミュレーションは、送る前の確認で止まり（`CheckFailed("council has no code")`、終了コード1）、ナンスは0のままである。正しいアドレスで`forge script script/Deploy.s.sol:Deploy --offline --rpc-url <RPC_URL> --keystore <キーファイル> --password-file <パスワードファイル>`：

```
== Return ==
timelock: contract TimelockController 0x5FbDB2315678afecb367f032d93F642f64180aa3
market: contract Market 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
Estimated total gas used for script: 4401661
SIMULATION COMPLETE. To broadcast these transactions, add --broadcast and wallet configuration(s) to the previous command. See forge script --help for more.
```

同じコマンドに`--broadcast --slow`を付けると`ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.`である。タイムロックはブロック6（gasUsed 1,376,896）、Marketはブロック7（gasUsed 2,008,998）に入った。

`python -I deploy/check.py <RPC_URL> broadcast/Deploy.s.sol/31337/run-latest.json --record <記録ファイル>`（Marketの部分）：

```
== Market 0xe7f1725e7734ce288f8367e1bb143e90bb3f0512 (ブロック 7, tx 0x08783169989b3c4610e54775c556c4500461f478f2d87c7915bc6ef21a546407)
  一致 1) デプロイ取引の入力の先頭 = ローカルのcreationバイトコード(9252 バイト)
     コンストラクタ引数 3 個: 0x5fbdb2315678afecb367f032d93f642f64180aa3, 0x95bd8d42f30351685e96c62eddc0d0613bf9a87a, 0xb1a2bc2ec50000
  一致 2) サイズ 8921 / ローカル 8921
  一致 2) immutableの場所 6 か所を隠したランタイム
  一致 4) 末尾のメタデータハッシュ d551e83c(末尾 51 バイト)
  記録 6) コードハッシュ 0xc5131569c9939ccc71e952da5b8057a850f6329589926798791c680839b3b979
  一致 3) immutable admin = タイムロック 0x5fbdb2315678afecb367f032d93f642f64180aa3
  一致 3) immutable rateAtKink = 50000000000000000
  一致 4) sources lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol keccak256 d5ea0736 (scope.md d5ea0736、ライセンス MIT)
  …(sourcesのファイルごとに1行、十一)
  一致 4) sourcesのファイル数 11 / scope.md 11
== 座っている席 (最新ブロック)
  一致 5) admin() 0x5fbdb2315678afecb367f032d93f642f64180aa3
  一致 5) guardian() 0x95bd8d42f30351685e96c62eddc0d0613bf9a87a = スロット4
  一致 5) タイムロックの最小待機 172800 秒
  一致 5) デプロイアカウント 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 にタイムロックの管理者ロールなし
結果: 確認リストすべて一致
```

タイムロックも同じ方法で確認した（creation 6,755バイト + 引数8個、ランタイム5,450、immutable 0か所、ハッシュ`c183412f`、コードハッシュ`0xdb832161…`）。読み取りのリクエストだけをしてキーを受け取らず、一つでも違えば終了コード1である。ローカルのビルドのランタイムのimmutableの場所六つは0で空いていて、チェーンのランタイムの同じ場所にはadmin（タイムロックのアドレス）三つとrateAtKink（0.05e18）三つが入っている。六つを隠して残りのバイトを比べる。

`forge verify-contract --show-standard-json-input 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 src/Market.sol:Market`が出した入力はファイル11個、設定`{"optimizer": {"enabled": true, "runs": 200}, "viaIR": true, "evmVersion": "osaka", "metadata": {"useLiteralContent": false, "bytecodeHash": "ipfs", "appendCBOR": true}}`である。同じ入力をsolc 0.8.30の`--standard-json`にもう一度入れた結果：

| 入力 | サイズ / 末尾のハッシュ | 先頭部分（immutableを隠す） |
|---|---|---|
| そのまま | 8,921 / d551e83c | チェーンと同じ |
| optimizer runs 200 → 201 | 8,921 / fda2cf6c | 同じ |
| Market.solの最後にコメント1行 | 8,921 / 4dec20d5 | 同じ |
| viaIR true → false | 10,169 / 7bc090fd | 違う |

デプロイ取引の入力の最後の96バイトを`cast decode-abi --input "f(address,address,uint256)"`で解くと、タイムロック`0x5FbDB2315678afecb367f032d93F642f64180aa3`、マルチシグ`0x95bD8D42f30351685e96C62EDdc0d0613bf9a87A`、`50000000000000000`である。

最初の上場（COLの担保比率75、USD 80、預け入れの上限なし）。各行の値の前の説明は、castの呼び出しをまとめたシェルが付けた見出し（シェルはcode/に入れていない）である：

```
デプロイしたアカウントがMarket.listAssetを直接呼ぶと: execution reverted: custom error 0x17a84242: 000000000000000000000000…
予約1: ブロック12 status 0x1
予約2: ブロック16 status 0x1
作業id 0x1546d047941d2cd126e4e574bbe8b56fdcb2e8789272645f32ae7720823d32bf
実行1: ブロック21 status 0x1
実行2: ブロック25 status 0x1
assetCount 2
```

`0x17a84242`は`NotAdmin(address)`で、入っているアドレスはデプロイしたアカウントである。署名する前に予約のcalldataを解き、作業idを計算し直した：

```
$ cast calldata-decode "schedule(address,uint256,bytes,bytes32,bytes32,uint256)" 0x01d5062a...
0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
0
0x2b42a8d1...(listAsset calldata)
0x0000000000000000000000000000000000000000000000000000000000000000
0x0000000000000000000000000000000000000000000000000000000000000001
172800 [1.728e5]
$ cast calldata-decode "listAsset(address,address,uint8,uint256)" 0x2b42a8d1...
0x98eDDadCfde04dC22a0e62119617e74a6Bc77313
0xcA8b49076D1A8039599e24979abf819af784c27a
75
115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]
$ cast keccak $(cast abi-encode "f(address,uint256,bytes,bytes32,bytes32)" <Market> 0 <listAsset calldata> 0x00…00 0x00…01)
0x1546d047941d2cd126e4e574bbe8b56fdcb2e8789272645f32ae7720823d32bf
```

### 試すときの注意

- Marketのadmin（設定キー = タイムロック）はimmutableなので、変える関数がない。設定キーに別のアドレスを入れてデプロイすると直す道がないので、捨てて新しいアドレスにデプロイし直す。そのあいだに預けたお金は前のアドレスに残り、引き出しはどの状態でもできる。
- タイムロックのコンストラクターのadmin引数は`address(0)`で入れ、デプロイするアカウントに、捨てることになる管理者ロールを最初から与えない。資産の上場はデプロイスクリプトに入れない（入れると最初の資産が2日の公開待機なしで上がる）。
- 秘密鍵をコマンドラインや環境変数に置かない。コマンドラインはシェルの履歴に残り、環境変数は同じシェルのプログラムが読む。キーファイルの欄はcrypto（aes-128-ctr、kdf scrypt）、id、versionである。
- デプロイしているあいだ、デプロイするアカウントでほかの取引を送らない。途中に一つ挟まると、タイムロックがナンス1、Marketがナンス2のアドレスに行く。
- `--slow`は、前の取引がブロックに入って成功してから次の取引を送る。
- `broadcast/Deploy.s.sol/31337/run-latest.json`（取引のハッシュ、ナンス、作ったアドレス、レシート）はリポジトリに入れ、取引ごとにRPCのアドレスが書かれた`cache/Deploy.s.sol/31337/run-latest.json`は入れない。実際のネットワークのRPCのアドレスには接続キーが付くこともある。
- immutableの場所だけを隠して比べたなら、隠した場所の値を別に読んでコンストラクター引数と合わせる必要がある。値を読まなければ、別のadminが入ったMarketも通る。
- マルチシグのアドレスだけを間違えて入れたMarketも、コードの比較は合う（guardianはスロット4なのでコードにない）。だから座っている席を別に読む。
- 検証が合ったというのは、そのアドレスのコードがこのソースとこの設定から出たという意味である。コンストラクター引数とコードがすることは別に読む。
- メタデータのsourcesには、ファイルごとにSPDXの行が入っている（srcの四つはGPL-3.0、取り込んだOpenZeppelinの七つはMIT）。エクスプローラーの様式のライセンスの欄一つとは別である。
- 予約一つは、マルチシグの提案・承認二つ・実行でブロックを四つ使う。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると変わることがあり、アドレス・ブロックはローカルのanvilでこの順番で実行した値である。

| 項目 | 値 | 基準日 |
|---|---|---|
| ツール | Foundry 1.8.3（commit cae51ad4）、solc 0.8.30、forge-std 1.17.0、OpenZeppelin Contracts 5.4.0 | 2026-10-21 |
| デプロイしたビルド | Market runtime 8,921 / creation 9,252、ハッシュ`d551e83c`、コードハッシュ`0xc5131569…`；タイムロック runtime 5,450 / creation 6,755、ハッシュ`c183412f`、コードハッシュ`0xdb832161…` | 2026-10-21 |
| デプロイのガス（ローカルのanvil） | シミュレーション4,401,661 / タイムロック1,376,896 / Market 2,008,998 | 2026-10-21 |
| アドレス・ブロック（ローカルのanvil 31337） | 代役（8番アカウントのナンス0〜4）、タイムロック`0x5FbD…0aa3` ブロック6、Market `0xe7f1…0512` ブロック7、予約12・16、実行21・25 | 2026-10-21 |
| 標準JSON入力の変形 | runs 201 `fda2cf6c`、コメント1行`4dec20d5`、viaIR false 10,169バイト`7bc090fd` | 2026-10-21 |
| エクスプローラー・署名方式の名前 | forge verify-contract `--verifier` etherscan・sourcify・blockscout・oklink・custom、`--license-type`；forge script `--ledger`・`--trezor`・`--aws`・`--gcp`・`--turnkey`。料金・APIキーは確認していない | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 実際のネットワークへのデプロイとエクスプローラーへの提出 | 扱わない（時効性のあるデータ） |
| ハードウェアウォレット・リモート署名サーバーの設定 | 扱わない（時効性のあるデータ） |
| `forge verify-bytecode` | 扱わない |
| 前のバージョンから新しいバージョンへの移行 | 扱わない |
| デプロイしたMarketの監視 | [第263講](../../part20/lecture263/) |
| 事故対応のリハーサル | [第264講](../../part20/lecture264/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
