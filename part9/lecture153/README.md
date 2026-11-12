# 第153講 Resources、Contributing、Brand Guide

第9部 最適化と規律・第40章 エコシステムと貢献

[← 第152講](../../part9/lecture152/) | [第9部 目次](../) | [第154講 →](../../part10/lecture154/)

## この講義の問い

言語の外に置かれた三つ（ツールの一覧、コンパイラのリポジトリに貢献する手順、名前とロゴの規則）をどう読み、自分のバージョン・自分の報告・自分の資料にどう照らし合わせるのか。

## 実習資料

### 準備

公式ドキュメントのResources、Contributing、Brand Guideの3ページとコンパイラのリポジトリ（github.com/argotorg/solidity、タグv0.8.36）を読み、リポジトリのテストの形とChangelogをsolc 0.8.30に照らし合わせる。コンパイラはビルドしていない。リポジトリは必要なフォルダだけをsparse cloneで取得した（`.github`、`docs`、`test/libsolidity/syntaxTests`、`test/cmdlineTests`、`scripts`）。Windowsでは取得する前に`git config core.longpaths true`と`git config core.autocrlf false`が必要である（ないと`Filename too long`で止まる）。

文法テスト（syntax test）の期待値の照合は、isoltestの代わりに、期待値の照合だけをまねた簡易チェッカーで行った（Standard JSON、optimizerオン、CBORメタデータオフ、警告1878・3420を除外、設定の欄があるファイルやソースが複数のファイルは飛ばす）。このチェッカーと結果の分類ツールは測定用なので載せていない。最小の再現とevm-versionの確認は、solc 0.8.30を直接呼ぶか、小さなFoundryプロジェクト（`demo/p153rep`、evm osaka）で`forge test`で行う。

通しプロジェクトMarketは第152講のバージョンのままである（コードの変更なし）。テストにはforge-stdが必要である（`lib/forge-std`）。

### コード

| ファイル | 内容 |
|---|---|
| [code/demo/p153syn/a_repo.sol](code/demo/p153syn/a_repo.sol) | リポジトリの文法テストのファイルそのまま（同じ名前を2回宣言、期待値`DeclarationError 2333`） |
| [code/demo/p153syn/b_doc.sol](code/demo/p153syn/b_doc.sol) | Contributingのドキュメントに載っている形（エラー番号なし、インデントは空白） |
| [code/demo/p153syn/c_broken.sol](code/demo/p153syn/c_broken.sol) | 2番目の宣言を消したバージョン |
| [code/demo/p153syn/d_updated.sol](code/demo/p153syn/d_updated.sol) | cを期待値まで直したバージョン |
| [code/demo/p153rep/Prec.sol](code/demo/p153rep/Prec.sol) | 最小の再現：`x & 0 == 1`（f）と、かっこを付けた`x & (0 == 1)`（g） |
| [code/demo/p153rep/src/Prec.sol](code/demo/p153rep/src/Prec.sol)、[code/demo/p153rep/test/Prec.t.sol](code/demo/p153rep/test/Prec.t.sol) | fだけを置いたバージョンと、0〜299でfが常に偽かを見るテスト |
| [code/demo/p153rep/Blob.sol](code/demo/p153rep/Blob.sol) | `block.blobbasefee`を読む関数（evm-version五つでビルド） |
| [code/demo/p153rep/Nat.sol](code/demo/p153rep/Nat.sol)、[code/demo/p153rep/Nat2.sol](code/demo/p153rep/Nat2.sol) | internal関数の`@param`の名前が間違っているバージョンと正しいバージョン。どちらもイベントに`@return` |
| [code/demo/p153rep/foundry.toml](code/demo/p153rep/foundry.toml) | solc 0.8.30、evm osaka |
| [code/market/](code/market/) | Market第153講のバージョン（第152講のバージョンと同じ）。テスト23ファイル（75個のテスト） |

### 実行結果

文法テストの四つの形を簡易チェッカーで照合した結果。ドキュメントに載っている形（b）は、エラー番号とバイト範囲がリポジトリのファイルと違うのでFAILである：

