# 第125講 Yulを単独で使う場面

第7部 アセンブリとYul・第28章 独立した言語としてのYul

[← 第124講](../../part7/lecture124/) | [第7部 目次](../) | [第126講 →](../../part7/lecture126/)

## この講義の問い

Yulだけでコントラクトを書くと何が減って何が抜け、実際にYulだけで書く場面はどこなのか。

## 実習資料

### 準備

YulのファイルとSolidityのファイルは、solc 0.8.30の実行ファイルを直接呼んでコンパイルした（Yulは`--strict-assembly`、入れたバージョンは`--optimize`、runs 200）。デプロイは、ローカルのanvilを新しく立ち上げてアカウント0番が`cast send --create`で行った。`Fwd125.yul`は転送先として、このチェーンでいちばん最初にデプロイしたBoxのアドレス（`0x5FbDB2315678afecb367f032d93F642f64180aa3`）を埋め込んであるので、試すときはBoxを先にデプロイするか、アドレスを変える。`market`は通しプロジェクトMarketの第125講のバージョンで、forge-stdが必要である。

### コード

| ファイル | 内容 |
|---|---|
| [code/yul/Tally125.yul](code/yul/Tally125.yul) | Yulだけで書いたTally。count・bump（Bumpedのログ）・owner・setOwnerのディスパッチャ。値のチェックとアドレスの引数のチェックがない |
| [code/sol/Tally.sol](code/sol/Tally.sol) | 同じことをするSolidityのバージョン |
| [code/yul/Fwd125.yul](code/yul/Fwd125.yul) | 受け取ったcalldataをBoxに`delegatecall`し、答えかリバートデータをそのまま返す転送役 |
| [code/sol/FwdSol.sol](code/sol/FwdSol.sol) | 同じ転送役をSolidityの`fallback`の中に書いたバージョン（転送先のアドレスは`immutable`） |
| [code/sol/Box.sol](code/sol/Box.sol) | 転送役が渡す先。store・value・fail（`Nope(7)`） |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第125講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第125講のバージョン。第124講のバージョンとコードが同じで、バージョンを説明するコメントを1行だけ足した。Yulだけで書いたファイルはない |
| [code/market/test/](code/market/test/) | Marketのテスト55個 |

EIP-1167の転送役は、ファイルなしでバイトを直接書いてデプロイした。デプロイのコード`3d602d80600a3d3981f3`の10バイトのうしろに、ランタイムの45バイトをつける。

```
363d3d373d3d3d363d73 5fbdb2315678afecb367f032d93f642f64180aa3 5af43d82803e903d91602b57fd5bf3
```

まん中の20バイトが転送先のアドレス（Box）である。

### 実行結果

Tallyの三つのバージョンのサイズとデプロイのgasUsed。

| バージョン | ランタイム / デプロイのコード（バイト） | デプロイのgasUsed |
|---|---|---|
| Tally125.yul `--optimize` | 146 / 160 | 106,897 |
| Tally.sol optimizerを切る | 877 / 969 | 265,389 |
| Tally.sol optimizerを入れる | 467 / 513 | 176,676 |
| Tally.sol via-IRで入れる | 380 / 424 | 157,848 |

bumpを送ると、三つともtopic0 `0xc081b7755956fdb9d6a5482bb04a62dbb62ad944141e7ff6ff2adad34bb1efb9`（Bumped）、data 1のログが残り、countは1である。gasUsedは44,255（Tally125） / 44,826（切る） / 44,586（入れる）である。実行ガス（`cast call --trace`のいちばん上の行）は、bump 23,191 / 23,522 / 23,347、count 2,149 / 2,260 / 2,247（Tally125 / Tally.sol 入れる / via-IRで入れる）である。

`solc --strict-assembly Tally125.yul --abi`。

```
Error: The following outputs are not supported in assembler mode: --abi.
```

1 weiをつけたbump（`cast send … "bump()" --value 1`）。

| バージョン | 結果 | コントラクトの残高 |
|---|---|---|
| Tally125.yul | status 1、gasUsed 27,155、count 2 | 1 wei |
| Tally.sol 入れる | `Failed to estimate gas: … execution reverted, data: "0x"` | 0 |

引数のないsetOwner（`cast call <アドレス> 0x13af4035 --from <アカウント0番>`）は、Tally125が`0x`（成功）、Tally.solが`execution reverted, data: "0x"`である。

上位12バイトをffで埋めたアドレスを、アカウント0番（今のowner）が送ったとき。

