# 第63講 代入のときのコピーと参照のルール

第4部 言語の詳細 ① ファイルと型・第14章 参照型

[← 第62講](../../part4/lecture62/) | [第4部 目次](../) | [第64講 →](../../part4/lecture64/)

## この講義の問い

同じ等号一行が、あるときはコピーを作り、あるときは元をそのまま直す。その分かれ目は何が決めるのか。

## 実習資料

### 準備

`forge init`で作った空のFoundryプロジェクトから、Counterのファイルを消して始める。`src/Ballot.sol`は、Solidity公式ドキュメントの投票の例（Voting with delegation）の原文そのままである。デプロイと呼び出しは、ローカルのanvilで既定のアカウント0番（デプロイ・議長）、1番（アリス）、2番（ボブ）を使って行う（公開されたテスト用のアカウント、`--unlocked`）。エラーを見る二つのファイルはプロジェクトの外の`bad/`に置き、見るときだけsrcに入れて、また外す。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | solc 0.8.30に固定、ビルドのときのリントをオフ |
| [code/src/MarkStorage.sol](code/src/MarkStorage.sol) | `Voter storage v = voters[msg.sender]`でvotedを直す版 |
| [code/src/MarkMemory.sol](code/src/MarkMemory.sol) | 同じ行を`Voter memory v`に変えた版（保存されない） |
| [code/src/MarkMemoryView.sol](code/src/MarkMemoryView.sol) | 警告どおり`markVoted`にviewをつけた版 |
| [code/src/Assign.sol](code/src/Assign.sol) | 場所の組み合わせ6種類の代入と、storage・memoryパラメーターの二つの版 |
| [code/src/Ballot.sol](code/src/Ballot.sol) | 公式ドキュメントの投票の例の原文 |
| [code/src/BallotMemory.sol](code/src/BallotMemory.sol) | Ballotの`Voter storage sender`を`Voter memory sender`に変えた版（77行目、122行目） |
| [code/bad/MemToStorage.sol](code/bad/MemToStorage.sol) | memory配列をstorageのローカル変数に代入。Error (9574) |
| [code/bad/ExtStorage.sol](code/bad/ExtStorage.sol) | external関数にstorageパラメーター。Error (6651) |

### 実行結果

`forge build --offline --force`。MarkMemoryにだけ警告がつき、MarkMemoryView、BallotMemoryにはない：

```
Compiling 6 files with Solc 0.8.30
Compiler run successful with warnings:
Warning (2018): Function state mutability can be restricted to view
  --> src/MarkMemory.sol:18:5:
   |
18 |     function markVoted() external {
   |     ^ (Relevant source part starts here and spans across multiple lines).
```

`bad/`の二つのファイルをsrcに入れたとき：

```
Error (9574): Type uint256[] memory is not implicitly convertible to expected type uint256[] storage pointer.
 --> src/MemToStorage.sol:9:9:
  |
9 |         uint[] storage s = m;
  |         ^^^^^^^^^^^^^^^^^^^^

Error (6651): Data location must be "memory" or "calldata" for parameter in external function, but "storage" was given.
 --> src/ExtStorage.sol:5:16:
  |
5 |     function f(uint[] storage arr) external {
  |                ^^^^^^^^^^^^^^^^^^
```

MarkStorageとMarkMemoryをデプロイし、アカウント1に投票権を与えたあと、アカウント1が`markVoted()`を呼んだ結果。二つの版とも成功するが、gasUsedは43477と28016である。`cast index address <アカウント1> 0`で求めたVoterの欄を`cast storage`で読むと、2番目の欄（voted）がMarkStorageは1、MarkMemoryは0である：

```
$ cast index address 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 0
0x14e04a66bf74771820a7400ff6cf065175b3d7eb25805a5bd1633b161af5d101
(MarkStorage)
...d101  0x0000000000000000000000000000000000000000000000000000000000000001
...d102  0x0000000000000000000000000000000000000000000000000000000000000001
(MarkMemory)
...d101  0x0000000000000000000000000000000000000000000000000000000000000001
...d102  0x0000000000000000000000000000000000000000000000000000000000000000
```

1番目の欄（…d101）はweight、2番目の欄（…d102）はvoted（いちばん最後のバイト）とdelegate、3番目の欄（…d103）はvoteである。`cast call`で`voters(address)`を読んでも、MarkStorageは`1 true`、MarkMemoryは`1 false`である。

Assignをデプロイした直後、xは[1,2,3]、yは[10,20,30]である。下の順番で呼んだ結果（順番を変えるとx[0]の値が変わる）：

