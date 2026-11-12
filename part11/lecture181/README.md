# 第181講 フロントエンド、DNS、ツールチェーン

第11部 推奨事項：敵対的環境とバージョン履歴・第47章 コードの外からの攻撃

[← 第180講](../../part11/lecture180/) | [第11部 目次](../) | [第182講 →](../../part11/lecture182/)

## この講義の問い

コントラクトが安全なら、それを使う人も安全なのか。ウォレットは何に署名するのか。アドレスバーのドメインと画面のトークン名は何を保証するのか。ソースが正しければ、デプロイされたバイトコードも正しいのか。

## 実習資料

### 準備

通しプロジェクトMarketの前のバージョン（第46章の終わりのバージョン）から始める。この講義ではMarketのコードとテストを直さない。forge-stdが必要である。ローカルのanvilを立ち上げ、anvilのアカウント0番（既定のテスト用の鍵）でMarket、StdToken、同じ名前のStdTokenの二つ目を順にデプロイしたあと、castでcalldata・承認・上場の有無を確認する。StdTokenは`test/StdToken.sol`を`forge create`でデプロイする。コンストラクタの引数は、Marketがadminアカウント0番・Rate 5e16・Ratio 80、StdTokenが"Std Token"・"STD"・18・1000である。外部への接続は使わない。

無制限の承認のcalldataは、castでバイトを作って解くところまでで、署名・送信はしない。事件の手口は扱わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | Marketのビルド設定。デプロイ用のビルド（solc 0.8.30、via-IR、optimizerオン、evm osaka）と、optimizerを切った`debug`プロファイル |
| [code/src/](code/src/) | Marketの本体（前のバージョンのまま）。承認を使う場所はdepositの`transferFrom(msg.sender, …)`の一行 |
| [code/test/StdToken.sol](code/test/StdToken.sol) | 名前・シンボル・小数桁・発行量をコンストラクタで受け取る標準トークン。同じ名前のトークンを二つデプロイするときに使う |
| [code/test/Allowance.t.sol](code/test/Allowance.t.sol) | 残った承認のテスト（`test_leftoverAllowanceStays`：100を承認、30を預け入れ、全部引き出したあと残る承認70） |
| [code/test/](code/test/) | このバージョンまでに積み重なった残りのテスト |

### 実行結果

承認のcalldata二つを作った`cast calldata`。上はMarket（0x5FbD…0aa3）に100だけ、下はコードのないアドレス0x…bEEFにuint256の最大値だけ承認するバイトである。

```
$ cast calldata "approve(address,uint256)" $M 100
0x095ea7b30000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa30000000000000000000000000000000000000000000000000000000000000064
$ cast calldata "approve(address,uint256)" 0x000000000000000000000000000000000000bEEF 115792089237316195423570985008687907853269984665640564039457584007913129639935
0x095ea7b3000000000000000000000000000000000000000000000000000000000000beefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
```

`cast decode-calldata`と`cast sig`で解くと、先頭4バイトのセレクタはどちらも0x095ea7b3で、違いは後ろの64バイトの受け取るアドレス（spender）と金額である。

```
$ cast decode-calldata "approve(address,uint256)" 0x095ea7b3…0064
0x5FbDB2315678afecb367f032d93F642f64180aa3
100
$ cast decode-calldata "approve(address,uint256)" 0x095ea7b3…ffff
0x000000000000000000000000000000000000bEEF
115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]
$ cast sig "approve(address,uint256)"
0x095ea7b3
```

`cast code`で受け取るアドレスのコードを見ると、Marketはランタイム2,990バイト、0x…bEEFはコードがない（`0x`）。

金額だけ承認してからdepositすると、残る承認は0である（$TはStdToken、$Aはアカウント0番、positionsの後ろの二つの欄は省略）。

```
$ cast send $T "approve(address,uint256)" $M 100 …
$ cast call $T "allowance(address,address)(uint256)" $A $M
100
$ cast send $M "deposit(address,uint256)" $T 100 …
$ cast call $T "allowance(address,address)(uint256)" $A $M
0
$ cast call $M "positions(address,address)(uint256,uint256,uint64,bool)" $T $A
100
0
```

名前とシンボルが同じトークンを二つデプロイすると、アドレスだけが違う。

```
$ forge create --offline --broadcast … test/StdToken.sol:StdToken --constructor-args "Std Token" "STD" 18 1000
Deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
$ forge create --offline --broadcast … test/StdToken.sol:StdToken --constructor-args "Std Token" "STD" 18 1000
Deployed to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
$ cast call $T "name()(string)"     →  "Std Token"
$ cast call $T "symbol()(string)"   →  "STD"
$ cast call $C "name()(string)"     →  "Std Token"
$ cast call $C "symbol()(string)"   →  "STD"
```

