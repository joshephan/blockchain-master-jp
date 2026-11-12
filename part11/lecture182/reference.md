# 第182講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| solc | 0.8.30+commit.73712a01.Windows.msvc | `solc --version` | 2026-10-21 |
| Foundry（forge） | 1.8.3 (cae51ad4) | `forge --version` | 2026-10-21 |
| ソルバー | z3・cvc5・Eldaricaなし | 実行ファイルとPythonのz3モジュールを確認 | 2026-10-21 |

付録の質問の式、警告、終了コードは、すべて上の環境で直接実行した結果である。Overflow・Robotの反例の出力はドキュメントに載っている例で、この環境の出力ではない。ソルバーはダウンロードせず、外部への接続は使わなかった。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| solcのバージョン、ソルバーのインストールの有無 | 直接確認 | 2026-10-21 |
| forgeの既定値 | 直接実行（`forge config`） | 2026-10-21 |
| forgeのsmtプロファイルの警告の数 | 直接実行（`FOUNDRY_PROFILE=smt forge build --offline --force`） | 2026-10-21 |
| Marketの目標とサポートしない文法 | 直接実行（solcの`--model-checker-*`オプションでMarketのsrcをチェック） | 2026-10-21 |

## 参考資料

- Solidity公式ドキュメント v0.8.36、SMTChecker and Formal Verification（`smtchecker.rst`、この講義のsolcは0.8.30）。引用した行：12〜15、19〜26、28〜38、40〜43、45〜46、48〜55、57〜66、107〜120（Overflowの例の出力）、333〜348（Robotの例の出力）、502〜511、758〜768、787〜812、824〜834: https://docs.soliditylang.org/en/v0.8.36/smtchecker.html
  - "it considers `require` statements as assumptions and tries to prove that the conditions inside `assert` statements are always true."
  - "The lack of warnings for a verification target represents an undisputed mathematical proof of correctness, assuming no bugs in the SMTChecker and the underlying solver."
  - 二つのエンジン（BMC、CHC）、既定の検証目標、ソルバー（cvc5、Eldarica、z3）、`abstract-function-nondet`、サポートしない文法の過大近似
- SMT-LIB2形式（`--model-checker-solvers smtlib2`が出す質問の形式）
- Foundry公式ドキュメント（`[profile.*.model_checker]`の設定、`deny`、`ignored_error_codes`）: https://getfoundry.sh/
