# 第45講 コメントとNatSpecの予告

第4部 言語の詳細 ① ファイルと型・第11章 ソースファイルの構造

[← 第44講](../../part4/lecture44/) | [第4部 目次](../) | [第46講 →](../../part4/lecture46/)

## この講義の問い

コメントはコンパイラが捨てると思っていたのに、あるコメントはなぜメタデータに文字どおりに入るのか。

## 実習資料

### 準備

`forge init`で作ったhelloプロジェクトから、`src`、`test`、`script`のCounterのファイルを消して始める。外部ライブラリは使わない。`src/Ballot.sol`は、[第37講](../../part3/lecture37/)の公式ドキュメントのVotingの例の原文である。コンパイルできない例と比較用のコピーは、`src`の外の`bad/`フォルダに置き、パスを指定して別々にビルドする。

`src/Vault.sol`の`deposit`の上の`@notice`に書かれた"No fee"は、ドキュメントがコードと食い違うことがあると示すために、わざと書いた偽の説明である。実際には1%を差し引いて`collected`に積む。このまま持ってきて使わないこと。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定 |
| [code/src/Vault.sol](code/src/Vault.sol) | NatSpec（`@title`、`@notice`、`@dev`、`@param`、`@return`）、ふつうのコメント、forgefmtの指示コメントが一緒にある入金の金庫 |
| [code/src/Ballot.sol](code/src/Ballot.sol) | 公式ドキュメントのVotingの例の原文（コメントの行数とドキュメント出力の比較用） |
| [code/bad/NoDirective.sol](code/bad/NoDirective.sol) | Vault.solからforgefmtの指示コメント一行だけを消したコピー |
| [code/bad/ParamName.sol](code/bad/ParamName.sol) | `@param`の名前の打ち間違い（コンパイルエラー） |
| [code/bad/UnknownTag.sol](code/bad/UnknownTag.sol) | 存在しないタグ`@foo`（コンパイルエラー） |
| [code/bad/CustomTag.sol](code/bad/CustomTag.sol) | ユーザー定義のタグ`@custom:fee` |

### 実行結果

`forge inspect Vault userdoc`、`forge inspect Vault devdoc`。ドキュメントがユーザー向けと開発者向けの二つに分かれる：

```
{
  "version": 1,
  "kind": "user",
  "methods": {
    "deposit(uint256)": {
      "notice": "Deposit ether. No fee."
    },
    "withdraw()": {
      "notice": "Withdraw your whole balance."
    }
  },
  "notice": "Everything you send becomes your balance."
}

{
  "version": 1,
  "kind": "dev",
  "methods": {
    "deposit(uint256)": {
      "details": "Balance is recorded in balanceOf.",
      "params": {
        "minAmount": "Minimum amount to be credited"
      },
      "returns": {
        "credited": "Amount added to the balance"
      }
    }
  },
  "title": "Deposit vault"
}
```

`out/Vault.sol/Vault.json`の`rawMetadata`の文字列（1,698文字）のうち、`"devdoc"`から`"settings"`の手前まで。NatSpecはメタデータのoutputの欄に入る：

```
"devdoc":{"kind":"dev","methods":{"deposit(uint256)":{"details":"Balance is recorded in balanceOf.","params":{"minAmount":"Minimum amount to be credited"},"returns":{"credited":"Amount added to the balance"}}},"title":"Deposit vault","version":1},"userdoc":{"kind":"user","methods":{"deposit(uint256)":{"notice":"Deposit ether. No fee."},"withdraw()":{"notice":"Withdraw your whole balance."}},"notice":"Everything you send becomes your balance.","version":1}}
```

同じ文字列に`No fee`はあり、`forgefmt`とふつうのコメントの文字はない。

ランタイムコードの末尾（`forge inspect Vault deployedBytecode`）。`a2 64 "ipfs" 58 22 1220`のあとの32バイトがメタデータのハッシュ、`64 "solc" 43 00081e`がコンパイラのバージョン、最後の`0033`が末尾の長さ（53バイト）である：

```
0x...fea2646970667358221220bbcfa19660862eef9eba4c6c66714464f5da76d4564f4bf9b2fade2a27f0006864736f6c634300081e0033
```

forgefmtの指示コメント。`forge fmt --check src/Vault.sol`は終了コード0で、指示コメントを消したコピーは直すべき場所を示して終了コード1になる：

```
$ forge fmt --check bad/NoDirective.sol
Diff in bad\NoDirective.sol:
13  13   |     /// @param minAmount Minimum amount to be credited
14  14   |     /// @return credited Amount added to the balance
15  15   |     function deposit(uint256 minAmount) external payable returns (uint256 credited) {
16       |-        uint256 fee=msg.value/100;
    16   |+        uint256 fee = msg.value / 100;
17  17   |         collected += fee;
18  18   |         credited = msg.value - fee;
19  19   |         require(credited >= minAmount);
```

NatSpecの形式チェック（Compiling、Solcの行は省略）：

