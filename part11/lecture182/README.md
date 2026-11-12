# 第182講 SMTChecker

第11部 推奨事項：敵対的環境とバージョン履歴・第48章 検証と形式証明

[← 第181講](../../part11/lecture181/) | [第11部 目次](../) | [第183講 →](../../part11/lecture183/)

## この講義の問い

SMTCheckerは何を問うのか。答えがないとき、ツールは何を残すのか。警告がないことは、いつ証明で、いつ何の意味もないのか。Marketにかけると何が出るのか。

## 実習資料

### 準備

solc 0.8.30の実行ファイル一つで`smt/`の小さなファイルを直接コンパイルし、通しプロジェクトMarket（第46章の終わりのバージョン）のsrcにSMTCheckerをかける。ソルバー（z3、cvc5、Eldarica）はインストールしていない状態で回した。そのため、出た結果はすべて「ソルバーがないときに残るもの」である。Marketのforgeのビルドにはforge-stdが必要である。Marketのコードとテストはそのままで、この講義ではデモ用にfoundry.tomlの末尾に`[profile.smt]`と`[profile.smt.model_checker]`だけを足した（基準のバージョンにはない）。anvilと外部への接続は使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/smt/Seven.sol](code/smt/Seven.sol) | 7を入れると壊れる`assert(x != 7)`一つ |
| [code/smt/Prag.sol](code/smt/Prag.sol) | 同じコードに`pragma experimental SMTChecker;`をつけたバージョン |
| [code/smt/Plain.sol](code/smt/Plain.sol) | `a * b / 1e18`を行うinternal関数 |
| [code/smt/Nondet.sol](code/smt/Nondet.sol) | 同じ関数に`/// @custom:smtchecker abstract-function-nondet`をつけたバージョン |
| [code/smt/Typo.sol](code/smt/Typo.sol) | タグの値を`abstract-function-nondett`と書き間違えたバージョン |
| [code/smt/sj_z3.json](code/smt/sj_z3.json) | Standard JSONの入力（engine chc、solvers z3） |
| [code/smt/sj_smtlib2.json](code/smt/sj_smtlib2.json) | Standard JSONの入力（engine chc、solvers smtlib2） |
| [code/market/foundry.toml](code/market/foundry.toml) | Marketのビルド設定、末尾にデモ用の`smt`プロファイル |
| [code/market/src/](code/market/src/) | Marketの本体（前のバージョンのまま） |
| [code/market/test/](code/market/test/) | 前のバージョンまでに積み重なったテスト（そのまま） |

### 実行結果

`solc --model-checker-engine bmc --model-checker-solvers smtlib2 --model-checker-print-query Seven.sol`がソルバーに送ろうとした質問の式（33行のうちの抜粋、`...`は省略）。xは0 〜 2²⁵⁶−1の任意の値で、最後の行`(not expr_11_1)`は「x != 7が偽」である。この式を真にするxがあるかという質問である。

```
Info: BMC: Requested query:
(set-option :produce-models true)
(set-logic ALL)
...
(declare-fun |x_3_0| () Int)
(declare-fun |expr_9_0| () Int)
(declare-fun |expr_10_0| () Int)
(declare-fun |expr_11_1| () Bool)
(assert (and ... (= expr_11_1 (not (= expr_9_0 expr_10_0)))
  ... (= expr_10_0 7)
  ... (= expr_9_0 x_3_0)
  ... (>= x_3_0 0) (<= x_3_0 115792089237316195423570985008687907853269984665640564039457584007913129639935)
  ... (not expr_11_1)))
(check-sat)
```

質問の式の名前はASTのノード番号から来る（`solc --ast-compact-json Seven.sol`）。

| ASTのノード | id | src |
|---|---|---|
| xの宣言`uint256 x` | 3 | 95:9 |
| 式の中のx | 9 | 155:1 |
| 7 | 10 | 160:1 |
| `x != 7` | 11 | 155:6 |
| assertの呼び出し`assert(x != 7)` | 12 | 148:14 |

ソルバーを選ばずに回すと、既定値のz3を探して警告二行だけを残し、終了コード0で終わる。assertの話は一行もない。