```
a_repo.sol: OK
    Expected result:
        DeclarationError 2333: (36-52): Identifier already declared.
    Obtained result:
        DeclarationError 2333: (36-52): Identifier already declared.
b_doc.sol: FAIL
    Expected result:
        DeclarationError: (36-52): Identifier already declared.
    Obtained result:
        DeclarationError 2333: (42-58): Identifier already declared.
c_broken.sol: FAIL
    Expected result:
        DeclarationError 2333: (36-52): Identifier already declared.
    Obtained result:
        Success
d_updated.sol: OK
    Expected result:
        Success
    Obtained result:
        Success
```

リポジトリの文法テスト3,547個をsolc 0.8.30で照合した結果（ソースが一つで設定の欄がない3,107個）：

```
FAIL 190
OK 2917
skip-multi 183
skip-not-utf8 1
skip-settings 256
```

FAILのうち、期待値にだけある行（0.8.30が出さないもの）の前半：

```
28 // Warning 6335: (17-50): "transient" will be promoted to keyword in the future and will not be allowed as an identifier anymore.
28 // Warning 8429: (106-132): Virtual modifiers are deprecated and scheduled for removal.
24 // Warning 9511: (34-53): ABI coder v1 is deprecated and scheduled for removal. Use ABI coder v2 instead.
...
6 // Warning 9207: (50-77): 'send' is deprecated and scheduled for removal. Use 'call{value: <amount>}("")' instead.
```

0.8.30の出力にだけある行のうち大きいものは`27 // DeclarationError 7576: (22-29): Undeclared identifier.`（0.8.35でできた`erc7201`という名前を0.8.30が知らない）である。ドキュメントの例169個を同じ方法でビルドすると`{'ok': 160, 'FAIL': 6, 'skip': 3}`である。FAILの六つはすべて「This will report a warning」というコメントが付いた例（send二つ、transfer一つ、virtual modifier二つ、`at`一つ）で、0.8.30はその警告を出さない。

`docs/resources.rst`のツールの一覧（「合計」の行は付けた集計）：

```
General Resources: 11
Integrated (Ethereum) Development Environments: 7
Editor Integrations: 12
Solidity Tools: 22
Third-Party Solidity Parsers and Grammars: 1
合計 53
28 💡 Note: As per the official docs, Brownie is no longer actively maintained.
46 💡 Note: Consensys announced the sunset of Truffle on September 21, 2023.
86 💡 Note: As per the official repository, this extension has been removed from the VSCODE marketplace and will be replaced by a dedicated stand-alone desktop application.
99 💡 Note: This extension has built-in support for the Truffle Suite which is being sunset.
```

最小の再現。かっこを付けたgは、`&`をboolに使えないのでビルドされない。`x & 0 == 1`が`(x & 0) == 1`と結びつくということである：

```
Error (2271): Built-in binary operator & cannot be applied to types uint160 and bool.
  --> Prec.sol:10:16:
   |
10 |         return x & (0 == 1);
   |                ^^^^^^^^^^^^
```

fだけを置いたプロジェクトで`forge test`は`[PASS] test_alwaysFalse()`である。コンパイラのバグではなく演算子の優先順位である。

`solc --evm-version <バージョン> Blob.sol`の結果：

```
-- paris
exit 1
Error (1006): "blobbasefee" is not supported by the VM version.
-- shanghai
exit 1
Error (1006): "blobbasefee" is not supported by the VM version.
-- cancun
exit 0
-- prague
exit 0
-- osaka
exit 0
```

`solc --userdoc --devdoc`でNatの二つのバージョン（`\uXXXX`のエスケープは文字に戻して載せた）。名前が間違った`@param`は3881で止められ、正しく直したバージョンは、イベントに書いた`@return`がエラーなしで抜ける（0.8.36のChangelogの「NatSpec: Disallow `@return` tag in event documentation.」が直した動作）：

