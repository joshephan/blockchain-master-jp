# 第131講 ASTとバイトコードの構造

第8部 コンパイラと内部構造・第31章 出力の分析

[← 第130講](../../part8/lecture130/) | [第8部 目次](../) | [第132講 →](../../part8/lecture132/)

## この講義の問い

solcが出すASTとバイトコードには、それぞれ何が残って何が抜け、バイトコードのどこからどこまでがデプロイのコード・ランタイムコード・メタデータで、その中をどう読むのか。

## 実習資料

### 準備

Storeは、solc 0.8.30の実行ファイルを直接呼んでAST（`--ast-compact-json`、パースの段階だけを見るなら`--stop-after parsing`を足す）、asm（`--asm`）、バイトコード（`--bin`、`--bin-runtime`）を取り出し、`cast disassemble`で命令単位で読んだ。Marketは`forge build --build-info`でbuild-infoに入っているASTを読み、第128講のように`forge verify-contract --show-standard-json-input`で取り出したsrcの四つのファイルの入力をsolcに入れ直して比べた。チェーンにはデプロイしなかった。`market`は通しプロジェクトMarketの第131講のバージョンで、forge-stdが必要である。

### コード

| ファイル | 内容 |
|---|---|
| [code/c131/Store.sol](code/c131/Store.sol) | 第128講から使ってきたStore（245バイト） |
| [code/c131/Store2.sol](code/c131/Store2.sol) | 同じStoreに日本語のコメントと空白だけを足したバージョン（319バイト） |
| [code/market/foundry.toml](code/market/foundry.toml) | Market 第131講のバージョンの設定 |
| [code/market/src/](code/market/src/) | Market 第131講のバージョン。第130講のバージョンとコードが同じで、バージョンを説明するコメントを1行だけ足した |
| [code/market/test/](code/market/test/) | Marketのテスト55個 |

### 実行結果

StoreのAST（`solc --ast-compact-json Store.sol`）。ノードごとにidと`src`（開始:長さ:ファイル番号）がつく。ノードは24個、種類は13である。

```
SourceUnit id 24 src 36:209:0
  PragmaDirective id 1 src 36:23:0
  ContractDefinition id 23 src 61:183:0 name 'Store'
    VariableDeclaration id 4 src 82:20:0 name 'v'
      ElementaryTypeName id 2 src 82:7:0 name 'uint256'
      Literal id 3 src 101:1:0
    FunctionDefinition id 12 src 109:72:0 name 'get'
      Block id 11 src 156:25:0
        Return id 10 src 166:8:0
          Identifier id 9 src 173:1:0 name 'v'
      ...
    FunctionDefinition id 22 src 187:55:0 name 'set'
      Block id 21 src 220:22:0
        ExpressionStatement id 20 src 230:5:0
          Assignment id 19 src 230:5:0
            Identifier id 17 src 230:1:0 name 'v'
            Identifier id 18 src 234:1:0 name 'x'
```

コメントと空白だけを変えたStore2.solは、`src`・`nameLocation`の欄を除けばASTが同じで、ノードのid・順序も同じである。`src`だけがずれる（例: `FunctionDefinition id 12: 109:72:0 -> 191:60:0`）。runtimeも、末尾の53バイトを除いた前の部分が同じである。

パースの段階のASTには、名前が何を指すかがない。コンパイル全体のASTでだけ、`typeDescriptions` 11か所、`referencedDeclaration` 3か所、`functionSelector` 3か所、`scope` 6か所が埋まる（`Identifier 'v' src 173:1:0 referencedDeclaration 4 -> VariableDeclaration 'v'`）。

`src`の数字は文字ではなくバイトの位置である。Store2.solの日本語のコメント「// 値を一つ保存するコントラクト」は17文字45バイトなので、`191:60:0`をバイトで読むと`function get() external view returns (uint256) { return v; }`だが、文字の位置で読むと見当違いの場所が出る。

Storeのデプロイのコード（creation 401バイト）の先頭32バイト。ランタイム369バイト（0x0171）を32番目のバイト（0x0020）からコピーして返す。