```
$ solc --model-checker-engine chc Seven.sol
Warning: Solver z3 was selected for SMTChecker but it is not available.

Warning: CHC analysis was not possible since no Horn solver was found and enabled. The accepted solvers for CHC are Eldarica and z3.
$ echo $?
0
$ solc --model-checker-engine bmc Seven.sol
Warning: Solver z3 was selected for SMTChecker but it is not available.

Warning: BMC analysis was not possible since no SMT solver was found and enabled. The accepted solvers for BMC are cvc5 and z3.
$ echo $?
0
```

ソルバーの代わりに質問を外に出すsmtlib2で回すと、"might happen"が出る。証明も反例も出せなかったという表示である。

```
$ solc --model-checker-engine chc --model-checker-solvers smtlib2 \
       --model-checker-show-unproved Seven.sol
Warning: CHC: Assertion violation might happen here.
 --> Seven.sol:6:9:
  |
6 |         assert(x != 7);
  |         ^^^^^^^^^^^^^^

Warning: CHC analysis was not possible. No Horn solver was available. None of the installed solvers was enabled.
$ echo $?
0
```

Standard JSONで入れた結果。`sj_z3.json`は警告8158・7649と終了コード0、`sj_smtlib2.json`は質問の式を`auxiliaryInputRequested`に出す（キーは質問のハッシュ、値はHornの式86行）。

```
$ solc --standard-json sj_smtlib2.json > sj_smtlib2.out.json; echo $?
0
errors:
  warning 6328 | CHC: Assertion violation might happen here.
  warning 3996 | CHC analysis was not possible. No Horn solver was available. ...
auxiliaryInputRequested:
  smtlib2queries: 1
    "0x043cb67b…2a6692958": "(set-logic HORN) ... (check-sat)"
```

MarketのsrcにCHC・smtlib2で既定の目標をかけた結果（`--model-checker-contracts src/Market.sol:Market --model-checker-show-unproved --model-checker-show-unsupported`）。目標四つがすべてmight happenである。

| 行 | 目標 | コード |
|---|---|---|
| Market.sol 209:9 | Assertion violation might happen | `assert(Amount.unwrap(totalDeposits[asset]) >= Amount.unwrap(p.deposited))` |
| Market.sol 262:35 | Out of bounds access might happen | `assets[i]` |
| MarketMath.sol 21:16（二つ） | Division by zero might happen | `amount * Rate.unwrap(rate) * elapsed / SECONDS_PER_YEAR / 1e18` |

同じ実行で、"Assertion checker does not yet implement type error"の警告が十三か所に出る。ユーザー定義のエラーで差し戻す`revert ZeroAdmin()`（Market.sol 72）、`revert NotActive(status)`（92）、`revert NotAdmin(msg.sender)`・`revert MarketFrozen()`（106・110）、`revert ZeroAsset()`・`AlreadyListed`・`RatioAboveCap`（133・134・135）、`revert NotListed(asset)`（148）、`revert TransferFromFailed(asset)`・`TransferFailed(asset)`（172・188）、`revert ZeroAmount()`（179・185）、`revert IMarket.InsufficientDeposit(have, amount)`（MarketMath.sol 39）である。

目標をすべてオンにした結果（`--model-checker-targets all`）：

| 目標（CHC、targets all） | 数 | 行 |
|---|---|---|
| Assertion violation、Out of bounds | 2 | Market 209、262 |
| Division by zero | 2 | MarketMath 21 |
| Overflow | 5 | Market 261 `i++`、263 `count++`、MarketMath 21の二つ、MarketTypes 14 addAmount |
| Underflow | 2 | Market 215、MarketTypes 18 subAmount |
| BMCで回すと | 10 | 配列の範囲の目標なし |

コメント一行違いの三つのバージョン（chc、smtlib2、targets all、show-unproved）：

| バージョン | SMTCheckerオン | 備考 |
|---|---|---|
| Plain.sol | Overflow might happen 7:16、Division by zero might happen 7:16、CHC analysis was not possible | 本体`a * b / 1e18`の目標二つ |
| Nondet.sol | 出力なし | 目標がなくなり、ソルバーなしの行もない |
| Typo.sol（`abstract-function-nondett`） | Unknown option for "custom:smtchecker"、Overflow might happen 7:16 | SMTCheckerを切ってコンパイルするとCompiler run successful. No output generated. 終了コード0 |