```
Error (3881): Documented parameter "y" not found in the parameter list of the function.
 --> Nat.sol:5:5:
  |
5 |     /// @param y 受け取る値
  |     ^^^^^^^^^^^^^^^^^^

======= Nat2.sol:Nat =======
Developer Documentation
{"kind":"dev","methods":{},"version":1}
User Documentation
{"events":{"Deposited(uint256)":{"notice":"預け入れ"}},"kind":"user","methods":{},"version":1}
```

Market第153講のバージョンは、コミット前の確認が`ci ok`、テスト75個が通り、末尾のハッシュの先頭4バイト`32e6a065`、レシートのgasUsedはデプロイ760,304、addAsset 92,656、deposit 127,515、withdraw 57,448、setStatus 45,001 / 23,089、失敗26,264である。第9部の出発点である第142講のバージョン（runtime 3,755 / creation 4,013、デプロイ867,827、テスト63個）から、第153講のバージョン（3,260 / 3,473、760,304、75個）に変わった。

### 試すときの注意

- リポジトリのテストの期待値は、そのバージョン（v0.8.36）のコンパイラ基準である。別のバージョンで実行すると、警告・エラーの行が違ってFAILが出る。
- 文法テストのファイルの実際のパスは、Contributingのドキュメント212行と違って`scoping/`の下にあり、期待値にエラー番号が付き、インデントはタブである。
- リポジトリの`scripts/isolate_tests.py`をWindowsでそのまま実行すると、ファイル名が長くて失敗する。
- コマンドラインテストのフォルダは675個（Standard JSON 341、コマンドライン275、スクリプト20、その他39）である。
- 0.8.31からsend・transfer、virtual modifierなどに廃止予定の警告が付き、既定のEVMがosakaになる。Marketは0.8.30をそのまま使う。
- バグ報告のテンプレート（`.github/ISSUE_TEMPLATE/bug_report.md`）のEnvironmentの六つの欄は、コンパイラのバージョン、コンパイルの経路（IRかどうか）、対象のEVM、フレームワーク、EVMの実行環境、OSである。セキュリティのバグは公開のissueに上げず、`SECURITY.md`が書いている方法で報告する。
- SolidityのロゴはCC BY 4.0で、ブランドガイドはコアチームが保証しているように見える使い方をしないようにと書いている。コンパイラのリポジトリのコードはGPL v3である。MarketのソースはGPL-3.0、forge-stdは`MIT OR Apache-2.0`、OpenZeppelin 5.4.0はMITである。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールのバージョン、リポジトリ、ドキュメントが変わると変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| solc | 0.8.30（`0.8.30+commit.73712a01.Windows.msvc`）。既定のevm_versionはprague。デモ用プロジェクトはoptimizerオフ・evm osaka。Market第153講のバージョンはdefaultがvia-IR + optimizerオン runs 200・evm osaka | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3 | 2026-10-20 |
| OS・ツール | Windows 11（10.0.26200）、Python 3.12.10、git 2.51.1 | 2026-10-20 |
| 公式ドキュメントの版 | Resources（176行）・Contributing（582行）・Brand Guide（86行）v0.8.36。Resourcesのまとまり`index.rst` 178〜185行 | 2026-10-20 |
| リポジトリ | github.com/argotorg/solidity、タグv0.8.36のコミット`8a079791d9cca7a6c03fd6a8429b93aa3bddefed`（2026-07-09）。sparse clone（.github、docs、test/libsolidity/syntaxTests、test/cmdlineTests、scripts）、Windowsでは`core.longpaths true`が必要、`core.autocrlf false`。Contributing 25行の行動規範のリンクはethereum/solidity | 2026-10-20 |
| ツールの一覧 | 53個（11 / 7 / 12 / 22 / 1）、Noteが四つ（28 Brownie、46 Truffle "September 21, 2023"、86 RemixのVS Code拡張、99 Truffle for VS Code）。ツールの現在の管理状態は確認していない | 2026-10-20 |
| チャンネル・チームコール | チームコールは水曜日3PM CET/CEST、Jitsi（meet.solidity.org）。チャットはMatrix（#ethereum_solidity、#ethereum_solidity-dev）、Gitter、フォーラムforum.soliditylang.org | 2026-10-20 |
| Changelogのバージョン・日付 | 0.8.30 2025-05-07、0.8.31 2025-12-03、0.8.32・0.8.33 2025-12-18、0.8.34 2026-02-18、0.8.35 2026-04-29、0.8.36 2026-07-09。既定のEVMは0.8.31からosaka（90行）。Important Bugfixes 4・5・51・67行 | 2026-10-20 |
| テストの数 | 文法テスト3,547（ソースが一つで設定の欄なし3,107：0.8.30でOK 2,917 / FAIL 190、設定の欄256、ソースが複数183、UTF-8でない1）、コマンドラインテスト675（341 / 275 / 20 / 39）、ドキュメントの例169（飛ばす3、ok 160、FAIL 6） | 2026-10-20 |
| 簡易チェッカーの範囲 | 期待値の照合だけ（Standard JSON、optimizerオン、CBORメタデータオフ、警告1878・3420を除外）。設定の欄・ソースが複数のファイルは飛ばす。isoltestではない | 2026-10-20 |
| テンプレートの欄の文言 | bug_report.mdのEnvironmentの六つの欄（27〜32行）、documentation_issue.mdの三つの欄、PRテンプレートのチェック二つ・AI Disclosure、SECURITY.mdの欄六つ（29〜36行） | 2026-10-20 |
| バウンティ | Ethereum bounty program bounty.ethereum.org（SECURITY.md 49〜50行） | 2026-10-20 |
| ドキュメントのビルド | `docs/docs.sh`（pip3 install、`sphinx-build -nW`）、requirements.txt `sphinx>=8.0.0, <9.0.0`・`sphinx_rtd_theme>=3.0.0`。実行はしていない | 2026-10-20 |
| ライセンスの版 | リポジトリGPL v3（`LICENSE.txt`）、ロゴCC BY 4.0、Market GPL-3.0、forge-std `MIT OR Apache-2.0`、OpenZeppelin 5.4.0 MIT | 2026-10-20 |
| 通しプロジェクトのガス（第25章の方法） | 第153講のバージョン：デプロイ760,304、addAsset 75 92,656、deposit 100 127,515、withdraw 30 57,448、setStatus 1 45,001、setStatus 0 23,089、失敗するdeposit 0 26,264 | 2026-10-20 |
| サイズ・ハッシュ | 第153講のバージョンdefault 3,260 / 3,473（legacy 3,755 / 4,013、debug 7,353 / 7,931）、末尾のハッシュの先頭4バイト`32e6a065`、`.gas-snapshot` 75行 | 2026-10-20 |
| 第9部の出発点の値 | 第142講のバージョン3,755 / 4,013、デプロイ867,827、テスト63個 | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| コンパイラのバグデータベースとImportant Bugfixesの判定 | [第184講](../../part11/lecture184/) |
| 0.8.31以降のバージョンに上げて警告を直す | [第185講](../../part11/lecture185/)、[第186講](../../part11/lecture186/) |
| 監査報告書に再現コードを書く | [第190講](../../part12/lecture190/) |
| セキュリティのバグの報告とバウンティ | [第191講](../../part12/lecture191/)、[第193講](../../part12/lecture193/) |
| ツールチェーンを選んで信頼すること | [第181講](../../part11/lecture181/) |
| 標準の実装を持ってきて使うときのライセンスとバージョン | [第154講](../../part10/lecture154/)〜[第159講](../../part10/lecture159/) |
| 検証済みのソースを公開リポジトリで探して使う | [第187講](../../part12/lecture187/)、[第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/)、[第190講](../../part12/lecture190/)、[第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |
| ドキュメントのビルド（Sphinx）の実測 | この講義では扱わない（データシートにだけ） |

出典と参考資料は[reference.md](reference.md)にまとめた。