```
$ forge build --offline bad/ParamName.sol
Error (3881): Documented parameter "minAmout" not found in the parameter list of the function.
 --> bad/ParamName.sol:5:5:

$ forge build --offline bad/UnknownTag.sol
Error (6546): Documentation tag @foo not valid for functions.
 --> bad/UnknownTag.sol:5:5:

$ forge build --offline bad/CustomTag.sol
Compiler run successful!
```

CustomTagの`rawMetadata`のdevdocは`"devdoc":{"kind":"dev","methods":{"deposit()":{"custom:fee":"1% goes to collected."}},"version":1}`である。

偽の@noticeがついたVaultをローカルのanvilにデプロイし、`deposit(0)`に1 etherを送った結果。残高には0.99 etherだけが入り、0.01 etherは`collected`に積まれる。チェーン上のコードの末尾は、上のビルド結果と同じである：

```
$ cast call <Vault> "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
990000000000000000 [9.9e17]
$ cast call <Vault> "collected()(uint256)"
10000000000000000 [1e16]
$ cast code <Vault>
0x...fea2646970667358221220bbcfa19660862eef9eba4c6c66714464f5da76d4564f4bf9b2fade2a27f0006864736f6c634300081e0033
```

`@notice`の文言だけを"Deposit ether. 1% fee goes to collected."に直したあと、ランタイムコードをバイト単位で比較した結果。メタデータのハッシュ32バイトだけが変わる：

```
サイズ: 1297 1297
最初に異なるバイト: 1254
異なるバイト数: 32
before 末尾: a2646970667358221220bbcfa19660862eef9eba4c6c66714464f5da76d4564f4bf9b2fade2a27f0006864736f6c634300081e0033
after  末尾: a2646970667358221220fe27514c95ddfcd3a50c0354fda9015ba6849b43c108255ca70b774f03b76a0764736f6c634300081e0033
```

文言を元に戻してビルドし直すと、最初と同じバイトコードが出る。

Ballot.solのコメントの行数は、`///`が7行、`//`が49行である。`forge inspect Ballot userdoc`と`devdoc`：

```
{
  "version": 1,
  "kind": "user",
  "methods": {
    "constructor": {
      "notice": "Create a new ballot to choose one of `proposalNames`."
    },
    "delegate(address)": {
      "notice": "Delegate your vote to the voter `to`."
    },
    "vote(uint256)": {
      "notice": "Give your vote (including votes delegated to you) to proposal `proposals[proposal].name`."
    }
  }
}

{
  "version": 1,
  "kind": "dev",
  "methods": {
    "winningProposal()": {
      "details": "Computes the winning proposal taking all previous votes into account."
    }
  },
  "title": "Voting with delegation."
}
```

タグのない`///`の行はnoticeとして出る。

### 試すときの注意

- forge 1.8.3の`forge inspect Vault metadata`の整形版には、コントラクト単位の`notice`・`title`が抜けている。コンパイラが出した原文は、成果物のJSONの`rawMetadata`で見る。
- 同じ理由で、`forge inspect ... devdoc`の整形版には`custom:fee`のようなユーザー定義のタグが抜け、`"deposit()": {}`として出る。`rawMetadata`には入っている。
- NatSpecを日本語で書くと、`rawMetadata`の中ではUnicodeエスケープの形で入る。
- Ballotのビルドのとき、forgeのリンターが`require-revert-in-loop`の警告を一つ出す。コンパイラの警告ではない。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| Solidity公式ドキュメントのバージョン | v0.8.36（Layout of a Solidity Source FileのCommentsの節、NatSpec Formatの節） | 2026-10-19 |
| solcのバージョン | 0.8.30（メタデータの末尾`64736f6c634300081e`） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| Vaultのサイズ | ランタイムコード1,297バイト、末尾53バイト、メタデータのJSON 1,698バイト（最適化オフ） | 2026-10-19 |
| エラーコード | 3881（ドキュメントのパラメーター名が存在しない）、6546（関数に使えないタグ） | 2026-10-19 |
| ツールの指示コメントの表記 | forgefmt：`// forgefmt: disable-next-line`（直接確認）。solhint：`// solhint-disable-next-line`、slither：`// slither-disable-next-line`（各ツールのドキュメントの表記、実行確認はしていない） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| NatSpecタグの全種類（@author、@inheritdocなど）、継承時のドキュメントの扱い、イベント・エラー・状態変数のNatSpec | [第146講](../../part9/lecture146/)、[第147講](../../part9/lecture147/) |
| メタデータJSONの内容全体と末尾のCBORの構造 | [第142講](../../part8/lecture142/) |
| 検証サービスの完全一致・部分一致のルール | [第130講](../../part8/lecture130/)、[第142講](../../part8/lecture142/) |
| コメント・命名のルールとコードレイアウトの慣例 | [第148講](../../part9/lecture148/)、[第149講](../../part9/lecture149/) |
| コードが守るべき条件をツールでチェックする方法 | [第182講](../../part11/lecture182/) |
| 監査でコメントとコードを突き合わせて読む順番 | [第188講](../../part12/lecture188/) |
| ドキュメントとコードが違う箇所を報告書に書く方法 | [第190講](../../part12/lecture190/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