```
      0: PUSH1 0x80
      2: PUSH1 0x40
      4: MSTORE
      5: PUSH1 0x07
      7: PUSH0
      8: SSTORE
      9: CALLVALUE
     10: DUP1
     11: ISZERO
     12: PUSH1 0x12
     14: JUMPI
     15: PUSH0
     16: PUSH0
     17: REVERT
     18: JUMPDEST
     19: POP
     20: PUSH2 0x0171
     23: DUP1
     24: PUSH2 0x0020
     27: PUSH0
     28: CODECOPY
     29: PUSH0
     30: RETURN
     31: INVALID
```

ランタイムの末尾2バイト`0x0033` = 51なので末尾は53バイト、コードの部分は316バイト（命令231個）である。末尾はCBORである。

```
a2(欄二つ) 64 "ipfs" 58 22(34バイト) 12203ab396b3c5e361ed97181003673109c0e57f7b8fa61beb317cec5d48c7e6d87d 64 "solc" 43(3バイト) 00081e = 0.8.30
```

ランタイムのディスパッチャの先頭部分とセレクタ（`solc --hashes`: 6d4ce63c get()、60fe47b1 set(uint256)、7c2efcba v()）。

```
     25: PUSH0
     26: CALLDATALOAD
     27: PUSH1 0xe0
     29: SHR
     30: DUP1
     31: PUSH4 0x60fe47b1
     36: EQ
     37: PUSH2 0x0043
     40: JUMPI
```

同じバイトを途中から読むと、別の命令が出る。31番のPUSH4の中の`fe`（33番目のバイト）から読むと次のとおり。

```
32番から:
     32: PUSH1 0xfe
     34: SELFBALANCE
     35: UNKNOWN(0xB1)
33番から:
     33: INVALID
     34: SELFBALANCE
     35: UNKNOWN(0xB1)
```

末尾の53バイトを命令として読んでも、`LOG2`、`PUSH5 0x6970667358`、`UNKNOWN(0x22)`のような意味のない行が出る。

Market（build-info、第131講のバージョン）。ソース39個のうち、src/Market.solはid 21、ノード651個、SourceUnitのid 42888である。immutableReferencesのキーは、immutableの宣言のノードのidである。

```
immutableReferences {"42252": [3489, 3660], "42362": [2374, 2421, 2923], "42785": [2845]}
  42252 -> VariableDeclaration 'admin' immutable src 4968:30:21 = 35行目 'address public immutable admin'
  42362 -> VariableDeclaration 'collateralRatio' immutable src 7614:38:21 = 88行目 'Ratio public immutable collateralRatio'
  42785 -> VariableDeclaration 'interestRate' immutable src 13369:34:21 = 185行目 'Rate public immutable interestRate'
```

srcの四つのファイルだけを入れたStandard JSONでは、ファイル番号が0〜3になり、同じ宣言のidが256・366・789に変わるが、runtime・creationのバイトコードはforgeの成果物と同じである。

Marketのランタイム7,353バイト = コード7,300 + 末尾53、creation 7,931 = 578 + runtime。命令3,933個（JUMPDEST 367、JUMP 295、JUMPI 69、REVERT 30、PUSH4 30、PUSH32 28）。PUSH4の値23種のうち、関数のセレクタ19個はすべてあり、エラーのセレクタ12個は一つもない。immutableの六つの欄は、すべてPUSH32のうしろの32バイトの0である。バイトコードの中に"deposit"、"withdraw"、"Market"、"admin"、"ZeroAmount"の文字はない。`deposit(address,uint256)`のセレクタ0x47e7ef24は、ソースから計算しなければならない（`cast sig`）。

Market 第131講のバージョンの末尾。

```
a2646970667358221220 f8e6f45129d902a62fcdc2f96d27b601258175d807ce7a9b111a0349ab069101 64736f6c63 4300081e 0033
```

### 試すときの注意

