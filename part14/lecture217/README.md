# 第217講 Safeマルチシグの運用

第14部 オラクル・クロスチェーン・ガバナンス・第58章 ガバナンスの実装

[← 第216講](../../part14/lecture216/) | [第14部 目次](../) | [第218講 →](../../part15/lecture218/)

## この講義の問い

署名をチェーンの外で集めて一度に実行するマルチシグは、何に署名するのか。同じ署名をもう一度出したり、ほかのチェーン・ほかのウォレットに出したりするとどうなるのか。署名はなぜ決まった順番に並べるのか。署名者は署名する前に何を確かめるのか。

## 実習資料

### 準備

通しプロジェクトMarket（第53章の終わりのバージョン、srcは直さない）のコピーに、テスト用のマルチシグ`MiniSafe`とそのテスト`Safe58.t.sol`を足す。`MiniSafe`はOpenZeppelin Contracts 5.4.0のEIP712・ECDSAを使い、OZの`contracts/`フォルダを`lib/`の外の`vendor/oz/`に置いて相対パスで読み込む。forge-stdは`lib/forge-std`に置く。Marketの`foundry.toml`はガス記録の検査をオンにしてあるので、このコピーでは`FOUNDRY_GAS_SNAPSHOT_CHECK=false FOUNDRY_GAS_SNAPSHOT_EMIT=false`をつけて実行する。

テストのほかに、anvil（チェーンの番号31337）でも同じ流れをcastで回す：MockToken・MiniSafe（署名者はanvilのアカウント1・3・4、しきい値2）・Market（admin = MiniSafe）をデプロイし、`addAsset(トークン, 75)`の取引のハッシュを計算し直してから、アカウント1・3が`cast wallet sign --no-hash`で署名し、アカウント0が`execute`を送る。署名にはanvilの既定のテスト用の鍵だけを使う。MiniSafeは講義用の最小のマルチシグなので、実際の資産には使わない。

### コード

| ファイル | 内容 |
|---|---|
| [code/foundry.toml](code/foundry.toml) | Marketのビルド設定（solc 0.8.30、optimizer runs 200、via-IR、evm osaka、ガス記録の検査） |
| [code/src/Market.sol](code/src/Market.sol) | 通しプロジェクトMarket（第53章の終わりのバージョン） |
| [code/src/IMarket.sol](code/src/IMarket.sol) | Marketのインターフェース |
| [code/src/MarketMath.sol](code/src/MarketMath.sol) | 利息・ポジションの計算のライブラリ |
| [code/src/MarketTypes.sol](code/src/MarketTypes.sol) | ユーザー定義型、構造体、IERC20・IPriceFeed |
| [code/src/MockToken.sol](code/src/MockToken.sol) | テスト用のトークン |
| [code/test/MiniSafe.sol](code/test/MiniSafe.sol) | 講義用の最小のマルチシグ：EIP-712のドメインと`Tx(address to,uint256 value,bytes data,uint256 nonce)`のハッシュ、アドレス順の署名の検査、しきい値、使用番号、CALLだけ |
| [code/test/Safe58.t.sol](code/test/Safe58.t.sol) | Safe58Testの13個：署名二つでの実行、並べ替え、しきい値、再提出、ほかのチェーン・ほかのウォレット、番号の順番、失敗時の番号、しきい値の変更、署名者一人 |

### 実行結果

`forge test --offline --match-contract Safe58Test -vvv`（ガス記録の検査を切ったまま）：

```
Ran 13 tests for test/Safe58.t.sol:Safe58Test
[PASS] test_adminIsSafe() (gas: 24222)
[PASS] test_changeThresholdOnlySelf() (gas: 125356)
[PASS] test_failedCallKeepsNonce() (gas: 107756)
[PASS] test_nonceOrder() (gas: 321220)
[PASS] test_oneSigBelowThreshold() (gas: 57222)
[PASS] test_otherChainRejected() (gas: 81206)
[PASS] test_otherSafeRejected() (gas: 943191)
[PASS] test_replayRejected() (gas: 160185)
[PASS] test_sameSignerTwice() (gas: 73371)
[PASS] test_signerAloneNotAdmin() (gas: 33249)
[PASS] test_strangerSig() (gas: 73625)
[PASS] test_twoSigsExecute() (gas: 179501)
Logs:
  txHash nonce 0: 0x8eff773e7e98ef44ee3592869a406c4d2736567da09de1e0a01cd4ad3f6c3128
[PASS] test_unsortedRejected() (gas: 79685)
Suite result: ok. 13 passed; 0 failed; 0 skipped
```

anvilでデプロイし、`cast decode-calldata`で取引をデコードした結果と、コントラクトが返したハッシュ、castで計算し直したハッシュ：

```
MockToken 0x5FbDB2315678afecb367f032d93F642f64180aa3
MiniSafe 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
Market 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
admin 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512  threshold 2 nonce 0
data 0x6127548a0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3000000000000000000000000000000000000000000000000000000000000004b
decode: 0x5FbDB2315678afecb367f032d93F642f64180aa3 75
txHash (contract) 0x0dbd8d48229780d309334e340fdc7c0e8feb9f0b7e6815a8f0bb388600e68ee4
txHash (recomputed) 0x0dbd8d48229780d309334e340fdc7c0e8feb9f0b7e6815a8f0bb388600e68ee4
```

計算し直した順番（ドメインのハッシュ → 取引の構造体のハッシュ → `0x1901`を前に付けてkeccak）：