```
calldata 0x13af4035ffffffffffffffffffffffff70997970c51812dc3a010c7d01b50e0d17dc79c8

Tally.sol    Failed to estimate gas: … execution reverted, data: "0x"   ownerはそのまま
Tally125     status 1  gasUsed 26703
$ cast call <Tally125> "owner()"
0xffffffffffffffffffffffff70997970c51812dc3a010c7d01b50e0d17dc79c8
アカウント1番のsetOwner   execution reverted: custom error 0x30cd7471 … NotOwner
アカウント0番のsetOwner   execution reverted: custom error 0x30cd7471 … NotOwner
```

`caller()`は上位12バイトがいつも0なので、スロット1の値と同じになりえない。ownerは誰も変えられなくなった。

`solc --ir Tally.sol`は493行・関数68個・`callvalue()`が5か所、`--ir-optimized --optimize`は87行・関数0個である。Marketの`forge inspect ir`（3,072行）には、`validator_revert_t_address`が4か所（定義二つ・呼び出し二つ）、`callvalue()`が20か所ある。

四つの転送役のサイズとデプロイのgasUsed。

| コントラクト | ランタイム / デプロイのコード（バイト） | デプロイのgasUsed |
|---|---|---|
| EIP-1167のバイトそのまま | 45 / 55 | 62,915 |
| Fwd125.yul（`--optimize`） | 46 / 56 | 63,128 |
| FwdSol.sol optimizerを入れる | 119 / 274（コンストラクタの引数32を含む） | 80,913 |
| Box.sol optimizerを切る | 494 / 522 | 159,683 |

転送役でstoreを送ると、Boxのコードが転送役のアドレスで動き、転送役のスロット0が変わる。Box自身のスロット0は、直接送った1のままである。

```
Box.store(1) 直接            status 1
Fwd125   store(5)            status 1  gasUsed 46385   value() 5   cast storage <Fwd125> 0   0x…05
FwdSol   store(6)            status 1  gasUsed 46400   value() 6   cast storage <FwdSol> 0   0x…06
EIP-1167 store(8)            status 1  gasUsed 46387   value() 8   cast storage <EIP-1167> 0 0x…08
Box      value() 1           cast storage <Box> 0   0x…01
```

`fail()`は、三つの転送役のどれもがBoxのリバートデータをそのまま送り返す。

```
$ cast call <転送役> "fail()"
Error: execution reverted: Nope(7)
… data: "0x63a2a81f0000000000000000000000000000000000000000000000000000000000000007"
$ cast calldata "Nope(uint256)" 7
0x63a2a81f0000000000000000000000000000000000000000000000000000000000000007
```

転送役の実行ガス（`cast call --trace`のいちばん上の行）。

| 呼んだ先 | store(5) | value() |
|---|---|---|
| Box直接（optimizerを入れる） | 22,309 | 2,259 |
| Fwd125.yul | 24,976 | 4,923 |
| FwdSol.sol 入れる | 24,991 | 4,941 |
| EIP-1167 | 24,978 | 4,925 |

コードの保存のガスは1バイトあたり200である。0x20・0x40・0x60バイトを返すinitcode（`60NN5ff3`）のデプロイのgasUsedが59,474 / 65,877 / 72,280で、1段階の差6,403 = 32 × 200 + メモリ1ワードの3である。

Market 第125講のバージョンは、methodIdentifiers 19、ABIのfunction 19 / event 4 / error 12 / constructor 1、ランタイム7,353 / デプロイのコード7,931、`forge test`の55個が通る。

### 試すときの注意