Marketは管理者がaddAssetで上げたアドレスだけを受け付ける。一つ目のトークン（$T）だけを上場すると、二つ目のトークン（$C）の預け入れはNotListed（セレクタ0x5d35c429）で差し戻される。

```
$ cast send $M "addAsset(address,uint8)" $T 75 …
$ cast call $M "assetConfig(address)(uint8,bool)" $T
75
true
$ cast call $M "assetConfig(address)(uint8,bool)" $C
0
false
$ cast call $M "deposit(address,uint256)" $C 1 --from $A
Error: execution reverted: NotListed(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0)
```

デプロイ用のビルドと、optimizerを切ったビルドで同じテストを回した結果：

```
$ FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false forge test --offline
Ran 40 test suites in 24.32ms (49.58ms CPU time): 111 tests passed, 0 failed, 0 skipped (111 total tests)
$ FOUNDRY_PROFILE=debug forge test --offline
Ran 40 test suites in 23.82ms (42.49ms CPU time): 111 tests passed, 0 failed, 0 skipped (111 total tests)
```

コンパイラの実行ファイルのバージョンとハッシュ：

```
$ solc-0.8.30 --version
solc, the solidity compiler commandline interface
Version: 0.8.30+commit.73712a01.Windows.msvc
$ sha256sum solc-0.8.30
ccbd3ed44d5fbd26fe039702d403421f1212d2e8752e3cbe3bfd074986911586 *solc-0.8.30
```

### 試すときの注意

- ドメイン・サーバー・画面はチェーンに残らない。チェーンに残るのは、ウォレットが署名したcalldata一つである。関数名だけでは正確な承認と無制限の承認が区別できないので、calldataを解いて受け取るアドレスと金額を読む。
- コードのないアドレスは普通、秘密鍵を持つアカウントで、承認された分だけtransferFromを直接送れる。無制限なら、今の残高とあとで入ってくる残高まで対象になる。
- 承認は金額だけ行う。使わなかった承認はそのまま残る（`test_leftoverAllowanceStays`の70）。
- トークン名が重なることを、チェーンは防がない。アドレスで見分ける。
- 二つのビルドが同じテストを通っても、確認されるのはテストが呼んだ動作までである。再入ロックのような動作は、二回目の呼び出しを実際に呼ぶテストがあってはじめて確認される。
- solcの実行ファイルのハッシュはOSごとに違う。受け取ったファイルのハッシュは、solc-binリポジトリの`list.json`に書かれたバージョンごとのkeccak256・sha256と照合する。上のハッシュはWindowsの実行ファイルの値である。
- アドレスは、anvilのアカウント0番が同じ順番でデプロイしたときの値である。順番が変わればアドレスも変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンが変わると数字が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad4) | 2026-10-21 |
| solc | 0.8.30+commit.73712a01.Windows.msvc、実行ファイル10,314,240バイト、sha256 `ccbd3ed44d5fbd26fe039702d403421f1212d2e8752e3cbe3bfd074986911586`（Windowsの実行ファイル、ほかのOSは違う値） | 2026-10-21 |
| Marketのビルド設定 | solc 0.8.30、optimizerオン（runs 200）、via-IRオン、evm osaka。debugプロファイルはoptimizerオフ・via-IRオフ | 2026-10-21 |
| Marketのテスト | 第46章の終わりのバージョン、40スイート111個、デプロイ用ビルド・debugビルドともに通過 | 2026-10-21 |
| Marketのアドレス | `0x5FbDB2315678afecb367f032d93F642f64180aa3`（anvilのアカウント0番の最初のデプロイ）、ランタイム2,990バイト | 2026-10-21 |
| トークンのアドレス | StdToken `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、同じ名前のStdToken `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`（アカウント0番の二番目・三番目のデプロイ） | 2026-10-21 |
| 事件の年 | BadgerDAO 2021、Curve DNS 2022、Curve Vyper 2023.07.30（Vyper 0.2.15・0.2.16・0.3.0） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ウォレットが署名の内容を人が読めるように見せる設計 | [第222講](../../part15/lecture222/)、[第223講](../../part15/lecture223/) |
| 名前が同じトークンをイベントとアドレスで見分けるインデクサー | [第238講](../../part18/lecture238/) |
| コンパイラのバグ一覧の読み方 | [第184講](../../part11/lecture184/) |
| バージョンの変更履歴 | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| Vyper事件の攻撃過程の詳細 | 扱わない / [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |
| 監査でのデプロイ物とツールチェーンの確定 | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |
| セキュリティバグの報告とバウンティ | [第191講](../../part12/lecture191/)、[第193講](../../part12/lecture193/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