```
domain 0x183549e025ed6e575459a147950fe0169e9a5e20ed0779e7cb2d265d9011f06e
TX_TYPEHASH 0x9131c2b6c18d884144cc09473785706bae6b83eb79c3cd354814b12f42e587d8
keccak(data) 0x6f9a1e2ef51e09ffe3421c48a8a4163064f9a38e6a148d2a99420be3e2fb897d
struct n0 0xfca78fe81055ebbf905bd419ef137d23f05cd8981d64d49414ea3a5271b03c4a
final 0x0dbd8d48229780d309334e340fdc7c0e8feb9f0b7e6815a8f0bb388600e68ee4
```

`execute`を送った結果（`cast send`）：

```
-- one signature:
: BelowThreshold(1, 2)
-- account3 first (unsorted):
: NotSorted(0x90F79bf6EB2c4f870365E785982E1f101E93b906, 0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
-- sorted two (sent by account 0):
gasUsed              140168
status               1 (success)
assetCount 1 assetConfig 75 true  nonce 1
-- replay same sigs:
: NotOwner(0x72c3ACec97Ba2E480Aa877C6737b2C6f05b1A06C)
-- account1 calls Market directly:
: NotAdmin(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
```

同じ署名をもう一度出すと、ハッシュにnonce 1が入って見当違いのアドレスが復元される（`NotOwner`）。署名者一人ではMarketに何もできない（`NotAdmin`）。

### 試すときの注意

- 署名する前にcalldataを`cast decode-calldata`でデコードし、署名するハッシュを自分で計算し直して、画面のハッシュと同じときだけ署名する。
- 署名するハッシュには、チェーンの番号とウォレットのアドレス（EIP-712のドメイン）、使用番号が入る。だから同じ署名をもう一度出したり、ほかのチェーン・ほかのウォレットに出したりすると、別の署名者が復元される。復元に失敗すると、OZの`ECDSA.recover`は0アドレスを返さずにリバートする。
- 署名は署名者のアドレス順に付ける。順番を決めておくと、同じ署名者を2回入れることを1回の比較で防げる（`test_sameSignerTwice`）。
- 実行を送るアカウントは署名者でなくてもよい（ガスを払うだけである）。
- 署名は前もって集めておけるが、実行の順番は使用番号が決める（`test_nonceOrder`）。
- 対象の呼び出しがリバートすると（`RatioAboveCap(90, 80)` → `CallFailed`）、実行全体がリバートして番号も使わない。同じ署名でもう一度出せるので、中身が間違った署名は、同じ番号でほかの取引に署名して上書きする。
- しきい値の変更はウォレット自身だけが行う。直接呼ぶと`NotSelf`、署名二つでウォレットが自分に取引を送ると変わる。
- MiniSafeには委任呼び出し（DELEGATECALL）を入れていない。委任呼び出しで呼んだコードは、ウォレットのストレージを書き換えられる。
- 署名者の鍵三つを一人が一つの機器に置くと、しきい値は意味がない。

## 時効性のあるデータ

基準日時点の値。時間がたつと変わることがある。ツールとライブラリのバージョン、公開ドキュメントが変わると、値が変わりうる。

| 項目 | 値 | 基準日 |
|---|---|---|
| Foundry（forge・cast・anvil） | 1.8.3、commit cae51ad4 | 2026-10-21 |
| solc | 0.8.30 | 2026-10-21 |
| OpenZeppelin Contracts | 5.4.0（EIP712・ECDSA、`vendor/oz`のコピー） | 2026-10-21 |
| anvil | チェーンの番号31337、既定のテスト用の鍵（アカウント0・1・3・4） | 2026-10-21 |
| デモのアドレス | MockToken 0x5FbDB2315678afecb367f032d93F642f64180aa3 / MiniSafe 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 / Market 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 | 2026-10-21 |
| 署名するハッシュ（nonce 0） | 0x0dbd8d48229780d309334e340fdc7c0e8feb9f0b7e6815a8f0bb388600e68ee4 | 2026-10-21 |
| 実行のガス | 署名二つのexecute（addAsset 75）gasUsed 140,168 | 2026-10-21 |
| テストのガス（Safe58Test） | adminIsSafe 24,222 / changeThresholdOnlySelf 125,356 / failedCallKeepsNonce 107,756 / nonceOrder 321,220 / oneSigBelowThreshold 57,222 / otherChainRejected 81,206 / otherSafeRejected 943,191 / replayRejected 160,185 / sameSignerTwice 73,371 / signerAloneNotAdmin 33,249 / strangerSig 73,625 / twoSigsExecute 179,501 / unsortedRejected 79,685 | 2026-10-21 |
| Safeの公開ドキュメント | しきい値の範囲、ハッシュに署名 | 2026-10-21 |
| Safeの公開ドキュメント | 署名の並べ方 | 2026-10-21 |
| Safe Knowledge Base（ヘルプのドキュメント） | 使用番号の定義、最後の番号 + 1だけを実行（ページに正確な更新日なし） | 2026-10-21 |

## 関連するテーマ

| テーマ | 扱う講義 |
|---|---|
| マルチシグのウォレットのモジュール・ガード（署名の確認を飛ばす道ができる、Safeのドキュメント"can bypass signature verification logic"） | [第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| 委任呼び出しの取引の署名 | [第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| ガスの肩代わりと様々な署名の形（コントラクトの署名EIP-1271） | [第218講](../../part15/lecture218/)〜[第223講](../../part15/lecture223/) |
| 署名者の機器と交代の手順 | [第269講](../../part21/lecture269/)、[第270講](../../part21/lecture270/) |
| 実際のSafeのデプロイ・画面 | 扱わない |
| チェーンの外の署名の投票ツール、投票の持ち分を分ける集計 | 付録 |

出典と参考資料は[reference.md](reference.md)にまとめた。