`market`でsmtプロファイルでビルドした結果（警告の行数は個数に縮めて書いた）。警告があっても終了コードは0で、`--deny warnings`をつけてはじめて1になる。

```
$ FOUNDRY_PROFILE=smt forge build --offline --force
Compiler run successful with warnings:
Warning (6328) ×1, (6368) ×1, (4281) ×2, (4984) ×5, (3944) ×2   検証目標 11
Warning (3996) ×1   CHC analysis was not possible
Warning (5724) ×47  SMTChecker: 13 unsupported language feature(s).
$ echo $?
0
$ FOUNDRY_PROFILE=smt forge build --offline --force --deny warnings; echo $?
1
```

### 試すときの注意

- SMTCheckerはrequireを仮定として、assertをどんな入力でも真でなければならない目標として見る。書かなかったルールは問わない。
- 警告がないことが証明になるには、ソルバーがあってチェックが最後まで回らなければならない。ソルバーがなければ警告が数行残るだけで、終了コードは0である。終了コードだけを見るCIは、チェックが回ったかどうかを知らない。
- Windows用のsolcの実行ファイルにはz3が入っていない。ドキュメントによれば、z3は`soljson.js`（JavaScript版のコンパイラ）に静的に入っており、それ以外ではシステムにインストールされた実行ファイルを使う。cvc5とEldarica（`eld`）は、インストールされた実行ファイルが必要である。
- `happens here`は目標が壊れるという証明（反例が一緒に出ることがある）で、`might happen here`は決められた時間内に証明も反例も出せなかったという表示である。
- サポートしていない文法は、何でもできるとみなして覆って進む。安全だという結論はそのまま信じられるが、誤報が出ることがある。
- `block.timestamp`は質問の式で範囲だけがかかった変数である。時間が逆に進まないという事実はチェッカーの外なので、`block.timestamp - p.lastUpdate`（Market.sol 215）にUnderflow might happenが出る。
- `@custom:smtchecker abstract-function-nondet`をつけると、本体を見ずに任意の値を返す関数とみなして、本体の中の目標が消える。タグの値の書き間違いは、SMTCheckerを切ってコンパイルすると何も言わずに通る。
- forgeの既定値は`deny = "never"`なので、SMTCheckerの警告があってもビルドが通る。SMTCheckerの警告番号は`ignored_error_codes`にもないので、隠しも止めもしない。
- ドキュメントのOverflow・Robotの例のように反例と取引の順番（Transaction trace）が出る出力は、ソルバーがあってはじめて得られる。この環境では出たことがない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョンとインストールしたソルバーによって結果が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30+commit.73712a01.Windows.msvc | 2026-10-21 |
| Foundry（forge） | 1.8.3 (cae51ad4) | 2026-10-21 |
| ソルバー | z3・cvc5・Eldaricaの実行ファイルなし、Pythonのz3モジュールなし（インストールしていない） | 2026-10-21 |
| forgeの既定値 | `deny = "never"`、`ignored_error_codes`の六つ（license、code-size、init-code-size、transient-storage、transfer-deprecated、natspec-memory-safe-assembly-deprecated） | 2026-10-21 |
| forgeのsmtプロファイルの警告の数 | 6328 1、6368 1、4281 2、4984 5、3944 2、3996 1、5724 47（5724の行数はビルドするテストファイルの数によって変わる） | 2026-10-21 |
| Marketのチェックの基準 | 第46章の終わりのバージョンのsrcのまま | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ソルバー（z3・Eldarica）をインストールして実際の証明と反例を受け取る | [第259講](../../part20/lecture259/)、[第260講](../../part20/lecture260/) |
| CHCが見つけた帰納的不変条件を見る（`--model-checker-invariants`） | [第259講](../../part20/lecture259/) |
| 外部の形式検証ツール・記号実行ツール | [第260講](../../part20/lecture260/) |
| 状態を変えながら実際に回して確かめるテスト | [第183講](../../part11/lecture183/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
