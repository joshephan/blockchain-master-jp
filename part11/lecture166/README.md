# 第166講 五軸の派生マップ

第11部 推奨事項：敵対的環境とバージョン履歴・第43章 敵対的環境の法則と5つの軸

[← 第165講](../../part11/lecture165/) | [第11部 目次](../) | [第167講 →](../../part11/lecture167/)

## この講義の問い

数多くの脆弱性をどうやって五つの系統に絞り、それぞれの系統は三つの法則のうちどこから出てくるのか。自分のコードでその系統が触れる行はどうやって探すのか。

## 実習資料

### 準備

通しプロジェクトMarketの第42章の終わりのバージョン（第164講のバージョン）を、コードもテストもそのまま使う。テストにはforge-stdが必要である（`lib/forge-std`）。同じブロックの中の取引の順番を見るデモは、ローカルのanvilを`--timestamp 1767225600 --order fees`で立ち上げ、回ごとに立ち上げ直す。アカウントはanvilの公開されたテスト用アカウントで、外部への接続はない。

### コード

| ファイル | 内容 |
|---|---|
| [code/market/foundry.toml](code/market/foundry.toml) | solc 0.8.30、optimizerオン（runs 200）・via-IRオン・evm osaka |
| [code/market/src/Market.sol](code/market/src/Market.sol) | レンディング市場の本体。外部呼び出し（168・183行）、管理者関数（97・130行）、経過時間（210行） |
| [code/market/src/MarketMath.sol](code/market/src/MarketMath.sol) | 利息計算（21行）、block.timestampの記録（33・41行） |
| [code/market/src/MarketTypes.sol](code/market/src/MarketTypes.sol) | Amount・Rate・Ratio型と構造体 |
| [code/market/src/IMarket.sol](code/market/src/IMarket.sol) | Marketのインターフェース |
| [code/market/src/MockToken.sol](code/market/src/MockToken.sol) | デモ用のトークン |
| [code/market/test/Pull.t.sol](code/market/test/Pull.t.sol) | トークンがtransferの途中で見た帳簿（70・70・100）、PullTestの二つ |
| [code/market/test/StatusTable.t.sol](code/market/test/StatusTable.t.sol) | 市場の状態ごとに許される関数の表、StatusTableTestの四つ |
| [code/market/test/Guards.t.sol](code/market/test/Guards.t.sol) | 預けた量より多く引き出すとInsufficientDeposit、GuardsTestの一つ |
| [code/market/test/Access.t.sol](code/market/test/Access.t.sol) | 管理者関数のアクセスチェック、AccessTestの二つ |
| [code/market/test/](code/market/test/) | 第42章の終わりのバージョンのテストすべて |

### 実行結果

`forge test --offline --match-contract "PullTest|AccessTest|GuardsTest|StatusTableTest"`は九つすべてが通る。テストごとのガスは時効性の表にある。

外部呼び出しの行（`grep -n "IERC20(asset)\." src/*.sol`）：

```
src/Market.sol:168:        bool ok = IERC20(asset).transferFrom(msg.sender, address(this), amount); // 第83講
src/Market.sol:183:        bool ok = IERC20(asset).transfer(msg.sender, amount); // 第83講
```

block.timestampを読む三か所（`grep -n "block\.\|tx\.origin" src/*.sol`からコメント行を除いたもの）：

```
src/MarketMath.sol:33:        self.lastUpdate = uint64(block.timestamp);
src/MarketMath.sol:41:        self.lastUpdate = uint64(block.timestamp);
src/Market.sol:210:        return block.timestamp - p.lastUpdate;
```

繰り返しと算術の行：

```
src/Market.sol:197:  totalDeposits[asset] = totalDeposits[asset] + Amount.wrap(amount);
src/Market.sol:203:  totalDeposits[asset] = totalDeposits[asset] - Amount.wrap(amount);
src/Market.sol:256:  for (uint256 i = 0; i < assets.length; i++) {
src/MarketMath.sol:21:  return amount * Rate.unwrap(rate) * elapsed / SECONDS_PER_YEAR / 1e18;
```

管理者の行：

```
src/Market.sol:67:    address public immutable admin;
src/Market.sol:97:    function setStatus(MarketStatus s) external onlyAdmin {
src/Market.sol:104:        if (msg.sender != admin) revert NotAdmin(msg.sender); // 第108講
src/Market.sol:130:    function addAsset(IERC20 asset, Ratio ratio) external onlyAdmin notFrozen {
```

署名・ハッシュの行（`grep -n "ecrecover\|keccak256\|abi.encode" src/Market.sol src/MarketMath.sol src/MarketTypes.sol`）は出力がない。

同じブロックに入った二つの取引。アカウント1番が100を預けたあとautomineを切り、アカウント1番のwithdraw 100と管理者のsetStatus(Frozen)を`--async`で送ると、`txpool_status`は`{"pending":"0x2","queued":"0x0"}`である。二つの取引の中身は同じで、手数料だけを変えて順番を入れ替えた二回の結果（`evm_mine`のあとの`cast receipt`）：