- ASTの`src`はバイトの位置である。日本語のように複数のバイトで書かれる文字があると、文字数で数えるとずれる。
- 名前がどの宣言を指すか（`referencedDeclaration`）と型は、パースの段階ではなく、コンパイル全体のASTにだけある。
- バイトコードは最初から順に読まなければならない。PUSHのうしろのデータのバイトを命令として読むと、別の命令が出る。末尾2バイトで末尾の長さを求め、末尾を先に切り離してから読む。
- ノードのidとファイル番号は、入力に入ったファイルの数によって変わる。バージョンを説明するコメントが1行変わるだけでも、`src`の位置と末尾のハッシュが変わる。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンやソースが変わると変わることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメントのバージョン | Source Mappings（`s:l:f`の原文）、Contract Metadata（Encoding of the Metadata Hash in the Bytecode、last two bytesの原文）はv0.8.36タグ | 2026-10-20 |
| solc | 0.8.30+commit.73712a01（直接呼ぶ、evm_versionの既定値はprague。Store） | 2026-10-20 |
| Foundry（forge・cast・anvil） | 1.8.3、forgeのビルドのevm_versionはosaka（Market） | 2026-10-20 |
| forgeのbuild-info | ソース39個（0番はforgeが作ったファイル、1〜19はforge-std、20〜24はsrc、25〜38はtest）、`source_id_to_path`、`output.sources[*].ast` | 2026-10-20 |
| StoreのAST・バイト | ノード24個13種、SourceUnit `36:209:0`、Store2.sol 319バイト、日本語のコメント17文字45バイト、creation 401 / runtime 369（コード316 + 末尾53、命令231個）、末尾のハッシュ`3ab396b3c5e361ed97181003673109c0e57f7b8fa61beb317cec5d48c7e6d87d` | 2026-10-20 |
| MarketのAST・バイト | build-infoのsrc/Market.solはid 21、ノード651個、SourceUnit 42888、immutableReferencesのキー42252・42362・42785（四つのファイルの入力では256・366・789）、admin `4968:30:21`（第30章の終わりのバージョンでは`4699:30:21`）、creation 7,931 = 578 + runtime 7,353、命令3,933個、PUSH4 23種、PUSH32 28か所、ZeroAdmin 7289db0eはcreationの106番目 | 2026-10-20 |
| Market 第131講のバージョンの末尾 | `a2646970667358221220 f8e6f45129d902a62fcdc2f96d27b601258175d807ce7a9b111a0349ab069101 64736f6c63 4300081e 0033` | 2026-10-20 |
| 完全一致・部分一致の呼び名 | Sourcify "Exact Match" / "Match"（以前のperfect / partial）、Etherscanの完全一致"Exact Match" | 2026-10-20 |
| 実測の条件 | Windows 11、ソースの改行はLF。バージョンを説明するコメントが変わると、src・ノードの位置・末尾のハッシュが変わる | 2026-10-20 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| ソースマップの読み方と、pcから行を探すこと | [第132講](../../part8/lecture132/) |
| 二つのコード生成の経路でのasmとYulのオブジェクト | [第133講](../../part8/lecture133/)、[第134講](../../part8/lecture134/) |
| immutableとスロットの配置 | [第135講](../../part8/lecture135/) |
| オプティマイザが命令を減らすやり方 | [第139講](../../part8/lecture139/)、[第140講](../../part8/lecture140/) |
| ABIエンコードとセレクタの計算の規則 | [第141講](../../part8/lecture141/) |
| メタデータの欄の一つひとつと、末尾のほかの形（bzzr1、experimental） | [第142講](../../part8/lecture142/) |
| ASTを読むドキュメント生成 | [第146講](../../part9/lecture146/)、[第147講](../../part9/lecture147/) |
| 命名規則のチェック | [第149講](../../part9/lecture149/) |
| 静的解析のツール | [第182講](../../part11/lecture182/)、[第183講](../../part11/lecture183/) |
| ほかの人がデプロイしたコードを読む | [第243講](../../part18/lecture243/)、[第244講](../../part18/lecture244/)、[第245講](../../part18/lecture245/)、[第246講](../../part18/lecture246/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
