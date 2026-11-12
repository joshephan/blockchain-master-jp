# 第117講 出典

## ツールと実行環境

| 項目 | 値 | 確認方法 | 基準日 |
|---|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3 (cae51ad) | `forge --version` | 2026-10-19 |
| solc | 0.8.30、optimizerは切る（既定値）、既定（レガシー）のパイプライン | foundry.toml `solc = "0.8.30"` | 2026-10-19 |
| anvil | 既定の設定、ブロックの間隔は1秒に固定（`cast rpc anvil_setBlockTimestampInterval 1`） | 直接実行 | 2026-10-19 |

付録のアドレス、トレース、サイズ、バイトの比較、ガスは、すべて上の環境で直接実行した結果である。同じ順番を二回走らせて、同じ値を確かめた。

## データの出典

| 項目 | 出典 | 基準日 |
|---|---|---|
| ランタイムコードのサイズの上限 | EIP-170 | 2026-10-19 |
| 外部呼び出しのコードの確認 | Solidity公式ドキュメント v0.8.36 Control Structuresの章 | 2026-10-19 |
| サイズ、linkReferences、セレクタ | 直接実行（`forge build --sizes`、成果物のJSON、`forge inspect methodIdentifiers`、`cast keccak`） | 2026-10-19 |
| ガス（ShelfExtのデモ） | 直接実行（`cast receipt`、`cast send --json`） | 2026-10-19 |
| 二つのShelfExtのランタイムコードの比較 | 直接実行（`cast code`二回をバイト単位で照合） | 2026-10-19 |
| Marketのガス | 直接実行（バージョンごとに新しいanvil、`cast send`、`cast estimate`） | 2026-10-19 |

## 参考資料

- Solidity公式ドキュメント v0.8.36 Librariesの節: https://github.com/argotorg/solidity/blob/v0.8.36/docs/contracts/libraries.rst
  - "Calling a public library function with `L.f()` results in an external call (`DELEGATECALL` to be precise)."
  - プレースホルダー："a 34 character prefix of the hex encoding of the keccak256 hash of the fully qualified library name"
  - Function Signatures and Selectors in Libraries："the calling convention for such calls is considered to be internal to Solidity and not the same as specified for the regular contract ABI"、storageのポインタ型は型の名前のあとに" storage"をつけ、値は指すスロット番号の`uint256`としてエンコード
  - Call Protection For Libraries：ライブラリのランタイムコードはコンパイル時に0の20バイトのPUSHで始まり、デプロイのときにその位置が現在のアドレスに変わり、view・pureでない関数は現在のアドレスとこの値を比べる
- Solidity公式ドキュメント v0.8.36 Control Structuresの章: https://docs.soliditylang.org/en/v0.8.36/control-structures.html
  - "Solidity uses the `extcodesize` opcode to check that the contract that is about to be called actually exists"、"This check is skipped if the return data will be decoded after the call"、"This check is not performed in case of low-level calls"
- EIP-170（コントラクトのコードのサイズの上限）: https://eips.ethereum.org/EIPS/eip-170
- Foundry公式ドキュメント（`forge create --libraries`、`cast run`、`cast call --trace`）: https://getfoundry.sh/