| | 順番1 | 順番2 |
|---|---|---|
| 6番ブロックの位置0 | withdraw 100、status 1 | setStatus(Frozen)、status 1 |
| 6番ブロックの位置1 | setStatus(Frozen)、status 1 | withdraw 100、status 0 |
| アカウント1番の帳簿 | 0 | 100 |
| アカウント1番のトークン | 200 | 100 |
| 市場の状態 | Frozen | Frozen |
| ブロックのあとwithdraw 100を先に走らせると | MarketFrozen | MarketFrozen |

この講義で作った攻撃マップ（軸五つ）：

| 軸 | 出てくる法則 | Marketで触れる行 | 今防いでいるものと確認したテスト | 以前の文書の行 |
|---|---|---|---|---|
| 1・制御権の移転 | 透明性・決定性 | depositのtransferFrom（Market.sol 168）、withdrawのtransfer（183） | withdrawは帳簿を先に減らしてからトークンを送る（第150講）、test/Pull.t.sol | 信頼の前提の第83講・第154講の行（トークン呼び出しの間トークンのコードが動く） |
| 2・順番の操作 | 透明性・決定性 | 同じブロックの中のsetStatusとwithdrawの順番、block.timestampの三か所（MarketMath.sol 33・41、Market.sol 210） | 防ぐ行なし（順番はブロックを作る側が決める）、test/StatusTable.t.solは順番を一つだけ見る | 信頼の前提の第76講の行 |
| 3・資源と精度 | 決定性 | Amountの+・-（0.8の既定の算術）、collateralCountのassets全体の繰り返し（256）、interestForの割り算 | オーバーフローチェックとInsufficientDeposit、test/Guards.t.sol | 信頼の前提の第81講・第88講・第89講の行 |
| 4・中央の点 | 不変性 | onlyAdminの二つ（setStatus 97、addAsset 130）、immutable admin | msg.senderの確認（104）、譲る関数なし、test/Access.t.sol | 権限一覧の第151講・第164講の行、信頼の前提の第151講・第164講の行 |
| 5・暗号の部品の組み違い | 透明性・不変性 | なし（署名・マークル証明・ハッシュ確認の行は0か所） | 該当なし | 信頼の前提の第79講の行（Marketに署名の機能なし） |

### 試すときの注意

- anvilのブロック内の順番は、`--order fees`を指定しないと手数料の大きい取引が前に来ない。既定（`--order`なし）は入ってきた順なので、チップだけを変えても順番は変わらない。
- 行番号は第42章の終わりのバージョンが基準である。バージョン説明のコメントが変わると行番号も変わる。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンや実行環境が変わると値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| solc | 0.8.30、Market第42章の終わりのバージョンの既定プロファイル | 2026-10-20 |
| anvilの設定 | `--timestamp 1767225600 --order fees`、`anvil_setBlockTimestampInterval 1`、回ごとに立ち上げ直す | 2026-10-20 |
| anvilの順番 | `--order fees`は手数料の大きい取引を前に。既定（`--order`なし）は入ってきた順なので、チップだけを変えても変わらない | 2026-10-20 |
| 手数料の値 | 順番1：withdrawは最大30gwei・チップ3gwei、setStatusは最大10gwei・チップ1gwei。順番2：逆。ガスリミットはどちらも200,000 | 2026-10-20 |
| ガス | withdraw 100の成功45,959、setStatus(Frozen) 45,001、失敗したwithdraw 24,323 | 2026-10-20 |
| テスト | PullTestの二つ（780,522 / 714,657）、GuardsTestの一つ（73,013）、AccessTestの二つ（35,962 / 436,538）、StatusTableTestの四つ（29,690 / 35,041 / 754,910 / 376,283） | 2026-10-20 |
| 行番号 | Market.sol 67・97・104・130・168・183・197・203・210・256、MarketMath.sol 21・33・41、MarketTypes.sol 13・17・21（第42章の終わりのバージョン） | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| 制御権の移転の回収（再入とその変種、外部呼び出しの結果、標準違反のトークン） | [第168講](../../part11/lecture168/)、[第169講](../../part11/lecture169/)、[第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/)、[第177講](../../part11/lecture177/) |
| 順番の操作の回収（取引の順番選び、オラクルの操作、フラッシュローン、オンチェーンの乱数） | [第172講](../../part11/lecture172/)、[第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/) |
| 中央の点の回収（アクセス制御、プロキシの乗っ取り、鍵の管理とマルチシグ、ブリッジ） | [第176講](../../part11/lecture176/)、[第177講](../../part11/lecture177/)、[第178講](../../part11/lecture178/)、[第179講](../../part11/lecture179/)、[第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |
| 暗号の部品の組み違いの回収（署名の再利用、証明検証の組み立て） | [第172講](../../part11/lecture172/)、[第173講](../../part11/lecture173/)、[第174講](../../part11/lecture174/)、[第175講](../../part11/lecture175/)、[第179講](../../part11/lecture179/)、[第212講](../../part14/lecture212/)、[第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| コードの外からの攻撃 | [第180講](../../part11/lecture180/)、[第181講](../../part11/lecture181/) |
| 検証ツールと不変条件 | [第182講](../../part11/lecture182/)、[第183講](../../part11/lecture183/) |
| 事件の年表を軸で分け直す | [第265講](../../part21/lecture265/)、[第266講](../../part21/lecture266/)、[第267講](../../part21/lecture267/)、[第268講](../../part21/lecture268/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