- Yulだけで書いたコントラクトには、コンパイラがつけていたチェックがない。値を受け取らない関数の`callvalue()`のチェック、calldataの長さのチェック、アドレスの引数の上位12バイトのチェックを自分で書かなければならない。
- セレクタとイベントのtopicは、`cast sig`・`cast keccak`で求めて定数として書く。ABIは出てこない。
- `cast send --create`は、ほかのオプションのうしろのいちばん最後に置く。
- 三つの転送役は、呼ぶときのガスがほとんど同じで（差は15以内）、デプロイのバイトだけが違う。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやハードフォークが変わると数字が変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| `--strict-assembly`での`--abi` | `Error: The following outputs are not supported in assembler mode: --abi.`、メタデータの末尾なし | 2026-10-19 |
| EIP-1167 | ERC-1167: Minimal Proxy Contract、2018-06-22作成、Final（Standards Track: ERC）。ランタイム`363d3d373d3d3d363d73` + アドレス20バイト + `5af43d82803e903d91602b57fd5bf3`（10〜29番目のバイトがアドレス）。本文にデプロイのコードはない。デプロイのコード`3d602d80600a3d3981f3`は自分で書いた | 2026-10-19 |
| コードの保存のガス | 1バイトあたり200。0x20・0x40・0x60バイトを返すinitcode（`60NN5ff3`）のデプロイのgasUsed 59,474 / 65,877 / 72,280、差6,403 = 32 × 200 + メモリ1ワードの3 | 2026-10-19 |
| solc | 0.8.30+commit.73712a01。直接呼ぶとevm_versionはprague、forge 1.8.3のビルドはosaka（コードは同じ、メタデータの末尾だけが違う） | 2026-10-19 |
| Foundry（forge・cast・anvil） | 1.8.3、anvilのハードフォークはBpo1 | 2026-10-19 |
| optimizer | 入れたバージョンはruns 200 | 2026-10-19 |
| Tallyのサイズ（ランタイム / デプロイのコード） | Tally125.yul `--optimize` 146 / 160、optimizeなし150 / 164・Tally.sol 切る877 / 969、入れる467 / 513、via-IRで入れる380 / 424 | 2026-10-19 |
| TallyのデプロイのgasUsed | 106,897 / 265,389 / 176,676 / 157,848 | 2026-10-19 |
| Tallyのbumpのトランザクション | gasUsed 44,255（Tally125） / 44,826（切る） / 44,586（入れる）、三つともtopic0 0xc081b775…efb9、data 1・`--value 1`のbumpはTally125でgasUsed 27,155 | 2026-10-19 |
| Tallyの実行ガス | bump 23,191 / 23,522 / 23,347、count 2,149 / 2,260 / 2,247（Tally125 / Tally.sol 入れる / via-IRで入れる） | 2026-10-19 |
| Tally125のownerのロック | 上位12バイトがffのcalldataでsetOwner status 1、gasUsed 26,703、owner() `0xffffffffffffffffffffffff70997970c51812dc3a010c7d01b50e0d17dc79c8` | 2026-10-19 |
| Tally.solのIR | `--ir` 493行・関数68個・`callvalue()` 5か所、`--ir-optimized --optimize` 87行・関数0個 | 2026-10-19 |
| 転送役のサイズ・デプロイのgasUsed | EIP-1167 45 / 55、62,915・Fwd125 46 / 56、63,128・FwdSol 入れる119 / 274、80,913・FwdSol 切る121 / 418、83,650・Box 切る494 / 522、159,683・Box 入れる214 / 240、99,711 | 2026-10-19 |
| 転送役のstoreのトランザクション | store(5) / (6) / (8) gasUsed 46,385 / 46,400 / 46,387、Box.store(1) 43,718 | 2026-10-19 |
| 転送役の実行ガス | store(5) Box直接22,309 / Fwd125 24,976 / FwdSol 24,991 / EIP-1167 24,978、value() 2,259 / 4,923 / 4,941 / 4,925 | 2026-10-19 |
| MarketのIR | 3,072行、`validator_revert_t_address` 4か所（定義二つ・呼び出し二つ）、`callvalue()` 20か所 | 2026-10-19 |
| Marketの数 | methodIdentifiers 19、ABIのfunction 19 / event 4 / error 12 / constructor 1、ランタイム7,353 / デプロイのコード7,931、テスト55個 | 2026-10-19 |
| デプロイのアドレス | 新しく立ち上げたanvilでデプロイした順に: Box `0x5FbDB2315678afecb367f032d93F642f64180aa3`、Store124 `0xe7f1…0512`、Store `0xcf7e…0fc9`、Tally125 `0xdc64…f6c9`、Tally.sol 切る`0x5fc8…5707`、入れる`0x0165…eb8f`、Fwd125 `0xa51c…91c0`、FwdSol 入れる`0x0dcd…cd82`、切る`0x9a67…7508`、EIP-1167 `0x0b30…7016` / アカウント0番 `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`、アカウント1番 `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`（公開されたテスト用の鍵） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| グローバル関数・組み込み関数の総覧 | [第126講](../../part7/lecture126/) |
| Yulの文法規格 | [第127講](../../part7/lecture127/) |
| YulのソースをStandard JSONで入れる方法 | [第128講](../../part8/lecture128/) |
| Yulで書いたコントラクトの検証 | [第130講](../../part8/lecture130/) |
| ABIエンコードの規則と引数のチェック | [第141講](../../part8/lecture141/) |
| サイズと実行ガスを見比べて選ぶ判断 | [第143講](../../part9/lecture143/)、[第144講](../../part9/lecture144/)、[第145講](../../part9/lecture145/) |
| 転送役・プロキシの構造、同じ転送役をいくつもデプロイするクローン、転送先のアドレスを選ぶこと、実装側のコンストラクタが動かない問題と初期化 | [第160講](../../part10/lecture160/)、[第161講](../../part10/lecture161/)、[第162講](../../part10/lecture162/)、[第163講](../../part10/lecture163/)、[第164講](../../part10/lecture164/) |
| 返ってきたデータを扱う危険 | [第170講](../../part11/lecture170/)、[第171講](../../part11/lecture171/) |
| 監査でYulのファイルを読む | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