| 呼び出し | 結果 |
|---|---|
| `storageToMemory()`（call） | 777、1。memoryのコピーだけが変わり、x[0]は1 |
| `memoryToMemory()`（call） | 7。memoryどうしは同じ配列を指す |
| `calldataToMemory([1,2,3])`（call） | 7、1。calldataはそのまま |
| `passCopy()`（call） | 2、1。memoryパラメーターはコピー |
| `passRef()`（send）のあとのx[0] | 2。storageパラメーターは元 |
| `storageToLocal()`（send）のあとのx[0] | 5 |
| `memoryToState()`（send）のあとのx[0] | 4。代入のあとのm[0] = 8は反映されない |
| `stateToState()`（send）のあとのx[0]、y[0]、x[1]、x[2] | 10、99、20、30。代入のあとのy[0] = 99はxに反映されない |

BallotとBallotMemoryを提案coffee、teaでデプロイし、アカウント1・2に投票権を与えたあと、アカウント2がアカウント1に`delegate`を2回呼んだ結果。最初の委任は両方とも成功し、2回目の委任でBallotだけが止められる：

```
Ballotの2回目の委任:
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: You already voted., data: "0x08c379a0...": Error("You already voted.")
BallotMemoryの2回目の委任:
status               1 (success)
```

そのあと`voters(address)`を読むと、Ballotはアカウント1がweight 2、アカウント2がvoted trueでdelegateがアカウント1である。BallotMemoryはアカウント1のweightが3に増え、アカウント2はvoted false、delegate 0x0のままである。

`forge inspect --offline Assign storageLayout`と`MarkStorage storageLayout`（見出しの行は省略）：

```
| x    | uint256[] | 0    | 0      | 32    | src/Assign.sol:Assign |
| y    | uint256[] | 1    | 0      | 32    | src/Assign.sol:Assign |
| voters | mapping(address => struct MarkStorage.Voter) | 0    | 0      | 32    | src/MarkStorage.sol:MarkStorage |
```

### 試すときの注意

- MarkMemoryの`markVoted()`はエラーなしで成功し、ガスも少なくてすむ。結果を確かめるには、`cast storage`や`voters(address)`で欄を直接読む必要がある。
- BallotMemoryはコンパイルの警告なしでビルドされる。警告がないからといって、storageをmemoryに変えた行が安全なわけではない。
- 新しいanvilで上の順番にデプロイすると、アドレスはMarkStorage `0x5FbDB2315678afecb367f032d93F642f64180aa3`、MarkMemory `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`、Assign `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`、Ballot `0x8A791620dd6260079BF849Dc5567aDC3F2FdC318`、BallotMemory `0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0`である。

## 時効性のあるデータ

基準日時点の値。ツールのバージョンが変わると、数字と警告の文言が違ってくることがある。

| 項目 | 値 | 基準日 |
|---|---|---|
| 公式ドキュメント | Typesの節のData location and assignment behavior、v0.8.36 | 2026-10-19 |
| solcのバージョン | 0.8.30、optimizerはオフ（既定値） | 2026-10-19 |
| Foundry（forge・cast・anvil）のバージョン | 1.8.3 | 2026-10-19 |
| markVotedのgasUsed | MarkStorage 43,477 / MarkMemory 28,016 | 2026-10-19 |
| MarkMemoryのビルドの警告 | Warning (2018) Function state mutability can be restricted to view | 2026-10-19 |
| MarkMemoryViewのビルドの警告 | なし（markVotedにviewだけをつけた版） | 2026-10-19 |
| BallotMemoryのビルドの警告 | なし（Compiler run successful!） | 2026-10-19 |
| エラーの原文 | 9574（memory → storageのローカル変数）、6651（external関数のstorageパラメーター） | 2026-10-19 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| コピーのコストの数字（配列の長さごとのgasUsed、memory・calldataパラメーターの比較） | [第64講](../../part4/lecture64/) |
| 固定サイズのメモリ配列の別名（`uint[3] memory b = a`） | [第65講](../../part4/lecture65/) |
| メモリ配列の作成（`new`、配列リテラル） | [第67講](../../part4/lecture67/) |
| calldataのスライスが元を指すこと | [第69講](../../part4/lecture69/) |
| 構造体のフィールドを別名で直すパターンと、書き戻しを忘れたmemoryの版 | [第70講](../../part4/lecture70/) |
| 外部呼び出しの引数のエンコードのルール | [第78講](../../part5/lecture78/) |
| 入れ子のマッピングの中の欄をstorageの名前で直すパターン、memoryで受け取って値が増えない場合 | [第72講](../../part4/lecture72/) |
| 内部関数の呼び出し全般とstorageパラメーター | [第82講](../../part5/lecture82/) |
| コードの精読でstorage・memoryの行を確かめる順番と、その誤用の深刻度の判定 | [第188講](../../part12/lecture188/)、[第189講](../../part12/lecture189/) |

出典と参考資料は[reference.md](reference.md)にまとめた。
